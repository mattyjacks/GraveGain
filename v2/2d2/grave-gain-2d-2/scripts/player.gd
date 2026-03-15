extends CharacterBody2D

signal hp_changed(current_hp: float, temp_hp: float, max_hp: float)
signal stamina_changed(current: float, max_val: float)
signal shields_changed(current: float, max_val: float)
signal mana_changed(current: float, max_val: float)
signal rage_changed(current: float, max_val: float)
signal ammo_changed(current: int, max_val: int)
signal gold_changed(amount: int)
signal slot_changed(slot: int)
signal player_attacked(attack_data: Dictionary)
signal player_died()
signal player_wounded()
signal kill_credit_earned(amount: int)
signal screen_shake(intensity: float, duration: float)
signal damage_direction(angle: float)
signal dodge_performed()
signal combo_hit(count: int)

var race: int = GameData.Race.HUMAN
var player_class: int = GameData.PlayerClass.DPS

var max_hp: float = 100.0
var hp: float = 100.0
var temp_hp: float = 0.0
var hp_regen: float = 1.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var stamina_regen_rate: float = 15.0
var stamina_regen_rate_still: float = 30.0

var has_shields: bool = false
var max_shields: float = 0.0
var shields: float = 0.0
var shield_regen: float = 2.0
var shield_delay: float = 5.0
var shield_delay_timer: float = 0.0

var has_mana: bool = false
var max_mana: float = 0.0
var mana: float = 0.0
var mana_regen: float = 0.0

var has_rage: bool = false
var max_rage: float = 0.0
var rage: float = 0.0

var run_speed: float = 250.0
var sprint_mult: float = 1.5
var is_sprinting: bool = false
var is_moving: bool = false
var velocity_smoothing: float = 14.0
var aim_smoothing: float = 0.15
var target_aim_angle: float = 0.0
var footstep_timer: float = 0.0
var footstep_interval: float = 0.18

var melee_damage: float = 15.0
var ranged_damage: float = 10.0
var melee_range: float = 55.0
var ranged_range: float = 500.0
var attack_cooldown: float = 0.0
var melee_cooldown_time: float = 0.4
var ranged_cooldown_time: float = 0.25
var is_blocking: bool = false
var block_damage_reduction: float = 0.5
var current_slot: int = GameData.Slot.MELEE

var ammo: int = 30
var max_ammo: int = 30

var is_wounded: bool = false
var wound_hp_cap_pct: float = 0.75
var lives: int = 2
var is_alive: bool = true
var is_down: bool = false

var gold_coins: int = 0
var kill_credits: int = 0
var total_kills: int = 0
var xp_earned: int = 0

# Improvement #1: Dodge Roll
var dodge_cooldown: float = 0.0
var dodge_cooldown_time: float = 0.8
var dodge_timer: float = 0.0
var dodge_duration: float = 0.25
var dodge_speed: float = 500.0
var dodge_dir: Vector2 = Vector2.ZERO
var is_dodging: bool = false

# Improvement #2: Combo Melee
var melee_combo_count: int = 0
var melee_combo_timer: float = 0.0
var melee_combo_window: float = 0.8
var melee_combo_max: int = 5

# Improvement #3: Critical Hits
var crit_chance: float = 0.1
var crit_multiplier: float = 2.0
var last_hit_was_crit: bool = false

# Improvement #8: Pickup Magnet
var pickup_magnet_range: float = 120.0
var pickup_magnet_speed: float = 300.0

# Improvement #11: HP Regen Delay
var hp_regen_delay: float = 0.0
var hp_regen_delay_time: float = 3.0

# Improvement #12: Lifesteal
var lifesteal_pct: float = 0.0

# Improvement #14: Perfect Block
var block_start_timer: float = 0.0
var perfect_block_window: float = 0.2
var was_perfect_block: bool = false

# Improvement #15: Dash Attack - melee while dodging does 1.5x damage
var dash_attack_bonus: float = 1.5

# Improvement #16: Momentum Damage - movement speed boosts damage
var momentum_damage_bonus: float = 0.0
var momentum_max_bonus: float = 0.25

# Improvement #17: Adrenaline Rush - below 25% HP gives speed+damage
var adrenaline_active: bool = false
var adrenaline_speed_mult: float = 1.3
var adrenaline_damage_mult: float = 1.25
var adrenaline_threshold: float = 0.25

# Improvement #18: Death Animation
var death_anim_timer: float = 0.0

# Improvement #19: Knockback
var knockback_vel: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0

# Improvement #20: Distance Tracking
var last_position: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0

# Improvement #21: Bloodlust - kills boost attack speed
var bloodlust_timer: float = 0.0
var bloodlust_stacks: int = 0
var bloodlust_max_stacks: int = 5
var bloodlust_atk_speed_per_stack: float = 0.08

# Improvement #22: Second Wind - auto-revive once per mission
var second_wind_available: bool = true

# Improvement #23: Charge Attack - hold for power
var charge_timer: float = 0.0
var is_charging: bool = false
var charge_max_time: float = 1.5
var charge_damage_mult: float = 3.0

# Improvement #24: Sprint Lunge Attack
var sprint_attack_lunge: float = 80.0
var sprint_attack_bonus: float = 1.4

# Improvement #25: Execution - instant kill low HP enemies
var execution_threshold: float = 0.10

# Improvement #26: Armor Penetration
var armor_pen: float = 0.0

# Improvement #27: Headshot cone for ranged
var headshot_cone: float = 0.15
var headshot_mult: float = 2.0

# Improvement #28: Multi-cleave at high combo
var cleave_combo_threshold: int = 3
var cleave_arc_bonus: float = 0.5

# Improvement #29: Parry counter
var parry_counter_damage: float = 2.0

# Improvement #30: Lucky dodge - chance to auto-dodge lethal
var lucky_dodge_chance: float = 0.05

var elevation: float = 0.0
var jump_vel: float = 0.0
var jump_max_height: float = 20.0
var jumps_remaining: int = 1
var max_jumps: int = 1
var is_grounded: bool = true

var aim_angle: float = 0.0
var race_color: Color = Color.WHITE

var light_on: bool = true
var ability_cooldown: float = 0.0
var ability_active: bool = false
var ability_timer: float = 0.0

# Touch/mobile controls
var touch_direction: Vector2 = Vector2.ZERO
var auto_attack_mode: bool = false
var auto_attack_timer: float = 0.0
var auto_attack_target: CharacterBody2D = null
var auto_attack_range: float = 120.0

var food_slots: Array[Dictionary] = []
var max_food_slots: int = 3

# Sidescroller mode
var is_sidescroller: bool = false
var ss_gravity: float = 800.0
var ss_jump_force: float = 350.0
var ss_velocity_y: float = 0.0
var ss_on_ground: bool = true
var ss_on_ladder: bool = false
var ss_is_crouching: bool = false
var ss_crouch_speed_mult: float = 0.5
var ss_coyote_timer: float = 0.0
var ss_jump_buffer: float = 0.0
var ss_max_jumps: int = 2
var ss_jumps_remaining: int = 2
var ss_facing_right: bool = true

var flashlight_node: PointLight2D = null
var ambient_light_node: PointLight2D = null
var emoji_label: Label = null
var shadow_label: Label = null
var collision_shape: CollisionShape2D = null
var attack_area: Area2D = null
var pickup_area: Area2D = null

var invincibility_timer: float = 0.0
var damage_flash_timer: float = 0.0
var melee_swing_timer: float = 0.0
var melee_swing_visual: float = 0.0

func _ready() -> void:
	_setup_race()
	_apply_level_scaling()
	_build_nodes()
	z_index = 10
	last_position = global_position

# Improvement #6: Level Scaling
func _apply_level_scaling() -> void:
	var bonus := GameSystems.get_level_stat_bonus()
	max_hp *= bonus
	hp = max_hp
	melee_damage *= bonus
	ranged_damage *= bonus
	run_speed += (GameSystems.player_level - 1) * 2.0
	crit_chance += GameSystems.player_level * 0.002
	# Improvement #26: Armor pen scales with level
	armor_pen = GameSystems.player_level * 0.01
	# Improvement #30: Lucky dodge scales with level
	lucky_dodge_chance = 0.03 + GameSystems.player_level * 0.002
	if player_class == GameData.PlayerClass.DPS:
		crit_chance += 0.05
		crit_multiplier = 2.5
		lifesteal_pct = 0.02
		headshot_cone = 0.12
		execution_threshold = 0.12
	elif player_class == GameData.PlayerClass.TANK:
		block_damage_reduction = 0.65
		max_hp *= 1.15
		hp = max_hp
		perfect_block_window = 0.3
		parry_counter_damage = 3.0
	elif player_class == GameData.PlayerClass.SUPPORT:
		hp_regen *= 2.0
		lifesteal_pct = 0.05
		second_wind_available = true
		adrenaline_threshold = 0.3
	elif player_class == GameData.PlayerClass.MAGE:
		crit_chance += 0.08
		charge_damage_mult = 4.0
		if has_mana:
			max_mana *= 1.3
			mana = max_mana

func _setup_race() -> void:
	var stats: Dictionary = GameData.get_race_data(race)
	if stats.is_empty():
		stats = GameData.get_race_data(GameData.Race.HUMAN)
	max_hp = stats["max_hp"]
	hp = max_hp
	hp_regen = stats["hp_regen"]
	run_speed = stats["run_speed"]
	melee_damage = stats["melee_damage"]
	ranged_damage = stats["ranged_damage"]
	race_color = stats["color"]
	has_shields = stats["has_shields"]
	max_shields = stats["max_shields"]
	shields = max_shields
	shield_regen = stats["shield_regen"]
	shield_delay = stats["shield_delay"]
	has_mana = stats["has_mana"]
	max_mana = stats["max_mana"]
	mana = max_mana
	mana_regen = stats["mana_regen"]
	has_rage = stats["has_rage"]
	max_rage = stats["max_rage"]
	rage = 0.0

	match stats["jump_type"]:
		"jetpack":
			max_jumps = 3
		"double_jump":
			max_jumps = 2
		"hover":
			max_jumps = 1
		"stomp":
			max_jumps = 1
	jumps_remaining = max_jumps

func _build_nodes() -> void:
	collision_layer = 1
	collision_mask = 4

	var shape := CircleShape2D.new()
	shape.radius = 14.0
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

	shadow_label = Label.new()
	var race_data: Dictionary = GameData.get_race_data(race)
	shadow_label.text = race_data.get("emoji", "\U0001F9D1")
	shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow_label.position = Vector2(-24, -16)
	shadow_label.size = Vector2(48, 48)
	shadow_label.modulate = Color(0, 0, 0, 0.5)
	shadow_label.z_index = -1
	var shadow_settings := LabelSettings.new()
	shadow_settings.font = GameData.emoji_font
	shadow_settings.font_size = 32
	shadow_label.label_settings = shadow_settings
	add_child(shadow_label)

	emoji_label = Label.new()
	emoji_label.text = race_data.get("emoji", "\U0001F9D1")
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.position = Vector2(-24, -24)
	emoji_label.size = Vector2(48, 48)
	var label_settings := LabelSettings.new()
	label_settings.font = GameData.emoji_font
	label_settings.font_size = 32
	emoji_label.label_settings = label_settings
	add_child(emoji_label)

	_setup_lights()
	_setup_areas()

func _setup_lights() -> void:
	if not GameData.point_light_texture:
		GameData.create_light_textures()

	var shadows_on: bool = GameSystems.get_setting("shadows_enabled")

	ambient_light_node = PointLight2D.new()
	ambient_light_node.texture = GameData.point_light_texture
	ambient_light_node.texture_scale = 3.0
	ambient_light_node.energy = 0.6
	ambient_light_node.color = Color(0.9, 0.85, 0.75)
	ambient_light_node.shadow_enabled = shadows_on
	add_child(ambient_light_node)

	var light_stats: Dictionary = GameData.get_race_data(race)
	match light_stats.get("light_type", "flashlight"):
		"flashlight":
			flashlight_node = PointLight2D.new()
			flashlight_node.texture = GameData.flashlight_texture
			flashlight_node.texture_scale = 5.0
			flashlight_node.energy = 1.2
			flashlight_node.color = Color(0.95, 0.9, 0.8)
			flashlight_node.shadow_enabled = shadows_on
			add_child(flashlight_node)
		"brighteyes":
			flashlight_node = PointLight2D.new()
			flashlight_node.texture = GameData.flashlight_texture
			flashlight_node.texture_scale = 4.0
			flashlight_node.energy = 1.0
			flashlight_node.color = Color(0.6, 0.9, 1.0)
			flashlight_node.shadow_enabled = shadows_on
			add_child(flashlight_node)
		"darkvision":
			ambient_light_node.texture_scale = 6.0
			ambient_light_node.energy = 1.2
			ambient_light_node.color = Color(0.5, 0.7, 0.5)
		"torch":
			ambient_light_node.texture_scale = 4.0
			ambient_light_node.energy = 0.9
			ambient_light_node.color = Color(1.0, 0.7, 0.3)

func _setup_areas() -> void:
	attack_area = Area2D.new()
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2
	var attack_shape := CollisionShape2D.new()
	var attack_circle := CircleShape2D.new()
	attack_circle.radius = melee_range
	attack_shape.shape = attack_circle
	attack_area.add_child(attack_shape)
	add_child(attack_area)

	pickup_area = Area2D.new()
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 8
	var pickup_shape := CollisionShape2D.new()
	var pickup_circle := CircleShape2D.new()
	pickup_circle.radius = 40.0
	pickup_shape.shape = pickup_circle
	pickup_area.add_child(pickup_shape)
	add_child(pickup_area)

func _physics_process(delta: float) -> void:
	if not is_alive:
		death_anim_timer += delta
		emoji_label.modulate.a = maxf(1.0 - death_anim_timer * 2.0, 0.0)
		shadow_label.modulate.a = maxf(0.5 - death_anim_timer * 2.0, 0.0)
		return
	if is_sidescroller:
		_ss_physics_process(delta)
		return
	_handle_dodge(delta)
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_abilities(delta)
	_handle_jump(delta)
	_handle_resources(delta)
	_handle_food(delta)
	_update_visuals(delta)
	_handle_pickup()
	_handle_magnet(delta)
	_track_distance()
	move_and_slide()

# Improvement #1: Dodge Roll
func _handle_dodge(delta: float) -> void:
	dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
	if is_dodging:
		dodge_timer -= delta
		velocity = dodge_dir * dodge_speed
		invincibility_timer = 0.1
		if dodge_timer <= 0:
			is_dodging = false
		return

func _try_dodge() -> void:
	if dodge_cooldown > 0 or is_dodging:
		return
	var dir := Vector2.ZERO
	# Use touch direction if available
	if touch_direction.length() > 0.1:
		dir = touch_direction
	else:
		if Input.is_action_pressed("move_up"): dir.y -= 1
		if Input.is_action_pressed("move_down"): dir.y += 1
		if Input.is_action_pressed("move_left"): dir.x -= 1
		if Input.is_action_pressed("move_right"): dir.x += 1
	if dir.length() < 0.1:
		dir = Vector2.from_angle(aim_angle)
	dodge_dir = dir.normalized()
	is_dodging = true
	dodge_timer = dodge_duration
	dodge_cooldown = dodge_cooldown_time
	stamina = maxf(stamina - 15.0, 0.0)
	dodge_performed.emit()
	GameSystems.track("dodges_performed")

# Improvement #8: Pickup Magnet
func _handle_magnet(delta: float) -> void:
	var areas := pickup_area.get_overlapping_areas()
	for area in areas:
		if area.has_method("get_magnet_pull") and area.get_magnet_pull():
			var dir := (global_position - area.global_position).normalized()
			area.global_position += dir * pickup_magnet_speed * delta

# Improvement #20: Distance Tracking
func _track_distance() -> void:
	var dist := global_position.distance_to(last_position)
	if dist > 0.5 and dist < 500.0:
		distance_traveled += dist
		GameSystems.track("total_distance", dist)
	last_position = global_position

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO

	# Use touch joystick if available, otherwise keyboard
	if touch_direction.length() > 0.1:
		input_dir = touch_direction
	else:
		if Input.is_action_pressed("move_up"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_down"):
			input_dir.y += 1
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1
		input_dir = input_dir.normalized()
	is_moving = input_dir.length() > 0.1

	is_sprinting = Input.is_action_pressed("sprint") and is_moving
	if is_dodging:
		return

	var speed := run_speed
	# Improvement #17: Adrenaline Rush
	adrenaline_active = (hp / maxf(max_hp, 1.0)) < adrenaline_threshold
	if adrenaline_active:
		speed *= adrenaline_speed_mult

	if is_sprinting:
		speed *= sprint_mult
		stamina = maxf(stamina - 20.0 * delta, 0.0)
		if stamina <= 0:
			is_sprinting = false

	if is_blocking:
		speed *= 0.5

	# Improvement #16: Momentum damage bonus from movement speed
	var speed_ratio := velocity.length() / maxf(run_speed, 1.0)
	momentum_damage_bonus = clampf(speed_ratio * 0.15, 0.0, momentum_max_bonus)

	# Smooth velocity lerp for responsive but not jerky movement
	var target_vel := input_dir * speed + knockback_vel
	velocity = velocity.lerp(target_vel, velocity_smoothing * delta)
	knockback_vel = knockback_vel.move_toward(Vector2.ZERO, knockback_decay * speed * delta)

	# Aim: use movement direction on touch, mouse on desktop
	if touch_direction.length() > 0.1:
		target_aim_angle = touch_direction.angle()
	elif auto_attack_target and is_instance_valid(auto_attack_target) and auto_attack_mode:
		target_aim_angle = (auto_attack_target.global_position - global_position).angle()
	else:
		var mouse_pos := get_global_mouse_position()
		target_aim_angle = (mouse_pos - global_position).angle()
	# Smooth aim interpolation
	aim_angle = lerp_angle(aim_angle, target_aim_angle, 1.0 - aim_smoothing)

	# Footstep dust
	if is_moving and is_grounded:
		footstep_timer -= delta
		if footstep_timer <= 0:
			var speed_ratio := speed / maxf(run_speed, 1.0)
			footstep_timer = footstep_interval / maxf(speed_ratio, 0.1)
			var vfx := get_tree().get_first_node_in_group("vfx")
			if vfx and vfx.has_method("spawn_footstep_dust"):
				vfx.spawn_footstep_dust(global_position + Vector2(0, 8))

func _handle_combat(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	melee_swing_timer = maxf(melee_swing_timer - delta, 0.0)
	var was_blocking := is_blocking
	is_blocking = Input.is_action_pressed("block")
	if is_blocking and not was_blocking:
		block_start_timer = perfect_block_window
	if is_blocking:
		block_start_timer = maxf(block_start_timer - delta, 0.0)

	if is_blocking:
		stamina = maxf(stamina - 5.0 * delta, 0.0)
		if stamina <= 0:
			is_blocking = false

	# Auto-attack on mobile
	if auto_attack_mode and attack_cooldown <= 0 and not is_dodging and not is_blocking:
		_handle_auto_attack(delta)
	elif Input.is_action_just_pressed("attack") and attack_cooldown <= 0 and not is_dodging:
		match current_slot:
			GameData.Slot.MELEE:
				_melee_attack()
			GameData.Slot.RANGED:
				_ranged_attack()
			GameData.Slot.THROWABLE:
				_throwable_attack()

	if Input.is_action_just_pressed("slot_melee"):
		current_slot = GameData.Slot.MELEE
		slot_changed.emit(current_slot)
	elif Input.is_action_just_pressed("slot_ranged"):
		current_slot = GameData.Slot.RANGED
		slot_changed.emit(current_slot)
	elif Input.is_action_just_pressed("slot_throwable"):
		current_slot = GameData.Slot.THROWABLE
		slot_changed.emit(current_slot)
	elif Input.is_action_just_pressed("slot_consumable"):
		current_slot = GameData.Slot.CONSUMABLE
		slot_changed.emit(current_slot)

func _handle_auto_attack(delta: float) -> void:
	auto_attack_timer -= delta
	if auto_attack_timer > 0:
		return
	auto_attack_timer = 0.15

	# Find nearest enemy
	_find_auto_attack_target()
	if auto_attack_target == null or not is_instance_valid(auto_attack_target):
		auto_attack_target = null
		return

	var dist := global_position.distance_to(auto_attack_target.global_position)
	aim_angle = (auto_attack_target.global_position - global_position).angle()

	if dist <= melee_range and attack_cooldown <= 0:
		_melee_attack()
	elif dist <= ranged_range and dist > melee_range and ammo > 0 and attack_cooldown <= 0:
		current_slot = GameData.Slot.RANGED
		_ranged_attack()

func _find_auto_attack_target() -> void:
	var best_dist := auto_attack_range
	var best_enemy: CharacterBody2D = null
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best_enemy = enemy
	auto_attack_target = best_enemy

func set_touch_direction(dir: Vector2) -> void:
	touch_direction = dir

func trigger_ability() -> void:
	if ability_cooldown <= 0:
		_activate_ability()

func trigger_light() -> void:
	_toggle_light()

func trigger_dodge() -> void:
	_try_dodge()

func _melee_attack() -> void:
	# Improvement #2: Combo system
	if melee_combo_timer > 0:
		melee_combo_count = mini(melee_combo_count + 1, melee_combo_max)
	else:
		melee_combo_count = 1
	melee_combo_timer = melee_combo_window
	var combo_mult := 1.0 + (melee_combo_count - 1) * 0.15

	# Improvement #21: Bloodlust attack speed bonus
	var bloodlust_bonus := 1.0 - bloodlust_stacks * bloodlust_atk_speed_per_stack
	attack_cooldown = melee_cooldown_time * (1.0 - melee_combo_count * 0.04) * maxf(bloodlust_bonus, 0.5)
	melee_swing_timer = 0.3
	melee_swing_visual = 1.0
	stamina = maxf(stamina - maxf(8.0 - melee_combo_count * 0.5, 4.0), 0.0)

	var attack_dir: Vector2
	if auto_attack_mode and auto_attack_target and is_instance_valid(auto_attack_target):
		attack_dir = (auto_attack_target.global_position - global_position).normalized()
	else:
		var mouse_pos := get_global_mouse_position()
		attack_dir = (mouse_pos - global_position).normalized()

	# Improvement #24: Sprint lunge
	if is_sprinting and is_moving:
		global_position += attack_dir * sprint_attack_lunge * 0.5
		combo_mult *= sprint_attack_bonus

	# Improvement #3: Critical hit
	last_hit_was_crit = randf() < crit_chance
	var final_damage := melee_damage * combo_mult * GameSystems.get_combo_damage_mult()
	# Improvement #16: Momentum damage
	final_damage *= (1.0 + momentum_damage_bonus)
	# Improvement #17: Adrenaline damage
	if adrenaline_active:
		final_damage *= adrenaline_damage_mult
	# Improvement #15: Dash attack bonus
	if is_dodging:
		final_damage *= dash_attack_bonus
	if has_rage and max_rage > 0 and rage > 50:
		final_damage *= 1.0 + (rage / max_rage) * 0.4
	if last_hit_was_crit:
		final_damage *= crit_multiplier
		GameSystems.track("critical_hits")

	GameSystems.register_hit()
	combo_hit.emit(melee_combo_count)

	# Improvement #28: Multi-cleave at high combo
	var attack_arc := PI / 2.0
	if melee_combo_count >= cleave_combo_threshold:
		attack_arc += cleave_arc_bonus

	player_attacked.emit({
		"type": "melee",
		"position": global_position,
		"direction": attack_dir,
		"damage": final_damage,
		"range": melee_range,
		"arc": attack_arc,
		"angle": aim_angle,
		"is_crit": last_hit_was_crit,
		"combo": melee_combo_count,
		"lifesteal": lifesteal_pct,
		"armor_pen": armor_pen,
		"execution_threshold": execution_threshold,
	})

func _ranged_attack() -> void:
	if ammo <= 0:
		return
	ammo -= 1
	# Improvement #21: Bloodlust attack speed
	var bloodlust_bonus := 1.0 - bloodlust_stacks * bloodlust_atk_speed_per_stack
	attack_cooldown = ranged_cooldown_time * maxf(bloodlust_bonus, 0.5)
	stamina = maxf(stamina - 3.0, 0.0)

	var attack_dir: Vector2
	if auto_attack_mode and auto_attack_target and is_instance_valid(auto_attack_target):
		attack_dir = (auto_attack_target.global_position - global_position).normalized()
	else:
		var mouse_pos := get_global_mouse_position()
		attack_dir = (mouse_pos - global_position).normalized()

	# Improvement #27: Headshot cone - precise aim = headshot
	var is_headshot := false
	if auto_attack_target and is_instance_valid(auto_attack_target):
		var to_target := (auto_attack_target.global_position - global_position).normalized()
		var aim_diff := absf(attack_dir.angle_to(to_target))
		if aim_diff < headshot_cone:
			is_headshot = true

	last_hit_was_crit = randf() < crit_chance or is_headshot
	var final_damage := ranged_damage * GameSystems.get_combo_damage_mult()
	# Improvement #16: Momentum damage
	final_damage *= (1.0 + momentum_damage_bonus)
	# Improvement #17: Adrenaline damage
	if adrenaline_active:
		final_damage *= adrenaline_damage_mult
	if is_headshot:
		final_damage *= headshot_mult
		GameSystems.track("headshots")
	if last_hit_was_crit:
		final_damage *= crit_multiplier
		GameSystems.track("critical_hits")

	GameSystems.register_hit()
	screen_shake.emit(0.3, 0.1)

	player_attacked.emit({
		"type": "ranged",
		"position": global_position + attack_dir * 20.0,
		"direction": attack_dir,
		"damage": final_damage,
		"speed": 600.0,
		"range": ranged_range,
		"is_crit": last_hit_was_crit,
		"is_headshot": is_headshot,
		"lifesteal": lifesteal_pct,
		"armor_pen": armor_pen,
	})
	ammo_changed.emit(ammo, max_ammo)

func _throwable_attack() -> void:
	pass

func _handle_abilities(delta: float) -> void:
	ability_cooldown = maxf(ability_cooldown - delta, 0.0)
	# Improvement #21: Bloodlust timer decay
	if bloodlust_timer > 0:
		bloodlust_timer -= delta
		if bloodlust_timer <= 0:
			bloodlust_stacks = 0

	# Improvement #23: Charge attack
	if Input.is_action_pressed("attack") and not is_dodging and not is_blocking:
		if charge_timer < charge_max_time:
			charge_timer += delta
			is_charging = charge_timer > 0.3
	if Input.is_action_just_released("attack") and is_charging:
		_release_charge_attack()
		is_charging = false
		charge_timer = 0.0
	elif not Input.is_action_pressed("attack"):
		is_charging = false
		charge_timer = 0.0

	if Input.is_action_just_pressed("jump") and dodge_cooldown <= 0:
		_try_dodge()

	if Input.is_action_just_pressed("ability") and ability_cooldown <= 0:
		_activate_ability()

	if Input.is_action_just_pressed("light_ability"):
		_toggle_light()

func _activate_ability() -> void:
	match race:
		GameData.Race.HUMAN:
			match player_class:
				GameData.PlayerClass.DPS:
					ability_active = true
					ability_timer = 20.0
					ability_cooldown = 30.0
		GameData.Race.ELF:
			if mana >= 20.0:
				mana -= 20.0
				var mouse_pos := get_global_mouse_position()
				var attack_dir := (mouse_pos - global_position).normalized()
				player_attacked.emit({
					"type": "melee",
					"position": global_position,
					"direction": attack_dir,
					"damage": melee_damage * 3.0,
					"range": melee_range * 1.5,
					"arc": PI,
					"angle": aim_angle,
				})
				ability_cooldown = 2.0
		GameData.Race.DWARF:
			var mouse_pos := get_global_mouse_position()
			var dash_dir := (mouse_pos - global_position).normalized()
			global_position += dash_dir * 200.0
			player_attacked.emit({
				"type": "melee",
				"position": global_position,
				"direction": dash_dir,
				"damage": melee_damage * 2.0,
				"range": 30.0,
				"arc": TAU,
				"angle": 0.0,
			})
			ability_cooldown = 8.0
		GameData.Race.ORC:
			player_attacked.emit({
				"type": "melee",
				"position": global_position,
				"direction": Vector2.from_angle(aim_angle),
				"damage": melee_damage * 0.5,
				"range": melee_range,
				"arc": PI / 3.0,
				"angle": aim_angle,
				"stagger": 2.0,
			})
			ability_cooldown = 10.0

func _toggle_light() -> void:
	light_on = not light_on
	if flashlight_node:
		flashlight_node.enabled = light_on

func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		jump_vel = 300.0
		jumps_remaining -= 1
		is_grounded = false

	if not is_grounded:
		elevation += jump_vel * delta
		jump_vel -= 600.0 * delta

		var jump_stats: Dictionary = GameData.get_race_data(race)
		match jump_stats.get("jump_type", "hover"):
			"hover":
				if Input.is_action_pressed("jump") and jump_vel < 0:
					jump_vel = maxf(jump_vel, -50.0)
			"jetpack":
				if Input.is_action_pressed("jump"):
					jump_vel += 400.0 * delta
			"stomp":
				if Input.is_action_pressed("jump") and elevation > 5.0:
					jump_vel -= 800.0 * delta

		if elevation <= 0:
			var was_airborne := not is_grounded
			elevation = 0
			jump_vel = 0
			is_grounded = true
			jumps_remaining = max_jumps

			if was_airborne and jump_stats.get("jump_type", "") == "stomp":
				player_attacked.emit({
					"type": "melee",
					"position": global_position,
					"direction": Vector2.ZERO,
					"damage": melee_damage * 1.5,
					"range": 80.0,
					"arc": TAU,
					"angle": 0.0,
					"stagger": 3.0,
				})

func _handle_resources(delta: float) -> void:
	if is_moving:
		stamina = minf(stamina + stamina_regen_rate * delta, max_stamina)
	else:
		stamina = minf(stamina + stamina_regen_rate_still * delta, max_stamina)
	stamina_changed.emit(stamina, max_stamina)

	# Improvement #11: HP Regen Delay
	hp_regen_delay = maxf(hp_regen_delay - delta, 0.0)
	var wound_cap := max_hp if not is_wounded else max_hp * wound_hp_cap_pct
	if hp_regen_delay <= 0:
		hp = minf(hp + hp_regen * delta, wound_cap)
	if is_wounded and hp >= wound_cap:
		is_wounded = false

	hp_changed.emit(hp + temp_hp, temp_hp, max_hp)

	if has_shields:
		shield_delay_timer = maxf(shield_delay_timer - delta, 0.0)
		if shield_delay_timer <= 0:
			shields = minf(shields + shield_regen * delta, max_shields)
		shields_changed.emit(shields, max_shields)

	if has_mana:
		mana = minf(mana + mana_regen * delta, max_mana)
		mana_changed.emit(mana, max_mana)

	if has_rage and max_rage > 0:
		if not is_moving and rage > 0:
			rage = maxf(rage - 0.25 * delta, 0.0)
		rage_changed.emit(rage, max_rage)

	if ability_active:
		ability_timer -= delta
		if ability_timer <= 0:
			ability_active = false

	if temp_hp > 0:
		temp_hp = maxf(temp_hp - 0.5 * delta, 0.0)

	invincibility_timer = maxf(invincibility_timer - delta, 0.0)
	damage_flash_timer = maxf(damage_flash_timer - delta, 0.0)

func _handle_food(delta: float) -> void:
	var finished: Array[int] = []
	for i in range(food_slots.size()):
		food_slots[i]["timer"] -= delta
		hp = minf(hp + food_slots[i]["heal_per_sec"] * delta, max_hp)
		if food_slots[i]["timer"] <= 0:
			finished.append(i)
	finished.reverse()
	for idx in finished:
		food_slots.remove_at(idx)

func _update_visuals(delta: float) -> void:
	emoji_label.position.y = -24 - elevation * 0.5
	shadow_label.position.y = -16
	shadow_label.modulate.a = clampf(remap(elevation, 0, 40, 0.5, 0.15), 0.0, 1.0)
	shadow_label.scale = Vector2.ONE * clampf(remap(elevation, 0, 40, 1.0, 1.3), 0.5, 2.0)

	if flashlight_node:
		flashlight_node.rotation = aim_angle

	melee_combo_timer = maxf(melee_combo_timer - delta, 0.0)
	if melee_combo_timer <= 0:
		melee_combo_count = 0

	melee_swing_visual = maxf(melee_swing_visual - delta * 5.0, 0.0)
	if melee_swing_visual > 0:
		var swing_intensity := 0.3 + melee_combo_count * 0.05
		emoji_label.rotation = sin(melee_swing_visual * PI * 4) * swing_intensity
	else:
		emoji_label.rotation = 0.0

	if is_dodging:
		emoji_label.modulate = Color(1.0, 1.0, 1.0, 0.4)
		# Dodge afterimage trail via VFX
		var vfx_node := get_tree().get_first_node_in_group("vfx")
		if vfx_node and vfx_node.has_method("spawn_footstep_dust"):
			vfx_node.spawn_footstep_dust(global_position)
	elif damage_flash_timer > 0:
		var flash := damage_flash_timer / 0.15
		emoji_label.modulate = Color(1.0 + flash * 1.5, 0.3 + (1.0 - flash) * 0.2, 0.3 + (1.0 - flash) * 0.2)
	elif ability_active:
		var ab_pulse := (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.15
		emoji_label.modulate = Color(1.4 + ab_pulse, 1.1 + ab_pulse * 0.5, 0.9)
	elif has_rage and max_rage > 0 and rage > max_rage * 0.8:
		var rage_pulse := (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.15
		emoji_label.modulate = Color(1.0 + rage_pulse, 0.7, 0.7)
	else:
		emoji_label.modulate = Color.WHITE

	# Scale pulse on melee swing
	if melee_swing_visual > 0:
		var scale_bump := 1.0 + melee_swing_visual * 0.1
		emoji_label.scale = Vector2(scale_bump, scale_bump)
	# Improvement #23: Charge attack visual
	elif is_charging:
		var charge_pct := clampf(charge_timer / charge_max_time, 0.0, 1.0)
		var pulse := 1.0 + charge_pct * 0.2 + sin(Time.get_ticks_msec() * 0.02) * charge_pct * 0.05
		emoji_label.scale = Vector2(pulse, pulse)
		emoji_label.modulate = Color(1.0 + charge_pct * 0.8, 1.0 - charge_pct * 0.3, 1.0 - charge_pct * 0.5)
	else:
		emoji_label.scale = Vector2.ONE

	# Improvement #17: Adrenaline visual
	if adrenaline_active and not is_dodging and damage_flash_timer <= 0 and not ability_active:
		var adr_pulse := (sin(Time.get_ticks_msec() * 0.015) + 1.0) * 0.2
		emoji_label.modulate = Color(1.0 + adr_pulse, 0.8, 0.6)

	# Shadow follows movement direction slightly
	if is_moving and velocity.length() > 10.0:
		var shadow_offset := velocity.normalized() * 2.0
		shadow_label.position.x = -24 + shadow_offset.x
	else:
		shadow_label.position.x = -24

func _handle_pickup() -> void:
	if Input.is_action_just_pressed("interact"):
		var bodies := pickup_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("pickup"):
				body.pickup(self)
		var areas := pickup_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("pickup"):
				area.pickup(self)

func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO) -> void:
	if not is_alive or invincibility_timer > 0 or is_dodging:
		return

	# Improvement #13: Damage direction indicator
	if from_pos != Vector2.ZERO:
		var dir_angle := (from_pos - global_position).angle()
		damage_direction.emit(dir_angle)

	# Improvement #14: Perfect Block + #29: Parry Counter
	if is_blocking:
		var block_dir := Vector2.from_angle(aim_angle)
		var damage_dir := (from_pos - global_position).normalized()
		if block_dir.dot(damage_dir) > 0.3:
			if block_start_timer > 0 and block_start_timer >= (perfect_block_window - 0.01):
				amount = 0.0
				was_perfect_block = true
				GameSystems.track("perfect_blocks")
				screen_shake.emit(0.5, 0.15)
				# Improvement #29: Parry counter - reflect damage back
				player_attacked.emit({
					"type": "melee",
					"position": global_position,
					"direction": -damage_dir,
					"damage": melee_damage * parry_counter_damage,
					"range": melee_range * 1.2,
					"arc": PI / 3.0,
					"angle": (-damage_dir).angle(),
					"is_crit": true,
					"is_parry": true,
					"combo": 0,
					"lifesteal": 0.0,
				})
			else:
				amount *= (1.0 - block_damage_reduction)
				was_perfect_block = false
			stamina -= amount * 0.5

	if has_shields and shields > 0:
		var shield_absorbed := minf(shields, amount)
		shields -= shield_absorbed
		amount -= shield_absorbed
		shield_delay_timer = shield_delay

	if temp_hp > 0:
		var temp_absorbed := minf(temp_hp, amount)
		temp_hp -= temp_absorbed
		amount -= temp_absorbed

	hp -= amount
	damage_flash_timer = 0.15
	invincibility_timer = 0.15
	hp_regen_delay = hp_regen_delay_time

	# Improvement #19: Knockback
	if from_pos != Vector2.ZERO and amount > 10.0:
		var kb_dir := (global_position - from_pos).normalized()
		knockback_vel = kb_dir * minf(amount * 3.0, 300.0)

	screen_shake.emit(minf(amount * 0.02, 1.0), 0.2)
	GameSystems.track("total_damage_taken", amount)

	if has_rage and max_rage > 0:
		rage = minf(rage + amount * 0.5, max_rage)
		rage_changed.emit(rage, max_rage)

	shield_delay_timer = shield_delay

	# Improvement #30: Lucky dodge - chance to survive lethal hit
	if hp <= 0 and randf() < lucky_dodge_chance:
		hp = 1.0
		invincibility_timer = 1.0
		GameSystems.track("lucky_dodges")
		var vfx_node := get_tree().get_first_node_in_group("vfx")
		if vfx_node and vfx_node.has_method("spawn_impact_ring"):
			vfx_node.spawn_impact_ring(global_position, 40.0, Color(1.0, 1.0, 0.3, 0.9))

	if hp <= 0:
		hp = 0
		_go_down()

	hp_changed.emit(hp + temp_hp, temp_hp, max_hp)

func _go_down() -> void:
	lives -= 1
	if lives <= 0:
		# Improvement #22: Second Wind
		if second_wind_available:
			second_wind_available = false
			hp = max_hp * 0.3
			invincibility_timer = 3.0
			screen_shake.emit(1.0, 0.5)
			GameSystems.track("second_winds_used")
			var vfx_node := get_tree().get_first_node_in_group("vfx")
			if vfx_node and vfx_node.has_method("spawn_impact_ring"):
				vfx_node.spawn_impact_ring(global_position, 80.0, Color(0.3, 1.0, 0.5, 0.9))
			return
		_die()
		return

	is_wounded = true
	hp = max_hp * 0.1
	temp_hp = max_hp * 0.4
	player_wounded.emit()
	invincibility_timer = 2.0

func _die() -> void:
	is_alive = false
	death_anim_timer = 0.0
	GameSystems.track("total_deaths")
	player_died.emit()

func heal(amount: float, is_real: bool = false) -> void:
	if is_real:
		var cap := max_hp if not is_wounded else max_hp * wound_hp_cap_pct
		hp = minf(hp + amount, cap)
		if hp >= cap and is_wounded:
			is_wounded = false
	else:
		temp_hp += amount
	hp_changed.emit(hp + temp_hp, temp_hp, max_hp)

func add_temp_hp(amount: float) -> void:
	temp_hp += amount
	hp_changed.emit(hp + temp_hp, temp_hp, max_hp)

func add_gold(amount: int) -> void:
	gold_coins += amount
	GameSystems.track("total_gold_earned", amount)
	gold_changed.emit(gold_coins)

func add_kill_credit(amount: int) -> void:
	kill_credits += amount
	kill_credit_earned.emit(kill_credits)

func add_xp(amount: int) -> void:
	xp_earned += amount
	GameSystems.add_xp(amount)
	GameSystems.track("total_xp_earned", amount)

func apply_lifesteal(damage_dealt: float, steal_pct: float) -> void:
	if steal_pct > 0 and damage_dealt > 0:
		var healed := damage_dealt * steal_pct
		heal(healed, true)

# Improvement #21: Bloodlust - called when player kills enemy
func on_kill() -> void:
	bloodlust_stacks = mini(bloodlust_stacks + 1, bloodlust_max_stacks)
	bloodlust_timer = 5.0
	total_kills += 1

# Improvement #23: Release charged attack
func _release_charge_attack() -> void:
	var charge_pct := clampf(charge_timer / charge_max_time, 0.0, 1.0)
	var charge_mult := 1.0 + (charge_damage_mult - 1.0) * charge_pct

	var attack_dir: Vector2
	if auto_attack_mode and auto_attack_target and is_instance_valid(auto_attack_target):
		attack_dir = (auto_attack_target.global_position - global_position).normalized()
	else:
		var mouse_pos := get_global_mouse_position()
		attack_dir = (mouse_pos - global_position).normalized()

	var final_damage := melee_damage * charge_mult
	var is_crit := randf() < crit_chance + charge_pct * 0.15
	if is_crit:
		final_damage *= crit_multiplier

	attack_cooldown = melee_cooldown_time * 1.5
	melee_swing_timer = 0.5
	melee_swing_visual = 1.0
	stamina = maxf(stamina - 15.0 * charge_pct, 0.0)
	screen_shake.emit(0.3 + charge_pct * 0.5, 0.15 + charge_pct * 0.1)

	player_attacked.emit({
		"type": "melee",
		"position": global_position,
		"direction": attack_dir,
		"damage": final_damage,
		"range": melee_range * (1.0 + charge_pct * 0.5),
		"arc": PI * (0.5 + charge_pct * 0.5),
		"angle": aim_angle,
		"is_crit": is_crit,
		"is_charged": true,
		"charge_pct": charge_pct,
		"combo": 0,
		"lifesteal": lifesteal_pct,
		"armor_pen": armor_pen + charge_pct * 0.3,
		"execution_threshold": execution_threshold + charge_pct * 0.1,
	})

func eat_food(food_data: Dictionary) -> void:
	if food_slots.size() >= max_food_slots:
		return
	GameSystems.track("food_eaten")
	food_slots.append({
		"heal_per_sec": food_data["heal_per_sec"],
		"timer": food_data["duration"],
		"stamina_boost": food_data["stamina_boost"],
	})

func restore_ammo(pct: float) -> void:
	ammo = mini(ammo + int(max_ammo * pct), max_ammo)
	ammo_changed.emit(ammo, max_ammo)

func restore_mana(amount: float) -> void:
	if has_mana:
		mana = minf(mana + amount, max_mana)
		mana_changed.emit(mana, max_mana)

# ===== SIDESCROLLER MODE =====

func enter_sidescroller_mode() -> void:
	is_sidescroller = true
	ss_velocity_y = 0.0
	ss_on_ground = true
	ss_on_ladder = false
	ss_is_crouching = false
	ss_coyote_timer = 0.0
	ss_jump_buffer = 0.0
	ss_jumps_remaining = ss_max_jumps
	ss_facing_right = true
	elevation = 0.0
	jump_vel = 0.0
	is_grounded = true
	knockback_vel = Vector2.ZERO

	# Flatten shadow for side view
	if shadow_label:
		shadow_label.position = Vector2(-24, 4)
		shadow_label.modulate = Color(0, 0, 0, 0.3)
		shadow_label.scale = Vector2(1.0, 0.3)

func exit_sidescroller_mode() -> void:
	is_sidescroller = false
	ss_velocity_y = 0.0
	ss_on_ground = true
	ss_is_crouching = false
	ss_on_ladder = false
	elevation = 0.0
	jump_vel = 0.0
	is_grounded = true

	# Restore shadow for top-down
	if shadow_label:
		shadow_label.position = Vector2(-24, -16)
		shadow_label.modulate = Color(0, 0, 0, 0.5)
		shadow_label.scale = Vector2.ONE

	# Restore emoji orientation
	if emoji_label:
		emoji_label.scale = Vector2.ONE
		emoji_label.flip_h = false

func _ss_physics_process(delta: float) -> void:
	_ss_handle_movement(delta)
	_ss_handle_gravity(delta)
	_ss_handle_jump(delta)
	_ss_handle_crouch()
	_handle_combat(delta)
	_handle_resources(delta)
	_handle_food(delta)
	_ss_update_visuals(delta)
	_handle_pickup()
	_handle_magnet(delta)
	_track_distance()
	move_and_slide()

	# Ground detection after move_and_slide
	_ss_check_ground()

func _ss_handle_movement(delta: float) -> void:
	var input_x: float = 0.0

	if touch_direction.length() > 0.1:
		input_x = touch_direction.x
	else:
		if Input.is_action_pressed("move_left"):
			input_x -= 1.0
		if Input.is_action_pressed("move_right"):
			input_x += 1.0

	is_moving = absf(input_x) > 0.1

	# Track facing direction
	if input_x > 0.1:
		ss_facing_right = true
	elif input_x < -0.1:
		ss_facing_right = false

	is_sprinting = Input.is_action_pressed("sprint") and is_moving
	if is_dodging:
		return

	var speed := run_speed
	if is_sprinting:
		speed *= sprint_mult
		stamina = maxf(stamina - 20.0 * delta, 0.0)
		if stamina <= 0:
			is_sprinting = false

	if ss_is_crouching:
		speed *= ss_crouch_speed_mult

	if is_blocking:
		speed *= 0.5

	# Horizontal velocity
	var target_vx := input_x * speed + knockback_vel.x
	velocity.x = lerpf(velocity.x, target_vx, velocity_smoothing * delta)
	knockback_vel = knockback_vel.move_toward(Vector2.ZERO, knockback_decay * speed * delta)

	# Ladder movement
	if ss_on_ladder:
		var input_y: float = 0.0
		if Input.is_action_pressed("move_up"):
			input_y -= 1.0
		if Input.is_action_pressed("move_down"):
			input_y += 1.0
		velocity.y = input_y * speed * 0.7
		ss_velocity_y = 0.0

	# Aiming - mouse aims freely in side view
	var mouse_pos := get_global_mouse_position()
	target_aim_angle = (mouse_pos - global_position).angle()
	aim_angle = lerp_angle(aim_angle, target_aim_angle, 1.0 - aim_smoothing)

	# Footstep dust
	if is_moving and ss_on_ground:
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = footstep_interval
			var vfx_node := get_tree().get_first_node_in_group("vfx")
			if vfx_node and vfx_node.has_method("spawn_footstep_dust"):
				vfx_node.spawn_footstep_dust(global_position + Vector2(0, 12))

func _ss_handle_gravity(delta: float) -> void:
	if ss_on_ladder:
		return

	if not ss_on_ground:
		ss_velocity_y += ss_gravity * delta
		# Terminal velocity
		ss_velocity_y = minf(ss_velocity_y, 600.0)
		velocity.y = ss_velocity_y

	# Coyote time
	if ss_on_ground:
		ss_coyote_timer = 0.08
	else:
		ss_coyote_timer = maxf(ss_coyote_timer - delta, 0.0)

	# Jump buffer
	ss_jump_buffer = maxf(ss_jump_buffer - delta, 0.0)

func _ss_handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"):
		ss_jump_buffer = 0.1

	# Perform jump if buffered and able
	if ss_jump_buffer > 0:
		if ss_on_ladder:
			# Jump off ladder
			ss_on_ladder = false
			ss_velocity_y = -ss_jump_force * 0.8
			velocity.y = ss_velocity_y
			ss_jump_buffer = 0.0
			ss_jumps_remaining = ss_max_jumps - 1
		elif ss_coyote_timer > 0 or ss_jumps_remaining > 0:
			ss_velocity_y = -ss_jump_force
			velocity.y = ss_velocity_y
			ss_on_ground = false
			ss_coyote_timer = 0.0
			ss_jump_buffer = 0.0
			ss_jumps_remaining -= 1
			stamina = maxf(stamina - 5.0, 0.0)

	# Variable jump height - release early for short hop
	if (Input.is_action_just_released("jump") or Input.is_action_just_released("move_up")) and ss_velocity_y < 0:
		ss_velocity_y *= 0.5
		velocity.y = ss_velocity_y

	# Dodge in sidescroller = dash
	if Input.is_action_just_pressed("jump") and dodge_cooldown <= 0 and Input.is_action_pressed("sprint"):
		_ss_dash()

func _ss_dash() -> void:
	if dodge_cooldown > 0:
		return
	var dir := 1.0 if ss_facing_right else -1.0
	is_dodging = true
	dodge_timer = dodge_duration
	dodge_cooldown = dodge_cooldown_time
	dodge_dir = Vector2(dir, 0.0)
	velocity.x = dir * dodge_speed
	stamina = maxf(stamina - 15.0, 0.0)
	dodge_performed.emit()

func _ss_handle_crouch() -> void:
	var wants_crouch := Input.is_action_pressed("move_down") and ss_on_ground and not ss_on_ladder
	if wants_crouch and not ss_is_crouching:
		ss_is_crouching = true
		# Shrink collision for crouching
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = 8.0
			collision_shape.position.y = 4.0
	elif not wants_crouch and ss_is_crouching:
		ss_is_crouching = false
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = 14.0
			collision_shape.position.y = 0.0

func _ss_check_ground() -> void:
	# Use move_and_slide's is_on_floor for ground detection
	var was_on_ground := ss_on_ground
	ss_on_ground = is_on_floor()

	if ss_on_ground and not was_on_ground:
		# Just landed
		ss_velocity_y = 0.0
		ss_jumps_remaining = ss_max_jumps

	if ss_on_ground:
		velocity.y = 0.0
		ss_velocity_y = 0.0

func _ss_update_visuals(delta: float) -> void:
	# Flip emoji based on facing direction
	if emoji_label:
		if ss_facing_right:
			emoji_label.scale.x = absf(emoji_label.scale.x)
		else:
			emoji_label.scale.x = -absf(emoji_label.scale.x)

	# Crouch visual - squish the emoji
	if ss_is_crouching:
		emoji_label.scale.y = 0.7
		emoji_label.position.y = -18
	elif not is_dodging:
		emoji_label.scale.y = absf(emoji_label.scale.y) if emoji_label.scale.y != 1.0 else 1.0
		emoji_label.position.y = -24

	# Shadow stays at feet
	if shadow_label:
		shadow_label.position = Vector2(-24, 4)
		shadow_label.modulate = Color(0, 0, 0, 0.3)
		shadow_label.scale = Vector2(1.0, 0.3)

	# Flashlight follows aim
	if flashlight_node:
		flashlight_node.rotation = aim_angle

	# Combat visuals
	melee_combo_timer = maxf(melee_combo_timer - delta, 0.0)
	if melee_combo_timer <= 0:
		melee_combo_count = 0

	melee_swing_visual = maxf(melee_swing_visual - delta * 5.0, 0.0)
	if melee_swing_visual > 0:
		var swing_intensity := 0.3 + melee_combo_count * 0.05
		emoji_label.rotation = sin(melee_swing_visual * PI * 4) * swing_intensity
	else:
		emoji_label.rotation = 0.0

	# Color effects (same as top-down)
	if is_dodging:
		emoji_label.modulate = Color(1.0, 1.0, 1.0, 0.4)
	elif damage_flash_timer > 0:
		var flash := damage_flash_timer / 0.15
		emoji_label.modulate = Color(1.0 + flash * 1.5, 0.3 + (1.0 - flash) * 0.2, 0.3 + (1.0 - flash) * 0.2)
	elif ability_active:
		var ab_pulse := (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.15
		emoji_label.modulate = Color(1.4 + ab_pulse, 1.1 + ab_pulse * 0.5, 0.9)
	else:
		emoji_label.modulate = Color.WHITE

	# Dodge timer
	dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false

	invincibility_timer = maxf(invincibility_timer - delta, 0.0)
	damage_flash_timer = maxf(damage_flash_timer - delta, 0.0)
