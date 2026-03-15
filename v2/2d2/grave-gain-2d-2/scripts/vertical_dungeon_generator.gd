extends Node

# Vertical Dungeon Generator - creates multi-floor dungeons with stairs, ladders, and ramps
# Maintains 2D rendering while adding vertical navigation mechanics

class_name VerticalDungeonGenerator

const FLOOR_HEIGHT: float = 256.0
const FLOORS_PER_DUNGEON: int = 3

var floors: Array[Dictionary] = []
var current_floor: int = 0
var max_floors: int = FLOORS_PER_DUNGEON

func generate_vertical_dungeon(seed_val: int = 0) -> Array[Dictionary]:
	if seed_val > 0:
		seed(seed_val)
	
	floors.clear()
	
	for floor_num in range(max_floors):
		var floor_data = _generate_floor(floor_num)
		floors.append(floor_data)
	
	_connect_floors_with_climbables()
	return floors

func _generate_floor(floor_num: int) -> Dictionary:
	var floor = {
		"floor_number": floor_num,
		"z_position": floor_num * FLOOR_HEIGHT,
		"rooms": [],
		"climbables": [],
		"entities": [],
		"visibility_alpha": 1.0 if floor_num == 0 else 0.7,
	}
	
	var room_count = randi_range(3, 6)
	for i in range(room_count):
		var room = {
			"position": Vector2(randf_range(100, 900), randf_range(100, 900)),
			"size": Vector2(randf_range(200, 400), randf_range(200, 400)),
			"floor": floor_num,
			"enemies": [],
			"items": [],
			"lore": [],
		}
		floor["rooms"].append(room)
	
	return floor

func _connect_floors_with_climbables() -> void:
	for floor_num in range(max_floors - 1):
		var current_floor = floors[floor_num]
		var next_floor = floors[floor_num + 1]
		
		if current_floor["rooms"].is_empty() or next_floor["rooms"].is_empty():
			continue
		
		var current_room = current_floor["rooms"][0]
		var next_room = next_floor["rooms"][0]
		
		var climbable_pos = current_room["position"] + current_room["size"] / 2.0
		
		var climbable_type = ["stairs", "ladder", "ramp"].pick_random()
		var climbable = {
			"type": climbable_type,
			"position": climbable_pos,
			"start_floor": floor_num,
			"end_floor": floor_num + 1,
			"width": 64.0 if climbable_type == "ladder" else 96.0,
			"climb_speed": 120.0 if climbable_type == "stairs" else (100.0 if climbable_type == "ladder" else 150.0),
		}
		
		current_floor["climbables"].append(climbable)

func get_floor(floor_num: int) -> Dictionary:
	if floor_num >= 0 and floor_num < floors.size():
		return floors[floor_num]
	return {}

func get_climbables_on_floor(floor_num: int) -> Array:
	var floor = get_floor(floor_num)
	return floor.get("climbables", [])

func get_rooms_on_floor(floor_num: int) -> Array:
	var floor = get_floor(floor_num)
	return floor.get("rooms", [])

func get_floor_at_height(z: float) -> int:
	var floor_num = int(z / FLOOR_HEIGHT)
	return clampi(floor_num, 0, max_floors - 1)

func get_floor_z_position(floor_num: int) -> float:
	var floor = get_floor(floor_num)
	return floor.get("z_position", 0.0)

func is_valid_floor(floor_num: int) -> bool:
	return floor_num >= 0 and floor_num < max_floors

func can_climb_between_floors(from_floor: int, to_floor: int) -> bool:
	return abs(to_floor - from_floor) == 1

func get_visible_floors(current_floor: int, visibility_range: int = 2) -> Array[int]:
	var visible: Array[int] = []
	for i in range(max(0, current_floor - visibility_range), min(max_floors, current_floor + visibility_range + 1)):
		visible.append(i)
	return visible
