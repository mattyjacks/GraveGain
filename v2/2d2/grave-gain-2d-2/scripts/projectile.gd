extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 10.0
var max_range: float = 500.0
var traveled: float = 0.0
var is_player_owned: bool = true
var pierce_count: int = 0
var max_pierce: int = 0

var trail_timer: float = 0.0
var emoji_label: Label = null
var trail_particles: Array[Dictionary] = []

func _ready() -> void:
	collision_layer = 16
	collision_mask = (2 | 4) if is_player_owned else (1 | 4)
	z_index = 15

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	emoji_label = Label.new()
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_label.position = Vector2(-8, -8)
	emoji_label.size = Vector2(16, 16)
	var settings := LabelSettings.new()
	if GameData.emoji_font:
		settings.font = GameData.emoji_font
	settings.font_size = 14
	emoji_label.label_settings = settings

	if is_player_owned:
		emoji_label.text = "\u2022"
		settings.font_color = Color(1.0, 0.9, 0.3)
	else:
		emoji_label.text = "\u2022"
		settings.font_color = Color(1.0, 0.3, 0.3)

	add_child(emoji_label)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var move := direction * speed * delta
	global_position += move
	traveled += move.length()

	if traveled >= max_range:
		queue_free()
		return

	trail_timer += delta
	if trail_timer >= 0.03:
		trail_timer = 0.0

func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if is_player_owned:
		if body.collision_layer & 2:
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
			pierce_count += 1
			if pierce_count > max_pierce:
				queue_free()
		elif body.collision_layer & 4:
			queue_free()
	else:
		if body.collision_layer & 1:
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
			queue_free()
		elif body.collision_layer & 4:
			queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

func setup(dir: Vector2, spd: float, dmg: float, rng_val: float, player_owned: bool = true) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	max_range = rng_val
	is_player_owned = player_owned
