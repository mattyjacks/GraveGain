extends CanvasLayer

# Human phone mini-game: tap-timing rhythm game
# Hit the targets as they scroll down

signal minigame_finished(won: bool, reward: Dictionary)

var game_type: int = 0  # HUMAN_PHONE
var player_ref: CharacterBody2D = null
var hud_ref: CanvasLayer = null

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var game_duration: float = 15.0
var time_remaining: float = 15.0
var is_active: bool = true

var target_nodes: Array[Node2D] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 0.5

func _ready() -> void:
	layer = 100
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.1, 0.15, 0.9)
	add_child(bg)

	var title := Label.new()
	title.text = "📱 PHONE RHYTHM"
	title.position = Vector2(512, 50)
	title.size = Vector2(500, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 32
	ts.font_color = Color(0.8, 1.0, 0.6)
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
	ts3.font_color = Color(1.0, 0.8, 0.4)
	score_label.label_settings = ts3
	add_child(score_label)

	var combo_label := Label.new()
	combo_label.name = "ComboLabel"
	combo_label.position = Vector2(900, 100)
	combo_label.size = Vector2(200, 30)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var ts4 := LabelSettings.new()
	ts4.font_size = 20
	ts4.font_color = Color(1.0, 0.5, 0.5)
	combo_label.label_settings = ts4
	add_child(combo_label)

	var hint := Label.new()
	hint.text = "Tap targets as they reach the bottom!"
	hint.position = Vector2(512, 150)
	hint.size = Vector2(500, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts5 := LabelSettings.new()
	ts5.font_size = 14
	ts5.font_color = Color(0.7, 0.7, 0.7)
	hint.label_settings = ts5
	add_child(hint)

func _process(delta: float) -> void:
	if not is_active:
		return

	time_remaining -= delta
	spawn_timer += delta

	# Update timer display
	var timer_label: Label = get_node_or_null("TimerLabel")
	if timer_label:
		timer_label.text = "Time: %.1f" % maxf(time_remaining, 0.0)

	var score_label: Label = get_node_or_null("ScoreLabel")
	if score_label:
		score_label.text = "Score: %d" % score

	var combo_label: Label = get_node_or_null("ComboLabel")
	if combo_label:
		combo_label.text = "Combo: %d" % combo

	# Spawn targets
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_target()

	# Update target positions
	for target in target_nodes:
		if is_instance_valid(target):
			target.position.y += 200.0 * delta
			if target.position.y > 700:
				target.queue_free()
				target_nodes.erase(target)
				combo = 0

	if time_remaining <= 0:
		_end_game()

func _spawn_target() -> void:
	var target := Node2D.new()
	target.position = Vector2(randf_range(200, 824), 200)
	target.z_index = 101

	var circle := ColorRect.new()
	circle.size = Vector2(60, 60)
	circle.position = Vector2(-30, -30)
	circle.color = Color(0.3, 0.8, 1.0, 0.8)
	target.add_child(circle)

	var label := Label.new()
	label.text = "TAP"
	label.position = Vector2(-20, -15)
	label.size = Vector2(40, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 12
	ts.font_color = Color.WHITE
	label.label_settings = ts
	target.add_child(label)

	target.set_meta("hit", false)
	add_child(target)
	target_nodes.append(target)

func _input(event: InputEvent) -> void:
	if not is_active or event is not InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_pos: Vector2 = event.position

	for target in target_nodes:
		if not is_instance_valid(target):
			continue
		if target.get_meta("hit", false):
			continue

		var dist: float = target.position.distance_to(mouse_pos)
		if dist < 40.0:
			target.set_meta("hit", true)
			score += 10 + combo * 2
			combo += 1
			max_combo = maxi(max_combo, combo)
			target.queue_free()
			target_nodes.erase(target)
			break

	get_tree().root.set_input_as_handled()

func _end_game() -> void:
	is_active = false
	var reward_gold: int = 50 + score / 2
	var reward_xp: int = 25 + max_combo * 2

	var result_label := Label.new()
	result_label.text = "Game Over!\nScore: %d\nMax Combo: %d\n+%d Gold, +%d XP" % [score, max_combo, reward_gold, reward_xp]
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
