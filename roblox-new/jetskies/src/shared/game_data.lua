local GameData = {}

-- Physics Constants
GameData.BASE_SPEED = 50
GameData.MAX_SPEED = 150
GameData.BOOST_MULTIPLIER = 2.0
GameData.TURN_SPEED = 3.0
GameData.PITCH_SPEED = 2.0
GameData.ALTITUDE_SPEED = 30
GameData.MOMENTUM_DECAY = 0.95
GameData.TILT_ANGLE = 15

-- Boost System
GameData.BOOST_FUEL_MAX = 100
GameData.BOOST_DRAIN_RATE = 20
GameData.BOOST_RECHARGE_RATE = 10
GameData.BOOST_COOLDOWN = 1.0

-- Water Physics
GameData.WATER_SPEED_MULTIPLIER = 1.5  -- 50% faster in water
GameData.WATER_DRAG = 0.8              -- Less drag in water (faster)
GameData.AIR_DRAG = 0.95             -- More drag in air
GameData.BUOYANCY_FORCE = 60         -- Upward force when in water
GameData.WATER_LEVEL = -10           -- Ocean surface Y position
GameData.SPLASH_THRESHOLD = 5        -- Min speed to create splash

-- World Settings
GameData.ISLAND_SPAWN_DISTANCE = 200
GameData.MAX_ALTITUDE = 1000
GameData.CEILING_BUFFER = 50
GameData.CLOUD_LAYER_HEIGHT = 800

-- Island Types
GameData.IslandTypes = {
    STARTER = {
        name = "Starter",
        size = {min = 50, max = 80},
        height = {min = 0, max = 100},
        ringCount = {min = 5, max = 8},
        color = Color3.fromRGB(100, 200, 100),
        difficulty = 1
    },
    EXPLORER = {
        name = "Explorer",
        size = {min = 80, max = 150},
        height = {min = 100, max = 400},
        ringCount = {min = 10, max = 15},
        color = Color3.fromRGB(100, 150, 200),
        difficulty = 2
    },
    SUMMIT = {
        name = "Summit",
        size = {min = 120, max = 200},
        height = {min = 400, max = 800},
        ringCount = {min = 15, max = 25},
        color = Color3.fromRGB(200, 100, 100),
        difficulty = 3
    }
}

-- Ring Settings
GameData.RING_VALUE = 1
GameData.RING_SIZE = 8
GameData.RING_HEIGHT_OFFSET = 15
GameData.HIDDEN_VALUE = 5

-- Upgrade Tiers
GameData.UpgradeTiers = {
    [1] = {cost = 10, multiplier = 1.1},
    [2] = {cost = 25, multiplier = 1.2},
    [3] = {cost = 50, multiplier = 1.3},
    [4] = {cost = 100, multiplier = 1.4},
    [5] = {cost = 200, multiplier = 1.5}
}

-- Upgrade Types
GameData.Upgrades = {
    SPEED = {
        id = "speed",
        name = "Engine Power",
        description = "Increases base flight speed",
        baseValue = 50,
        increment = 10
    },
    BOOST = {
        id = "boost",
        name = "Boost Capacity",
        description = "Increases boost duration",
        baseValue = 100,
        increment = 20
    },
    HANDLING = {
        id = "handling",
        name = "Agility",
        description = "Improves turn responsiveness",
        baseValue = 3.0,
        increment = 0.5
    }
}

-- Remote Event Names
GameData.RemoteEvents = {
    -- Client to Server
    REQUEST_UPGRADE = "RequestUpgrade",
    COLLECT_RING = "CollectRing",
    PLAYER_READY = "PlayerReady",
    
    -- Server to Client
    UPGRADE_RESPONSE = "UpgradeResponse",
    RING_COLLECTED = "RingCollected",
    WORLD_INIT = "WorldInit",
    STATS_UPDATE = "StatsUpdate"
}

-- Remote Function Names
GameData.RemoteFunctions = {
    GET_PLAYER_DATA = "GetPlayerData",
    GET_UPGRADES = "GetUpgrades",
    PURCHASE_UPGRADE = "PurchaseUpgrade"
}

-- Camera Settings
GameData.CAMERA_DISTANCE = 20
GameData.CAMERA_HEIGHT = 8
GameData.CAMERA_SMOOTH_SPEED = 6
GameData.CAMERA_MIN_DISTANCE = 15
GameData.CAMERA_MAX_DISTANCE = 35

-- UI Colors
GameData.UIColors = {
    PRIMARY = Color3.fromRGB(0, 170, 255),
    SECONDARY = Color3.fromRGB(255, 200, 50),
    SUCCESS = Color3.fromRGB(50, 200, 50),
    WARNING = Color3.fromRGB(255, 150, 50),
    DANGER = Color3.fromRGB(255, 50, 50),
    BACKGROUND = Color3.fromRGB(30, 30, 40),
    TEXT = Color3.fromRGB(255, 255, 255)
}

-- Particles
GameData.ParticleSettings = {
    THRUSTER = {
        color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(100, 255, 255)),
        size = NumberSequence.new(0.5, 1.5),
        lifetime = 0.3,
        rate = 50,
        speed = 10
    },
    BOOST = {
        color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 100)),
        size = NumberSequence.new(1, 3),
        lifetime = 0.5,
        rate = 100,
        speed = 20
    },
    RING_COLLECT = {
        color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 200)),
        size = NumberSequence.new(2, 0),
        lifetime = 0.8,
        rate = 0,
        speed = 15
    }
}

return GameData
