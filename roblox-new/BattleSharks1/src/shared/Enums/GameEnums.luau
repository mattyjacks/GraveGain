-- BattleSharks Game Enums
-- Central enumeration definitions for type safety and clarity

local GameEnums = {}

-- GAME MODES
GameEnums.GameMode = {
	OCEAN = "Ocean",
	AQUARIUM = "Aquarium",
	MENU = "Menu"
}

-- SHARK CLASSES
GameEnums.SharkClass = {
	FIGHTER = "Fighter",
	RANGER = "Ranger",
	HEALER = "Healer"
}

-- SHARK STATES
GameEnums.SharkState = {
	IDLE = "Idle",
	SWIMMING = "Swimming",
	BOOSTING = "Boosting",
	LEAPING = "Leaping",
	BITING = "Biting",
	DEAD = "Dead"
}

-- EMOTION STATES (Aquarium Mode)
GameEnums.EmotionState = {
	HAPPY = "Happy",
	HUNGRY = "Hungry",
	ANGRY = "Angry",
	SLEEPY = "Sleepy",
	PLAYFUL = "Playful"
}

-- MUTATION TYPES
GameEnums.MutationType = {
	EYES_EXTRA = "EyesExtra",
	TEETH_LARGE = "TeethLarge",
	FINS_DEFORMED = "FinsDeformed",
	GLOW_EFFECT = "GlowEffect",
	SIZE_INCREASED = "SizeIncreased",
	COLOR_SHIFT = "ColorShift",
	PATTERN_CHANGE = "PatternChange"
}

-- ITEM TYPES
GameEnums.ItemType = {
	WEAPON = "Weapon",
	ARMOR = "Armor",
	POTION = "Potion",
	FOOD = "Food",
	COSMETIC = "Cosmetic",
	DECORATION = "Decoration",
	MUTATION_STABILIZER = "MutationStabilizer"
}

-- RARITY TIERS
GameEnums.Rarity = {
	COMMON = "Common",
	UNCOMMON = "Uncommon",
	RARE = "Rare",
	EPIC = "Epic",
	LEGENDARY = "Legendary"
}

-- ENEMY TYPES
GameEnums.EnemyType = {
	FISH = "Fish",
	BIRD = "Bird",
	CRAB = "Crab",
	DIVER = "Diver",
	SPEARFISHERMAN = "Spearfisherman",
	JELLYFISH = "Jellyfish",
	SQUID = "Squid",
	WHALE = "Whale",
	SHARK = "Shark"
}

-- DAMAGE TYPES
GameEnums.DamageType = {
	PHYSICAL = "Physical",
	MAGICAL = "Magical",
	RANGED = "Ranged",
	ENVIRONMENT = "Environment"
}

-- ABILITY TYPES
GameEnums.AbilityType = {
	BASIC_ATTACK = "BasicAttack",
	ACTIVE_ABILITY = "ActiveAbility",
	ULTIMATE_ABILITY = "UltimateAbility",
	PASSIVE_ABILITY = "PassiveAbility"
}

-- UI PANELS
GameEnums.UIPanel = {
	MAIN_HUD = "MainHUD",
	INVENTORY = "Inventory",
	AQUARIUM = "Aquarium",
	MUTATIONS = "Mutations",
	CLASSES = "Classes",
	DAILY_REWARDS = "DailyRewards",
	SETTINGS = "Settings"
}

-- CURRENCY TYPES
GameEnums.CurrencyType = {
	GOLD = "Gold",
	CRYSTALS = "Crystals"
}

-- DECORATION CATEGORIES
GameEnums.DecorationCategory = {
	STRUCTURES = "Structures",
	PLANTS = "Plants",
	PROPS = "Props",
	BACKGROUNDS = "Backgrounds",
	LIGHTING = "Lighting"
}

-- SOCIAL STATES
GameEnums.SocialState = {
	ONLINE = "Online",
	OFFLINE = "Offline",
	AWAY = "Away",
	DO_NOT_DISTURB = "DoNotDisturb"
}

-- NETWORK EVENTS
GameEnums.NetworkEvent = {
	PLAYER_JOINED = "PlayerJoined",
	PLAYER_LEFT = "PlayerLeft",
	SHARK_SPAWNED = "SharkSpawned",
	SHARK_MOVED = "SharkMoved",
	SHARK_ATTACKED = "SharkAttacked",
	ENEMY_SPAWNED = "EnemySpawned",
	ENEMY_DIED = "EnemyDied",
	ITEM_PICKED_UP = "ItemPickedUp",
	MUTATION_APPLIED = "MutationApplied",
	CLASS_CHANGED = "ClassChanged"
}

-- INPUT ACTIONS
GameEnums.InputAction = {
	MOVE_FORWARD = "MoveForward",
	MOVE_BACKWARD = "MoveBackward",
	MOVE_LEFT = "MoveLeft",
	MOVE_RIGHT = "MoveRight",
	BOOST = "Boost",
	ATTACK = "Attack",
	INTERACT = "Interact",
	OPEN_INVENTORY = "OpenInventory",
	OPEN_AQUARIUM = "OpenAquarium",
	TOGGLE_MENU = "ToggleMenu"
}

return GameEnums
