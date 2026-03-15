extends CanvasLayer

# ===== STARSHIP DIALOGUE UI =====
# Shows NPC dialogue with portrait, name, and text progression

signal dialogue_finished()

var is_open: bool = false
var current_lines: Array = []
var current_index: int = 0

var overlay: ColorRect
var panel: Panel
var portrait_label: Label
var name_label: Label
var text_label: RichTextLabel
var continue_label: Label

func _ready() -> void:
	layer = 95
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func open_dialogue(npc_data: Dictionary) -> void:
	current_lines = npc_data.get("dialogue", ["..."])
	current_index = 0
	is_open = true
	visible = true
	get_tree().paused = true
	
	portrait_label.text = npc_data.get("emoji", "\U0001F464")
	name_label.text = npc_data.get("name", "NPC")
	_show_current_line()

func close() -> void:
	is_open = false
	visible = false
	get_tree().paused = false
	dialogue_finished.emit()

func _show_current_line() -> void:
	if current_index < current_lines.size():
		text_label.text = current_lines[current_index]
		var has_next := current_index < current_lines.size() - 1
		continue_label.text = "[Space/E] Next" if has_next else "[Space/E] Close"
	else:
		close()

func _advance() -> void:
	current_index += 1
	if current_index >= current_lines.size():
		close()
	else:
		_show_current_line()

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -160
	panel.offset_bottom = -20
	panel.offset_left = 60
	panel.offset_right = -60
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	style.border_color = Color(0.4, 0.5, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	# Portrait emoji
	portrait_label = Label.new()
	portrait_label.text = "\U0001F464"
	portrait_label.position = Vector2(15, 15)
	portrait_label.size = Vector2(60, 60)
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var portrait_settings := LabelSettings.new()
	portrait_settings.font = GameData.emoji_font
	portrait_settings.font_size = 36
	portrait_label.label_settings = portrait_settings
	panel.add_child(portrait_label)
	
	# NPC name
	name_label = Label.new()
	name_label.text = "NPC"
	name_label.position = Vector2(80, 10)
	name_label.size = Vector2(300, 25)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	name_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(name_label)
	
	# Dialogue text
	text_label = RichTextLabel.new()
	text_label.position = Vector2(80, 38)
	text_label.size = Vector2(700, 60)
	text_label.bbcode_enabled = false
	text_label.scroll_active = false
	text_label.add_theme_color_override("default_color", Color(0.85, 0.85, 0.9))
	text_label.add_theme_font_size_override("normal_font_size", 14)
	panel.add_child(text_label)
	
	# Continue prompt
	continue_label = Label.new()
	continue_label.text = "[Space/E] Next"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.position = Vector2(500, 105)
	continue_label.size = Vector2(280, 20)
	continue_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.7))
	continue_label.add_theme_font_size_override("font_size", 11)
	panel.add_child(continue_label)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E or event.keycode == KEY_ENTER:
			_advance()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
