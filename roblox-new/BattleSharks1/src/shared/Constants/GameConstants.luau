-- BattleSharks Game Constants
-- Central configuration for all game systems

local GameConstants = {}

-- GAME CONFIGURATION
GameConstants.GAME_NAME = "BattleSharks"
GameConstants.VERSION = "0.1.0"
GameConstants.MAX_PLAYERS = 50

-- OCEAN WORLD SETTINGS
GameConstants.OCEAN_SIZE = Vector2.new(2000, 2000) -- studs
GameConstants.OCEAN_DEPTH = -200 -- studs
GameConstants.WATER_LEVEL = 0 -- studs
GameConstants.WATER_DENSITY = 1.0
GameConstants.UNDERWATER_GRAVITY = 0.3
GameConstants.SURFACE_GRAVITY = 1.0

-- SHARK MOVEMENT
GameConstants.SHARK_BASE_SPEED = 25 -- studs/second
GameConstants.SHARK_BOOST_SPEED = 50 -- studs/second
GameConstants.SHARK_BOOST_DURATION = 2.0 -- seconds
GameConstants.SHARK_BOOST_COOLDOWN = 5.0 -- seconds
GameConstants.SHARK_TURN_SPEED = 2.5 -- radians/second
GameConstants.SHARK_LEAP_FORCE = 150 -- studs/second upward

-- HUNGER SYSTEM
GameConstants.HUNGER_MAX = 100
GameConstants.HUNGER_DECAY_RATE = 0.5 -- per second
GameConstants.HUNGER_DAMAGE_THRESHOLD = 20
GameConstants.HUNGER_DAMAGE_RATE = 5 -- per second
GameConstants.FOOD_HEAL_AMOUNT = 20

-- COMBAT SYSTEM
GameConstants.BITE_DAMAGE = 15
GameConstants.BITE_RANGE = 8 -- studs
GameConstants.BITE_COOLDOWN = 0.8 -- seconds
GameConstants.SHARK_BASE_HEALTH = 100
GameConstants.SHARK_REGEN_RATE = 1 -- per second

-- CLASS SYSTEM
GameConstants.CLASSES = {
	FIGHTER = "Fighter",
	RANGER = "Ranger", 
	HEALER = "Healer"
}

GameConstants.CLASS_STATS = {
	[GameConstants.CLASSES.FIGHTER] = {
		HealthMultiplier = 1.5,
		DamageMultiplier = 1.3,
		SpeedMultiplier = 0.9,
		RegenMultiplier = 1.0
	},
	[GameConstants.CLASSES.RANGER] = {
		HealthMultiplier = 1.0,
		DamageMultiplier = 1.1,
		SpeedMultiplier = 1.2,
		RegenMultiplier = 0.8
	},
	[GameConstants.CLASSES.HEALER] = {
		HealthMultiplier = 0.8,
		DamageMultiplier = 0.9,
		SpeedMultiplier = 1.0,
		RegenMultiplier = 1.5
	}
}

-- XP AND LEVELING
GameConstants.XP_PER_LEVEL = 100
GameConstants.XP_MULTIPLIER = 1.0
GameConstants.MAX_LEVEL = 100

-- ECONOMY
GameConstants.STARTING_GOLD = 100
GameConstants.STARTING_CRYSTALS = 10

-- MUTATION SYSTEM
GameConstants.MUTATION_DURATION = 300 -- seconds (5 minutes)
GameConstants.MUTATION_MAX_SIZE_INCREASE = 0.25 -- 25%
GameConstants.MUTATION_DAILY_RESET_TIME = 24 * 60 * 60 -- seconds

-- AQUARIUM SYSTEM
GameConstants.AQUARIUM_MAX_DECORATIONS = 20
GameConstants.AQUARIUM_FEED_COOLDOWN = 30 -- seconds
GameConstants.AQUARIUM_CLEANUP_COOLDOWN = 60 -- seconds
GameConstants.AQUARIUM_HUNGER_RATE = 0.3 -- per second

-- INVENTORY
GameConstants.INVENTORY_SLOTS = 20
GameConstants.WAREHOUSE_SLOTS = 100

-- NETWORKING
GameConstants.NETWORK_UPDATE_RATE = 20 -- Hz
GameConstants.INTERPOLATION_DELAY = 0.1 -- seconds

-- VISUAL EFFECTS
GameConstants.BLOOD_DURATION = 5.0 -- seconds
GameConstants.BUBBLE_SPAWN_RATE = 2 -- per second
GameConstants.TRAIL_DURATION = 1.0 -- seconds

-- AUDIO
GameConstants.MASTER_VOLUME = 0.8
GameConstants.SFX_VOLUME = 0.7
GameConstants.MUSIC_VOLUME = 0.5

return GameConstants
