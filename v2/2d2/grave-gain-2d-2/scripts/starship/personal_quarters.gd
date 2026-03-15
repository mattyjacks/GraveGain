extends Node2D

# Personal Quarters - player's room on the starship with botany and repair stations

class_name PersonalQuarters

signal room_upgraded(new_size: Vector2)
signal skill_used(skill_name: String)

var room_size: Vector2 = Vector2(400, 300)
var room_level: int = 1

var upgrade_costs: Dictionary = {
	1: 50.0,
	2: 150.0,
	3: 400.0,
	4: 1000.0,
	5: 2500.0,
}

var upgrade_sizes: Dictionary = {
	0: Vector2(400, 300),
	1: Vector2(600, 400),
	2: Vector2(800, 500),
	3: Vector2(1000, 600),
	4: Vector2(1200, 700),
	5: Vector2(1400, 800),
}

var botany_skill: BotanySkill = null
var repair_skill: ItemRepairSkill = null
var currency_system: CurrencySystem = null

var botany_station_pos: Vector2 = Vector2(100, 100)
var repair_station_pos: Vector2 = Vector2(300, 100)
var bed_pos: Vector2 = Vector2(200, 250)

func _ready() -> void:
	_load_room_data()
	_setup_stations()

func _load_room_data() -> void:
	var config = ConfigFile.new()
	if config.load("user://quarters.save") == OK:
		room_level = config.get_value("quarters", "level", 1)
		room_size = upgrade_sizes.get(room_level, Vector2(400, 300))

func _save_room_data() -> void:
	var config = ConfigFile.new()
	config.set_value("quarters", "level", room_level)
	config.save("user://quarters.save")

func _setup_stations() -> void:
	# Create botany station
	var botany_station = Area2D.new()
	botany_station.name = "BotanyStation"
	botany_station.position = botany_station_pos
	add_child(botany_station)
	
	var botany_sprite = Sprite2D.new()
	botany_sprite.text = "🌱"
	botany_station.add_child(botany_sprite)
	
	# Create repair station
	var repair_station = Area2D.new()
	repair_station.name = "RepairStation"
	repair_station.position = repair_station_pos
	add_child(repair_station)
	
	var repair_sprite = Sprite2D.new()
	repair_sprite.text = "🔧"
	repair_station.add_child(repair_sprite)
	
	# Create bed
	var bed = Area2D.new()
	bed.name = "Bed"
	bed.position = bed_pos
	add_child(bed)
	
	var bed_sprite = Sprite2D.new()
	bed_sprite.text = "🛏️"
	bed.add_child(bed_sprite)

func set_references(botany: BotanySkill, repair: ItemRepairSkill, currency: CurrencySystem) -> void:
	botany_skill = botany
	repair_skill = repair
	currency_system = currency

func upgrade_room() -> bool:
	if not currency_system:
		return false
	
	var next_level = room_level + 1
	if not upgrade_costs.has(next_level):
		return false
	
	var cost = upgrade_costs[next_level]
	
	if not currency_system.remove_uusd(cost):
		return false
	
	room_level = next_level
	room_size = upgrade_sizes.get(room_level, room_size)
	
	# Upgrade botany quarters space
	if botany_skill:
		var new_space = 100.0 + (room_level * 50.0)
		botany_skill.upgrade_quarters(new_space, cost)
	
	room_upgraded.emit(room_size)
	_save_room_data()
	
	return true

func get_upgrade_cost() -> float:
	var next_level = room_level + 1
	return upgrade_costs.get(next_level, 0.0)

func get_room_size() -> Vector2:
	return room_size

func get_room_level() -> int:
	return room_level

func can_upgrade() -> bool:
	if not currency_system:
		return false
	
	var next_level = room_level + 1
	if not upgrade_costs.has(next_level):
		return false
	
	var cost = upgrade_costs[next_level]
	return currency_system.get_uusd() >= cost

func get_botany_station_pos() -> Vector2:
	return botany_station_pos

func get_repair_station_pos() -> Vector2:
	return repair_station_pos

func get_bed_pos() -> Vector2:
	return bed_pos
