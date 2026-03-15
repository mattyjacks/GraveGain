extends CanvasLayer

signal reader_closed()

const LoreDatabase = preload("res://scripts/lore/lore_database.gd")

var current_entry: Dictionary = {}
var is_open: bool = false

var panel: PanelContainer = null
var title_label: Label = null
var type_label: Label = null
var rarity_label: Label = null
var content_label: RichTextLabel = null
var close_button: Button = null
var play_button: Button = null
var stop_button: Button = null
var status_label: Label = null
var scroll_container: ScrollContainer = null
var new_badge: Label = null

var tts_manager_ref: Node = null

func _ready() -> void:
	layer = 200
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-350, -280)
	panel.size = Vector2(700, 560)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.1)
	panel_style.border_color = Color(0.3, 0.25, 0.5)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_vbox)

	title_label = Label.new()
	title_label.text = "Lore Title"
	var tl_settings := LabelSettings.new()
	tl_settings.font_size = 24
	tl_settings.font_color = Color(0.95, 0.85, 0.6)
	tl_settings.outline_size = 2
	tl_settings.outline_color = Color(0, 0, 0)
	title_label.label_settings = tl_settings
	title_vbox.add_child(title_label)

	var meta_hbox := HBoxContainer.new()
	meta_hbox.add_theme_constant_override("separation", 16)
	title_vbox.add_child(meta_hbox)

	type_label = Label.new()
	var typ_settings := LabelSettings.new()
	typ_settings.font_size = 13
	typ_settings.font_color = Color(0.6, 0.6, 0.7)
	type_label.label_settings = typ_settings
	meta_hbox.add_child(type_label)

	rarity_label = Label.new()
	var rar_settings := LabelSettings.new()
	rar_settings.font_size = 13
	rarity_label.label_settings = rar_settings
	meta_hbox.add_child(rarity_label)

	new_badge = Label.new()
	new_badge.text = " NEW "
	var nb_settings := LabelSettings.new()
	nb_settings.font_size = 11
	nb_settings.font_color = Color(1.0, 0.9, 0.3)
	new_badge.label_settings = nb_settings
	new_badge.visible = false
	meta_hbox.add_child(new_badge)

	close_button = Button.new()
	close_button.text = "\u2715"
	close_button.custom_minimum_size = Vector2(36, 36)
	_style_btn(close_button, Color(0.7, 0.3, 0.3))
	close_button.pressed.connect(close_reader)
	header.add_child(close_button)

	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	vbox.add_child(separator)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll_container)

	content_label = RichTextLabel.new()
	content_label.bbcode_enabled = false
	content_label.fit_content = true
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.add_theme_font_size_override("normal_font_size", 15)
	content_label.add_theme_color_override("default_color", Color(0.85, 0.85, 0.9))
	scroll_container.add_child(content_label)

	var separator2 := HSeparator.new()
	separator2.add_theme_constant_override("separation", 8)
	vbox.add_child(separator2)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	vbox.add_child(controls)

	play_button = Button.new()
	play_button.text = "\u25B6 Read Aloud"
	play_button.custom_minimum_size = Vector2(140, 36)
	_style_btn(play_button, Color(0.3, 0.7, 0.4))
	play_button.pressed.connect(_on_play_pressed)
	controls.add_child(play_button)

	stop_button = Button.new()
	stop_button.text = "\u25A0 Stop"
	stop_button.custom_minimum_size = Vector2(100, 36)
	_style_btn(stop_button, Color(0.7, 0.4, 0.3))
	stop_button.pressed.connect(_on_stop_pressed)
	stop_button.visible = false
	controls.add_child(stop_button)

	status_label = Label.new()
	var st_settings := LabelSettings.new()
	st_settings.font_size = 12
	st_settings.font_color = Color(0.5, 0.5, 0.6)
	status_label.label_settings = st_settings
	controls.add_child(status_label)

func _style_btn(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.1, 0.15)
	normal.border_color = accent * 0.6
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.15, 0.15, 0.2)
	hover.border_color = accent
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(6)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_font_size_override("font_size", 13)

func open_entry(entry_id: String, tts_mgr: Node = null) -> void:
	var entry := LoreManager.get_entry(entry_id)
	if entry.is_empty():
		return

	# If already open, close first to reset state cleanly
	if is_open:
		_force_close_no_unpause()

	current_entry = entry
	tts_manager_ref = tts_mgr
	is_open = true

	var type_info: Dictionary = LoreDatabase.TYPE_INFO.get(entry["type"], {"emoji": "\U0001F4DD", "name": "Note"})
	title_label.text = type_info["emoji"] + " " + entry["title"]
	type_label.text = type_info["name"]

	var rarity: String = entry.get("rarity", "common")
	rarity_label.text = rarity.capitalize()
	match rarity:
		"common":
			rarity_label.label_settings.font_color = Color(0.7, 0.7, 0.7)
		"uncommon":
			rarity_label.label_settings.font_color = Color(0.4, 1.0, 0.4)
		"rare":
			rarity_label.label_settings.font_color = Color(0.4, 0.6, 1.0)
		"epic":
			rarity_label.label_settings.font_color = Color(0.7, 0.3, 1.0)
		"legendary":
			rarity_label.label_settings.font_color = Color(1.0, 0.7, 0.2)

	var was_new := not LoreManager.has_read(entry_id)
	new_badge.visible = was_new
	LoreManager.mark_read(entry_id)

	content_label.text = entry.get("content", "")
	scroll_container.scroll_vertical = 0

	play_button.visible = tts_manager_ref != null
	stop_button.visible = false
	status_label.text = ""

	if tts_manager_ref:
		if tts_manager_ref.is_entry_cached(entry_id):
			status_label.text = "\U0001F4BE Cached"
		else:
			var provider: String = entry.get("voice_provider", "openai")
			var voice: String = entry.get("voice_id", "nova")
			status_label.text = provider.capitalize() + " / " + voice
		if not tts_manager_ref.tts_started.is_connected(_on_tts_started):
			tts_manager_ref.tts_started.connect(_on_tts_started)
			tts_manager_ref.tts_finished.connect(_on_tts_finished)
			tts_manager_ref.tts_error.connect(_on_tts_error)

	visible = true
	get_tree().paused = true

func close_reader() -> void:
	if not is_open:
		return
	_force_close_no_unpause()
	get_tree().paused = false
	reader_closed.emit()

func _force_close_no_unpause() -> void:
	is_open = false
	visible = false
	if tts_manager_ref and is_instance_valid(tts_manager_ref) and tts_manager_ref.has_method("is_currently_playing") and tts_manager_ref.is_currently_playing():
		tts_manager_ref.stop()
	if tts_manager_ref and is_instance_valid(tts_manager_ref):
		if tts_manager_ref.has_signal("tts_started") and tts_manager_ref.tts_started.is_connected(_on_tts_started):
			tts_manager_ref.tts_started.disconnect(_on_tts_started)
			tts_manager_ref.tts_finished.disconnect(_on_tts_finished)
			tts_manager_ref.tts_error.disconnect(_on_tts_error)

func _on_play_pressed() -> void:
	if not tts_manager_ref or not is_instance_valid(tts_manager_ref) or current_entry.is_empty():
		return
	tts_manager_ref.speak_entry(current_entry)

func _on_stop_pressed() -> void:
	if tts_manager_ref:
		tts_manager_ref.stop()

func _on_tts_started(entry_id: String) -> void:
	if entry_id == current_entry.get("id", "") and is_open:
		if play_button: play_button.visible = false
		if stop_button: stop_button.visible = true
		if status_label: status_label.text = "\U0001F50A Playing..."

func _on_tts_finished(entry_id: String) -> void:
	if entry_id == current_entry.get("id", "") and is_open:
		if play_button: play_button.visible = true
		if stop_button: stop_button.visible = false
		if status_label: status_label.text = "\u2705 Done"

func _on_tts_error(entry_id: String, error_msg: String) -> void:
	if entry_id == current_entry.get("id", "") and is_open:
		if play_button: play_button.visible = true
		if stop_button: stop_button.visible = false
		if status_label: status_label.text = "\u26A0 " + error_msg

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close_reader()
			get_viewport().set_input_as_handled()
