extends CanvasLayer

signal joystick_input(direction: Vector2)
signal special_pressed()
signal light_pressed()
signal inventory_pressed()
signal stats_pressed()
signal dodge_pressed()

var is_touch_mode: bool = false

# Joystick
var joystick_outer: Control
var joystick_inner: Control
var joystick_center: Vector2 = Vector2.ZERO
var joystick_radius: float = 60.0
var joystick_touch_index: int = -1
var joystick_direction: Vector2 = Vector2.ZERO
var joystick_deadzone: float = 0.15

# Action buttons
var btn_special: Control
var btn_light: Control
var btn_dodge: Control
var btn_inventory: Control
var btn_stats: Control

# Auto-attack indicator
var auto_attack_label: Label
var auto_attack_enabled: bool = true

# Layout
var screen_size: Vector2 = Vector2(1152, 648)
var button_size: float = 64.0
var joystick_size: float = 140.0

func _ready() -> void:
	is_touch_mode = _detect_touch()
	if not is_touch_mode:
		visible = false
		return

	layer = 100
	_build_touch_ui()

func _detect_touch() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web"):
		return DisplayServer.is_touchscreen_available()
	return false

func force_touch_mode(enabled: bool) -> void:
	is_touch_mode = enabled
	visible = enabled
	if enabled and joystick_outer == null:
		_build_touch_ui()

func _build_touch_ui() -> void:
	screen_size = get_viewport().get_visible_rect().size

	_build_joystick()
	_build_action_buttons()
	_build_top_bar_buttons()
	_build_auto_attack_indicator()

func _build_joystick() -> void:
	var joystick_pos := Vector2(30.0 + joystick_size * 0.5, screen_size.y - 30.0 - joystick_size * 0.5)

	# Outer ring
	joystick_outer = Control.new()
	joystick_outer.position = joystick_pos - Vector2(joystick_size * 0.5, joystick_size * 0.5)
	joystick_outer.size = Vector2(joystick_size, joystick_size)

	var outer_bg := ColorRect.new()
	outer_bg.size = Vector2(joystick_size, joystick_size)
	outer_bg.color = Color(0.2, 0.2, 0.3, 0.35)
	joystick_outer.add_child(outer_bg)

	# Outer ring border (using 4 thin rects as border)
	var border_w := 2.0
	var border_color := Color(0.5, 0.5, 0.7, 0.5)
	for data in [
		[Vector2(0, 0), Vector2(joystick_size, border_w)],
		[Vector2(0, joystick_size - border_w), Vector2(joystick_size, border_w)],
		[Vector2(0, 0), Vector2(border_w, joystick_size)],
		[Vector2(joystick_size - border_w, 0), Vector2(border_w, joystick_size)],
	]:
		var b := ColorRect.new()
		b.position = data[0]
		b.size = data[1]
		b.color = border_color
		joystick_outer.add_child(b)

	add_child(joystick_outer)

	# Inner knob
	var knob_size := 50.0
	joystick_inner = Control.new()
	joystick_inner.size = Vector2(knob_size, knob_size)

	var inner_bg := ColorRect.new()
	inner_bg.size = Vector2(knob_size, knob_size)
	inner_bg.color = Color(0.6, 0.6, 0.8, 0.6)
	joystick_inner.add_child(inner_bg)

	add_child(joystick_inner)

	joystick_center = joystick_pos
	joystick_radius = joystick_size * 0.5 - knob_size * 0.5
	_reset_joystick_knob()

func _reset_joystick_knob() -> void:
	var knob_size := joystick_inner.size.x
	joystick_inner.position = joystick_center - Vector2(knob_size * 0.5, knob_size * 0.5)

func _build_action_buttons() -> void:
	var right_x := screen_size.x - 30 - button_size
	var bottom_y := screen_size.y - 30 - button_size

	# Special button - bottom right
	btn_special = _create_button(
		Vector2(right_x, bottom_y - button_size - 20),
		"\u2694\uFE0F", "Special", Color(0.8, 0.3, 0.3, 0.5)
	)
	add_child(btn_special)

	# Light button - to the left of special
	btn_light = _create_button(
		Vector2(right_x - button_size - 15, bottom_y),
		"\U0001F4A1", "Light", Color(0.8, 0.7, 0.2, 0.5)
	)
	add_child(btn_light)

	# Dodge button - bottom right corner
	btn_dodge = _create_button(
		Vector2(right_x, bottom_y),
		"\U0001F4A8", "Dodge", Color(0.3, 0.6, 0.8, 0.5)
	)
	add_child(btn_dodge)

func _build_top_bar_buttons() -> void:
	# Inventory button - top left
	btn_inventory = _create_button(
		Vector2(10, 10),
		"\U0001F392", "Bag", Color(0.4, 0.3, 0.6, 0.5)
	)
	btn_inventory.size = Vector2(50, 50)
	add_child(btn_inventory)

	# Stats button - next to inventory
	btn_stats = _create_button(
		Vector2(70, 10),
		"\U0001F4CA", "Stats", Color(0.3, 0.5, 0.4, 0.5)
	)
	btn_stats.size = Vector2(50, 50)
	add_child(btn_stats)

func _build_auto_attack_indicator() -> void:
	auto_attack_label = Label.new()
	auto_attack_label.text = "\u2694\uFE0F AUTO"
	auto_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	auto_attack_label.position = Vector2(screen_size.x / 2.0 - 40, screen_size.y - 40)
	auto_attack_label.size = Vector2(80, 30)
	var ls := LabelSettings.new()
	ls.font_size = 14
	ls.font_color = Color(0.3, 1.0, 0.5, 0.7)
	auto_attack_label.label_settings = ls
	add_child(auto_attack_label)

func _create_button(pos: Vector2, emoji: String, label_text: String, bg_color: Color) -> Control:
	var btn := Control.new()
	btn.position = pos
	btn.size = Vector2(button_size, button_size)

	var bg := ColorRect.new()
	bg.size = Vector2(button_size, button_size)
	bg.color = bg_color
	btn.add_child(bg)

	# Border
	var border_color := bg_color * 1.5
	border_color.a = 0.7
	var bw := 2.0
	for data in [
		[Vector2(0, 0), Vector2(button_size, bw)],
		[Vector2(0, button_size - bw), Vector2(button_size, bw)],
		[Vector2(0, 0), Vector2(bw, button_size)],
		[Vector2(button_size - bw, 0), Vector2(bw, button_size)],
	]:
		var b := ColorRect.new()
		b.position = data[0]
		b.size = data[1]
		b.color = border_color
		btn.add_child(b)

	var emoji_lbl := Label.new()
	emoji_lbl.text = emoji
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.position = Vector2(0, -2)
	emoji_lbl.size = Vector2(button_size, button_size * 0.65)
	var els := LabelSettings.new()
	els.font_size = 22
	if GameData.emoji_font:
		els.font = GameData.emoji_font
	emoji_lbl.label_settings = els
	btn.add_child(emoji_lbl)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0, button_size * 0.55)
	name_lbl.size = Vector2(button_size, button_size * 0.35)
	var nls := LabelSettings.new()
	nls.font_size = 10
	nls.font_color = Color(0.8, 0.8, 0.9)
	name_lbl.label_settings = nls
	btn.add_child(name_lbl)

	return btn

func _input(event: InputEvent) -> void:
	if not is_touch_mode:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var pos := event.position

	if event.pressed:
		# Check joystick area (left half of screen, bottom half)
		if pos.x < screen_size.x * 0.4 and pos.y > screen_size.y * 0.5:
			joystick_touch_index = event.index
			_update_joystick(pos)
			return

		# Check action buttons
		if btn_special and _point_in_control(pos, btn_special):
			special_pressed.emit()
			_flash_button(btn_special)
			return
		if btn_light and _point_in_control(pos, btn_light):
			light_pressed.emit()
			_flash_button(btn_light)
			return
		if btn_dodge and _point_in_control(pos, btn_dodge):
			dodge_pressed.emit()
			_flash_button(btn_dodge)
			return
		if btn_inventory and _point_in_control(pos, btn_inventory):
			inventory_pressed.emit()
			_flash_button(btn_inventory)
			return
		if btn_stats and _point_in_control(pos, btn_stats):
			stats_pressed.emit()
			_flash_button(btn_stats)
			return

		# Tap on auto-attack label to toggle
		if auto_attack_label and pos.distance_to(auto_attack_label.position + auto_attack_label.size / 2.0) < 50.0:
			auto_attack_enabled = not auto_attack_enabled
			_update_auto_attack_label()
			return

	else:
		# Touch released
		if event.index == joystick_touch_index:
			joystick_touch_index = -1
			joystick_direction = Vector2.ZERO
			_reset_joystick_knob()
			joystick_input.emit(Vector2.ZERO)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var offset := touch_pos - joystick_center
	var dist := offset.length()

	if dist > joystick_radius:
		offset = offset.normalized() * joystick_radius

	# Update knob position
	var knob_size := joystick_inner.size.x
	joystick_inner.position = joystick_center + offset - Vector2(knob_size * 0.5, knob_size * 0.5)

	# Calculate normalized direction
	var normalized := offset / maxf(joystick_radius, 0.001)
	if normalized.length() < joystick_deadzone:
		joystick_direction = Vector2.ZERO
	else:
		joystick_direction = normalized

	joystick_input.emit(joystick_direction)

func _point_in_control(point: Vector2, ctrl: Control) -> bool:
	if ctrl == null:
		return false
	var rect := Rect2(ctrl.position, ctrl.size)
	# Add some touch padding
	rect = rect.grow(10.0)
	return rect.has_point(point)

func _flash_button(btn: Control) -> void:
	if not is_instance_valid(btn) or btn.get_child_count() == 0:
		return
	var bg: ColorRect = btn.get_child(0) as ColorRect
	if bg:
		var orig_color := bg.color
		bg.color = Color(1, 1, 1, 0.6)
		var tween := create_tween()
		tween.tween_property(bg, "color", orig_color, 0.2)

func _update_auto_attack_label() -> void:
	if auto_attack_label:
		if auto_attack_enabled:
			auto_attack_label.text = "\u2694\uFE0F AUTO"
			auto_attack_label.label_settings.font_color = Color(0.3, 1.0, 0.5, 0.7)
		else:
			auto_attack_label.text = "\u2694\uFE0F MANUAL"
			auto_attack_label.label_settings.font_color = Color(1.0, 0.5, 0.3, 0.7)

func get_joystick_direction() -> Vector2:
	return joystick_direction

func is_auto_attack() -> bool:
	return auto_attack_enabled and is_touch_mode

func _process(_delta: float) -> void:
	if not is_touch_mode:
		return
	# Update screen size on resize
	var new_size := get_viewport().get_visible_rect().size
	if new_size != screen_size and new_size.x > 0:
		screen_size = new_size
		# Rebuild on resize
		for child in get_children():
			child.queue_free()
		call_deferred("_build_touch_ui")
