-- DwarfDrop: level_generator/init.lua
-- Main procedural level generator: session-isolated folders, seeded chunks

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameData   = require(game.ReplicatedStorage.Shared.game_data)
local BiomeData  = require(game.ReplicatedStorage.Shared.biome_data)
local ItemData   = require(game.ReplicatedStorage.Shared.item_data)
local SeedSystem = require(game.ReplicatedStorage.Shared.seed_system)

local LevelGenerator = {}

local LEVEL_WIDTH     = GameData.LEVEL_WIDTH
local SLOT_METERS     = GameData.SLOT_DEPTH_METERS
local SLOT_STUDS      = GameData.SLOT_DEPTH_STUDS
local LEVEL_Y_OFFSET  = GameData.LEVEL_Y_OFFSET

-- ==================== SESSION FOLDER ====================

-- FIX Bug#3: Basket is stored on the session folder for reliable reference
function LevelGenerator.CreateSessionFolder(seed, sessionId)
    local folder = Instance.new("Folder")
    folder.Name = "Level_" .. tostring(sessionId)
    folder.Parent = workspace

    local seedTag = Instance.new("StringValue")
    seedTag.Name = "Seed"
    seedTag.Value = tostring(seed)
    seedTag.Parent = folder

    return folder
end

-- ==================== GEOMETRY HELPERS ====================

local function makePart(parent, name, pos, size, color, anchored, canCollide)
    local p = Instance.new("Part")
    p.Name      = name or "Part"
    p.Position  = pos
    p.Size      = size
    p.Color     = color or Color3.new(0.5, 0.5, 0.5)
    p.Anchored  = anchored ~= false
    p.CanCollide = canCollide ~= false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent    = parent
    return p
end

local function tagPart(part, tagName, value)
    local tag = Instance.new(type(value) == "number" and "NumberValue" or
        (type(value) == "boolean" and "BoolValue" or "StringValue"))
    tag.Name   = tagName
    tag.Value  = value
    tag.Parent = part
end

-- ==================== COIN SPAWN ====================

-- FIX Bug#2: SpawnCoins is a module-level helper (no PartBuilders dependency)
function LevelGenerator.SpawnCoins(parent, centerPos, count, rng)
    local coins = {}
    for i = 1, count do
        local offset = Vector3.new(
            rng:NextNumber(-4, 4),
            rng:NextNumber(1, 3),
            rng:NextNumber(-4, 4)
        )
        local coin = makePart(parent, "GoldCoin",
            centerPos + offset,
            Vector3.new(GameData.COIN_SIZE, GameData.COIN_SIZE, GameData.COIN_SIZE),
            Color3.fromRGB(255, 210, 40),
            false, false)
        coin.Shape = Enum.PartType.Ball
        coin.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.3, 0.5, 0, 0)
        tagPart(coin, "IsCoin", true)
        tagPart(coin, "CoinValue", GameData.COIN_VALUE)
        table.insert(coins, coin)
    end
    return coins
end

-- ==================== ITEM CRATE SPAWN ====================

local function spawnItemCrate(parent, pos, itemId, rng)
    if not ItemData.Items[itemId] then return end
    local def = ItemData.Items[itemId]

    local crate = Instance.new("Model")
    crate.Name = "ItemCrate_" .. itemId
    crate.Parent = parent

    local base = makePart(crate, "BaseCrate", pos, Vector3.new(3, 3, 3),
        def.glowColor or Color3.fromRGB(200, 200, 200))
    tagPart(base, "IsItemCrate", true)
    tagPart(base, "CrateId", tostring(math.floor(pos.X * 10)) .. "_" .. tostring(math.floor(pos.Y * 10)))
    tagPart(base, "ItemId", itemId)
    tagPart(base, "ItemCount", 1)

    -- Glow
    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Range = 10
    light.Color = def.glowColor or Color3.new(1, 1, 1)
    light.Parent = base

    crate.PrimaryPart = base
    return crate
end

-- ==================== SLOT GENERATION ====================

-- Generate one 100m slot at slotIndex (1-10)
-- slotIndex 1 = 0-100m, slotIndex 2 = 100-200m, etc.
function LevelGenerator.GenerateSlot(sessionFolder, seed, slotIndex, biomeSequence, modifier)
    local slotFolder = Instance.new("Folder")
    slotFolder.Name  = "Slot_" .. slotIndex
    slotFolder.Parent = sessionFolder

    local rng   = SeedSystem.NewRNG(seed, "slot_" .. slotIndex)
    local biome = biomeSequence[slotIndex] or BiomeData.Biomes.Volcano

    -- Depth range for this slot
    local topDepthM = (slotIndex - 1) * SLOT_METERS
    local botDepthM = slotIndex * SLOT_METERS

    -- World Y range: top of slot Y, bottom of slot Y
    local topY = LEVEL_Y_OFFSET - GameData.MetersToStuds(topDepthM)
    local botY = LEVEL_Y_OFFSET - GameData.MetersToStuds(botDepthM)

    -- ===== WALLS =====
    local wallH  = SLOT_STUDS + 8  -- slight overlap for seamless seams
    local wallY  = topY - SLOT_STUDS / 2
    local halfW  = LEVEL_WIDTH / 2

    -- Determine wall colors
    local wallColors = biome.wallColors or biome.colors
    local function rndWallColor()
        local idx = rng:NextInteger(1, #wallColors)
        return wallColors[idx]
    end

    -- North wall
    local wallN = makePart(slotFolder, "WallN",
        Vector3.new(0, wallY, -(halfW + 1)),
        Vector3.new(LEVEL_WIDTH + 2, wallH, 2),
        rndWallColor())

    -- South wall
    local wallS = makePart(slotFolder, "WallS",
        Vector3.new(0, wallY, (halfW + 1)),
        Vector3.new(LEVEL_WIDTH + 2, wallH, 2),
        rndWallColor())

    -- East wall
    local wallE = makePart(slotFolder, "WallE",
        Vector3.new(halfW + 1, wallY, 0),
        Vector3.new(2, wallH, LEVEL_WIDTH + 2),
        rndWallColor())

    -- West wall
    local wallW = makePart(slotFolder, "WallW",
        Vector3.new(-(halfW + 1), wallY, 0),
        Vector3.new(2, wallH, LEVEL_WIDTH + 2),
        rndWallColor())

    -- Tag ore nodes on East/West walls
    for _, wall in ipairs({ wallE, wallW }) do
        if rng:NextNumber() < 0.4 then
            tagPart(wall, "IsOre", true)
            tagPart(wall, "OreHP", 3)
            tagPart(wall, "OreGoldValue", rng:NextInteger(8, 20))
        end
    end

    -- ===== PLATFORMS =====
    local pCfg   = biome.platform
    local platforms = {}
    local currentY   = topY - 8  -- first platform slightly below slot top
    local centerX    = 0
    local centerZ    = 0

    local modSpeedMult = modifier and modifier.speedMult or 1
    -- Smaller platforms for Speedy
    local sizeScale = modSpeedMult > 1.2 and 0.7 or 1.0

    while currentY > botY + biome.dropMin * GameData.STUDS_PER_METER do
        local drop = rng:NextNumber(biome.dropMin, biome.dropMax) * GameData.STUDS_PER_METER
        currentY = currentY - drop

        if currentY < botY then break end

        -- Platform offset from center
        local ox = rng:NextNumber(-halfW * 0.5, halfW * 0.5)
        local oz = rng:NextNumber(-halfW * 0.5, halfW * 0.5)

        local sizeX = rng:NextNumber(pCfg.minX, pCfg.maxX) * sizeScale
        local sizeZ = rng:NextNumber(pCfg.minZ, pCfg.maxZ) * sizeScale

        local pColor = biome.colors[rng:NextInteger(1, #biome.colors)]
        local plat = makePart(slotFolder, "Platform",
            Vector3.new(ox, currentY, oz),
            Vector3.new(sizeX, 2, sizeZ),
            pColor)

        -- Terrain tag
        tagPart(plat, "TerrainType", "Firm")

        -- Hazard chance
        if rng:NextNumber() < biome.hazardChance then
            tagPart(plat, "IsHazard", biome.hazardDamage or 10)
            plat.Color = biome.accentColor or Color3.fromRGB(255, 0, 0)
            plat.Material = Enum.Material.Neon
        end

        -- Coin spawn
        local goldMult = modifier and modifier.goldMult or 1
        if rng:NextNumber() < biome.coinChance then
            local coinCount = math.floor(rng:NextInteger(1, 4) * goldMult + 0.5)
            LevelGenerator.SpawnCoins(slotFolder,
                Vector3.new(ox, currentY + 2.5, oz),
                coinCount, rng)
        end

        -- Item crate spawn (rare)
        if rng:NextNumber() < 0.06 then
            local itemPool = ItemData.UtilityItems
            local idx = rng:NextInteger(1, #itemPool)
            spawnItemCrate(slotFolder,
                Vector3.new(ox + rng:NextNumber(-2, 2), currentY + 3.5, oz + rng:NextNumber(-2, 2)),
                itemPool[idx], rng)
        end

        -- Tunnel ceiling slab
        if rng:NextNumber() < biome.tunnelChance then
            local ceilY = currentY + rng:NextNumber(14, 22)
            local ceilColor = biome.colors[rng:NextInteger(1, #biome.colors)]
            makePart(slotFolder, "CeilingSlab",
                Vector3.new(ox, ceilY, oz),
                Vector3.new(sizeX + 4, 2, sizeZ + 4),
                ceilColor)
        end

        table.insert(platforms, plat)
    end

    -- ===== SLIMES (server-side AI anchor points only; client handles visuals) =====
    local slimeCount = rng:NextInteger(1, 4)
    for _ = 1, slimeCount do
        if #platforms > 0 then
            local platIdx = rng:NextInteger(1, #platforms)
            local p = platforms[platIdx]
            local anchor = makePart(slotFolder, "SlimeAnchor",
                p.Position + Vector3.new(0, 2.5, 0),
                Vector3.new(0.5, 0.5, 0.5),
                Color3.fromRGB(80, 200, 80),
                true, false)
            anchor.Transparency = 1
            tagPart(anchor, "IsSlimeSpawn", true)
            tagPart(anchor, "SlimeId", tostring(slotIndex) .. "_" .. tostring(_))
        end
    end

    -- Tag slot metadata
    tagPart(slotFolder:FindFirstChildWhichIsA("Part") or
        makePart(slotFolder, "SlotMeta",
            Vector3.new(0, topY - SLOT_STUDS / 2, 0),
            Vector3.new(1, 1, 1),
            Color3.new(0, 0, 0)), "SlotIndex", slotIndex)

    return slotFolder
end

-- ==================== DWARVEN ENTRY BASKET ====================

function LevelGenerator.BuildBasket(sessionFolder)
    local basketFolder = Instance.new("Folder")
    basketFolder.Name  = "DwarvenEntryBasket"
    basketFolder.Parent = sessionFolder

    local basketY  = LEVEL_Y_OFFSET + 12
    local basketCX = 0
    local basketCZ = 0

    -- Floor
    local floor = makePart(basketFolder, "BasketFloor",
        Vector3.new(basketCX, basketY, basketCZ),
        Vector3.new(14, 2, 14),
        Color3.fromRGB(100, 80, 60))

    -- Walls
    local wallH = 10
    local wallThick = 2
    local halfE = 8
    local positions = {
        Vector3.new(basketCX,      basketY + wallH / 2, basketCZ - halfE),
        Vector3.new(basketCX,      basketY + wallH / 2, basketCZ + halfE),
        Vector3.new(basketCX - halfE, basketY + wallH / 2, basketCZ),
        Vector3.new(basketCX + halfE, basketY + wallH / 2, basketCZ),
    }
    local sizes = {
        Vector3.new(16, wallH, wallThick),
        Vector3.new(16, wallH, wallThick),
        Vector3.new(wallThick, wallH, 16),
        Vector3.new(wallThick, wallH, 16),
    }
    for i, pos in ipairs(positions) do
        makePart(basketFolder, "BasketWall" .. i, pos, sizes[i],
            Color3.fromRGB(80, 65, 50))
    end

    -- Spawn pad inside basket
    local spawnPad = makePart(basketFolder, "SpawnPad",
        Vector3.new(basketCX, basketY + 1.5, basketCZ),
        Vector3.new(10, 1, 10),
        Color3.fromRGB(180, 160, 120))
    spawnPad.Transparency = 0.3
    tagPart(spawnPad, "IsSpawnPad", true)

    -- Tag basket folder for death_handler lookup
    tagPart(basketFolder, "IsBasket", true)

    return basketFolder
end

-- ==================== LEVEL INIT ====================

-- Build a complete level for a session: basket + first 2 slots pre-generated
-- Returns the session folder
function LevelGenerator.BuildLevel(seed, sessionId, biomeSequence, modifier)
    local sessionFolder = LevelGenerator.CreateSessionFolder(seed, sessionId)

    -- Build basket
    LevelGenerator.BuildBasket(sessionFolder)

    -- Pre-generate first 2 slots (slots 1 and 2)
    for i = 1, 2 do
        LevelGenerator.GenerateSlot(sessionFolder, seed, i, biomeSequence, modifier)
    end

    return sessionFolder
end

-- Load slot on demand (called from session_handler)
function LevelGenerator.LoadSlot(sessionFolder, seed, slotIndex, biomeSequence, modifier)
    -- Don't regenerate if already loaded
    if sessionFolder:FindFirstChild("Slot_" .. slotIndex) then
        return sessionFolder:FindFirstChild("Slot_" .. slotIndex)
    end
    return LevelGenerator.GenerateSlot(sessionFolder, seed, slotIndex, biomeSequence, modifier)
end

-- Unload old slots (called when player is N slots ahead)
function LevelGenerator.UnloadSlot(sessionFolder, slotIndex)
    local folder = sessionFolder:FindFirstChild("Slot_" .. slotIndex)
    if folder then
        folder:Destroy()
    end
end

return LevelGenerator
