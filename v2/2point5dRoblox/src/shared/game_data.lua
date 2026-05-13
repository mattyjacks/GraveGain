local GameData = {}

GameData.RACES = {
	Human = {
		name = "Human",
		emoji = "👤",
		color = Color3.fromRGB(200, 150, 100),
		stats = { str = 10, dex = 10, int = 10, vit = 10, lck = 10 },
		xpMultiplier = 1.1,
	},
	Dwarf = {
		name = "Dwarf",
		emoji = "⛏️",
		color = Color3.fromRGB(150, 100, 50),
		stats = { str = 12, dex = 8, int = 8, vit = 14, lck = 8 },
		xpMultiplier = 0.95,
	},
	Elf = {
		name = "Elf",
		emoji = "🏹",
		color = Color3.fromRGB(100, 200, 100),
		stats = { str = 8, dex = 14, int = 12, vit = 6, lck = 10 },
		xpMultiplier = 1.0,
	},
	Orc = {
		name = "Orc",
		emoji = "🗡️",
		color = Color3.fromRGB(100, 150, 100),
		stats = { str = 15, dex = 10, int = 6, vit = 12, lck = 7 },
		xpMultiplier = 0.9,
	},
}

GameData.CLASSES = {
	Adventurer = {
		name = "Adventurer",
		emoji = "�️",
		description = "Master of all trades, can use any weapon",
		skillBranches = { "Melee", "Magic", "Survival" },
	},
}

GameData.DIFFICULTIES = {
	Beginner = { multiplier = 0.5, healthMult = 0.5, damageMult = 0.5, xpMult = 0.5, color = Color3.fromRGB(150, 255, 150), emoji = "🌱" },
	Easy     = { multiplier = 0.75, healthMult = 0.75, damageMult = 0.75, xpMult = 0.75, color = Color3.fromRGB(100, 255, 200), emoji = "⭐" },
	Normal   = { multiplier = 1.0, healthMult = 1.0, damageMult = 1.0, xpMult = 1.0, color = Color3.fromRGB(100, 200, 255), emoji = "⭐⭐" },
	Hard     = { multiplier = 1.5, healthMult = 1.5, damageMult = 1.4, xpMult = 1.5, color = Color3.fromRGB(255, 150, 0), emoji = "⭐⭐⭐" },
	Insane   = { multiplier = 2.5, healthMult = 2.5, damageMult = 2.0, xpMult = 3.0, color = Color3.fromRGB(255, 0, 50), emoji = "💀" }
}

GameData.STAT_NAMES = { "str", "dex", "int", "vit", "lck" }
GameData.STAT_LABELS = {
	str = "Strength",
	dex = "Dexterity",
	int = "Intelligence",
	vit = "Vitality",
	lck = "Luck",
}

GameData.WEAPON_TYPES = {
	Sword = { name = "Sword", emoji = "🗡️", damage = 10, speed = 1.0, range = 2 },
	Axe = { name = "Axe", emoji = "🪓", damage = 14, speed = 0.8, range = 2 },
	Mace = { name = "Mace", emoji = "�", damage = 12, speed = 0.9, range = 2 },
	Bow = { name = "Bow", emoji = "🏹", damage = 8, speed = 1.2, range = 20 },
	Staff = { name = "Staff", emoji = "🔱", damage = 6, speed = 1.0, range = 15 },
	Dagger = { name = "Dagger", emoji = "🔪", damage = 6, speed = 1.5, range = 1.5 },
	Crossbow = { name = "Crossbow", emoji = "🎯", damage = 11, speed = 0.9, range = 18 },
	Wand = { name = "Wand", emoji = "✨", damage = 5, speed = 1.1, range = 16 },
}

GameData.RARITY_TIERS = {
	common = { color = Color3.fromRGB(200, 200, 200), emoji = "⚪" },
	uncommon = { color = Color3.fromRGB(100, 200, 100), emoji = "🟢" },
	rare = { color = Color3.fromRGB(100, 150, 255), emoji = "🔵" },
	epic = { color = Color3.fromRGB(200, 100, 255), emoji = "🟣" },
	legendary = { color = Color3.fromRGB(255, 200, 0), emoji = "🟡" },
	unique = { color = Color3.fromRGB(255, 100, 0), emoji = "🟠" },
}

GameData.EQUIPMENT_SLOTS = {
	"Head", "Chest", "Legs", "Feet", "Gloves", "Ring1", "Ring2", "Amulet", "Weapon", "Offhand"
}

GameData.DAMAGE_TYPES = {
	"Physical", "Fire", "Ice", "Lightning", "Poison", "Holy", "Dark"
}

GameData.STATUS_EFFECTS = {
	Burn = { duration = 3, emoji = "🔥", damagePerSecond = 1 },
	Freeze = { duration = 2, emoji = "❄️", slowPercent = 0.5 },
	Stun = { duration = 1, emoji = "⭐", immobilize = true },
	Bleed = { duration = 4, emoji = "🩸", damagePerSecond = 0.5 },
	Slow = { duration = 3, emoji = "🐌", slowPercent = 0.3 },
	Poison = { duration = 5, emoji = "☠️", damagePerSecond = 0.8 },
}

GameData.ENEMY_TYPES = {
	Skeleton = { name = "Skeleton", emoji = "💀", health = 30, damage = 5, xp = 45 },
	Zombie = { name = "Zombie", emoji = "🧟", health = 50, damage = 8, xp = 60 },
	Spider = { name = "Spider", emoji = "�️", health = 8, damage = 2.5, xp = 30 },
	Goblin = { name = "Goblin", emoji = "👹", health = 35, damage = 7, xp = 50 },
	Demon = { name = "Demon", emoji = "😈", health = 120, damage = 15, xp = 150 },
	Boss = { name = "Boss", emoji = "👹", health = 800, damage = 25, xp = 1500 },
}

GameData.ENEMY_AFFIXES = {
	ExtraFast = { emoji = "⚡", speedMult = 1.5 },
	Teleporter = { emoji = "🌀", teleportChance = 0.3 },
	FireChains = { emoji = "🔥", damageType = "Fire" },
	Molten = { emoji = "🌋", aura = "fire" },
	Arcane = { emoji = "✨", aura = "magic" },
}

GameData.BIOMES = {
	Crypt = { name = "Crypt", emoji = "⚰️", color = Color3.fromRGB(100, 100, 100) },
	Forest = { name = "Forest", emoji = "🌲", color = Color3.fromRGB(100, 150, 100) },
	Cave = { name = "Cave", emoji = "🏔️", color = Color3.fromRGB(120, 100, 80) },
	Hellscape = { name = "Hellscape", emoji = "🔥", color = Color3.fromRGB(200, 50, 50) },
	Ruins = { name = "Ruins", emoji = "🏛️", color = Color3.fromRGB(150, 150, 100) },
}

GameData.ABILITIES = {
	Slash = { name = "Slash", emoji = "🗡️", cooldown = 0.5, manaCost = 0, damage = 1.0, range = 2, aoe = false },
	Fireball = { name = "Fireball", emoji = "🔥", cooldown = 2, manaCost = 30, damage = 1.5, range = 15, aoe = true },
	IceShards = { name = "Ice Shards", emoji = "❄️", cooldown = 1.5, manaCost = 25, damage = 1.2, range = 12, aoe = false },
	LightningBolt = { name = "Lightning Bolt", emoji = "⚡", cooldown = 1.8, manaCost = 28, damage = 1.4, range = 18, aoe = true },
	PoisonCloud = { name = "Poison Cloud", emoji = "☠️", cooldown = 2.5, manaCost = 35, damage = 0.8, range = 10, aoe = true },
	HolyStrike = { name = "Holy Strike", emoji = "✨", cooldown = 1.2, manaCost = 20, damage = 1.3, range = 3, aoe = false },
	DarkBolt = { name = "Dark Bolt", emoji = "🌑", cooldown = 1.5, manaCost = 25, damage = 1.2, range = 14, aoe = false },
	DodgeRoll = { name = "Dodge Roll", emoji = "�", cooldown = 0.8, manaCost = 0, damage = 0, range = 0, aoe = false },
}

GameData.LOOT_TABLES = {
	common = {
		{ type = "weapon", rarity = "common", chance = 0.4 },
		{ type = "armor", rarity = "common", chance = 0.3 },
		{ type = "potion", rarity = "common", chance = 0.2 },
		{ type = "gold", rarity = "common", chance = 0.1 },
	},
	uncommon = {
		{ type = "weapon", rarity = "uncommon", chance = 0.4 },
		{ type = "armor", rarity = "uncommon", chance = 0.35 },
		{ type = "potion", rarity = "uncommon", chance = 0.15 },
		{ type = "gold", rarity = "uncommon", chance = 0.1 },
	},
	rare = {
		{ type = "weapon", rarity = "rare", chance = 0.5 },
		{ type = "armor", rarity = "rare", chance = 0.3 },
		{ type = "potion", rarity = "rare", chance = 0.1 },
		{ type = "gold", rarity = "rare", chance = 0.1 },
	},
}

GameData.ITEM_PREFIXES = {
	"Flaming", "Icy", "Shocking", "Poisoned", "Holy", "Dark", "Ancient", "Blessed",
	"Cursed", "Enchanted", "Mystic", "Ethereal", "Radiant", "Shadowy", "Infernal",
}

GameData.ITEM_SUFFIXES = {
	"of Strength", "of Dexterity", "of Intelligence", "of Vitality", "of Luck",
	"of Fire Resistance", "of Cold Resistance", "of Lightning Resistance",
	"of Health", "of Mana", "of Speed", "of Damage",
}

GameData.DUNGEON_CONFIG = {
	roomSize = 20,
	minRoomWidth = 8,
	maxRoomWidth = 16,
	minRoomHeight = 8,
	maxRoomHeight = 16,
	corridorWidth = 3,
	floorsPerAct = 4,
	numActs = 4,
	offset = Vector3.new(0, 0, 4000), -- Moved further to make room for huge world
}

GameData.WORLD_CONFIG = {
	chunkSize = 128,        -- Studs per chunk
	renderDistance = 4,    -- Chunks around player
	worldRadius = 15,       -- Max chunks from origin
	seed = 1337,
	fenceHeight = 120,      -- High enough to prevent all jumping
	biomeFrequency = 0.15,  -- Higher frequency = smaller biomes
	lobbyHeight = 800,
}

GameData.TALENTS = {
	MeleeDamage = { name = "Brute Force", desc = "+10% Melee Damage", max = 5, bonus = 0.1 },
	Health = { name = "Vitality", desc = "+20 Max Health", max = 5, bonus = 20 },
	RangedSpeed = { name = "Quick Draw", desc = "+15% Ranged Attack Speed", max = 5, bonus = 0.15 },
	ShieldRegen = { name = "Hardened Plates", desc = "+10% Shield Regen", max = 5, bonus = 0.1 },
	LootQuality = { name = "Scavenger", desc = "+5% Better Loot", max = 3, bonus = 0.05 }
}

GameData.BIOMES = {
	Wasteland = {
		id = 1,
		color = Color3.fromRGB(80, 75, 70),
		material = Enum.Material.Slate,
		heightMod = 1.0,
		props = {"Rock", "Scrap"},
		ambient = Color3.fromRGB(100, 80, 120),
	},
	Forest = {
		id = 2,
		color = Color3.fromRGB(40, 90, 40),
		material = Enum.Material.Grass,
		heightMod = 0.6,
		props = {"Tree", "Bush", "Flower"},
		ambient = Color3.fromRGB(60, 120, 60),
	},
	CrystalPlains = {
		id = 3,
		color = Color3.fromRGB(60, 40, 100),
		material = Enum.Material.Glass,
		heightMod = 0.4,
		props = {"Crystal", "GlowMushroom"},
		ambient = Color3.fromRGB(100, 50, 200),
	},
	Inferno = {
		id = 4,
		color = Color3.fromRGB(40, 20, 10),
		material = Enum.Material.Basalt,
		heightMod = 1.2,
		props = {"ObsidianRock", "LavaPond"},
		ambient = Color3.fromRGB(200, 50, 20),
	}
}

GameData.RACE_UTILITIES = {
	Human = {
		flashlight = { color = Color3.new(1,1,1), range = 60, brightness = 2 },
		flare = { color = Color3.fromRGB(255, 80, 20), duration = 60, brightness = 5 }
	},
	Elf = {
		brighteyes = { color = Color3.fromRGB(150, 200, 255), range = 40, brightness = 1.5 },
		magicBall = { color = Color3.fromRGB(100, 150, 255), duration = 120, brightness = 3 }
	},
	Dwarf = {
		glowstone = { color = Color3.fromRGB(200, 255, 100), duration = 90, brightness = 4 },
		darkvision = { saturation = -1.0 } -- Full desaturation
	},
	Orc = {
		torch = { color = Color3.fromRGB(255, 120, 30), duration = 180, brightness = 3.5 }
	}
}

GameData.PLAYER_CONFIG = {
	baseHealth = 100,
	baseMana = 50,
	healthPerVit = 10,
	manaPerInt = 5,
	damagePerStr = 1.5,
	critChancePerDex = 0.01,
	critDamageMultiplier = 1.5,
	armorPerLevel = 0.5,
}

GameData.GAME_BALANCE = {
	xpPerKill = 10,
	xpPerLevel = 100,
	goldDropMultiplier = 1.0,
	lootDropRate = 0.3,
	bossLootDropRate = 0.8,
	inventorySlots = 20,
	stashSlots = 50,
}

return GameData
