extends Node

# Gravity System - handles jumping, falling, and vertical movement in 3D levels

class_name GravitySystem

signal jumped(velocity: float)
signal landed(fall_distance: float)
signal floor_changed(new_floor: int)

const GRAVITY: float = 800.0
const JUMP_FORCE: float = 400.0
const MAX_FALL_SPEED: float = 600.0
const FLOOR_HEIGHT: float = 256.0

var vertical_velocity: float = 0.0
var is_grounded: bool = true
var current_floor: int = 0
var current_height: float = 0.0
var max_height_reached: float = 0.0

var player_ref: Node2D = null
var vertical_system: Node = null

func _ready() -> void:
	pass

func set_references(player: Node2D, v_system: Node) -> void:
	player_ref = player
	vertical_system = v_system
	current_floor = v_system.get_current_floor()
	current_height = v_system.get_floor_z_position(current_floor)

func update_gravity(delta: float) -> void:
	if not is_grounded:
		vertical_velocity = minf(vertical_velocity + GRAVITY * delta, MAX_FALL_SPEED)
	
	current_height += vertical_velocity * delta
	max_height_reached = maxf(max_height_reached, current_height)
	
	_check_floor_transition()

func jump(force: float = JUMP_FORCE) -> void:
	if is_grounded:
		vertical_velocity = -force
		is_grounded = false
		jumped.emit(force)

func apply_velocity(vel: float) -> void:
	vertical_velocity = vel

func set_grounded(grounded: bool) -> void:
	if grounded and not is_grounded:
		var fall_distance = max_height_reached - current_height
		landed.emit(fall_distance)
		max_height_reached = current_height
	
	is_grounded = grounded

func _check_floor_transition() -> void:
	if not vertical_system:
		return
	
	var new_floor = vertical_system.get_floor_at_height(current_height)
	if new_floor != current_floor:
		current_floor = new_floor
		floor_changed.emit(new_floor)
		vertical_system.set_current_floor(new_floor)

func get_current_height() -> float:
	return current_height

func set_current_height(height: float) -> void:
	current_height = height
	_check_floor_transition()

func get_vertical_velocity() -> float:
	return vertical_velocity

func is_falling() -> bool:
	return vertical_velocity > 0.0

func is_jumping() -> bool:
	return vertical_velocity < 0.0

func get_height_above_floor() -> float:
	var floor_z = vertical_system.get_floor_z_position(current_floor) if vertical_system else 0.0
	return current_height - floor_z

func can_land_on_floor(floor: int) -> bool:
	if not vertical_system:
		return false
	return floor >= 0 and floor < vertical_system.max_floors

func reset_to_floor(floor: int) -> void:
	current_floor = floor
	if vertical_system:
		current_height = vertical_system.get_floor_z_position(floor)
	vertical_velocity = 0.0
	is_grounded = true
	max_height_reached = current_height
