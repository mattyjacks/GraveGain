-- DropDwarf: handlers/death_handler.lua
-- Server-side lifecycle management for deaths, respawns, and rescue revives.

local Players    = game:GetService("Players")
local Networking = require(game.ReplicatedStorage.Shared.networking)
local GameData   = require(game.ReplicatedStorage.Shared.game_data)
local GameMode   = require(game.ReplicatedStorage.Shared.game_mode)
local PlayerData = require(script.Parent.Parent.player_data)
local UpgradeData = require(game.ReplicatedStorage.Shared.upgrade_data)
local Leaderboard = require(script.Parent.Parent.leaderboard)
local Session    = require(script.Parent.Parent.session)
local ItemHandler = require(script.Parent.Parent.item_handler)

local DeathHandler = {}

local rescueTick = {}

local function applyStats(player, stats)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.BreakJointsOnDeath = false
    humanoid.AutoJumpEnabled = false
    humanoid.MaxHealth = stats.maxHealth
    humanoid.Health = math.min(humanoid.Health, stats.maxHealth)
    humanoid.WalkSpeed = stats.walkSpeed
    humanoid.JumpHeight = 0
    humanoid.JumpPower  = 0
end

function DeathHandler.SendToHub(player, getStateFn)
    local character = player.Character
    if not character then return end
    -- NOTE: Let natural spawn handle positioning - no forced teleport
    -- This prevents anchoring/unanchoring bounce issues
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local state = getStateFn(player)
        local stats = state and state.stats
        humanoid.WalkSpeed  = stats and stats.walkSpeed or 16
        humanoid.JumpHeight = 0
        humanoid.Health     = humanoid.MaxHealth
    end
end

function DeathHandler.HandleDeath(player, getStateFn)
    local state = getStateFn(player)
    if not state or not state.inLevel or state.isDying then return end
    
    state.isDying       = true
    state.blockHubRoute = true
    state.inLevel       = false

    local depthReached = state.currentDepth
    PlayerData.RecordRun(player, depthReached, 0, false)
    Leaderboard.SubmitDepth(player, depthReached)

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 1
            humanoid.WalkSpeed = 0
            humanoid.JumpHeight = 0
        end
    end

    print("[DropDwarf Server]", player.Name, "died at", depthReached, "m")
    Networking.FireClient(Networking.Events.PlayerDied, player, {
        depthReached = depthReached,
        goldEarned   = state.goldThisRun,
    })

    -- Safety timeout: send to hub if no choice made
    task.delay(30, function()
        local s = getStateFn(player)
        if s and s.isDying then
            s.isDying       = false
            s.blockHubRoute = false
            s.inLevel       = false
            DeathHandler.SendToHub(player, getStateFn)
            Networking.FireClient(Networking.Events.RespawnInHub, player, { isReset = false })
        end
    end)
end

function DeathHandler.RespawnInBasket(player, getStateFn)
    local state = getStateFn(player)
    if not state then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if humanoid then
        humanoid.BreakJointsOnDeath = false
        humanoid.Health     = state.maxHealth
        humanoid.WalkSpeed  = state.stats and state.stats.walkSpeed or 16
        humanoid.JumpHeight = 0
        
        humanoid.Died:Once(function()
            local s = getStateFn(player)
            if not s or not s.inLevel then return end
            local modeId = Session.GetMode(player)
            local mode   = GameMode.Get(modeId)
            if mode and mode.coopEnabled and not s.isDying then
                s.isDying  = true
                s.isDowned = true
                humanoid.Health = 1
                Session.SetDowned(player, true)
                local teammates = Session.GetAllMembers(player)
                local hrpRef = character:FindFirstChild("HumanoidRootPart")
                local posArr = hrpRef and { hrpRef.Position.X, hrpRef.Position.Y, hrpRef.Position.Z } or {0,0,0}
                for _, p in ipairs(teammates) do
                    Networking.FireClient(Networking.Events.PlayerDowned, p, {
                        userId = player.UserId,
                        name   = player.Name,
                        pos    = posArr,
                    })
                end
            else
                DeathHandler.HandleDeath(player, getStateFn)
            end
        end)
    end

    -- Reset trapdoors to collidable so they can support the player
    local sessionFolder = state.levelFolder
    if sessionFolder then
        local basket = sessionFolder:FindFirstChild("DwarvenEntryBasket")
        if basket then
            local doorL = basket:FindFirstChild("BasketTrapdoorL")
            local doorR = basket:FindFirstChild("BasketTrapdoorR")
            if doorL then doorL.CanCollide = true end
            if doorR then doorR.CanCollide = true end
        end
    end

    -- Position player on basket trapdoor (no anchor - let physics settle naturally)
    hrp.CFrame = CFrame.new(3, GameData.LEVEL_Y_OFFSET - 10, 0)
    hrp.AssemblyLinearVelocity = Vector3.zero

    Networking.FireClient(Networking.Events.TriggerBasketLaunch, player)

    task.spawn(function()
        task.wait(2.2)
        if sessionFolder then
            local basket = sessionFolder:FindFirstChild("DwarvenEntryBasket")
            if basket then
                local doorL = basket:FindFirstChild("BasketTrapdoorL")
                local doorR = basket:FindFirstChild("BasketTrapdoorR")
                if doorL then doorL.CanCollide = false end
                if doorR then doorR.CanCollide = false end
            end
        end
    end)
    
    state.inLevel       = true
    state.isDying       = false
    state.blockHubRoute = false
end

function DeathHandler.Init(getStateFn)
    -- Death Choice network handler
    Networking.OnServer(Networking.Events.DeathChoice, function(player, choice)
        local state = getStateFn(player)
        if not state or not state.isDying then return end

        local isReset   = (choice == "resetBasket" or choice == "resetHub")
        local isBasket  = (choice == "respawnBasket" or choice == "resetBasket")
        local data      = PlayerData.Get(player)

        if isReset then
            ItemHandler.ResetRunItems(player)
            state.goldThisRun  = 0
            state.currentDepth = 0
            state.startTime    = tick()
            
            local stats = UpgradeData.ComputeStats(data.upgrades)
            state.stats      = stats
            state.maxHealth  = stats.maxHealth
            state.health     = stats.maxHealth
            applyStats(player, stats)
            Networking.FireClient(Networking.Events.TimerSync, player, 0)
        else
            state.health = state.maxHealth
            local character = player.Character
            if character then
                local hum = character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = state.maxHealth end
            end
        end

        if isBasket then
            DeathHandler.RespawnInBasket(player, getStateFn)
            Networking.FireClient(Networking.Events.RespawnInBasket, player, {
                timerSeconds = isReset and 0 or (tick() - state.startTime),
                isReset      = isReset,
            })
        else
            state.isDying       = false
            state.inLevel       = false
            state.blockHubRoute = false
            DeathHandler.SendToHub(player, getStateFn)
            Networking.FireClient(Networking.Events.RespawnInHub, player, {
                isReset = isReset,
            })
        end
    end)

    -- Cooperative Downed rescue handler
    Networking.OnServer(Networking.Events.RequestRescue, function(player, targetUserId)
        local state = getStateFn(player)
        if not state or not state.inLevel then return end
        local modeId = Session.GetMode(player)
        local mode = GameMode.Get(modeId)
        if not mode.coopEnabled then return end

        local targetPlayer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == targetUserId then targetPlayer = p; break end
        end
        if not targetPlayer then return end
        if not Session.IsDowned(targetPlayer) then return end

        local rescuerChar = player.Character
        local targetChar  = targetPlayer.Character
        if not rescuerChar or not targetChar then return end
        local rHrp = rescuerChar:FindFirstChild("HumanoidRootPart")
        local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not rHrp or not tHrp then return end
        if (rHrp.Position - tHrp.Position).Magnitude > mode.rescueRange then
            Session.CancelRescue(targetUserId)
            return
        end

        local now = tick()
        local last = rescueTick[player.UserId]
        local dt = math.min(last and (now - last) or (1/30), 1/20)
        rescueTick[player.UserId] = now

        local complete = Session.UpdateRescue(player, targetPlayer, dt)

        local rs = Session.GetDownedState(targetPlayer)
        Networking.FireClient(Networking.Events.RescueProgress, player, {
            targetId  = targetUserId,
            progress  = rs and rs.rescueProgress or 0,
        })

        if complete then
            Session.SetDowned(targetPlayer, false)
            local tState = getStateFn(targetPlayer)
            if tState then
                tState.isDying  = false
                tState.isDowned = false
                local tHum  = targetChar:FindFirstChildOfClass("Humanoid")
                if tHum then
                    tHum.Health = math.max(1, tState.maxHealth * 0.3)
                end
            end
            
            local team = Session.GetAllMembers(player)
            for _, p in ipairs(team) do
                Networking.FireClient(Networking.Events.PlayerRescued, p, {
                    userId     = targetUserId,
                    rescuerId  = player.UserId,
                    name       = targetPlayer.Name,
                })
            end
            rescueTick[player.UserId] = nil
        end
    end)
end

function DeathHandler.CleanupPlayer(player)
    rescueTick[player.UserId] = nil
end

return DeathHandler
