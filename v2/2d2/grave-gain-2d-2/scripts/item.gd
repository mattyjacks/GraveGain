extends Area2D

signal item_collected(item_data: Dictionary)

var item_type: String = "gold_coin"
var item_data: Dictionary = {}
var is_food: bool = false
var food_data: Dictionary = {}

var emoji_label: Label = null
var shadow_label: Label = null
var glow_timer: float = 0.0
var bob_offset: float = 0.0
var auto_pickup_radius: float = 40.0
var magnet_radius: float = 80.0
var is_auto_pickup: bool = false
var sparkle_timer: float = 0.0
var magnet_speed: float = 200.0

# Improvement #66: Rarity system
var rarity: String = "common"
var rarity_colors: Dictionary = {
	"common": Color(1.0, 1.0, 1.0),
	"uncommon": Color(0.3, 1.0, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
	"legendary": Color(1.0, 0.7, 0.1),
}

# Improvement #67b: Spin animation
var spin_speed: float = 0.0
var spin_angle: float = 0.0

# Improvement #68: Buff items
var is_buff_item: bool = false
var buff_type: String = ""
var buff_duration: float = 0.0
var buff_value: float = 0.0

# Improvement #69: Health orb (spawned from kills)
var is_health_orb: bool = false
var health_orb_amount: float = 0.0

# Improvement #70: Multiplier pickups
var is_multiplier: bool = false
var multiplier_type: String = ""
var multiplier_value: float = 1.0
var multiplier_duration: float = 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	z_index = 5
	bob_offset = randf() * TAU
	var pickup_range = GameSystems.get_setting("auto_pickup_range")
	auto_pickup_radius = pickup_range if pickup_range and pickup_range > 0 else 40.0
	magnet_radius = auto_pickup_radius * 2.0

	_build_nodes()

func setup_item(type: String) -> void:
	item_type = type
	if type in GameData.item_defs:
		item_data = GameData.item_defs[type]
		is_food = false
		is_auto_pickup = type == "gold_coin"
		# Improvement #66: Assign rarity
		rarity = item_data.get("rarity", "common")
		# Improvement #67b: Rare+ items spin
		if rarity in ["rare", "epic", "legendary"]:
			spin_speed = 2.0
			is_auto_pickup = true
	elif type in GameData.food_defs:
		food_data = GameData.food_defs[type]
		is_food = true
		is_auto_pickup = true
		item_data = food_data
	# Improvement #68: Buff item types
	elif type == "speed_boost":
		is_buff_item = true
		buff_type = "speed"
		buff_duration = 10.0
		buff_value = 1.3
		is_auto_pickup = true
		item_data = {"emoji": "\u26A1", "type": "buff", "name": "Speed Boost"}
		rarity = "uncommon"
	elif type == "damage_boost":
		is_buff_item = true
		buff_type = "damage"
		buff_duration = 10.0
		buff_value = 1.5
		is_auto_pickup = true
		item_data = {"emoji": "\u2694\uFE0F", "type": "buff", "name": "Damage Boost"}
		rarity = "rare"
	elif type == "shield_orb":
		is_buff_item = true
		buff_type = "shield"
		buff_duration = 0.0
		buff_value = 25.0
		is_auto_pickup = true
		item_data = {"emoji": "\U0001F6E1\uFE0F", "type": "buff", "name": "Shield Orb"}
		rarity = "uncommon"
	elif type == "rage_potion":
		is_buff_item = true
		buff_type = "rage"
		buff_duration = 0.0
		buff_value = 50.0
		is_auto_pickup = true
		item_data = {"emoji": "\U0001F4A2", "type": "buff", "name": "Rage Potion"}
		rarity = "uncommon"
	elif type == "health_orb":
		is_health_orb = true
		health_orb_amount = 10.0
		is_auto_pickup = true
		item_data = {"emoji": "\u2764\uFE0F", "type": "health_orb", "name": "Health Orb"}
		rarity = "common"
	elif type == "gold_multiplier":
		is_multiplier = true
		multiplier_type = "gold"
		multiplier_value = 2.0
		multiplier_duration = 30.0
		is_auto_pickup = true
		item_data = {"emoji": "\U0001FA99", "type": "multiplier", "name": "Gold x2"}
		rarity = "rare"
	elif type == "xp_multiplier":
		is_multiplier = true
		multiplier_type = "xp"
		multiplier_value = 2.0
		multiplier_duration = 30.0
		is_auto_pickup = true
		item_data = {"emoji": "\u2B50", "type": "multiplier", "name": "XP x2"}
		rarity = "epic"

func _build_nodes() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)

	var emoji_text: String
	if is_food:
		emoji_text = food_data.get("emoji", "\U0001F34E")
	else:
		emoji_text = item_data.get("emoji", "\U0001FA99")

	shadow_label = Label.new()
	shadow_label.text = emoji_text
	shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow_label.position = Vector2(-12, -4)
	shadow_label.size = Vector2(24, 24)
	shadow_label.modulate = Color(0, 0, 0, 0.35)
	shadow_label.z_index = -1
	var shadow_settings := LabelSettings.new()
	shadow_settings.font = GameData.emoji_font
	shadow_settings.font_size = 18
	shadow_label.label_settings = shadow_settings
	add_child(shadow_label)

	emoji_label = Label.new()
	emoji_label.text = emoji_text
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.position = Vector2(-12, -12)
	emoji_label.size = Vector2(24, 24)
	var label_settings := LabelSettings.new()
	label_settings.font = GameData.emoji_font
	label_settings.font_size = 18
	emoji_label.label_settings = label_settings
	add_child(emoji_label)

func _physics_process(delta: float) -> void:
	glow_timer += delta
	bob_offset += delta * 2.0
	sparkle_timer += delta

	var bob := sin(bob_offset) * 3.0
	emoji_label.position.y = -12 + bob

	# Improvement #66: Rarity glow color
	var glow_pulse := (sin(glow_timer * 3.0) + 1.0) * 0.15
	var base_color: Color = rarity_colors.get(rarity, Color.WHITE)
	emoji_label.modulate = Color(
		base_color.r + glow_pulse,
		base_color.g + glow_pulse,
		base_color.b + glow_pulse
	)

	# Improvement #67b: Spin animation for rare+ items
	if spin_speed > 0:
		spin_angle += spin_speed * delta
		var scale_x := cos(spin_angle)
		emoji_label.scale.x = absf(scale_x) * 0.8 + 0.2

	# Improvement #66: Legendary items pulse bigger
	if rarity == "legendary":
		var legend_pulse := 1.0 + sin(glow_timer * 5.0) * 0.1
		emoji_label.scale = Vector2(legend_pulse, legend_pulse)

	if is_auto_pickup:
		_check_auto_pickup()

func _check_auto_pickup() -> void:
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		if not is_instance_valid(player):
			continue
		if player is CharacterBody2D and player.has_method("add_gold"):
			var dist := global_position.distance_to(player.global_position)
			# Improvement #67c: Magnet radius scales with player level
			var level_bonus := GameSystems.player_level * 3.0
			var effective_magnet := magnet_radius + level_bonus
			var effective_pickup := auto_pickup_radius + level_bonus * 0.5
			if dist < effective_pickup:
				pickup(player)
				return
			# Magnetic pull when close enough
			elif dist < effective_magnet and dist > 0:
				var pull_strength := 1.0 - (dist / effective_magnet)
				var dir: Vector2 = (player.global_position - global_position).normalized()
				global_position += dir * magnet_speed * pull_strength * get_physics_process_delta_time()

var _picked_up: bool = false

func pickup(player: CharacterBody2D) -> void:
	if _picked_up:
		return
	_picked_up = true
	if is_food:
		if player.has_method("eat_food"):
			player.eat_food(food_data)
		item_collected.emit(food_data)
		queue_free()
		return

	# Improvement #69: Health orb
	if is_health_orb:
		if player.has_method("heal"):
			player.heal(health_orb_amount, false)
		var vfx_node := get_tree().get_first_node_in_group("vfx")
		if vfx_node and vfx_node.has_method("spawn_heal_particles"):
			vfx_node.spawn_heal_particles(player.global_position, health_orb_amount)
		item_collected.emit(item_data)
		queue_free()
		return

	# Improvement #68: Buff items
	if is_buff_item:
		_apply_buff(player)
		item_collected.emit(item_data)
		queue_free()
		return

	# Improvement #70: Multiplier pickups
	if is_multiplier:
		_apply_multiplier(player)
		item_collected.emit(item_data)
		queue_free()
		return

	var loot_mult := GameSystems.get_diff_mult("loot")
	match item_data.get("type", ""):
		"treasure":
			if player.has_method("add_gold"):
				var gold_val := int(float(item_data.get("value", 0)) / 100.0 * loot_mult)
				gold_val = maxi(gold_val, 1)
				player.add_gold(gold_val)
				GameSystems.track("total_gold_earned", gold_val)
		"consumable":
			if item_data.has("heals"):
				if player.has_method("heal"):
					player.heal(item_data["heals"], item_data.get("heals_real", false))
				GameSystems.track("health_potions_used")
				var vfx_node := get_tree().get_first_node_in_group("vfx")
				if vfx_node and vfx_node.has_method("spawn_heal_particles"):
					vfx_node.spawn_heal_particles(player.global_position, item_data["heals"])
			if item_data.has("mana"):
				if player.has_method("restore_mana"):
					player.restore_mana(item_data["mana"])
				GameSystems.track("mana_potions_used")
		"ammo":
			if player.has_method("restore_ammo"):
				player.restore_ammo(item_data.get("ammo_pct", 0.1))

	item_collected.emit(item_data)
	queue_free()

# Improvement #68: Apply buff to player
func _apply_buff(player: CharacterBody2D) -> void:
	match buff_type:
		"speed":
			if "run_speed" in player:
				player.run_speed *= buff_value
				# Speed buff wears off via timer in player
		"damage":
			if "melee_damage" in player:
				player.melee_damage *= buff_value
				player.ranged_damage *= buff_value
		"shield":
			if player.has_method("add_temp_hp"):
				player.add_temp_hp(buff_value)
		"rage":
			if "rage" in player and "max_rage" in player:
				player.rage = minf(player.rage + buff_value, player.max_rage)
				if player.has_signal("rage_changed"):
					player.rage_changed.emit(player.rage, player.max_rage)
	var hud_node := get_tree().get_first_node_in_group("hud")
	if hud_node and hud_node.has_method("add_buff"):
		hud_node.add_buff(buff_type, buff_duration, item_data.get("emoji", ""))

func _apply_multiplier(_player: CharacterBody2D) -> void:
	GameSystems.track("multiplier_" + multiplier_type + "_active", multiplier_value)
	var hud_node := get_tree().get_first_node_in_group("hud")
	if hud_node and hud_node.has_method("add_buff"):
		hud_node.add_buff(multiplier_type + "_mult", multiplier_duration, item_data.get("emoji", ""))
