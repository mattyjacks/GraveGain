extends Node

enum Race { HUMAN, ELF, DWARF, ORC }
enum PlayerClass { DPS, TANK, SUPPORT, MAGE }
enum EnemyType {
	GOBLIN_SKELETON, ELVEN_SKELETON, GOBLIN_ZED, SMALL_ORC_ZED,
	FLYING_ELF_SKULL, MEDIUM_ORC_ZED, DWARVEN_ZED,
	HUMAN_ZED, HUGE_ORC_ZED, ELVEN_NECROMANCER
}
enum Slot { MELEE = 1, RANGED = 2, THROWABLE = 3, CONSUMABLE = 4 }

var selected_race: Race = Race.HUMAN
var selected_class: PlayerClass = PlayerClass.DPS

var emoji_font: Font
var emoji_font_large: Font

func _ready() -> void:
	# Initial system font - EmojiManager autoload will override this with the user's chosen set
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji", "Segoe UI Symbol"])
	sf.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	emoji_font = sf
	emoji_font_large = sf

var race_stats: Dictionary = {
	Race.HUMAN: {
		"name": "Human",
		"emoji": "\U0001F469\u200D\U0001F680",
		"desc": "Shields - Jetpacks - KillCredits",
		"max_hp": 100.0,
		"hp_regen": 1.0,
		"max_stamina": 100.0,
		"run_speed": 250.0,
		"has_shields": true,
		"max_shields": 20.0,
		"shield_regen": 2.0,
		"shield_delay": 5.0,
		"has_mana": false,
		"max_mana": 0.0,
		"mana_regen": 0.0,
		"has_rage": false,
		"max_rage": 0.0,
		"light_type": "flashlight",
		"jump_type": "jetpack",
		"color": Color(0.3, 0.5, 1.0),
		"melee_damage": 12.0,
		"ranged_damage": 10.0,
	},
	Race.ELF: {
		"name": "Elf",
		"emoji": "\U0001F9DD\u200D\u2640\uFE0F",
		"desc": "Mana - Hover - BrightEyes",
		"max_hp": 75.0,
		"hp_regen": 3.0,
		"max_stamina": 100.0,
		"run_speed": 275.0,
		"has_shields": false,
		"max_shields": 0.0,
		"shield_regen": 0.0,
		"shield_delay": 0.0,
		"has_mana": true,
		"max_mana": 100.0,
		"mana_regen": 2.0,
		"has_rage": false,
		"max_rage": 0.0,
		"light_type": "brighteyes",
		"jump_type": "hover",
		"color": Color(0.3, 1.0, 0.5),
		"melee_damage": 14.0,
		"ranged_damage": 12.0,
	},
	Race.DWARF: {
		"name": "Dwarf",
		"emoji": "\u26CF\uFE0F",
		"desc": "DarkVision - Double Jump - Mining",
		"max_hp": 150.0,
		"hp_regen": 2.0,
		"max_stamina": 100.0,
		"run_speed": 200.0,
		"has_shields": false,
		"max_shields": 0.0,
		"shield_regen": 0.0,
		"shield_delay": 0.0,
		"has_mana": false,
		"max_mana": 0.0,
		"mana_regen": 0.0,
		"has_rage": false,
		"max_rage": 0.0,
		"light_type": "darkvision",
		"jump_type": "double_jump",
		"color": Color(1.0, 0.8, 0.3),
		"melee_damage": 18.0,
		"ranged_damage": 8.0,
	},
	Race.ORC: {
		"name": "Orc",
		"emoji": "\U0001F479",
		"desc": "Rage - Stomp - Regeneration",
		"max_hp": 200.0,
		"hp_regen": 3.0,
		"max_stamina": 100.0,
		"run_speed": 225.0,
		"has_shields": false,
		"max_shields": 0.0,
		"shield_regen": 0.0,
		"shield_delay": 0.0,
		"has_mana": false,
		"max_mana": 0.0,
		"mana_regen": 0.0,
		"has_rage": true,
		"max_rage": 100.0,
		"light_type": "torch",
		"jump_type": "stomp",
		"color": Color(1.0, 0.3, 0.3),
		"melee_damage": 20.0,
		"ranged_damage": 6.0,
	},
}

var class_names: Dictionary = {
	Race.HUMAN: {
		PlayerClass.DPS: "Soldier",
		PlayerClass.TANK: "Warden",
		PlayerClass.SUPPORT: "Medic",
		PlayerClass.MAGE: "Engineer",
	},
	Race.ELF: {
		PlayerClass.DPS: "Assassin",
		PlayerClass.TANK: "Guardian",
		PlayerClass.SUPPORT: "Druid",
		PlayerClass.MAGE: "Witch",
	},
	Race.DWARF: {
		PlayerClass.DPS: "Slayer",
		PlayerClass.TANK: "Paladin",
		PlayerClass.SUPPORT: "Brewer",
		PlayerClass.MAGE: "Tinkerer",
	},
	Race.ORC: {
		PlayerClass.DPS: "Berserker",
		PlayerClass.TANK: "Brute",
		PlayerClass.SUPPORT: "Shaman",
		PlayerClass.MAGE: "Warlock",
	},
}

var class_emojis: Dictionary = {
	PlayerClass.DPS: "\u2694\uFE0F",
	PlayerClass.TANK: "\U0001F6E1\uFE0F",
	PlayerClass.SUPPORT: "\U0001F49A",
	PlayerClass.MAGE: "\U0001F52E",
}

var class_descs: Dictionary = {
	PlayerClass.DPS: "High damage dealer",
	PlayerClass.TANK: "Frontline defender",
	PlayerClass.SUPPORT: "Team healer & buffer",
	PlayerClass.MAGE: "Abilities & summons",
}

var enemy_stats: Dictionary = {
	EnemyType.GOBLIN_SKELETON: {
		"name": "Goblin Skeleton", "emoji": "\U0001F480", "emoji_scale": 0.6,
		"max_hp": 15.0, "damage": 3.0, "speed": 120.0,
		"attack_range": 30.0, "attack_cooldown": 1.0,
		"xp": 5, "gold_drop": 1, "color": Color(0.8, 0.8, 0.7),
		"category": "standard", "collision_radius": 10.0,
		"blood_color": Color(0.4, 0.35, 0.25),
	},
	EnemyType.ELVEN_SKELETON: {
		"name": "Elven Skeleton", "emoji": "\U0001F480", "emoji_scale": 1.0,
		"max_hp": 25.0, "damage": 5.0, "speed": 100.0,
		"attack_range": 35.0, "attack_cooldown": 1.2,
		"xp": 10, "gold_drop": 2, "color": Color(0.9, 0.85, 0.75),
		"category": "standard", "collision_radius": 14.0,
		"blood_color": Color(0.5, 0.4, 0.3),
	},
	EnemyType.GOBLIN_ZED: {
		"name": "Goblin Zed", "emoji": "\U0001F9DF", "emoji_scale": 0.7,
		"max_hp": 40.0, "damage": 8.0, "speed": 90.0,
		"attack_range": 40.0, "attack_cooldown": 1.5,
		"xp": 15, "gold_drop": 3, "color": Color(0.5, 0.7, 0.4),
		"category": "standard", "collision_radius": 12.0,
		"blood_color": Color(0.3, 0.5, 0.15),
	},
	EnemyType.SMALL_ORC_ZED: {
		"name": "Small Orc Zed", "emoji": "\U0001F9DF\u200D\u2642\uFE0F", "emoji_scale": 0.85,
		"max_hp": 60.0, "damage": 12.0, "speed": 80.0,
		"attack_range": 50.0, "attack_cooldown": 1.8,
		"xp": 20, "gold_drop": 5, "color": Color(0.6, 0.4, 0.3),
		"category": "standard", "collision_radius": 14.0,
		"blood_color": Color(0.5, 0.15, 0.05),
	},
	EnemyType.FLYING_ELF_SKULL: {
		"name": "Flying Elf Skull", "emoji": "\U0001F47B", "emoji_scale": 0.5,
		"max_hp": 10.0, "damage": 30.0, "speed": 150.0,
		"attack_range": 15.0, "attack_cooldown": 3.0,
		"xp": 25, "gold_drop": 5, "color": Color(0.7, 0.9, 1.0),
		"category": "special", "collision_radius": 8.0, "explodes": true, "flies": true,
		"blood_color": Color(0.3, 0.6, 0.7),
	},
	EnemyType.MEDIUM_ORC_ZED: {
		"name": "Medium Orc Zed", "emoji": "\U0001F47A", "emoji_scale": 1.2,
		"max_hp": 150.0, "damage": 20.0, "speed": 70.0,
		"attack_range": 45.0, "attack_cooldown": 2.0,
		"xp": 50, "gold_drop": 10, "color": Color(0.8, 0.3, 0.2),
		"category": "elite", "collision_radius": 18.0,
		"blood_color": Color(0.55, 0.12, 0.05),
	},
	EnemyType.DWARVEN_ZED: {
		"name": "Dwarven Zed", "emoji": "\U0001F6E1\uFE0F", "emoji_scale": 0.8,
		"max_hp": 200.0, "damage": 15.0, "speed": 60.0,
		"attack_range": 35.0, "attack_cooldown": 2.5,
		"xp": 60, "gold_drop": 15, "color": Color(0.7, 0.6, 0.4),
		"category": "elite", "collision_radius": 14.0, "armored": true,
		"blood_color": Color(0.5, 0.2, 0.1),
	},
	EnemyType.HUMAN_ZED: {
		"name": "Human Zed", "emoji": "\U0001F916", "emoji_scale": 1.3,
		"max_hp": 500.0, "damage": 25.0, "speed": 80.0,
		"attack_range": 200.0, "attack_cooldown": 1.0,
		"xp": 200, "gold_drop": 50, "color": Color(0.4, 0.6, 0.9),
		"category": "boss", "collision_radius": 20.0, "has_ranged": true,
		"blood_color": Color(0.6, 0.1, 0.1),
	},
	EnemyType.HUGE_ORC_ZED: {
		"name": "Huge Orc Zed", "emoji": "\U0001F479", "emoji_scale": 2.0,
		"max_hp": 800.0, "damage": 40.0, "speed": 50.0,
		"attack_range": 60.0, "attack_cooldown": 3.0,
		"xp": 300, "gold_drop": 75, "color": Color(0.9, 0.2, 0.1),
		"category": "boss", "collision_radius": 28.0,
		"blood_color": Color(0.7, 0.08, 0.0),
	},
	EnemyType.ELVEN_NECROMANCER: {
		"name": "Elven Necromancer", "emoji": "\U0001F9D9", "emoji_scale": 1.1,
		"max_hp": 400.0, "damage": 15.0, "speed": 60.0,
		"attack_range": 300.0, "attack_cooldown": 2.0,
		"xp": 250, "gold_drop": 60, "color": Color(0.5, 0.2, 0.8),
		"category": "boss", "collision_radius": 16.0,
		"summons": true, "regen_pct": 0.75,
		"blood_color": Color(0.3, 0.1, 0.5),
	},
}

var item_defs: Dictionary = {
	"gold_coin": {"emoji": "\U0001FA99", "name": "Gold Coin", "value": 100, "type": "treasure"},
	"gold_bar": {"emoji": "\U0001F947", "name": "Gold Bar", "value": 50000, "type": "treasure"},
	"gold_cube": {"emoji": "\U0001F48E", "name": "Gold Cube", "value": 200000, "type": "treasure"},
	"health_potion": {"emoji": "\u2764\uFE0F\u200D\U0001FA79", "name": "Health Potion", "value": 5000, "type": "consumable", "heals": 50.0, "heals_real": true},
	"mana_potion": {"emoji": "\U0001F52E", "name": "Mana Potion", "value": 3000, "type": "consumable", "mana": 50.0},
	"artifact_ring": {"emoji": "\U0001F48D", "name": "Ancient Ring", "value": 8000, "type": "treasure"},
	"artifact_vase": {"emoji": "\U0001F3FA", "name": "Ornate Vase", "value": 12000, "type": "treasure"},
	"artifact_trident": {"emoji": "\U0001F531", "name": "Golden Trident", "value": 15000, "type": "treasure"},
	"ammo_small": {"emoji": "\U0001F4E6", "name": "Small Ammo Box", "value": 500, "type": "ammo", "ammo_pct": 0.1},
	"ammo_medium": {"emoji": "\U0001F4E6", "name": "Medium Ammo Box", "value": 1000, "type": "ammo", "ammo_pct": 0.5},
}

var food_defs: Dictionary = {
	# === Fruits ===
	"grapes": {"emoji": "\U0001F347", "name": "Grapes", "heal_per_sec": 0.7, "duration": 45.0, "stamina_boost": 0.12},
	"melon": {"emoji": "\U0001F348", "name": "Melon", "heal_per_sec": 0.9, "duration": 50.0, "stamina_boost": 0.14},
	"watermelon": {"emoji": "\U0001F349", "name": "Watermelon", "heal_per_sec": 0.8, "duration": 55.0, "stamina_boost": 0.18},
	"tangerine": {"emoji": "\U0001F34A", "name": "Tangerine", "heal_per_sec": 0.6, "duration": 35.0, "stamina_boost": 0.20},
	"lemon": {"emoji": "\U0001F34B", "name": "Lemon", "heal_per_sec": 0.4, "duration": 25.0, "stamina_boost": 0.25},
	"banana": {"emoji": "\U0001F34C", "name": "Banana", "heal_per_sec": 0.75, "duration": 40.0, "stamina_boost": 0.22},
	"pineapple": {"emoji": "\U0001F34D", "name": "Pineapple", "heal_per_sec": 0.85, "duration": 60.0, "stamina_boost": 0.16},
	"mango": {"emoji": "\U0001F96D", "name": "Mango", "heal_per_sec": 0.95, "duration": 55.0, "stamina_boost": 0.17},
	"apple": {"emoji": "\U0001F34E", "name": "Red Apple", "heal_per_sec": 0.7, "duration": 40.0, "stamina_boost": 0.15},
	"green_apple": {"emoji": "\U0001F34F", "name": "Green Apple", "heal_per_sec": 0.65, "duration": 38.0, "stamina_boost": 0.16},
	"pear": {"emoji": "\U0001F350", "name": "Pear", "heal_per_sec": 0.6, "duration": 42.0, "stamina_boost": 0.13},
	"peach": {"emoji": "\U0001F351", "name": "Peach", "heal_per_sec": 0.8, "duration": 36.0, "stamina_boost": 0.19},
	"cherries": {"emoji": "\U0001F352", "name": "Cherries", "heal_per_sec": 0.5, "duration": 30.0, "stamina_boost": 0.21},
	"strawberry": {"emoji": "\U0001F353", "name": "Strawberry", "heal_per_sec": 0.55, "duration": 28.0, "stamina_boost": 0.23},
	"blueberries": {"emoji": "\U0001FAD0", "name": "Blueberries", "heal_per_sec": 0.6, "duration": 32.0, "stamina_boost": 0.20},
	"kiwi": {"emoji": "\U0001F95D", "name": "Kiwi", "heal_per_sec": 0.65, "duration": 34.0, "stamina_boost": 0.18},
	"tomato": {"emoji": "\U0001F345", "name": "Tomato", "heal_per_sec": 0.5, "duration": 30.0, "stamina_boost": 0.10},
	"olive": {"emoji": "\U0001FAD2", "name": "Olive", "heal_per_sec": 0.3, "duration": 90.0, "stamina_boost": 0.08},
	"coconut": {"emoji": "\U0001F965", "name": "Coconut", "heal_per_sec": 0.7, "duration": 70.0, "stamina_boost": 0.14},
	# === Vegetables ===
	"avocado": {"emoji": "\U0001F951", "name": "Avocado", "heal_per_sec": 0.8, "duration": 65.0, "stamina_boost": 0.15},
	"eggplant": {"emoji": "\U0001F346", "name": "Eggplant", "heal_per_sec": 0.55, "duration": 50.0, "stamina_boost": 0.09},
	"potato": {"emoji": "\U0001F954", "name": "Potato", "heal_per_sec": 0.6, "duration": 80.0, "stamina_boost": 0.06},
	"carrot": {"emoji": "\U0001F955", "name": "Carrot", "heal_per_sec": 0.5, "duration": 55.0, "stamina_boost": 0.14},
	"corn": {"emoji": "\U0001F33D", "name": "Corn", "heal_per_sec": 0.65, "duration": 60.0, "stamina_boost": 0.11},
	"hot_pepper": {"emoji": "\U0001F336\uFE0F", "name": "Hot Pepper", "heal_per_sec": 0.3, "duration": 20.0, "stamina_boost": 0.35},
	"bell_pepper": {"emoji": "\U0001FAD1", "name": "Bell Pepper", "heal_per_sec": 0.45, "duration": 40.0, "stamina_boost": 0.13},
	"cucumber": {"emoji": "\U0001F952", "name": "Cucumber", "heal_per_sec": 0.4, "duration": 45.0, "stamina_boost": 0.16},
	"leafy_green": {"emoji": "\U0001F96C", "name": "Leafy Green", "heal_per_sec": 0.35, "duration": 50.0, "stamina_boost": 0.18},
	"broccoli": {"emoji": "\U0001F966", "name": "Broccoli", "heal_per_sec": 0.45, "duration": 55.0, "stamina_boost": 0.17},
	"garlic": {"emoji": "\U0001F9C4", "name": "Garlic", "heal_per_sec": 0.2, "duration": 120.0, "stamina_boost": 0.05},
	"onion": {"emoji": "\U0001F9C5", "name": "Onion", "heal_per_sec": 0.25, "duration": 100.0, "stamina_boost": 0.07},
	"mushroom": {"emoji": "\U0001F344", "name": "Mushroom", "heal_per_sec": 0.5, "duration": 55.0, "stamina_boost": 0.09},
	"peanuts": {"emoji": "\U0001F95C", "name": "Peanuts", "heal_per_sec": 0.4, "duration": 90.0, "stamina_boost": 0.10},
	"beans": {"emoji": "\U0001FAD8", "name": "Beans", "heal_per_sec": 0.55, "duration": 75.0, "stamina_boost": 0.08},
	"chestnut": {"emoji": "\U0001F330", "name": "Chestnut", "heal_per_sec": 0.45, "duration": 85.0, "stamina_boost": 0.07},
	"ginger": {"emoji": "\U0001FAD0", "name": "Ginger Root", "heal_per_sec": 0.3, "duration": 110.0, "stamina_boost": 0.12},
	# === Grains & Bread ===
	"bread": {"emoji": "\U0001F35E", "name": "Bread", "heal_per_sec": 0.75, "duration": 60.0, "stamina_boost": 0.05},
	"croissant": {"emoji": "\U0001F950", "name": "Croissant", "heal_per_sec": 0.7, "duration": 45.0, "stamina_boost": 0.08},
	"baguette": {"emoji": "\U0001F956", "name": "Baguette", "heal_per_sec": 0.8, "duration": 65.0, "stamina_boost": 0.06},
	"flatbread": {"emoji": "\U0001FAD3", "name": "Flatbread", "heal_per_sec": 0.65, "duration": 55.0, "stamina_boost": 0.07},
	"pretzel": {"emoji": "\U0001F968", "name": "Pretzel", "heal_per_sec": 0.5, "duration": 40.0, "stamina_boost": 0.09},
	"bagel": {"emoji": "\U0001F96F", "name": "Bagel", "heal_per_sec": 0.7, "duration": 50.0, "stamina_boost": 0.07},
	"pancakes": {"emoji": "\U0001F95E", "name": "Pancakes", "heal_per_sec": 0.85, "duration": 55.0, "stamina_boost": 0.12},
	"waffle": {"emoji": "\U0001F9C7", "name": "Waffle", "heal_per_sec": 0.8, "duration": 50.0, "stamina_boost": 0.13},
	"rice_ball": {"emoji": "\U0001F359", "name": "Rice Ball", "heal_per_sec": 0.6, "duration": 70.0, "stamina_boost": 0.06},
	"rice_cracker": {"emoji": "\U0001F358", "name": "Rice Cracker", "heal_per_sec": 0.3, "duration": 30.0, "stamina_boost": 0.04},
	"cooked_rice": {"emoji": "\U0001F35A", "name": "Cooked Rice", "heal_per_sec": 0.7, "duration": 80.0, "stamina_boost": 0.05},
	# === Protein & Meat ===
	"meat_leg": {"emoji": "\U0001F356", "name": "Meat on Bone", "heal_per_sec": 1.5, "duration": 120.0, "stamina_boost": 0.05},
	"poultry_leg": {"emoji": "\U0001F357", "name": "Poultry Leg", "heal_per_sec": 1.3, "duration": 100.0, "stamina_boost": 0.07},
	"steak": {"emoji": "\U0001F969", "name": "Steak", "heal_per_sec": 1.8, "duration": 130.0, "stamina_boost": 0.04},
	"bacon": {"emoji": "\U0001F953", "name": "Bacon", "heal_per_sec": 1.0, "duration": 60.0, "stamina_boost": 0.10},
	"hot_dog": {"emoji": "\U0001F32D", "name": "Hot Dog", "heal_per_sec": 0.9, "duration": 50.0, "stamina_boost": 0.08},
	"hamburger": {"emoji": "\U0001F354", "name": "Hamburger", "heal_per_sec": 1.2, "duration": 75.0, "stamina_boost": 0.09},
	"sandwich": {"emoji": "\U0001F96A", "name": "Sandwich", "heal_per_sec": 1.0, "duration": 65.0, "stamina_boost": 0.10},
	"taco": {"emoji": "\U0001F32E", "name": "Taco", "heal_per_sec": 0.95, "duration": 55.0, "stamina_boost": 0.11},
	"burrito": {"emoji": "\U0001F32F", "name": "Burrito", "heal_per_sec": 1.1, "duration": 80.0, "stamina_boost": 0.09},
	"tamale": {"emoji": "\U0001FAD4", "name": "Tamale", "heal_per_sec": 1.0, "duration": 70.0, "stamina_boost": 0.10},
	"stuffed_flatbread": {"emoji": "\U0001F959", "name": "Stuffed Flatbread", "heal_per_sec": 0.95, "duration": 65.0, "stamina_boost": 0.08},
	"falafel": {"emoji": "\U0001F9C6", "name": "Falafel", "heal_per_sec": 0.7, "duration": 50.0, "stamina_boost": 0.11},
	"egg": {"emoji": "\U0001F95A", "name": "Egg", "heal_per_sec": 0.6, "duration": 40.0, "stamina_boost": 0.09},
	"fried_egg": {"emoji": "\U0001F373", "name": "Fried Egg", "heal_per_sec": 0.75, "duration": 45.0, "stamina_boost": 0.10},
	# === Seafood ===
	"fish": {"emoji": "\U0001F41F", "name": "Fish", "heal_per_sec": 1.25, "duration": 80.0, "stamina_boost": 0.12},
	"shrimp": {"emoji": "\U0001F990", "name": "Shrimp", "heal_per_sec": 0.9, "duration": 45.0, "stamina_boost": 0.15},
	"squid": {"emoji": "\U0001F991", "name": "Squid", "heal_per_sec": 0.85, "duration": 50.0, "stamina_boost": 0.11},
	"lobster": {"emoji": "\U0001F99E", "name": "Lobster", "heal_per_sec": 1.4, "duration": 70.0, "stamina_boost": 0.14},
	"crab": {"emoji": "\U0001F980", "name": "Crab", "heal_per_sec": 1.2, "duration": 65.0, "stamina_boost": 0.13},
	"oyster": {"emoji": "\U0001F9AA", "name": "Oyster", "heal_per_sec": 0.6, "duration": 35.0, "stamina_boost": 0.20},
	"sushi": {"emoji": "\U0001F363", "name": "Sushi", "heal_per_sec": 1.1, "duration": 55.0, "stamina_boost": 0.14},
	"fried_shrimp": {"emoji": "\U0001F364", "name": "Fried Shrimp", "heal_per_sec": 1.0, "duration": 50.0, "stamina_boost": 0.12},
	# === Prepared Meals ===
	"stew": {"emoji": "\U0001F372", "name": "Stew", "heal_per_sec": 1.2, "duration": 150.0, "stamina_boost": 0.16},
	"curry": {"emoji": "\U0001F35B", "name": "Curry Rice", "heal_per_sec": 1.3, "duration": 120.0, "stamina_boost": 0.13},
	"spaghetti": {"emoji": "\U0001F35D", "name": "Spaghetti", "heal_per_sec": 1.1, "duration": 100.0, "stamina_boost": 0.11},
	"ramen": {"emoji": "\U0001F35C", "name": "Ramen", "heal_per_sec": 1.15, "duration": 90.0, "stamina_boost": 0.14},
	"steaming_bowl": {"emoji": "\U0001F35C", "name": "Hot Noodle Soup", "heal_per_sec": 1.0, "duration": 110.0, "stamina_boost": 0.15},
	"fondue": {"emoji": "\U0001FAD5", "name": "Fondue", "heal_per_sec": 0.9, "duration": 85.0, "stamina_boost": 0.12},
	"green_salad": {"emoji": "\U0001F957", "name": "Green Salad", "heal_per_sec": 0.4, "duration": 60.0, "stamina_boost": 0.20},
	"shallow_pan_food": {"emoji": "\U0001F958", "name": "Paella", "heal_per_sec": 1.25, "duration": 110.0, "stamina_boost": 0.13},
	"canned_food": {"emoji": "\U0001F96B", "name": "Canned Food", "heal_per_sec": 0.5, "duration": 200.0, "stamina_boost": 0.03},
	"bento_box": {"emoji": "\U0001F371", "name": "Bento Box", "heal_per_sec": 1.15, "duration": 95.0, "stamina_boost": 0.12},
	"dumpling": {"emoji": "\U0001F95F", "name": "Dumpling", "heal_per_sec": 0.8, "duration": 50.0, "stamina_boost": 0.10},
	"fortune_cookie": {"emoji": "\U0001F960", "name": "Fortune Cookie", "heal_per_sec": 0.2, "duration": 15.0, "stamina_boost": 0.30},
	"takeout_box": {"emoji": "\U0001F961", "name": "Takeout Box", "heal_per_sec": 1.0, "duration": 80.0, "stamina_boost": 0.11},
	"oden": {"emoji": "\U0001F362", "name": "Oden", "heal_per_sec": 0.9, "duration": 75.0, "stamina_boost": 0.10},
	"dango": {"emoji": "\U0001F361", "name": "Dango", "heal_per_sec": 0.5, "duration": 30.0, "stamina_boost": 0.15},
	"moon_cake": {"emoji": "\U0001F96E", "name": "Moon Cake", "heal_per_sec": 0.7, "duration": 50.0, "stamina_boost": 0.12},
	"spring_roll": {"emoji": "\U0001F960", "name": "Spring Roll", "heal_per_sec": 0.75, "duration": 45.0, "stamina_boost": 0.11},
	# === Pizza & Fast Food ===
	"pizza": {"emoji": "\U0001F355", "name": "Pizza", "heal_per_sec": 1.1, "duration": 70.0, "stamina_boost": 0.10},
	"fries": {"emoji": "\U0001F35F", "name": "French Fries", "heal_per_sec": 0.5, "duration": 35.0, "stamina_boost": 0.08},
	"popcorn": {"emoji": "\U0001F37F", "name": "Popcorn", "heal_per_sec": 0.2, "duration": 25.0, "stamina_boost": 0.06},
	# === Dairy & Cheese ===
	"cheese": {"emoji": "\U0001F9C0", "name": "Cheese Wedge", "heal_per_sec": 0.8, "duration": 180.0, "stamina_boost": 0.20},
	"butter": {"emoji": "\U0001F9C8", "name": "Butter", "heal_per_sec": 0.3, "duration": 120.0, "stamina_boost": 0.04},
	# === Sweets & Desserts ===
	"chocolate": {"emoji": "\U0001F36B", "name": "Chocolate Bar", "heal_per_sec": 0.6, "duration": 30.0, "stamina_boost": 0.22},
	"candy": {"emoji": "\U0001F36C", "name": "Candy", "heal_per_sec": 0.3, "duration": 15.0, "stamina_boost": 0.28},
	"lollipop": {"emoji": "\U0001F36D", "name": "Lollipop", "heal_per_sec": 0.25, "duration": 20.0, "stamina_boost": 0.25},
	"custard": {"emoji": "\U0001F36E", "name": "Custard", "heal_per_sec": 0.7, "duration": 40.0, "stamina_boost": 0.14},
	"honey": {"emoji": "\U0001F36F", "name": "Honey Pot", "heal_per_sec": 0.9, "duration": 35.0, "stamina_boost": 0.19},
	"cookie": {"emoji": "\U0001F36A", "name": "Cookie", "heal_per_sec": 0.4, "duration": 20.0, "stamina_boost": 0.18},
	"cake": {"emoji": "\U0001F370", "name": "Shortcake", "heal_per_sec": 0.8, "duration": 40.0, "stamina_boost": 0.16},
	"birthday_cake": {"emoji": "\U0001F382", "name": "Birthday Cake", "heal_per_sec": 1.0, "duration": 45.0, "stamina_boost": 0.18},
	"cupcake": {"emoji": "\U0001F9C1", "name": "Cupcake", "heal_per_sec": 0.6, "duration": 25.0, "stamina_boost": 0.17},
	"pie": {"emoji": "\U0001F967", "name": "Pie", "heal_per_sec": 0.9, "duration": 60.0, "stamina_boost": 0.13},
	"ice_cream": {"emoji": "\U0001F368", "name": "Ice Cream", "heal_per_sec": 0.5, "duration": 20.0, "stamina_boost": 0.20},
	"shaved_ice": {"emoji": "\U0001F367", "name": "Shaved Ice", "heal_per_sec": 0.3, "duration": 15.0, "stamina_boost": 0.22},
	"soft_ice_cream": {"emoji": "\U0001F366", "name": "Soft Serve", "heal_per_sec": 0.45, "duration": 18.0, "stamina_boost": 0.19},
	"doughnut": {"emoji": "\U0001F369", "name": "Doughnut", "heal_per_sec": 0.55, "duration": 25.0, "stamina_boost": 0.15},
	# === Drinks (heal fast, short duration) ===
	"baby_bottle": {"emoji": "\U0001F37C", "name": "Milk Bottle", "heal_per_sec": 0.6, "duration": 30.0, "stamina_boost": 0.10},
	"glass_milk": {"emoji": "\U0001F95B", "name": "Glass of Milk", "heal_per_sec": 0.7, "duration": 25.0, "stamina_boost": 0.12},
	"hot_beverage": {"emoji": "\u2615", "name": "Coffee", "heal_per_sec": 0.2, "duration": 10.0, "stamina_boost": 0.35},
	"tea": {"emoji": "\U0001FAD6", "name": "Tea", "heal_per_sec": 0.4, "duration": 30.0, "stamina_boost": 0.20},
	"teacup": {"emoji": "\U0001F375", "name": "Green Tea", "heal_per_sec": 0.35, "duration": 35.0, "stamina_boost": 0.18},
	"sake": {"emoji": "\U0001F376", "name": "Sake", "heal_per_sec": 0.5, "duration": 20.0, "stamina_boost": 0.25},
	"wine": {"emoji": "\U0001F377", "name": "Wine", "heal_per_sec": 0.6, "duration": 25.0, "stamina_boost": 0.22},
	"beer": {"emoji": "\U0001F37A", "name": "Beer", "heal_per_sec": 0.4, "duration": 20.0, "stamina_boost": 0.18},
	"beers": {"emoji": "\U0001F37B", "name": "Beer Mugs", "heal_per_sec": 0.8, "duration": 25.0, "stamina_boost": 0.20},
	"cocktail": {"emoji": "\U0001F378", "name": "Cocktail", "heal_per_sec": 0.3, "duration": 15.0, "stamina_boost": 0.28},
	"tropical_drink": {"emoji": "\U0001F379", "name": "Tropical Drink", "heal_per_sec": 0.5, "duration": 20.0, "stamina_boost": 0.24},
	"tumbler_glass": {"emoji": "\U0001F943", "name": "Whiskey", "heal_per_sec": 0.2, "duration": 10.0, "stamina_boost": 0.30},
	"cup_with_straw": {"emoji": "\U0001F964", "name": "Smoothie", "heal_per_sec": 0.7, "duration": 25.0, "stamina_boost": 0.16},
	"bubble_tea": {"emoji": "\U0001F9CB", "name": "Bubble Tea", "heal_per_sec": 0.5, "duration": 30.0, "stamina_boost": 0.14},
	"juice_box": {"emoji": "\U0001F9C3", "name": "Juice Box", "heal_per_sec": 0.6, "duration": 20.0, "stamina_boost": 0.15},
	"mate": {"emoji": "\U0001F9C9", "name": "Mate", "heal_per_sec": 0.3, "duration": 25.0, "stamina_boost": 0.26},
	"ice_cube": {"emoji": "\U0001F9CA", "name": "Ice Cube", "heal_per_sec": 0.1, "duration": 10.0, "stamina_boost": 0.05},
	# === Condiments & Extras ===
	"salt": {"emoji": "\U0001F9C2", "name": "Salt", "heal_per_sec": 0.1, "duration": 300.0, "stamina_boost": 0.02},
	"jar": {"emoji": "\U0001FAD9", "name": "Jar of Jam", "heal_per_sec": 0.5, "duration": 45.0, "stamina_boost": 0.10},
}

var point_light_texture: Texture2D
var flashlight_texture: Texture2D

func create_light_textures() -> void:
	point_light_texture = _generate_radial_texture(256)
	flashlight_texture = _generate_cone_texture(512)

func _generate_radial_texture(tex_size: int) -> Texture2D:
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(tex_size / 2.0, tex_size / 2.0)
	var half := tex_size / 2.0
	for y in range(tex_size):
		for x in range(tex_size):
			var dist := Vector2(x - center.x, y - center.y).length() / half
			if dist > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var b := (1.0 - dist * dist) * (1.0 - dist)
				img.set_pixel(x, y, Color(b, b, b, b))
	return ImageTexture.create_from_image(img)

func _generate_cone_texture(tex_size: int) -> Texture2D:
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(tex_size / 2.0, tex_size / 2.0)
	var half := tex_size / 2.0
	for y in range(tex_size):
		for x in range(tex_size):
			var dir := Vector2(x - center.x, y - center.y)
			var dist := dir.length() / half
			if dist > 1.0 or dist < 0.001:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var angle := absf(dir.angle())
			var cone_half := PI / 5.0
			if angle > cone_half:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var angle_f := 1.0 - (angle / cone_half)
			angle_f = angle_f * angle_f
			var dist_f := 1.0 - dist
			dist_f = dist_f * sqrt(dist_f)
			var b := angle_f * dist_f
			img.set_pixel(x, y, Color(b, b, b, b))
	return ImageTexture.create_from_image(img)

func get_difficulty_multiplier(mission_time_seconds: float) -> float:
	var minutes := mission_time_seconds / 60.0
	var time_mult := 1.0 + (minutes * 0.05)
	var diff_mult := GameSystems.get_diff_mult("enemy_dmg") if GameSystems else 1.0
	return time_mult * diff_mult

func get_enemy_name(etype: int) -> String:
	if etype in enemy_stats:
		return enemy_stats[etype].get("name", "Unknown")
	return "Unknown"

func get_class_name_for(race: Race, player_class: PlayerClass) -> String:
	if race not in class_names:
		return "Unknown"
	if player_class not in class_names[race]:
		return "Unknown"
	return class_names[race][player_class]

func get_race_data(race: Race) -> Dictionary:
	return race_stats.get(race, {})

func get_enemy_data(etype: EnemyType) -> Dictionary:
	return enemy_stats.get(etype, {})
