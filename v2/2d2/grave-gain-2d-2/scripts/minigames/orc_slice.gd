extends CanvasLayer

# Orc slice mini-game: swipe to slice fruit/meat
# Build combos for bonus points

signal minigame_finished(won: bool, reward: Dictionary)

var game_type: int = 3  # ORC_SLICE
var player_ref: CharacterBody2D = null
var hud_ref: CanvasLayer = null

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var time_remaining: float = 20.0
var is_active: bool = true

var objects: Array[Node2D] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 0.6

var slice_trail: Line2D = null
var is_swiping: bool = false
var swipe_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	layer = 100
	_build_ui()
	_setup_slice_trail()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.2, 0.1, 0.05, 0.9)
	add_child(bg)

	var title := Label.new()
	title.text = "🔪 SLICE & DICE"
	title.position = Vector2(512, 50)
	title.size = Vector2(500, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 32
	ts.font_color = Color(1.0, 0.5, 0.3)
	title.label_settings = ts
	add_child(title)

	var timer_label := Label.new()
	timer_label.name = "TimerLabel"
	timer_label.position = Vector2(512, 100)
	timer_label.size = Vector2(200, 30)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts2 := LabelSettings.new()
	ts2.font_size = 24
	ts2.font_color = Color.WHITE
	timer_label.label_settings = ts2
	add_child(timer_label)

	var score_label := Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(50, 100)
	score_label.size = Vector2(200, 30)
	var ts3 := LabelSettings.new()
	ts3.font_size = 20
	ts3.font_color = Color(1.0, 0.6, 0.3)
	score_label.label_settings = ts3
	add_child(score_label)

	var combo_label := Label.new()
	combo_label.name = "ComboLabel"
	combo_label.position = Vector2(900, 100)
	combo_label.size = Vector2(200, 30)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var ts4 := LabelSettings.new()
	ts4.font_size = 20
	ts4.font_color = Color(1.0, 0.3, 0.3)
	combo_label.label_settings = ts4
	add_child(combo_label)

	var hint := Label.new()
	hint.text = "Swipe to slice the objects!"
	hint.position = Vector2(512, 150)
	hint.size = Vector2(500, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts5 := LabelSettings.new()
	ts5.font_size = 14
	ts5.font_color = Color(0.7, 0.7, 0.7)
	hint.label_settings = ts5
	add_child(hint)

func _setup_slice_trail() -> void:
	slice_trail = Line2D.new()
	slice_trail.width = 4.0
	slice_trail.default_color = Color(1.0, 0.8, 0.2, 0.8)
	slice_trail.z_index = 102
	add_child(slice_trail)

func _process(delta: float) -> void:
	if not is_active:
		return

	time_remaining -= delta
	spawn_timer += delta

	var timer_label: Label = get_node_or_null("TimerLabel")
	if timer_label:
		timer_label.text = "Time: %.1f" % maxf(time_remaining, 0.0)

	var score_label: Label = get_node_or_null("ScoreLabel")
	if score_label:
		score_label.text = "Score: %d" % score

	var combo_label: Label = get_node_or_null("ComboLabel")
	if combo_label:
		combo_label.text = "Combo: %d" % combo

	# Spawn objects
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_object()

	# Update object positions
	for obj in objects:
		if is_instance_valid(obj):
			obj.position.y += 150.0 * delta
			if obj.position.y > 700:
				obj.queue_free()
				objects.erase(obj)
				combo = 0

	if time_remaining <= 0:
		_end_game()

func _spawn_object() -> void:
	var obj := Node2D.new()
	obj.position = Vector2(randf_range(150, 874), 100)
	obj.z_index = 101

	var emoji_label := Label.new()
	var emojis := ["🍎", "🍊", "🍌", "🥩", "🍖"]
	emoji_label.text = emojis[randi() % emojis.size()]
	emoji_label.position = Vector2(-20, -20)
	emoji_label.size = Vector2(40, 40)
	var ts := LabelSettings.new()
	ts.font_size = 32
	emoji_label.label_settings = ts
	obj.add_child(emoji_label)

	obj.set_meta("hit", false)
	add_child(obj)
	objects.append(obj)

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_swiping = true
			swipe_start = event.position
			slice_trail.clear_points()
			slice_trail.add_point(swipe_start)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_swiping = false
			slice_trail.clear_points()

	elif event is InputEventMouseMotion and is_swiping:
		slice_trail.add_point(event.position)

		# Check for hits along the swipe
		for obj in objects:
			if not is_instance_valid(obj):
				continue
			if obj.get_meta("hit", false):
				continue

			var dist: float = obj.position.distance_to(event.position)
			if dist < 50.0:
				obj.set_meta("hit", true)
				score += 15 + combo * 3
				combo += 1
				max_combo = maxi(max_combo, combo)

				# Slice effect
				var particles := GPUParticles2D.new()
				particles.position = obj.position
				particles.z_index = 102
				particles.amount = 8
				particles.lifetime = 0.5
				particles.emitting = true

				var mat := ParticleProcessMaterial.new()
				mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				mat.emission_sphere_radius = 20.0
				mat.gravity = Vector3(0, 100, 0)
				mat.initial_velocity_min = 100.0
				mat.initial_velocity_max = 200.0
				mat.color = Color(1.0, 0.6, 0.2, 0.8)
				particles.process_material = mat
				add_child(particles)

				obj.queue_free()
				objects.erase(obj)
				break

	get_tree().root.set_input_as_handled()

func _end_game() -> void:
	is_active = false
	var reward_gold: int = 55 + score / 3
	var reward_xp: int = 28 + max_combo * 3

	var result_label := Label.new()
	result_label.text = "Time's Up!\nScore: %d\nMax Combo: %d\n+%d Gold, +%d XP" % [score, max_combo, reward_gold, reward_xp]
	result_label.position = Vector2(512, 400)
	result_label.size = Vector2(400, 200)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 20
	ts.font_color = Color.WHITE
	result_label.label_settings = ts
	add_child(result_label)

	await get_tree().create_timer(3.0).timeout
	minigame_finished.emit(true, {"gold": reward_gold, "xp": reward_xp})
	queue_free()
