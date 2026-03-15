extends Camera2D

# Vertical Camera System - handles isometric-style 3D camera for multi-floor dungeons

class_name VerticalCameraSystem

const FLOOR_HEIGHT: float = 256.0
const ISOMETRIC_ANGLE: float = PI / 6.0
const DEPTH_SCALE: float = 0.5

var player_ref: Node2D = null
var vertical_system: VerticalLevelSystem = null
var gravity_system: GravitySystem = null

var camera_height_offset: float = 200.0
var camera_distance: float = 300.0
var follow_smoothing: float = 0.1

var current_floor: int = 0
var visible_floors: Array[int] = []

func _ready() -> void:
	zoom = Vector2(1.0, 1.0)
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0

func set_references(player: Node2D, v_system: VerticalLevelSystem, g_system: GravitySystem) -> void:
	player_ref = player
	vertical_system = v_system
	gravity_system = g_system

func _process(delta: float) -> void:
	if not player_ref or not vertical_system or not gravity_system:
		return
	
	_update_camera_position(delta)
	_update_visible_floors()

func _update_camera_position(delta: float) -> void:
	if not player_ref:
		return
	
	var player_pos = player_ref.global_position
	var player_height = gravity_system.get_current_height()
	
	var camera_target = player_pos
	
	var height_offset = (player_height / FLOOR_HEIGHT) * camera_height_offset
	camera_target.y -= height_offset
	
	global_position = global_position.lerp(camera_target, follow_smoothing)

func _update_visible_floors() -> void:
	if not vertical_system:
		return
	
	var current = vertical_system.get_current_floor()
	visible_floors = vertical_system.get_visible_floors(current, 2)

func get_visible_floors() -> Array[int]:
	return visible_floors

func get_depth_for_floor(floor: int) -> float:
	var current = vertical_system.get_current_floor() if vertical_system else 0
	var floor_diff = float(floor - current)
	return floor_diff * DEPTH_SCALE

func get_render_position(world_pos: Vector2, floor: int) -> Vector2:
	var depth = get_depth_for_floor(floor)
	var render_pos = world_pos
	render_pos.y -= depth * FLOOR_HEIGHT * 0.25
	return render_pos

func get_render_scale(floor: int) -> float:
	var depth = get_depth_for_floor(floor)
	var scale = 1.0 - (depth * 0.1)
	return maxf(scale, 0.5)

func get_render_modulate(floor: int) -> Color:
	var current = vertical_system.get_current_floor() if vertical_system else 0
	var floor_diff = abs(floor - current)
	
	var alpha = 1.0
	match floor_diff:
		0:
			alpha = 1.0
		1:
			alpha = 0.8
		2:
			alpha = 0.5
		_:
			alpha = 0.2
	
	return Color(1.0, 1.0, 1.0, alpha)

func is_floor_visible(floor: int) -> bool:
	return floor in visible_floors

func shake_camera(intensity: float, duration: float) -> void:
	var tween = create_tween()
	for i in range(int(duration * 60)):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		global_position += offset
		await get_tree().process_frame
	global_position = global_position.round()
