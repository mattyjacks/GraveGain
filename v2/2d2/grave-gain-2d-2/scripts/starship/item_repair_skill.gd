extends Node

# Item Repair Skill - repair damaged items through mini-game mechanics

class_name ItemRepairSkill

signal repair_started(item: Dictionary)
signal repair_progress(item: Dictionary, progress: float)
signal repair_completed(item: Dictionary, cost: float)
signal repair_failed(item: Dictionary)

var skill_level: int = 1
var skill_xp: float = 0.0
var xp_per_level: float = 100.0

var current_repair_item: Dictionary = {}
var repair_progress_value: float = 0.0
var repair_active: bool = false

var repair_costs: Dictionary = {
	"common": 5.0,
	"uncommon": 15.0,
	"rare": 40.0,
	"epic": 100.0,
	"legendary": 250.0,
}

var repair_times: Dictionary = {
	"common": 5.0,
	"uncommon": 8.0,
	"rare": 12.0,
	"epic": 18.0,
	"legendary": 25.0,
}

var repair_parts: Dictionary = {
	"common": ["bolt", "screw", "wire"],
	"uncommon": ["spring", "gear", "circuit"],
	"rare": ["crystal", "alloy", "core"],
	"epic": ["essence", "matrix", "nexus"],
	"legendary": ["void_shard", "star_dust", "infinity_stone"],
}

func _ready() -> void:
	_load_skill_data()

func _load_skill_data() -> void:
	var config = ConfigFile.new()
	if config.load("user://skills.save") == OK:
		skill_level = config.get_value("repair", "level", 1)
		skill_xp = config.get_value("repair", "xp", 0.0)

func _save_skill_data() -> void:
	var config = ConfigFile.new()
	config.set_value("repair", "level", skill_level)
	config.set_value("repair", "xp", skill_xp)
	config.save("user://skills.save")

func start_repair(item: Dictionary) -> bool:
	if repair_active:
		return false
	
	if not item.has("durability") or item["durability"] >= 100.0:
		return false
	
	current_repair_item = item.duplicate()
	repair_progress_value = 0.0
	repair_active = true
	repair_started.emit(item)
	return true

func update_repair(delta: float, click_count: int = 0, drag_progress: float = 0.0) -> void:
	if not repair_active or current_repair_item.is_empty():
		return
	
	var rarity = current_repair_item.get("rarity", "common")
	var repair_time = repair_times.get(rarity, 5.0)
	
	# Progress from clicking and dragging mini-games
	var progress_per_second = (1.0 / repair_time) * 100.0
	repair_progress_value += progress_per_second * delta
	
	# Bonus from click mini-game
	if click_count > 0:
		repair_progress_value += click_count * 2.0
	
	# Bonus from drag mini-game
	if drag_progress > 0.0:
		repair_progress_value += drag_progress * 1.5
	
	repair_progress_value = minf(repair_progress_value, 100.0)
	repair_progress.emit(current_repair_item, repair_progress_value)
	
	if repair_progress_value >= 100.0:
		_complete_repair()

func _complete_repair() -> void:
	if current_repair_item.is_empty():
		return
	
	var rarity = current_repair_item.get("rarity", "common")
	var cost = repair_costs.get(rarity, 5.0)
	
	# Durability restored based on skill level
	var durability_restored = 50.0 + (skill_level * 5.0)
	current_repair_item["durability"] = minf(current_repair_item.get("durability", 0.0) + durability_restored, 100.0)
	
	# Gain XP
	var xp_gained = 10.0 + (skill_level * 2.0)
	add_xp(xp_gained)
	
	repair_completed.emit(current_repair_item, cost)
	repair_active = false
	current_repair_item = {}
	repair_progress_value = 0.0

func cancel_repair() -> void:
	if repair_active:
		repair_failed.emit(current_repair_item)
		repair_active = false
		current_repair_item = {}
		repair_progress_value = 0.0

func add_xp(amount: float) -> void:
	skill_xp += amount
	
	while skill_xp >= xp_per_level:
		skill_xp -= xp_per_level
		skill_level += 1
		xp_per_level *= 1.1
	
	_save_skill_data()

func get_repair_cost(item: Dictionary) -> float:
	var rarity = item.get("rarity", "common")
	return repair_costs.get(rarity, 5.0)

func get_repair_time(item: Dictionary) -> float:
	var rarity = item.get("rarity", "common")
	return repair_times.get(rarity, 5.0)

func get_required_parts(item: Dictionary) -> Array[String]:
	var rarity = item.get("rarity", "common")
	var parts = repair_parts.get(rarity, [])
	return Array(parts)

func get_skill_level() -> int:
	return skill_level

func get_skill_xp() -> float:
	return skill_xp

func is_repairing() -> bool:
	return repair_active

func get_repair_progress() -> float:
	return repair_progress_value
