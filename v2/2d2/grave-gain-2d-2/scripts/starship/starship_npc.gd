extends Area2D

# ===== STARSHIP NPC =====
# Interactive NPCs on the starship with dialogue, services, and emoji display

signal npc_interacted(npc_data: Dictionary)

var npc_data: Dictionary = {}
var emoji_label: Label = null
var name_label: Label = null
var prompt_label: Label = null
var is_player_nearby: bool = false
var bob_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Detect player
	z_index = 10
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	add_child(shape)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup(data: Dictionary) -> void:
	npc_data = data
	global_position = data.get("position", Vector2.ZERO)
	_build_visuals()

func _build_visuals() -> void:
	# NPC emoji
	emoji_label = Label.new()
	emoji_label.text = npc_data.get("emoji", "\U0001F464")
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.position = Vector2(-16, -24)
	emoji_label.size = Vector2(32, 32)
	var emoji_settings := LabelSettings.new()
	emoji_settings.font = GameData.emoji_font
	emoji_settings.font_size = 24
	emoji_label.label_settings = emoji_settings
	add_child(emoji_label)
	
	# Name label below
	name_label = Label.new()
	name_label.text = npc_data.get("name", "NPC")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-50, 10)
	name_label.size = Vector2(100, 20)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	name_label.add_theme_font_size_override("font_size", 10)
	add_child(name_label)
	
	# Interaction prompt (hidden by default)
	prompt_label = Label.new()
	prompt_label.text = "[E] Talk"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-30, -40)
	prompt_label.size = Vector2(60, 20)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.visible = false
	add_child(prompt_label)

func _physics_process(delta: float) -> void:
	bob_timer += delta
	if emoji_label:
		emoji_label.position.y = -24 + sin(bob_timer * 2.0) * 2.0
	
	if is_player_nearby and prompt_label:
		prompt_label.modulate.a = 0.7 + sin(bob_timer * 4.0) * 0.3

func interact() -> void:
	npc_interacted.emit(npc_data)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		is_player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("players"):
		is_player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func get_dialogue() -> Array:
	return npc_data.get("dialogue", ["..."])

func get_npc_type() -> String:
	return npc_data.get("type", "generic")
