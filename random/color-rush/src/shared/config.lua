-- Color Rush - Configuration
-- Procedural color-matching platformer

local Config = {}

-- Game Settings
Config.GAME_NAME = "Color Rush"
Config.GAME_VERSION = "1.0"

-- Level Settings
Config.LEVEL_WIDTH = 12 -- Platforms per row
Config.LEVEL_LENGTH = 100 -- Sections per level
Config.PLATFORM_SIZE = 8
Config.PLATFORM_GAP = 2
Config.ROW_SPACING = 12

-- Colors (4 main colors for matching)
Config.COLORS = {
    Color3.fromRGB(244, 67, 54),   -- Red
    Color3.fromRGB(76, 175, 80),   -- Green
    Color3.fromRGB(33, 150, 243),  -- Blue
    Color3.fromRGB(255, 193, 7),   -- Yellow
}

-- Speed Settings
Config.SCROLL_SPEED_BASE = 10
Config.SCROLL_SPEED_MAX = 25
Config.SPEED_INCREMENT = 0.5
Config.SPEED_UP_INTERVAL = 10 -- Every 10 platforms

-- Game Modes
Config.GAME_MODES = {
    Classic = {
        description = "Match your color to the platforms",
        lives = 3,
        speedRamp = true,
    },
    Endless = {
        description = "Infinite runner, how far can you go?",
        lives = 1,
        speedRamp = true,
    },
    SpeedRun = {
        description = "Reach the end as fast as possible",
        lives = 5,
        speedRamp = false,
        fixedLength = 200,
    },
}

-- Powerups
Config.POWERUPS = {
    Rainbow = { duration = 5, matchesAll = true, color = Color3.fromRGB(255, 255, 255) },
    SlowMo = { duration = 3, speedMultiplier = 0.5, color = Color3.fromRGB(156, 39, 176) },
    ExtraLife = { lives = 1, color = Color3.fromRGB(0, 230, 118) },
}

-- Player Settings
Config.PLAYER_COLORS = {
    Color3.fromRGB(244, 67, 54),
    Color3.fromRGB(76, 175, 80),
    Color3.fromRGB(33, 150, 243),
    Color3.fromRGB(255, 193, 7),
}

-- Score
Config.SCORE_PER_PLATFORM = 10
Config.COMBO_MULTIPLIER = 1.5

return Config
