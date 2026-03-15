extends Node

# Botany Skill - grow plants in personal quarters with space management

class_name BotanySkill

signal plant_planted(plant: Dictionary)
signal plant_grown(plant: Dictionary, yield_amount: float)
signal plant_harvested(plant: Dictionary, yield_amount: float)
signal space_changed(used: float, total: float)

var skill_level: int = 1
var skill_xp: float = 0.0
var xp_per_level: float = 100.0

var plants: Array[Dictionary] = []
var space_used: float = 0.0
var space_total: float = 100.0

var plant_types: Dictionary = {
	"sativa": {
		"name": "Cannabis Sativa",
		"space": 15.0,
		"growth_time": 120.0,
		"yield": 3,
		"value": 50.0,
		"emoji": "🌿",
	},
	"indica": {
		"name": "Cannabis Indica",
		"space": 12.0,
		"growth_time": 100.0,
		"yield": 4,
		"value": 45.0,
		"emoji": "🍃",
	},
	"hybrid": {
		"name": "Cannabis Hybrid",
		"space": 14.0,
		"growth_time": 110.0,
		"yield": 3,
		"value": 55.0,
		"emoji": "🌱",
	},
	"magic_mushroom": {
		"name": "Magic Mushroom",
		"space": 8.0,
		"growth_time": 80.0,
		"yield": 2,
		"value": 75.0,
		"emoji": "🍄",
	},
	"tomato": {
		"name": "Tomato Plant",
		"space": 6.0,
		"growth_time": 60.0,
		"yield": 5,
		"value": 10.0,
		"emoji": "🍅",
	},
	"lettuce": {
		"name": "Lettuce",
		"space": 4.0,
		"growth_time": 45.0,
		"yield": 6,
		"value": 8.0,
		"emoji": "🥬",
	},
	"basil": {
		"name": "Basil",
		"space": 3.0,
		"growth_time": 40.0,
		"yield": 4,
		"value": 12.0,
		"emoji": "🌿",
	},
	"oak_tree": {
		"name": "Oak Tree",
		"space": 30.0,
		"growth_time": 300.0,
		"yield": 10,
		"value": 200.0,
		"emoji": "🌳",
	},
	"apple_tree": {
		"name": "Apple Tree",
		"space": 25.0,
		"growth_time": 250.0,
		"yield": 8,
		"value": 150.0,
		"emoji": "🌳",
	},
}

func _ready() -> void:
	_load_skill_data()

func _load_skill_data() -> void:
	var config = ConfigFile.new()
	if config.load("user://skills.save") == OK:
		skill_level = config.get_value("botany", "level", 1)
		skill_xp = config.get_value("botany", "xp", 0.0)
		space_total = config.get_value("botany", "space_total", 100.0)
	
	_load_plants()

func _load_plants() -> void:
	var config = ConfigFile.new()
	if config.load("user://plants.save") == OK:
		var plant_count = config.get_value("plants", "count", 0)
		for i in range(plant_count):
			var plant_data = {
				"type": config.get_value("plants", "type_%d" % i, "tomato"),
				"growth_time": config.get_value("plants", "growth_%d" % i, 0.0),
				"planted_at": config.get_value("plants", "planted_%d" % i, 0.0),
			}
			plants.append(plant_data)
			_update_space()

func _save_skill_data() -> void:
	var config = ConfigFile.new()
	config.set_value("botany", "level", skill_level)
	config.set_value("botany", "xp", skill_xp)
	config.set_value("botany", "space_total", space_total)
	config.save("user://skills.save")
	
	_save_plants()

func _save_plants() -> void:
	var config = ConfigFile.new()
	config.set_value("plants", "count", plants.size())
	for i in range(plants.size()):
		config.set_value("plants", "type_%d" % i, plants[i]["type"])
		config.set_value("plants", "growth_%d" % i, plants[i]["growth_time"])
		config.set_value("plants", "planted_%d" % i, plants[i]["planted_at"])
	config.save("user://plants.save")

func plant_seed(plant_type: String) -> bool:
	if not plant_types.has(plant_type):
		return false
	
	var plant_data = plant_types[plant_type]
	
	# Check space
	if space_used + plant_data["space"] > space_total:
		return false
	
	var new_plant = {
		"type": plant_type,
		"growth_time": plant_data["growth_time"],
		"planted_at": Time.get_ticks_msec() / 1000.0,
	}
	
	plants.append(new_plant)
	_update_space()
	plant_planted.emit(new_plant)
	_save_skill_data()
	
	return true

func update_plants(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for plant in plants:
		var plant_data = plant_types[plant["type"]]
		var elapsed = current_time - plant["planted_at"]
		var growth_progress = elapsed / plant_data["growth_time"]
		
		if growth_progress >= 1.0 and plant.get("harvested", false) == false:
			plant["harvested"] = true
			plant_grown.emit(plant, plant_data["yield"])

func harvest_plant(plant_index: int) -> float:
	if plant_index < 0 or plant_index >= plants.size():
		return 0.0
	
	var plant = plants[plant_index]
	var plant_data = plant_types[plant["type"]]
	
	var yield_amount = plant_data["yield"] + skill_level
	var value = plant_data["value"] * yield_amount
	
	plants.remove_at(plant_index)
	_update_space()
	
	# Gain XP
	add_xp(5.0 + (skill_level * 1.0))
	
	plant_harvested.emit(plant, yield_amount)
	_save_skill_data()
	
	return value

func remove_plant(plant_index: int) -> void:
	if plant_index >= 0 and plant_index < plants.size():
		plants.remove_at(plant_index)
		_update_space()
		_save_skill_data()

func _update_space() -> void:
	space_used = 0.0
	for plant in plants:
		var plant_data = plant_types[plant["type"]]
		space_used += plant_data["space"]
	
	space_changed.emit(space_used, space_total)

func upgrade_quarters(new_size: float, cost: float) -> bool:
	space_total = new_size
	_save_skill_data()
	return true

func add_xp(amount: float) -> void:
	skill_xp += amount
	
	while skill_xp >= xp_per_level:
		skill_xp -= xp_per_level
		skill_level += 1
		xp_per_level *= 1.1
	
	_save_skill_data()

func get_plants() -> Array[Dictionary]:
	return plants

func get_plant_growth_progress(plant_index: int) -> float:
	if plant_index < 0 or plant_index >= plants.size():
		return 0.0
	
	var plant = plants[plant_index]
	var plant_data = plant_types[plant["type"]]
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - plant["planted_at"]
	var progress = minf(elapsed / plant_data["growth_time"], 1.0)
	
	return progress

func get_space_used() -> float:
	return space_used

func get_space_total() -> float:
	return space_total

func get_space_percentage() -> float:
	return (space_used / space_total) * 100.0

func get_skill_level() -> int:
	return skill_level

func get_skill_xp() -> float:
	return skill_xp

func get_plant_types() -> Dictionary:
	return plant_types

func can_plant(plant_type: String) -> bool:
	if not plant_types.has(plant_type):
		return false
	
	var plant_data = plant_types[plant_type]
	return space_used + plant_data["space"] <= space_total
