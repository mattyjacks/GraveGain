-- DropDwarf: biome_data.lua
-- Biome visual configs, block types, and generation parameters
-- Biomes are placed in randomized sequences of 10 per run (each 100m deep)

local SeedSystem = require(game.ReplicatedStorage.Shared.seed_system)

local BiomeData = {}

-- Color3 helpers
local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

-- Each biome defines:
--   colors: table of block colors (random pick during generation)
--   accentColor: for special blocks, coins, glow
--   fogColor, fogEnd: atmosphere
--   ambientColor: Lighting ambient
--   platform: platform size ranges [minX, maxX, minZ, maxZ] in studs
--   gapMin/gapMax: horizontal gap between platforms (studs)
--   dropMin/dropMax: vertical drop between platforms (studs = meters * 3.2)
--   hazardChance: 0-1 probability of hazard on platform
--   tunnelChance: 0-1 probability of enclosed tunnel section
--   coinChance: chance of coin per platform
--   wallStyle: "none" | "cliff" | "brick" | "cave" | "shaft"
-- NOTE: minDepth/maxDepth are NOT fixed - they are assigned dynamically per run
BiomeData.Biomes = {
    Volcano = {
        name = "Volcano",
        index = 1,
        colors = {
            rgb(80, 20, 10),   -- dark basalt
            rgb(110, 30, 15),  -- burnt rock
            rgb(60, 15, 5),    -- obsidian dark
            rgb(130, 40, 5),   -- lava rock
            rgb(40, 10, 5),    -- deep basalt
        },
        accentColor = rgb(255, 100, 0),  -- lava orange
        lavaColor = rgb(255, 60, 0),
        fogColor = rgb(50, 20, 10),
        fogEnd = 600,
        ambientColor = rgb(80, 30, 10),
        sunlightColor = rgb(255, 120, 40),
        platform = { minX = 8, maxX = 20, minZ = 8, maxZ = 20 },
        gapMin = 6,
        gapMax = 18,
        dropMin = 5.0,
        dropMax = 18.0,
        hazardChance = 0.25,
        tunnelChance = 0.10,
        coinChance = 0.45,
        wallStyle = "cliff",
        specialBlocks = { "lava_pool", "obsidian_spike" },
        -- Lava pools: glowing floor sections that deal damage
        hazardDamage = 15,
    },
    Fortress = {
        name = "Fortress",
        index = 2,
        colors = {
            rgb(52, 50, 46),    -- dark weathered stone (matches reference)
            rgb(38, 36, 32),    -- near-black cracked block
            rgb(65, 60, 54),    -- aged limestone
            rgb(44, 42, 38),    -- mortared brick shadow
            rgb(72, 66, 58),    -- granite face
        },
        wallColors = {
            rgb(40, 38, 34),
            rgb(30, 28, 25),
            rgb(48, 45, 40),
            rgb(35, 33, 29),
        },
        accentColor = rgb(200, 130, 40),  -- dim torch orange
        fogColor = rgb(8, 7, 6),
        fogEnd = 400,                     -- tight foggy corridor feel
        ambientColor = rgb(25, 20, 15),   -- near-black ambient
        sunlightColor = rgb(120, 100, 60),
        platform = { minX = 12, maxX = 28, minZ = 12, maxZ = 28 },
        gapMin = 4,
        gapMax = 16,
        dropMin = 6.0,
        dropMax = 22.0,
        hazardChance = 0.20,
        tunnelChance = 0.45,  -- lots of enclosed tunnel sections
        coinChance = 0.50,
        wallStyle = "brick",
        material = "SmoothPlastic",  -- used by generator for platforms
        specialBlocks = { "crumble_block", "torch_post" },
        hazardDamage = 10,
    },
    Cave = {
        name = "Cave",
        index = 3,
        colors = {
            rgb(50, 48, 45),   -- granite
            rgb(65, 60, 55),   -- dark granite
            rgb(40, 38, 35),   -- deepstone
            rgb(75, 70, 60),   -- mixed rock
            rgb(30, 28, 25),   -- void rock
        },
        accentColor = rgb(55, 130, 180),   -- muted teal-blue (was 100,200,255 - too intense)
        crystalColor = rgb(40, 100, 160),   -- even dimmer for neon crystal blocks
        fogColor = rgb(6, 8, 12),
        fogEnd = 400,
        ambientColor = rgb(12, 14, 22),
        sunlightColor = rgb(50, 70, 130),
        platform = { minX = 6, maxX = 18, minZ = 6, maxZ = 18 },
        gapMin = 5,
        gapMax = 16,
        dropMin = 7.0,
        dropMax = 26.0,
        hazardChance = 0.30,
        tunnelChance = 0.30,   -- was 0.50, fewer ceiling slabs
        coinChance = 0.40,
        wallStyle = "cave",
        specialBlocks = { "crystal_floor", "stalactite" },
        hazardDamage = 20,
    },
    Mine = {
        name = "Mine",
        index = 4,
        colors = {
            rgb(55, 50, 42),   -- mine wall
            rgb(42, 38, 32),   -- coal seam
            rgb(70, 62, 52),   -- dirt mix
            rgb(30, 26, 20),   -- dark earth
            rgb(80, 70, 55),   -- clay
        },
        accentColor = rgb(255, 220, 60),  -- gold vein
        fogColor = rgb(15, 12, 8),
        fogEnd = 400,
        ambientColor = rgb(30, 22, 12),
        sunlightColor = rgb(220, 180, 80),
        platform = { minX = 5, maxX = 16, minZ = 5, maxZ = 16 },
        gapMin = 6,
        gapMax = 20,
        dropMin = 8.0,
        dropMax = 30.0,
        hazardChance = 0.35,
        tunnelChance = 0.40,
        coinChance = 0.55,
        wallStyle = "shaft",
        specialBlocks = { "gold_vein", "support_beam" },
        hazardDamage = 25,
    },
}

-- Ordered list for iteration
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
-- Each slot is 100m deep. Biomes repeat across the 10 slots.
-- Returns array of biome objects (length 10), one per 100m band.
function BiomeData.GenerateSequence(seed)
    local rng = SeedSystem.NewRNG(seed, "biome_sequence")
    -- Build a pool of 12 entries (3 of each biome) then pick 10
    local pool = {}
    for i = 1, 3 do
        for _, b in ipairs(BiomeData.BiomeList) do
            table.insert(pool, b)
        end
    end
    -- Fisher-Yates shuffle
    for i = #pool, 2, -1 do
        local j = rng:NextInteger(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    -- Take first 10
    local sequence = {}
    for i = 1, 10 do
        sequence[i] = pool[i]
    end
    return sequence
end

-- Given a biomeSequence (array of 10 biome objects) and a depth in meters,
-- return the biome for that depth. Each slot = 100m.
function BiomeData.GetBiomeAtDepthInSequence(biomeSequence, depthMeters)
    local slot = math.floor(depthMeters / 100) + 1
    slot = math.clamp(slot, 1, 10)
    return biomeSequence[slot]
end

-- Legacy: Get biome by fixed depth (used in hub/non-level contexts)
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
