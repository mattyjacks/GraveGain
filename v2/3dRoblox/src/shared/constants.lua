-- Shared Constants for GraveGain 3D
local Constants = {}

Constants.GAME_NAME = "GraveGain 3D"
Constants.VERSION = "1.0.0"
Constants.MAX_PLAYERS_PER_TEAM = 5
Constants.TEAM_COUNT = 2

-- Races
Constants.RACES = {
	HUMAN = 1,
	ELF = 2,
	DWARF = 3,
	ORC = 4,
}

Constants.RACE_NAMES = {
	[Constants.RACES.HUMAN] = "Human",
	[Constants.RACES.ELF] = "Elf",
	[Constants.RACES.DWARF] = "Dwarf",
	[Constants.RACES.ORC] = "Orc",
}

-- Classes
Constants.CLASSES = {
	DPS = 1,
	TANK = 2,
	SUPPORT = 3,
	MAGE = 4,
}

Constants.CLASS_NAMES = {
	[Constants.CLASSES.DPS] = "DPS",
	[Constants.CLASSES.TANK] = "Tank",
	[Constants.CLASSES.SUPPORT] = "Support",
	[Constants.CLASSES.MAGE] = "Mage",
}

-- Race-specific class names
Constants.RACE_CLASS_NAMES = {
	[Constants.RACES.HUMAN] = {
		[Constants.CLASSES.DPS] = "Soldier",
		[Constants.CLASSES.TANK] = "Warden",
		[Constants.CLASSES.SUPPORT] = "Medic",
		[Constants.CLASSES.MAGE] = "Engineer",
	},
	[Constants.RACES.ELF] = {
		[Constants.CLASSES.DPS] = "Assassin",
		[Constants.CLASSES.TANK] = "Guardian",
		[Constants.CLASSES.SUPPORT] = "Druid",
		[Constants.CLASSES.MAGE] = "Witch",
	},
	[Constants.RACES.DWARF] = {
		[Constants.CLASSES.DPS] = "Slayer",
		[Constants.CLASSES.TANK] = "Paladin",
		[Constants.CLASSES.SUPPORT] = "Brewer",
		[Constants.CLASSES.MAGE] = "Tinkerer",
	},
	[Constants.RACES.ORC] = {
		[Constants.CLASSES.DPS] = "Berserker",
		[Constants.CLASSES.TANK] = "Brute",
		[Constants.CLASSES.SUPPORT] = "Shaman",
		[Constants.CLASSES.MAGE] = "Warlock",
	},
}

-- Enemy Types
Constants.ENEMY_TYPES = {
	GOBLIN_SKELETON = 1,
	ELVEN_SKELETON = 2,
	GOBLIN_ZED = 3,
	SMALL_ORC_ZED = 4,
	FLYING_ELF_SKULL = 5,
	MEDIUM_ORC_ZED = 6,
	DWARVEN_ZED = 7,
	HUMAN_ZED = 8,
	HUGE_ORC_ZED = 9,
	ELVEN_NECROMANCER = 10,
}

-- Game States
Constants.GAME_STATES = {
	LOBBY = "lobby",
	LOADING = "loading",
	IN_GAME = "in_game",
	PAUSED = "paused",
	MISSION_COMPLETE = "mission_complete",
	MISSION_FAILED = "mission_failed",
}

-- Difficulty Levels
Constants.DIFFICULTIES = {
	EASY = 1,
	NORMAL = 2,
	HARD = 3,
	NIGHTMARE = 4,
}

Constants.DIFFICULTY_NAMES = {
	[Constants.DIFFICULTIES.EASY] = "Easy",
	[Constants.DIFFICULTIES.NORMAL] = "Normal",
	[Constants.DIFFICULTIES.HARD] = "Hard",
	[Constants.DIFFICULTIES.NIGHTMARE] = "Nightmare",
}

-- Difficulty multipliers
Constants.DIFFICULTY_MULTIPLIERS = {
	[Constants.DIFFICULTIES.EASY] = 0.75,
	[Constants.DIFFICULTIES.NORMAL] = 1.0,
	[Constants.DIFFICULTIES.HARD] = 1.5,
	[Constants.DIFFICULTIES.NIGHTMARE] = 2.5,
}

return Constants
