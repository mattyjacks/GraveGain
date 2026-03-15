extends Node

signal lore_collected(entry_id: String)
signal lore_collection_updated(total: int, collected: int)

const LoreDatabase = preload("res://scripts/lore/lore_database.gd")

const SAVE_PATH := "user://lore_collection.save"
const NEW_LORE_WEIGHT := 3.0
const OLD_LORE_WEIGHT := 1.0

var all_entries: Dictionary = {}
var collected_ids: Dictionary = {}
var read_ids: Dictionary = {}
var total_entries: int = 0
var total_collected: int = 0

func _ready() -> void:
	all_entries = LoreDatabase.get_all_entries()
	total_entries = all_entries.size()
	load_collection()

func has_collected(entry_id: String) -> bool:
	return entry_id in collected_ids

func has_read(entry_id: String) -> bool:
	return entry_id in read_ids

func collect_entry(entry_id: String) -> bool:
	if entry_id not in all_entries:
		return false
	if entry_id in collected_ids:
		return false
	collected_ids[entry_id] = Time.get_unix_time_from_system()
	total_collected = collected_ids.size()
	lore_collected.emit(entry_id)
	lore_collection_updated.emit(total_entries, total_collected)
	save_collection()
	return true

func mark_read(entry_id: String) -> void:
	if entry_id in all_entries:
		read_ids[entry_id] = true
		save_collection()

func get_entry(entry_id: String) -> Dictionary:
	if entry_id in all_entries:
		return all_entries[entry_id]
	return {}

func get_collected_entries() -> Array:
	var result: Array = []
	for id in collected_ids:
		if id in all_entries:
			result.append(all_entries[id])
	return result

func get_collected_by_category(category: String) -> Array:
	var result: Array = []
	for id in collected_ids:
		if id in all_entries and all_entries[id]["category"] == category:
			result.append(all_entries[id])
	return result

func get_category_progress(category: String) -> Dictionary:
	var total := 0
	var collected := 0
	for id in all_entries:
		if all_entries[id]["category"] == category:
			total += 1
			if id in collected_ids:
				collected += 1
	return {"total": total, "collected": collected}

func get_completion_percentage() -> float:
	if total_entries == 0:
		return 0.0
	return float(total_collected) / float(total_entries) * 100.0

func pick_lore_for_spawn(rng: RandomNumberGenerator, allowed_types: Array = [], allowed_rarities: Array = []) -> String:
	var candidates: Array = []
	var weights: Array = []

	for id in all_entries:
		var entry: Dictionary = all_entries[id]
		if allowed_types.size() > 0 and entry["type"] not in allowed_types:
			continue
		if allowed_rarities.size() > 0 and entry["rarity"] not in allowed_rarities:
			continue
		candidates.append(id)
		if id in collected_ids:
			weights.append(OLD_LORE_WEIGHT)
		else:
			weights.append(NEW_LORE_WEIGHT)

	if candidates.is_empty():
		return ""

	var total_weight := 0.0
	for w in weights:
		total_weight += w
	if total_weight <= 0.0:
		return candidates[0] if not candidates.is_empty() else ""

	var roll := rng.randf() * total_weight
	var cumulative := 0.0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]

	return candidates[candidates.size() - 1]

func pick_room_lore(rng: RandomNumberGenerator) -> String:
	var types := ["book", "scroll", "note", "journal", "letter", "crystal", "tablet"]
	var rarities := ["common", "uncommon", "rare"]
	return pick_lore_for_spawn(rng, types, rarities)

func pick_corridor_lore(rng: RandomNumberGenerator) -> String:
	var types := ["note", "scroll", "sign"]
	var rarities := ["common", "uncommon"]
	return pick_lore_for_spawn(rng, types, rarities)

func pick_gravestone_lore(rng: RandomNumberGenerator) -> String:
	var types := ["gravestone"]
	return pick_lore_for_spawn(rng, types)

func pick_sign_lore(rng: RandomNumberGenerator) -> String:
	var types := ["sign"]
	return pick_lore_for_spawn(rng, types)

func pick_rare_lore(rng: RandomNumberGenerator) -> String:
	var rarities := ["epic", "legendary"]
	return pick_lore_for_spawn(rng, [], rarities)

func save_collection() -> void:
	var save_data := {
		"collected": collected_ids,
		"read": read_ids,
		"version": 1,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))

func load_collection() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file = null

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return
	if not json.data is Dictionary:
		return

	var data: Dictionary = json.data
	if "collected" in data:
		collected_ids = data["collected"]
	if "read" in data:
		read_ids = data["read"]
	total_collected = collected_ids.size()

func reset_collection() -> void:
	collected_ids.clear()
	read_ids.clear()
	total_collected = 0
	save_collection()
	lore_collection_updated.emit(total_entries, 0)
