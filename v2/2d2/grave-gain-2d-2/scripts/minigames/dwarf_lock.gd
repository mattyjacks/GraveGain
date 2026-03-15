extends CanvasLayer

# Dwarf mechanical lock puzzle: rotate dials to match target
# Timing windows for bonus points

signal minigame_finished(won: bool, reward: Dictionary)

var game_type: int = 2  # DWARF_LOCK
var player_ref: CharacterBody2D = null
var hud_ref: CanvasLayer = null

var dials: Array[int] = [0, 0, 0]
var target: Array[int] = [0, 0, 0]
var score: int = 0
var time_remaining: float = 20.0
var is_active: bool = true

var dial_nodes: Array[Node2D] = []

func _ready() -> void:
	layer = 100
	_build_ui()
	_generate_puzzle()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.15, 0.1, 0.08, 0.9)
	add_child(bg)

	var title := Label.new()
	title.text = "🔧 MECHANICAL LOCK"
	title.position = Vector2(512, 50)
	title.size = Vector2(500, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 32
	ts.font_color = Color(1.0, 0.8, 0.4)
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

	var hint := Label.new()
	hint.text = "Click dials to rotate. Match the target!"
	hint.position = Vector2(512, 150)
	hint.size = Vector2(500, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts3 := LabelSettings.new()
	ts3.font_size = 14
	ts3.font_color = Color(0.7, 0.7, 0.7)
	hint.label_settings = ts3
	add_child(hint)

	# Create 3 dials
	for i in range(3):
		var dial := Node2D.new()
		dial.position = Vector2(250 + i * 260, 350)
		dial.z_index = 101
		dial.set_meta("index", i)

		var bg_circle := ColorRect.new()
		bg_circle.size = Vector2(120, 120)
		bg_circle.position = Vector2(-60, -60)
		bg_circle.color = Color(0.3, 0.25, 0.2)
		dial.add_child(bg_circle)

		var value_label := Label.new()
		value_label.name = "ValueLabel"
		value_label.text = "0"
		value_label.position = Vector2(-30, -20)
		value_label.size = Vector2(60, 40)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var ts4 := LabelSettings.new()
		ts4.font_size = 32
		ts4.font_color = Color(1.0, 0.8, 0.4)
		value_label.label_settings = ts4
		dial.add_child(value_label)

		add_child(dial)
		dial_nodes.append(dial)

	# Target display
	var target_label := Label.new()
	target_label.name = "TargetLabel"
	target_label.text = "TARGET: 0-0-0"
	target_label.position = Vector2(512, 520)
	target_label.size = Vector2(300, 30)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts5 := LabelSettings.new()
	ts5.font_size = 18
	ts5.font_color = Color(0.6, 1.0, 0.6)
	target_label.label_settings = ts5
	add_child(target_label)

func _generate_puzzle() -> void:
	for i in range(3):
		target[i] = randi() % 10
		dials[i] = randi() % 10

func _process(delta: float) -> void:
	time_remaining -= delta

	var timer_label: Label = get_node_or_null("TimerLabel")
	if timer_label:
		timer_label.text = "Time: %.1f" % maxf(time_remaining, 0.0)

	var target_label: Label = get_node_or_null("TargetLabel")
	if target_label:
		target_label.text = "TARGET: %d-%d-%d" % [target[0], target[1], target[2]]

	# Update dial displays
	for i in range(3):
		if i < dial_nodes.size():
			var dial = dial_nodes[i]
			var value_label: Label = dial.get_node_or_null("ValueLabel")
			if value_label:
				value_label.text = str(dials[i])

	# Check if solved
	if dials == target:
		_end_game(true)
	elif time_remaining <= 0:
		_end_game(false)

func _input(event: InputEvent) -> void:
	if not is_active or event is not InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_pos: Vector2 = event.position

	for dial in dial_nodes:
		if not is_instance_valid(dial):
			continue

		var dist: float = dial.position.distance_to(mouse_pos)
		if dist < 70.0:
			var idx: int = dial.get_meta("index", -1)
			if idx >= 0:
				dials[idx] = (dials[idx] + 1) % 10
				score += 5
			break

	get_tree().root.set_input_as_handled()

func _end_game(won: bool) -> void:
	is_active = false
	var reward_gold: int = 60 if won else 20
	var reward_xp: int = 30 if won else 10

	var result_label := Label.new()
	if won:
		result_label.text = "Lock Opened!\n+%d Gold, +%d XP" % [reward_gold, reward_xp]
	else:
		result_label.text = "Time's Up!\n+%d Gold, +%d XP" % [reward_gold, reward_xp]
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
