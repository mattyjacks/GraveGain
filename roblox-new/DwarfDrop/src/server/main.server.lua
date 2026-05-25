-- DwarfDrop: main.server.lua
-- Server entry point: init remotes, hub, gravity, player lifecycle, game tick

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")

-- CreateRemotes MUST run before any module that calls Networking.OnServer at load time
local Networking = require(game.ReplicatedStorage.Shared.networking)
Networking.CreateRemotes()

-- Now safe to require modules that bind events at load time
local GameData          = require(game.ReplicatedStorage.Shared.game_data)
local UpgradeData       = require(game.ReplicatedStorage.Shared.upgrade_data)

local PlayerData        = require(script.Parent.player_data)
local PlayerStateManager = require(script.Parent.player_state_manager)
local Session           = require(script.Parent.session)
local Leaderboard       = require(script.Parent.leaderboard)
local HubGenerator      = require(script.Parent.hub_generator)
local ItemHandler       = require(script.Parent.item_handler)

local SessionHandler    = require(script.Parent.handlers.session_handler)
local DeathHandler      = require(script.Parent.handlers.death_handler)
local MiningHandler     = require(script.Parent.handlers.mining_handler)
local PvPHandler        = require(script.Parent.handlers.pvp_handler)

-- ==================== INIT ====================

-- Gravity
workspace.Gravity = 100

-- Prevent Roblox void from killing players mid-drop.
-- Level bottom is at Y = LEVEL_Y_OFFSET - TOTAL_DEPTH_STUDS = -50 - 3200 = -3250.
-- Set destroy height well below that so parts and humanoids survive the full descent.
workspace.FallenPartsDestroyHeight = -4000

-- Lighting baseline
Lighting.Ambient            = Color3.fromRGB(60, 55, 70)
Lighting.OutdoorAmbient     = Color3.fromRGB(40, 38, 45)
Lighting.Brightness         = 1.0
Lighting.ClockTime          = 20
Lighting.FogStart           = 0
Lighting.FogEnd             = 800
Lighting.FogColor           = Color3.fromRGB(20, 16, 24)

-- Build hub
HubGenerator.Build()

-- Init sub-systems
SessionHandler.Init()
DeathHandler.Init()
MiningHandler.Init()
PvPHandler.Init()

-- ==================== PLAYER STATE ====================
-- Per-player in-level tracking
-- playerStates[userId] = {
--   inLevel = bool, depth = num, timer = num, gold = num,
--   modifier = table, lastHealTick = num, lastDepthY = num
-- }
local playerStates = {}

local function getState(player)
    return playerStates[player.UserId]
end

local function setState(player, data)
    playerStates[player.UserId] = data
end

-- ==================== PLAYER LIFECYCLE ====================

local function onPlayerAdded(player)
    -- Load data
    local data = PlayerData.Load(player)

    -- Create solo session by default
    Session.CreateSession(player)

    -- Init item backpack
    ItemHandler.InitPlayer(player)

    -- Wire GetPlayerData remote function
    local rf = Networking.GetFunction(Networking.Functions.GetPlayerData)
    if rf then
        rf.OnServerInvoke = function(requester)
            if requester ~= player then return nil end
            return PlayerData.Get(player)
        end
    end

    -- Push initial stats once character loads
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)  -- wait for Humanoid to initialize
        local upgrades = data.upgrades or UpgradeData.DefaultUpgrades()
        PlayerStateManager.PushStats(player, upgrades, ItemHandler.GetBackpack(player))

        -- Send player data to hub UI
        Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold or 0)
        Networking.FireClient(Networking.Events.StatsUpdate, player,
            UpgradeData.ComputeStats(upgrades))
    end)
end

local function onPlayerRemoving(player)
    -- Save and clean up
    PlayerData.Save(player)
    PlayerData.Unload(player)
    Session.RemoveMember(player)
    ItemHandler.CleanupPlayer(player)
    playerStates[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game (Studio play mode)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

-- ==================== GAME EVENT HANDLERS ====================

-- Purchase upgrade
Networking.OnServer(Networking.Events.PurchaseUpgrade, function(player, upgradeId)
    if not upgradeId then return end
    local success, reason = PlayerData.PurchaseUpgrade(player, upgradeId)
    if success then
        local data = PlayerData.Get(player)
        Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
        PlayerStateManager.PushStats(player, data.upgrades, ItemHandler.GetBackpack(player))
    end
end)

-- Save camera preference
Networking.OnServer(Networking.Events.SaveCameraPreference, function(player, camType)
    if camType == "fps" or camType == "tps" then
        PlayerData.SetCameraPreference(player, camType)
    end
end)

-- Set modifier
Networking.OnServer(Networking.Events.SetModifier, function(player, modId)
    local state = getState(player)
    if state and state.inLevel then return end  -- cannot change mid-run
    local mod = GameData.RunModifiers[modId]
    if not mod then return end
    -- Store for next run start
    local data = PlayerData.Get(player)
    if data then data.pendingModifier = modId end
end)

-- Apply fall damage (client-reported, server-authoritative)
Networking.OnServer(Networking.Events.ApplyFallDamage, function(player, fallMeters)
    if type(fallMeters) ~= "number" then return end
    fallMeters = math.clamp(fallMeters, 0, 500)
    local safe = GameData.FALL_DAMAGE_THRESHOLD_METERS
    if fallMeters <= safe then return end

    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local state = getState(player)
    local damageMult = 1.0
    if state and state.modifier then
        damageMult = state.modifier.damageMult or 1.0
    end

    -- Fall resist from upgrades
    local data = PlayerData.Get(player)
    local fallResist = 0
    if data then
        fallResist = UpgradeData.GetValue("fall_resist", data.upgrades.fall_resist or 0)
    end

    -- Weight multiplier
    local weightFallMult = 1.0
    if state and state.weightFallMult then
        weightFallMult = state.weightFallMult
    end

    local excessMeters = fallMeters - safe
    -- Power-curve scaling: smooth ramp, small falls barely hurt
    local scale    = GameData.FALL_DAMAGE_SCALE    or 0.8
    local exponent = GameData.FALL_DAMAGE_EXPONENT or 1.5
    local rawDamage = (excessMeters ^ exponent) * scale
    -- Apply modifiers and resist AFTER capping base damage to prevent insta-kill spikes
    rawDamage = math.min(rawDamage, GameData.FALL_DAMAGE_MAX)
    local damage = rawDamage * damageMult * weightFallMult * (1 - fallResist)
    damage = math.min(damage, GameData.FALL_DAMAGE_MAX)

    hum.Health = math.max(0, hum.Health - damage)
    Networking.FireClient(Networking.Events.HealthUpdate, player, hum.Health, hum.MaxHealth)
end)

-- Coin collection
-- FIX Bug#10: single CollectCoin event; combo handled server-side
Networking.OnServer(Networking.Events.CollectCoin, function(player, coinId)
    local state = getState(player)
    if not state or not state.inLevel then return end

    local data = PlayerData.Get(player)
    if not data then return end

    local modifier = state.modifier or GameData.RunModifiers.Normal
    local goldMult = modifier.goldMult or 1.0

    local earned = math.floor(GameData.COIN_VALUE * goldMult)
    PlayerData.AddGold(player, earned)
    state.gold = (state.gold or 0) + earned

    Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
end)

-- Treasure chest collection
Networking.OnServer(Networking.Events.CollectTreasureChest, function(player, chestId)
    if type(chestId) ~= "string" then return end
    local state = getState(player)
    if not state or not state.inLevel then return end
    local data = PlayerData.Get(player)
    if not data then return end

    -- Find chest by ChestId tag in workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "ChestBody" then
            local idTag = obj:FindFirstChild("ChestId")
            if idTag and idTag.Value == chestId then
                -- Guard against double-collect
                if obj:FindFirstChild("_Opened") then return end
                local guard = Instance.new("BoolValue")
                guard.Name   = "_Opened"
                guard.Parent = obj

                local goldTag = obj:FindFirstChild("ChestGold")
                local goldVal = goldTag and goldTag.Value or 200

                -- Apply modifier goldMult
                local modifier = state.modifier or GameData.RunModifiers.Normal
                local earned = math.floor(goldVal * (modifier.goldMult or 1.0))

                PlayerData.AddGold(player, earned)
                state.gold = (state.gold or 0) + earned
                Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
                Networking.FireClient(Networking.Events.TreasureChestOpened, player,
                    { gold = earned })

                -- Destroy chest model after a brief moment
                local model = obj.Parent
                task.delay(0.5, function()
                    if model and model.Parent then model:Destroy() end
                end)
                return
            end
        end
    end
end)

-- Air jump (server needs to know for fall damage calc consistency)
Networking.OnServer(Networking.Events.AirJumpUsed, function(player)
    -- Acknowledged; client handles physics
end)

-- Slime hit
Networking.OnServer(Networking.Events.SlimeHit, function(player, damage)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    damage = math.clamp(tonumber(damage) or 10, 0, 50)
    hum.Health = math.max(0, hum.Health - damage)
    Networking.FireClient(Networking.Events.HealthUpdate, player, hum.Health, hum.MaxHealth)
end)

-- Player reached bottom (win!)
Networking.OnServer(Networking.Events.PlayerReachedBottom, function(player)
    local state = getState(player)
    if not state or not state.inLevel then return end
    state.inLevel = false

    local data = PlayerData.Get(player)
    local timeSeconds = state.timer or 0
    PlayerData.RecordRun(player, timeSeconds, 1000)

    -- Submit to leaderboard
    task.spawn(function()
        Leaderboard.SubmitTime(player, timeSeconds)
        Leaderboard.SubmitDepth(player, 1000)

        local tops = Leaderboard.GetTopTimes(10)
        local topDepths = Leaderboard.GetTopDepths(10)
        Networking.FireClient(Networking.Events.LeaderboardUpdate, player,
            { times = tops, depths = topDepths })
    end)

    -- Determine rank (approximate)
    Networking.FireClient(Networking.Events.PlayerWon, player, {
        timeSeconds = timeSeconds,
        goldEarned  = state.gold or 0,
        rank        = 999,
    })
end)

-- Leaderboard request
Networking.OnServer(Networking.Events.RequestLeaderboard, function(player)
    task.spawn(function()
        local tops      = Leaderboard.GetTopTimes(10)
        local topDepths = Leaderboard.GetTopDepths(10)
        Networking.FireClient(Networking.Events.LeaderboardUpdate, player,
            { times = tops, depths = topDepths })
    end)
end)

-- ==================== REGISTER StartLevel IN MAIN ====================
-- The actual handler is in session_handler but we expose PlayerStates

function SessionHandler.SetPlayerInLevel(player, state)
    setState(player, state)
end

function SessionHandler.GetPlayerState(player)
    return getState(player)
end

-- ==================== GAME TICK ====================

local TICK_RATE = 0.1  -- 10 Hz
local accumulator = 0

RunService.Heartbeat:Connect(function(dt)
    accumulator = accumulator + dt
    if accumulator < TICK_RATE then return end
    local tickDt = accumulator
    accumulator = 0

    -- Tick all in-level players
    for _, player in ipairs(Players:GetPlayers()) do
        local state = getState(player)
        if not state or not state.inLevel then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        -- Timer
        state.timer = (state.timer or 0) + tickDt

        -- Depth tracking from character Y position
        if hrp then
            local depth = GameData.WorldYToDepth(hrp.Position.Y)
            depth = math.clamp(depth, 0, GameData.TOTAL_DEPTH_METERS)
            if math.abs(depth - (state.depth or 0)) > 0.5 then
                state.depth = depth
                Networking.FireClient(Networking.Events.DepthUpdate, player, depth)
            end
        end

        -- Health regeneration
        if hum and hum.Health > 0 then
            local data = PlayerData.Get(player)
            local modifier = state.modifier or GameData.RunModifiers.Normal
            if data and not modifier.noRegen then
                local healRate = UpgradeData.GetValue("heal_rate", data.upgrades.heal_rate or 0)
                if healRate > 0 and hum.Health < hum.MaxHealth then
                    hum.Health = math.min(hum.MaxHealth, hum.Health + healRate * tickDt)
                    Networking.FireClient(Networking.Events.HealthUpdate, player,
                        hum.Health, hum.MaxHealth)
                end
            end
        end
    end

    -- Tick coop downed bleed timers
    local expired = Session.TickDowned(tickDt)
    for _, uid in ipairs(expired) do
        local player = Players:GetPlayerByUserId(uid)
        if player then
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
            end
        end
    end

    -- Periodic PvP cooldown cleanup
    Session.CleanupPvPCooldowns()
end)
