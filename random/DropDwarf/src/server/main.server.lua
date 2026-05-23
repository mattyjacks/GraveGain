-- DropDwarf: main.server.lua
-- Server entry point: initializes all server systems

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local Networking   = require(game.ReplicatedStorage.Shared.networking)
local GameData     = require(game.ReplicatedStorage.Shared.game_data)
local UpgradeData  = require(game.ReplicatedStorage.Shared.upgrade_data)
local ItemData     = require(game.ReplicatedStorage.Shared.item_data)
local BiomeData    = require(game.ReplicatedStorage.Shared.biome_data)
local GameMode     = require(game.ReplicatedStorage.Shared.game_mode)
local PlayerData   = require(script.Parent.player_data)
local Leaderboard  = require(script.Parent.leaderboard)
local HubGenerator = require(script.Parent.hub_generator)
local LevelGenerator = require(script.Parent.level_generator)
local ItemHandler  = require(script.Parent.item_handler)
local Session      = require(script.Parent.session)

-- Create all RemoteEvents first, before any module tries to connect handlers
Networking.CreateRemotes()

-- Wire item handler network events (must be after CreateRemotes)
ItemHandler.Init()

-- Generate hub on startup
print("[DropDwarf Server] Generating hub...")
local hub = HubGenerator.Generate(workspace)
print("[DropDwarf Server] Hub ready.")

-- Set lighting defaults (Future technology for best shadows + reflections)
local Lighting = game:GetService("Lighting")
pcall(function()
    Lighting.Technology              = Enum.Technology.Future
    Lighting.GlobalShadows           = true
    Lighting.ShadowSoftness          = 0.25
    Lighting.EnvironmentDiffuseScale = 1.0
    Lighting.EnvironmentSpecularScale = 1.0
end)
Lighting.Ambient                 = Color3.fromRGB(55, 48, 40)
Lighting.OutdoorAmbient          = Color3.fromRGB(60, 55, 45)
Lighting.Brightness              = 2.0
Lighting.FogColor                = Color3.fromRGB(20, 16, 12)
Lighting.FogEnd                  = 600
Lighting.FogStart                = 200
Lighting.ColorShift_Bottom       = Color3.fromRGB(25, 18, 10)
Lighting.ColorShift_Top          = Color3.fromRGB(200, 160, 80)
Lighting.ClockTime               = 14 -- afternoon sun angle

-- Server-side Atmosphere (client will override per biome via visuals.lua)
local existingAtmo = Lighting:FindFirstChildOfClass("Atmosphere")
if not existingAtmo then
    local atmo = Instance.new("Atmosphere")
    atmo.Density = 0.35
    atmo.Offset  = 0.06
    atmo.Color   = Color3.fromRGB(200, 160, 100)
    atmo.Decay   = Color3.fromRGB(80, 60, 30)
    atmo.Glare   = 0.3
    atmo.Haze    = 0.8
    atmo.Parent  = Lighting
end

-- Per-player state
local playerStates = {}

local function getState(player)
    return playerStates[player]
end

local function createState(player)
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
        isDowned     = false,  -- coop: player is downed, awaiting rescue
    }
    return playerStates[player]
end

-- Helper: move player to hub
local function sendToHub(player)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(0, GameData.HUB_FLOOR_Y + 5, 0)
    end
    -- Restore movement that was frozen during the death choice screen
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local state = getState(player)
        local stats = state and state.stats
        humanoid.WalkSpeed  = stats and stats.walkSpeed or 16
        humanoid.JumpHeight = 8
        humanoid.Health     = humanoid.MaxHealth
    end
end

-- Helper: apply character stats
local function applyStats(player, stats)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.MaxHealth = stats.maxHealth
    humanoid.Health = math.min(humanoid.Health, stats.maxHealth)
    humanoid.WalkSpeed = stats.walkSpeed
    humanoid.JumpHeight = 8
end

-- Broadcast team health to all session members (coop HUD)
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

-- Start level for a player
local function startLevel(player, seed)
    local state = getState(player)
    if not state then return end
    local data = PlayerData.Get(player)

    seed = tostring(seed or state.seed or "MattyJacks")
    state.seed = seed
    state.inLevel = true
    state.isDying = false
    state.startTime = tick()
    state.goldThisRun = 0
    state.currentDepth = 0
    PlayerData.SetLastSeed(player, seed)

    -- Recompute stats (upgrades may have changed)
    local stats = UpgradeData.ComputeStats(data.upgrades)
    state.stats = stats
    state.maxHealth = stats.maxHealth
    state.health = stats.maxHealth

    -- Reset any placed items from previous run
    ItemHandler.ResetRunItems(player)

    print("[DropDwarf Server] Generating level with seed:", seed, "for player:", player.Name)
    local levelFolder, biomeSequence, allSlimeSpawns = LevelGenerator.Generate(workspace, seed)
    state.levelFolder = levelFolder
    state.biomeSequence = biomeSequence
    state.currentBiome = nil

    -- Spawn player inside the dwarven basket (basket floor at Y=LEVEL_Y_OFFSET-12.5,
    -- rim/wall tops at Y=LEVEL_Y_OFFSET-7.5). Spawn at -11 so feet clear the floor
    -- and character is fully inside the basket before the chain releases.
    local spawnY = GameData.LEVEL_Y_OFFSET - 11
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, spawnY, 0)
        end
        applyStats(player, stats)
    end

    -- Build sequence name list for client
    local seqNames = {}
    for i, b in ipairs(biomeSequence) do seqNames[i] = b.name end
    Networking.FireClient(Networking.Events.LevelGenerated, player, {
        seed = seed,
        biomeSequence = seqNames,
    })
    Networking.FireClient(Networking.Events.HealthUpdate, player, state.health, state.maxHealth)
    Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
    Networking.FireClient(Networking.Events.TimerSync, player, 0)
    -- Send full stats so client knows airJumps, coinMagnet, etc.
    Networking.FireClient(Networking.Events.StatsUpdate, player, stats)
    -- Confirm active modifier
    Networking.FireClient(Networking.Events.ModifierSet, player, state.modifier.id)
    -- Notify all session teammates to also enter the level with the same seed
    local modeId = Session.GetMode(player)
    local mode   = GameMode.Get(modeId)
    if mode.sharedLevel then
        Session.MarkActive(player, levelFolder)
        for _, teammate in ipairs(Session.GetTeammates(player)) do
            local tState = getState(teammate)
            if tState and not tState.inLevel then
                -- Give teammate same level/seed/modifier but own stats
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
                tState.levelFolder  = levelFolder
                tState.biomeSequence = state.biomeSequence
                ItemHandler.ResetRunItems(teammate)
                applyStats(teammate, tStats)
                local tmHrp = teammate.Character and teammate.Character:FindFirstChild("HumanoidRootPart")
                if tmHrp then
                    -- Spread spawn slightly so teammates don't overlap
                    local offset = Vector3.new(math.random(-3,3), 0, math.random(-3,3))
                    tmHrp.CFrame = CFrame.new(offset + Vector3.new(0, GameData.LEVEL_Y_OFFSET - 11, 0))
                end
                -- Build teammate seqNames the same way the host path does
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
    print("[DropDwarf Server] Level started for", player.Name, "seed:", seed,
        "modifier:", state.modifier.id, "mode:", modeId)
end

-- Helper: teleport player into the basket at run-start position and restore inLevel
local function respawnInBasket(player)
    local state = getState(player)
    if not state then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- Restore full health and movement that was frozen during death choice screen
    if humanoid then
        humanoid.Health     = state.maxHealth
        humanoid.WalkSpeed  = state.stats and state.stats.walkSpeed or 16
        humanoid.JumpHeight = 8
    end
    hrp.CFrame = CFrame.new(0, GameData.LEVEL_Y_OFFSET - 11, 0)
    state.inLevel  = true
    state.isDying  = false
end

-- Handle player death in level
local function handleDeath(player)
    local state = getState(player)
    if not state then return end
    if not state.inLevel then return end
    if state.isDying then return end  -- debounce: prevent double-death
    state.isDying = true

    local depthReached = state.currentDepth
    local data = PlayerData.Get(player)
    PlayerData.RecordRun(player, depthReached, 0, false)
    Leaderboard.SubmitDepth(player, depthReached)

    state.inLevel = false

    -- Keep character alive at 1 HP so Roblox does NOT auto-respawn at the
    -- hub SpawnLocation while the player is reading the death choice screen.
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
    -- Send death event - client will show 2x2 choice grid, no auto-route
    Networking.FireClient(Networking.Events.PlayerDied, player, {
        depthReached = depthReached,
        goldEarned   = state.goldThisRun,
    })

    -- Safety timeout: if no choice within 30s, send to hub
    task.delay(30, function()
        local s = getState(player)
        if s and s.isDying then
            sendToHub(player)
            s.isDying = false
            s.inLevel = false
        end
    end)
end

-- Handle player win
local function handleWin(player)
    local state = getState(player)
    if not state then return end
    if not state.inLevel then return end

    local timeSeconds = tick() - state.startTime
    local data = PlayerData.Get(player)
    PlayerData.RecordRun(player, GameData.TOTAL_DEPTH_METERS, timeSeconds, true)
    Leaderboard.SubmitTime(player, timeSeconds)
    Leaderboard.SubmitDepth(player, GameData.TOTAL_DEPTH_METERS)

    local absoluteRank = Leaderboard.GetPlayerTimeRank(player.UserId, timeSeconds)
    local timeStr = Leaderboard.FormatTime(timeSeconds)

    state.inLevel = false
    print("[DropDwarf Server]", player.Name, "WON! Time:", timeStr, "Rank:", absoluteRank)
    Networking.FireClient(Networking.Events.PlayerWon, player, {
        timeSeconds = timeSeconds,
        timeStr = timeStr,
        absoluteRank = absoluteRank,
        goldEarned = state.goldThisRun,
    })

    task.delay(5, function()
        sendToHub(player)
    end)
end

-- Server game loop: track depth, health, heal, fall detection
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
        local depthM = GameData.WorldYToDepth(worldY)
        depthM = math.max(0, depthM)

        -- Update depth record
        if depthM > state.currentDepth then
            state.currentDepth = depthM
            Networking.FireClient(Networking.Events.DepthUpdate, player, depthM)
        end

        -- Check for biome change (use per-run sequence)
        local biome
        if state.biomeSequence then
            biome = BiomeData.GetBiomeAtDepthInSequence(state.biomeSequence, depthM)
        else
            biome = BiomeData.GetBiomeAtDepth(depthM)
        end
        if state.currentBiome ~= biome.name then
            state.currentBiome = biome.name
            Networking.FireClient(Networking.Events.BiomeChanged, player, biome.name)
        end

        -- Passive heal (suppressed by Golden modifier)
        if state.stats.healRate > 0 and not (state.modifier and state.modifier.noRegen) then
            local heal = state.stats.healRate * TICK_RATE
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + heal)
        end
        -- Healing Potion tick (ItemHandler tracks remaining; we apply the HP here)
        local itemState = ItemHandler.GetState(player)
        if itemState and itemState.healTick then
            local healAmt = ItemData.Items.HealingPotion.healPerSec * TICK_RATE
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmt)
            itemState.healTick.remaining = itemState.healTick.remaining - TICK_RATE
            if itemState.healTick.remaining <= 0 then
                itemState.healTick = nil
            end
        end
        -- Keep state.health in sync with authoritative humanoid health
        state.health = humanoid.Health
        Networking.FireClient(Networking.Events.HealthUpdate, player, math.floor(humanoid.Health), humanoid.MaxHealth)

        -- Timer sync every ~0.5s using accumulator
        if state.startTime then
            state.timerSyncAcc = (state.timerSyncAcc or 0) + TICK_RATE
            if state.timerSyncAcc >= 0.5 then
                state.timerSyncAcc = 0
                Networking.FireClient(Networking.Events.TimerSync, player, tick() - state.startTime)
            end
        end

        -- Death check
        local modeId = Session.GetMode(player)
        local mode   = GameMode.Get(modeId)
        if humanoid.Health <= 0 then
            if mode.coopEnabled and not state.isDying then
                -- Coop: go downed instead of full death
                state.isDying  = true
                state.isDowned = true
                humanoid.Health = 1  -- keep alive at 1 HP while downed
                Session.SetDowned(player, true)
                -- Broadcast downed to whole team
                local teammates = Session.GetAllMembers(player)
                local hrpPos = hrp.Position
                for _, p in ipairs(teammates) do
                    Networking.FireClient(Networking.Events.PlayerDowned, p, {
                        userId = player.UserId,
                        name   = player.Name,
                        pos    = { hrpPos.X, hrpPos.Y, hrpPos.Z },
                    })
                end
            else
                handleDeath(player)
            end
        end

        -- Coop: bleed-out tick is handled in a separate loop below

        -- Out of bounds (fell past finish but didn't trigger)
        if worldY < GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS) - 50 then
            handleDeath(player)
        end
    end
end)

-- Coop bleed-out + team health heartbeat
local teamHealthAcc = 0
RunService.Heartbeat:Connect(function(dt)
    -- Tick bleed timers; any that expire become full deaths
    local expired = Session.TickBleedTimers(dt)
    for _, p in ipairs(expired) do
        local s = getState(p)
        if s then
            s.isDowned = false
            Session.SetDowned(p, false)
            handleDeath(p)
        end
    end

    -- Broadcast team health every 0.25s
    teamHealthAcc = teamHealthAcc + dt
    if teamHealthAcc >= 0.25 then
        teamHealthAcc = 0
        -- Find one player per active shared session to trigger a broadcast
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

-- RemoteEvent handlers

-- Death choice: player selected one of the four options on the death screen
-- choice: "respawnBasket" | "respawnHub" | "resetBasket" | "resetHub"
Networking.OnServer(Networking.Events.DeathChoice, function(player, choice)
    local state = getState(player)
    if not state then return end
    -- Only valid while in dying state
    if not state.isDying then return end

    local isReset   = (choice == "resetBasket" or choice == "resetHub")
    local isBasket  = (choice == "respawnBasket" or choice == "resetBasket")
    local data      = PlayerData.Get(player)

    if isReset then
        -- Reset: clear placed items, reset timer, keep gold
        ItemHandler.ResetRunItems(player)
        state.goldThisRun  = 0
        state.currentDepth = 0
        state.startTime    = tick()  -- timer restarts from 0
        -- Recompute stats in case upgrades changed
        local stats = UpgradeData.ComputeStats(data.upgrades)
        state.stats      = stats
        state.maxHealth  = stats.maxHealth
        state.health     = stats.maxHealth
        applyStats(player, stats)
        -- Notify client to reset timer display
        Networking.FireClient(Networking.Events.TimerSync, player, 0)
    else
        -- Respawn: keep timer running, keep placed items, restore health
        state.health = state.maxHealth
        local character = player.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = state.maxHealth end
        end
    end

    if isBasket then
        respawnInBasket(player)
        -- Tell client to re-enter level (keeps systems running)
        Networking.FireClient(Networking.Events.RespawnInBasket, player, {
            timerSeconds = isReset and 0 or (tick() - state.startTime),
            isReset      = isReset,
        })
    else
        -- Hub route
        state.isDying = false
        state.inLevel = false
        sendToHub(player)
        -- Client handles returnToHub on PlayerDied already; send explicit signal
        Networking.FireClient(Networking.Events.RespawnInHub, player, {
            isReset = isReset,
        })
    end

    print("[DropDwarf Server]", player.Name, "death choice:", choice)
end)

-- Start level
Networking.OnServer(Networking.Events.RequestStartLevel, function(player, seed)
    -- Sanitize seed: force to string, clamp length to 32 chars, strip non-printable
    if type(seed) ~= "string" and type(seed) ~= "number" then seed = "MattyJacks" end
    seed = tostring(seed):sub(1, 32):gsub("%c", "")
    if #seed == 0 then seed = "MattyJacks" end
    local state = getState(player)
    if state and state.inLevel then return end -- already in level
    startLevel(player, seed)
end)

-- Per-player coin collection rate limiter (anti-exploit: prevents spam-fire for infinite gold)
local coinLastCollect = {}
local COIN_COLLECT_MIN_INTERVAL = 0.12  -- max ~8 coins/sec per player

-- Coin collected (apply goldMult from modifier, update combo on server too)
Networking.OnServer(Networking.Events.CollectCoin, function(player, coinId)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local now = tick()
    if now - (coinLastCollect[player.UserId] or 0) < COIN_COLLECT_MIN_INTERVAL then return end
    coinLastCollect[player.UserId] = now
    local data = PlayerData.Get(player)
    local goldMult = state.modifier and state.modifier.goldMult or 1
    local earned   = math.floor(GameData.COIN_VALUE * goldMult)
    PlayerData.AddGold(player, earned)
    state.goldThisRun = (state.goldThisRun or 0) + earned
    Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
end)

-- Fall damage reported by client
local FALL_METERS_MAX_PLAUSIBLE = 400  -- ~1280 studs - more than the entire level height
Networking.OnServer(Networking.Events.ApplyFallDamage, function(player, fallMeters)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Validate: must be a real number within plausible bounds
    if type(fallMeters) ~= "number" or fallMeters ~= fallMeters then return end  -- NaN check
    fallMeters = math.clamp(fallMeters, 0, FALL_METERS_MAX_PLAUSIBLE)

    -- Cross-check with server-side fall state: if player Y velocity is near zero they
    -- didn't fall that far - cap to what physics actually allows (~sqrt(2*g*h)/3.2 in meters)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local velY = math.abs(hrp.AssemblyLinearVelocity.Y)
        local physicsMaxMeters = (velY * velY) / (2 * workspace.Gravity / GameData.STUDS_PER_METER)
        physicsMaxMeters = math.max(physicsMaxMeters, GameData.FALL_DAMAGE_THRESHOLD_METERS + 5)
        fallMeters = math.min(fallMeters, physicsMaxMeters)
    end

    local safeMeters = GameData.FALL_DAMAGE_THRESHOLD_METERS
    if fallMeters <= safeMeters then return end
    local excessMeters = fallMeters - safeMeters
    local rawDamage    = excessMeters * GameData.FALL_DAMAGE_PER_METER
    -- Apply fall resist upgrade
    local resist   = state.stats.fallResist or 0
    rawDamage      = rawDamage * (1 - resist)
    -- Apply modifier damageMult (Fragile = 3x)
    local damageMult = state.modifier and state.modifier.damageMult or 1
    -- Apply weight-based fall damage multiplier
    local totalKg    = ItemHandler.GetBackpackWeightKg(player)
    local weightMult = 1 + totalKg * ItemData.WEIGHT_FALL_PER_KG
    local finalDamage = math.min(rawDamage * damageMult * weightMult, GameData.FALL_DAMAGE_MAX)
    humanoid.Health = humanoid.Health - finalDamage
    state.health = humanoid.Health
    Networking.FireClient(Networking.Events.HealthUpdate, player, humanoid.Health, humanoid.MaxHealth)
end)

-- Purchase upgrade
Networking.OnServer(Networking.Events.PurchaseUpgrade, function(player, upgradeId)
    local success, msg = PlayerData.PurchaseUpgrade(player, upgradeId)
    if success then
        local data  = PlayerData.Get(player)
        local stats = UpgradeData.ComputeStats(data.upgrades)
        local state = getState(player)
        if state then
            state.stats     = stats
            state.maxHealth = stats.maxHealth
        end
        applyStats(player, stats)
        Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
        -- Push updated stats to client so airJumps / magnet update live
        Networking.FireClient(Networking.Events.StatsUpdate, player, stats)
        PlayerData.Save(player)
    end
end)

-- SetModifier: player picks a modifier from the hub before starting
Networking.OnServer(Networking.Events.SetModifier, function(player, modId)
    local state = getState(player)
    if not state or state.inLevel then return end  -- can't change mid-run
    local mod = GameData.RunModifiers[modId] or GameData.RunModifiers.Normal
    state.modifier = mod
    Networking.FireClient(Networking.Events.ModifierSet, player, mod.id)
end)

-- MineWall: client hit a WallOre node with the pickaxe
-- Rate-limited: max 1 hit per 0.35s per player to prevent spam
local mineHitTimes = {}
Networking.OnServer(Networking.Events.MineWall, function(player, orePart)
    local state = getState(player)
    if not state or not state.inLevel then return end

    -- Validate the part exists and is truly a WallOre
    if not orePart or not orePart:IsA("BasePart") then return end
    if orePart.Name ~= "WallOre" then return end
    local mineTag = orePart:FindFirstChild("IsMineable")
    if not mineTag then return end

    -- Range check: ore must be within 10 studs of player
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if (hrp.Position - orePart.Position).Magnitude > 12 then return end

    -- Rate limit per player
    local now = tick()
    local lastHit = mineHitTimes[player] or 0
    if now - lastHit < 0.3 then return end
    mineHitTimes[player] = now

    -- Deduct 1 HP
    local hpTag = orePart:FindFirstChild("OreHp")
    local goldTag = orePart:FindFirstChild("GoldValue")
    if not hpTag or not goldTag then return end

    hpTag.Value = hpTag.Value - 1

    if hpTag.Value <= 0 then
        -- Depleted: award gold
        local rawGold = goldTag.Value
        local modifier = state.modifier or GameData.RunModifiers.Normal
        local earned = math.floor(rawGold * (modifier.goldMult or 1))
        state.goldThisRun = (state.goldThisRun or 0) + earned

        local data = PlayerData.Get(player)
        if data then
            data.gold = data.gold + earned
            -- Do NOT Save here - ore depletion fires many times per run.
            -- Gold is persisted on run end (RecordRun) or when player returns to hub.
            Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
        end

        -- Notify client: ore depleted at this position with gold earned
        Networking.FireClient(Networking.Events.WallMined, player,
            orePart.Position, mineTag.Value, earned)

        -- Destroy the streak overlay and ore body
        local streakRef = orePart:FindFirstChild("OreStreak")
        if streakRef and streakRef.Value and streakRef.Value.Parent then
            streakRef.Value:Destroy()
        end
        orePart:Destroy()
    else
        -- Still has HP: send a "cracked" signal (gold=0 means just a hit, not depleted)
        local maxHp = (orePart:FindFirstChild("OreMaxHp") and orePart:FindFirstChild("OreMaxHp").Value) or hpTag.Value + 1
        Networking.FireClient(Networking.Events.WallMined, player,
            orePart.Position, mineTag.Value, 0, hpTag.Value, maxHp)
    end
end)

-- Request leaderboard
Networking.OnServer(Networking.Events.RequestLeaderboard, function(player)
    local times = Leaderboard.GetTopTimes(10)
    local depths = Leaderboard.GetTopDepths(10)
    Networking.FireClient(Networking.Events.LeaderboardUpdate, player, times, depths)
end)

-- Player reached bottom
Networking.OnServer(Networking.Events.PlayerReachedBottom, function(player)
    local state = getState(player)
    if not state or not state.inLevel then return end
    -- Verify player is actually at the bottom of the level (anti-exploit: can't fire from hub)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local finishY = GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS)
    if hrp.Position.Y > finishY + 30 then return end  -- must be within 30 studs of finish
    handleWin(player)
end)

-- RemoteFunction handlers
local getDataFn = Networking.GetFunction(Networking.Functions.GetPlayerData)
if getDataFn then
    getDataFn.OnServerInvoke = function(player)
        local data = PlayerData.Get(player)
        if data then
            return {
                gold = data.gold,
                upgrades = data.upgrades,
                bestTime = data.bestTime,
                bestDepth = data.bestDepth,
                totalRuns = data.totalRuns,
                wins = data.wins,
                lastSeed = data.lastSeed,
            }
        end
        return nil
    end
end

local validateSeedFn = Networking.GetFunction(Networking.Functions.ValidateSeed)
if validateSeedFn then
    validateSeedFn.OnServerInvoke = function(player, seed)
        if type(seed) ~= "string" and type(seed) ~= "number" then
            return false, "Invalid seed type"
        end
        local str = tostring(seed)
        if #str < 1 or #str > 32 then
            return false, "Seed must be 1-32 characters"
        end
        return true, "Valid"
    end
end

-- ===================== MULTIPLAYER HANDLERS =====================

-- Host sets game mode from hub UI (only the session host can change the mode)
Networking.OnServer(Networking.Events.SetGameMode, function(player, modeId)
    local state = getState(player)
    if state and state.inLevel then return end  -- can't change mid-run
    -- Validate modeId is one of the known modes
    if not GameMode.Get(modeId) then return end
    Session.SetMode(player, modeId)
end)

-- Player requests to join another player's lobby
Networking.OnServer(Networking.Events.RequestJoinSession, function(player, hostUserId)
    local state = getState(player)
    if state and state.inLevel then return end
    Session.JoinSession(player, hostUserId)
end)

-- Player voluntarily leaves lobby
Networking.OnServer(Networking.Events.LeaveSession, function(player)
    Session.LeaveSession(player)
end)

-- Coop: rescuer holding E near downed player
-- targetId: UserId number of the downed player
local rescueTick = {}  -- [rescuerId] = { targetId, acc }
Networking.OnServer(Networking.Events.RequestRescue, function(player, targetUserId)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local modeId = Session.GetMode(player)
    local mode = GameMode.Get(modeId)
    if not mode.coopEnabled then return end

    -- Find the target player object
    local targetPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == targetUserId then targetPlayer = p; break end
    end
    if not targetPlayer then return end
    if not Session.IsDowned(targetPlayer) then return end

    -- Range check
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

    -- Rate: called each client heartbeat, dt approximated
    -- Cap dt to 1/20 to prevent instant-rescue exploit via rapid fire
    local now = tick()
    local last = rescueTick[player.UserId]
    local dt = math.min(last and (now - last) or (1/30), 1/20)
    rescueTick[player.UserId] = now

    local complete = Session.UpdateRescue(player, targetPlayer, dt)

    -- Report progress back to rescuer
    local rs = Session.GetDownedState(targetPlayer)
    Networking.FireClient(Networking.Events.RescueProgress, player, {
        targetId  = targetUserId,
        progress  = rs and rs.rescueProgress or 0,
    })

    if complete then
        -- Rescue complete
        Session.SetDowned(targetPlayer, false)
        local tState = getState(targetPlayer)
        if tState then
            tState.isDying  = false
            tState.isDowned = false
            local tChar = targetPlayer.Character
            local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")
            if tHum then
                tHum.Health = math.max(1, tState.maxHealth * 0.3)  -- revive at 30% HP
            end
        end
        -- Broadcast rescue to team
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

-- Coop: give active item to nearest teammate (G key)
Networking.OnServer(Networking.Events.GiveItemRequest, function(player)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local modeId = Session.GetMode(player)
    local mode = GameMode.Get(modeId)
    if not mode.coopEnabled then return end

    local itemState = ItemHandler.GetState(player)
    if not itemState or not itemState.activeItem then return end

    local myChar = player.Character
    local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    -- Find nearest teammate within range
    local nearest, nearDist = nil, mode.giveItemRange
    for _, teammate in ipairs(Session.GetTeammates(player)) do
        local tChar = teammate.Character
        local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tHrp then
            local d = (myHrp.Position - tHrp.Position).Magnitude
            if d < nearDist then
                nearest  = teammate
                nearDist = d
            end
        end
    end
    if not nearest then return end

    -- Transfer one unit of the active item
    local itemId  = itemState.activeItem
    local slot    = itemState.activeSlot
    local slotData = itemState.backpack[slot]
    if not slotData or slotData.count <= 0 then return end

    -- Deduct from giver
    slotData.count = slotData.count - 1
    if slotData.count <= 0 then
        itemState.backpack[slot] = nil
        itemState.activeItem = nil
    end
    -- Give to recipient
    ItemHandler.GiveItem(nearest, itemId, 1)

    -- Notify team
    local team = Session.GetAllMembers(player)
    for _, p in ipairs(team) do
        Networking.FireClient(Networking.Events.ItemGiven, p, {
            fromId  = player.UserId,
            toId    = nearest.UserId,
            itemId  = itemId,
            count   = 1,
        })
    end
end)

-- Competitive: pickaxe swing hit another player
-- targetId: UserId, hitPos: Vector3 serialized {x,y,z}
Networking.OnServer(Networking.Events.AttackPlayer, function(player, targetUserId, hitPos)
    local state = getState(player)
    if not state or not state.inLevel then return end
    local modeId = Session.GetMode(player)
    local mode = GameMode.Get(modeId)
    if not mode.pvpEnabled then return end

    -- Find target
    local targetPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == targetUserId then targetPlayer = p; break end
    end
    if not targetPlayer then return end
    if targetPlayer == player then return end  -- can't attack yourself
    local tState = getState(targetPlayer)
    if not tState or not tState.inLevel then return end

    -- Verify both players are in the same session (anti-exploit: can't attack across sessions)
    local attackerSid = Session.GetSessionId(player)
    local targetSid   = Session.GetSessionId(targetPlayer)
    if not attackerSid or attackerSid ~= targetSid then return end

    -- Range check
    local myChar = player.Character
    local tChar  = targetPlayer.Character
    if not myChar or not tChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    local tHrp  = tChar:FindFirstChild("HumanoidRootPart")
    if not myHrp or not tHrp then return end
    if (myHrp.Position - tHrp.Position).Magnitude > mode.pickaxeRange then return end

    -- Cooldown check
    if not Session.CanHitPlayer(player, targetPlayer) then return end
    Session.RecordHit(player, targetPlayer)

    -- Apply damage
    local hum = tChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    hum.Health = math.max(0, hum.Health - mode.pickaxeDamage)

    -- Knockback: push target away from attacker
    local knockDir = (tHrp.Position - myHrp.Position)
    if knockDir.Magnitude < 0.01 then knockDir = Vector3.new(1,0,0) end
    knockDir = knockDir.Unit
    -- Send knockback vector to victim's client to apply via BodyVelocity
    Networking.FireClient(Networking.Events.PlayerHit, targetPlayer, {
        damage      = mode.pickaxeDamage,
        knockbackDir = { knockDir.X, knockDir.Y + 0.4, knockDir.Z },
        knockbackForce = mode.knockbackForce,
        attackerName = player.Name,
    })
end)

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
    PlayerData.OnPlayerAdded(player)
    ItemHandler.InitPlayer(player)
    local state = createState(player)

    player.CharacterAdded:Connect(function(character)
        local data = PlayerData.Get(player)
        if data then
            local stats = UpgradeData.ComputeStats(data.upgrades)
            task.wait(0.5) -- wait for character to load
            applyStats(player, stats)
            sendToHub(player)
        end
    end)

    -- Send initial leaderboard
    task.delay(2, function()
        if player and player.Parent then
            local times = Leaderboard.GetTopTimes(10)
            local depths = Leaderboard.GetTopDepths(10)
            Networking.FireClient(Networking.Events.LeaderboardUpdate, player, times, depths)
            local data = PlayerData.Get(player)
            if data then
                Networking.FireClient(Networking.Events.GoldUpdate, player, data.gold)
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    Session.CleanupPlayer(player)
    ItemHandler.CleanupPlayer(player)
    PlayerData.OnPlayerRemoving(player)
    playerStates[player] = nil
end)

-- (Healing and regen are now handled inside the TICK_RATE loop above)

print("[DropDwarf Server] Server initialized!")
