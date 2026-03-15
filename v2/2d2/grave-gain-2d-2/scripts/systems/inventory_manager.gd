extends Node

# ===== INVENTORY MANAGER =====
# Manages player inventory: equipment, consumables, materials, quest items

signal inventory_changed()
signal item_equipped(slot: String, item: Dictionary)
signal item_unequipped(slot: String)
signal item_used(item: Dictionary)

const MAX_INVENTORY_SIZE: int = 40
const MAX_STACK_SIZE: int = 99

# Equipment slots
enum EquipSlot { WEAPON, OFFHAND, HELMET, CHEST, BOOTS, RING1, RING2, AMULET, TRINKET }

const EQUIP_SLOT_NAMES: Dictionary = {
	EquipSlot.WEAPON: "Weapon",
	EquipSlot.OFFHAND: "Offhand",
	EquipSlot.HELMET: "Helmet",
	EquipSlot.CHEST: "Chest",
	EquipSlot.BOOTS: "Boots",
	EquipSlot.RING1: "Ring 1",
	EquipSlot.RING2: "Ring 2",
	EquipSlot.AMULET: "Amulet",
	EquipSlot.TRINKET: "Trinket",
}

# Item categories
enum ItemCategory { WEAPON, ARMOR, CONSUMABLE, MATERIAL, QUEST, MISC }

# Rarity tiers
const RARITY_ORDER: Array[String] = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const RARITY_COLORS: Dictionary = {
	"common": Color(0.8, 0.8, 0.8),
	"uncommon": Color(0.3, 1.0, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.7, 0.1),
	"mythic": Color(1.0, 0.2, 0.2),
}

# Inventory data
var inventory: Array[Dictionary] = []
var equipped: Dictionary = {}  # EquipSlot -> Dictionary (item)
var gold: int = 0

func _ready() -> void:
	# Initialize empty equipment slots
	for slot in EquipSlot.values():
		equipped[slot] = {}

# ===== INVENTORY OPERATIONS =====

func add_item(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	
	# Check if stackable and already exists
	if item.get("stackable", false):
		for i in range(inventory.size()):
			if inventory[i].get("id", "") == item.get("id", "") and inventory[i].get("count", 1) < MAX_STACK_SIZE:
				inventory[i]["count"] = mini(inventory[i].get("count", 1) + item.get("count", 1), MAX_STACK_SIZE)
				inventory_changed.emit()
				return true
	
	# Add to new slot
	if inventory.size() >= MAX_INVENTORY_SIZE:
		return false
	
	var new_item := item.duplicate(true)
	if not new_item.has("count"):
		new_item["count"] = 1
	if not new_item.has("uid"):
		new_item["uid"] = _generate_uid()
	inventory.append(new_item)
	inventory_changed.emit()
	return true

func remove_item(index: int) -> Dictionary:
	if index < 0 or index >= inventory.size():
		return {}
	var item := inventory[index]
	inventory.remove_at(index)
	inventory_changed.emit()
	return item

func remove_item_by_id(item_id: String, count: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i].get("id", "") == item_id:
			var current_count: int = inventory[i].get("count", 1)
			if current_count > count:
				inventory[i]["count"] = current_count - count
				inventory_changed.emit()
				return true
			elif current_count == count:
				inventory.remove_at(i)
				inventory_changed.emit()
				return true
	return false

func has_item(item_id: String, count: int = 1) -> bool:
	var total: int = 0
	for item in inventory:
		if item.get("id", "") == item_id:
			total += item.get("count", 1)
	return total >= count

func get_item_count(item_id: String) -> int:
	var total: int = 0
	for item in inventory:
		if item.get("id", "") == item_id:
			total += item.get("count", 1)
	return total

func get_inventory_size() -> int:
	return inventory.size()

func is_inventory_full() -> bool:
	return inventory.size() >= MAX_INVENTORY_SIZE

# ===== EQUIPMENT OPERATIONS =====

func equip_item(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		return false
	
	var item := inventory[index]
	var slot_type = item.get("equip_slot", -1)
	if slot_type == -1:
		return false
	
	# Unequip current item in that slot
	if not equipped[slot_type].is_empty():
		var old_item: Dictionary = equipped[slot_type].duplicate(true)
		equipped[slot_type] = {}
		inventory.append(old_item)
	
	# Equip the new item
	equipped[slot_type] = item.duplicate(true)
	inventory.remove_at(index)
	
	item_equipped.emit(EQUIP_SLOT_NAMES.get(slot_type, "Unknown"), equipped[slot_type])
	inventory_changed.emit()
	return true

func unequip_item(slot: int) -> bool:
	if equipped.get(slot, {}).is_empty():
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		return false
	
	var item: Dictionary = equipped[slot].duplicate(true)
	equipped[slot] = {}
	inventory.append(item)
	
	item_unequipped.emit(EQUIP_SLOT_NAMES.get(slot, "Unknown"))
	inventory_changed.emit()
	return true

func get_equipped(slot: int) -> Dictionary:
	return equipped.get(slot, {})

func get_total_stat_bonus(stat_name: String) -> float:
	var total: float = 0.0
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		if not item.is_empty():
			total += item.get("stats", {}).get(stat_name, 0.0)
	return total

# ===== CONSUMABLE USE =====

func use_item(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		return false
	
	var item := inventory[index]
	if item.get("category", -1) != ItemCategory.CONSUMABLE:
		return false
	
	item_used.emit(item)
	
	var count: int = item.get("count", 1)
	if count <= 1:
		inventory.remove_at(index)
	else:
		inventory[index]["count"] = count - 1
	
	inventory_changed.emit()
	return true

# ===== SORTING =====

func sort_by_rarity() -> void:
	inventory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra: int = RARITY_ORDER.find(a.get("rarity", "common"))
		var rb: int = RARITY_ORDER.find(b.get("rarity", "common"))
		return ra > rb
	)
	inventory_changed.emit()

func sort_by_name() -> void:
	inventory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("name", "") < b.get("name", "")
	)
	inventory_changed.emit()

func sort_by_category() -> void:
	inventory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("category", 0) < b.get("category", 0)
	)
	inventory_changed.emit()

# ===== GOLD =====

func add_gold(amount: int) -> void:
	gold += amount
	inventory_changed.emit()

func remove_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	inventory_changed.emit()
	return true

func get_gold() -> int:
	return gold

# ===== ITEM GENERATION =====

func generate_random_item(level: int, rarity_override: String = "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var rarity: String = rarity_override
	if rarity == "":
		var roll := rng.randf()
		if roll < 0.01:
			rarity = "mythic"
		elif roll < 0.05:
			rarity = "legendary"
		elif roll < 0.15:
			rarity = "epic"
		elif roll < 0.35:
			rarity = "rare"
		elif roll < 0.60:
			rarity = "uncommon"
		else:
			rarity = "common"
	
	var item_type := rng.randi_range(0, 5)
	var item: Dictionary = {}
	
	match item_type:
		0:  # Weapon
			item = _generate_weapon(level, rarity, rng)
		1:  # Helmet
			item = _generate_armor(level, rarity, rng, EquipSlot.HELMET)
		2:  # Chest
			item = _generate_armor(level, rarity, rng, EquipSlot.CHEST)
		3:  # Boots
			item = _generate_armor(level, rarity, rng, EquipSlot.BOOTS)
		4:  # Ring
			item = _generate_accessory(level, rarity, rng, EquipSlot.RING1)
		5:  # Consumable
			item = _generate_consumable(level, rarity, rng)
	
	return item

func _generate_weapon(level: int, rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	var weapons := [
		{"name": "Rusty Sword", "emoji": "\U0001F5E1\uFE0F", "base_dmg": 5.0},
		{"name": "Iron Axe", "emoji": "\U0001FA93", "base_dmg": 7.0},
		{"name": "War Hammer", "emoji": "\U0001F528", "base_dmg": 8.0},
		{"name": "Hunting Bow", "emoji": "\U0001F3F9", "base_dmg": 4.0},
		{"name": "Magic Staff", "emoji": "\U0001FA84", "base_dmg": 6.0},
		{"name": "Crystal Dagger", "emoji": "\U0001F48E", "base_dmg": 3.0},
	]
	var base: Dictionary = weapons[rng.randi_range(0, weapons.size() - 1)]
	var rarity_mult := _get_rarity_mult(rarity)
	var dmg: float = base["base_dmg"] * (1.0 + level * 0.1) * rarity_mult
	
	var prefixes := _get_rarity_prefixes(rarity)
	var prefix: String = prefixes[rng.randi_range(0, prefixes.size() - 1)]
	
	return {
		"id": "weapon_" + str(rng.randi()),
		"uid": _generate_uid(),
		"name": prefix + " " + base["name"],
		"emoji": base["emoji"],
		"category": ItemCategory.WEAPON,
		"equip_slot": EquipSlot.WEAPON,
		"rarity": rarity,
		"level": level,
		"stackable": false,
		"stats": {
			"damage": snappedf(dmg, 0.1),
			"crit_chance": rng.randf_range(0.0, 0.05) * rarity_mult,
			"attack_speed": rng.randf_range(0.8, 1.2),
		},
		"description": "A " + rarity + " weapon that deals " + str(int(dmg)) + " damage.",
	}

func _generate_armor(level: int, rarity: String, rng: RandomNumberGenerator, slot: int) -> Dictionary:
	var slot_names := {
		EquipSlot.HELMET: {"name": "Helm", "emoji": "\U0001FA96"},
		EquipSlot.CHEST: {"name": "Chestplate", "emoji": "\U0001F6E1\uFE0F"},
		EquipSlot.BOOTS: {"name": "Boots", "emoji": "\U0001F462"},
	}
	var base: Dictionary = slot_names.get(slot, {"name": "Armor", "emoji": "\U0001F6E1\uFE0F"})
	var rarity_mult := _get_rarity_mult(rarity)
	var defense := (3.0 + level * 0.5) * rarity_mult
	
	var prefixes := _get_rarity_prefixes(rarity)
	var prefix: String = prefixes[rng.randi_range(0, prefixes.size() - 1)]
	
	return {
		"id": "armor_" + str(slot) + "_" + str(rng.randi()),
		"uid": _generate_uid(),
		"name": prefix + " " + base["name"],
		"emoji": base["emoji"],
		"category": ItemCategory.ARMOR,
		"equip_slot": slot,
		"rarity": rarity,
		"level": level,
		"stackable": false,
		"stats": {
			"defense": snappedf(defense, 0.1),
			"max_hp": rng.randf_range(0.0, 10.0) * rarity_mult,
		},
		"description": "A " + rarity + " armor piece with " + str(int(defense)) + " defense.",
	}

func _generate_accessory(level: int, rarity: String, rng: RandomNumberGenerator, slot: int) -> Dictionary:
	var rarity_mult := _get_rarity_mult(rarity)
	var prefixes := _get_rarity_prefixes(rarity)
	var prefix: String = prefixes[rng.randi_range(0, prefixes.size() - 1)]
	
	var acc_types := [
		{"name": "Ring", "emoji": "\U0001F48D"},
		{"name": "Amulet", "emoji": "\U0001F4FF"},
		{"name": "Charm", "emoji": "\U0001F9FF"},
	]
	var base: Dictionary = acc_types[rng.randi_range(0, acc_types.size() - 1)]
	
	# Pick 1-3 random stat bonuses
	var possible_stats := ["damage", "defense", "max_hp", "crit_chance", "speed", "lifesteal", "dodge"]
	var stats: Dictionary = {}
	var num_stats := rng.randi_range(1, mini(3, 1 + RARITY_ORDER.find(rarity)))
	for _i in range(num_stats):
		var stat: String = possible_stats[rng.randi_range(0, possible_stats.size() - 1)]
		var val := rng.randf_range(1.0, 5.0) * rarity_mult * (1.0 + level * 0.05)
		if stat in ["crit_chance", "lifesteal", "dodge"]:
			val *= 0.01
		stats[stat] = snappedf(val, 0.01)
	
	return {
		"id": "acc_" + str(rng.randi()),
		"uid": _generate_uid(),
		"name": prefix + " " + base["name"],
		"emoji": base["emoji"],
		"category": ItemCategory.ARMOR,
		"equip_slot": slot,
		"rarity": rarity,
		"level": level,
		"stackable": false,
		"stats": stats,
		"description": "A " + rarity + " accessory with magical properties.",
	}

func _generate_consumable(level: int, rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	var consumables := [
		{"name": "Health Potion", "emoji": "\u2764\uFE0F", "effect": "heal", "base_val": 25.0},
		{"name": "Mana Potion", "emoji": "\U0001F537", "effect": "mana", "base_val": 20.0},
		{"name": "Stamina Elixir", "emoji": "\U0001F7E2", "effect": "stamina", "base_val": 30.0},
		{"name": "Antidote", "emoji": "\U0001F9EA", "effect": "cure_poison", "base_val": 1.0},
		{"name": "Speed Tonic", "emoji": "\u26A1", "effect": "speed_buff", "base_val": 1.3},
		{"name": "Strength Elixir", "emoji": "\U0001F4AA", "effect": "damage_buff", "base_val": 1.5},
	]
	var base: Dictionary = consumables[rng.randi_range(0, consumables.size() - 1)]
	var rarity_mult := _get_rarity_mult(rarity)
	var val: float = base["base_val"] * rarity_mult * (1.0 + level * 0.1)
	
	return {
		"id": "consumable_" + base["effect"],
		"uid": _generate_uid(),
		"name": base["name"],
		"emoji": base["emoji"],
		"category": ItemCategory.CONSUMABLE,
		"rarity": rarity,
		"level": level,
		"stackable": true,
		"count": 1,
		"effect": base["effect"],
		"value": snappedf(val, 0.1),
		"description": "Use to gain " + base["effect"].replace("_", " ") + " effect.",
	}

func _get_rarity_mult(rarity: String) -> float:
	match rarity:
		"common": return 1.0
		"uncommon": return 1.3
		"rare": return 1.7
		"epic": return 2.2
		"legendary": return 3.0
		"mythic": return 4.5
	return 1.0

func _get_rarity_prefixes(rarity: String) -> Array[String]:
	match rarity:
		"common": return ["Worn", "Simple", "Basic", "Plain"]
		"uncommon": return ["Sturdy", "Solid", "Fine", "Polished"]
		"rare": return ["Superior", "Enchanted", "Masterwork", "Runed"]
		"epic": return ["Arcane", "Radiant", "Prismatic", "Celestial"]
		"legendary": return ["Legendary", "Mythical", "Godforged", "Ancient"]
		"mythic": return ["Eternal", "Void-Touched", "Reality-Warped", "Primordial"]
	return ["Basic"]

var _uid_counter: int = 0
func _generate_uid() -> String:
	_uid_counter += 1
	return "item_" + str(Time.get_ticks_msec()) + "_" + str(_uid_counter)

# ===== SAVE/LOAD =====

func save_inventory() -> Dictionary:
	return {
		"inventory": inventory.duplicate(true),
		"equipped": equipped.duplicate(true),
		"gold": gold,
	}

func load_inventory(data: Dictionary) -> void:
	inventory = data.get("inventory", [])
	equipped = data.get("equipped", {})
	gold = data.get("gold", 0)
	inventory_changed.emit()
