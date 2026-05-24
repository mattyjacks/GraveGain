-- DropDwarf: main.server.lua
-- Server entry point: initializes all game sub-handlers and handles ticks/regens.

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local workspace     = game:GetService("Workspace")
local Lighting      = game:GetService("Lighting")

local Networking    = require(game.ReplicatedStorage.Shared.networking)
local GameData      = require(game.ReplicatedStorage.Shared.game_data)
local UpgradeData   = require(game.ReplicatedStorage.Shared.upgrade_data)
local ItemData      = require(game.ReplicatedStorage.Shared.item_data)
local BiomeData     = require(game.ReplicatedStorage.Shared.biome_data)
local GameMode      = require(game.ReplicatedStorage.Shared.game_mode)

local PlayerData    = require(script.Parent.player_data)
local Leaderboard   = require(script.Parent.leaderboard)
local HubGenerator  = require(script.Parent.hub_generator)
local ItemHandler   = require(script.Parent.item_handler)
local Session       = require(script.Parent.session)

-- Handlers
local MiningHandler  = require(script.Parent.handlers.mining_handler)
local DeathHandler   = require(script.Parent.handlers.death_handler)
local PvpHandler     = require(script.Parent.handlers.pvp_handler)
local SessionHandler = require(script.Parent.handlers.session_handler)

-- Initialize networking remotes and item handlers
Networking.CreateRemotes()
ItemHandler.Init()

-- Generate lobby hub
print("[DropDwarf Server] Generating hub...")
HubGenerator.Generate(workspace)

-- Reduce gravity for smoother, more controlled falling
workspace.Gravity = 100

-- Future lighting configurations for AAA shadows
pcall(function()
    Lighting.Technology               = Enum.Technology.Future
    Lighting.GlobalShadows            = true
    Lighting.ShadowSoftness           = 0.25
    Lighting.EnvironmentDiffuseScale  = 1.0
    Lighting.EnvironmentSpecularScale = 1.0
end)
Lighting.Ambient                  = Color3.fromRGB(110, 105, 95)
Lighting.OutdoorAmbient           = Color3.fromRGB(120, 115, 105)
Lighting.Brightness               = 3.5
Lighting.FogColor                 = Color3.fromRGB(20, 16, 12)
Lighting.FogEnd                   = 1000
Lighting.FogStart                 = 400

local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atmo.Density = 0.35
atmo.Offset  = 0.06
atmo.Color   = Color3.fromRGB(200, 160, 100)
atmo.Decay   = Color3.fromRGB(80, 60, 30)

local playerStates = {}

local function getState(player)
    return playerStates[player]
end

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

local function broadcastTeamHealth(player)
    local teammates = Session.GetAllMembers(player)
    if #teammates <= 1 then return end
    local healthData = {}
    for _, p in ipairs(teammates) do
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        healthData[tostring(p.UserId)] = {
            name    = p.Name,
            health  = hum and math.floor(hum.Health) or 0,
            max     = hum and math.floor(hum.MaxHealth) or 100,
            downed  = Session.IsDowned(p),
        }
    end
    for _, p in ipairs(teammates) do
        Networking.FireClient(Networking.Events.TeamHealthUpdate, p, healthData)
    end
end

local function handleWin(player)
    local state = getState(player)
    if not state or not state.inLevel then return end

    local timeSeconds = tick() - state.startTime
    local data = PlayerData.Get(player)
    PlayerData.RecordRun(player, GameData.TOTAL_DEPTH_METERS, timeSeconds, true)
    Leaderboard.SubmitTime(player, timeSeconds)
    Leaderboard.SubmitDepth(player, GameData.TOTAL_DEPTH_METERS)

    local absoluteRank = Leaderboard.GetPlayerTimeRank(player.UserId, timeSeconds)
    local timeStr      = Leaderboard.FormatTime(timeSeconds)

    state.inLevel       = false
    state.isDying       = false
    state.blockHubRoute = false
    
    print("[DropDwarf Server]", player.Name, "WON! Time:", timeStr, "Rank:", absoluteRank)
    Networking.FireClient(Networking.Events.PlayerWon, player, {
        timeSeconds  = timeSeconds,
        timeStr      = timeStr,
        absoluteRank = absoluteRank,
        goldEarned   = state.goldThisRun,
    })

    task.delay(5, function()
        DeathHandler.SendToHub(player, getState)
    end)
end

-- Initialize our modular sub-handlers
MiningHandler.Init(getState)
DeathHandler.Init(getState)
PvpHandler.Init(getState)
SessionHandler.Init(getState)

-- Server authoritative tick loop: tracking depth, passive regenerations, and out of bounds falls
local TICK_RATE = 0.1
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator = accumulator + dt
    if accumulator < TICK_RATE then return end
    accumulator = 0

    for player, state in pairs(playerStates) do
        if not state.inLevel then continue end
        local character = player.Character
        if not character then continue end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then continue end

        local worldY = hrp.Position.Y
        local depthM = math.max(0, GameData.WorldYToDepth(worldY))

        if depthM > state.currentDepth then
            state.currentDepth = depthM
            Networking.FireClient(Networking.Events.DepthUpdate, player, depthM)
        end

        local biome = BiomeData.GetBiomeAtDepthInSequence(state.biomeSequence or BiomeData.GenerateSequence(state.seed), depthM)
        if state.currentBiome ~= biome.name then
            state.currentBiome = biome.name
            Networking.FireClient(Networking.Events.BiomeChanged, player, biome.name)
        end

        if state.stats.healRate > 0 and not (state.modifier and state.modifier.noRegen) then
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + state.stats.healRate * TICK_RATE)
        end

        local itemState = ItemHandler.GetState(player)
        if itemState and itemState.healTick then
            local healAmt = ItemData.Items.HealingPotion.healPerSec * TICK_RATE
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmt)
            itemState.healTick.remaining = itemState.healTick.remaining - TICK_RATE
            if itemState.healTick.remaining <= 0 then itemState.healTick = nil end
        end

        state.health = humanoid.Health
        Networking.FireClient(Networking.Events.HealthUpdate, player, math.floor(humanoid.Health), humanoid.MaxHealth)

        if state.startTime then
            state.timerSyncAcc = (state.timerSyncAcc or 0) + TICK_RATE
            if state.timerSyncAcc >= 0.5 then
                state.timerSyncAcc = 0
                Networking.FireClient(Networking.Events.TimerSync, player, tick() - state.startTime)
            end
        end

        if worldY < GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS) - 50 then
            DeathHandler.HandleDeath(player, getState)
        end
    end
end)

-- Coop downed team updates tick
local teamHealthAcc = 0
RunService.Heartbeat:Connect(function(dt)
    local expired = Session.TickBleedTimers(dt)
    for _, p in ipairs(expired) do
        local s = getState(p)
        if s then
            s.isDowned = false
            Session.SetDowned(p, false)
            DeathHandler.HandleDeath(p, getState)
        end
    end

    teamHealthAcc = teamHealthAcc + dt
    if teamHealthAcc >= 0.25 then
        teamHealthAcc = 0
        local seen = {}
        for player, state in pairs(playerStates) do
            if state.inLevel then
                local sid = Session.GetSessionId(player)
                if sid and not seen[sid] then
                    seen[sid] = true
                    broadcastTeamHealth(player)
                end
            end
        end
    end
end)

-- Coin rate limiter
local coinLastCollect = {}
Networking.OnServer(Networking.Events.CollectCoin, function(player, coinId)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local now = tick()
    if now - (coinLastCollect[player.UserId] or 0) < 0.12 then return end
    coinLastCollect[player.UserId] = now

    local data = PlayerData.Get(player)
    local earned = math.floor(GameData.COIN_VALUE * (state.modifier and state.modifier.goldMult or 1))
    PlayerData.AddGold(player, earned)
    state.goldThisRun = (state.goldThisRun or 0) + earned
    Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
end)

-- Fall damage calculations
Networking.OnServer(Networking.Events.ApplyFallDamage, function(player, fallMeters)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or type(fallMeters) ~= "number" or fallMeters ~= fallMeters then return end

    fallMeters = math.clamp(fallMeters, 0, 400)
    local velY = math.abs(hrp.AssemblyLinearVelocity.Y)
    local physicsMaxMeters = (velY * velY) / (2 * workspace.Gravity / GameData.STUDS_PER_METER)
    physicsMaxMeters = math.max(physicsMaxMeters, GameData.FALL_DAMAGE_THRESHOLD_METERS + 5)
    fallMeters = math.min(fallMeters, physicsMaxMeters)

    local safeMeters = GameData.FALL_DAMAGE_THRESHOLD_METERS
    if fallMeters <= safeMeters then return end
    
    local excessMeters = fallMeters - safeMeters
    local rawDamage    = excessMeters * GameData.FALL_DAMAGE_PER_METER
    rawDamage          = rawDamage * (1 - (state.stats.fallResist or 0))
    
    local finalDamage  = math.min(rawDamage * (state.modifier and state.modifier.damageMult or 1) * (1 + ItemHandler.GetBackpackWeightKg(player) * ItemData.WEIGHT_FALL_PER_KG), GameData.FALL_DAMAGE_MAX)
    humanoid.Health    = humanoid.Health - finalDamage
    state.health       = humanoid.Health
    Networking.FireClient(Networking.Events.HealthUpdate, player, humanoid.Health, humanoid.MaxHealth)
end)

-- Purchase upgrade
Networking.OnServer(Networking.Events.PurchaseUpgrade, function(player, upgradeId)
    local success = PlayerData.PurchaseUpgrade(player, upgradeId)
    if success then
        local data = PlayerData.Get(player)
        local stats = UpgradeData.ComputeStats(data.upgrades)
        local state = getState(player)
        if state then
            state.stats = stats
            state.maxHealth = stats.maxHealth
        end
        applyStats(player, stats)
        Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
        Networking.FireClient(Networking.Events.StatsUpdate, player, stats)
        PlayerData.Save(player)
    end
end)

-- Set run modifier
Networking.OnServer(Networking.Events.SetModifier, function(player, modId)
    local state = getState(player)
    if not state or state.inLevel then return end
    state.modifier = GameData.RunModifiers[modId] or GameData.RunModifiers.Normal
    Networking.FireClient(Networking.Events.ModifierSet, player, state.modifier.id)
end)

Networking.OnServer(Networking.Events.RequestLeaderboard, function(player)
    Networking.FireClient(Networking.Events.LeaderboardUpdate, player, Leaderboard.GetTopTimes(10), Leaderboard.GetTopDepths(10))
end)

-- Save camera preference
Networking.OnServer(Networking.Events.SaveCameraPreference, function(player, camType)
    PlayerData.SetDefaultCamera(player, camType)
end)

Networking.OnServer(Networking.Events.PlayerReachedBottom, function(player)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or hrp.Position.Y > GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS) + 30 then return end
    handleWin(player)
end)

-- Authoritative Item Crate Collection
Networking.OnServer(Networking.Events.CollectItem, function(player, crateId)
    local state = getState(player)
    if not state or not state.inLevel or not state.levelFolder then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Find the item crate part in the levelFolder
    local targetCrate = nil
    for _, desc in ipairs(state.levelFolder:GetDescendants()) do
        if desc.Name == "BaseCrate" and desc:FindFirstChild("IsItemCrate") then
            local idTag = desc:FindFirstChild("CrateId")
            if idTag and idTag.Value == crateId then
                targetCrate = desc
                break
            end
        end
    end

    if not targetCrate then return end

    -- Distance validation (must be within 18 studs)
    if (hrp.Position - targetCrate.Position).Magnitude > 18 then return end

    local itemIdTag = targetCrate:FindFirstChild("ItemId")
    local itemId = itemIdTag and itemIdTag.Value

    if itemId then
        ItemHandler.GiveItem(player, itemId, 1)
        
        -- Broadcast collection toast notification
        local teammates = Session.GetAllMembers(player)
        for _, p in ipairs(teammates) do
            Networking.FireClient(Networking.Events.ItemGiven, p, {
                fromId = 0,
                toId = player.UserId,
                itemId = itemId,
                count = 1,
            })
        end
    end

    -- Destroy the crate model
    local model = targetCrate.Parent
    if model and model:IsA("Model") then
        model:Destroy()
    else
        targetCrate:Destroy()
    end
end)

-- Authoritative Slime Damage & Knockback
local playerLastSlimeHit = {}
Networking.OnServer(Networking.Events.SlimeHit, function(player, hitInfo)
    local state = getState(player)
    if not state or not state.inLevel then return end

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local now = tick()
    local lastHit = playerLastSlimeHit[player] or 0
    if now - lastHit < 0.3 then return end
    playerLastSlimeHit[player] = now

    local damage = hitInfo.damage or 10
    local knockbackDir = hitInfo.knockbackDir or { 0, 1, 0 }
    local knockbackForce = hitInfo.knockbackForce or 30

    hum.Health = math.max(0, hum.Health - damage)
    broadcastTeamHealth(player)

    -- Send PlayerHit client event to trigger screen shake, red flash, and physics knockback
    Networking.FireClient(Networking.Events.PlayerHit, player, {
        damage = damage,
        knockbackDir = knockbackDir,
        knockbackForce = knockbackForce,
        attackerName = "Slime",
    })
end)

-- Authoritative Slime Defeat Coin Spawner
Networking.OnServer(Networking.Events.SlimeKilled, function(player, slimeId, slimeSize, slimePos)
    local state = getState(player)
    if not state or not state.inLevel or not state.levelFolder then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local slimeVec = (type(slimePos) == "table") and Vector3.new(slimePos[1], slimePos[2], slimePos[3]) or slimePos
    if not slimeVec then return end

    -- Verify distance to prevent exploit spawning
    if (hrp.Position - slimeVec).Magnitude > 50 then return end

    -- Spawn physical collectible gold coins at slime death position
    local coinCount = slimeSize == "Large" and 8
        or slimeSize == "Medium" and 4
        or slimeSize == "Small" and 2
        or 1

    for i = 1, coinCount do
        local offset = Vector3.new(math.random(-3, 3), math.random(1, 3), math.random(-3, 3))
        PartBuilders.SpawnCoin(state.levelFolder, slimeVec + offset)
    end
end)

-- Remote Invokes
local getDataFn = Networking.GetFunction(Networking.Functions.GetPlayerData)
if getDataFn then
    getDataFn.OnServerInvoke = function(player)
        local data = PlayerData.Get(player)
        return data and {
            gold          = data.gold,
            upgrades      = data.upgrades,
            bestTime      = data.bestTime,
            bestDepth     = data.bestDepth,
            totalRuns     = data.totalRuns,
            wins          = data.wins,
            lastSeed      = data.lastSeed,
            defaultCamera = data.defaultCamera or "fps",
        } or nil
    end
end

local validateSeedFn = Networking.GetFunction(Networking.Functions.ValidateSeed)
if validateSeedFn then
    validateSeedFn.OnServerInvoke = function(player, seed)
        if type(seed) ~= "string" and type(seed) ~= "number" then return false, "Invalid seed type" end
        local str = tostring(seed)
        return (#str >= 1 and #str <= 32), (#str < 1 or #str > 32) and "Seed must be 1-32 characters" or "Valid"
    end
end

-- Player Lifecycles
Players.PlayerAdded:Connect(function(player)
    PlayerData.OnPlayerAdded(player)
    ItemHandler.InitPlayer(player)
    
    local data = PlayerData.Get(player)
    local stats = UpgradeData.ComputeStats(data.upgrades)
    
    playerStates[player] = {
        inLevel      = false,
        levelFolder  = nil,
        seed         = data.lastSeed or "MattyJacks",
        startTime    = nil,
        bestDepth    = data.bestDepth or 0,
        currentDepth = 0,
        goldThisRun  = 0,
        health       = stats.maxHealth,
        maxHealth    = stats.maxHealth,
        stats        = stats,
        isFalling    = false,
        fallStartY   = nil,
        modifier     = GameData.RunModifiers.Normal,
        comboStreak  = 0,
        comboTimer   = 0,
        isDowned     = false,
        blockHubRoute = false,
    }

    player.CharacterAdded:Connect(function(character)
        local state = getState(player)
        if state and state.blockHubRoute then return end

        task.defer(function()
            if not character.Parent then return end
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if hrp then hrp.CFrame = CFrame.new(0, GameData.HUB_FLOOR_Y + 5, 0) end
        end)

        local d = PlayerData.Get(player)
        if d then
            local s = UpgradeData.ComputeStats(d.upgrades)
            applyStats(player, s)
            local st = getState(player)
            if st and not st.inLevel then
                task.defer(function()
                    if character.Parent then
                        DeathHandler.SendToHub(player, getState)
                    end
                end)
            end
        end
    end)

    task.delay(2, function()
        if player and player.Parent then
            Networking.FireClient(Networking.Events.LeaderboardUpdate, player, Leaderboard.GetTopTimes(10), Leaderboard.GetTopDepths(10))
            Networking.FireClient(Networking.Events.GoldUpdate, player, PlayerData.Get(player).gold)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    MiningHandler.CleanupPlayer(player)
    DeathHandler.CleanupPlayer(player)
    Session.CleanupPlayer(player)
    ItemHandler.CleanupPlayer(player)
    PlayerData.OnPlayerRemoving(player)
    playerStates[player] = nil
end)

print("[DropDwarf Server] Server initialized successfully!")
