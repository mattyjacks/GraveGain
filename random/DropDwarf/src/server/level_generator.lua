-- DropDwarf: level_generator.lua
-- Seeded procedural level: 1000m deep, randomized biome sequence, rich geometry

local GameData   = require(game.ReplicatedStorage.Shared.game_data)
local BiomeData  = require(game.ReplicatedStorage.Shared.biome_data)
local SeedSystem = require(game.ReplicatedStorage.Shared.seed_system)

local LevelGenerator = {}

-- Terrain type constants (tagged on platforms)
local TERRAIN_SOFT = "Soft"   -- pickaxe sticks, fall speed reduced
local TERRAIN_FIRM = "Firm"   -- needs heavy attack
local TERRAIN_HARD = "Hard"   -- always bounces

-- Per-biome terrain type distributions [Soft, Firm, Hard] cumulative weights
local BIOME_TERRAIN = {
    Volcano  = { soft = 0.15, firm = 0.55 }, -- mostly firm/hard, lava rock
    Fortress = { soft = 0.25, firm = 0.65 }, -- crumbled stone mixes
    Cave     = { soft = 0.40, firm = 0.75 }, -- crystal soil, mixed
    Mine     = { soft = 0.50, firm = 0.80 }, -- earthy, lots of soft
}

local function getTerrainType(biome, rng)
    local t = BIOME_TERRAIN[biome.name] or { soft = 0.33, firm = 0.66 }
    local r = rng:NextNumber()
    if r < t.soft then return TERRAIN_SOFT
    elseif r < t.firm then return TERRAIN_FIRM
    else return TERRAIN_HARD end
end

-- Moving platform configuration per biome
local BIOME_MOVING_PLATFORM = {
    Volcano  = { speed = 5,  axis = "X", range = 14 },
    Fortress = { speed = 3,  axis = "Z", range = 18 },
    Cave     = { speed = 6,  axis = "X", range = 12 },
    Mine     = { speed = 4,  axis = "Z", range = 16 },
}

-- Coin model: flat cylinder-like block
local function spawnCoin(parent, pos)
    local coin = Instance.new("Part")
    coin.Name = "GoldCoin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Size = Vector3.new(0.5, GameData.COIN_SIZE, GameData.COIN_SIZE)
    coin.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi/2)
    coin.Anchored = true
    coin.CanCollide = false
    coin.Color = Color3.fromRGB(255, 200, 0)
    coin.Material = Enum.Material.Neon
    coin.Transparency = 0.1
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 8
    light.Color = Color3.fromRGB(255, 220, 80)
    light.Parent = coin
    -- Tag
    local tag = Instance.new("StringValue")
    tag.Name = "IsCoin"
    tag.Value = "true"
    tag.Parent = coin
    coin.Parent = parent
    return coin
end

-- Hazard block (damages on touch)
local function spawnHazard(parent, pos, size, biome)
    local h = Instance.new("Part")
    h.Name = "Hazard"
    h.Size = size
    h.Position = pos
    h.Anchored = true
    h.CanCollide = true
    h.Color = biome.accentColor
    h.Material = Enum.Material.Neon
    h.Transparency = 0.3
    h.TopSurface = Enum.SurfaceType.Smooth
    h.BottomSurface = Enum.SurfaceType.Smooth
    local tag = Instance.new("StringValue")
    tag.Name = "IsHazard"
    tag.Value = tostring(biome.hazardDamage)
    tag.Parent = h
    local light = Instance.new("PointLight")
    light.Brightness = 1.5
    light.Range = 6
    light.Color = biome.accentColor
    light.Parent = h
    h.Parent = parent
    return h
end

-- Per-biome preferred wall/platform material (overrides generic SmoothPlastic)
local BIOME_MATERIAL = {
    Volcano  = Enum.Material.Slate,
    Fortress = Enum.Material.SmoothPlastic,  -- used with dark colors for stone look
    Cave     = Enum.Material.Granite,
    Mine     = Enum.Material.Sandstone,
}

-- Core part builder
local function makePart(parent, name, pos, size, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = pos
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Transparency = transparency or 0
    p.CastShadow = true
    p.Parent = parent
    return p
end

-- Get the preferred material for a biome
local function getBiomeMat(biome, override)
    return override or BIOME_MATERIAL[biome.name] or Enum.Material.SmoothPlastic
end

-- Platform block with terrain type tag
local function spawnPlatform(parent, pos, size, color, material, terrainType, biome)
    local mat = material
    if not mat and biome then
        mat = getBiomeMat(biome)
        -- Soft terrain overrides
        if terrainType == TERRAIN_SOFT then mat = Enum.Material.Mud
        elseif terrainType == TERRAIN_HARD then mat = Enum.Material.Granite end
    end
    local p = makePart(parent, "Platform", pos, size, color, mat or Enum.Material.SmoothPlastic)
    local tt = Instance.new("StringValue")
    tt.Name = "TerrainType"
    tt.Value = terrainType or TERRAIN_FIRM
    tt.Parent = p
    return p
end

-- Wall block
local function spawnWall(parent, pos, size, color, material, biome)
    local mat = material or (biome and getBiomeMat(biome)) or Enum.Material.SmoothPlastic
    local w = makePart(parent, "Wall", pos, size, color, mat)
    return w
end

-- Ceiling/tunnel roof
local function spawnCeiling(parent, pos, size, color, material, biome)
    local mat = material or (biome and getBiomeMat(biome)) or Enum.Material.SmoothPlastic
    return makePart(parent, "Ceiling", pos, size, color, mat)
end

-- Glow decoration block (neon, no collision)
local function spawnGlowBlock(parent, pos, size, color, brightness, range)
    local g = makePart(parent, "GlowBlock", pos, size, color, Enum.Material.Neon, 0.25)
    g.CanCollide = false
    g.CastShadow = false
    local pl = Instance.new("PointLight")
    pl.Brightness = brightness or 1.5
    pl.Range      = range or 12
    pl.Color      = color
    pl.Parent     = g
    return g
end

-- Biome ore configs: type name, color, gold value range, HP (hits to mine), glow color
local BIOME_ORE = {
    Volcano  = { { name="SulfurVein",  color=Color3.fromRGB(200,180,30),  gold={8,18},  hp=2, glow=Color3.fromRGB(255,220,50) },
                 { name="ObsidianShard", color=Color3.fromRGB(40,20,60),  gold={15,30}, hp=4, glow=Color3.fromRGB(160,80,255) } },
    Fortress = { { name="GoldVein",    color=Color3.fromRGB(220,180,40),  gold={12,25}, hp=3, glow=Color3.fromRGB(255,210,60) },
                 { name="SilverSeam",  color=Color3.fromRGB(190,190,200), gold={8,16},  hp=2, glow=Color3.fromRGB(220,230,255) } },
    Cave     = { { name="GoldVein",    color=Color3.fromRGB(215,175,35),  gold={10,22}, hp=3, glow=Color3.fromRGB(255,205,50) },
                 { name="GemCluster",  color=Color3.fromRGB(80,200,160),  gold={18,35}, hp=5, glow=Color3.fromRGB(100,255,200) } },
    Mine     = { { name="GoldVein",    color=Color3.fromRGB(225,185,40),  gold={14,28}, hp=3, glow=Color3.fromRGB(255,215,60) },
                 { name="CoalSeam",    color=Color3.fromRGB(25,25,30),    gold={4,10},  hp=1, glow=Color3.fromRGB(100,120,180) } },
}

-- Spawn a minable ore node embedded in a wall face
-- side: 1=NegX, 2=PosX, 3=NegZ, 4=PosZ  halfW: half-width of shaft
local function spawnWallOre(parent, side, yPos, halfW, biome, rng)
    local oreList = BIOME_ORE[biome.name]
    if not oreList or #oreList == 0 then return end

    -- Pick random ore type for this biome
    local ore = oreList[rng:NextInteger(1, #oreList)]
    local goldVal = rng:NextInteger(ore.gold[1], ore.gold[2])
    local depth = rng:NextNumber(0.8, 2.0)  -- how far it protrudes from wall
    local wSize = rng:NextNumber(2.5, 5.5)
    local hSize = rng:NextNumber(1.5, 3.5)

    -- Position on the chosen wall face
    local pos
    local wallX = halfW - depth / 2
    local wallZ = halfW - depth / 2
    local slideRange = GameData.LEVEL_WIDTH / 2 - 4
    if side == 1 then
        pos = Vector3.new(-wallX, yPos, rng:NextNumber(-slideRange, slideRange))
    elseif side == 2 then
        pos = Vector3.new(wallX, yPos, rng:NextNumber(-slideRange, slideRange))
    elseif side == 3 then
        pos = Vector3.new(rng:NextNumber(-slideRange, slideRange), yPos, -wallX)
    else
        pos = Vector3.new(rng:NextNumber(-slideRange, slideRange), yPos, wallX)
    end

    -- Main ore body (embedded in wall)
    local sizeX = (side == 1 or side == 2) and depth or wSize
    local sizeZ = (side == 3 or side == 4) and depth or wSize
    local oreBody = makePart(parent, "WallOre", pos,
        Vector3.new(sizeX, hSize, sizeZ), ore.color, Enum.Material.SmoothPlastic, 0)
    oreBody.CanCollide = false  -- no collision - pickaxe raycast detects it

    -- Neon vein streaks overlaid on top (thinner slab, brighter color)
    local streakDepth = depth + 0.05
    local streakSizeX = (side == 1 or side == 2) and streakDepth or wSize * 0.6
    local streakSizeZ = (side == 3 or side == 4) and streakDepth or wSize * 0.6
    local streak = makePart(parent, "OreStreak", pos,
        Vector3.new(streakSizeX, hSize * 0.5, streakSizeZ),
        ore.glow, Enum.Material.Neon, 0.45)
    streak.CanCollide = false

    -- Point light for glow (subtle - player will mine it up close)
    local pl = Instance.new("PointLight")
    pl.Brightness = 0.4
    pl.Range = 5
    pl.Color = ore.glow
    pl.Parent = oreBody

    -- Tags for server mining logic
    local mineTag = Instance.new("StringValue")
    mineTag.Name = "IsMineable"
    mineTag.Value = ore.name
    mineTag.Parent = oreBody

    local goldTag = Instance.new("IntValue")
    goldTag.Name = "GoldValue"
    goldTag.Value = goldVal
    goldTag.Parent = oreBody

    local hpTag = Instance.new("IntValue")
    hpTag.Name = "OreHp"
    hpTag.Value = ore.hp
    hpTag.Parent = oreBody

    local maxHpTag = Instance.new("IntValue")
    maxHpTag.Name = "OreMaxHp"
    maxHpTag.Value = ore.hp
    maxHpTag.Parent = oreBody

    -- Store streak ref so server can destroy it with the body
    local streakRef = Instance.new("ObjectValue")
    streakRef.Name = "OreStreak"
    streakRef.Value = streak
    streakRef.Parent = oreBody

    return oreBody
end

-- Stalactite: tapered wedge hanging from ceiling
local function spawnStalactite(parent, pos, biome, rng)
    local w = rng:NextInteger(2, 5)
    local h = rng:NextInteger(4, 14)
    local col = BiomeData.GetRandomColor(biome, rng)
    -- Body
    local body = makePart(parent, "Stalactite", pos, Vector3.new(w, h, w), col, Enum.Material.SmoothPlastic)
    -- Tip glow for cave/volcano
    if biome.name == "Cave" or biome.name == "Volcano" then
        local tipPos = Vector3.new(pos.X, pos.Y - h/2 - 0.5, pos.Z)
        spawnGlowBlock(parent, tipPos, Vector3.new(w*0.4, 1, w*0.4), biome.accentColor, 0.8, 6)
    end
    return body
end

-- Ore vein: small embedded neon strip in wall
local function spawnOreVein(parent, pos, biome, rng)
    local vW = rng:NextInteger(2, 6)
    local vH = rng:NextInteger(1, 3)
    local vD = rng:NextInteger(1, 2)
    local ore = makePart(parent, "OreVein", pos, Vector3.new(vW, vH, vD), biome.accentColor, Enum.Material.Neon, 0.1)
    ore.CanCollide = false
    local pl = Instance.new("PointLight")
    pl.Brightness = 0.8
    pl.Range = 8
    pl.Color = biome.accentColor
    pl.Parent = ore
    return ore
end

-- Rock pillar rising from a platform
local function spawnPillar(parent, basePos, height, color, material)
    local sections = math.ceil(height / 4)
    for i = 1, sections do
        local w = math.max(2, 5 - i)
        local y = basePos.Y + (i - 0.5) * 4
        makePart(parent, "Pillar", Vector3.new(basePos.X, y, basePos.Z),
            Vector3.new(w, 4, w), color, material or Enum.Material.SmoothPlastic)
    end
end

-- Decorative rubble cluster on a platform top surface
local function spawnRubble(parent, basePos, pW, pD, biome, rng, count)
    count = count or rng:NextInteger(2, 6)
    for i = 1, count do
        local rx = basePos.X + rng:NextNumber(-pW/2 + 1, pW/2 - 1)
        local rz = basePos.Z + rng:NextNumber(-pD/2 + 1, pD/2 - 1)
        local rs = rng:NextNumber(0.5, 2.5)
        local col = BiomeData.GetRandomColor(biome, rng)
        -- Rubble is never neon - just decorative rock chunks
        local rb = makePart(parent, "Rubble", Vector3.new(rx, basePos.Y + rs/2, rz),
            Vector3.new(rs, rs, rs), col, Enum.Material.SmoothPlastic, 0)
        rb.CanCollide = false
    end
end

-- Lava pool (animated neon surface, hazard)
local function spawnLavaPool(parent, pos, sizeX, sizeZ, biome)
    local pool = makePart(parent, "LavaPool", pos, Vector3.new(sizeX, 0.3, sizeZ),
        biome.lavaColor or Color3.fromRGB(255, 80, 0), Enum.Material.Neon, 0.15)
    pool.CanCollide = true
    local tag = Instance.new("StringValue")
    tag.Name = "IsHazard"
    tag.Value = tostring(biome.hazardDamage or 20)
    tag.Parent = pool
    local pl = Instance.new("PointLight")
    pl.Brightness = 3
    pl.Range = 18
    pl.Color = Color3.fromRGB(255, 100, 20)
    pl.Parent = pool
    return pool
end

-- Crystal formation: multiple wedge spikes
local function spawnCrystalCluster(parent, basePos, biome, rng, count)
    count = count or rng:NextInteger(2, 5)
    local crystalCol = biome.crystalColor or biome.accentColor
    for i = 1, count do
        local angle  = (i / count) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
        local radius = rng:NextNumber(0.4, 1.8)
        local cx = basePos.X + math.cos(angle) * radius
        local cz = basePos.Z + math.sin(angle) * radius
        local ch = rng:NextInteger(2, 5)  -- was 3-10, too tall
        local cw = rng:NextInteger(1, 2)  -- was 1-3, too wide
        local crystal = makePart(parent, "Crystal",
            Vector3.new(cx, basePos.Y + ch/2, cz),
            Vector3.new(cw, ch, cw), crystalCol, Enum.Material.Neon, 0.55)
        crystal.CFrame = crystal.CFrame * CFrame.Angles(
            rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25))
        crystal.CanCollide = false  -- don't block player movement
        local pl = Instance.new("PointLight")
        pl.Brightness = 0.25
        pl.Range = 4
        pl.Color = crystalCol
        pl.Parent = crystal
    end
end

-- Moving platform anchor (client reads MovePlatform tag and animates)
local function spawnMovingPlatform(parent, pos, size, color, biome, rng, seed)
    local cfg = BIOME_MOVING_PLATFORM[biome.name] or { speed = 4, axis = "X", range = 12 }
    local p = spawnPlatform(parent, pos, size, color, Enum.Material.SmoothPlastic, TERRAIN_FIRM)
    p.Name = "MovingPlatform"
    -- Store config as StringValue for client
    local mv = Instance.new("StringValue")
    mv.Name = "MovePlatform"
    -- format: axis,speed,range,startX,startY,startZ
    mv.Value = string.format("%s,%.2f,%.2f,%.3f,%.3f,%.3f",
        cfg.axis, cfg.speed, cfg.range, pos.X, pos.Y, pos.Z)
    mv.Parent = p
    -- Glow strip on top
    spawnGlowBlock(parent, Vector3.new(pos.X, pos.Y + size.Y/2 + 0.15, pos.Z),
        Vector3.new(size.X * 0.8, 0.3, size.Z * 0.8), biome.accentColor, 1.0, 8)
    return p
end

-- Finish platform at bottom
local function spawnFinish(parent, worldY)
    local p = Instance.new("Part")
    p.Name = "FinishPlatform"
    p.Size = Vector3.new(GameData.LEVEL_WIDTH, 2, GameData.LEVEL_WIDTH)
    p.Position = Vector3.new(0, worldY - 1, 0)
    p.Anchored = true
    p.Color = Color3.fromRGB(255, 220, 60)
    p.Material = Enum.Material.Neon
    p.Transparency = 0.2
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent

    local light = Instance.new("PointLight")
    light.Brightness = 5
    light.Range = 60
    light.Color = Color3.fromRGB(255, 240, 100)
    light.Parent = p

    local tag = Instance.new("StringValue")
    tag.Name = "IsFinish"
    tag.Value = "true"
    tag.Parent = p

    -- Label
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 400, 0, 100)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.AlwaysOnTop = false
    bb.Parent = p
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "BOTTOM - 1000m"
    tl.TextColor3 = Color3.new(1, 1, 0.5)
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Parent = bb

    return p
end

-- Biome transition marker
local function spawnBiomeMarker(parent, worldY, biomeName, color)
    local marker = Instance.new("Part")
    marker.Name = "BiomeMarker_" .. biomeName
    marker.Size = Vector3.new(GameData.LEVEL_WIDTH + 20, 0.5, GameData.LEVEL_WIDTH + 20)
    marker.Position = Vector3.new(0, worldY, 0)
    marker.Anchored = true
    marker.CanCollide = false
    marker.Color = color
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.7
    marker.Parent = parent

    -- Tag for client biome detection
    local tag = Instance.new("StringValue")
    tag.Name = "BiomeName"
    tag.Value = biomeName
    tag.Parent = marker
    return marker
end

-- Returns a table of slime patrol spawn records for this section
-- { pos=Vector3, size="Large"|"Medium"|"Small"|"Tiny", patrolEnd=Vector3 }
local function generateBiomeSection(folder, biome, startDepthMeters, endDepthMeters, seed)
    local rng       = SeedSystem.NewRNG(seed, biome.name)
    local BLOCK     = 4
    local startY    = GameData.DepthToWorldY(startDepthMeters)
    local endY      = GameData.DepthToWorldY(endDepthMeters)
    local totalStuds = startY - endY
    local halfW     = GameData.LEVEL_WIDTH / 2 + 4
    local wallThick = 10
    local wallCenterY = startY - totalStuds / 2

    local slimeSpawns = {} -- returned to Generate()

    -- Biome marker
    spawnBiomeMarker(folder, startY, biome.name, biome.accentColor)

    -- ==== WALLS: multi-layer with face detail ====
    local biomeMat = getBiomeMat(biome)
    -- Use biome.wallColors if defined (Fortress), otherwise random from palette
    local wallColors = biome.wallColors or {
        BiomeData.GetRandomColor(biome, rng),
        BiomeData.GetRandomColor(biome, rng),
        BiomeData.GetRandomColor(biome, rng),
        BiomeData.GetRandomColor(biome, rng),
    }
    -- Primary outer walls
    local wallDirs = {
        { pos = Vector3.new(-halfW - wallThick/2, wallCenterY, 0),
          size = Vector3.new(wallThick, totalStuds, GameData.LEVEL_WIDTH + wallThick*2) },
        { pos = Vector3.new(halfW  + wallThick/2, wallCenterY, 0),
          size = Vector3.new(wallThick, totalStuds, GameData.LEVEL_WIDTH + wallThick*2) },
        { pos = Vector3.new(0, wallCenterY, -halfW - wallThick/2),
          size = Vector3.new(GameData.LEVEL_WIDTH + wallThick*2, totalStuds, wallThick) },
        { pos = Vector3.new(0, wallCenterY,  halfW + wallThick/2),
          size = Vector3.new(GameData.LEVEL_WIDTH + wallThick*2, totalStuds, wallThick) },
    }
    for i, wd in ipairs(wallDirs) do
        spawnWall(folder, wd.pos, wd.size, wallColors[((i-1)%#wallColors)+1], biomeMat)
    end

    -- Wall face detail: protruding rock slabs every ~20 studs
    local slabInterval = 20
    local slabY = startY - slabInterval / 2
    while slabY > endY do
        -- 4 sides, random chance per side
        for side = 1, 4 do
            if rng:NextNumber() < 0.55 then
                local sW = rng:NextInteger(3, 10)
                local sH = rng:NextInteger(2, 8)
                local sD = rng:NextInteger(2, 5)
                local sColor = BiomeData.GetRandomColor(biome, rng)
                local sY = slabY + rng:NextNumber(-4, 4)
                local sPos
                if side == 1 then
                    sPos = Vector3.new(-halfW + sD/2, sY, rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW))
                    spawnWall(folder, sPos, Vector3.new(sD, sH, sW), sColor, biomeMat)
                elseif side == 2 then
                    sPos = Vector3.new(halfW - sD/2, sY, rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW))
                    spawnWall(folder, sPos, Vector3.new(sD, sH, sW), sColor, biomeMat)
                elseif side == 3 then
                    sPos = Vector3.new(rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW), sY, -halfW + sD/2)
                    spawnWall(folder, sPos, Vector3.new(sW, sH, sD), sColor, biomeMat)
                else
                    sPos = Vector3.new(rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW), sY, halfW - sD/2)
                    spawnWall(folder, sPos, Vector3.new(sW, sH, sD), sColor, biomeMat)
                end
            end
        end
        -- Ore veins embedded in walls
        if rng:NextNumber() < 0.4 then
            local vSide = rng:NextInteger(1, 4)
            local vX = vSide == 1 and (-halfW + 1) or (vSide == 2 and (halfW - 1) or rng:NextNumber(-halfW+2, halfW-2))
            local vZ = vSide == 3 and (-halfW + 1) or (vSide == 4 and (halfW - 1) or rng:NextNumber(-halfW+2, halfW-2))
            spawnOreVein(folder, Vector3.new(vX, slabY + rng:NextNumber(-6, 6), vZ), biome, rng)
        end
        slabY = slabY - slabInterval
    end

    -- Biome-specific wall styles: extra character
    if biome.wallStyle == "cliff" then
        -- Volcano: lava river channels down walls + hanging drips
        for si = 1, 12 do
            local lY = startY - (totalStuds / 12 * si) + rng:NextNumber(-3, 3)
            local side = rng:NextNumber() > 0.5 and (-halfW + 1) or (halfW - 1)
            local w = rng:NextInteger(2, 8)
            local lavaStrip = spawnWall(folder, Vector3.new(side, lY, rng:NextNumber(-20, 20)),
                Vector3.new(2, w, rng:NextInteger(3, 12)),
                biome.lavaColor or biome.accentColor, Enum.Material.Neon)
            lavaStrip.Transparency = 0.15
            local lpl = Instance.new("PointLight")
            lpl.Brightness = 2.5; lpl.Range = 16; lpl.Color = Color3.fromRGB(255, 80, 10)
            lpl.Parent = lavaStrip
        end
        -- Hanging obsidian spikes from ceiling sections
        for si = 1, 8 do
            local spY = startY - (totalStuds / 8 * si) + rng:NextNumber(-5, 5)
            if spY > endY then
                local spX = rng:NextNumber(-halfW + 5, halfW - 5)
                local spZ = rng:NextNumber(-halfW + 5, halfW - 5)
                spawnStalactite(folder, Vector3.new(spX, spY, spZ), biome, rng)
            end
        end

    elseif biome.wallStyle == "brick" then
        -- Fortress: dark stone arched frames + torch sconces (reference: gritty dungeon)
        for si = 1, 10 do
            local archY = startY - (totalStuds / 10 * si)
            local archColor = Color3.fromRGB(
                rng:NextInteger(35, 58), rng:NextInteger(33, 52), rng:NextInteger(28, 46))
            -- Arch frames on all 4 sides
            spawnWall(folder, Vector3.new(0, archY, -halfW + 3),
                Vector3.new(GameData.LEVEL_WIDTH - 4, 4, 5), archColor, Enum.Material.SmoothPlastic)
            spawnWall(folder, Vector3.new(0, archY, halfW - 3),
                Vector3.new(GameData.LEVEL_WIDTH - 4, 4, 5), archColor, Enum.Material.SmoothPlastic)
            spawnWall(folder, Vector3.new(-halfW + 3, archY, 0),
                Vector3.new(5, 4, GameData.LEVEL_WIDTH - 4), archColor, Enum.Material.SmoothPlastic)
            spawnWall(folder, Vector3.new(halfW - 3, archY, 0),
                Vector3.new(5, 4, GameData.LEVEL_WIDTH - 4), archColor, Enum.Material.SmoothPlastic)
            -- Torch sconces (much brighter to compensate for near-black ambient)
            for t = 1, rng:NextInteger(1, 3) do
                local torchSide = rng:NextNumber() > 0.5 and (-halfW + 2) or (halfW - 2)
                local torchZ2 = rng:NextNumber(-halfW/2, halfW/2)
                local torchY = archY + rng:NextNumber(0, 5)
                -- Torch bracket
                spawnGlowBlock(folder, Vector3.new(torchSide, torchY, torchZ2),
                    Vector3.new(1.5, 4, 1.5), Color3.fromRGB(255, 140, 30), 5, 32)
                -- Secondary flame puff above
                spawnGlowBlock(folder, Vector3.new(torchSide, torchY + 2.5, torchZ2),
                    Vector3.new(1, 1.5, 1), Color3.fromRGB(255, 220, 80), 3, 20)
            end
        end
        -- Battlements on top of walls: crenellations
        for ci = 1, 8 do
            local cX = -halfW + ci * (GameData.LEVEL_WIDTH / 8)
            spawnWall(folder, Vector3.new(cX, startY + 2, -halfW - 2),
                Vector3.new(4, 4, 4), Color3.fromRGB(90, 82, 68), Enum.Material.SmoothPlastic)
            spawnWall(folder, Vector3.new(cX, startY + 2, halfW + 2),
                Vector3.new(4, 4, 4), Color3.fromRGB(90, 82, 68), Enum.Material.SmoothPlastic)
        end

    elseif biome.wallStyle == "cave" then
        -- Cave: dense crystal formations + bioluminescent patches
        for si = 1, 16 do
            local cY = startY - (totalStuds / 16 * si) + rng:NextNumber(-4, 4)
            local side = rng:NextNumber() > 0.5 and (-halfW + 3) or (halfW - 3)
            local cZ = rng:NextNumber(-halfW + 3, halfW - 3)
            spawnCrystalCluster(folder, Vector3.new(side, cY, cZ), biome, rng, rng:NextInteger(4, 9))
        end
        -- Floor-rising stalagmites (spawn at bottom of each section tier)
        for si = 1, 6 do
            local sY = endY + (totalStuds / 6 * si) - rng:NextNumber(0, 8)
            if sY < startY and sY > endY then
                local sX = rng:NextNumber(-halfW + 4, halfW - 4)
                local sZ = rng:NextNumber(-halfW + 4, halfW - 4)
                -- Stalagmite: pillar pointing up with glow tip
                local stagH = rng:NextInteger(6, 18)
                local stagCol = BiomeData.GetRandomColor(biome, rng)
                spawnPillar(folder, Vector3.new(sX, sY, sZ), stagH, stagCol, Enum.Material.SmoothPlastic)
                local tipCol = biome.crystalColor or biome.accentColor
                spawnGlowBlock(folder, Vector3.new(sX, sY + stagH + 1, sZ),
                    Vector3.new(2, 2, 2), tipCol, 0.6, 7)
            end
        end
        -- Bioluminescent wall patches (reduced count and brightness)
        local bioCol = biome.crystalColor or biome.accentColor
        for si = 1, 6 do  -- reduced from 12 - fewer glowing patches
            local pY = startY - rng:NextNumber(0, totalStuds)
            local pSide = rng:NextInteger(1, 4)
            local pX = pSide == 1 and (-halfW + 0.5) or (pSide == 2 and (halfW - 0.5) or rng:NextNumber(-halfW+2, halfW-2))
            local pZ = pSide == 3 and (-halfW + 0.5) or (pSide == 4 and (halfW - 0.5) or rng:NextNumber(-halfW+2, halfW-2))
            local pW = rng:NextInteger(1, 3)  -- was 2-5, smaller
            local biolum = spawnGlowBlock(folder, Vector3.new(pX, pY, pZ),
                Vector3.new(pW, rng:NextInteger(1, 2), pW),
                bioCol, 0.15, 4)  -- brightness 0.15, range 4
            biolum.Transparency = 0.7  -- mostly transparent

        end

    elseif biome.wallStyle == "shaft" then
        -- Mine: heavy timber support beams + lanterns + cracked sections
        for si = 1, 12 do
            local beamY = startY - (totalStuds / 12 * si)
            local woodCol = Color3.fromRGB(rng:NextInteger(90,130), rng:NextInteger(60,90), rng:NextInteger(30,55))
            -- Horizontal cross-beams
            spawnWall(folder, Vector3.new(0, beamY, 0),
                Vector3.new(GameData.LEVEL_WIDTH + wallThick, 3, 3), woodCol, Enum.Material.Wood)
            spawnWall(folder, Vector3.new(0, beamY, 0),
                Vector3.new(3, 3, GameData.LEVEL_WIDTH + wallThick), woodCol, Enum.Material.Wood)
            -- Vertical side posts
            spawnWall(folder, Vector3.new(-halfW + 2, beamY - 6, 0),
                Vector3.new(4, 12, 4), woodCol, Enum.Material.Wood)
            spawnWall(folder, Vector3.new(halfW - 2, beamY - 6, 0),
                Vector3.new(4, 12, 4), woodCol, Enum.Material.Wood)
            -- Hanging lanterns
            if rng:NextNumber() < 0.6 then
                local lX = rng:NextNumber(-halfW/2, halfW/2)
                local lZ = rng:NextNumber(-halfW/2, halfW/2)
                spawnGlowBlock(folder, Vector3.new(lX, beamY - 3, lZ),
                    Vector3.new(2, 3, 2), Color3.fromRGB(220, 170, 60), 2.5, 18)
            end
            -- Cracked wall section (dark patch)
            if rng:NextNumber() < 0.4 then
                local crX = rng:NextNumber() > 0.5 and (-halfW + 2) or (halfW - 2)
                spawnWall(folder, Vector3.new(crX, beamY + rng:NextNumber(-4, 4), rng:NextNumber(-10, 10)),
                    Vector3.new(3, rng:NextInteger(4, 10), rng:NextInteger(3, 8)),
                    Color3.fromRGB(20, 15, 8), Enum.Material.SmoothPlastic)
            end
        end
        -- Gold vein glow clusters along mine floor
        for si = 1, 8 do
            local gY = startY - (totalStuds / 8 * si) + rng:NextNumber(-5, 5)
            local gX = rng:NextNumber(-halfW + 2, halfW - 2)
            local gZ = rng:NextNumber(-halfW + 2, halfW - 2)
            spawnOreVein(folder, Vector3.new(gX, gY, gZ), biome, rng)
        end
    end

    -- ==== WALL ORE NODES (minable gold/gems) ====
    -- Spawn 8-14 ore pockets scattered on all 4 walls throughout this section
    local oreCount = rng:NextInteger(8, 14)
    for oi = 1, oreCount do
        local oreY = startY - (totalStuds / oreCount * oi) + rng:NextNumber(-8, 8)
        if oreY < startY and oreY > endY + 5 then
            local side = rng:NextInteger(1, 4)
            spawnWallOre(folder, side, oreY, halfW, biome, rng)
        end
    end

    -- ==== PLATFORM GENERATION ====
    -- For the first biome section (startDepthMeters == 0), skip the top 80 studs
    -- so the player has room to fall in before hitting the first platform.
    local ENTRY_CLEARANCE = startDepthMeters == 0 and 80 or 0
    local currentY = startY - BLOCK - ENTRY_CLEARANCE
    local platformIndex = 0

    while currentY > endY do
        platformIndex = platformIndex + 1
        local platRng = SeedSystem.ChildRNG(seed .. biome.name, platformIndex)

        local pW = platRng:NextInteger(biome.platform.minX, biome.platform.maxX)
        local pD = platRng:NextInteger(biome.platform.minZ, biome.platform.maxZ)
        local pH = platRng:NextInteger(2, BLOCK) -- variable height for visual depth

        local maxDrift = math.max(0, (GameData.LEVEL_WIDTH / 2) - (math.max(pW, pD) / 2) - 2)
        local pX = platRng:NextNumber(-maxDrift, maxDrift)
        local pZ = platRng:NextNumber(-maxDrift, maxDrift)
        local pColor = BiomeData.GetRandomColor(biome, platRng)
        local terrainType = getTerrainType(biome, platRng)

        -- Decide if this platform moves
        local isMoving = platRng:NextNumber() < 0.18

        if isMoving then
            spawnMovingPlatform(folder,
                Vector3.new(pX, currentY - pH/2, pZ),
                Vector3.new(pW, pH, pD), pColor, biome, platRng, seed)
        else
            local mat = Enum.Material.SmoothPlastic
            if terrainType == TERRAIN_SOFT then mat = Enum.Material.Mud
            elseif terrainType == TERRAIN_HARD then mat = Enum.Material.Granite end
            spawnPlatform(folder,
                Vector3.new(pX, currentY - pH/2, pZ),
                Vector3.new(pW, pH, pD), pColor, mat, terrainType)
        end

        local platTopY = currentY -- top surface Y of platform

        -- === Under-platform stalactites (hanging from bottom edge) ===
        if platRng:NextNumber() < 0.45 then
            local stCount = platRng:NextInteger(1, 4)
            for st = 1, stCount do
                local stX = pX + platRng:NextNumber(-pW/2 + 1, pW/2 - 1)
                local stZ = pZ + platRng:NextNumber(-pD/2 + 1, pD/2 - 1)
                spawnStalactite(folder,
                    Vector3.new(stX, currentY - pH - platRng:NextInteger(3, 10), stZ),
                    biome, platRng)
            end
        end

        -- === Layered platform underside (recessed blocks below) ===
        if platRng:NextNumber() < 0.5 then
            local layers = platRng:NextInteger(1, 3)
            for li = 1, layers do
                local lOff = li * 2
                local lCol = BiomeData.GetRandomColor(biome, platRng)
                spawnWall(folder,
                    Vector3.new(pX, currentY - pH - lOff, pZ),
                    Vector3.new(math.max(2, pW - li*2), 2, math.max(2, pD - li*2)),
                    lCol, Enum.Material.SmoothPlastic)
            end
        end

        -- === Surface detail: rubble, rubble, special blocks ===
        spawnRubble(folder, Vector3.new(pX, platTopY, pZ), pW, pD, biome, platRng)

        -- Biome special surface blocks
        if biome.name == "Volcano" and platRng:NextNumber() < 0.35 then
            -- Lava pool on platform surface
            local lpW = platRng:NextInteger(3, math.max(4, pW - 4))
            local lpD = platRng:NextInteger(3, math.max(4, pD - 4))
            spawnLavaPool(folder, Vector3.new(pX, platTopY + 0.2, pZ), lpW, lpD, biome)
        elseif biome.name == "Cave" and platRng:NextNumber() < 0.40 then
            -- Crystal cluster growing from platform
            spawnCrystalCluster(folder, Vector3.new(
                pX + platRng:NextNumber(-pW/3, pW/3),
                platTopY,
                pZ + platRng:NextNumber(-pD/3, pD/3)),
                biome, platRng, platRng:NextInteger(3, 8))
        elseif biome.name == "Fortress" and platRng:NextNumber() < 0.3 then
            -- Stone pillars on platform
            local pilH = platRng:NextInteger(6, 16)
            spawnPillar(folder,
                Vector3.new(pX + platRng:NextNumber(-pW/3, pW/3), platTopY, pZ + platRng:NextNumber(-pD/3, pD/3)),
                pilH, BiomeData.GetRandomColor(biome, platRng), Enum.Material.SmoothPlastic)
        elseif biome.name == "Mine" and platRng:NextNumber() < 0.45 then
            -- Ore veins on platform surface
            for ov = 1, platRng:NextInteger(1, 3) do
                spawnOreVein(folder,
                    Vector3.new(pX + platRng:NextNumber(-pW/2+1, pW/2-1), platTopY + 0.5, pZ + platRng:NextNumber(-pD/2+1, pD/2-1)),
                    biome, platRng)
            end
        end

        -- === Hazard (skip first 3 platforms - player needs landing room) ===
        if platformIndex > 3 and platRng:NextNumber() < biome.hazardChance then
            local hW = platRng:NextInteger(3, math.max(3, math.min(pW - 2, 8)))
            local hD = platRng:NextInteger(3, math.max(3, math.min(pD - 2, 8)))
            spawnHazard(folder, Vector3.new(pX, platTopY + 0.5, pZ),
                Vector3.new(hW, 1, hD), biome)
        end

        -- === Tunnel ceiling with stalactites ===
        if platRng:NextNumber() < biome.tunnelChance then
            local ceilH = platRng:NextInteger(10, 20)
            local ceilY = platTopY + ceilH
            if ceilY < startY then
                local ceilColor = BiomeData.GetRandomColor(biome, platRng)
                spawnCeiling(folder, Vector3.new(pX, ceilY, pZ),
                    Vector3.new(pW + 6, BLOCK, pD + 6), ceilColor, Enum.Material.SmoothPlastic)
                -- Stalactites hanging from ceiling
                local cStCount = platRng:NextInteger(2, 5)
                for csi = 1, cStCount do
                    local csX = pX + platRng:NextNumber(-pW/2, pW/2)
                    local csZ = pZ + platRng:NextNumber(-pD/2, pD/2)
                    local csH = platRng:NextInteger(3, ceilH - 4)
                    spawnStalactite(folder, Vector3.new(csX, ceilY - csH/2, csZ), biome, platRng)
                end
                -- Ambient glow inside tunnel
                local tunnelGlowCol = biome.crystalColor or biome.accentColor
                spawnGlowBlock(folder, Vector3.new(pX, ceilY - ceilH/2, pZ),
                    Vector3.new(1, 1, 1), tunnelGlowCol, 0.3, 8)
            end
        end

        -- === Coin ===
        if platRng:NextNumber() < biome.coinChance then
            local coinX = pX + platRng:NextNumber(-pW/2 + 1, pW/2 - 1)
            local coinZ = pZ + platRng:NextNumber(-pD/2 + 1, pD/2 - 1)
            spawnCoin(folder, Vector3.new(coinX, platTopY + 2, coinZ))
        end

        -- === Secondary stepping-stone platform ===
        if platRng:NextNumber() < 0.50 then
            local s2W  = platRng:NextInteger(5, 14)
            local s2D  = platRng:NextInteger(5, 14)
            local s2H  = platRng:NextInteger(2, BLOCK)
            local s2X  = platRng:NextNumber(-maxDrift, maxDrift)
            local s2Z  = platRng:NextNumber(-maxDrift, maxDrift)
            local s2Color = BiomeData.GetRandomColor(biome, platRng)
            local s2Drop  = platRng:NextNumber(biome.dropMin * 0.4, biome.dropMax * 0.6)
            local s2Y  = currentY - s2Drop
            if s2Y > endY then
                local s2Terrain = getTerrainType(biome, platRng)
                local s2Mat = s2Terrain == TERRAIN_SOFT and Enum.Material.Mud
                    or s2Terrain == TERRAIN_HARD and Enum.Material.Granite
                    or Enum.Material.SmoothPlastic
                spawnPlatform(folder,
                    Vector3.new(s2X, s2Y - s2H/2, s2Z),
                    Vector3.new(s2W, s2H, s2D), s2Color, s2Mat, s2Terrain)
                -- Occasional tiny glow accent dot on stepping stone edge
                if platRng:NextNumber() < 0.2 then
                    local glowCol = biome.crystalColor or biome.accentColor
                    local dot = spawnGlowBlock(folder,
                        Vector3.new(s2X + platRng:NextNumber(-s2W/3,s2W/3), s2Y + 0.3, s2Z + platRng:NextNumber(-s2D/3,s2D/3)),
                        Vector3.new(0.6, 0.3, 0.6),
                        glowCol, 0.2, 4)
                end
            end
        end

        -- === Third bridge platform (wide, rare) ===
        if platRng:NextNumber() < 0.20 then
            local b3W = platRng:NextInteger(10, 20)
            local b3D = platRng:NextInteger(3, 6)
            local b3X = platRng:NextNumber(-maxDrift, maxDrift)
            local b3Z = platRng:NextNumber(-maxDrift, maxDrift)
            local b3Drop = platRng:NextNumber(biome.dropMax * 0.3, biome.dropMax * 0.7)
            local b3Y = currentY - b3Drop
            if b3Y > endY then
                spawnPlatform(folder,
                    Vector3.new(b3X, b3Y - 2, b3Z),
                    Vector3.new(b3W, 2, b3D),
                    BiomeData.GetRandomColor(biome, platRng),
                    Enum.Material.SmoothPlastic, TERRAIN_FIRM)
            end
        end

        -- === Slime patrol spawn point (seeded) ===
        if platRng:NextNumber() < 0.22 and not isMoving then
            local slimeSizes = { "Large", "Medium", "Small", "Tiny" }
            local sizeWeights = { 0.15, 0.35, 0.35, 0.15 }
            local sRoll = platRng:NextNumber()
            local slimeSize = "Small"
            local cumulative = 0
            for si, sw in ipairs(sizeWeights) do
                cumulative = cumulative + sw
                if sRoll < cumulative then
                    slimeSize = slimeSizes[si]
                    break
                end
            end
            -- Patrol end: opposite corner of platform
            local patrolRange = platRng:NextNumber(6, 16)
            local patrolAngle = platRng:NextNumber(0, math.pi * 2)
            local patrolEnd = Vector3.new(
                pX + math.cos(patrolAngle) * patrolRange,
                platTopY + 2,
                pZ + math.sin(patrolAngle) * patrolRange)
            table.insert(slimeSpawns, {
                pos       = Vector3.new(pX, platTopY + 2, pZ),
                patrolEnd = patrolEnd,
                size      = slimeSize,
                platform  = Vector3.new(pX, platTopY, pZ),
            })
        end

        -- Drop to next platform
        local drop = platRng:NextNumber(biome.dropMin, biome.dropMax)
        currentY = currentY - drop
    end

    -- === Ambient atmosphere lights along shaft (invisible source, just the PointLight) ===
    local lightSpacing = 40  -- was 28, fewer lights
    local lY = startY - lightSpacing
    while lY > endY do
        local lPart = makePart(folder, "ShaftLight",
            Vector3.new(rng:NextNumber(-halfW+8, halfW-8), lY, rng:NextNumber(-halfW+8, halfW-8)),
            Vector3.new(0.5, 0.5, 0.5), biome.accentColor, Enum.Material.Neon, 1)  -- fully transparent
        lPart.CanCollide = false
        lPart.CastShadow = false
        local lpl = Instance.new("PointLight")
        lpl.Brightness = rng:NextNumber(0.3, 0.8)  -- was 0.5-1.5
        lpl.Range = rng:NextNumber(14, 22)          -- was 20-40
        lpl.Color = biome.ambientColor
        lpl.Parent = lPart
        lY = lY - lightSpacing
    end

    return endY, slimeSpawns
end

-- Main generation entry point
-- seed: string or number
-- Returns levelFolder, biomeSequence (array of 10 biome objects)
function LevelGenerator.Generate(workspace, seed)
    local seedStr = tostring(seed)

    -- Generate the randomized 10-biome sequence for this seed
    local biomeSequence = BiomeData.GenerateSequence(seedStr)

    -- Clear old level
    local existing = workspace:FindFirstChild("Level")
    if existing then existing:Destroy() end

    local levelFolder = Instance.new("Folder")
    levelFolder.Name = "Level"
    levelFolder.Parent = workspace

    -- Store biome sequence names in folder for server lookup
    local seqStore = Instance.new("StringValue")
    seqStore.Name = "BiomeSequence"
    seqStore.Value = ""
    local names = {}
    for i, b in ipairs(biomeSequence) do
        names[i] = b.name
    end
    seqStore.Value = table.concat(names, ",")
    seqStore.Parent = levelFolder

    -- ============================================================
    -- SURFACE CAP: solid ceiling above the level so the player
    -- spawns BELOW it already inside the shaft. No hole needed.
    -- Player teleports to Y = SPAWN_Y (negative, inside shaft).
    -- ============================================================
    local surfaceY = GameData.LEVEL_Y_OFFSET  -- 0
    local W        = GameData.LEVEL_WIDTH      -- 60
    -- Solid rock cap sealing the top of the level (player never sees the sky)
    local capColor = Color3.fromRGB(55, 52, 46)
    makePart(levelFolder, "SurfaceCap",
        Vector3.new(0, surfaceY + 5, 0),
        Vector3.new(W + 20, 10, W + 20), capColor, Enum.Material.SmoothPlastic)

    -- ============================================================
    -- DWARVEN BASKET + CHAIN
    -- A wrought-iron basket hangs at spawn (Y=-10) from a chain
    -- of steel links that disappears into the rock ceiling above.
    -- Player spawns standing on the basket floor.
    -- ============================================================
    local basketY   = -10   -- basket center Y (matches spawnY in main.server.lua)
    local basketW   = 10    -- basket interior width
    local basketH   = 5     -- basket wall height
    local basketT   = 1     -- wall thickness
    local steelColor = Color3.fromRGB(60, 65, 72)    -- dwarven steel: cold blue-gray
    local steelMat   = Enum.Material.Metal
    local accentColor = Color3.fromRGB(90, 78, 55)   -- brass/bronze rivets accent

    -- Basket floor
    local basketFloor = makePart(levelFolder, "BasketFloor",
        Vector3.new(0, basketY - basketH/2, 0),
        Vector3.new(basketW, 0.8, basketW), steelColor, steelMat)
    -- Cross-bracing on floor (X pattern)
    makePart(levelFolder, "BasketBraceA",
        Vector3.new(0, basketY - basketH/2 + 0.5, 0),
        Vector3.new(basketW, 0.4, 0.6), accentColor, Enum.Material.Metal)
    makePart(levelFolder, "BasketBraceB",
        Vector3.new(0, basketY - basketH/2 + 0.5, 0),
        Vector3.new(0.6, 0.4, basketW), accentColor, Enum.Material.Metal)

    -- 4 basket walls with geometric cutouts (dwarven pattern)
    local wallY = basketY - basketH/2 + basketH/2 + 0.4  -- wall center Y
    -- North wall
    makePart(levelFolder, "BasketWallN",
        Vector3.new(0, wallY, -(basketW/2 - basketT/2)),
        Vector3.new(basketW, basketH, basketT), steelColor, steelMat)
    -- South wall
    makePart(levelFolder, "BasketWallS",
        Vector3.new(0, wallY, (basketW/2 - basketT/2)),
        Vector3.new(basketW, basketH, basketT), steelColor, steelMat)
    -- West wall
    makePart(levelFolder, "BasketWallW",
        Vector3.new(-(basketW/2 - basketT/2), wallY, 0),
        Vector3.new(basketT, basketH, basketW), steelColor, steelMat)
    -- East wall
    makePart(levelFolder, "BasketWallE",
        Vector3.new((basketW/2 - basketT/2), wallY, 0),
        Vector3.new(basketT, basketH, basketW), steelColor, steelMat)

    -- Decorative geometric panels on each wall (dwarven angular motif)
    local panelY = wallY + 0.5
    for _, sign in ipairs({-1, 1}) do
        -- Diagonal struts on N/S walls
        local diagN = makePart(levelFolder, "DiagN" .. sign,
            Vector3.new(sign * basketW * 0.25, panelY, -(basketW/2 - basketT/2)),
            Vector3.new(0.5, basketH * 0.6, basketT + 0.2), accentColor, Enum.Material.Metal)
        diagN.CFrame = CFrame.new(diagN.Position) * CFrame.Angles(0, 0, math.rad(30 * sign))
        local diagS = makePart(levelFolder, "DiagS" .. sign,
            Vector3.new(sign * basketW * 0.25, panelY, (basketW/2 - basketT/2)),
            Vector3.new(0.5, basketH * 0.6, basketT + 0.2), accentColor, Enum.Material.Metal)
        diagS.CFrame = CFrame.new(diagS.Position) * CFrame.Angles(0, 0, math.rad(30 * sign))
    end

    -- 4 corner posts (thicker pillars at basket corners)
    for _, cx in ipairs({-1, 1}) do
        for _, cz in ipairs({-1, 1}) do
            makePart(levelFolder, "CornerPost",
                Vector3.new(cx * (basketW/2 - 0.5), wallY + 0.5, cz * (basketW/2 - 0.5)),
                Vector3.new(1.2, basketH + 1.5, 1.2), accentColor, Enum.Material.Metal)
        end
    end

    -- Rim cap along top of walls
    makePart(levelFolder, "BasketRimN",
        Vector3.new(0, wallY + basketH/2 + 0.3, -(basketW/2)),
        Vector3.new(basketW + 1.5, 0.6, 1.5), accentColor, Enum.Material.Metal)
    makePart(levelFolder, "BasketRimS",
        Vector3.new(0, wallY + basketH/2 + 0.3, (basketW/2)),
        Vector3.new(basketW + 1.5, 0.6, 1.5), accentColor, Enum.Material.Metal)
    makePart(levelFolder, "BasketRimW",
        Vector3.new(-(basketW/2), wallY + basketH/2 + 0.3, 0),
        Vector3.new(1.5, 0.6, basketW - 1.5), accentColor, Enum.Material.Metal)
    makePart(levelFolder, "BasketRimE",
        Vector3.new((basketW/2), wallY + basketH/2 + 0.3, 0),
        Vector3.new(1.5, 0.6, basketW - 1.5), accentColor, Enum.Material.Metal)

    -- Chain links from basket top to surface cap
    -- Alternating horizontal/vertical ovals for chain effect
    local chainTopY   = surfaceY + 0.5   -- just below the cap underside
    local chainBotY   = wallY + basketH/2 + 1.5  -- just above basket rim
    local chainSteps  = math.ceil((chainTopY - chainBotY) / 2.2)
    for ci = 0, chainSteps do
        local cy = chainBotY + (chainTopY - chainBotY) * (ci / chainSteps)
        local isHoriz = (ci % 2 == 0)
        local linkW = isHoriz and 2.2 or 0.6
        local linkD = isHoriz and 0.6 or 2.2
        local link = makePart(levelFolder, "ChainLink",
            Vector3.new(0, cy, 0),
            Vector3.new(linkW, 1.4, linkD), steelColor, Enum.Material.Metal)
        link.CanCollide = false
    end

    -- Glow light inside basket (warm lantern feel)
    local lanternGlow = Instance.new("Part")
    lanternGlow.Name = "BasketLantern"
    lanternGlow.Size = Vector3.new(0.8, 0.8, 0.8)
    lanternGlow.Position = Vector3.new(0, basketY + 1, 0)
    lanternGlow.Anchored = true
    lanternGlow.CanCollide = false
    lanternGlow.Color = Color3.fromRGB(255, 200, 100)
    lanternGlow.Material = Enum.Material.Neon
    lanternGlow.Transparency = 0.3
    lanternGlow.CastShadow = false
    lanternGlow.Parent = levelFolder
    local lanternLight = Instance.new("PointLight")
    lanternLight.Brightness = 3
    lanternLight.Range = 20
    lanternLight.Color = Color3.fromRGB(255, 200, 100)
    lanternLight.Parent = lanternGlow

    -- Generate 10 biome sections, each 100m deep; collect slime spawns
    local SLOT_DEPTH = 100
    local allSlimeSpawns = {}
    for i, biome in ipairs(biomeSequence) do
        local slotStart = (i - 1) * SLOT_DEPTH
        local slotEnd   = i * SLOT_DEPTH
        local _, sectionSlimes = generateBiomeSection(
            levelFolder, biome, slotStart, slotEnd, seedStr .. "_slot" .. i)
        for _, s in ipairs(sectionSlimes) do
            table.insert(allSlimeSpawns, s)
        end
    end

    -- Serialize slime spawn data into the level folder for client
    local slimeData = Instance.new("StringValue")
    slimeData.Name = "SlimeSpawnData"
    local parts = {}
    for _, s in ipairs(allSlimeSpawns) do
        -- format per entry: size|px,py,pz|ex,ey,ez
        table.insert(parts, string.format("%s|%.2f,%.2f,%.2f|%.2f,%.2f,%.2f",
            s.size,
            s.pos.X, s.pos.Y, s.pos.Z,
            s.patrolEnd.X, s.patrolEnd.Y, s.patrolEnd.Z))
    end
    slimeData.Value = table.concat(parts, ";")
    slimeData.Parent = levelFolder

    -- Finish platform at bottom (1000m)
    local finishY = GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS)
    spawnFinish(levelFolder, finishY)

    return levelFolder, biomeSequence, allSlimeSpawns
end

return LevelGenerator
