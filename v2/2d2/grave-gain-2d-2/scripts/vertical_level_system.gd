extends Node

# Vertical Level System - manages multiple floors, climbing, and gravity
# Uses Z-axis for height (0 = ground floor, positive = higher floors)

class_name VerticalLevelSystem

signal floor_changed(new_floor: int, old_floor: int)
signal player_climbing(climbing: bool, climb_type: String)

const FLOOR_HEIGHT: float = 256.0
const STAIRS_HEIGHT: float = 128.0
const LADDER_HEIGHT: float = 256.0
const RAMP_ANGLE: float = PI / 6.0

var floors: Array[Dictionary] = []
var current_floor: int = 0
var max_floors: int = 5

class Floor:
	var floor_number: int = 0
	var rooms: Array[Dictionary] = []
	var z_position: float = 0.0
	var entities: Array[Node2D] = []
	var visibility_range: float = 512.0
	
	func _init(floor_num: int) -> void:
		floor_number = floor_num
		z_position = floor_num * FLOOR_HEIGHT

class ClimbableObject:
	var type: String = "stairs"
	var position: Vector2 = Vector2.ZERO
	var start_floor: int = 0
	var end_floor: int = 1
	var width: float = 64.0
	var climb_speed: float = 100.0
	var direction: Vector2 = Vector2.ZERO
	
	func _init(p_type: String, p_pos: Vector2, p_start: int, p_end: int) -> void:
		type = p_type
		position = p_pos
		start_floor = p_start
		end_floor = p_end
		
		match type:
			"stairs":
				climb_speed = 120.0
				width = 64.0
			"ladder":
				climb_speed = 100.0
				width = 32.0
			"ramp":
				climb_speed = 150.0
				width = 96.0
			"elevator":
				climb_speed = 200.0
				width = 80.0

func _ready() -> void:
	_initialize_floors()

func _initialize_floors() -> void:
	floors.clear()
	for i in range(max_floors):
		var floor = Floor.new(i)
		floors.append(floor)

func get_floor_z_position(floor: int) -> float:
	if floor >= 0 and floor < floors.size():
		return floors[floor].z_position
	return 0.0

func get_current_floor() -> int:
	return current_floor

func set_current_floor(floor: int) -> void:
	if floor >= 0 and floor < floors.size() and floor != current_floor:
		var old_floor = current_floor
		current_floor = floor
		floor_changed.emit(floor, old_floor)

func get_floor_at_height(z: float) -> int:
	var floor_num = int(z / FLOOR_HEIGHT)
	return clampi(floor_num, 0, max_floors - 1)

func add_climbable(climbable: ClimbableObject) -> void:
	if climbable.start_floor >= 0 and climbable.start_floor < floors.size():
		if not floors[climbable.start_floor].rooms.is_empty():
			floors[climbable.start_floor].rooms[0]["climbables"] = floors[climbable.start_floor].rooms[0].get("climbables", [])
			floors[climbable.start_floor].rooms[0]["climbables"].append(climbable)

func get_climbables_near(position: Vector2, floor: int, range: float = 100.0) -> Array[ClimbableObject]:
	var result: Array[ClimbableObject] = []
	if floor >= 0 and floor < floors.size():
		for room in floors[floor].rooms:
			for climbable in room.get("climbables", []):
				if position.distance_to(climbable.position) < range:
					result.append(climbable)
	return result

func is_on_climbable(position: Vector2, floor: int, climbable: ClimbableObject) -> bool:
	var dist = position.distance_to(climbable.position)
	return dist < climbable.width / 2.0

func can_climb_to_floor(from_floor: int, to_floor: int) -> bool:
	return abs(to_floor - from_floor) == 1

func get_visible_floors(current_floor: int, visibility_distance: int = 2) -> Array[int]:
	var visible: Array[int] = []
	for i in range(max(0, current_floor - visibility_distance), min(max_floors, current_floor + visibility_distance + 1)):
		visible.append(i)
	return visible
