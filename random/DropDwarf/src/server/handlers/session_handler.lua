-- DropDwarf: handlers/session_handler.lua
-- Multiplayer game lobby matching, isolated levels creation, and dynamic chunk load triggers.

local Players        = game:GetService("Players")
local Networking     = require(game.ReplicatedStorage.Shared.networking)
local GameData       = require(game.ReplicatedStorage.Shared.game_data)
local GameMode       = require(game.ReplicatedStorage.Shared.game_mode)
local PlayerData     = require(script.Parent.Parent.player_data)
local UpgradeData    = require(game.ReplicatedStorage.Shared.upgrade_data)
local LevelGenerator = require(script.Parent.Parent.level_generator)
local Session        = require(script.Parent.Parent.session)
local ItemHandler    = require(script.Parent.Parent.item_handler)

local SessionHandler = {}

local function applyStats(player, stats)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.BreakJointsOnDeath = false
    humanoid.MaxHealth = stats.maxHealth
    humanoid.Health = math.min(humanoid.Health, stats.maxHealth)
    humanoid.WalkSpeed = stats.walkSpeed
    humanoid.JumpHeight = 8
end

function SessionHandler.StartLevel(player, seed, getStateFn)
    local state = getStateFn(player)
    if not state then return end
    local data = PlayerData.Get(player)

    seed = tostring(seed or state.seed or "MattyJacks")
    state.seed = seed
    state.inLevel = true
    state.isDying = false
    state.blockHubRoute = true
    state.startTime = tick()
    state.goldThisRun = 0
    state.currentDepth = 0
    PlayerData.SetLastSeed(player, seed)

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.BreakJointsOnDeath = false
            humanoid.Died:Once(function()
                local s = getStateFn(player)
                if not s or s.isDying then return end
                local modeId = Session.GetMode(player)
                local mode   = GameMode.Get(modeId)
                if mode and mode.coopEnabled then
                    s.isDying  = true
                    s.isDowned = true
                    humanoid.Health = 1
                    Session.SetDowned(player, true)
                    local teammates = Session.GetAllMembers(player)
                    local hrpPos = character:FindFirstChild("HumanoidRootPart")
                    local posArr = hrpPos and { hrpPos.Position.X, hrpPos.Position.Y, hrpPos.Position.Z } or {0,0,0}
                    for _, p in ipairs(teammates) do
                        Networking.FireClient(Networking.Events.PlayerDowned, p, {
                            userId = player.UserId,
                            name   = player.Name,
                            pos    = posArr,
                        })
                    end
                else
                    local DeathHandler = require(script.Parent.death_handler)
                    DeathHandler.HandleDeath(player, getStateFn)
                end
            end)
        end
    end

    local stats = UpgradeData.ComputeStats(data.upgrades)
    state.stats = stats
    state.maxHealth = stats.maxHealth
    state.health = stats.maxHealth

    ItemHandler.ResetRunItems(player)

    -- Isolated multiplayer workspace levels folder
    local sessionId = Session.GetSessionId(player) or player.UserId
    local sessionFolder = LevelGenerator.CreateSessionFolder(sessionId)

    print("[DropDwarf Server] Generating isolated level seed:", seed, "session:", sessionId)
    local _, biomeSequence, allSlimeSpawns = LevelGenerator.Generate(sessionFolder, seed)
    state.levelFolder = sessionFolder
    state.biomeSequence = biomeSequence
    state.currentBiome = nil

    local spawnY = GameData.LEVEL_Y_OFFSET - 10
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = true
            hrp.CFrame = CFrame.new(3, spawnY, 0) -- Spawn on right trapdoor, off-center from the lantern
        end
        applyStats(player, stats)
    end


    local seqNames = {}
    for i, b in ipairs(biomeSequence) do seqNames[i] = b.name end
    Networking.FireClient(Networking.Events.LevelGenerated, player, {
        seed = seed,
        biomeSequence = seqNames,
    })
    Networking.FireClient(Networking.Events.HealthUpdate, player, state.health, state.maxHealth)
    Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
    Networking.FireClient(Networking.Events.TimerSync, player, 0)
    Networking.FireClient(Networking.Events.StatsUpdate, player, stats)
    Networking.FireClient(Networking.Events.ModifierSet, player, state.modifier.id)

    local modeId = Session.GetMode(player)
    local mode   = GameMode.Get(modeId)
    if mode.sharedLevel then
        Session.MarkActive(player, sessionFolder)
        for _, teammate in ipairs(Session.GetTeammates(player)) do
            local tState = getStateFn(teammate)
            if tState and not tState.inLevel then
                local tData   = PlayerData.Get(teammate)
                local tStats  = UpgradeData.ComputeStats(tData.upgrades)
                tState.seed         = seed
                tState.inLevel      = true
                tState.isDying      = false
                tState.isDowned     = false
                tState.startTime    = state.startTime
                tState.goldThisRun  = 0
                tState.currentDepth = 0
                tState.currentBiome = nil
                tState.stats        = tStats
                tState.maxHealth    = tStats.maxHealth
                tState.health       = tStats.maxHealth
                tState.levelFolder  = sessionFolder
                tState.biomeSequence = state.biomeSequence
                ItemHandler.ResetRunItems(teammate)
                applyStats(teammate, tStats)
                
                local tmHrp = teammate.Character and teammate.Character:FindFirstChild("HumanoidRootPart")
                if tmHrp then
                    tmHrp.Anchored = true
                    local sideX = (math.random() < 0.5) and -3 or 3
                    local offset = Vector3.new(sideX + math.random(-0.5, 0.5), 0, math.random(-2, 2))
                    tmHrp.CFrame = CFrame.new(offset + Vector3.new(0, GameData.LEVEL_Y_OFFSET - 10, 0))
                end
                
                local tmSeqNames = {}
                for i, b in ipairs(state.biomeSequence or {}) do tmSeqNames[i] = b.name end
                Networking.FireClient(Networking.Events.LevelGenerated, teammate, {
                    seed = seed, biomeSequence = tmSeqNames,
                })
                Networking.FireClient(Networking.Events.GameModeChanged, teammate, modeId)
                Networking.FireClient(Networking.Events.HealthUpdate, teammate, tState.maxHealth, tState.maxHealth)
                Networking.FireClient(Networking.Events.GoldUpdate, teammate, tData.gold)
                Networking.FireClient(Networking.Events.TimerSync, teammate, 0)
                Networking.FireClient(Networking.Events.StatsUpdate, teammate, tStats)
            end
        end
        Networking.FireClient(Networking.Events.GameModeChanged, player, modeId)
    end

    -- Trigger Dwarven Basket cinematic launch sequence
    local allMembers = Session.GetAllMembers(player)
    for _, member in ipairs(allMembers) do
        Networking.FireClient(Networking.Events.TriggerBasketLaunch, member)
    end

    task.spawn(function()
        task.wait(2.2)
        -- Make trapdoors non-collidable so they drop
        local basket = sessionFolder:FindFirstChild("DwarvenEntryBasket")
        if basket then
            local doorL = basket:FindFirstChild("BasketTrapdoorL")
            local doorR = basket:FindFirstChild("BasketTrapdoorR")
            if doorL then doorL.CanCollide = false end
            if doorR then doorR.CanCollide = false end
        end
        -- Unanchor all players so they drop
        for _, member in ipairs(allMembers) do
            local char = member.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = false
            end
        end
    end)
end

function SessionHandler.Init(getStateFn)
    -- Dynamic Chunk Loading loop request from client
    Networking.OnServer(Networking.Events.RequestChunkLoad, function(player, slotIndex)
        local state = getStateFn(player)
        if not state or not state.inLevel or not state.levelFolder then return end

        print("[DropDwarf Server] Dynamic loading Slot", slotIndex, "for", player.Name)
        local slotModel, slimeSpawns = LevelGenerator.GenerateSlot(state.levelFolder, slotIndex, state.seed)

        local serializedSpawns = {}
        if slimeSpawns then
            for _, s in ipairs(slimeSpawns) do
                table.insert(serializedSpawns, {
                    size = s.size,
                    pos = { s.pos.X, s.pos.Y, s.pos.Z },
                    patrolEnd = { s.patrolEnd.X, s.patrolEnd.Y, s.patrolEnd.Z }
                })
            end
        end

        -- Inform client the chunk geometry is available, along with slimes to spawn
        Networking.FireClient(Networking.Events.ChunkLoaded, player, slotIndex, serializedSpawns)

        -- Clean up slot N - 2 behind the player
        local oldSlot = slotIndex - 2
        if oldSlot > 0 then
            LevelGenerator.UnloadSlot(state.levelFolder, oldSlot)
            Networking.FireClient(Networking.Events.UnloadChunk, player, oldSlot)
        end
    end)

    -- Request start run from hub
    Networking.OnServer(Networking.Events.RequestStartLevel, function(player, seed)
        if type(seed) ~= "string" and type(seed) ~= "number" then seed = "MattyJacks" end
        seed = tostring(seed):sub(1, 32):gsub("%c", "")
        if #seed == 0 then seed = "MattyJacks" end

        local state = getStateFn(player)
        if state and state.inLevel then return end
        SessionHandler.StartLevel(player, seed, getStateFn)
    end)

    -- Host game mode select
    Networking.OnServer(Networking.Events.SetGameMode, function(player, modeId)
        local state = getStateFn(player)
        if state and state.inLevel then return end
        if not GameMode.Get(modeId) then return end
        Session.SetMode(player, modeId)
    end)

    -- Join teammate session
    Networking.OnServer(Networking.Events.RequestJoinSession, function(player, hostUserId)
        local state = getStateFn(player)
        if state and state.inLevel then return end
        Session.JoinSession(player, hostUserId)
    end)

    -- Leave session
    Networking.OnServer(Networking.Events.LeaveSession, function(player)
        Session.LeaveSession(player)
    end)
end

return SessionHandler
