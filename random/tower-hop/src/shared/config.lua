-- Tower Hop - Configuration
-- Simple viral tower obby with procedural generation

local Config = {}

-- Game Settings
Config.GAME_NAME = "Tower Hop"
Config.GAME_VERSION = "1.0"

-- Tower Settings
Config.TOWER_RADIUS = 20
Config.FLOOR_HEIGHT = 4
Config.PLATFORM_SIZE_MIN = 6
Config.PLATFORM_SIZE_MAX = 16
Config.GAP_MIN = 2
Config.GAP_MAX = 6
Config.MAX_FLOORS = 1000 -- Infinite tower

-- Difficulty Scaling
Config.DIFFICULTY_SETTINGS = {
    [1] = { gapMultiplier = 1.0, speedMultiplier = 1.0, movingPlatforms = false },
    [25] = { gapMultiplier = 1.2, speedMultiplier = 1.1, movingPlatforms = true },
    [50] = { gapMultiplier = 1.4, speedMultiplier = 1.2, movingPlatforms = true },
    [100] = { gapMultiplier = 1.6, speedMultiplier = 1.3, movingPlatforms = true },
}

-- Colors
Config.PLATFORM_COLORS = {
    Color3.fromRGB(76, 175, 80),   -- Green
    Color3.fromRGB(33, 150, 243),  -- Blue
    Color3.fromRGB(255, 152, 0),   -- Orange
    Color3.fromRGB(156, 39, 176),  -- Purple
    Color3.fromRGB(244, 67, 54),   -- Red
    Color3.fromRGB(0, 188, 212), -- Cyan
}

-- Win Settings
Config.CHECKPOINT_INTERVAL = 10 -- Save every 10 floors

-- Leaderboard
Config.LEADERBOARD_SIZE = 100

return Config
