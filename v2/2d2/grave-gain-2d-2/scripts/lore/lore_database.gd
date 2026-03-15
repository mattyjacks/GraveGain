extends RefCounted

const CATEGORIES: Dictionary = {
	"the_world": {"name": "The World of MoonRock", "icon": "\U0001F30D", "order": 0},
	"human_history": {"name": "Human History", "icon": "\U0001F680", "order": 1},
	"elven_history": {"name": "Elven History", "icon": "\U0001F33F", "order": 2},
	"dwarven_history": {"name": "Dwarven History", "icon": "\u2692\uFE0F", "order": 3},
	"orc_history": {"name": "Orc History", "icon": "\U0001F4AA", "order": 4},
	"goblin_tales": {"name": "Goblin Tales", "icon": "\U0001F47E", "order": 5},
	"the_necrogenesis": {"name": "The NecroGenesis", "icon": "\U0001F480", "order": 6},
	"lucifer_hades": {"name": "Lucifer Hades", "icon": "\U0001F525", "order": 7},
	"the_gods": {"name": "The Gods", "icon": "\u2728", "order": 8},
	"the_undead": {"name": "The Undead", "icon": "\U0001F9DF", "order": 9},
	"safespaces": {"name": "SafeSpaces & Ley Lines", "icon": "\U0001F308", "order": 10},
	"personal_accounts": {"name": "Personal Accounts", "icon": "\U0001F4DD", "order": 11},
	"weapons_tech": {"name": "Weapons & Technology", "icon": "\u2694\uFE0F", "order": 12},
	"humor": {"name": "Humor & Oddities", "icon": "\U0001F921", "order": 13},
}

const TYPE_INFO: Dictionary = {
	"book": {"emoji": "\U0001F4D6", "name": "Book"},
	"scroll": {"emoji": "\U0001F4DC", "name": "Scroll"},
	"sign": {"emoji": "\U0001FAA7", "name": "Sign"},
	"gravestone": {"emoji": "\U0001FAA6", "name": "Gravestone"},
	"note": {"emoji": "\U0001F4DD", "name": "Note"},
	"tablet": {"emoji": "\U0001F5FF", "name": "Tablet"},
	"journal": {"emoji": "\U0001F4D4", "name": "Journal"},
	"letter": {"emoji": "\u2709\uFE0F", "name": "Letter"},
	"crystal": {"emoji": "\U0001F4A0", "name": "Crystal Memory"},
}

static func get_all_entries() -> Dictionary:
	var entries: Dictionary = {}
	var p1 := preload("res://scripts/lore/lore_entries_1.gd")
	var p2 := preload("res://scripts/lore/lore_entries_2.gd")
	entries.merge(p1.get_entries())
	entries.merge(p2.get_entries())
	return entries

static func get_entry_ids_by_category(entries: Dictionary) -> Dictionary:
	var by_cat: Dictionary = {}
	for cat_key in CATEGORIES:
		by_cat[cat_key] = []
	for id in entries:
		var cat: String = entries[id]["category"]
		if cat in by_cat:
			by_cat[cat].append(id)
	return by_cat

static func get_entry_ids_by_rarity(entries: Dictionary, rarity: String) -> Array:
	var result: Array = []
	for id in entries:
		if entries[id]["rarity"] == rarity:
			result.append(id)
	return result
