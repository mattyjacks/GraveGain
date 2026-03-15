extends Area2D

signal lore_picked_up(entry_id: String)

const LoreDatabase = preload("res://scripts/lore/lore_database.gd")

var entry_id: String = ""
var entry_data: Dictionary = {}
var is_collected: bool = false
var is_interactable: bool = false

var emoji_label: Label = null
var shadow_label: Label = null
var glow_label: Label = null
var interact_hint: Label = null
var collision_shape: CollisionShape2D = null

var bob_offset: float = 0.0
var glow_timer: float = 0.0
var hint_alpha: float = 0.0
var sparkle_timer: float = 0.0

var is_sign_type: bool = false
var is_gravestone_type: bool = false

func setup(lore_entry_id: String) -> void:
	entry_id = lore_entry_id
	var all_entries := LoreDatabase.get_all_entries()
	if entry_id in all_entries:
		entry_data = all_entries[entry_id]
	is_sign_type = entry_data.get("type", "") == "sign"
	is_gravestone_type = entry_data.get("type", "") == "gravestone"
	is_interactable = is_sign_type or is_gravestone_type

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = false
	z_index = 6
	bob_offset = randf() * TAU

	_build_nodes()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_nodes() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	if is_sign_type or is_gravestone_type:
		circle.radius = 40.0
	else:
		circle.radius = 18.0
	shape.shape = circle
	collision_shape = shape
	add_child(collision_shape)

	var type_info: Dictionary = LoreDatabase.TYPE_INFO.get(entry_data.get("type", "note"), {"emoji": "\U0001F4DD"})
	var emoji_text: String = type_info["emoji"]
	var font_size := 24
	var is_already_collected := LoreManager.has_collected(entry_id)
	var text_based: bool = GameSystems.get_setting("text_based_graphics") == true
	if text_based:
		emoji_text = _get_text_representation(emoji_text)

	if is_gravestone_type:
		font_size = 28
	elif is_sign_type:
		font_size = 22
	elif entry_data.get("type", "") == "book":
		font_size = 26
	elif entry_data.get("type", "") == "crystal":
		font_size = 22

	shadow_label = Label.new()
	shadow_label.text = emoji_text
	shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow_label.position = Vector2(-font_size * 0.75, -font_size * 0.25)
	shadow_label.size = Vector2(font_size * 1.5, font_size * 1.5)
	shadow_label.modulate = Color(0, 0, 0, 0.35)
	shadow_label.z_index = -1
	var ss := LabelSettings.new()
	if GameData.emoji_font and not text_based:
		ss.font = GameData.emoji_font
	ss.font_size = font_size
	shadow_label.label_settings = ss
	add_child(shadow_label)

	emoji_label = Label.new()
	emoji_label.text = emoji_text
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.position = Vector2(-font_size * 0.75, -font_size * 0.75)
	emoji_label.size = Vector2(font_size * 1.5, font_size * 1.5)
	var ls := LabelSettings.new()
	if GameData.emoji_font and not text_based:
		ls.font = GameData.emoji_font
	ls.font_size = font_size
	emoji_label.label_settings = ls
	add_child(emoji_label)

	if not is_sign_type and not is_gravestone_type and not is_already_collected:
		glow_label = Label.new()
		var glow_text := "\u2728"
		if text_based:
			glow_text = "[*]"
		glow_label.text = glow_text
		glow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glow_label.position = Vector2(-8, -font_size - 4)
		glow_label.size = Vector2(16, 16)
		var gs := LabelSettings.new()
		if GameData.emoji_font and not text_based:
			gs.font = GameData.emoji_font
		gs.font_size = 12
		glow_label.label_settings = gs
		add_child(glow_label)

	interact_hint = Label.new()
	interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interact_hint.position = Vector2(-60, font_size * 0.5 + 4)
	interact_hint.size = Vector2(120, 20)
	interact_hint.modulate.a = 0.0
	var hs := LabelSettings.new()
	hs.font_size = 11
	hs.font_color = Color(0.9, 0.85, 0.7)
	hs.outline_size = 2
	hs.outline_color = Color(0, 0, 0)
	interact_hint.label_settings = hs
	add_child(interact_hint)

	if is_sign_type:
		interact_hint.text = "[E] Read Sign"
	elif is_gravestone_type:
		interact_hint.text = "[E] Read Gravestone"
	else:
		interact_hint.text = "[E] Pick Up"

	if is_already_collected:
		emoji_label.modulate = Color(0.6, 0.6, 0.6, 0.7)

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	glow_timer += delta
	sparkle_timer += delta

	if not is_sign_type and not is_gravestone_type:
		bob_offset += delta * 2.5
		var bob := sin(bob_offset) * 3.0
		emoji_label.position.y = -18 + bob

	var is_already_collected := LoreManager.has_collected(entry_id)
	if not is_already_collected:
		var pulse := (sin(glow_timer * 3.0) + 1.0) * 0.1
		var rarity_color := _get_rarity_glow()
		emoji_label.modulate = Color(
			rarity_color.r + pulse,
			rarity_color.g + pulse,
			rarity_color.b + pulse
		)
		if glow_label:
			glow_label.modulate.a = (sin(glow_timer * 4.0) + 1.0) * 0.5

	var hint_target := 1.0 if (is_interactable and not is_collected) else 0.0
	hint_alpha = move_toward(hint_alpha, hint_target, delta * 4.0)
	interact_hint.modulate.a = hint_alpha

func _get_rarity_glow() -> Color:
	match entry_data.get("rarity", "common"):
		"common":
			return Color(1.0, 1.0, 1.0)
		"uncommon":
			return Color(0.4, 1.0, 0.4)
		"rare":
			return Color(0.4, 0.6, 1.0)
		"epic":
			return Color(0.7, 0.3, 1.0)
		"legendary":
			return Color(1.0, 0.7, 0.2)
	return Color.WHITE

func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body) or is_collected:
		return
	if body.is_in_group("players"):
		is_interactable = true
		if not is_sign_type and not is_gravestone_type:
			pickup(body)

func _on_body_exited(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body.is_in_group("players"):
		is_interactable = false

func setup_random() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var picked_id := LoreManager.pick_room_lore(rng)
	if picked_id != "":
		setup(picked_id)
	else:
		# No lore available, remove self
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not is_interactable or is_collected:
		return
	if Input.is_action_just_pressed("interact"):
		if is_sign_type or is_gravestone_type:
			_read_in_place()
			get_viewport().set_input_as_handled()
		else:
			pickup(null)
			get_viewport().set_input_as_handled()

func pickup(_player: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	var is_new := LoreManager.collect_entry(entry_id)
	lore_picked_up.emit(entry_id)

	if glow_label:
		glow_label.queue_free()
		glow_label = null

	_show_collect_animation(is_new)

func _read_in_place() -> void:
	if is_collected:
		return
	LoreManager.collect_entry(entry_id)
	is_collected = true
	lore_picked_up.emit(entry_id)

func _get_text_representation(emoji: String) -> String:
	var text_map := {
		"\U0001F4DD": "[N]",
		"\U0001F4DA": "[B]",
		"\U0001F4C4": "[S]",
		"\u26B0\uFE0F": "[G]",
		"\U0001F52E": "[C]",
		"\U0001F4E7": "[L]",
		"\U0001F5DD": "[J]",
		"\u270E\uFE0F": "[T]",
	}
	return text_map.get(emoji, emoji)

func _show_collect_animation(is_new: bool) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(emoji_label, "position:y", emoji_label.position.y - 40, 0.5)
	tween.tween_property(emoji_label, "modulate:a", 0.0, 0.5)
	tween.tween_property(shadow_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(interact_hint, "modulate:a", 0.0, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
