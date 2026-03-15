extends CanvasLayer

# Elf mind puzzle: Simon-style pattern memory game
# Repeat increasingly complex sequences

signal minigame_finished(won: bool, reward: Dictionary)

var game_type: int = 1  # ELF_MIND
var player_ref: CharacterBody2D = null
var hud_ref: CanvasLayer = null

var sequence: Array[int] = []
var player_sequence: Array[int] = []
var level: int = 1
var is_active: bool = true
var is_playing_sequence: bool = false
var is_waiting_for_input: bool = false

var button_nodes: Array[Node2D] = []
var colors: Array[Color] = [
	Color(1.0, 0.3, 0.3),
	Color(0.3, 1.0, 0.3),
	Color(0.3, 0.3, 1.0),
	Color(1.0, 1.0, 0.3),
]

func _ready() -> void:
	layer = 100
	_build_ui()
	_start_level()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.1, 0.15, 0.9)
	add_child(bg)

	var title := Label.new()
	title.text = "🧠 MIND PUZZLE"
	title.position = Vector2(512, 50)
	title.size = Vector2(500, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 32
	ts.font_color = Color(0.6, 1.0, 0.8)
	title.label_settings = ts
	add_child(title)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.position = Vector2(512, 100)
	level_label.size = Vector2(200, 30)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts2 := LabelSettings.new()
	ts2.font_size = 24
	ts2.font_color = Color.WHITE
	level_label.label_settings = ts2
	add_child(level_label)

	var hint := Label.new()
	hint.text = "Watch and repeat the pattern!"
	hint.position = Vector2(512, 150)
	hint.size = Vector2(500, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts3 := LabelSettings.new()
	ts3.font_size = 14
	ts3.font_color = Color(0.7, 0.7, 0.7)
	hint.label_settings = ts3
	add_child(hint)

	# Create 4 buttons in a grid
	for i in range(4):
		var btn := Node2D.new()
		btn.position = Vector2(300 + (i % 2) * 220, 300 + (i / 2) * 220)
		btn.z_index = 101
		btn.set_meta("index", i)

		var rect := ColorRect.new()
		rect.size = Vector2(180, 180)
		rect.position = Vector2(-90, -90)
		rect.color = colors[i]
		btn.add_child(rect)

		var label := Label.new()
		label.text = str(i + 1)
		label.position = Vector2(-30, -20)
		label.size = Vector2(60, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var ts4 := LabelSettings.new()
		ts4.font_size = 28
		ts4.font_color = Color.BLACK
		label.label_settings = ts4
		btn.add_child(label)

		add_child(btn)
		button_nodes.append(btn)

func _process(delta: float) -> void:
	var level_label: Label = get_node_or_null("LevelLabel")
	if level_label:
		level_label.text = "Level: %d" % level

func _start_level() -> void:
	player_sequence.clear()
	sequence.append(randi() % 4)
	is_playing_sequence = true
	is_waiting_for_input = false

	await get_tree().create_timer(0.5).timeout
	_play_sequence()

func _play_sequence() -> void:
	for idx in sequence:
		await _flash_button(idx)
		await get_tree().create_timer(0.3).timeout

	is_playing_sequence = false
	is_waiting_for_input = true

func _flash_button(idx: int) -> void:
	if idx < 0 or idx >= button_nodes.size():
		return

	var btn = button_nodes[idx]
	var rect: ColorRect = btn.get_child(0)
	var original_color: Color = rect.color

	rect.color = original_color.lightened(0.5)
	await get_tree().create_timer(0.2).timeout
	rect.color = original_color

func _input(event: InputEvent) -> void:
	if not is_active or not is_waiting_for_input or event is not InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_pos: Vector2 = event.position

	for btn in button_nodes:
		if not is_instance_valid(btn):
			continue

		var dist: float = btn.position.distance_to(mouse_pos)
		if dist < 100.0:
			var idx: int = btn.get_meta("index", -1)
			if idx >= 0:
				player_sequence.append(idx)
				await _flash_button(idx)

				if player_sequence[player_sequence.size() - 1] != sequence[player_sequence.size() - 1]:
					_end_game(false)
					return

				if player_sequence.size() == sequence.size():
					level += 1
					await get_tree().create_timer(1.0).timeout
					_start_level()
			break

	get_tree().root.set_input_as_handled()

func _end_game(won: bool) -> void:
	is_active = false
	is_waiting_for_input = false
	var reward_gold: int = 40 + level * 10
	var reward_xp: int = 20 + level * 5

	var result_label := Label.new()
	if won:
		result_label.text = "Perfect!\nReached Level %d\n+%d Gold, +%d XP" % [level, reward_gold, reward_xp]
	else:
		result_label.text = "Game Over!\nReached Level %d\n+%d Gold, +%d XP" % [level, reward_gold, reward_xp]
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
