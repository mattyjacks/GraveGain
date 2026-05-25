-- DwarfDrop: handlers/death_handler.lua
-- Server-side death, respawn, rescue mechanics

local Players    = game:GetService("Players")

local Networking        = require(game.ReplicatedStorage.Shared.networking)
local GameData          = require(game.ReplicatedStorage.Shared.game_data)
local GameMode          = require(game.ReplicatedStorage.Shared.game_mode)

local Session           = require(script.Parent.Parent.session)
local PlayerData        = require(script.Parent.Parent.player_data)
local ItemHandler       = require(script.Parent.Parent.item_handler)
local Leaderboard       = require(script.Parent.Parent.leaderboard)

local DeathHandler = {}

-- FIX Bug#7: use player.UserId as key consistently throughout (no player-object keys)
local rescueTick = {}  -- rescueTick[targetUserId] = { rescuerId, startTime, progress }

local RESCUE_TIME = GameMode.Modes.Cooperative.rescueTime or 4.0

-- ==================== DEATH ====================

local function handleDeath(player)
    local sess   = Session.GetSessionForPlayer(player)
    local modeId = sess and sess.modeId or "Singleplayer"
    local mode   = GameMode.Get(modeId)

    local state = nil
    -- We reach into main's state via the injected callback if available
    if DeathHandler.GetPlayerState then
        state = DeathHandler.GetPlayerState(player)
    end

    local depth      = state and state.depth or 0
    local timer      = state and state.timer or 0
    local goldEarned = state and state.gold  or 0

    -- Record run depth
    PlayerData.RecordRun(player, timer, depth)

    -- Submit depth to leaderboard
    task.spawn(function()
        Leaderboard.SubmitDepth(player, depth)
    end)

    -- ===== COOP: go downed instead of dying =====
    if mode.downedEnabled then
        Session.SetDowned(player)
        Networking.FireClient(Networking.Events.PlayerDowned, player, {
            userId = player.UserId,
            depth  = depth,
        })
        -- Also notify teammates
        if sess then
            for _, member in ipairs(Session.GetMembers(sess.host.UserId)) do
                if member ~= player then
                    Networking.FireClient(Networking.Events.PlayerDowned, member, {
                        userId = player.UserId,
                        depth  = depth,
                    })
                end
            end
        end
        return
    end

    -- ===== STANDARD DEATH: send death screen =====
    Networking.FireClient(Networking.Events.PlayerDied, player, {
        depth      = depth,
        time       = timer,
        goldEarned = goldEarned,
    })
end

-- ==================== RESPAWN ====================

local function getBasketSpawnPos(sess)
    -- FIX Bug#3: safely look up basket from session folder with nil guard
    if not sess or not sess.levelFolder then
        return Vector3.new(0, GameData.LEVEL_Y_OFFSET + 15, 0)
    end
    local basketFolder = sess.levelFolder:FindFirstChild("DwarvenEntryBasket")
    if not basketFolder then
        return Vector3.new(0, GameData.LEVEL_Y_OFFSET + 15, 0)
    end
    local spawnPad = basketFolder:FindFirstChild("SpawnPad")
    if spawnPad then
        return spawnPad.Position + Vector3.new(
            (math.random() - 0.5) * 4, 3, (math.random() - 0.5) * 4)
    end
    return basketFolder:FindFirstChildWhichIsA("BasePart") and
        basketFolder:FindFirstChildWhichIsA("BasePart").Position + Vector3.new(0, 5, 0)
        or Vector3.new(0, GameData.LEVEL_Y_OFFSET + 15, 0)
end

local function sendToHub(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(Vector3.new(0, GameData.HUB_Y + 4, 30))
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = hum.MaxHealth
    end
    Networking.FireClient(Networking.Events.RespawnInHub, player)
end

local function respawnInBasket(player, resetTimer)
    local sess   = Session.GetSessionForPlayer(player)
    local pos    = getBasketSpawnPos(sess)

    local char = player.Character
    if not char then
        player:LoadCharacter()
        task.wait(1)
        char = player.Character
    end

    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(pos)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth
        end
    end

    if resetTimer and DeathHandler.SetPlayerInLevel then
        local state = DeathHandler.GetPlayerState and DeathHandler.GetPlayerState(player)
        if state then
            if resetTimer then
                state.timer = 0
                ItemHandler.ClearBackpack(player)
            end
        end
    end

    Networking.FireClient(Networking.Events.RespawnInBasket, player, { reset = resetTimer })
end

-- ==================== DEATH CHOICE ====================

Networking_DeathChoiceHandler = nil

local function onDeathChoice(player, choice)
    if choice == "respawnBasket" then
        respawnInBasket(player, false)
    elseif choice == "respawnHub" then
        sendToHub(player)
    elseif choice == "resetBasket" then
        respawnInBasket(player, true)
    elseif choice == "resetHub" then
        ItemHandler.ClearBackpack(player)
        sendToHub(player)
    end
end

-- ==================== RESCUE (COOP) ====================

-- C->S: player holds E near downed teammate
local function onRequestRescue(player, targetUserId)
    targetUserId = tonumber(targetUserId)
    if not targetUserId then return end

    local sess = Session.GetSessionForPlayer(player)
    if not sess or not GameMode.IsCoop(sess.modeId) then return end

    local target = Players:GetPlayerByUserId(targetUserId)
    if not target or not Session.IsDowned(target) then return end

    -- Range check
    local rescuerChar = player.Character
    local targetChar  = target.Character
    if not rescuerChar or not targetChar then return end
    local rescuerHRP = rescuerChar:FindFirstChild("HumanoidRootPart")
    local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart")
    if not rescuerHRP or not targetHRP then return end

    local dist = (rescuerHRP.Position - targetHRP.Position).Magnitude
    local rescueRadius = GameMode.Modes.Cooperative.rescueRadius or 8
    if dist > rescueRadius then return end

    -- FIX Bug#7: use targetUserId as key (number)
    if not rescueTick[targetUserId] then
        rescueTick[targetUserId] = {
            rescuerId = player.UserId,
            startTime = tick(),
            progress  = 0,
        }
    end

    local rt = rescueTick[targetUserId]
    rt.progress = math.clamp((tick() - rt.startTime) / RESCUE_TIME, 0, 1)
    Networking.FireClient(Networking.Events.RescueProgress, player, rt.progress)

    if rt.progress >= 1 then
        -- Rescue complete
        Session.ClearDowned(target)
        rescueTick[targetUserId] = nil  -- FIX Bug#7: clear by userId

        -- Revive target
        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
        if targetHum then
            targetHum.Health = targetHum.MaxHealth * 0.3
        end
        -- Notify all session members
        for _, m in ipairs(Session.GetMembers(sess.host.UserId)) do
            Networking.FireClient(Networking.Events.PlayerRescued, m, {
                userId = targetUserId,
            })
        end
        Networking.FireClient(Networking.Events.RescueProgress, player, nil)
    end
end

-- ==================== HUMANOID DIED HOOK ====================

local function onCharacterAdded(player, char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum.Died:Connect(function()
        task.wait(0.1)
        handleDeath(player)
    end)
end

-- ==================== INIT ====================

-- External injections from main.server
DeathHandler.GetPlayerState   = nil
DeathHandler.SetPlayerInLevel = nil

function DeathHandler.Init()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(player, char)
        end)
        if player.Character then
            onCharacterAdded(player, player.Character)
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            onCharacterAdded(player, player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(player, char)
        end)
    end

    Networking.OnServer(Networking.Events.DeathChoice, onDeathChoice)
    Networking.OnServer(Networking.Events.RequestRescue, onRequestRescue)
end

return DeathHandler
