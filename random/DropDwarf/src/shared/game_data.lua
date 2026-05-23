-- DropDwarf: game_data.lua
-- Core constants and configuration

local GameData = {}

-- Conversion: 1 meter = 3.2 studs in Roblox
GameData.STUDS_PER_METER = 3.2
GameData.TOTAL_DEPTH_METERS = 1000
GameData.TOTAL_DEPTH_STUDS = GameData.TOTAL_DEPTH_METERS * GameData.STUDS_PER_METER -- 3200 studs

-- Level layout
GameData.LEVEL_WIDTH = 60  -- studs wide
GameData.LEVEL_DEPTH_START_Y = 500 -- world Y where level surface begins (positive = above hub)
GameData.LEVEL_Y_OFFSET = 0 -- world Y at depth 0m
GameData.HUB_Y = 600 -- hub sits above level

-- Fall damage
GameData.FALL_DAMAGE_THRESHOLD_METERS = 5 -- safe fall in meters
GameData.FALL_DAMAGE_PER_METER = 8 -- damage per meter beyond threshold
GameData.FALL_DAMAGE_MAX = 100 -- cap per single fall

-- Player defaults
GameData.DEFAULT_MAX_HEALTH = 100
GameData.DEFAULT_WALK_SPEED = 18
GameData.DEFAULT_SPRINT_SPEED = 28
GameData.DEFAULT_HEAL_RATE = 0 -- HP per second (starts at 0, upgradeable)
GameData.SPRINT_KEY = Enum.KeyCode.LeftShift

-- Gold
GameData.COIN_VALUE = 5
GameData.COIN_SIZE = 2 -- studs diameter

-- Timer
GameData.TIMER_FORMAT = "%02d:%02d.%02d" -- MM:SS.cs

-- Upgrades max tier
GameData.MAX_UPGRADE_TIER = 10

-- Hub constants
GameData.HUB_RADIUS = 80
GameData.HUB_FLOOR_Y = 600
GameData.PORTAL_POSITION = Vector3.new(0, GameData.HUB_FLOOR_Y + 3, -60)

-- Leaderboard
GameData.MAX_LEADERBOARD_ENTRIES = 100

-- Coin combo streak
GameData.COMBO_RESET_TIME   = 3.0   -- seconds without a coin before streak resets
GameData.COMBO_THRESHOLDS   = { 1, 5, 10, 20 }  -- coins collected for x1/x2/x3/x5
GameData.COMBO_MULTIPLIERS  = { 1,  2,  3,   5 }

-- Coin magnet pull speed (studs/s) at max magnet tier
GameData.MAGNET_PULL_SPEED  = 28

-- Coyote time (seconds after leaving ground where jump is still valid)
GameData.COYOTE_TIME        = 0.15

-- Run modifiers
GameData.RunModifiers = {
    Normal = {
        id = "Normal",
        displayName = "Normal",
        description = "Standard run. No changes.",
        color = Color3.fromRGB(200, 200, 200),
        goldMult    = 1.0,
        speedMult   = 1.0,
        damageMult  = 1.0,
        slimeRain   = false,
    },
    Speedy = {
        id = "Speedy",
        displayName = "SPEEDY",
        description = "Move 35% faster, but platforms are smaller.",
        color = Color3.fromRGB(80, 220, 255),
        goldMult    = 1.25,
        speedMult   = 1.35,
        damageMult  = 1.0,
        slimeRain   = false,
    },
    Fragile = {
        id = "Fragile",
        displayName = "FRAGILE",
        description = "Double gold, but fall damage is 3x.",
        color = Color3.fromRGB(255, 80, 80),
        goldMult    = 2.0,
        speedMult   = 1.0,
        damageMult  = 3.0,
        slimeRain   = false,
    },
    Golden = {
        id = "Golden",
        displayName = "GOLDEN",
        description = "Triple coins everywhere. Health does not regenerate.",
        color = Color3.fromRGB(255, 220, 40),
        goldMult    = 3.0,
        speedMult   = 1.0,
        damageMult  = 1.0,
        slimeRain   = false,
        noRegen     = true,
    },
    SlimeRain = {
        id = "SlimeRain",
        displayName = "SLIME RAIN",
        description = "Everything is slimed from the start. Insane speed but chaotic.",
        color = Color3.fromRGB(80, 255, 120),
        goldMult    = 1.5,
        speedMult   = 1.0,
        damageMult  = 1.0,
        slimeRain   = true,
    },
}

GameData.ModifierList = { "Normal", "Speedy", "Fragile", "Golden", "SlimeRain" }

-- Biome depth ranges (in meters)
GameData.BIOME_RANGES = {
    { name = "Volcano", minDepth = 0,   maxDepth = 250,  index = 1 },
    { name = "Fortress", minDepth = 250, maxDepth = 500,  index = 2 },
    { name = "Cave",    minDepth = 500, maxDepth = 750,  index = 3 },
    { name = "Mine",    minDepth = 750, maxDepth = 1000, index = 4 },
}

function GameData.GetBiomeAtDepth(depthMeters)
    for _, biome in ipairs(GameData.BIOME_RANGES) do
        if depthMeters >= biome.minDepth and depthMeters < biome.maxDepth then
            return biome
        end
    end
    return GameData.BIOME_RANGES[4]
end

function GameData.MetersToStuds(meters)
    return meters * GameData.STUDS_PER_METER
end

function GameData.StudsToMeters(studs)
    return studs / GameData.STUDS_PER_METER
end

-- Depth: level surface Y is LEVEL_Y_OFFSET, going DOWN (negative Y direction)
function GameData.DepthToWorldY(depthMeters)
    local depthStuds = GameData.MetersToStuds(depthMeters)
    return GameData.LEVEL_Y_OFFSET - depthStuds
end

function GameData.WorldYToDepth(worldY)
    local depthStuds = GameData.LEVEL_Y_OFFSET - worldY
    return GameData.StudsToMeters(depthStuds)
end

return GameData
