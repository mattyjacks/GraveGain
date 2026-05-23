-- Maze Runner - Configuration
-- Procedural maze escape game with timer

local Config = {}

-- Game Settings
Config.GAME_NAME = "Maze Runner"
Config.GAME_VERSION = "1.0"

-- Maze Settings
Config.MAZE_SIZE_MIN = 15 -- Minimum maze size (odd number)
Config.MAZE_SIZE_MAX = 51 -- Maximum maze size
Config.CELL_SIZE = 8 -- Size of each maze cell
Config.WALL_HEIGHT = 12
Config.WALL_THICKNESS = 1

-- Difficulty Settings
Config.DIFFICULTIES = {
    Easy = { size = 15, timeLimit = 120, fogDensity = 0.3 },
    Medium = { size = 25, timeLimit = 180, fogDensity = 0.5 },
    Hard = { size = 35, timeLimit = 240, fogDensity = 0.7 },
    Insane = { size = 51, timeLimit = 300, fogDensity = 0.9 },
}

-- Colors
Config.WALL_COLORS = {
    Color3.fromRGB(64, 64, 64),    -- Stone
    Color3.fromRGB(101, 67, 33),   -- Brown
    Color3.fromRGB(25, 25, 112),   -- Midnight Blue
    Color3.fromRGB(85, 107, 47),   -- Olive
    Color3.fromRGB(139, 0, 0),     -- Dark Red
}

Config.FLOOR_COLORS = {
    Color3.fromRGB(169, 169, 169), -- Dark Gray
    Color3.fromRGB(160, 82, 45),   -- Sienna
    Color3.fromRGB(70, 130, 180),  -- Steel Blue
    Color3.fromRGB(107, 142, 35),  -- Olive Drab
    Color3.fromRGB(178, 34, 34),   -- Fire Brick
}

-- Powerups
Config.POWERUPS = {
    SpeedBoost = { duration = 10, multiplier = 1.5, color = Color3.fromRGB(0, 255, 0) },
    TimeBonus = { seconds = 30, color = Color3.fromRGB(255, 215, 0) },
    VisionBoost = { duration = 15, range = 50, color = Color3.fromRGB(0, 191, 255) },
}

-- Leaderboard
Config.LEADERBOARD_SIZE = 50

return Config
