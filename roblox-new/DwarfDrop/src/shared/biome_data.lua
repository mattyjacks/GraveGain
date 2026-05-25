-- DwarfDrop: biome_data.lua
-- Biome visual configs, block types, and generation parameters

local SeedSystem = require(game.ReplicatedStorage.Shared.seed_system)

local BiomeData = {}

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

BiomeData.Biomes = {
    Volcano = {
        name = "Volcano",
        index = 1,
        colors = {
            rgb(80, 20, 10), rgb(110, 30, 15),
            rgb(60, 15, 5),  rgb(130, 40, 5), rgb(40, 10, 5),
        },
        wallColors = { rgb(60,15,5), rgb(50,12,4), rgb(70,18,6), rgb(45,10,3) },
        accentColor  = rgb(255, 100, 0),
        lavaColor    = rgb(255, 60, 0),
        fogColor     = rgb(50, 20, 10),
        fogEnd       = 800,
        ambientColor = rgb(80, 30, 10),
        sunlightColor = rgb(255, 120, 40),
        -- Larger platforms spread across 120-stud shaft
        platform    = { minX = 14, maxX = 36, minZ = 14, maxZ = 36 },
        dropMin     = 3.0,   -- tighter = more platforms
        dropMax     = 10.0,
        hazardChance = 0.20,
        tunnelChance = 0.12,
        coinChance   = 0.50,
        wallStyle    = "cliff",
        -- Terrain generation
        platMaterial  = Enum.Material.Rock,
        wallMaterial  = Enum.Material.Rock,
        terrainStyle  = "volcano",  -- adds lava crack edges and obsidian pillars
        specialBlocks = { "lava_pool", "obsidian_spike" },
        hazardDamage  = 15,
        hazardColor   = rgb(255, 60, 0),
        hazardMat     = Enum.Material.Neon,
    },
    Fortress = {
        name = "Fortress",
        index = 2,
        colors = {
            rgb(52, 50, 46), rgb(38, 36, 32),
            rgb(65, 60, 54), rgb(44, 42, 38), rgb(72, 66, 58),
        },
        wallColors = {
            rgb(40, 38, 34), rgb(30, 28, 25),
            rgb(48, 45, 40), rgb(35, 33, 29),
        },
        accentColor  = rgb(200, 130, 40),
        fogColor     = rgb(8, 7, 6),
        fogEnd       = 600,
        ambientColor = rgb(25, 20, 15),
        sunlightColor = rgb(120, 100, 60),
        platform    = { minX = 16, maxX = 40, minZ = 16, maxZ = 40 },
        dropMin     = 3.5,
        dropMax     = 12.0,
        hazardChance = 0.15,
        tunnelChance = 0.40,
        coinChance   = 0.55,
        wallStyle    = "brick",
        platMaterial  = Enum.Material.SmoothPlastic,
        wallMaterial  = Enum.Material.Brick,
        terrainStyle  = "fortress",  -- adds battlements and torch pillars
        specialBlocks = { "crumble_block", "torch_post" },
        hazardDamage  = 10,
        hazardColor   = rgb(200, 130, 40),
        hazardMat     = Enum.Material.SmoothPlastic,
    },
    Cave = {
        name = "Cave",
        index = 3,
        colors = {
            rgb(50, 48, 45), rgb(65, 60, 55),
            rgb(40, 38, 35), rgb(75, 70, 60), rgb(30, 28, 25),
        },
        wallColors = { rgb(35,33,30), rgb(28,26,24), rgb(45,42,38), rgb(22,20,18) },
        accentColor  = rgb(55, 130, 180),
        crystalColor = rgb(40, 100, 160),
        fogColor     = rgb(6, 8, 12),
        fogEnd       = 500,
        ambientColor = rgb(12, 14, 22),
        sunlightColor = rgb(50, 70, 130),
        platform    = { minX = 10, maxX = 28, minZ = 10, maxZ = 28 },
        dropMin     = 4.0,
        dropMax     = 14.0,
        hazardChance = 0.25,
        tunnelChance = 0.35,
        coinChance   = 0.45,
        wallStyle    = "cave",
        platMaterial  = Enum.Material.Rock,
        wallMaterial  = Enum.Material.Rock,
        terrainStyle  = "cave",  -- adds crystal spikes and dripping stalactites
        specialBlocks = { "crystal_floor", "stalactite" },
        hazardDamage  = 20,
        hazardColor   = rgb(55, 130, 180),
        hazardMat     = Enum.Material.Neon,
    },
    Mine = {
        name = "Mine",
        index = 4,
        colors = {
            rgb(55, 50, 42), rgb(42, 38, 32),
            rgb(70, 62, 52), rgb(30, 26, 20), rgb(80, 70, 55),
        },
        wallColors = { rgb(45,40,32), rgb(35,30,24), rgb(55,48,38), rgb(28,24,18) },
        accentColor  = rgb(255, 220, 60),
        fogColor     = rgb(15, 12, 8),
        fogEnd       = 500,
        ambientColor = rgb(30, 22, 12),
        sunlightColor = rgb(220, 180, 80),
        platform    = { minX = 10, maxX = 30, minZ = 10, maxZ = 30 },
        dropMin     = 4.0,
        dropMax     = 14.0,
        hazardChance = 0.28,
        tunnelChance = 0.38,
        coinChance   = 0.60,
        wallStyle    = "shaft",
        platMaterial  = Enum.Material.Rock,
        wallMaterial  = Enum.Material.Rock,
        terrainStyle  = "mine",  -- adds wood support beams and gold vein streaks
        specialBlocks = { "gold_vein", "support_beam" },
        hazardDamage  = 25,
        hazardColor   = rgb(255, 80, 40),
        hazardMat     = Enum.Material.Neon,
    },
}

BiomeData.BiomeList = {
    BiomeData.Biomes.Volcano,
    BiomeData.Biomes.Fortress,
    BiomeData.Biomes.Cave,
    BiomeData.Biomes.Mine,
}

function BiomeData.GetBiome(nameOrIndex)
    if type(nameOrIndex) == "number" then
        for _, b in ipairs(BiomeData.BiomeList) do
            if b.index == nameOrIndex then return b end
        end
    end
    return BiomeData.Biomes[nameOrIndex]
end

-- Generate a randomized sequence of 10 biome slots from the seed
function BiomeData.GenerateSequence(seed)
    local rng = SeedSystem.NewRNG(seed, "biome_sequence")
    local pool = {}
    for _ = 1, 3 do
        for _, b in ipairs(BiomeData.BiomeList) do
            table.insert(pool, b)
        end
    end
    for i = #pool, 2, -1 do
        local j = rng:NextInteger(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local sequence = {}
    for i = 1, 10 do
        sequence[i] = pool[i]
    end
    return sequence
end

function BiomeData.GetBiomeAtDepthInSequence(biomeSequence, depthMeters)
    local slot = math.floor(depthMeters / 100) + 1
    slot = math.clamp(slot, 1, 10)
    return biomeSequence[slot]
end

function BiomeData.GetBiomeAtDepth(depthMeters)
    if depthMeters < 250 then return BiomeData.Biomes.Volcano end
    if depthMeters < 500 then return BiomeData.Biomes.Fortress end
    if depthMeters < 750 then return BiomeData.Biomes.Cave end
    return BiomeData.Biomes.Mine
end

function BiomeData.GetRandomColor(biome, rng)
    local idx = rng:NextInteger(1, #biome.colors)
    return biome.colors[idx]
end

return BiomeData
