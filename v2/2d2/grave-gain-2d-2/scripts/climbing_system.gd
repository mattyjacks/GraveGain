extends Node

# Climbing System - handles player climbing mechanics for stairs, ladders, ramps, elevators

class_name ClimbingSystem

signal climb_started(climb_type: String)
signal climb_finished()
signal floor_transition(from_floor: int, to_floor: int)

enum ClimbState { IDLE, CLIMBING, TRANSITIONING }

var climb_state: ClimbState = ClimbState.IDLE
var current_climbable: Object = null
var climb_progress: float = 0.0
var climb_direction: int = 1
var climb_speed: float = 100.0

var player_ref: Node2D = null
var vertical_system: Node = null

func _ready() -> void:
	pass

func set_references(player: Node2D, v_system: Node) -> void:
	player_ref = player
	vertical_system = v_system

func start_climb(climbable: Object, direction: int = 1) -> bool:
	if climb_state != ClimbState.IDLE or not climbable:
		return false
	
	current_climbable = climbable
	climb_direction = direction
	climb_state = ClimbState.CLIMBING
	climb_progress = 0.0
	climb_speed = climbable.climb_speed
	
	var climb_type = climbable.type
	climb_started.emit(climb_type)
	return true

func stop_climb() -> void:
	if climb_state == ClimbState.CLIMBING:
		climb_state = ClimbState.IDLE
		current_climbable = null
		climb_finished.emit()

func update_climb(delta: float) -> void:
	if climb_state != ClimbState.CLIMBING or not current_climbable or not player_ref:
		return
	
	var floor_height = VerticalLevelSystem.FLOOR_HEIGHT
	var total_climb_distance = floor_height
	
	climb_progress += climb_speed * delta * climb_direction
	
	var start_floor = current_climbable.start_floor
	var end_floor = current_climbable.end_floor
	
	if climb_direction > 0:
		if climb_progress >= total_climb_distance:
			climb_progress = total_climb_distance
			_finish_climb(end_floor)
	else:
		if climb_progress <= 0:
			climb_progress = 0
			_finish_climb(start_floor)

func _finish_climb(destination_floor: int) -> void:
	if vertical_system:
		var old_floor = vertical_system.get_current_floor()
		vertical_system.set_current_floor(destination_floor)
		floor_transition.emit(old_floor, destination_floor)
	
	climb_state = ClimbState.IDLE
	current_climbable = null
	climb_finished.emit()

func get_climb_progress() -> float:
	return climb_progress

func is_climbing() -> bool:
	return climb_state == ClimbState.CLIMBING

func get_climb_position() -> Vector2:
	if not current_climbable or not player_ref:
		return Vector2.ZERO
	
	var base_pos = current_climbable.position
	var progress_ratio = climb_progress / VerticalLevelSystem.FLOOR_HEIGHT
	
	match current_climbable.type:
		"stairs":
			var climb_dir = (current_climbable.position - player_ref.global_position).normalized()
			return base_pos + climb_dir * (progress_ratio * VerticalLevelSystem.FLOOR_HEIGHT)
		"ladder":
			return base_pos + Vector2(0, progress_ratio * VerticalLevelSystem.FLOOR_HEIGHT * climb_direction)
		"ramp":
			var climb_dir = (current_climbable.position - player_ref.global_position).normalized()
			return base_pos + climb_dir * (progress_ratio * VerticalLevelSystem.FLOOR_HEIGHT)
		"elevator":
			return base_pos + Vector2(0, progress_ratio * VerticalLevelSystem.FLOOR_HEIGHT * climb_direction)
	
	return base_pos
