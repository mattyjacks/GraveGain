-- Core game data and configuration for Dead-Letter Drop

local GameData = {}

-- Game constants
GameData.GAME_NAME = "Last Words Zombies"
GameData.VERSION = "0.2.0"

-- Zombie configuration
GameData.ZOMBIE = {
	HEALTH = 1,
	SPEED_BASE = 3, -- studs per second (slow shamble)
	SPEED_INCREMENT = 0.15, -- speed increase per wave
	SPAWN_RATE_BASE = 3.5, -- seconds between spawns
	SPAWN_RATE_MIN = 0.8, -- minimum spawn rate
	MAX_ZOMBIES = 50,
	SPAWN_DISTANCE = 150, -- studs from camera
	KNOCKBACK_RESISTANCE = 0.3,
	RAGDOLL_DURATION = 5.0 -- seconds
}

-- Explosion physics
GameData.EXPLOSION = {
	RADIUS = 12, -- studs
	PRESSURE = 500, -- base pressure value
	IMPULSE_DURATION = 0.1, -- seconds
	VISUAL_DURATION = 0.8, -- seconds
	KNOCKBACK_MULTIPLIER = 1.5,
	STUN_DURATION = 1.5 -- seconds
}

-- Scoring system
GameData.SCORE = {
	WORD_COMPLETE_BASE = 100,
	KNOCKBACK_HIT = 25,
	COMBO_MULTIPLIER = 1.5,
	WAVE_COMPLETE = 1000,
	SURVIVAL_TIME_BONUS = 10 -- per second
}

-- Wave progression
GameData.WAVES = {
	ZOMBIES_PER_WAVE = 15,
	WAVE_DURATION = 60, -- seconds
	DIFFICULTY_SCALING = 1.2,
	SPEED_INCREASE_PER_WAVE = 2,
	SPAWN_RATE_DECREASE = 0.1
}

-- Visual settings
GameData.VISUALS = {
	BLOOD_COLOR = Color3.new(0, 1, 0.5), -- Neon green
	BLOOD_PARTICLES = 20,
	EXPLOSION_COLOR = Color3.new(0, 0.8, 1),
	EXPLOSION_PARTICLES = 30,
	CORRIDOR_LENGTH = 200,
	CORRIDOR_WIDTH = 50,
	CORRIDOR_HEIGHT = 18,
	FOG_COLOR = Color3.new(0.1, 0.1, 0.15),
	FOG_END = 100,
	AMBIENT_LIGHT = 0.2
}

-- Audio settings
GameData.AUDIO = {
	MUSIC_VOLUME = 0.7,
	SFX_VOLUME = 0.8,
	EXPLOSION_SOUND = "rbxasset://sounds/collide.mp3",
	TYPING_SOUND = "rbxasset://sounds/uuhhh.mp3",
	ZOMBIE_GROWL = "rbxasset://sounds/uuhhh.mp3"
}

-- Input settings
GameData.INPUT = {
	TYPING_SOUND_ENABLED = true,
	AUTO_TARGET_ENABLED = true,
	TARGET_SWITCH_DELAY = 0.1,
	KEYBOARD_BUFFER_SIZE = 10
}

-- Monetization (premium visual upgrades)
GameData.PREMIUM = {
	BLOOD_EFFECTS = {
		{ name = "Neon Green", id = "default", price = 0, color = Color3.new(0, 1, 0.5) },
		{ name = "Electric Blue", id = "plasma", price = 100, color = Color3.new(0, 0.5, 1) },
		{ name = "Fire Red", id = "inferno", price = 150, color = Color3.new(1, 0.2, 0) },
		{ name = "Cosmic Purple", id = "void", price = 200, color = Color3.new(0.8, 0, 1) },
		{ name = "Golden", id = "divine", price = 300, color = Color3.new(1, 0.8, 0) }
	},
	FONT_STYLES = {
		{ name = "Default", id = "default", price = 0 },
		{ name = "Retro Pixel", id = "pixel", price = 50 },
		{ name = "Cyberpunk", id = "cyber", price = 75 },
		{ name = "Terminal", id = "terminal", price = 100 }
	},
	MUSIC_TRACKS = {
		{ name = "Dark Synth", id = "default", price = 0 },
		{ name = "Industrial Bass", id = "industrial", price = 100 },
		{ name = "Techno Horror", id = "techno", price = 150 },
		{ name = "Ambient Dread", id = "ambient", price = 200 }
	}
}

-- Performance settings
GameData.PERFORMANCE = {
	MAX_PARTICLES = 100,
	PARTICLE_LIFETIME = 2.0,
	RAGDOLL_CLEANUP_TIME = 10.0,
	LOD_DISTANCE = 50,
	UPDATE_RATE = 60 -- FPS target
}

-- Game states
GameData.GAME_STATES = {
	MENU = "menu",
	PLAYING = "playing",
	PAUSED = "paused",
	GAME_OVER = "game_over",
	WAVE_COMPLETE = "wave_complete"
}

-- Difficulty presets
GameData.DIFFICULTY = {
	Easy = {
		zombieSpeed = 12,
		spawnRate = 3.0,
		wordDifficulty = "Easy",
		scoreMultiplier = 0.8
	},
	Normal = {
		zombieSpeed = 16,
		spawnRate = 2.0,
		wordDifficulty = "Medium",
		scoreMultiplier = 1.0
	},
	Hard = {
		zombieSpeed = 20,
		spawnRate = 1.5,
		wordDifficulty = "Hard",
		scoreMultiplier = 1.5
	},
	Nightmare = {
		zombieSpeed = 24,
		spawnRate = 1.0,
		wordDifficulty = "Extreme",
		scoreMultiplier = 2.0
	}
}

-- Utility functions
function GameData.GetDifficultySettings(difficulty)
	return GameData.DIFFICULTY[difficulty] or GameData.DIFFICULTY.Normal
end

function GameData.GetPremiumItem(category, itemId)
	for _, item in ipairs(GameData.PREMIUM[category]) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

function GameData.CalculateWaveSettings(wave)
	local wordDifficulty = "Easy"
	if wave >= 20 then
		wordDifficulty = "Extreme"
	elseif wave >= 15 then
		wordDifficulty = "Hard"
	elseif wave >= 8 then
		wordDifficulty = "Medium"
	elseif wave >= 3 then
		wordDifficulty = math.random() > 0.6 and "Medium" or "Easy"
	end
	
	local settings = {
		zombieSpeed = GameData.ZOMBIE.SPEED_BASE + (wave * GameData.ZOMBIE.SPEED_INCREMENT),
		spawnRate = math.max(
			GameData.ZOMBIE.SPAWN_RATE_MIN,
			GameData.ZOMBIE.SPAWN_RATE_BASE - (wave * GameData.WAVES.SPAWN_RATE_DECREASE)
		),
		zombiesPerWave = GameData.WAVES.ZOMBIES_PER_WAVE + math.floor(wave / 2),
		wordDifficulty = wordDifficulty
	}
	
	return settings
end

return GameData
