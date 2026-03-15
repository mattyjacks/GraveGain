extends Node

# Vertical Integration - integrates all vertical systems into the game

class_name VerticalIntegration

var game_ref: Node = null
var player_ref: Node2D = null

var vertical_dungeon: VerticalDungeonGenerator = null
var vertical_renderer: VerticalRenderer = null
var gravity_system: GravitySystem = null
var climbing_system: ClimbingSystem = null
var vertical_camera: VerticalCameraSystem = null

var current_floor: int = 0
var max_floors: int = 3

func _ready() -> void:
	pass

func initialize(game: Node, player: Node2D, max_f: int = 3) -> void:
	game_ref = game
	player_ref = player
	max_floors = max_f
	
	_setup_vertical_systems()
	_connect_signals()

func _setup_vertical_systems() -> void:
	# Create vertical dungeon generator
	vertical_dungeon = VerticalDungeonGenerator.new()
	vertical_dungeon.max_floors = max_floors
	vertical_dungeon.generate_vertical_dungeon()
	add_child(vertical_dungeon)
	
	# Create vertical renderer
	vertical_renderer = VerticalRenderer.new()
	vertical_renderer.set_dungeon(vertical_dungeon)
	game_ref.add_child(vertical_renderer)
	
	# Create gravity system
	gravity_system = GravitySystem.new()
	gravity_system.set_references(player_ref, vertical_dungeon)
	add_child(gravity_system)
	
	# Create climbing system
	climbing_system = ClimbingSystem.new()
	climbing_system.set_references(player_ref, vertical_dungeon)
	add_child(climbing_system)
	
	# Create vertical camera
	vertical_camera = VerticalCameraSystem.new()
	vertical_camera.set_references(player_ref, vertical_dungeon, gravity_system)
	game_ref.add_child(vertical_camera)

func _connect_signals() -> void:
	if gravity_system:
		gravity_system.floor_changed.connect(_on_floor_changed)
		gravity_system.landed.connect(_on_player_landed)
		gravity_system.jumped.connect(_on_player_jumped)
	
	if climbing_system:
		climbing_system.floor_transition.connect(_on_climb_floor_transition)
		climbing_system.climb_started.connect(_on_climb_started)
		climbing_system.climb_finished.connect(_on_climb_finished)

func update(delta: float) -> void:
	if not gravity_system or not climbing_system or not vertical_renderer:
		return
	
	# Update gravity
	gravity_system.update_gravity(delta)
	
	# Update climbing
	climbing_system.update_climb(delta)
	
	# Update visibility
	vertical_renderer.update_visible_floors(current_floor, 2)
	
	# Handle jumping input
	_handle_jump_input()
	
	# Handle climbing input
	_handle_climbing_input()

func _handle_jump_input() -> void:
	if not player_ref or not gravity_system:
		return
	
	if Input.is_action_just_pressed("jump"):
		if gravity_system.is_grounded:
			gravity_system.jump()

func _handle_climbing_input() -> void:
	if not player_ref or not climbing_system or not vertical_dungeon:
		return
	
	if climbing_system.is_climbing():
		# Handle climbing direction
		var climb_input = 0
		if Input.is_action_pressed("move_up"):
			climb_input = 1
		elif Input.is_action_pressed("move_down"):
			climb_input = -1
		
		if climb_input != 0:
			climbing_system.climb_direction = climb_input
		
		# Exit climbing
		if Input.is_action_just_pressed("interact"):
			climbing_system.stop_climb()
	else:
		# Check for nearby climbables
		var climbables = vertical_dungeon.get_climbables_on_floor(current_floor)
		for climbable in climbables:
			var dist = player_ref.global_position.distance_to(climbable["position"])
			if dist < 100.0:
				if Input.is_action_just_pressed("jump"):
					climbing_system.start_climb(climbable, 1)
					break

func _on_floor_changed(new_floor: int) -> void:
	current_floor = new_floor
	if game_ref.has_method("_on_player_floor_changed"):
		game_ref._on_player_floor_changed(new_floor)

func _on_player_landed(fall_distance: float) -> void:
	if fall_distance > 100.0:
		gravity_system.set_grounded(true)

func _on_player_jumped(velocity: float) -> void:
	pass

func _on_climb_floor_transition(from_floor: int, to_floor: int) -> void:
	current_floor = to_floor

func _on_climb_started(climb_type: String) -> void:
	pass

func _on_climb_finished() -> void:
	pass

func get_current_floor() -> int:
	return current_floor

func get_floor_z_position(floor: int) -> float:
	return vertical_dungeon.get_floor_z_position(floor)

func get_visible_floors() -> Array[int]:
	return vertical_renderer.get_visible_floors()

func is_climbing() -> bool:
	return climbing_system.is_climbing() if climbing_system else false

func can_jump() -> bool:
	return gravity_system.is_grounded if gravity_system else false
