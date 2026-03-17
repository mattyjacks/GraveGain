extends CharacterBody2D

signal enemy_died(enemy: CharacterBody2D, data: Dictionary)
signal enemy_attacked(target: CharacterBody2D, damage: float, from_pos: Vector2)
signal alert_nearby(position: Vector2, alert_range: float)
signal damage_taken_visual(position: Vector2, amount: float, is_crit: bool)

enum State { IDLE, CHASE, ATTACK, STAGGERED, STUNNED, SCARED, FLEEING, DEAD }

var enemy_type: int = GameData.EnemyType.GOBLIN_SKELETON
var stats: Dictionary = {}
var state: State = State.IDLE

var max_hp: float = 25.0
var hp: float = 25.0
var damage: float = 5.0
var move_speed: float = 100.0
var attack_range: float = 35.0
var attack_cooldown_time: float = 1.2
var attack_timer: float = 0.0
var emoji_scale: float = 1.0
var collision_radius: float = 14.0
var gold_drop: int = 2
var xp_value: int = 10
var category: String = "standard"

var is_armored: bool = false
var armor_rating: float = 0.0

# Knockback weight - heavier enemies resist knockback more (0.5 = half knockback, 2.0 = double)
var knockback_weight: float = 1.0
var can_summon: bool = false
var explodes: bool = false
var regen_pct: float = 0.0
var has_ranged: bool = false
var can_fly: bool = false

var target: CharacterBody2D = null
var detection_range: float = 400.0
var stagger_timer: float = 0.0
var stun_timer: float = 0.0
var scared_timer: float = 0.0
var bleed_timer: float = 0.0
var bleed_damage: float = 0.0
var burn_timer: float = 0.0
var burn_damage: float = 0.0

var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var path_update_timer: float = 0.0

var emoji_label: Label = null
var shadow_label: Label = null
var hp_bar_bg: ColorRect = null
var hp_bar_fg: ColorRect = null
var collision_shape: CollisionShape2D = null
var elite_glow: Label = null

var difficulty_mult: float = 1.0
var is_alive: bool = true
var death_timer: float = 0.0
var hit_flash_timer: float = 0.0

var bob_offset: float = 0.0
var bob_speed: float = 2.0

# Improvement #21: Patrol Behavior
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var is_patrolling: bool = false
var patrol_wait_timer: float = 0.0

# Improvement #22: Group Aggro
var alert_range: float = 200.0
var has_alerted: bool = false

# Improvement #23: Elite Variants
var is_elite: bool = false
var elite_damage_mult: float = 1.5
var elite_hp_mult: float = 2.0
var elite_speed_mult: float = 1.2

# Improvement #24: Spawn Animation
var spawn_timer: float = 0.4
var is_spawning: bool = true

# Improvement #28: Flee at Low HP
var flee_hp_threshold: float = 0.15
var is_fleeing: bool = false

# Improvement #30: Boss Enrage
var is_enraged: bool = false
var enrage_threshold: float = 0.3
var enrage_speed_mult: float = 1.4
var enrage_damage_mult: float = 1.5

# Improvement #33: Corpse Persistence
var corpse_timer: float = 3.0

# Improvement #35: Damage Type Tracking
var last_damage_type: String = ""
var total_damage_received: float = 0.0

# Improvement: Freeze immunity timer
var freeze_timer: float = 0.0

# Improvement #31: Telegraph attacks - visual warning before attack
var telegraph_timer: float = 0.0
var telegraph_duration: float = 0.4
var is_telegraphing: bool = false

# Improvement #32: Elemental damage on attack
var elemental_type: String = "none"
var elemental_chance: float = 0.0
var elemental_damage: float = 0.0

# Improvement #33b: Aggro leash - return to spawn if too far
var spawn_position: Vector2 = Vector2.ZERO
var leash_range: float = 800.0
var is_leashing: bool = false

# Improvement #34: Pack tactics - grouped enemies deal more damage
var pack_bonus: float = 0.0
var nearby_ally_count: int = 0

# Improvement #35b: Distance-based level scaling
var distance_level_bonus: float = 0.0

# Improvement #36: Out-of-combat healing
var ooc_timer: float = 0.0
var ooc_heal_delay: float = 5.0
var ooc_heal_rate: float = 0.02

# Improvement #37: Ambush stealth enemies
var is_ambush: bool = false
var ambush_revealed: bool = false
var ambush_alpha: float = 0.15

# Improvement #38: Dodge/strafe behavior for ranged enemies
var strafe_timer: float = 0.0
var strafe_dir: float = 1.0

# Improvement #39: Attack wind-up visual indicator
var windup_indicator: ColorRect = null

# Improvement #40: Death loot explosion radius
var loot_explosion_count: int = 1

# Improvement #41: Varied attack patterns
var attack_pattern: int = 0
var attack_pattern_count: int = 0
var multi_hit_remaining: int = 0
var multi_hit_delay: float = 0.0

# Improvement #42: Armor pen interaction
var armor_value: float = 0.0

# Improvement #43: Enrage visual particles
var enrage_particle_timer: float = 0.0

# Improvement #44: Boss summon minions
var summon_cooldown: float = 0.0
var summon_cooldown_time: float = 15.0
var minions_summoned: int = 0
var max_minions: int = 3

# Improvement #45: Execution vulnerability
var execution_vulnerable: bool = false

# Sidescroller mode
var is_sidescroller: bool = false
var ss_gravity: float = 600.0
var ss_velocity_y: float = 0.0
var ss_on_ground: bool = true
var ss_facing_right: bool = true
var ss_patrol_left: float = 0.0
var ss_patrol_right: float = 0.0
var ss_patrol_dir: float = 1.0
var ss_jump_timer: float = 0.0

func setup(etype: int, diff_mult: float = 1.0) -> void:
	enemy_type = etype
	difficulty_mult = diff_mult
	stats = GameData.get_enemy_data(etype)
	if stats.is_empty():
		stats = GameData.get_enemy_data(GameData.EnemyType.GOBLIN_SKELETON)
	max_hp = stats["max_hp"] * diff_mult
	hp = max_hp
	damage = stats["damage"] * diff_mult
	move_speed = stats["speed"]
	attack_range = stats["attack_range"]
	attack_cooldown_time = stats["attack_cooldown"]
	emoji_scale = stats["emoji_scale"]
	collision_radius = stats["collision_radius"]
	gold_drop = stats["gold_drop"]
	xp_value = stats["xp"]
	category = stats["category"]
	is_armored = stats.get("armored", false)
	has_ranged = stats.get("has_ranged", false)
	can_fly = stats.get("flies", false)
	can_summon = stats.get("summons", false)
	explodes = stats.get("explodes", false)
	regen_pct = stats.get("regen_pct", 0.0)

	# Improvement #31: Telegraph duration varies by enemy speed
	telegraph_duration = clampf(attack_cooldown_time * 0.3, 0.2, 0.6)

	# Improvement #32: Elemental damage based on enemy type
	if stats.get("element", "") != "":
		elemental_type = stats["element"]
		elemental_chance = stats.get("element_chance", 0.3)
		elemental_damage = damage * 0.3

	# Improvement #42: Armor value for armored enemies
	if is_armored:
		armor_value = max_hp * 0.15

	# Improvement #21: Varied detection ranges
	detection_range = randf_range(350.0, 450.0)
	if category == "elite":
		detection_range = randf_range(450.0, 550.0)
	elif category == "boss":
		detection_range = randf_range(650.0, 800.0)

	# Improvement #22: Group aggro range
	alert_range = detection_range * 0.6

	# Improvement #28: Flee threshold varies by type
	if category == "standard":
		flee_hp_threshold = randf_range(0.1, 0.2)
	else:
		flee_hp_threshold = 0.0

	# Improvement #37: Ambush enemies
	is_ambush = stats.get("ambush", false) or (category == "standard" and randf() < 0.08)
	ambush_revealed = false

	# Improvement #38: Ranged enemies strafe
	if has_ranged:
		strafe_timer = randf_range(1.0, 3.0)
		strafe_dir = [-1.0, 1.0].pick_random()

	# Improvement #40: Elite/boss drop more loot items
	if category == "boss":
		loot_explosion_count = 5
	elif category == "elite" or is_elite:
		loot_explosion_count = 3
	else:
		loot_explosion_count = 1

	# Set knockback weight based on enemy type and size
	# Heavier/larger enemies resist knockback more
	knockback_weight = 1.0
	if category == "boss":
		knockback_weight = 2.5
	elif category == "elite" or is_elite:
		knockback_weight = 1.8
	elif emoji_scale > 1.2:
		knockback_weight = 1.5
	elif emoji_scale < 0.8:
		knockback_weight = 0.7

	# Improvement #41: Varied attack patterns for bosses
	if category == "boss":
		attack_pattern_count = 3
	elif is_elite:
		attack_pattern_count = 2
	else:
		attack_pattern_count = 1

	# Improvement #44: Boss summon cooldown
	if can_summon:
		summon_cooldown_time = 12.0 + randf_range(-2.0, 4.0)

	# Apply difficulty system multipliers
	max_hp *= GameSystems.get_diff_mult("enemy_hp")
	hp = max_hp
	damage *= GameSystems.get_diff_mult("enemy_dmg")
	move_speed *= GameSystems.get_diff_mult("enemy_speed")

# Improvement #23: Make this enemy an elite variant
func make_elite() -> void:
	is_elite = true
	max_hp *= elite_hp_mult
	hp = max_hp
	damage *= elite_damage_mult
	move_speed *= elite_speed_mult
	gold_drop = int(gold_drop * 3)
	xp_value = int(xp_value * 2.5)
	detection_range *= 1.3
	attack_cooldown_time *= 0.8

func _ready() -> void:
	_build_nodes()
	z_index = 10
	bob_offset = randf() * TAU
	spawn_position = global_position
	# Improvement #24: Start with spawn animation
	if is_spawning:
		emoji_label.scale = Vector2.ZERO
		shadow_label.scale = Vector2.ZERO
	# Improvement #37: Ambush enemies start mostly invisible
	if is_ambush and not ambush_revealed:
		emoji_label.modulate.a = ambush_alpha
		shadow_label.modulate.a = 0.0
		hp_bar_bg.visible = false
		hp_bar_fg.visible = false

func _build_nodes() -> void:
	collision_layer = 2
	collision_mask = 5

	var shape := CircleShape2D.new()
	shape.radius = collision_radius
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

	shadow_label = Label.new()
	var emoji_text: String = stats.get("emoji", "\U0001F480")
	var text_based: bool = GameSystems.get_setting("text_based_graphics") == true
	if text_based:
		emoji_text = _get_text_representation(emoji_text)
	
	var shadow_size := int(32 * emoji_scale)
	var label_size := int(32 * emoji_scale)
	
	# Try to render emoji as SVG texture
	if not text_based and SvgEmojiRenderer.is_svg_emoji_available():
		var shadow_texture = SvgEmojiRenderer.load_emoji_texture(emoji_text, shadow_size)
		if shadow_texture:
			var shadow_rect = TextureRect.new()
			shadow_rect.texture = shadow_texture
			shadow_rect.custom_minimum_size = Vector2(shadow_size * 1.5, shadow_size * 1.5)
			shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			shadow_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			shadow_rect.position = Vector2(-shadow_size * 0.75, -shadow_size * 0.25)
			shadow_rect.modulate = Color(0, 0, 0, 0.4)
			shadow_rect.z_index = -1
			add_child(shadow_rect)
			shadow_label = shadow_rect
			
			var emoji_texture = SvgEmojiRenderer.load_emoji_texture(emoji_text, label_size)
			if emoji_texture:
				var emoji_rect = TextureRect.new()
				emoji_rect.texture = emoji_texture
				emoji_rect.custom_minimum_size = Vector2(label_size * 1.5, label_size * 1.5)
				emoji_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				emoji_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				emoji_rect.position = Vector2(-label_size * 0.75, -label_size * 0.75)
				add_child(emoji_rect)
				emoji_label = emoji_rect
			else:
				# Fallback to label
				emoji_label = Label.new()
				emoji_label.text = emoji_text
				emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				emoji_label.position = Vector2(-label_size * 0.75, -label_size * 0.75)
				emoji_label.size = Vector2(label_size * 1.5, label_size * 1.5)
				var label_settings := LabelSettings.new()
				label_settings.font_size = label_size
				emoji_label.label_settings = label_settings
				add_child(emoji_label)
		else:
			# Fallback to text rendering
			shadow_label.text = emoji_text
			shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			shadow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			shadow_label.position = Vector2(-shadow_size * 0.75, -shadow_size * 0.25)
			shadow_label.size = Vector2(shadow_size * 1.5, shadow_size * 1.5)
			shadow_label.modulate = Color(0, 0, 0, 0.4)
			shadow_label.z_index = -1
			var shadow_settings := LabelSettings.new()
			if GameData.emoji_font:
				shadow_settings.font = GameData.emoji_font
			shadow_settings.font_size = shadow_size
			shadow_label.label_settings = shadow_settings
			add_child(shadow_label)

			emoji_label = Label.new()
			emoji_label.text = emoji_text
			emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			emoji_label.position = Vector2(-label_size * 0.75, -label_size * 0.75)
			emoji_label.size = Vector2(label_size * 1.5, label_size * 1.5)
			var label_settings := LabelSettings.new()
			if GameData.emoji_font:
				label_settings.font = GameData.emoji_font
			label_settings.font_size = label_size
			emoji_label.label_settings = label_settings
			add_child(emoji_label)
	else:
		# Text-based or SVG not available - use label rendering
		shadow_label.text = emoji_text
		shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shadow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shadow_label.position = Vector2(-shadow_size * 0.75, -shadow_size * 0.25)
		shadow_label.size = Vector2(shadow_size * 1.5, shadow_size * 1.5)
		shadow_label.modulate = Color(0, 0, 0, 0.4)
		shadow_label.z_index = -1
		var shadow_settings := LabelSettings.new()
		if GameData.emoji_font and not text_based:
			shadow_settings.font = GameData.emoji_font
		shadow_settings.font_size = shadow_size
		shadow_label.label_settings = shadow_settings
		add_child(shadow_label)

		emoji_label = Label.new()
		emoji_label.text = emoji_text
		emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji_label.position = Vector2(-label_size * 0.75, -label_size * 0.75)
		emoji_label.size = Vector2(label_size * 1.5, label_size * 1.5)
		var label_settings := LabelSettings.new()
		if GameData.emoji_font and not text_based:
			label_settings.font = GameData.emoji_font
		label_settings.font_size = label_size
		emoji_label.label_settings = label_settings
		add_child(emoji_label)

	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(40 * emoji_scale, 4)
	hp_bar_bg.position = Vector2(-20 * emoji_scale, -24 * emoji_scale)
	hp_bar_bg.color = Color(0.2, 0.0, 0.0, 0.8)
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)

	hp_bar_fg = ColorRect.new()
	hp_bar_fg.size = Vector2(40 * emoji_scale, 4)
	hp_bar_fg.position = Vector2(-20 * emoji_scale, -24 * emoji_scale)
	hp_bar_fg.color = Color(0.9, 0.1, 0.1, 0.9)
	hp_bar_fg.visible = false
	add_child(hp_bar_fg)

	# Improvement #23: Elite glow indicator
	if is_elite:
		elite_glow = Label.new()
		elite_glow.text = "\u2728"
		elite_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elite_glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		elite_glow.position = Vector2(-8, -32 * emoji_scale)
		elite_glow.size = Vector2(16, 16)
		var glow_settings := LabelSettings.new()
		if GameData.emoji_font:
			glow_settings.font = GameData.emoji_font
		glow_settings.font_size = 10
		elite_glow.label_settings = glow_settings
		add_child(elite_glow)

func _physics_process(delta: float) -> void:
	if not is_alive:
		# Improvement #33: Corpse persistence
		corpse_timer -= delta
		death_timer -= delta
		if emoji_label:
			emoji_label.modulate.a = clampf(corpse_timer / 3.0, 0.0, 1.0) * 0.5
		if corpse_timer <= 0:
			queue_free()
		return

	# Improvement #24: Spawn animation
	if is_spawning:
		spawn_timer -= delta
		var t := 1.0 - (spawn_timer / 0.4)
		var s := minf(t * 1.2, 1.0)
		emoji_label.scale = Vector2(s, s)
		shadow_label.scale = Vector2(s, s)
		if spawn_timer <= 0:
			is_spawning = false
			emoji_label.scale = Vector2.ONE
			shadow_label.scale = Vector2.ONE
		return

	_update_timers(delta)
	_update_state(delta)
	if is_sidescroller:
		_ss_act(delta)
		_ss_update_visuals(delta)
	else:
		_act(delta)
		_update_visuals(delta)
	move_and_slide()
	if is_sidescroller:
		_ss_check_ground()

func _update_timers(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	stagger_timer = maxf(stagger_timer - delta, 0.0)
	stun_timer = maxf(stun_timer - delta, 0.0)
	scared_timer = maxf(scared_timer - delta, 0.0)
	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	path_update_timer = maxf(path_update_timer - delta, 0.0)
	wander_timer -= delta

	# Improvement #31: Telegraph timer
	if is_telegraphing:
		telegraph_timer -= delta
		if telegraph_timer <= 0:
			is_telegraphing = false

	# Improvement #41: Multi-hit delay
	if multi_hit_remaining > 0:
		multi_hit_delay -= delta
		if multi_hit_delay <= 0 and target and is_instance_valid(target):
			enemy_attacked.emit(target, damage * 0.6, global_position)
			multi_hit_remaining -= 1
			multi_hit_delay = 0.2

	# Improvement #44: Boss summon cooldown
	if can_summon and is_alive:
		summon_cooldown = maxf(summon_cooldown - delta, 0.0)

	if bleed_timer > 0:
		bleed_timer -= delta
		hp -= bleed_damage * delta
		if hp <= 0 and is_alive:
			_die()
			return

	if burn_timer > 0:
		burn_timer -= delta
		hp -= burn_damage * delta
		if hp <= 0 and is_alive:
			_die()
			return

	if regen_pct > 0 and max_hp > 0 and hp < max_hp * regen_pct:
		hp = minf(hp + max_hp * 0.02 * delta, max_hp * regen_pct)

	# Improvement #36: Out-of-combat healing
	if state == State.IDLE and hp < max_hp and hp > 0:
		ooc_timer += delta
		if ooc_timer >= ooc_heal_delay:
			hp = minf(hp + max_hp * ooc_heal_rate * delta, max_hp)
	else:
		ooc_timer = 0.0

	# Improvement #43: Enrage particle timer
	if is_enraged:
		enrage_particle_timer += delta

func _update_state(_delta: float) -> void:
	if stagger_timer > 0:
		state = State.STAGGERED
		return
	if stun_timer > 0:
		state = State.STUNNED
		return
	if scared_timer > 0:
		state = State.SCARED
		return
	if freeze_timer > 0:
		state = State.STUNNED
		return

	# Improvement #45: Execution vulnerability at low HP
	execution_vulnerable = hp > 0 and max_hp > 0 and hp / max_hp <= 0.1

	# Improvement #28: Flee at low HP
	if flee_hp_threshold > 0 and hp > 0 and max_hp > 0 and hp / max_hp <= flee_hp_threshold and not is_enraged:
		is_fleeing = true
		state = State.FLEEING
		return

	# Improvement #33b: Aggro leash - return home if too far
	if spawn_position != Vector2.ZERO and global_position.distance_to(spawn_position) > leash_range:
		is_leashing = true
		target = null
		state = State.IDLE
		has_alerted = false
		return
	else:
		is_leashing = false

	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)

		# Improvement #37: Ambush reveal when player is close
		if is_ambush and not ambush_revealed and dist < detection_range * 0.5:
			ambush_revealed = true
			# Surprise attack with bonus damage
			if dist < attack_range * 2.0:
				enemy_attacked.emit(target, damage * 1.5, global_position)
				attack_timer = attack_cooldown_time

		# Improvement #34: Pack tactics
		nearby_ally_count = 0
		for ally in get_tree().get_nodes_in_group("enemies"):
			if ally != self and is_instance_valid(ally) and ally.is_alive:
				if global_position.distance_to(ally.global_position) < 150.0:
					nearby_ally_count += 1
		pack_bonus = minf(nearby_ally_count * 0.08, 0.4)

		# Improvement #30: Boss Enrage
		if category == "boss" and not is_enraged and max_hp > 0 and hp / max_hp <= enrage_threshold:
			is_enraged = true
			move_speed *= enrage_speed_mult
			damage *= enrage_damage_mult
			attack_cooldown_time *= 0.7

		# Improvement #44: Boss summon minions at low HP
		if can_summon and category == "boss" and summon_cooldown <= 0 and minions_summoned < max_minions:
			if max_hp > 0 and hp / max_hp < 0.5:
				summon_cooldown = summon_cooldown_time
				minions_summoned += 1
				enemy_died.emit(self, {
					"type": enemy_type,
					"position": global_position,
					"gold": 0,
					"xp": 0,
					"category": "summon_request",
					"is_elite": false,
					"overkill": 0,
					"name": "Minion",
					"color": stats.get("blood_color", Color(0.5, 0.0, 0.0)),
				})

		if dist <= attack_range and attack_timer <= 0:
			state = State.ATTACK
		elif dist <= detection_range:
			state = State.CHASE
			# Improvement #22: Group aggro
			if not has_alerted:
				has_alerted = true
				alert_nearby.emit(global_position, alert_range)
		else:
			state = State.IDLE
			target = null
			has_alerted = false
	else:
		state = State.IDLE
		has_alerted = false

func _act(delta: float) -> void:
	match state:
		State.IDLE:
			_wander(delta)
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack()
		State.STAGGERED:
			velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		State.STUNNED:
			velocity = Vector2.ZERO
			freeze_timer = maxf(freeze_timer - delta, 0.0)
		State.SCARED:
			if target and is_instance_valid(target):
				var flee_dir := (global_position - target.global_position).normalized()
				velocity = flee_dir * move_speed * 1.2
			else:
				velocity = Vector2.ZERO
		State.FLEEING:
			# Improvement #28: Flee behavior
			if target and is_instance_valid(target):
				var flee_dir := (global_position - target.global_position).normalized()
				var jitter := Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
				velocity = (flee_dir + jitter).normalized() * move_speed * 1.3
			else:
				velocity = wander_dir * move_speed
		State.DEAD:
			velocity = Vector2.ZERO

func _wander(delta: float) -> void:
	# Improvement #21: Patrol behavior
	if is_patrolling and patrol_points.size() > 0:
		if patrol_wait_timer > 0:
			patrol_wait_timer -= delta
			velocity = Vector2.ZERO
			return
		var target_pos := patrol_points[patrol_index]
		var dist := global_position.distance_to(target_pos)
		if dist < 20.0:
			patrol_index = (patrol_index + 1) % patrol_points.size()
			patrol_wait_timer = randf_range(0.5, 2.0)
			velocity = Vector2.ZERO
		else:
			velocity = (target_pos - global_position).normalized() * move_speed * 0.4
		return

	if wander_timer <= 0:
		wander_dir = Vector2.from_angle(randf() * TAU)
		wander_timer = randf_range(1.0, 3.0)
	velocity = wander_dir * move_speed * 0.3

func set_patrol(points: Array[Vector2]) -> void:
	patrol_points = points
	is_patrolling = true
	patrol_index = 0

func alert_from(pos: Vector2) -> void:
	# Improvement #22: Group aggro - called when nearby enemy alerts
	if state == State.IDLE and is_alive and not is_spawning:
		if global_position.distance_to(pos) <= alert_range:
			state = State.CHASE

func _chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	# Improvement #33b: Leash - walk back to spawn
	if is_leashing:
		var home_dir := (spawn_position - global_position).normalized()
		velocity = home_dir * move_speed * 0.6
		if global_position.distance_to(spawn_position) < 30.0:
			is_leashing = false
			hp = minf(hp + max_hp * 0.2, max_hp)
		return

	var dir := (target.global_position - global_position).normalized()

	# Improvement #38: Ranged enemies strafe
	if has_ranged:
		var dist_to_target := global_position.distance_to(target.global_position)
		if dist_to_target < attack_range * 0.8:
			# Back away if too close
			velocity = -dir * move_speed * 0.7
		elif dist_to_target < attack_range * 1.5:
			# Strafe perpendicular
			strafe_timer -= delta
			if strafe_timer <= 0:
				strafe_dir *= -1.0
				strafe_timer = randf_range(1.0, 2.5)
			var perp := Vector2(-dir.y, dir.x) * strafe_dir
			velocity = perp * move_speed * 0.6
		else:
			velocity = dir * move_speed
	else:
		velocity = dir * move_speed

func _attack() -> void:
	if attack_timer > 0:
		velocity = Vector2.ZERO
		return

	# Improvement #31: Telegraph before attacking
	if not is_telegraphing and telegraph_duration > 0:
		is_telegraphing = true
		telegraph_timer = telegraph_duration
		velocity = Vector2.ZERO
		return
	if is_telegraphing:
		velocity = Vector2.ZERO
		return

	attack_timer = attack_cooldown_time
	velocity = Vector2.ZERO

	if target and is_instance_valid(target):
		if explodes:
			_explode()
		else:
			# Improvement #34: Pack tactics damage bonus
			var final_dmg := damage * (1.0 + pack_bonus)
			# Improvement #32: Elemental damage
			if elemental_type != "none" and randf() < elemental_chance:
				if elemental_type == "fire" and target.has_method("take_damage"):
					final_dmg *= 1.15
				elif elemental_type == "poison":
					final_dmg *= 0.9
					if target.has_method("apply_bleed"):
						target.apply_bleed(elemental_damage * 0.5, 3.0)
				elif elemental_type == "ice":
					final_dmg *= 0.85
			enemy_attacked.emit(target, final_dmg, global_position)

			# Improvement #41: Multi-hit attack pattern
			if attack_pattern_count > 1:
				attack_pattern = (attack_pattern + 1) % attack_pattern_count
				if attack_pattern == 1:
					multi_hit_remaining = 2
					multi_hit_delay = 0.2

func _explode() -> void:
	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist < attack_range * 2:
			enemy_attacked.emit(target, damage, global_position)
	_die()

func take_damage(amount: float, from_pos: Vector2 = Vector2.ZERO, is_headshot: bool = false, is_crit: bool = false, damage_type: String = "physical", armor_pen_val: float = 0.0, exec_threshold: float = 0.0) -> void:
	if not is_alive:
		return

	# Improvement #37: Ambush reveal on damage
	if is_ambush and not ambush_revealed:
		ambush_revealed = true

	# Improvement #42: Armor with penetration
	if is_armored and not is_headshot:
		var effective_armor := maxf(1.0 - armor_pen_val, 0.3)
		amount *= effective_armor

	# Improvement #45: Execution - instant kill at very low HP
	if exec_threshold > 0 and max_hp > 0 and hp / max_hp <= exec_threshold and hp > 0:
		amount = hp + 1.0
		is_crit = true
		GameSystems.track("executions")

	# Improvement #35: Damage type tracking
	last_damage_type = damage_type
	total_damage_received += amount

	hp -= amount
	hit_flash_timer = 0.15

	hp_bar_bg.visible = true
	hp_bar_fg.visible = true
	var hp_pct := maxf(hp / maxf(max_hp, 1.0), 0.0)
	hp_bar_fg.size.x = hp_pct * 40 * emoji_scale
	# Color the HP bar based on health
	if hp_pct > 0.5:
		hp_bar_fg.color = Color(0.2, 0.9, 0.2, 0.9)
	elif hp_pct > 0.25:
		hp_bar_fg.color = Color(0.9, 0.7, 0.1, 0.9)
	else:
		hp_bar_fg.color = Color(0.9, 0.1, 0.1, 0.9)

	# Improvement #31: Damage number signal
	damage_taken_visual.emit(global_position + Vector2(randf_range(-10, 10), -20), amount, is_crit)

	# VFX: blood drip on hit
	var vfx_node := get_tree().get_first_node_in_group("vfx")
	if vfx_node and vfx_node.has_method("spawn_blood_burst") and from_pos != Vector2.ZERO:
		var blood_dir := (global_position - from_pos).normalized()
		var blood_count := 3 + int(amount * 0.15)
		var blood_color: Color = stats.get("blood_color", Color(0.5, 0.0, 0.0))
		vfx_node.spawn_blood_burst(global_position, blood_dir, blood_count, 60.0 + amount)
		vfx_node.spawn_blood_splat(global_position, 0.4 + amount * 0.01, blood_color)

	# Improvement: Boss HP signal
	if category == "boss":
		GameSystems.boss_hp_updated.emit(stats.get("name", "Boss"), hp_pct, true)

	if amount > max_hp * 0.15:
		stagger_timer = 0.3
		if from_pos != Vector2.ZERO:
			# Enhanced knockback: scales with damage and crit status
			var base_kb := 150.0
			var damage_mult := (amount / max_hp) * 2.0
			var kb_force := base_kb * (1.0 + damage_mult)
			if is_crit: kb_force *= 1.5
			# Apply knockback weight - heavier enemies resist knockback
			kb_force /= knockback_weight
			var knockback := (global_position - from_pos).normalized() * kb_force
			velocity = knockback
			# Increase stagger duration for heavy hits
			stagger_timer = 0.3 + (damage_mult * 0.2)

	GameSystems.track("total_damage_dealt", amount)

	if hp <= 0:
		hp = 0
		_die()

func apply_stun(duration: float) -> void:
	stun_timer = maxf(stun_timer, duration)

func apply_scare(duration: float) -> void:
	scared_timer = maxf(scared_timer, duration)

func apply_bleed(dmg_per_sec: float, duration: float) -> void:
	if category == "standard" and stats.get("emoji", "") == "\U0001F480":
		return
	bleed_damage = dmg_per_sec
	bleed_timer = duration

func apply_burn(dmg_per_sec: float, duration: float) -> void:
	burn_damage = dmg_per_sec
	burn_timer = duration

func _die() -> void:
	is_alive = false
	state = State.DEAD
	death_timer = 0.5
	corpse_timer = 3.0
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	emoji_label.modulate = Color(0.5, 0.5, 0.5, 0.5)
	shadow_label.visible = false
	hp_bar_bg.visible = false
	hp_bar_fg.visible = false
	if elite_glow:
		elite_glow.visible = false

	# Improvement #30: Boss HP hide on death
	if category == "boss":
		GameSystems.boss_hp_updated.emit(stats.get("name", "Boss"), 0.0, false)
		GameSystems.track("bosses_killed")

	var loot_mult := GameSystems.get_diff_mult("loot")
	# Improvement #35b: Distance scaling bonus loot
	var dist_from_spawn_bonus := 1.0 + distance_level_bonus * 0.2
	enemy_died.emit(self, {
		"type": enemy_type,
		"position": global_position,
		"gold": int(gold_drop * loot_mult * dist_from_spawn_bonus),
		"xp": int(xp_value * dist_from_spawn_bonus),
		"category": category,
		"is_elite": is_elite,
		"overkill": absf(hp),
		"name": stats.get("name", "Enemy"),
		"color": stats.get("blood_color", Color(0.5, 0.0, 0.0)),
		"loot_count": loot_explosion_count,
		"elemental": elemental_type,
	})

func set_target(new_target: CharacterBody2D) -> void:
	target = new_target

func _update_visuals(delta: float) -> void:
	if hit_flash_timer > 0:
		var flash_intensity := hit_flash_timer / 0.15
		emoji_label.modulate = Color(1.0 + flash_intensity * 2.0, 0.3, 0.3)
	elif freeze_timer > 0:
		emoji_label.modulate = Color(0.5, 0.8, 1.5)
	elif burn_timer > 0:
		var burn_pulse := (sin(Time.get_ticks_msec() * 0.015) + 1.0) * 0.2
		emoji_label.modulate = Color(1.5 + burn_pulse, 0.8, 0.3)
	elif bleed_timer > 0:
		var bleed_pulse := (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.15
		emoji_label.modulate = Color(1.2 + bleed_pulse, 0.5, 0.5)
	elif is_enraged:
		var rage_pulse := (sin(Time.get_ticks_msec() * 0.02) + 1.0) * 0.3
		emoji_label.modulate = Color(1.5 + rage_pulse, 0.3, 0.3)
	elif is_fleeing:
		emoji_label.modulate = Color(0.8, 0.8, 0.5)
	elif is_elite:
		var elite_pulse := (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.1
		emoji_label.modulate = Color(1.0 + elite_pulse, 0.9 + elite_pulse, 0.3 + elite_pulse)
	elif not is_alive:
		pass
	else:
		emoji_label.modulate = Color.WHITE

	# Improvement #37: Ambush fade in/out
	if is_ambush and not ambush_revealed:
		emoji_label.modulate.a = ambush_alpha + sin(Time.get_ticks_msec() * 0.003) * 0.05
		shadow_label.modulate.a = 0.0
	elif is_ambush and ambush_revealed:
		emoji_label.modulate.a = minf(emoji_label.modulate.a + delta * 3.0, 1.0)

	if can_fly:
		bob_offset += bob_speed * delta
		var bob := sin(bob_offset) * 6.0
		emoji_label.position.y = -int(32 * emoji_scale) * 0.75 + bob - 10
		shadow_label.modulate.a = remap(10.0 + bob, 0, 30, 0.4, 0.15)

	if elite_glow and is_alive:
		elite_glow.modulate.a = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5

	# Improvement #31: Telegraph visual - flash before attack
	if is_telegraphing:
		var flash := sin(telegraph_timer * 30.0) * 0.5 + 0.5
		emoji_label.modulate = Color(1.0 + flash, 0.5, 0.5)
		var warn_scale := 1.0 + (1.0 - telegraph_timer / telegraph_duration) * 0.2
		emoji_label.scale = Vector2(warn_scale, warn_scale)

	# Improvement #43: Enrage particles
	if is_enraged and is_alive:
		enrage_particle_timer += delta
		if fmod(enrage_particle_timer, 0.3) < delta:
			var vfx_node := get_tree().get_first_node_in_group("vfx")
			if vfx_node and vfx_node.has_method("spawn_footstep_dust"):
				vfx_node.spawn_footstep_dust(global_position + Vector2(randf_range(-10, 10), 5))

	# Improvement #45: Execution indicator
	if execution_vulnerable and is_alive:
		var exec_flash := (sin(Time.get_ticks_msec() * 0.02) + 1.0) * 0.5
		emoji_label.modulate = Color(1.0, 0.3 + exec_flash * 0.3, 0.3)

	# Attack scale pulse
	if state == State.ATTACK and attack_cooldown_time > 0 and attack_timer > attack_cooldown_time * 0.7:
		var atk_t := (attack_timer - attack_cooldown_time * 0.7) / maxf(attack_cooldown_time * 0.3, 0.01)
		var scale_bump := 1.0 + atk_t * 0.15
		emoji_label.scale = Vector2(scale_bump, scale_bump)
	elif velocity.length() > 10.0:
		# Subtle squash/stretch on movement
		var spd_norm := minf(velocity.length() / maxf(move_speed, 1.0), 1.5)
		var move_dir := velocity.normalized()
		var sx := 1.0 + absf(move_dir.x) * spd_norm * 0.04
		var sy := 1.0 + absf(move_dir.y) * spd_norm * 0.04
		emoji_label.scale = Vector2(sx, sy)
	else:
		emoji_label.scale = Vector2(emoji_scale, emoji_scale)

	# Shadow follows movement direction
	if velocity.length() > 10.0:
		var s_offset := velocity.normalized() * 1.5
		shadow_label.position.x = -int(32 * emoji_scale) * 0.75 + s_offset.x
	else:
		shadow_label.position.x = -int(32 * emoji_scale) * 0.75

	if (state == State.CHASE or state == State.FLEEING) and target and is_instance_valid(target):
		var dir := (target.global_position - global_position).x
		emoji_label.scale.x = (-1.0 if dir < 0 else 1.0) * absf(emoji_label.scale.x)

func apply_freeze(duration: float) -> void:
	freeze_timer = maxf(freeze_timer, duration)

# ===== SIDESCROLLER MODE =====

func enter_sidescroller_mode() -> void:
	is_sidescroller = true
	ss_velocity_y = 0.0
	ss_on_ground = true
	ss_facing_right = randf() > 0.5
	ss_patrol_dir = 1.0 if ss_facing_right else -1.0
	# Set patrol bounds around current position
	ss_patrol_left = global_position.x - randf_range(80.0, 160.0)
	ss_patrol_right = global_position.x + randf_range(80.0, 160.0)
	ss_jump_timer = 0.0

	# Flatten shadow for side view
	if shadow_label:
		shadow_label.position = Vector2(-int(32 * emoji_scale) * 0.75, 4)
		shadow_label.modulate = Color(0, 0, 0, 0.3)
		shadow_label.scale = Vector2(1.0, 0.3)

func exit_sidescroller_mode() -> void:
	is_sidescroller = false
	ss_velocity_y = 0.0
	if shadow_label:
		shadow_label.modulate = Color(0, 0, 0, 0.4)
		shadow_label.scale = Vector2.ONE

func _ss_act(delta: float) -> void:
	# Apply gravity
	if not ss_on_ground:
		ss_velocity_y += ss_gravity * delta
		ss_velocity_y = minf(ss_velocity_y, 500.0)
		velocity.y = ss_velocity_y
	else:
		velocity.y = 0.0
		ss_velocity_y = 0.0

	ss_jump_timer = maxf(ss_jump_timer - delta, 0.0)

	match state:
		State.IDLE:
			_ss_patrol(delta)
		State.CHASE:
			_ss_chase(delta)
		State.ATTACK:
			_ss_attack()
		State.STAGGERED:
			velocity.x = velocity.x * 0.9
		State.STUNNED:
			velocity.x = 0.0
		State.SCARED, State.FLEEING:
			_ss_flee(delta)
		State.DEAD:
			velocity.x = 0.0

func _ss_patrol(delta: float) -> void:
	# Walk back and forth on platforms
	velocity.x = ss_patrol_dir * move_speed * 0.4

	# Reverse at patrol bounds
	if global_position.x > ss_patrol_right:
		ss_patrol_dir = -1.0
		ss_facing_right = false
	elif global_position.x < ss_patrol_left:
		ss_patrol_dir = 1.0
		ss_facing_right = true

	# Reverse at walls (if velocity is blocked)
	if is_on_wall():
		ss_patrol_dir *= -1.0
		ss_facing_right = not ss_facing_right

func _ss_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		velocity.x = 0.0
		return

	var dir_x: float = target.global_position.x - global_position.x
	var dir_y: float = target.global_position.y - global_position.y

	# Move toward target horizontally
	if absf(dir_x) > 10.0:
		velocity.x = signf(dir_x) * move_speed
		ss_facing_right = dir_x > 0
	else:
		velocity.x = 0.0

	# Jump if target is above and we're on the ground
	if dir_y < -40.0 and ss_on_ground and ss_jump_timer <= 0:
		ss_velocity_y = -350.0
		velocity.y = ss_velocity_y
		ss_on_ground = false
		ss_jump_timer = 1.5

	# Also jump if hitting a wall while chasing
	if is_on_wall() and ss_on_ground and ss_jump_timer <= 0:
		ss_velocity_y = -300.0
		velocity.y = ss_velocity_y
		ss_on_ground = false
		ss_jump_timer = 1.0

func _ss_attack() -> void:
	if attack_timer > 0:
		velocity.x = 0.0
		return
	attack_timer = attack_cooldown_time
	velocity.x = 0.0

	if target and is_instance_valid(target):
		if explodes:
			_explode()
		else:
			enemy_attacked.emit(target, damage, global_position)

func _ss_flee(delta: float) -> void:
	if target and is_instance_valid(target):
		var flee_dir := signf(global_position.x - target.global_position.x)
		velocity.x = flee_dir * move_speed * 1.3
		ss_facing_right = flee_dir > 0

		# Jump while fleeing for evasion
		if ss_on_ground and ss_jump_timer <= 0 and randf() < 0.02:
			ss_velocity_y = -280.0
			velocity.y = ss_velocity_y
			ss_on_ground = false
			ss_jump_timer = 2.0
	else:
		velocity.x = ss_patrol_dir * move_speed * 0.5

func _ss_check_ground() -> void:
	var was_on_ground := ss_on_ground
	ss_on_ground = is_on_floor()

	if ss_on_ground and not was_on_ground:
		ss_velocity_y = 0.0

	if ss_on_ground:
		velocity.y = 0.0
		ss_velocity_y = 0.0

func _ss_update_visuals(delta: float) -> void:
	# Reuse most of the top-down visual logic
	if hit_flash_timer > 0:
		var flash_intensity := hit_flash_timer / 0.15
		emoji_label.modulate = Color(1.0 + flash_intensity * 2.0, 0.3, 0.3)
	elif freeze_timer > 0:
		emoji_label.modulate = Color(0.5, 0.8, 1.5)
	elif burn_timer > 0:
		var burn_pulse := (sin(Time.get_ticks_msec() * 0.015) + 1.0) * 0.2
		emoji_label.modulate = Color(1.5 + burn_pulse, 0.8, 0.3)
	elif is_enraged:
		var rage_pulse := (sin(Time.get_ticks_msec() * 0.02) + 1.0) * 0.3
		emoji_label.modulate = Color(1.5 + rage_pulse, 0.3, 0.3)
	elif is_fleeing:
		emoji_label.modulate = Color(0.8, 0.8, 0.5)
	elif is_elite:
		var elite_pulse := (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.1
		emoji_label.modulate = Color(1.0 + elite_pulse, 0.9 + elite_pulse, 0.3 + elite_pulse)
	elif not is_alive:
		pass
	else:
		emoji_label.modulate = Color.WHITE

	# Flip based on facing
	if ss_facing_right:
		emoji_label.scale.x = absf(emoji_label.scale.x)
	else:
		emoji_label.scale.x = -absf(emoji_label.scale.x)

	# Attack scale pulse
	if state == State.ATTACK and attack_cooldown_time > 0 and attack_timer > attack_cooldown_time * 0.7:
		var atk_t := (attack_timer - attack_cooldown_time * 0.7) / maxf(attack_cooldown_time * 0.3, 0.01)
		var scale_bump := 1.0 + atk_t * 0.15
		emoji_label.scale.y = scale_bump
	else:
		emoji_label.scale.y = emoji_scale

	# Shadow stays flat at feet
	if shadow_label:
		shadow_label.position = Vector2(-int(32 * emoji_scale) * 0.75, 4)
		shadow_label.modulate = Color(0, 0, 0, 0.3)
		shadow_label.scale = Vector2(1.0, 0.3)

	if elite_glow and is_alive:
		elite_glow.modulate.a = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5

func _get_text_representation(emoji: String) -> String:
	var text_map := {
		"\U0001F480": "[X]",
		"\U0001F9DD\u200D\u2640\uFE0F": "[E]",
		"\u26CF\uFE0F": "[D]",
		"\U0001F9B9": "[O]",
		"\U0001F469\u200D\U0001F680": "[H]",
	}
	return text_map.get(emoji, emoji)
