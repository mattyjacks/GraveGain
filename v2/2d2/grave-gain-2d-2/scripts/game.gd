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

func _ready() -> void:
	if not GameData.point_light_texture:
		GameData.create_light_textures()

	GameSystems.reset_mission()

	_generate_map()
	_build_scene_tree()
	_spawn_player()
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
	_setup_hud()
	_setup_lore_ui()
	_setup_sidescroller()
	_setup_minigames()

	_connect_game_signals()
	_setup_touch_controls()

	GameSystems.show_tutorial("movement", "WASD to move, Shift to sprint, Space to dodge", 6.0)

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

		var torch_emoji := Label.new()
		torch_emoji.text = "\U0001F525"
		torch_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		torch_emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		torch_emoji.position = Vector2(-10, -14)
		torch_emoji.size = Vector2(20, 20)
		var ts := LabelSettings.new()
		ts.font = GameData.emoji_font
		ts.font_size = 16
		torch_emoji.label_settings = ts
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
	camera.global_position = player.global_position + camera_punch
	# Smooth zoom transitions
	camera.zoom = camera.zoom.lerp(camera_target_zoom, camera_zoom_speed * delta)

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
	_update_hud(delta)
	_update_torch_flicker(delta)

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

		var hp_before: float = enemy.hp
		enemy.take_damage(actual_dmg, origin)
		hit_count += 1

		# VFX: blood burst and hit flash on impact
		var hit_dir := (enemy.global_position - origin).normalized()
		if vfx:
			vfx.spawn_hit_effect(enemy.global_position, actual_dmg, is_crit, hit_dir)

		# Track overkill
		if not enemy.is_alive:
			total_overkill += maxf(actual_dmg - hp_before, 0.0)

		if stagger > 0:
			enemy.stagger_timer = maxf(enemy.stagger_timer, stagger)

		# Register hit with combo system
		GameSystems.register_hit()
		GameSystems.track("total_damage_dealt", actual_dmg)
		if is_crit:
			GameSystems.track("critical_hits")

		if hud.has_method("spawn_damage_number"):
			hud.spawn_damage_number(enemy.global_position + Vector2(0, -20), actual_dmg, is_crit)
		if hud.has_method("show_hit_marker"):
			hud.show_hit_marker(is_crit)

	# VFX: melee swing trail
	if vfx:
		var trail_color := Color(1.0, 0.9, 0.5, 0.7) if not is_crit else Color(1.0, 0.4, 0.2, 0.9)
		vfx.spawn_attack_trail(origin, angle, arc, rng_val, trail_color)

	# Also check destructibles in melee range
	_check_melee_destructibles(origin, angle, arc, rng_val, dmg)

	if hit_count > 0 and player.is_alive:
		# Lifesteal: 2 temp HP per hit + overkill bonus
		var lifesteal := hit_count * 2.0 + total_overkill * 0.1
		player.add_temp_hp(lifesteal)
		_on_screen_shake_request(0.15 * hit_count, 0.1)
		# Camera punch toward hit direction
		if GameSystems.get_setting("camera_punch"):
			camera_punch = direction * (3.0 + hit_count * 1.5)
		# Hit pause on crits for impact feel
		if is_crit and GameSystems.get_setting("hit_pause_enabled"):
			hit_pause_timer = 0.04

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
	total_kills += 1
	if is_instance_valid(player) and player.is_alive:
		player.add_gold(data["gold"])
		player.add_xp(data["xp"])
		player.total_kills = total_kills

	# Track with GameSystems
	var enemy_name: String = data.get("name", "Enemy")
	var weapon := "melee" if data.get("killed_by_melee", true) else "ranged"
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

	if randf() < 0.15:
		var drop_roll := randf()
		var drop_type: String
		if drop_roll < 0.4:
			drop_type = "gold_coin"
		elif drop_roll < 0.6:
			drop_type = "ammo_small"
		elif drop_roll < 0.75:
			drop_type = "health_potion"
		elif drop_roll < 0.85:
			drop_type = "artifact_ring"
		else:
			drop_type = "gold_bar"
		_spawn_item(data["position"], drop_type)

	if randf() < 0.08:
		var food_keys := GameData.food_defs.keys()
		if not food_keys.is_empty():
			var food_type: String = food_keys.pick_random()
			_spawn_food(data["position"] + Vector2(randf_range(-20, 20), randf_range(-20, 20)), food_type)

func _on_enemy_attack(target: CharacterBody2D, dmg: float, from_pos: Vector2) -> void:
	if target == player and player.is_alive:
		player.take_damage(dmg, from_pos)
		GameSystems.track("total_damage_taken", dmg)
		_on_screen_shake_request(0.2, 0.15)
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
	Engine.time_scale = 1.0
	GameSystems.track("total_deaths")
	_on_screen_shake_request(1.0, 0.8)
	if hud.has_method("show_notification"):
		hud.show_notification("YOU DIED - Mission Failed", Color(1, 0.2, 0.2))
	# VFX: player death gore explosion
	if vfx:
		vfx.spawn_gore_explosion(player.global_position, Color(0.6, 0.05, 0.05))
		vfx.spawn_blood_burst(player.global_position, Vector2.UP, 20, 180.0)
		vfx.spawn_blood_splat(player.global_position, 3.0)
	if GameSystems.get_setting("hit_pause_enabled"):
		hit_pause_timer = 0.08

	var timer := get_tree().create_timer(3.0)
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

	minimap_update_timer -= delta
	if minimap_update_timer <= 0:
		minimap_update_timer = 0.5
		var enemy_positions: Array[Vector2] = []
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive:
				enemy_positions.append(enemy.global_position)
		if hud.has_method("update_minimap"):
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

	var lbl := Label.new()
	lbl.text = emoji_map.get(dtype, "\U0001F4E6")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-12, -16)
	lbl.size = Vector2(24, 24)
	var ls := LabelSettings.new()
	ls.font = GameData.emoji_font
	ls.font_size = 20
	lbl.label_settings = ls
	destr.add_child(lbl)

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
	GameSystems.screen_shake_requested.connect(_on_screen_shake_request)
	GameSystems.damage_indicator_requested.connect(_on_damage_direction)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# If in sidescroller, exit building first
			if ss_controller and ss_controller.is_sidescroller_mode():
				ss_controller.exit_building()
				return
			_return_to_menu()
		elif event.keycode == KEY_I or event.keycode == KEY_TAB:
			if lore_collection and not lore_collection.is_open:
				lore_collection.open_collection(tts_manager, lore_reader)
		elif event.keycode == KEY_E or event.keycode == KEY_F:
			if ss_controller and ss_controller.is_sidescroller_mode():
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
	ss_controller.player_ref = player
	ss_controller.camera_ref = camera
	ss_controller.game_ref = self
	ss_controller.top_down_nodes = [
		map_renderer, entities_node, projectiles_node, items_node,
		torches_node, lore_node, destructibles_node, traps_node,
		chests_node, particles_node, vfx,
	]
	if buildings_node:
		ss_controller.top_down_nodes.append(buildings_node)
	if safespace_visual:
		ss_controller.top_down_nodes.append(safespace_visual)
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
	var emoji_lbl := Label.new()
	emoji_lbl.text = bdata["emoji"]
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.position = Vector2(-32, -40)
	emoji_lbl.size = Vector2(64, 64)
	var ls := LabelSettings.new()
	ls.font = GameData.emoji_font_large
	ls.font_size = 48
	emoji_lbl.label_settings = ls
	building.add_child(emoji_lbl)

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

	var nearest_building: Node2D = null
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
			nearest_building = building


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
	var num_corners: int = mini(rng.randi_range(2, 4), available_rooms.size())

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
	var emoji_lbl := Label.new()
	emoji_lbl.text = "🕹️"
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.position = Vector2(-32, -40)
	emoji_lbl.size = Vector2(64, 64)
	var ls := LabelSettings.new()
	ls.font = GameData.emoji_font_large
	ls.font_size = 48
	emoji_lbl.label_settings = ls
	corner.add_child(emoji_lbl)

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
