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

-- ==================== BIOME TERRAIN DECORATIONS ====================

local function addVolcanoTerrain(parent, plat, rng)
    local px, py, pz = plat.Position.X, plat.Position.Y, plat.Position.Z
    local sx, sz = plat.Size.X, plat.Size.Z
    -- Lava crack strip along one edge
    if rng:NextNumber() < 0.5 then
        local crack = makePart(parent, "LavaCrack",
            Vector3.new(px + rng:NextNumber(-sx*0.3, sx*0.3), py + 1.1, pz + sz*0.4),
            Vector3.new(sx * rng:NextNumber(0.3, 0.7), 0.4, 1.5),
            Color3.fromRGB(255, 80, 0))
        crack.Material = Enum.Material.Neon; crack.CastShadow = false
        local l = Instance.new("PointLight")
        l.Brightness = 1.5; l.Range = 12; l.Color = Color3.fromRGB(255, 100, 0); l.Parent = crack
    end
    -- Obsidian spike pillar on corner
    if rng:NextNumber() < 0.3 then
        local h = rng:NextNumber(3, 8)
        local spike = makePart(parent, "ObsidianSpike",
            Vector3.new(px + sx*0.4, py + h/2 + 1, pz + sz*0.4),
            Vector3.new(1.5, h, 1.5),
            Color3.fromRGB(20, 10, 30))
        spike.Material = Enum.Material.Rock
    end
end

local function addFortressTerrain(parent, plat, rng)
    local px, py, pz = plat.Position.X, plat.Position.Y, plat.Position.Z
    local sx, sz = plat.Size.X, plat.Size.Z
    -- Battlement crenels along top edge
    if rng:NextNumber() < 0.45 then
        local count = rng:NextInteger(2, 4)
        for i = 1, count do
            local bx = px - sx/2 + (i / (count+1)) * sx
            makePart(parent, "Battlement",
                Vector3.new(bx, py + 2.5, pz - sz*0.45),
                Vector3.new(2, 3, 2),
                Color3.fromRGB(48, 45, 40))
        end
    end
    -- Torch pillar
    if rng:NextNumber() < 0.35 then
        local pole = makePart(parent, "TorchPole",
            Vector3.new(px + sx*0.35, py + 3, pz + sz*0.35),
            Vector3.new(0.8, 5, 0.8),
            Color3.fromRGB(60, 55, 50))
        pole.Material = Enum.Material.SmoothPlastic
        local flame = makePart(parent, "TorchFlame",
            Vector3.new(px + sx*0.35, py + 6, pz + sz*0.35),
            Vector3.new(1.2, 1.2, 1.2),
            Color3.fromRGB(255, 160, 40))
        flame.Material = Enum.Material.Neon; flame.Shape = Enum.PartType.Ball
        local l = Instance.new("PointLight")
        l.Brightness = 2; l.Range = 18; l.Color = Color3.fromRGB(255, 160, 40); l.Parent = flame
    end
end

local function addCaveTerrain(parent, plat, rng)
    local px, py, pz = plat.Position.X, plat.Position.Y, plat.Position.Z
    local sx, sz = plat.Size.X, plat.Size.Z
    -- Crystal spikes growing up from platform surface
    local spikeCount = rng:NextInteger(1, 4)
    for _ = 1, spikeCount do
        local h = rng:NextNumber(2, 6)
        local ox = rng:NextNumber(-sx*0.4, sx*0.4)
        local oz = rng:NextNumber(-sz*0.4, sz*0.4)
        local spike = makePart(parent, "CrystalSpike",
            Vector3.new(px + ox, py + h/2 + 1, pz + oz),
            Vector3.new(rng:NextNumber(0.8,1.8), h, rng:NextNumber(0.8,1.8)),
            Color3.fromRGB(
                rng:NextInteger(30,80),
                rng:NextInteger(80,160),
                rng:NextInteger(160,220)))
        spike.Material = Enum.Material.Neon
        spike.CastShadow = false
    end
    -- Stalactite hanging from ceiling slab
    if rng:NextNumber() < 0.4 then
        local ceilY = py + rng:NextNumber(12, 20)
        local dripH = rng:NextNumber(4, 10)
        makePart(parent, "Stalactite",
            Vector3.new(px + rng:NextNumber(-sx*0.3,sx*0.3), ceilY - dripH/2, pz + rng:NextNumber(-sz*0.3,sz*0.3)),
            Vector3.new(1.5, dripH, 1.5),
            Color3.fromRGB(40, 38, 35))
    end
end

local function addMineTerrain(parent, plat, rng)
    local px, py, pz = plat.Position.X, plat.Position.Y, plat.Position.Z
    local sx, sz = plat.Size.X, plat.Size.Z
    -- Wooden support beam pair
    if rng:NextNumber() < 0.5 then
        local beamH = rng:NextNumber(6, 10)
        for _, side in ipairs({-1, 1}) do
            makePart(parent, "SupportPost",
                Vector3.new(px + side * sx * 0.38, py + beamH/2 + 1, pz),
                Vector3.new(1.2, beamH, 1.2),
                Color3.fromRGB(100, 72, 42))
        end
        -- Horizontal cross-beam
        makePart(parent, "CrossBeam",
            Vector3.new(px, py + beamH + 1, pz),
            Vector3.new(sx * 0.8, 1.2, 1.2),
            Color3.fromRGB(88, 62, 36))
    end
    -- Gold vein streak on platform surface
    if rng:NextNumber() < 0.45 then
        local vein = makePart(parent, "GoldVein",
            Vector3.new(px + rng:NextNumber(-sx*0.3,sx*0.3), py + 1.1, pz + rng:NextNumber(-sz*0.3,sz*0.3)),
            Vector3.new(rng:NextNumber(2,5), 0.3, rng:NextNumber(1,3)),
            Color3.fromRGB(220, 180, 40))
        vein.Material = Enum.Material.Rock
        tagPart(vein, "IsOre", true)
        tagPart(vein, "OreHP", 2)
        tagPart(vein, "OreGoldValue", rng:NextInteger(12, 28))
    end
end

local TERRAIN_FNS = {
    volcano = addVolcanoTerrain,
    fortress = addFortressTerrain,
    cave = addCaveTerrain,
    mine = addMineTerrain,
}

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

    -- ===== WALLS (4 thick slabs, biome material) =====
    local wallH    = SLOT_STUDS + 8
    local wallY    = topY - SLOT_STUDS / 2
    local halfW    = LEVEL_WIDTH / 2
    local wallMat  = biome.wallMaterial or Enum.Material.Rock
    local wallThick = 8  -- thick walls for natural look

    local wallColors = biome.wallColors or biome.colors
    local function rndWallColor()
        return wallColors[rng:NextInteger(1, #wallColors)]
    end

    local walls = {}
    local wallN = makePart(slotFolder, "WallN",
        Vector3.new(0, wallY, -(halfW + wallThick/2)),
        Vector3.new(LEVEL_WIDTH + wallThick*2, wallH, wallThick), rndWallColor())
    local wallS = makePart(slotFolder, "WallS",
        Vector3.new(0, wallY,  (halfW + wallThick/2)),
        Vector3.new(LEVEL_WIDTH + wallThick*2, wallH, wallThick), rndWallColor())
    local wallE = makePart(slotFolder, "WallE",
        Vector3.new( halfW + wallThick/2, wallY, 0),
        Vector3.new(wallThick, wallH, LEVEL_WIDTH + wallThick*2), rndWallColor())
    local wallW = makePart(slotFolder, "WallW",
        Vector3.new(-(halfW + wallThick/2), wallY, 0),
        Vector3.new(wallThick, wallH, LEVEL_WIDTH + wallThick*2), rndWallColor())
    for _, w in ipairs({wallN, wallS, wallE, wallW}) do
        w.Material = wallMat
        table.insert(walls, w)
    end

    -- Ore nodes on E/W walls
    for _, wall in ipairs({ wallE, wallW }) do
        if rng:NextNumber() < 0.4 then
            tagPart(wall, "IsOre", true)
            tagPart(wall, "OreHP", 3)
            tagPart(wall, "OreGoldValue", rng:NextInteger(8, 20))
        end
    end

    -- ===== PLATFORMS =====
    local pCfg        = biome.platform
    local platMat     = biome.platMaterial or Enum.Material.Rock
    local terrainFn   = TERRAIN_FNS[biome.terrainStyle]
    local platforms   = {}
    local modSpeedMult = modifier and modifier.speedMult or 1
    local sizeScale    = modSpeedMult > 1.2 and 0.7 or 1.0

    -- Primary platforms: march down the slot with randomised drop gaps
    local currentY = topY - 6
    while currentY > botY + biome.dropMin * GameData.STUDS_PER_METER do
        local drop = rng:NextNumber(biome.dropMin, biome.dropMax) * GameData.STUDS_PER_METER
        currentY = currentY - drop
        if currentY < botY then break end

        -- Spread platforms across the full shaft width
        local ox = rng:NextNumber(-halfW * 0.65, halfW * 0.65)
        local oz = rng:NextNumber(-halfW * 0.65, halfW * 0.65)
        local sizeX = rng:NextNumber(pCfg.minX, pCfg.maxX) * sizeScale
        local sizeZ = rng:NextNumber(pCfg.minZ, pCfg.maxZ) * sizeScale
        -- Vary platform thickness for natural look (1-3 studs)
        local thick = rng:NextNumber(1.5, 3.5)

        local pColor = biome.colors[rng:NextInteger(1, #biome.colors)]
        local plat = makePart(slotFolder, "Platform",
            Vector3.new(ox, currentY, oz),
            Vector3.new(sizeX, thick, sizeZ), pColor)
        plat.Material = platMat
        tagPart(plat, "TerrainType", "Firm")

        -- Hazard
        if rng:NextNumber() < biome.hazardChance then
            tagPart(plat, "IsHazard", biome.hazardDamage or 10)
            plat.Color  = biome.hazardColor  or Color3.fromRGB(255, 0, 0)
            plat.Material = biome.hazardMat  or Enum.Material.Neon
        end

        -- Coins
        local goldMult = modifier and modifier.goldMult or 1
        if rng:NextNumber() < biome.coinChance then
            local coinCount = math.floor(rng:NextInteger(1, 5) * goldMult + 0.5)
            LevelGenerator.SpawnCoins(slotFolder,
                Vector3.new(ox, currentY + thick + 1, oz), coinCount, rng)
        end

        -- Item crate (rare)
        if rng:NextNumber() < 0.06 then
            local itemPool = ItemData.UtilityItems
            spawnItemCrate(slotFolder,
                Vector3.new(ox + rng:NextNumber(-2,2), currentY + thick + 2, oz + rng:NextNumber(-2,2)),
                itemPool[rng:NextInteger(1, #itemPool)], rng)
        end

        -- Biome terrain decoration
        if terrainFn and rng:NextNumber() < 0.65 then
            terrainFn(slotFolder, plat, rng)
        end

        -- Tunnel ceiling slab
        if rng:NextNumber() < biome.tunnelChance then
            local ceilY = currentY + rng:NextNumber(14, 24)
            local cColor = biome.colors[rng:NextInteger(1, #biome.colors)]
            local slab = makePart(slotFolder, "CeilingSlab",
                Vector3.new(ox, ceilY, oz),
                Vector3.new(sizeX + 6, 2, sizeZ + 6), cColor)
            slab.Material = platMat
        end

        table.insert(platforms, plat)

        -- Secondary filler platform: offset ~half a gap to the side
        -- keeps the shaft feeling dense without being trivial
        if rng:NextNumber() < 0.55 then
            local fDrop = rng:NextNumber(biome.dropMin*0.5, biome.dropMax*0.5) * GameData.STUDS_PER_METER
            local fY    = currentY - fDrop
            if fY > botY then
                local fox  = rng:NextNumber(-halfW * 0.65, halfW * 0.65)
                local foz  = rng:NextNumber(-halfW * 0.65, halfW * 0.65)
                local fSX  = rng:NextNumber(pCfg.minX * 0.6, pCfg.maxX * 0.8) * sizeScale
                local fSZ  = rng:NextNumber(pCfg.minZ * 0.6, pCfg.maxZ * 0.8) * sizeScale
                local fCol = biome.colors[rng:NextInteger(1, #biome.colors)]
                local fp   = makePart(slotFolder, "PlatformFill",
                    Vector3.new(fox, fY, foz),
                    Vector3.new(fSX, rng:NextNumber(1.5,3), fSZ), fCol)
                fp.Material = platMat
                tagPart(fp, "TerrainType", "Firm")
                if rng:NextNumber() < biome.coinChance * 0.6 then
                    local goldMult = modifier and modifier.goldMult or 1
                    LevelGenerator.SpawnCoins(slotFolder,
                        Vector3.new(fox, fY + 2.5, foz),
                        rng:NextInteger(1,3), rng)
                end
                table.insert(platforms, fp)
            end
        end
    end

    -- ===== SLIMES =====
    local slimeCount = rng:NextInteger(2, 5)
    for _ = 1, slimeCount do
        if #platforms > 0 then
            local p = platforms[rng:NextInteger(1, #platforms)]
            local anchor = makePart(slotFolder, "SlimeAnchor",
                p.Position + Vector3.new(0, 2.5, 0),
                Vector3.new(0.5, 0.5, 0.5),
                Color3.fromRGB(80, 200, 80), true, false)
            anchor.Transparency = 1
            tagPart(anchor, "IsSlimeSpawn", true)
            tagPart(anchor, "SlimeId", tostring(slotIndex) .. "_" .. tostring(_))
        end
    end

    -- Tag slot metadata
    tagPart(slotFolder:FindFirstChildWhichIsA("Part") or
        makePart(slotFolder, "SlotMeta",
            Vector3.new(0, topY - SLOT_STUDS/2, 0),
            Vector3.new(1,1,1), Color3.new(0,0,0)), "SlotIndex", slotIndex)

    return slotFolder
end

-- ==================== DWARVEN ENTRY BASKET ====================

function LevelGenerator.BuildBasket(sessionFolder)
    local basketFolder = Instance.new("Folder")
    basketFolder.Name  = "DwarvenEntryBasket"
    basketFolder.Parent = sessionFolder

    -- 1 meter = 3.2 studs tall walls, open top, open bottom.
    -- Basket sits at the very top of the shaft so player drops straight in.
    local wallH   = 3.2   -- 1 metre
    local halfW   = 8     -- basket inner half-width (16 stud interior)
    local wallThk = 2
    -- Basket floor center: just above LEVEL_Y_OFFSET so it's the very top of the shaft
    local floorY  = LEVEL_Y_OFFSET + wallH + wallThk/2  -- floor top face at LEVEL_Y_OFFSET + wallH
    local wallMidY = LEVEL_Y_OFFSET + wallH/2 + wallThk/2

    local woodColor = Color3.fromRGB(110, 80, 50)

    -- Floor
    local floor = makePart(basketFolder, "BasketFloor",
        Vector3.new(0, LEVEL_Y_OFFSET + wallThk/2, 0),
        Vector3.new(halfW*2, wallThk, halfW*2), woodColor)
    floor.Material = Enum.Material.WoodPlanks

    -- Four walls (1m tall, open top)
    local wallDefs = {
        { Vector3.new(0,          wallMidY, -(halfW + wallThk/2)), Vector3.new(halfW*2 + wallThk*2, wallH, wallThk) },
        { Vector3.new(0,          wallMidY,  (halfW + wallThk/2)), Vector3.new(halfW*2 + wallThk*2, wallH, wallThk) },
        { Vector3.new(-(halfW + wallThk/2), wallMidY, 0),          Vector3.new(wallThk, wallH, halfW*2) },
        { Vector3.new( (halfW + wallThk/2), wallMidY, 0),          Vector3.new(wallThk, wallH, halfW*2) },
    }
    for i, wd in ipairs(wallDefs) do
        local w = makePart(basketFolder, "BasketWall"..i, wd[1], wd[2], woodColor)
        w.Material = Enum.Material.WoodPlanks
    end

    -- SpawnPosition: player stands on the floor inside the basket
    local spawnMarker = Instance.new("Vector3Value")
    spawnMarker.Name  = "SpawnPosition"
    -- HRP is ~3 studs above floor top face
    spawnMarker.Value = Vector3.new(0, LEVEL_Y_OFFSET + wallThk + 3.5, 0)
    spawnMarker.Parent = basketFolder

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
