extends Node2D

# Controls transitions between top-down and sidescroller modes
# Manages the sidescroller scene, camera, and player mode switching

const SidescrollerRoom = preload("res://scripts/sidescroller/sidescroller_room.gd")
const SidescrollerRendererScript = preload("res://scripts/sidescroller/sidescroller_renderer.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ItemScript = preload("res://scripts/item.gd")

signal entered_building(building_data: Dictionary)
signal exited_building()

enum Mode { TOP_DOWN, SIDESCROLLER }

var current_mode: Mode = Mode.TOP_DOWN
var is_transitioning: bool = false
var transition_timer: float = 0.0
const TRANSITION_DURATION := 0.6

var current_room: RefCounted = null
var renderer: Node2D = null
var ss_entities: Node2D = null
var ss_items: Node2D = null
var ss_enemies: Array[CharacterBody2D] = []

# Building data for the current sidescroller session
var current_building: Dictionary = {}

# References set by game.gd
var player_ref: CharacterBody2D = null
var camera_ref: Camera2D = null
var game_ref: Node2D = null
var top_down_nodes: Array[Node] = []

# Player state backup for restoring after exit
var player_saved_position: Vector2 = Vector2.ZERO
var player_saved_collision_mask: int = 0

# Fade overlay for transitions
var fade_overlay: ColorRect = null
var fade_canvas: CanvasLayer = null

func _ready() -> void:
	_create_fade_overlay()

func _create_fade_overlay() -> void:
	fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 150
	add_child(fade_canvas)

	fade_overlay = ColorRect.new()
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_canvas.add_child(fade_overlay)

func _process(delta: float) -> void:
	if is_transitioning:
		transition_timer -= delta
		var t := 1.0 - (transition_timer / TRANSITION_DURATION)

		if t < 0.5:
			# Fade to black
			fade_overlay.color.a = t * 2.0
		else:
			# Fade from black
			fade_overlay.color.a = (1.0 - t) * 2.0

		if transition_timer <= 0:
			is_transitioning = false
			fade_overlay.color.a = 0.0

	if current_mode == Mode.SIDESCROLLER and renderer:
		renderer.update_torch_flicker(delta)

func enter_building(building_data: Dictionary) -> void:
	if is_transitioning or current_mode == Mode.SIDESCROLLER:
		return

	current_building = building_data
	is_transitioning = true
	transition_timer = TRANSITION_DURATION

	# Start fade, then switch at midpoint
	get_tree().create_timer(TRANSITION_DURATION * 0.5).timeout.connect(_do_enter_building)

func _do_enter_building() -> void:
	# Save player state
	player_saved_position = player_ref.global_position
	player_saved_collision_mask = player_ref.collision_mask

	# Generate sidescroller room
	var building_type: int = current_building.get("building_type", SidescrollerRoom.BuildingType.HOUSE)
	current_room = SidescrollerRoom.new()
	current_room.generate(building_type, current_building.get("seed", -1))

	# Hide top-down world
	for node in top_down_nodes:
		if is_instance_valid(node):
			node.visible = false

	# Create sidescroller scene
	_create_ss_scene()

	# Move player to entry position
	player_ref.global_position = current_room.entry_pos
	player_ref.collision_mask = 4  # Only collide with walls

	# Switch player to sidescroller mode
	if player_ref.has_method("enter_sidescroller_mode"):
		player_ref.enter_sidescroller_mode()

	# Adjust camera
	camera_ref.zoom = Vector2(2.0, 2.0)

	current_mode = Mode.SIDESCROLLER
	entered_building.emit(current_building)

func exit_building() -> void:
	if is_transitioning or current_mode == Mode.TOP_DOWN:
		return

	is_transitioning = true
	transition_timer = TRANSITION_DURATION

	get_tree().create_timer(TRANSITION_DURATION * 0.5).timeout.connect(_do_exit_building)

func _do_exit_building() -> void:
	# Clean up sidescroller scene
	_cleanup_ss_scene()

	# Show top-down world
	for node in top_down_nodes:
		if is_instance_valid(node):
			node.visible = true

	# Restore player
	player_ref.global_position = player_saved_position
	player_ref.collision_mask = player_saved_collision_mask

	if player_ref.has_method("exit_sidescroller_mode"):
		player_ref.exit_sidescroller_mode()

	# Restore camera
	camera_ref.zoom = Vector2(1.5, 1.5)

	current_mode = Mode.TOP_DOWN
	current_room = null
	current_building = {}
	exited_building.emit()

func _create_ss_scene() -> void:
	# Renderer
	renderer = Node2D.new()
	renderer.set_script(SidescrollerRendererScript)
	renderer.z_index = 0
	add_child(renderer)
	renderer.set_room(current_room)

	# Entities container
	ss_entities = Node2D.new()
	ss_entities.name = "SSEntities"
	ss_entities.y_sort_enabled = false
	ss_entities.z_index = 10
	add_child(ss_entities)

	# Items container
	ss_items = Node2D.new()
	ss_items.name = "SSItems"
	ss_items.z_index = 5
	add_child(ss_items)

	# Spawn enemies
	_spawn_ss_enemies()

	# Spawn items
	_spawn_ss_items()

func _cleanup_ss_scene() -> void:
	for enemy in ss_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	ss_enemies.clear()

	if is_instance_valid(renderer):
		renderer.clear_room()
		renderer.queue_free()
		renderer = null

	if is_instance_valid(ss_entities):
		ss_entities.queue_free()
		ss_entities = null

	if is_instance_valid(ss_items):
		ss_items.queue_free()
		ss_items = null

func _spawn_ss_enemies() -> void:
	if not current_room:
		return

	var enemy_types := [
		GameData.EnemyType.GOBLIN_SKELETON,
		GameData.EnemyType.GOBLIN_ZED,
		GameData.EnemyType.ELVEN_SKELETON,
		GameData.EnemyType.SMALL_ORC_ZED,
	]

	# Harder enemies for harder buildings
	if current_room.building_type == SidescrollerRoom.BuildingType.FORTRESS:
		enemy_types.append(GameData.EnemyType.MEDIUM_ORC_ZED)
		enemy_types.append(GameData.EnemyType.DWARVEN_ZED)
	elif current_room.building_type == SidescrollerRoom.BuildingType.CASTLE:
		enemy_types.append(GameData.EnemyType.HUGE_ORC_ZED)
		enemy_types.append(GameData.EnemyType.HUMAN_ZED)
		enemy_types.append(GameData.EnemyType.ELVEN_NECROMANCER)

	for spawn_pos in current_room.enemy_spawns:
		var enemy := CharacterBody2D.new()
		enemy.set_script(EnemyScript)
		var etype: int = enemy_types[randi() % enemy_types.size()]
		enemy.global_position = spawn_pos
		ss_entities.add_child(enemy)
		enemy.setup(etype)

		# Enable sidescroller mode on enemy
		if enemy.has_method("enter_sidescroller_mode"):
			enemy.enter_sidescroller_mode()

		ss_enemies.append(enemy)

func _spawn_ss_items() -> void:
	if not current_room:
		return

	var item_types := ["gold_pile", "health_potion", "mana_potion"]
	if current_room.building_type == SidescrollerRoom.BuildingType.CASTLE:
		item_types.append("artifact")
		item_types.append("large_gold")

	for spawn_pos in current_room.item_spawns:
		var item := Area2D.new()
		item.set_script(ItemScript)
		item.global_position = spawn_pos
		var item_type: String = item_types[randi() % item_types.size()]
		ss_items.add_child(item)
		item.setup_item(item_type)

func is_sidescroller_mode() -> bool:
	return current_mode == Mode.SIDESCROLLER

func check_exit_proximity(player_pos: Vector2) -> bool:
	if not current_room:
		return false
	return player_pos.distance_to(current_room.exit_pos) < 40.0

func check_entry_door_proximity(player_pos: Vector2) -> bool:
	if not current_room:
		return false
	return player_pos.distance_to(current_room.entry_pos) < 40.0
