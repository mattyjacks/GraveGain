extends Node2D

const MapGenerator = preload("res://scripts/map_generator.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const ItemScript = preload("res://scripts/item.gd")
const HudScript = preload("res://scripts/hud.gd")
const LorePickupScript = preload("res://scripts/lore/lore_pickup.gd")
const LoreReaderScript = preload("res://scripts/lore/lore_reader_ui.gd")
const LoreCollectionScript = preload("res://scripts/lore/lore_collection_ui.gd")
const TtsManagerScript = preload("res://scripts/lore/tts_manager.gd")
const TouchControlsScript = preload("res://scripts/touch_controls.gd")
const VFXManagerScript = preload("res://scripts/vfx_manager.gd")
const SidescrollerControllerScript = preload("res://scripts/sidescroller/sidescroller_controller.gd")
const MinigameManagerScript = preload("res://scripts/minigames/minigame_manager.gd")
const StarshipMapScript = preload("res://scripts/starship/starship_map.gd")
const StarshipRendererScript = preload("res://scripts/starship/starship_renderer.gd")
const StarshipNpcScript = preload("res://scripts/starship/starship_npc.gd")
const StarshipDialogueScript = preload("res://scripts/starship/starship_dialogue.gd")
const PauseMenuScript = preload("res://scripts/systems/pause_menu.gd")
const InventoryManagerScript = preload("res://scripts/systems/inventory_manager.gd")
const InventoryUIScript = preload("res://scripts/systems/inventory_ui.gd")
const VerticalDungeonScript = preload("res://scripts/vertical_dungeon_generator.gd")
const VerticalRendererScript = preload("res://scripts/vertical_renderer.gd")
const GravitySystemScript = preload("res://scripts/gravity_system.gd")
const ClimbingSystemScript = preload("res://scripts/climbing_system.gd")
const VerticalCameraScript = preload("res://scripts/vertical_camera_system.gd")
const VerticalIntegrationScript = preload("res://scripts/vertical_integration.gd")
const DialogueManagerScript = preload("res://scripts/dialogue/dialogue_manager.gd")
const CombatDialogueScript = preload("res://scripts/dialogue/combat_dialogue_system.gd")
const ExplorationDialogueScript = preload("res://scripts/dialogue/exploration_dialogue_system.gd")
const EnemyConversationScript = preload("res://scripts/dialogue/enemy_conversation_system.gd")
const CurrencySystemScript = preload("res://scripts/starship/currency_system.gd")
const ItemRepairSkillScript = preload("res://scripts/starship/item_repair_skill.gd")
const BotanySkillScript = preload("res://scripts/starship/botany_skill.gd")
const PersonalQuartersScript = preload("res://scripts/starship/personal_quarters.gd")
const QuartersUIScript = preload("res://scripts/starship/quarters_ui.gd")
const QualityOfLifeScript = preload("res://scripts/improvements/quality_of_life.gd")
const AdvancedEnemyAIScript = preload("res://scripts/improvements/advanced_enemy_ai.gd")
const VisualPolishScript = preload("res://scripts/improvements/visual_polish.gd")
const PerformanceOptimizationScript = preload("res://scripts/improvements/performance_optimization.gd")
const Improvements1201_1300Script = preload("res://scripts/improvements/improvements_1201_1300.gd")

var map_gen: RefCounted
var player: CharacterBody2D
var camera: Camera2D
var canvas_modulate: CanvasModulate
var entities_node: Node2D
var projectiles_node: Node2D
var items_node: Node2D
var torches_node: Node2D
var map_renderer: Node2D
var hud: CanvasLayer
var safespace_visual: Node2D
var lore_node: Node2D
var lore_reader: CanvasLayer
var lore_collection: CanvasLayer
var tts_manager: Node
var touch_controls: CanvasLayer
var vfx: Node2D
var ss_controller: Node2D
var buildings_node: Node2D
var building_entry_check_timer: float = 0.0
var minigame_manager: Node = null
var game_corners_node: Node2D = null

# Starship systems
var starship_map: RefCounted = null

# Vertical dungeon systems (2.5D multi-floor exploration)
var vertical_dungeon: VerticalDungeonGenerator = null
var vertical_renderer: VerticalRenderer = null
var gravity_system: GravitySystem = null
var climbing_system: ClimbingSystem = null
var current_floor: int = 0
var max_floors: int = 3

# Dialogue systems
var dialogue_manager: DialogueManager = null
var combat_dialogue: CombatDialogueSystem = null
var exploration_dialogue: ExplorationDialogueSystem = null
var enemy_conversation: EnemyConversationSystem = null

# Starship skill systems
var currency_system: CurrencySystem = null
var repair_skill: ItemRepairSkill = null
var botany_skill: BotanySkill = null
var personal_quarters: PersonalQuarters = null
var quarters_ui: QuartersUI = null

# Improvement systems
var quality_of_life: QualityOfLifeImprovements = null
var advanced_enemy_ai: AdvancedEnemyAI = null
var visual_polish: VisualPolish = null
var performance_optimization: PerformanceOptimization = null

var starship_renderer: Node2D = null
var starship_npcs: Array[Area2D] = []
var starship_dialogue: CanvasLayer = null
var is_on_starship: bool = true
var starship_npc_node: Node2D = null
var starship_interactables_node: Node2D = null

# Pause menu and inventory
var pause_menu: CanvasLayer = null
var inventory_mgr: Node = null
var inventory_ui: CanvasLayer = null

# Dev mode
var dev_mode_enabled: bool = false
var text_based_graphics: bool = false

var enemies: Array[CharacterBody2D] = []
var active_lights: Array[PointLight2D] = []

var mission_time: float = 0.0
var total_kills: int = 0
var is_mission_active: bool = true
var is_paused: bool = false

var minimap_update_timer: float = 0.0
var enemy_retarget_timer: float = 0.0
var spawn_check_timer: float = 0.0
var difficulty_mult: float = 1.0

# Improvement #1131: Low health warning
var low_health_overlay: ColorRect = null
var low_health_pulse: float = 0.0

# Improvement #1157: Item pickup magnet
var item_magnet_range: float = 100.0

# Enemy collision avoidance
var enemy_separation_range: float = 40.0
var enemy_separation_force: float = 150.0

# Persistent gore system
var max_gore_decals: int = 200
var gore_decals: Array[Dictionary] = []

var wall_occluders: Array[Node2D] = []

# Batch 4: Combat improvements
var destructibles_node: Node2D
var traps_node: Node2D
var chests_node: Node2D
var particles_node: Node2D
var screen_shake_timer: float = 0.0
var screen_shake_intensity: float = 0.0
var current_room_index: int = -1
var destructibles: Array[Node2D] = []

# Camera juice
var camera_punch: Vector2 = Vector2.ZERO
var camera_punch_decay: float = 12.0
var camera_target_zoom: Vector2 = Vector2(1.5, 1.5)
var camera_zoom_speed: float = 4.0
var hit_pause_timer: float = 0.0

# Improvement #71: Ambient dust timer
var ambient_dust_timer: float = 0.0

# Improvement #72: Camera lead direction
var camera_lead_amount: float = 30.0

# Improvement #73: Input buffer
var input_buffer_attack: float = 0.0
var input_buffer_dodge: float = 0.0
var input_buffer_window: float = 0.15

# Improvement #74: Quick restart
var can_quick_restart: bool = false

func _ready() -> void:
	if not GameData.point_light_texture:
		GameData.create_light_textures()

	GameSystems.reset_mission()
	
	# Check for dev mode
	dev_mode_enabled = GameSystems.get_setting("dev_mode") == true
	text_based_graphics = GameSystems.get_setting("text_based_graphics") == true
	
	# Emoji fonts are initialized by EmojiManager autoload (PNG or font-based)

	# Setup pause menu and inventory (always available)
	_setup_pause_menu()
	_setup_inventory()

	if dev_mode_enabled:
		# Dev mode: skip starship, go directly to dungeon
		_setup_dungeon_directly()
	else:
		# Normal mode: start on the starship
		_setup_starship()
		_spawn_player_on_starship()
	
	_setup_hud()
	_setup_lore_ui()

	_connect_game_signals()
	_setup_touch_controls()
	_setup_low_health_overlay()
	_setup_dialogue_systems()
	
	if not dev_mode_enabled:
		_setup_starship_skills()
	
	_setup_improvement_systems()

	if dev_mode_enabled:
		GameSystems.show_tutorial("dev", "[DEV MODE] Text-based graphics enabled. Direct dungeon entry. Press ESC to quit.", 5.0)
	else:
		GameSystems.show_tutorial("starship", "Explore the ship. Talk to crew with [E]. Head to the Hangar to deploy. Visit your quarters to earn $UUSD!", 8.0)

	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _generate_map() -> void:
	map_gen = MapGenerator.new()
	map_gen.generate()

func _build_scene_tree() -> void:
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.08, 0.07, 0.1)
	add_child(canvas_modulate)

	map_renderer = Node2D.new()
	map_renderer.name = "MapRenderer"
	map_renderer.z_index = 0
	map_renderer.set_script(preload("res://scripts/map_renderer.gd"))
	add_child(map_renderer)
	map_renderer.set_map_data(map_gen)

	entities_node = Node2D.new()
	entities_node.name = "Entities"
	entities_node.y_sort_enabled = true
	entities_node.z_index = 10
	add_child(entities_node)

	projectiles_node = Node2D.new()
	projectiles_node.name = "Projectiles"
	projectiles_node.z_index = 15
	add_child(projectiles_node)

	items_node = Node2D.new()
	items_node.name = "Items"
	items_node.y_sort_enabled = true
	items_node.z_index = 5
	add_child(items_node)

	torches_node = Node2D.new()
	torches_node.name = "Torches"
	torches_node.z_index = 8
	add_child(torches_node)

	lore_node = Node2D.new()
	lore_node.name = "Lore"
	lore_node.y_sort_enabled = true
	lore_node.z_index = 6
	add_child(lore_node)

	destructibles_node = Node2D.new()
	destructibles_node.name = "Destructibles"
	destructibles_node.y_sort_enabled = true
	destructibles_node.z_index = 7
	add_child(destructibles_node)

	traps_node = Node2D.new()
	traps_node.name = "Traps"
	traps_node.z_index = 3
	add_child(traps_node)

	chests_node = Node2D.new()
	chests_node.name = "Chests"
	chests_node.y_sort_enabled = true
	chests_node.z_index = 6
	add_child(chests_node)

	particles_node = Node2D.new()
	particles_node.name = "Particles"
	particles_node.z_index = 2
	add_child(particles_node)

	vfx = Node2D.new()
	vfx.set_script(VFXManagerScript)
	vfx.add_to_group("vfx")
	vfx.z_index = 12
	vfx.set("game_ref", self)
	add_child(vfx)

	camera = Camera2D.new()
	camera.name = "MainCamera"
	var cam_zoom: float = GameSystems.get_setting("camera_zoom")
	camera.zoom = Vector2(cam_zoom, cam_zoom)
	camera_target_zoom = camera.zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = GameSystems.get_setting("camera_smoothing")
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.15
	camera.drag_right_margin = 0.15
	camera.drag_top_margin = 0.15
	camera.drag_bottom_margin = 0.15
	add_child(camera)

func _setup_dungeon_directly() -> void:
	is_on_starship = false
	_generate_map()
	_build_scene_tree()
	_spawn_player()
	_place_torches()
	_place_items()
	_place_lore_pickups()
	_place_safespace()
	_place_destructibles()
	_place_traps()
	_place_chests()
	_place_fountains()
	_place_altars()
	_place_decorations()
	_place_dead_end_treasures()
	_place_buildings()
	_place_game_corners()

func _get_text_representation(emoji: String) -> String:
	if not text_based_graphics:
		return emoji
	
	var text_map := {
		"\U0001F525": "[F]",
		"\U0001F308": "[R]",
		"\U0001F4E6": "[C]",
		"\U0001F48E": "[G]",
		"\U0001F3C6": "[T]",
		"\U0001F451": "[L]",
		"\u2728": "[*]",
		"\u2694\uFE0F": "[S]",
		"\U0001F469\u200D\U0001F680": "[H]",
		"\U0001F9DD\u200D\u2640\uFE0F": "[E]",
		"\u26CF\uFE0F": "[D]",
		"\U0001F9B9": "[O]",
		"\U0001F480": "[X]",
		"\u2620\uFE0F": "[!]",
		"\U0001F4A2": "[*]",
		"\U0001F4DA": "[B]",
		"\u2699\uFE0F": "[?]",
		"\u26B0\uFE0F": "[#]",
	}
	
	return text_map.get(emoji, emoji)

func _create_emoji_node(emoji_text: String, font_size: int, node_size: Vector2, pos: Vector2) -> Control:
	# Try PNG texture first
	if not text_based_graphics and SvgEmojiRenderer.is_svg_emoji_available():
		var texture = SvgEmojiRenderer.load_emoji_texture(emoji_text, font_size)
		if texture:
			var rect = TextureRect.new()
			rect.texture = texture
			rect.custom_minimum_size = node_size
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.position = pos
			return rect
	# Fallback to label
	var lbl = Label.new()
	lbl.text = emoji_text if not text_based_graphics else _get_text_representation(emoji_text)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.size = node_size
	var ls := LabelSettings.new()
	if GameData.emoji_font and not text_based_graphics:
		ls.font = GameData.emoji_font
	ls.font_size = font_size
	lbl.label_settings = ls
	return lbl

func _create_emoji_node_large(emoji_text: String, font_size: int, node_size: Vector2, pos: Vector2) -> Control:
	# Try PNG texture first
	if not text_based_graphics and SvgEmojiRenderer.is_svg_emoji_available():
		var texture = SvgEmojiRenderer.load_emoji_texture(emoji_text, font_size)
		if texture:
			var rect = TextureRect.new()
			rect.texture = texture
			rect.custom_minimum_size = node_size
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.position = pos
			return rect
	# Fallback to label
	var lbl = Label.new()
	lbl.text = emoji_text if not text_based_graphics else _get_text_representation(emoji_text)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.size = node_size
	var ls := LabelSettings.new()
	if GameData.emoji_font_large and not text_based_graphics:
		ls.font = GameData.emoji_font_large
	ls.font_size = font_size
	lbl.label_settings = ls
	return lbl

func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.race = GameData.selected_race
	player.player_class = GameData.selected_class
	player.global_position = map_gen.spawn_position
	player.add_to_group("players")
	entities_node.add_child(player)

	player.player_attacked.connect(_on_player_attack)
	player.hp_changed.connect(_on_hp_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.shields_changed.connect(_on_shields_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.rage_changed.connect(_on_rage_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.gold_changed.connect(_on_gold_changed)
	player.slot_changed.connect(_on_slot_changed)
	player.player_died.connect(_on_player_died)
	player.screen_shake.connect(_on_screen_shake_request)
	player.damage_direction.connect(_on_damage_direction)

	camera.global_position = player.global_position

func _place_torches() -> void:
	for torch_pos in map_gen.torch_positions:
		var torch_node := Node2D.new()
		torch_node.global_position = torch_pos
		torch_node.z_index = 8

		var torch_emoji = _create_emoji_node("\U0001F525", 16, Vector2(20, 20), Vector2(-10, -14))
		torch_node.add_child(torch_emoji)

		var light := PointLight2D.new()
		light.texture = GameData.point_light_texture
		light.texture_scale = 3.0 + randf_range(-0.3, 0.3)
		light.energy = 0.85 + randf_range(-0.1, 0.1)
		# Warm color variation per torch
		var hue_shift := randf_range(-0.03, 0.03)
		light.color = Color(1.0 + hue_shift, 0.65 + hue_shift * 2.0, 0.3 + hue_shift)
		light.shadow_enabled = GameSystems.get_setting("shadows_enabled")
		torch_node.add_child(light)
		active_lights.append(light)

		torches_node.add_child(torch_node)

func _place_items() -> void:
	for item_info in map_gen.item_positions:
		_spawn_item(item_info["pos"], item_info["type"])

	for food_info in map_gen.food_positions:
		_spawn_food(food_info["pos"], food_info["type"])

func _spawn_item(pos: Vector2, item_type: String) -> void:
	var item := Area2D.new()
	item.set_script(ItemScript)
	item.global_position = pos
	item.setup_item(item_type)
	items_node.add_child(item)

func _spawn_food(pos: Vector2, food_type: String) -> void:
	var food := Area2D.new()
	food.set_script(ItemScript)
	food.global_position = pos
	food.setup_item(food_type)
	items_node.add_child(food)

func _place_safespace() -> void:
	if map_gen.safespace_position == Vector2.ZERO:
		return

	safespace_visual = Node2D.new()
	safespace_visual.global_position = map_gen.safespace_position
	safespace_visual.z_index = 3

	var rainbow_label := Label.new()
	rainbow_label.text = "\U0001F308"
	rainbow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rainbow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rainbow_label.position = Vector2(-32, -32)
	rainbow_label.size = Vector2(64, 64)
	var rs := LabelSettings.new()
	if GameData.emoji_font:
		rs.font = GameData.emoji_font
	rs.font_size = 48
	rainbow_label.label_settings = rs
	safespace_visual.add_child(rainbow_label)

	var ss_light := PointLight2D.new()
	ss_light.texture = GameData.point_light_texture
	ss_light.texture_scale = 4.0
	ss_light.energy = 1.0
	ss_light.color = Color(0.4, 1.0, 0.6)
	ss_light.shadow_enabled = false
	safespace_visual.add_child(ss_light)
	active_lights.append(ss_light)

	add_child(safespace_visual)

func _setup_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(HudScript)
	add_child(hud)

func _process(delta: float) -> void:
	if not is_mission_active:
		return
	if not is_instance_valid(player):
		return

	# Starship mode - simplified update
	if is_on_starship:
		camera.global_position = player.global_position
		camera.zoom = camera.zoom.lerp(camera_target_zoom, camera_zoom_speed * delta)
		_update_starship_interactable_prompts()
		_update_hud(delta)
		return

	mission_time += delta
	difficulty_mult = GameData.get_difficulty_multiplier(mission_time)

	# Hit pause (freeze frame on big hits)
	if hit_pause_timer > 0:
		hit_pause_timer -= delta
		Engine.time_scale = 0.05
		if hit_pause_timer <= 0:
			Engine.time_scale = 1.0

	_apply_screen_shake(delta)
	# Smooth camera follow with punch offset
	camera_punch = camera_punch.lerp(Vector2.ZERO, camera_punch_decay * delta)
	# Improvement #72: Camera lead - offset camera in movement direction
	var cam_lead := Vector2.ZERO
	if player.velocity.length() > 30.0 and GameSystems.get_setting("camera_lead"):
		cam_lead = player.velocity.normalized() * camera_lead_amount
	camera.global_position = player.global_position + camera_punch + cam_lead
	# Smooth zoom transitions
	camera.zoom = camera.zoom.lerp(camera_target_zoom, camera_zoom_speed * delta)

	# Improvement #71: Ambient dust near player
	ambient_dust_timer -= delta
	if ambient_dust_timer <= 0 and vfx:
		ambient_dust_timer = 2.0
		vfx.spawn_ambient_dust(player.global_position, Vector2(400, 400))

	# Improvement #73: Input buffer
	if input_buffer_attack > 0:
		input_buffer_attack -= delta
	if input_buffer_dodge > 0:
		input_buffer_dodge -= delta

	# Skip top-down updates while in sidescroller mode
	if ss_controller and ss_controller.is_sidescroller_mode():
		_check_ss_exit()
		_update_hud(delta)
		GameSystems.track("total_distance", player.velocity.length() * delta / 64.0)
		return

	_update_enemies(delta)
	_check_room_triggers()
	_check_safespace()
	_check_player_room()
	_check_trap_damage(delta)
	_check_building_entry(delta)
	_check_fountain_healing(delta)
	_check_corridor_ambushes()
	_check_hazard_zones(delta)
	_update_hud(delta)
	_update_torch_flicker(delta)
	_update_item_magnet(delta)
	_update_low_health_warning(delta)
	_update_gore_decals(delta)
	
	# Update vertical dungeon systems when in dungeon
	if not is_on_starship:
		_update_vertical_dungeon(delta)
	
	# Update dialogue systems
	if dialogue_manager and exploration_dialogue and not is_on_starship:
		exploration_dialogue.start_exploration()
	
	# Update enemy conversations
	if enemy_conversation and not is_on_starship and is_instance_valid(player):
		enemy_conversation.update_conversations(delta, enemies, player.global_position)

	GameSystems.track("total_distance", player.velocity.length() * delta / 64.0)

func _update_enemies(delta: float) -> void:
	enemy_retarget_timer -= delta
	if enemy_retarget_timer <= 0:
		enemy_retarget_timer = 0.5
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				var dist := enemy.global_position.distance_to(player.global_position)
				if dist < enemy.detection_range:
					enemy.set_target(player)

	# Apply enemy separation forces to prevent overlapping
	_apply_enemy_separation(delta)

	var dead_indices: Array[int] = []
	for i in range(enemies.size()):
		if not is_instance_valid(enemies[i]):
			dead_indices.append(i)
	dead_indices.reverse()
	for idx in dead_indices:
		enemies.remove_at(idx)

func _check_room_triggers() -> void:
	spawn_check_timer -= get_process_delta_time()
	if spawn_check_timer > 0:
		return
	spawn_check_timer = 0.3

	for room_data in map_gen.enemy_spawn_rooms:
		if room_data["triggered"]:
			continue
		var dist := player.global_position.distance_to(room_data["room_center"])
		if dist < 400.0:
			room_data["triggered"] = true
			_spawn_room_enemies(room_data)

func _spawn_room_enemies(room_data: Dictionary) -> void:
	var difficulty: String = room_data["difficulty"]
	var points: Array = room_data["spawn_points"]

	for spawn_pos in points:
		spawn_pos = _get_offscreen_spawn_position(spawn_pos)
		var etype: int
		match difficulty:
			"easy":
				var roll := randf()
				if roll < 0.6:
					etype = GameData.EnemyType.GOBLIN_SKELETON
				else:
					etype = GameData.EnemyType.ELVEN_SKELETON
			"medium":
				var roll := randf()
				if roll < 0.35:
					etype = GameData.EnemyType.GOBLIN_SKELETON
				elif roll < 0.6:
					etype = GameData.EnemyType.ELVEN_SKELETON
				elif roll < 0.8:
					etype = GameData.EnemyType.GOBLIN_ZED
				else:
					etype = GameData.EnemyType.SMALL_ORC_ZED
			"hard":
				var roll := randf()
				if roll < 0.2:
					etype = GameData.EnemyType.GOBLIN_SKELETON
				elif roll < 0.4:
					etype = GameData.EnemyType.ELVEN_SKELETON
				elif roll < 0.6:
					etype = GameData.EnemyType.GOBLIN_ZED
				elif roll < 0.75:
					etype = GameData.EnemyType.SMALL_ORC_ZED
				elif roll < 0.9:
					etype = GameData.EnemyType.MEDIUM_ORC_ZED
				else:
					etype = GameData.EnemyType.DWARVEN_ZED
			"boss":
				var roll := randf()
				if roll < 0.3:
					etype = GameData.EnemyType.ELVEN_SKELETON
				elif roll < 0.5:
					etype = GameData.EnemyType.GOBLIN_ZED
				elif roll < 0.65:
					etype = GameData.EnemyType.SMALL_ORC_ZED
				elif roll < 0.75:
					etype = GameData.EnemyType.MEDIUM_ORC_ZED
				elif roll < 0.85:
					etype = GameData.EnemyType.DWARVEN_ZED
				else:
					etype = GameData.EnemyType.HUGE_ORC_ZED
			_:
				etype = GameData.EnemyType.GOBLIN_SKELETON

		# Elite chance based on difficulty
		var elite_chance := 0.0
		match difficulty:
			"medium": elite_chance = 0.05
			"hard": elite_chance = 0.1
			"boss": elite_chance = 0.15
		_spawn_enemy(spawn_pos, etype, randf() < elite_chance)

	if difficulty == "boss":
		var boss_pos: Vector2 = room_data["room_center"]
		var boss_roll := randf()
		var boss_type: int
		if boss_roll < 0.33:
			boss_type = GameData.EnemyType.HUMAN_ZED
		elif boss_roll < 0.66:
			boss_type = GameData.EnemyType.HUGE_ORC_ZED
		else:
			boss_type = GameData.EnemyType.ELVEN_NECROMANCER
		_spawn_enemy(boss_pos, boss_type)

func _spawn_enemy(pos: Vector2, etype: int, make_elite: bool = false) -> void:
	var enemy := CharacterBody2D.new()
	enemy.set_script(EnemyScript)
	enemy.setup(etype, difficulty_mult)
	if make_elite:
		enemy.make_elite()
	enemy.global_position = pos
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_attacked.connect(_on_enemy_attack)
	enemy.alert_nearby.connect(_on_enemy_alert)

	# Improvement #35b: Distance-based level scaling
	if map_gen and map_gen.spawn_position != Vector2.ZERO:
		var dist_from_start := pos.distance_to(map_gen.spawn_position)
		enemy.distance_level_bonus = clampf(dist_from_start / 2000.0, 0.0, 2.0)
		enemy.max_hp *= (1.0 + enemy.distance_level_bonus * 0.3)
		enemy.hp = enemy.max_hp
		enemy.damage *= (1.0 + enemy.distance_level_bonus * 0.15)
		enemy.gold_drop = int(enemy.gold_drop * (1.0 + enemy.distance_level_bonus * 0.5))
		enemy.xp_value = int(enemy.xp_value * (1.0 + enemy.distance_level_bonus * 0.3))

	enemy.add_to_group("enemies")
	entities_node.add_child(enemy)
	enemies.append(enemy)

	# Assign patrol route if available
	if map_gen.patrol_routes.size() > 0:
		var route: Dictionary = map_gen.patrol_routes.pick_random()
		if route.has("points"):
			enemy.set_patrol(route["points"])

	var dist_to_player := pos.distance_to(player.global_position)
	if dist_to_player < enemy.detection_range:
		enemy.set_target(player)

func _get_offscreen_spawn_position(base_pos: Vector2) -> Vector2:
	if not is_instance_valid(player) or not camera:
		return base_pos
	
	var camera_pos := camera.global_position
	var viewport_size := get_viewport().get_visible_rect().size
	var camera_zoom := camera.zoom
	var half_width := viewport_size.x / (2.0 * camera_zoom.x)
	var half_height := viewport_size.y / (2.0 * camera_zoom.y)
	
	var spawn_distance := 150.0
	var direction := (base_pos - camera_pos).normalized()
	
	if direction.length() < 0.1:
		direction = Vector2.from_angle(randf() * TAU)
	
	var offscreen_pos := camera_pos + direction * spawn_distance
	return offscreen_pos

func _on_enemy_alert(alert_pos: Vector2, alert_range: float) -> void:
	if not is_instance_valid(player):
		return
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var dist := enemy.global_position.distance_to(alert_pos)
		if dist < alert_range and enemy.has_method("alert_from"):
			enemy.alert_from(player.global_position)

func _on_player_attack(attack_data: Dictionary) -> void:
	match attack_data["type"]:
		"melee":
			_handle_melee_attack(attack_data)
		"ranged":
			_handle_ranged_attack(attack_data)

func _handle_melee_attack(data: Dictionary) -> void:
	var origin: Vector2 = data["position"]
	var direction: Vector2 = data["direction"]
	var dmg: float = data["damage"]
	var rng_val: float = data["range"]
	var arc: float = data["arc"]
	var angle: float = data["angle"]
	var stagger: float = data.get("stagger", 0.0)
	var is_crit: bool = data.get("is_crit", false)

	# Apply combo damage multiplier
	var combo_mult := GameSystems.get_combo_damage_mult()
	var level_mult := GameSystems.get_level_stat_bonus()
	dmg *= combo_mult * level_mult

	# Get new improvement data from attack
	var armor_pen_val: float = data.get("armor_pen", 0.0)
	var exec_threshold: float = data.get("execution_threshold", 0.0)
	var is_charged: bool = data.get("is_charged", false)
	var is_parry: bool = data.get("is_parry", false)

	var hit_count := 0
	var total_overkill := 0.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var to_enemy := enemy.global_position - origin
		var dist := to_enemy.length()
		if dist > rng_val:
			continue
		var angle_to := to_enemy.angle()
		var angle_diff := absf(angle_difference(angle, angle_to))
		if angle_diff > arc / 2.0:
			continue

		var actual_dmg := dmg
		# Damage falloff: reduce by 20% at max range
		var falloff := 1.0 - (dist / rng_val) * 0.2
		actual_dmg *= falloff

		# Improvement #1105: Backstab bonus - 50% extra from behind
		if enemy.has_method("get_facing_direction"):
			var enemy_facing: Vector2 = enemy.get_facing_direction()
			var attack_dir: Vector2 = (enemy.global_position - origin).normalized()
			if enemy_facing.dot(attack_dir) > 0.5:
				actual_dmg *= 1.5
				is_crit = true

		var hp_before: float = enemy.hp
		var was_alive: bool = enemy.is_alive
		# Pass armor pen and execution threshold to enemy
		enemy.take_damage(actual_dmg, origin, false, is_crit, "physical", armor_pen_val, exec_threshold)
		hit_count += 1

		# Trigger player attack dialogue
		if combat_dialogue:
			combat_dialogue.on_player_attack(origin, actual_dmg, is_crit)
		
		# Trigger enemy damage dialogue
		if combat_dialogue and enemy.is_alive:
			var enemy_type = enemy.stats.get("name", "Enemy")
			combat_dialogue.on_enemy_take_damage(enemy, enemy_type, actual_dmg)

		# VFX: blood burst and hit flash on impact
		var hit_dir := (enemy.global_position - origin).normalized()
		if vfx:
			vfx.spawn_hit_effect(enemy.global_position, actual_dmg, is_crit, hit_dir)
			# Improvement #51: Execution VFX
			if was_alive and not enemy.is_alive and exec_threshold > 0 and hp_before / maxf(enemy.max_hp, 1.0) <= exec_threshold:
				vfx.spawn_execution_slash(enemy.global_position, direction)
			# Improvement #52: Charge glow on impact
			if is_charged:
				var charge_pct: float = data.get("charge_pct", 0.5)
				vfx.spawn_charge_glow(enemy.global_position, charge_pct)

		# Track overkill
		if not enemy.is_alive:
			total_overkill += maxf(actual_dmg - hp_before, 0.0)
			# Improvement #55: Overkill VFX for big overkills
			var ok_amount := maxf(actual_dmg - hp_before, 0.0)
			if ok_amount > 20.0 and vfx:
				vfx.spawn_overkill_explosion(enemy.global_position, ok_amount)

		if stagger > 0:
			enemy.stagger_timer = maxf(enemy.stagger_timer, stagger)

		# Register hit with combo system
		GameSystems.register_hit()
		GameSystems.track("total_damage_dealt", actual_dmg)
		# Improvement #59: DPS tracking
		if hud and hud.has_method("add_dps_sample"):
			hud.add_dps_sample(actual_dmg)
		if is_crit:
			GameSystems.track("critical_hits")

		if hud.has_method("spawn_damage_number"):
			hud.spawn_damage_number(enemy.global_position + Vector2(0, -20), actual_dmg, is_crit)
		if hud.has_method("show_hit_marker"):
			hud.show_hit_marker(is_crit)

	# VFX: melee swing trail
	if vfx:
		var trail_color := Color(1.0, 0.9, 0.5, 0.7) if not is_crit else Color(1.0, 0.4, 0.2, 0.9)
		if is_charged:
			trail_color = Color(1.0, 0.5, 0.1, 0.9)
		if is_parry:
			trail_color = Color(0.3, 0.7, 1.0, 0.9)
		vfx.spawn_attack_trail(origin, angle, arc, rng_val, trail_color)

	# Also check destructibles in melee range
	_check_melee_destructibles(origin, angle, arc, rng_val, dmg)

	if hit_count > 0 and player.is_alive:
		# Lifesteal: 2 temp HP per hit + overkill bonus
		var lifesteal: float = hit_count * 2.0 + total_overkill * 0.1
		player.add_temp_hp(lifesteal)
		_on_screen_shake_request(0.15 * hit_count, 0.1)
		# Camera punch toward hit direction
		if GameSystems.get_setting("camera_punch"):
			camera_punch = direction * (3.0 + hit_count * 1.5)
		# Hit pause on crits/charged for impact feel
		if (is_crit or is_charged) and GameSystems.get_setting("hit_pause_enabled"):
			hit_pause_timer = 0.04 + (0.04 if is_charged else 0.0)

func _handle_ranged_attack(data: Dictionary) -> void:
	var proj := Area2D.new()
	proj.set_script(ProjectileScript)
	proj.global_position = data["position"]
	proj.setup(data["direction"], data["speed"], data["damage"], data["range"], true)
	projectiles_node.add_child(proj)

	# VFX: muzzle flash
	if vfx:
		vfx.spawn_muzzle_flash(data["position"], data["direction"])
	if GameSystems.get_setting("camera_punch"):
		camera_punch = -data["direction"] * 2.0

func _on_enemy_died(_enemy: CharacterBody2D, data: Dictionary) -> void:
	# Improvement #44: Handle summon requests (not actual deaths)
	if data.get("category", "") == "summon_request":
		var summon_pos: Vector2 = data["position"] + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		_spawn_enemy(summon_pos, data["type"])
		return

	total_kills += 1
	if is_instance_valid(player) and player.is_alive:
		player.add_gold(data["gold"])
		player.add_xp(data["xp"])
		player.total_kills = total_kills
		# Improvement #21: Bloodlust on kill
		if player.has_method("on_kill"):
			player.on_kill()
		# Improvement #1119: Lifesteal on kill - restore 5% max HP
		var lifesteal: float = player.max_hp * 0.05
		if player.hp < player.max_hp and player.has_method("heal"):
			player.heal(lifesteal, false)
			if vfx:
				vfx.spawn_heal_particles(player.global_position, lifesteal)
		# Improvement #63: Update bloodlust HUD
		if hud and hud.has_method("update_bloodlust"):
			hud.update_bloodlust(player.bloodlust_stacks)
		# Improvement #60: Gold popup
		if hud and hud.has_method("show_gold_popup") and data["gold"] > 0:
			hud.show_gold_popup(data["gold"])
		# Improvement #1137: Gold fly-to-HUD animation
		if hud and hud.has_method("animate_gold_pickup") and data["gold"] > 0:
			hud.animate_gold_pickup(data.get("position", player.global_position))
		# Trigger kill dialogue
		if combat_dialogue:
			combat_dialogue.on_player_kill(_enemy)

	# Track with GameSystems
	var enemy_name: String = data.get("name", "Enemy")
	var weapon: String = "melee" if data.get("killed_by_melee", true) else "ranged"
	GameSystems.register_kill(enemy_name, weapon)
	GameSystems.track("total_kills")
	GameSystems.track("total_gold_earned", data["gold"])
	GameSystems.track("total_xp_earned", data["xp"])

	if data["category"] == "standard":
		player.add_kill_credit(1)
		GameSystems.add_score(10)
		GameSystems.track("enemies_killed_" + weapon)
	elif data["category"] == "elite":
		player.add_kill_credit(5)
		GameSystems.add_score(50)
		GameSystems.track("enemies_killed_" + weapon)
	elif data["category"] == "boss":
		player.add_kill_credit(10)
		GameSystems.add_score(200)
		GameSystems.track("bosses_killed")
		_on_screen_shake_request(0.6, 0.5)
		# Boss death: big hit pause and camera zoom
		if GameSystems.get_setting("hit_pause_enabled"):
			hit_pause_timer = 0.12
		camera_target_zoom = Vector2(2.0, 2.0)
		get_tree().create_timer(1.0).timeout.connect(func(): camera_target_zoom = Vector2(GameSystems.get_setting("camera_zoom"), GameSystems.get_setting("camera_zoom")))

	# VFX: death gore/blood
	if vfx:
		var enemy_color: Color = data.get("color", Color(0.5, 0.0, 0.0))
		var is_boss: bool = data["category"] == "boss"
		vfx.spawn_death_effect(data["position"], enemy_color, is_boss)
		# Improvement #55: Overkill VFX
		var overkill: float = data.get("overkill", 0.0)
		if overkill > 15.0:
			vfx.spawn_overkill_explosion(data["position"], overkill)
		# Improvement #49: Elemental death VFX
		var elem: String = data.get("elemental", "none")
		if elem != "none" and elem != "":
			vfx.spawn_elemental_hit(data["position"], elem, Vector2.UP)

	# Improvement #40: Loot explosion - drop multiple items for elites/bosses
	var loot_count: int = data.get("loot_count", 1)
	for _i in range(loot_count):
		if randf() < 0.15 + (loot_count - 1) * 0.1:
			var drop_roll := randf()
			var drop_type: String
			if drop_roll < 0.25:
				drop_type = "gold_coin"
			elif drop_roll < 0.40:
				drop_type = "ammo_small"
			elif drop_roll < 0.55:
				drop_type = "health_potion"
			elif drop_roll < 0.65:
				drop_type = "artifact_ring"
			elif drop_roll < 0.72:
				drop_type = "gold_bar"
			# Improvement #68-70: New buff/multiplier drops
			elif drop_roll < 0.78:
				drop_type = "speed_boost"
			elif drop_roll < 0.84:
				drop_type = "damage_boost"
			elif drop_roll < 0.88:
				drop_type = "shield_orb"
			elif drop_roll < 0.92:
				drop_type = "rage_potion"
			elif drop_roll < 0.96:
				drop_type = "gold_multiplier"
			else:
				drop_type = "xp_multiplier"
			var offset := Vector2(randf_range(-20, 20), randf_range(-20, 20))
			_spawn_item(data["position"] + offset, drop_type)

	# Improvement #69: Health orb drop chance
	if randf() < 0.12:
		_spawn_item(data["position"] + Vector2(randf_range(-15, 15), randf_range(-15, 15)), "health_orb")

	if randf() < 0.08:
		var food_keys := GameData.food_defs.keys()
		if not food_keys.is_empty():
			var food_type: String = food_keys.pick_random()
			_spawn_food(data["position"] + Vector2(randf_range(-20, 20), randf_range(-20, 20)), food_type)

func _on_enemy_attack(target: CharacterBody2D, dmg: float, from_pos: Vector2) -> void:
	if target == player and player.is_alive:
		player.take_damage(dmg, from_pos)
		GameSystems.track("total_damage_taken", dmg)
		# Enhanced knockback feedback - scale with damage
		var shake_intensity := minf(dmg * 0.03, 0.8)
		_on_screen_shake_request(shake_intensity, 0.2)
		
		# Trigger player damage dialogue
		if combat_dialogue:
			combat_dialogue.on_player_take_damage(dmg, from_pos)
		# VFX: player blood
		if vfx and from_pos != Vector2.ZERO:
			var dir := (player.global_position - from_pos).angle()
			vfx.spawn_player_hit_effect(player.global_position, dir)
		if GameSystems.get_setting("camera_punch") and from_pos != Vector2.ZERO:
			var punch_dir := (player.global_position - from_pos).normalized()
			camera_punch = punch_dir * minf(dmg * 0.15, 5.0)

func _on_hp_changed(current: float, temp: float, max_val: float) -> void:
	if hud.has_method("update_hp"):
		hud.update_hp(current, temp, max_val)
	if hud.has_method("set_vignette_intensity"):
		var real_hp := current - temp
		hud.set_vignette_intensity(real_hp / maxf(max_val, 1.0))

func _on_stamina_changed(current: float, max_val: float) -> void:
	if hud.has_method("update_stamina"):
		hud.update_stamina(current, max_val)

func _on_shields_changed(current: float, max_val: float) -> void:
	if hud.has_method("update_shields"):
		hud.update_shields(current, max_val)

func _on_mana_changed(current: float, max_val: float) -> void:
	if hud.has_method("update_mana"):
		hud.update_mana(current, max_val)

func _on_rage_changed(current: float, max_val: float) -> void:
	if hud.has_method("update_rage"):
		hud.update_rage(current, max_val)

func _on_ammo_changed(current: int, max_val: int) -> void:
	if hud.has_method("update_ammo"):
		hud.update_ammo(current, max_val)

func _on_gold_changed(amount: int) -> void:
	if hud.has_method("update_gold"):
		hud.update_gold(amount)

func _on_slot_changed(slot: int) -> void:
	if hud.has_method("update_slot"):
		hud.update_slot(slot)

func _on_player_died() -> void:
	is_mission_active = false
	can_quick_restart = true
	Engine.time_scale = 1.0
	GameSystems.track("total_deaths")
	_on_screen_shake_request(1.0, 0.8)
	# VFX: player death gore explosion
	if vfx:
		vfx.spawn_gore_explosion(player.global_position, Color(0.6, 0.05, 0.05))
		vfx.spawn_blood_burst(player.global_position, Vector2.UP, 20, 180.0)
		vfx.spawn_blood_splat(player.global_position, 3.0)
	if GameSystems.get_setting("hit_pause_enabled"):
		hit_pause_timer = 0.08

	# Improvement #61: Death screen with stats
	if hud and hud.has_method("show_death_screen"):
		var stats_text := "Kills: " + str(total_kills)
		stats_text += "\nTime: " + str(int(mission_time / 60)) + ":" + str(int(mission_time) % 60).pad_zeros(2)
		stats_text += "\nGold: " + str(player.gold_coins if is_instance_valid(player) else 0)
		stats_text += "\nDamage Dealt: " + str(int(GameSystems.stats.get("total_damage_dealt", 0.0)))
		stats_text += "\nDamage Taken: " + str(int(GameSystems.stats.get("total_damage_taken", 0.0)))
		stats_text += "\nCritical Hits: " + str(int(GameSystems.stats.get("critical_hits", 0)))
		stats_text += "\nPerfect Blocks: " + str(int(GameSystems.stats.get("perfect_blocks", 0)))
		stats_text += "\n\nPress R to restart or ESC for menu"
		hud.show_death_screen(stats_text)

	var timer := get_tree().create_timer(8.0)
	timer.timeout.connect(_return_to_menu)

func _check_safespace() -> void:
	if map_gen.safespace_position == Vector2.ZERO:
		return
	if not player.is_alive:
		return
	var dist := player.global_position.distance_to(map_gen.safespace_position)
	if dist < 60.0:
		_mission_complete()

func _mission_complete() -> void:
	if not is_mission_active:
		return
	is_mission_active = false
	GameSystems.track("missions_completed")
	var rating := GameSystems.get_mission_rating(total_kills, mission_time, GameSystems.stats.get("total_damage_taken", 0.0), player.gold_coins)
	if hud.has_method("show_notification"):
		hud.show_notification("MISSION COMPLETE! Rating: " + rating, Color(0.3, 1.0, 0.5))
	GameSystems.save_stats()

	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(_return_to_menu)

func _return_to_menu() -> void:
	Engine.time_scale = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _update_hud(delta: float) -> void:
	if not hud:
		return
	if hud.has_method("update_timer"):
		hud.update_timer(mission_time)
	if hud.has_method("update_kills"):
		hud.update_kills(total_kills)
	if hud.has_method("update_xp"):
		hud.update_xp(GameSystems.player_xp, GameSystems.xp_to_next_level, GameSystems.player_level)

	# Improvement #63: Bloodlust indicator
	if is_instance_valid(player) and hud.has_method("update_bloodlust"):
		hud.update_bloodlust(player.bloodlust_stacks)

	# Improvement #64: Charge bar
	if is_instance_valid(player) and hud.has_method("show_charge_progress"):
		if player.is_charging:
			hud.show_charge_progress(clampf(player.charge_timer / player.charge_max_time, 0, 1))
		else:
			hud.show_charge_progress(0.0)

	# Improvement #74: Quick restart
	if can_quick_restart and Input.is_action_just_pressed("interact"):
		can_quick_restart = false
		get_tree().reload_current_scene()

	minimap_update_timer -= delta
	if minimap_update_timer <= 0:
		minimap_update_timer = 0.5
		var enemy_positions: Array[Vector2] = []
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				enemy_positions.append(enemy.global_position)
		if hud.has_method("update_minimap") and map_gen and map_gen.tiles:
			hud.update_minimap(map_gen.tiles, player.global_position, enemy_positions, map_gen.safespace_position)

func _update_torch_flicker(delta: float) -> void:
	for light in active_lights:
		if is_instance_valid(light):
			light.energy = light.energy + (randf_range(-0.5, 0.5)) * delta
			light.energy = clampf(light.energy, 0.5, 1.1)

# ===== Batch 4: Screen Shake =====

func _on_screen_shake_request(intensity: float, duration: float) -> void:
	if not GameSystems.get_setting("screen_shake"):
		return
	if intensity > screen_shake_intensity:
		screen_shake_intensity = intensity
		screen_shake_timer = duration

func _apply_screen_shake(delta: float) -> void:
	if screen_shake_timer > 0:
		screen_shake_timer -= delta
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * screen_shake_intensity * 10.0
		camera.offset = offset
		screen_shake_intensity *= 0.9
		if screen_shake_timer <= 0:
			camera.offset = Vector2.ZERO
			screen_shake_intensity = 0.0

func _on_damage_direction(angle: float) -> void:
	if hud.has_method("show_damage_direction"):
		hud.show_damage_direction(angle)

# ===== Batch 4: Destructibles =====

func _place_destructibles() -> void:
	for destr_info in map_gen.destructible_positions:
		var pos: Vector2 = destr_info["pos"]
		var dtype: String = destr_info["type"]
		_spawn_destructible(pos, dtype)

func _spawn_destructible(pos: Vector2, dtype: String) -> void:
	var destr := Node2D.new()
	destr.global_position = pos
	destr.z_index = 7
	destr.set_meta("type", dtype)
	destr.set_meta("hp", 15.0)
	destr.set_meta("alive", true)

	var emoji_map := {
		"barrel": "\U0001FAA3",
		"crate": "\U0001F4E6",
		"vase": "\U0001F3FA",
		"tombstone": "\U0001FAA6",
		"crystal": "\U0001F48E",
	}

	var emoji_node = _create_emoji_node(emoji_map.get(dtype, "\U0001F4E6"), 20, Vector2(24, 24), Vector2(-12, -16))
	destr.add_child(emoji_node)

	destructibles_node.add_child(destr)
	destructibles.append(destr)

func _check_melee_destructibles(origin: Vector2, angle: float, arc: float, rng_val: float, dmg: float) -> void:
	for destr in destructibles:
		if not is_instance_valid(destr) or not destr.get_meta("alive", false):
			continue
		var to_obj := destr.global_position - origin
		var dist := to_obj.length()
		if dist > rng_val:
			continue
		var angle_to := to_obj.angle()
		var angle_diff := absf(angle_difference(angle, angle_to))
		if angle_diff > arc / 2.0:
			continue
		var destr_hp: float = destr.get_meta("hp", 0.0) - dmg
		destr.set_meta("hp", destr_hp)
		if destr_hp <= 0:
			_destroy_destructible(destr)

func _destroy_destructible(destr: Node2D) -> void:
	destr.set_meta("alive", false)
	var dtype: String = destr.get_meta("type", "crate")

	# Drop loot from destructible
	var drop_chance := 0.3
	if dtype == "crystal":
		drop_chance = 0.6
	if randf() < drop_chance:
		var drop_types := ["gold_coin", "ammo_small", "health_potion"]
		_spawn_item(destr.global_position, drop_types.pick_random())

	GameSystems.add_score(5)

	# VFX: destructible break effect
	if vfx:
		vfx.spawn_impact_ring(destr.global_position, 20.0, Color(0.8, 0.6, 0.3, 0.8))
		vfx.spawn_hit_flash(destr.global_position, 15.0, Color(1, 0.9, 0.6, 0.7))
		if dtype == "barrel" or dtype == "vase":
			vfx.spawn_blood_burst(destr.global_position, Vector2.UP, 6, 80.0)

	# Show break effect then remove
	var label: Label = destr.get_child(0) if destr.get_child_count() > 0 else null
	if label:
		label.text = "\U0001F4A5"
	var tween := create_tween()
	tween.tween_property(destr, "modulate:a", 0.0, 0.4)
	tween.tween_callback(destr.queue_free)

# ===== Batch 4: Traps =====

func _place_traps() -> void:
	for trap_info in map_gen.trap_positions:
		var pos: Vector2 = trap_info["pos"]
		var ttype: String = trap_info["type"]
		_spawn_trap(pos, ttype)

func _spawn_trap(pos: Vector2, ttype: String) -> void:
	var trap := Node2D.new()
	trap.global_position = pos
	trap.z_index = 3
	trap.set_meta("type", ttype)
	trap.set_meta("cooldown", 0.0)

	var lbl := Label.new()
	if ttype == "spike":
		lbl.text = "\U0001F4A2"
	else:
		lbl.text = "\u2620\uFE0F"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-10, -10)
	lbl.size = Vector2(20, 20)
	var ls := LabelSettings.new()
	if GameData.emoji_font:
		ls.font = GameData.emoji_font
	ls.font_size = 14
	lbl.label_settings = ls
	lbl.modulate = Color(1, 1, 1, 0.3)
	trap.add_child(lbl)

	traps_node.add_child(trap)

var trap_check_timer: float = 0.0

func _check_trap_damage(delta: float) -> void:
	trap_check_timer -= delta
	if trap_check_timer > 0:
		return
	trap_check_timer = 0.3

	for trap in traps_node.get_children():
		if not is_instance_valid(trap):
			continue
		var cd: float = trap.get_meta("cooldown", 0.0)
		if cd > 0:
			trap.set_meta("cooldown", cd - 0.3)
			continue
		var dist: float = trap.global_position.distance_to(player.global_position)
		if dist < 30.0 and player.is_alive:
			var ttype: String = trap.get_meta("type", "spike")
			if ttype == "spike":
				player.take_damage(8.0, trap.global_position)
			else:
				player.take_damage(5.0, trap.global_position)
				# Poison: slow player briefly
				var original_speed: float = player.run_speed
				player.run_speed *= 0.7
				get_tree().create_timer(2.0).timeout.connect(func():
					if is_instance_valid(player) and player.is_alive:
						player.run_speed = original_speed
				)
			trap.set_meta("cooldown", 2.0)
			_on_screen_shake_request(0.1, 0.1)

		# Check enemies on traps too
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.is_alive:
				continue
			var enemy_dist: float = trap.global_position.distance_to(enemy.global_position)
			if enemy_dist < 30.0:
				var ttype: String = trap.get_meta("type", "spike")
				var trap_dmg := 5.0 if ttype == "spike" else 3.0
				enemy.take_damage(trap_dmg, trap.global_position)
				trap.set_meta("cooldown", 2.0)
# ===== Batch 4: Chests =====

func _place_chests() -> void:
	for chest_info in map_gen.chest_positions:
		var pos: Vector2 = chest_info["pos"]
		var rarity: String = chest_info.get("rarity", "common")
		_spawn_chest(pos, rarity)

func _spawn_chest(pos: Vector2, rarity: String) -> void:
	var chest := Area2D.new()
	chest.global_position = pos
	chest.set_meta("rarity", rarity)
	chest.set_meta("opened", false)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	col.shape = shape
	chest.add_child(col)
	chest.collision_layer = 0
	chest.collision_mask = 1

	var lbl := Label.new()
	var rarity_emojis := {
		"common": "\U0001F4E6",
		"uncommon": "\U0001F381",
		"rare": "\U0001F3C6",
		"epic": "\U0001F48E",
		"legendary": "\U0001F451",
	}
	lbl.text = rarity_emojis.get(rarity, "\U0001F4E6")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-16, -20)
	lbl.size = Vector2(32, 32)
	var ls := LabelSettings.new()
	if GameData.emoji_font:
		ls.font = GameData.emoji_font
	ls.font_size = 24
	lbl.label_settings = ls
	chest.add_child(lbl)

	# Glow for rarer chests
	if rarity != "common":
		var light := PointLight2D.new()
		light.texture = GameData.point_light_texture
		light.texture_scale = 1.5
		light.energy = 0.4
		var glow_colors := {
			"uncommon": Color(0.3, 0.8, 0.3),
			"rare": Color(0.3, 0.5, 1.0),
			"epic": Color(0.7, 0.3, 1.0),
			"legendary": Color(1.0, 0.8, 0.2),
		}
		light.color = glow_colors.get(rarity, Color.WHITE)
		light.shadow_enabled = false
		chest.add_child(light)

	chest.body_entered.connect(_on_chest_body_entered.bind(chest))
	chests_node.add_child(chest)

func _on_chest_body_entered(body: Node2D, chest: Area2D) -> void:
	if not is_instance_valid(body) or not is_instance_valid(chest):
		return
	if body != player or not player.is_alive:
		return
	if chest.get_meta("opened", false):
		return
	chest.set_meta("opened", true)

	var rarity: String = chest.get_meta("rarity", "common")
	var item_count := 1
	match rarity:
		"uncommon": item_count = 2
		"rare": item_count = 3
		"epic": item_count = 4
		"legendary": item_count = 5

	var possible_items := ["gold_coin", "gold_bar", "ammo_small", "health_potion", "artifact_ring"]
	for i in range(item_count):
		var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_spawn_item(chest.global_position + offset, possible_items.pick_random())

	# Bonus gold for rarity
	var bonus_gold := {"common": 5, "uncommon": 15, "rare": 30, "epic": 60, "legendary": 150}
	player.add_gold(bonus_gold.get(rarity, 5))
	GameSystems.add_score(bonus_gold.get(rarity, 5))

	if hud.has_method("show_notification"):
		var rarity_colors := {
			"common": Color(0.7, 0.7, 0.7),
			"uncommon": Color(0.3, 0.9, 0.3),
			"rare": Color(0.3, 0.5, 1.0),
			"epic": Color(0.7, 0.3, 1.0),
			"legendary": Color(1.0, 0.8, 0.2),
		}
		hud.show_notification(rarity.capitalize() + " Chest opened!", rarity_colors.get(rarity, Color.WHITE))

	# Open animation
	var lbl: Label = chest.get_child(1) if chest.get_child_count() > 1 else null
	if lbl:
		lbl.text = "\u2728"
	var tween := create_tween()
	tween.tween_property(chest, "modulate:a", 0.0, 1.0)
	tween.tween_callback(chest.queue_free)

# ===== Batch 4: Ambient Particles =====

func _place_ambient_particles() -> void:
	for p_info in map_gen.particle_positions:
		var pos: Vector2 = p_info["pos"]
		var ptype: String = p_info["type"]
		_spawn_ambient_particle(pos, ptype)

func _spawn_ambient_particle(pos: Vector2, ptype: String) -> void:
	var particle := GPUParticles2D.new()
	particle.global_position = pos
	particle.z_index = 2
	particle.amount = 4
	particle.lifetime = 3.0
	particle.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 20.0
	mat.gravity = Vector3(0, -5, 0)
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 8.0

	match ptype:
		"dust":
			mat.color = Color(0.6, 0.5, 0.4, 0.3)
			mat.gravity = Vector3(0, 3, 0)
		"mist":
			mat.color = Color(0.5, 0.6, 0.7, 0.2)
			mat.gravity = Vector3(0, 0, 0)
			particle.amount = 6
		"sparkle":
			mat.color = Color(1.0, 0.9, 0.5, 0.5)
			mat.gravity = Vector3(0, -10, 0)
		"smoke":
			mat.color = Color(0.3, 0.3, 0.3, 0.25)
			mat.gravity = Vector3(0, -8, 0)
		_:
			mat.color = Color(0.5, 0.5, 0.5, 0.2)

	particle.process_material = mat
	particles_node.add_child(particle)

# ===== Improvement #76: Fountains =====

var fountain_nodes: Array[Node2D] = []
var fountain_check_timer: float = 0.0

func _place_fountains() -> void:
	for f_info in map_gen.fountain_positions:
		var fountain := Node2D.new()
		fountain.global_position = f_info["pos"]
		fountain.z_index = 6
		fountain.set_meta("heal_per_sec", f_info["heal_per_sec"])
		fountain.set_meta("radius", f_info["radius"])
		fountain.set_meta("uses_left", f_info["uses_left"])

		var emoji_node = _create_emoji_node(f_info["emoji"], 20, Vector2(24, 24), Vector2(-12, -16))
		fountain.add_child(emoji_node)

		var light := PointLight2D.new()
		light.texture = GameData.point_light_texture
		light.texture_scale = 2.0
		light.energy = 0.3
		light.color = Color(0.3, 0.5, 1.0)
		light.shadow_enabled = false
		fountain.add_child(light)

		items_node.add_child(fountain)
		fountain_nodes.append(fountain)

func _check_fountain_healing(delta: float) -> void:
	fountain_check_timer -= delta
	if fountain_check_timer > 0:
		return
	fountain_check_timer = 0.5
	if not is_instance_valid(player) or not player.is_alive:
		return
	for fountain in fountain_nodes:
		if not is_instance_valid(fountain):
			continue
		var uses: int = fountain.get_meta("uses_left", 0)
		if uses <= 0:
			continue
		var radius: float = fountain.get_meta("radius", 64.0)
		var dist := player.global_position.distance_to(fountain.global_position)
		if dist < radius:
			var heal: float = fountain.get_meta("heal_per_sec", 3.0) * 0.5
			player.heal(heal, false)
			fountain.set_meta("uses_left", uses - 1)
			if vfx:
				vfx.spawn_heal_particles(fountain.global_position, heal)
			if uses - 1 <= 0:
				fountain.modulate = Color(0.5, 0.5, 0.5, 0.5)

# ===== Improvement #77: Altars =====

var altar_nodes: Array[Area2D] = []

func _place_altars() -> void:
	for a_info in map_gen.altar_positions:
		var altar := Area2D.new()
		altar.global_position = a_info["pos"]
		altar.z_index = 6
		altar.set_meta("buff", a_info["buff"])
		altar.set_meta("value", a_info["value"])
		altar.set_meta("duration", a_info["duration"])
		altar.set_meta("name", a_info["name"])
		altar.set_meta("activated", false)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 24.0
		col.shape = shape
		altar.add_child(col)
		altar.collision_layer = 0
		altar.collision_mask = 1

		var emoji_node = _create_emoji_node(a_info["emoji"], 22, Vector2(28, 28), Vector2(-14, -18))
		altar.add_child(emoji_node)

		var light := PointLight2D.new()
		light.texture = GameData.point_light_texture
		light.texture_scale = 2.0
		light.energy = 0.4
		light.color = Color(0.8, 0.6, 1.0)
		light.shadow_enabled = false
		altar.add_child(light)

		altar.body_entered.connect(_on_altar_body_entered.bind(altar))
		chests_node.add_child(altar)
		altar_nodes.append(altar)

func _on_altar_body_entered(body: Node2D, altar: Area2D) -> void:
	if not is_instance_valid(body) or not is_instance_valid(altar):
		return
	if body != player or not player.is_alive:
		return
	if altar.get_meta("activated", false):
		return
	altar.set_meta("activated", true)

	var buff_type: String = altar.get_meta("buff", "damage")
	var buff_val: float = altar.get_meta("value", 1.2)
	var buff_dur: float = altar.get_meta("duration", 60.0)
	var altar_name: String = altar.get_meta("name", "Altar")

	match buff_type:
		"damage":
			if "melee_damage" in player:
				player.melee_damage *= buff_val
				player.ranged_damage *= buff_val
		"speed":
			if "run_speed" in player:
				player.run_speed *= buff_val
		"defense":
			player.add_temp_hp(30.0)
		"crit_chance":
			if "crit_chance" in player:
				player.crit_chance += buff_val
		"regen":
			player.heal(20.0, true)

	if hud and hud.has_method("add_buff"):
		hud.add_buff(buff_type, buff_dur, "")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(altar_name + " activated!", Color(0.8, 0.6, 1.0))

	altar.modulate = Color(0.4, 0.4, 0.4, 0.5)
	if vfx:
		vfx.spawn_level_up_burst(altar.global_position)

# ===== Improvement #78: Decorations =====

func _place_decorations() -> void:
	for d_info in map_gen.decoration_positions:
		var deco := Node2D.new()
		deco.global_position = d_info["pos"]
		deco.z_index = 4

		var emoji_node = _create_emoji_node(d_info["emoji"], 14, Vector2(20, 20), Vector2(-10, -12))
		emoji_node.modulate = Color(1.0, 1.0, 1.0, 0.6)
		deco.add_child(emoji_node)

		items_node.add_child(deco)

# ===== Improvement #80: Dead-End Treasures =====

func _place_dead_end_treasures() -> void:
	for t_info in map_gen.dead_end_treasures:
		_spawn_chest(t_info["pos"], t_info["rarity"])

# ===== Improvement #83: Themed Items =====

func _place_themed_items() -> void:
	for t_info in map_gen.themed_item_positions:
		_spawn_item(t_info["pos"], t_info["type"])

# ===== Improvement #79: Corridor Ambush Check =====

var corridor_ambush_check_timer: float = 0.0

func _check_corridor_ambushes() -> void:
	if not is_instance_valid(player) or not player.is_alive:
		return
	for ambush in map_gen.corridor_ambush_points:
		if ambush["triggered"]:
			continue
		var dist := player.global_position.distance_to(ambush["pos"])
		if dist < 120.0:
			ambush["triggered"] = true
			var count: int = ambush["enemy_count"]
			for _i in range(count):
				var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40))
				_spawn_enemy(ambush["pos"] + offset, GameData.EnemyType.GOBLIN_SKELETON)
			if hud and hud.has_method("show_notification"):
				hud.show_notification("Ambush!", Color(1.0, 0.3, 0.3))
			_on_screen_shake_request(0.3, 0.2)

# ===== Improvement #81: Hazard Zone Check =====

var hazard_check_timer: float = 0.0

func _check_hazard_zones(delta: float) -> void:
	hazard_check_timer -= delta
	if hazard_check_timer > 0:
		return
	hazard_check_timer = 0.5
	if not is_instance_valid(player) or not player.is_alive:
		return
	for hz in map_gen.hazard_zones:
		var dist := player.global_position.distance_to(hz["pos"])
		if dist < hz["radius"]:
			var dmg: float = hz["damage"] * 0.5
			player.take_damage(dmg, hz["pos"])
			if vfx:
				vfx.spawn_elemental_hit(player.global_position, hz["type"], Vector2.UP)

# ===== Batch 4: Room Exploration =====

func _check_player_room() -> void:
	if not map_gen.has_method("get_room_at_world_pos"):
		return
	var room_idx: int = map_gen.get_room_at_world_pos(player.global_position)
	if room_idx >= 0 and room_idx != current_room_index:
		current_room_index = room_idx
		if map_gen.has_method("mark_room_explored"):
			map_gen.mark_room_explored(room_idx)
		if map_gen.has_method("get_room_type"):
			var room_type: String = map_gen.get_room_type(room_idx)
			if hud.has_method("show_room_name"):
				hud.show_room_name(room_type)

# ===== Batch 4: Signal Connections =====

func _connect_game_signals() -> void:
	pass

func _setup_touch_controls() -> void:
	touch_controls = CanvasLayer.new()
	touch_controls.set_script(TouchControlsScript)
	add_child(touch_controls)

	if touch_controls.is_touch_mode:
		player.auto_attack_mode = true
		touch_controls.joystick_input.connect(_on_touch_joystick)
		touch_controls.special_pressed.connect(_on_touch_special)
		touch_controls.light_pressed.connect(_on_touch_light)
		touch_controls.dodge_pressed.connect(_on_touch_dodge)

func _on_touch_joystick(direction: Vector2) -> void:
	if player and player.is_alive:
		player.set_touch_direction(direction)

func _on_touch_special() -> void:
	if player and player.is_alive:
		player.trigger_ability()

func _on_touch_light() -> void:
	if player and player.is_alive:
		player.trigger_light()

func _on_touch_dodge() -> void:
	if player and player.is_alive:
		player.trigger_dodge()

func _place_lore_pickups() -> void:
	for lore_info in map_gen.lore_positions:
		var pickup := Area2D.new()
		pickup.set_script(LorePickupScript)
		pickup.setup(lore_info["entry_id"])
		pickup.global_position = lore_info["pos"]
		pickup.lore_picked_up.connect(_on_lore_picked_up)
		lore_node.add_child(pickup)

func _setup_lore_ui() -> void:
	tts_manager = Node.new()
	tts_manager.set_script(TtsManagerScript)
	add_child(tts_manager)

	lore_reader = CanvasLayer.new()
	lore_reader.set_script(LoreReaderScript)
	add_child(lore_reader)

	lore_collection = CanvasLayer.new()
	lore_collection.set_script(LoreCollectionScript)
	add_child(lore_collection)

func _on_lore_picked_up(entry_id: String) -> void:
	var entry := LoreManager.get_entry(entry_id)
	if entry.is_empty():
		return
	var is_new := not LoreManager.has_read(entry_id)
	lore_reader.open_entry(entry_id, tts_manager)
	if hud.has_method("show_notification"):
		if is_new:
			hud.show_notification("NEW LORE: " + entry["title"], Color(0.9, 0.8, 0.4))
		else:
			hud.show_notification("Lore: " + entry["title"], Color(0.6, 0.6, 0.7))

func _notification(what: int) -> void:
	# Improvement #1160: Pause on focus loss
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_mission_active and not get_tree().paused and pause_menu and not pause_menu.is_open:
			pause_menu.open()

func _unhandled_input(event: InputEvent) -> void:
	# Improvement #1159: Camera zoom with scroll wheel
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var new_zoom := camera_target_zoom * 1.1
				camera_target_zoom = Vector2(clampf(new_zoom.x, 0.5, 4.0), clampf(new_zoom.y, 0.5, 4.0))
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var new_zoom := camera_target_zoom * 0.9
				camera_target_zoom = Vector2(clampf(new_zoom.x, 0.5, 4.0), clampf(new_zoom.y, 0.5, 4.0))
				get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Check if any UI is open first
			if starship_dialogue and starship_dialogue.is_open:
				return  # Dialogue handles its own escape
			if inventory_ui and inventory_ui.is_open:
				return  # Inventory handles its own escape
			if pause_menu and pause_menu.is_open:
				return  # Pause menu handles its own escape
			# If in sidescroller, exit building first
			if not is_on_starship and ss_controller and ss_controller.is_sidescroller_mode():
				ss_controller.exit_building()
				return
			# Open pause menu instead of immediately quitting
			if pause_menu:
				pause_menu.open()
		elif event.keycode == KEY_I:
			# Toggle inventory
			if inventory_ui:
				inventory_ui.toggle()
		elif event.keycode == KEY_TAB:
			if lore_collection and not lore_collection.is_open:
				lore_collection.open_collection(tts_manager, lore_reader)
		elif event.keycode == KEY_E or event.keycode == KEY_F:
			# Don't handle E/F if lore reader is open
			if lore_reader and lore_reader.is_open:
				return
			# Starship interactions
			if is_on_starship:
				_try_starship_interaction()
			elif not is_on_starship and ss_controller and ss_controller.is_sidescroller_mode():
				# Exit sidescroller building via door
				if ss_controller.check_exit_proximity(player.global_position) or ss_controller.check_entry_door_proximity(player.global_position):
					ss_controller.exit_building()
			else:
				# Enter building in top-down mode, or interact with game corner
				if not _try_interact_game_corner():
					_try_enter_nearest_building()

# ===== SIDESCROLLER BUILDINGS =====

func _setup_sidescroller() -> void:
	ss_controller = Node2D.new()
	ss_controller.set_script(SidescrollerControllerScript)
	ss_controller.name = "SidescrollerController"
	var controller = ss_controller as Node
	controller.set("player_ref", player)
	controller.set("camera_ref", camera)
	controller.set("game_ref", self)
	var nodes_array: Array[Node] = [
		map_renderer, entities_node, projectiles_node, items_node,
		torches_node, lore_node, destructibles_node, traps_node,
		chests_node, particles_node, vfx,
	]
	if buildings_node:
		nodes_array.append(buildings_node)
	if safespace_visual:
		nodes_array.append(safespace_visual)
	controller.set("top_down_nodes", nodes_array)
	add_child(ss_controller)

	ss_controller.entered_building.connect(_on_entered_building)
	ss_controller.exited_building.connect(_on_exited_building)

func _place_buildings() -> void:
	buildings_node = Node2D.new()
	buildings_node.name = "Buildings"
	buildings_node.y_sort_enabled = true
	buildings_node.z_index = 9
	add_child(buildings_node)

	for bdata in map_gen.building_positions:
		_spawn_building_visual(bdata)

func _spawn_building_visual(bdata: Dictionary) -> void:
	var building := Node2D.new()
	building.global_position = bdata["pos"]
	building.z_index = 9
	building.set_meta("building_data", bdata)

	# Building emoji (large)
	var emoji_node = _create_emoji_node_large(bdata["emoji"], 48, Vector2(64, 64), Vector2(-32, -40))
	building.add_child(emoji_node)

	# Building name label
	var name_lbl := Label.new()
	var bname: String = bdata["building_name"]
	name_lbl.text = bname.capitalize()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(-40, 20)
	name_lbl.size = Vector2(80, 20)
	var name_ls := LabelSettings.new()
	name_ls.font_size = 10
	name_ls.font_color = Color(0.8, 0.75, 0.6)
	name_ls.outline_size = 1
	name_ls.outline_color = Color(0, 0, 0)
	name_lbl.label_settings = name_ls
	building.add_child(name_lbl)

	# "Press E to Enter" hint (visible when player is nearby)
	var hint_lbl := Label.new()
	hint_lbl.text = "[E] Enter"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.position = Vector2(-30, 34)
	hint_lbl.size = Vector2(60, 16)
	hint_lbl.visible = false
	var hint_ls := LabelSettings.new()
	hint_ls.font_size = 9
	hint_ls.font_color = Color(0.5, 1.0, 0.5)
	hint_ls.outline_size = 1
	hint_ls.outline_color = Color(0, 0, 0)
	hint_lbl.label_settings = hint_ls
	building.add_child(hint_lbl)
	building.set_meta("hint_label", hint_lbl)

	# Glow light
	var light := PointLight2D.new()
	light.texture = GameData.point_light_texture
	light.texture_scale = 2.5
	light.energy = 0.5
	light.color = Color(0.9, 0.7, 0.4)
	light.shadow_enabled = false
	building.add_child(light)

	buildings_node.add_child(building)

func _check_building_entry(delta: float) -> void:
	if not is_instance_valid(player) or not player.is_alive:
		return
	if ss_controller and ss_controller.is_sidescroller_mode():
		return

	building_entry_check_timer -= delta
	if building_entry_check_timer > 0:
		return
	building_entry_check_timer = 0.1

	var _nearest_building: Node2D = null
	var nearest_dist: float = 999999.0

	for building in buildings_node.get_children():
		if not is_instance_valid(building):
			continue
		var dist: float = player.global_position.distance_to(building.global_position)

		# Show/hide entry hint
		var hint: Label = building.get_meta("hint_label", null)
		if hint:
			hint.visible = dist < 80.0

		if dist < nearest_dist:
			nearest_dist = dist


func _try_enter_nearest_building() -> void:
	if not is_instance_valid(player) or not player.is_alive:
		return
	if ss_controller and ss_controller.is_sidescroller_mode():
		return

	for building in buildings_node.get_children():
		if not is_instance_valid(building):
			continue
		var dist: float = player.global_position.distance_to(building.global_position)
		if dist < 80.0:
			var bdata: Dictionary = building.get_meta("building_data", {})
			if not bdata.is_empty():
				_enter_building(bdata)
				return

func _enter_building(bdata: Dictionary) -> void:
	if not ss_controller or ss_controller.is_sidescroller_mode():
		return

	if hud.has_method("show_notification"):
		var bname: String = bdata.get("building_name", "building")
		hud.show_notification("Entering " + bname.capitalize() + "...", Color(0.8, 0.7, 0.5))

	ss_controller.enter_building(bdata)

func _check_ss_exit() -> void:
	if not ss_controller or not ss_controller.is_sidescroller_mode():
		return
	if not is_instance_valid(player) or not player.is_alive:
		return

	# Check if player is near exit or entry door
	if ss_controller.check_exit_proximity(player.global_position):
		# Show hint
		if hud.has_method("show_tutorial_hint"):
			GameSystems.show_tutorial("ss_exit", "Press [E] to exit building", 2.0)
	elif ss_controller.check_entry_door_proximity(player.global_position):
		if hud.has_method("show_tutorial_hint"):
			GameSystems.show_tutorial("ss_exit", "Press [E] to exit building", 2.0)

func _on_entered_building(building_data: Dictionary) -> void:
	var bname: String = building_data.get("building_name", "building")
	if hud.has_method("show_room_name"):
		hud.show_room_name(bname.capitalize() + " Interior")
	if hud.has_method("show_notification"):
		hud.show_notification("Side-view mode - WASD + Mouse to fight!", Color(0.6, 0.9, 0.6))

func _on_exited_building() -> void:
	if hud.has_method("show_notification"):
		hud.show_notification("Returned to dungeon", Color(0.7, 0.7, 0.8))
	if hud.has_method("show_room_name"):
		var room_type: String = map_gen.get_room_type(current_room_index) if current_room_index >= 0 else "dungeon"
		hud.show_room_name(room_type)

# ===== MINI-GAMES =====

func _setup_minigames() -> void:
	minigame_manager = Node.new()
	minigame_manager.set_script(MinigameManagerScript)
	minigame_manager.player_ref = player
	minigame_manager.hud_ref = hud
	add_child(minigame_manager)

func _place_game_corners() -> void:
	game_corners_node = Node2D.new()
	game_corners_node.name = "GameCorners"
	game_corners_node.y_sort_enabled = true
	game_corners_node.z_index = 8
	add_child(game_corners_node)

	# Place 2-4 game corners in larger rooms
	var available_rooms: Array[int] = []
	for i in range(1, map_gen.rooms.size()):
		var room = map_gen.rooms[i]
		var area: int = int(room.size.x * room.size.y)
		if area >= 50:
			available_rooms.append(i)

	available_rooms.shuffle()
	var num_corners: int = mini(randi_range(2, 4), available_rooms.size())

	for c in range(num_corners):
		var room_idx: int = available_rooms[c]
		var room = map_gen.rooms[room_idx]
		var corner_x: int = room.position.x + int(room.size.x / 2.0)
		var corner_y: int = room.position.y + int(room.size.y / 2.0)

		var world_pos := Vector2(
			corner_x * 64 + 32,
			corner_y * 64 + 32
		)

		_spawn_game_corner(world_pos)

func _spawn_game_corner(pos: Vector2) -> void:
	var corner := Node2D.new()
	corner.global_position = pos
	corner.z_index = 8
	corner.set_meta("is_game_corner", true)

	# Game corner emoji (arcade cabinet)
	var emoji_node = _create_emoji_node_large("🕹️", 48, Vector2(64, 64), Vector2(-32, -40))
	corner.add_child(emoji_node)

	# "Press E to Play" hint
	var hint_lbl := Label.new()
	hint_lbl.text = "[E] Play"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.position = Vector2(-30, 34)
	hint_lbl.size = Vector2(60, 16)
	hint_lbl.visible = false
	var hint_ls := LabelSettings.new()
	hint_ls.font_size = 9
	hint_ls.font_color = Color(1.0, 0.8, 0.3)
	hint_ls.outline_size = 1
	hint_ls.outline_color = Color(0, 0, 0)
	hint_lbl.label_settings = hint_ls
	corner.add_child(hint_lbl)
	corner.set_meta("hint_label", hint_lbl)

	# Glow light
	var light := PointLight2D.new()
	light.texture = GameData.point_light_texture
	light.texture_scale = 2.0
	light.energy = 0.6
	light.color = Color(0.8, 0.6, 1.0)
	light.shadow_enabled = false
	corner.add_child(light)

	game_corners_node.add_child(corner)

func _try_interact_game_corner() -> bool:
	if not is_instance_valid(player) or not player.is_alive:
		return false
	if not game_corners_node:
		return false

	for corner in game_corners_node.get_children():
		if not is_instance_valid(corner):
			continue
		var dist: float = player.global_position.distance_to(corner.global_position)

		# Show/hide hint
		var hint: Label = corner.get_meta("hint_label", null)
		if hint:
			hint.visible = dist < 80.0

		if dist < 80.0:
			if minigame_manager and minigame_manager.has_method("start_minigame"):
				var game_type = minigame_manager.get_minigame_for_race(player.race)
				minigame_manager.start_minigame(game_type)
			return true

	return false

# ===== PAUSE MENU =====

func _setup_pause_menu() -> void:
	pause_menu = CanvasLayer.new()
	pause_menu.set_script(PauseMenuScript)
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	pause_menu.quit_to_menu.connect(_return_to_menu)

# ===== INVENTORY SYSTEM =====

func _setup_inventory() -> void:
	# Create inventory manager
	inventory_mgr = Node.new()
	inventory_mgr.set_script(InventoryManagerScript)
	inventory_mgr.name = "InventoryManager"
	add_child(inventory_mgr)
	
	# Create inventory UI
	inventory_ui = CanvasLayer.new()
	inventory_ui.set_script(InventoryUIScript)
	inventory_ui.name = "InventoryUI"
	inventory_ui.add_to_group("inventory_ui")
	add_child(inventory_ui)
	inventory_ui.set_inventory(inventory_mgr)
	
	# Connect inventory item use to player effects
	if inventory_mgr.has_signal("item_used"):
		inventory_mgr.item_used.connect(_on_inventory_item_used)

func _on_inventory_item_used(item: Dictionary) -> void:
	if not is_instance_valid(player):
		return
	var effect: String = item.get("effect", "")
	var val: float = item.get("value", 0.0)
	match effect:
		"heal":
			if player.has_method("heal"):
				player.heal(val, false)
		"mana":
			if player.has_method("restore_mana"):
				player.restore_mana(val)
		"stamina":
			if "stamina" in player:
				player.stamina = minf(player.stamina + val, player.max_stamina)
		"cure_poison":
			if "is_poisoned" in player:
				player.is_poisoned = false
		"speed_buff":
			if "run_speed" in player:
				player.run_speed *= val
		"damage_buff":
			if "melee_damage" in player:
				player.melee_damage *= val
				player.ranged_damage *= val
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Used: " + item.get("name", "item"), Color(0.3, 0.8, 1.0))

# ===== STARSHIP SYSTEMS =====

func _setup_starship() -> void:
	is_on_starship = true
	
	# Generate starship map
	starship_map = StarshipMapScript.new()
	starship_map.generate()
	
	# Dark ambient for starship interior
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.12, 0.12, 0.18)
	add_child(canvas_modulate)
	
	# Render starship
	starship_renderer = Node2D.new()
	starship_renderer.set_script(StarshipRendererScript)
	starship_renderer.name = "StarshipRenderer"
	starship_renderer.z_index = 0
	add_child(starship_renderer)
	starship_renderer.set_map_data(starship_map)
	
	# Entities node (for player)
	entities_node = Node2D.new()
	entities_node.name = "Entities"
	entities_node.y_sort_enabled = true
	entities_node.z_index = 10
	add_child(entities_node)
	
	# Items node
	items_node = Node2D.new()
	items_node.name = "Items"
	items_node.y_sort_enabled = true
	items_node.z_index = 5
	add_child(items_node)
	
	# Lore node
	lore_node = Node2D.new()
	lore_node.name = "Lore"
	lore_node.y_sort_enabled = true
	lore_node.z_index = 6
	add_child(lore_node)
	
	# VFX
	vfx = Node2D.new()
	vfx.set_script(VFXManagerScript)
	vfx.add_to_group("vfx")
	vfx.z_index = 12
	vfx.set("game_ref", self)
	add_child(vfx)
	
	# Camera
	camera = Camera2D.new()
	camera.name = "MainCamera"
	var cam_zoom: float = GameSystems.get_setting("camera_zoom")
	camera.zoom = Vector2(cam_zoom, cam_zoom)
	camera_target_zoom = camera.zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = GameSystems.get_setting("camera_smoothing")
	add_child(camera)
	
	# Place starship lights
	_place_starship_lights()
	
	# Place NPCs
	_place_starship_npcs()
	
	# Place starship items
	_place_starship_items()
	
	# Place starship interactables
	_place_starship_interactables()
	
	# Place starship lore
	_place_starship_lore()
	
	# Dialogue UI
	starship_dialogue = CanvasLayer.new()
	starship_dialogue.set_script(StarshipDialogueScript)
	starship_dialogue.name = "StarshipDialogue"
	add_child(starship_dialogue)

func _spawn_player_on_starship() -> void:
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.race = GameData.selected_race
	player.player_class = GameData.selected_class
	player.global_position = starship_map.spawn_position
	player.add_to_group("players")
	entities_node.add_child(player)
	
	player.player_attacked.connect(_on_player_attack)
	player.hp_changed.connect(_on_hp_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.shields_changed.connect(_on_shields_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.rage_changed.connect(_on_rage_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.gold_changed.connect(_on_gold_changed)
	player.slot_changed.connect(_on_slot_changed)
	player.player_died.connect(_on_player_died)
	player.screen_shake.connect(_on_screen_shake_request)
	player.damage_direction.connect(_on_damage_direction)
	
	camera.global_position = player.global_position

func _place_starship_lights() -> void:
	for light_pos in starship_map.light_positions:
		var light := PointLight2D.new()
		light.texture = GameData.point_light_texture
		light.texture_scale = 4.0
		light.energy = 0.7
		light.color = Color(0.7, 0.75, 1.0)  # Cool sci-fi blue-white
		light.shadow_enabled = GameSystems.get_setting("shadows_enabled")
		light.global_position = light_pos
		add_child(light)

func _place_starship_npcs() -> void:
	starship_npc_node = Node2D.new()
	starship_npc_node.name = "StarshipNPCs"
	starship_npc_node.z_index = 10
	add_child(starship_npc_node)
	
	for npc_data in starship_map.npc_positions:
		var npc := Area2D.new()
		npc.set_script(StarshipNpcScript)
		npc.name = "NPC_" + npc_data.get("name", "Unknown").replace(" ", "_")
		starship_npc_node.add_child(npc)
		npc.setup(npc_data)
		npc.npc_interacted.connect(_on_npc_interacted)
		starship_npcs.append(npc)

func _place_starship_items() -> void:
	for item_data in starship_map.item_positions:
		var item_node := Area2D.new()
		item_node.set_script(ItemScript)
		item_node.global_position = item_data["position"]
		items_node.add_child(item_node)
		item_node.setup_item(item_data["type"])

func _place_starship_interactables() -> void:
	starship_interactables_node = Node2D.new()
	starship_interactables_node.name = "StarshipInteractables"
	starship_interactables_node.z_index = 8
	add_child(starship_interactables_node)
	
	for inter_data in starship_map.interactable_positions:
		var inter_node := Node2D.new()
		inter_node.global_position = inter_data["position"]
		inter_node.set_meta("inter_data", inter_data)
		
		# Emoji label
		var emoji_node = _create_emoji_node(inter_data.get("emoji", "?"), 18, Vector2(24, 24), Vector2(-12, -16))
		inter_node.add_child(emoji_node)
		
		# Name label
		var name_label := Label.new()
		name_label.text = inter_data.get("name", "")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-40, 8)
		name_label.size = Vector2(80, 16)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		name_label.add_theme_font_size_override("font_size", 8)
		inter_node.add_child(name_label)
		
		# Interaction prompt (hidden)
		var prompt := Label.new()
		prompt.text = "[E]"
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.position = Vector2(-10, -30)
		prompt.size = Vector2(20, 14)
		prompt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		prompt.add_theme_font_size_override("font_size", 9)
		prompt.visible = false
		inter_node.add_child(prompt)
		inter_node.set_meta("prompt_label", prompt)
		
		starship_interactables_node.add_child(inter_node)

func _place_starship_lore() -> void:
	for lore_data in starship_map.lore_positions:
		var pickup := Area2D.new()
		pickup.set_script(LorePickupScript)
		pickup.global_position = lore_data["position"]
		if pickup.has_method("setup_random"):
			pickup.setup_random()
		pickup.lore_picked_up.connect(_on_lore_picked_up)
		lore_node.add_child(pickup)

func _try_starship_interaction() -> void:
	if not is_instance_valid(player):
		return
	
	# Check NPCs first
	for npc in starship_npcs:
		if not is_instance_valid(npc):
			continue
		if npc.is_player_nearby:
			npc.interact()
			return
	
	# Check interactables
	if starship_interactables_node:
		for inter_node in starship_interactables_node.get_children():
			if not is_instance_valid(inter_node):
				continue
			var dist: float = player.global_position.distance_to(inter_node.global_position)
			if dist < 80.0:
				var inter_data: Dictionary = inter_node.get_meta("inter_data", {})
				_handle_starship_interactable(inter_data)
				return

func _handle_starship_interactable(data: Dictionary) -> void:
	var action: String = data.get("action", "")
	match action:
		"deploy_to_surface":
			_deploy_to_dungeon()
		"full_heal":
			if is_instance_valid(player) and player.has_method("heal"):
				player.hp = player.max_hp
				if hud and hud.has_method("show_notification"):
					hud.show_notification("Fully healed!", Color(0.3, 1.0, 0.5))
		"save_game":
			GameSystems.save_stats()
			if hud and hud.has_method("show_notification"):
				hud.show_notification("Game saved!", Color(0.5, 0.8, 1.0))
		"eat_food":
			if is_instance_valid(player) and player.has_method("heal"):
				player.heal(20.0, false)
				if hud and hud.has_method("show_notification"):
					hud.show_notification("Ate a meal. +20 HP", Color(0.3, 1.0, 0.5))
		"equip_weapons":
			# Give player a random weapon
			if inventory_mgr:
				var weapon: Dictionary = inventory_mgr.generate_random_item(GameSystems.player_level, "uncommon")
				if inventory_mgr.add_item(weapon):
					if hud and hud.has_method("show_notification"):
						hud.show_notification("Found: " + weapon.get("name", "item"), Color(0.3, 1.0, 0.3))
		"equip_armor":
			# Give player random armor
			if inventory_mgr:
				var armor: Dictionary = inventory_mgr.generate_random_item(GameSystems.player_level, "common")
				if inventory_mgr.add_item(armor):
					if hud and hud.has_method("show_notification"):
						hud.show_notification("Found: " + armor.get("name", "item"), Color(0.3, 1.0, 0.3))
		"loot_crate":
			if inventory_mgr:
				var loot: Dictionary = inventory_mgr.generate_random_item(GameSystems.player_level)
				if inventory_mgr.add_item(loot):
					if hud and hud.has_method("show_notification"):
						hud.show_notification("Looted: " + loot.get("name", "item"), Color(1.0, 0.85, 0.3))
		"view_map", "comms", "research":
			if hud and hud.has_method("show_notification"):
				hud.show_notification(data.get("name", "Console") + " accessed.", Color(0.5, 0.7, 1.0))

func _on_npc_interacted(npc_data: Dictionary) -> void:
	if starship_dialogue:
		starship_dialogue.open_dialogue(npc_data)

func _deploy_to_dungeon() -> void:
	if hud and hud.has_method("show_notification"):
		hud.show_notification("DEPLOYING TO SURFACE...", Color(1.0, 0.5, 0.2))
	
	# Cleanup starship
	is_on_starship = false
	
	if starship_renderer:
		starship_renderer.queue_free()
		starship_renderer = null
	if starship_npc_node:
		starship_npc_node.queue_free()
		starship_npc_node = null
	if starship_interactables_node:
		starship_interactables_node.queue_free()
		starship_interactables_node = null
	starship_npcs.clear()
	
	# Remove starship items and lore
	for child in items_node.get_children():
		child.queue_free()
	for child in lore_node.get_children():
		child.queue_free()
	
	# Remove player from entities temporarily
	if is_instance_valid(player):
		entities_node.remove_child(player)
	
	# Remove starship lights
	for child in get_children():
		if child is PointLight2D:
			child.queue_free()
	
	# Remove old entities/nodes
	if entities_node:
		entities_node.queue_free()
	if items_node:
		items_node.queue_free()
	if lore_node:
		lore_node.queue_free()
	if vfx:
		vfx.queue_free()
	
	# Change ambient color to dungeon
	if canvas_modulate:
		canvas_modulate.color = Color(0.08, 0.07, 0.1)
	
	# Generate dungeon
	_generate_map()
	_build_scene_tree()
	
	# Place player in dungeon
	if is_instance_valid(player):
		player.global_position = map_gen.spawn_position
		entities_node.add_child(player)
	
	camera.global_position = player.global_position
	
	# Setup vertical dungeon systems (2.5D multi-floor exploration)
	_setup_vertical_dungeon()
	
	# Setup dungeon content
	_place_torches()
	_place_items()
	_place_destructibles()
	_place_traps()
	_place_chests()
	_place_ambient_particles()
	_place_safespace()
	_place_lore_pickups()
	_place_buildings()
	_place_game_corners()
	_place_fountains()
	_place_altars()
	_place_decorations()
	_place_dead_end_treasures()
	_place_themed_items()
	_setup_sidescroller()
	_setup_minigames()
	
	GameSystems.show_tutorial("dungeon", "You've landed. Clear the dungeon! Kill enemies, find loot, survive.", 6.0)

# ===== IMPROVEMENT IMPLEMENTATIONS =====

# Improvement #1157: Item pickup magnet - pull nearby items toward player
func _update_item_magnet(delta: float) -> void:
	if not items_node or not is_instance_valid(player):
		return
	if not GameSystems.get_setting("auto_pickup"):
		return
	for item in items_node.get_children():
		if not is_instance_valid(item):
			continue
		var dist: float = player.global_position.distance_to(item.global_position)
		if dist < item_magnet_range and dist > 10.0:
			var dir: Vector2 = (player.global_position - item.global_position).normalized()
			item.global_position += dir * 200.0 * delta

# Improvement #1131: Low health screen edge warning
func _update_low_health_warning(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var hp_pct: float = player.hp / maxf(player.max_hp, 1.0)
	if hp_pct < 0.25:
		low_health_pulse += delta * 4.0
		var alpha := (sin(low_health_pulse) + 1.0) * 0.15 * (1.0 - hp_pct * 4.0)
		if low_health_overlay:
			low_health_overlay.modulate.a = alpha
			low_health_overlay.visible = true
	else:
		low_health_pulse = 0.0
		if low_health_overlay:
			low_health_overlay.visible = false

func _setup_improvement_systems() -> void:
	# Create quality of life system
	var qol = Node.new()
	qol.set_script(QualityOfLifeScript)
	qol.name = "QualityOfLife"
	add_child(qol)
	quality_of_life = qol as QualityOfLifeImprovements
	
	# Create advanced enemy AI system
	var aea = Node.new()
	aea.set_script(AdvancedEnemyAIScript)
	aea.name = "AdvancedEnemyAI"
	add_child(aea)
	advanced_enemy_ai = aea as AdvancedEnemyAI
	
	# Create visual polish system
	var vp = Node.new()
	vp.set_script(VisualPolishScript)
	vp.name = "VisualPolish"
	add_child(vp)
	visual_polish = vp as VisualPolish
	
	# Create performance optimization system
	var po = Node.new()
	po.set_script(PerformanceOptimizationScript)
	po.name = "PerformanceOptimization"
	add_child(po)
	performance_optimization = po as PerformanceOptimization

func _setup_starship_skills() -> void:
	# Create currency system
	var cs = Node.new()
	cs.set_script(CurrencySystemScript)
	cs.name = "CurrencySystem"
	add_child(cs)
	currency_system = cs as CurrencySystem
	
	# Create repair skill
	var rs = Node.new()
	rs.set_script(ItemRepairSkillScript)
	rs.name = "RepairSkill"
	add_child(rs)
	repair_skill = rs as ItemRepairSkill
	
	# Create botany skill
	var bs = Node.new()
	bs.set_script(BotanySkillScript)
	bs.name = "BotanySkill"
	add_child(bs)
	botany_skill = bs as BotanySkill
	
	# Create personal quarters
	var pq = Node2D.new()
	pq.set_script(PersonalQuartersScript)
	pq.name = "PersonalQuarters"
	add_child(pq)
	personal_quarters = pq as PersonalQuarters
	personal_quarters.set_references(botany_skill, repair_skill, currency_system)
	
	# Create quarters UI
	var qui = CanvasLayer.new()
	qui.set_script(QuartersUIScript)
	qui.name = "QuartersUI"
	add_child(qui)
	quarters_ui = qui as QuartersUI
	quarters_ui.set_references(botany_skill, repair_skill, currency_system, personal_quarters)

func _setup_dialogue_systems() -> void:
	# Create dialogue manager
	var dm = Node.new()
	dm.set_script(DialogueManagerScript)
	dm.name = "DialogueManager"
	add_child(dm)
	dialogue_manager = dm as DialogueManager
	
	# Create combat dialogue system
	var cd = Node.new()
	cd.set_script(CombatDialogueScript)
	cd.name = "CombatDialogue"
	add_child(cd)
	combat_dialogue = cd as CombatDialogueSystem
	if is_instance_valid(player):
		combat_dialogue.set_references(dialogue_manager, self, player)
	
	# Create exploration dialogue system
	var ed = Node.new()
	ed.set_script(ExplorationDialogueScript)
	ed.name = "ExplorationDialogue"
	add_child(ed)
	exploration_dialogue = ed as ExplorationDialogueSystem
	if is_instance_valid(player):
		exploration_dialogue.set_references(dialogue_manager, self, player)
	
	# Create enemy conversation system
	var ec = Node.new()
	ec.set_script(EnemyConversationScript)
	ec.name = "EnemyConversation"
	add_child(ec)
	enemy_conversation = ec as EnemyConversationSystem
	enemy_conversation.set_references(dialogue_manager, self)

func _setup_low_health_overlay() -> void:
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 90
	overlay_layer.name = "LowHealthOverlay"
	add_child(overlay_layer)
	low_health_overlay = ColorRect.new()
	low_health_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	low_health_overlay.color = Color(0.8, 0.05, 0.05, 1.0)
	low_health_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_health_overlay.visible = false
	overlay_layer.add_child(low_health_overlay)

# Enemy separation forces - prevent overlapping
func _apply_enemy_separation(delta: float) -> void:
	for i in range(enemies.size()):
		if not is_instance_valid(enemies[i]) or not enemies[i].is_alive:
			continue
		var enemy_a = enemies[i]
		var separation := Vector2.ZERO
		var neighbor_count := 0
		
		for j in range(enemies.size()):
			if i == j or not is_instance_valid(enemies[j]) or not enemies[j].is_alive:
				continue
			var enemy_b = enemies[j]
			var dist: float = enemy_a.global_position.distance_to(enemy_b.global_position)
			
			if dist < enemy_separation_range and dist > 1.0:
				var push_dir: Vector2 = (enemy_a.global_position - enemy_b.global_position).normalized()
				var push_force: float = (1.0 - dist / enemy_separation_range) * enemy_separation_force
				separation += push_dir * push_force
				neighbor_count += 1
		
		if neighbor_count > 0:
			separation /= neighbor_count
			if enemy_a.has_method("apply_separation"):
				enemy_a.apply_separation(separation * delta)
			else:
				enemy_a.global_position += separation * delta

# Persistent gore management
func _add_gore_decal(pos: Vector2, size: float, color: Color) -> void:
	gore_decals.append({
		"pos": pos,
		"size": size,
		"color": color,
		"age": 0.0,
		"max_age": 300.0
	})
	
	# Remove oldest gore if we exceed the limit
	if gore_decals.size() > max_gore_decals:
		gore_decals.remove_at(0)

func _update_gore_decals(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(gore_decals.size()):
		gore_decals[i]["age"] += delta
		if gore_decals[i]["age"] >= gore_decals[i]["max_age"]:
			to_remove.append(i)
	
	to_remove.reverse()
	for idx in to_remove:
		gore_decals.remove_at(idx)

func _draw_gore_decals() -> void:
	# This is called from _process to render persistent gore
	if gore_decals.is_empty():
		return
	
	for decal in gore_decals:
		var alpha: float = 1.0 - (decal["age"] / decal["max_age"]) * 0.7
		var col: Color = decal["color"]
		col.a = alpha
		draw_circle(decal["pos"], decal["size"], col)

func _setup_vertical_dungeon() -> void:
	if not is_instance_valid(player):
		return
	
	# Create vertical dungeon generator
	vertical_dungeon = VerticalDungeonGenerator.new()
	vertical_dungeon.max_floors = max_floors
	vertical_dungeon.generate_vertical_dungeon(randi())
	add_child(vertical_dungeon)
	
	# Create vertical renderer for depth effects
	vertical_renderer = VerticalRenderer.new()
	vertical_renderer.set_dungeon(vertical_dungeon)
	add_child(vertical_renderer)
	
	# Create gravity system
	gravity_system = GravitySystem.new()
	gravity_system.set_references(player, vertical_dungeon)
	add_child(gravity_system)
	
	# Create climbing system
	climbing_system = ClimbingSystem.new()
	climbing_system.set_references(player, vertical_dungeon)
	add_child(climbing_system)
	
	# Setup vertical camera
	if camera:
		var v_cam = VerticalCameraScript.new()
		v_cam.set_references(player, vertical_dungeon, gravity_system)
		add_child(v_cam)
	
	current_floor = 0
	GameSystems.show_tutorial("vertical", "Use SPACE to jump and climb stairs/ladders. Navigate multiple floors!", 6.0)

func _update_vertical_dungeon(delta: float) -> void:
	if not gravity_system or not climbing_system or not vertical_renderer:
		return
	
	# Update gravity
	gravity_system.update_gravity(delta)
	
	# Update climbing
	climbing_system.update_climb(delta)
	
	# Update visibility
	vertical_renderer.update_visible_floors(current_floor, 2)
	
	# Handle jumping input
	if Input.is_action_just_pressed("jump"):
		if gravity_system.is_grounded and not climbing_system.is_climbing():
			gravity_system.jump()
	
	# Handle climbing input
	if climbing_system.is_climbing():
		var climb_input = 0
		if Input.is_action_pressed("move_up"):
			climb_input = 1
		elif Input.is_action_pressed("move_down"):
			climb_input = -1
		
		if climb_input != 0:
			climbing_system.climb_direction = climb_input
		
		if Input.is_action_just_pressed("interact"):
			climbing_system.stop_climb()
	else:
		if vertical_dungeon:
			var climbables = vertical_dungeon.get_climbables_on_floor(current_floor)
			for climbable in climbables:
				var dist = player.global_position.distance_to(climbable["position"])
				if dist < 100.0:
					if Input.is_action_just_pressed("jump"):
						climbing_system.start_climb(climbable, 1)
						break

func _on_player_floor_changed(new_floor: int) -> void:
	current_floor = new_floor
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Floor %d" % (new_floor + 1), Color(0.7, 0.9, 1.0))

func _update_starship_interactable_prompts() -> void:
	if not is_on_starship or not starship_interactables_node or not is_instance_valid(player):
		return
	for inter_node in starship_interactables_node.get_children():
		if not is_instance_valid(inter_node):
			continue
		var dist: float = player.global_position.distance_to(inter_node.global_position)
		var prompt: Label = inter_node.get_meta("prompt_label", null)
		if prompt:
			prompt.visible = dist < 80.0
