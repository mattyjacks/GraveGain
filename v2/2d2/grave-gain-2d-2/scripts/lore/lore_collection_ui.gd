extends CanvasLayer

signal collection_closed()

const LoreDatabase = preload("res://scripts/lore/lore_database.gd")

var is_open: bool = false
var selected_category: String = ""
var selected_entry_id: String = ""

var bg: ColorRect = null
var main_panel: PanelContainer = null
var title_label: Label = null
var progress_label: Label = null
var progress_bar: ColorRect = null
var progress_bar_bg: ColorRect = null
var category_list: VBoxContainer = null
var entry_list: VBoxContainer = null
var entry_scroll: ScrollContainer = null
var detail_panel: VBoxContainer = null
var detail_title: Label = null
var detail_content: RichTextLabel = null
var detail_scroll: ScrollContainer = null
var close_button: Button = null
var read_aloud_button: Button = null
var back_button: Button = null
var status_label: Label = null

var tts_manager_ref: Node = null
var lore_reader_ref: Node = null
var category_buttons: Array[Button] = []
var entry_buttons: Array[Button] = []

var api_key_panel: VBoxContainer = null
var openai_input: LineEdit = null
var elevenlabs_input: LineEdit = null

func _ready() -> void:
	layer = 190
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _build_ui() -> void:
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.position = Vector2(-480, -320)
	main_panel.size = Vector2(960, 640)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.04, 0.08)
	ps.border_color = Color(0.35, 0.25, 0.55)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	ps.set_content_margin_all(16)
	main_panel.add_theme_stylebox_override("panel", ps)
	add_child(main_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	main_panel.add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root_vbox.add_child(header)

	title_label = Label.new()
	title_label.text = "\U0001F4DA Lore Collection"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tls := LabelSettings.new()
	tls.font_size = 28
	tls.font_color = Color(0.9, 0.8, 0.6)
	tls.outline_size = 2
	tls.outline_color = Color(0, 0, 0)
	title_label.label_settings = tls
	header.add_child(title_label)

	progress_label = Label.new()
	var pls := LabelSettings.new()
	pls.font_size = 14
	pls.font_color = Color(0.6, 0.6, 0.7)
	progress_label.label_settings = pls
	header.add_child(progress_label)

	close_button = Button.new()
	close_button.text = "\u2715 Close"
	close_button.custom_minimum_size = Vector2(80, 32)
	_style_btn(close_button, Color(0.6, 0.3, 0.3))
	close_button.pressed.connect(close_collection)
	header.add_child(close_button)

	progress_bar_bg = ColorRect.new()
	progress_bar_bg.custom_minimum_size = Vector2(0, 6)
	progress_bar_bg.color = Color(0.1, 0.1, 0.15)
	root_vbox.add_child(progress_bar_bg)

	progress_bar = ColorRect.new()
	progress_bar.custom_minimum_size = Vector2(0, 6)
	progress_bar.color = Color(0.5, 0.3, 0.8)
	progress_bar.size = Vector2(0, 6)
	progress_bar_bg.add_child(progress_bar)

	var content_hbox := HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(content_hbox)

	_build_category_panel(content_hbox)
	_build_entry_panel(content_hbox)
	_build_detail_panel(content_hbox)
	_build_api_key_section(root_vbox)

func _build_category_panel(parent: HBoxContainer) -> void:
	var cat_panel := PanelContainer.new()
	cat_panel.custom_minimum_size = Vector2(200, 0)
	var cps := StyleBoxFlat.new()
	cps.bg_color = Color(0.06, 0.06, 0.1)
	cps.set_corner_radius_all(6)
	cps.set_content_margin_all(6)
	cat_panel.add_theme_stylebox_override("panel", cps)
	parent.add_child(cat_panel)

	var cat_scroll := ScrollContainer.new()
	cat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cat_panel.add_child(cat_scroll)

	category_list = VBoxContainer.new()
	category_list.add_theme_constant_override("separation", 4)
	cat_scroll.add_child(category_list)

	var sorted_cats: Array = []
	for key in LoreDatabase.CATEGORIES:
		sorted_cats.append({"key": key, "order": LoreDatabase.CATEGORIES[key]["order"]})
	sorted_cats.sort_custom(func(a, b): return a["order"] < b["order"])

	for cat_info in sorted_cats:
		var key: String = cat_info["key"]
		var cat: Dictionary = LoreDatabase.CATEGORIES[key]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 36)
		btn.text = cat["icon"] + " " + cat["name"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_btn(btn, Color(0.4, 0.3, 0.6))
		btn.pressed.connect(_on_category_selected.bind(key))
		category_list.add_child(btn)
		category_buttons.append(btn)

func _build_entry_panel(parent: HBoxContainer) -> void:
	var entry_panel := PanelContainer.new()
	entry_panel.custom_minimum_size = Vector2(260, 0)
	entry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var eps := StyleBoxFlat.new()
	eps.bg_color = Color(0.05, 0.05, 0.09)
	eps.set_corner_radius_all(6)
	eps.set_content_margin_all(6)
	entry_panel.add_theme_stylebox_override("panel", eps)
	parent.add_child(entry_panel)

	entry_scroll = ScrollContainer.new()
	entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	entry_panel.add_child(entry_scroll)

	entry_list = VBoxContainer.new()
	entry_list.add_theme_constant_override("separation", 3)
	entry_scroll.add_child(entry_list)

func _build_detail_panel(parent: HBoxContainer) -> void:
	var det_panel := PanelContainer.new()
	det_panel.custom_minimum_size = Vector2(400, 0)
	det_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dps := StyleBoxFlat.new()
	dps.bg_color = Color(0.05, 0.05, 0.09)
	dps.set_corner_radius_all(6)
	dps.set_content_margin_all(10)
	det_panel.add_theme_stylebox_override("panel", dps)
	parent.add_child(det_panel)

	detail_panel = VBoxContainer.new()
	detail_panel.add_theme_constant_override("separation", 8)
	det_panel.add_child(detail_panel)

	detail_title = Label.new()
	detail_title.text = "Select a lore entry"
	var dts := LabelSettings.new()
	dts.font_size = 18
	dts.font_color = Color(0.9, 0.85, 0.65)
	detail_title.label_settings = dts
	detail_panel.add_child(detail_title)

	detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(detail_scroll)

	detail_content = RichTextLabel.new()
	detail_content.bbcode_enabled = false
	detail_content.fit_content = true
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_font_size_override("normal_font_size", 14)
	detail_content.add_theme_color_override("default_color", Color(0.8, 0.8, 0.85))
	detail_scroll.add_child(detail_content)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	detail_panel.add_child(controls)

	read_aloud_button = Button.new()
	read_aloud_button.text = "\u25B6 Read Aloud"
	read_aloud_button.custom_minimum_size = Vector2(120, 32)
	_style_btn(read_aloud_button, Color(0.3, 0.6, 0.4))
	read_aloud_button.pressed.connect(_on_read_aloud)
	read_aloud_button.visible = false
	controls.add_child(read_aloud_button)

	status_label = Label.new()
	var sls := LabelSettings.new()
	sls.font_size = 12
	sls.font_color = Color(0.5, 0.5, 0.6)
	status_label.label_settings = sls
	controls.add_child(status_label)

func _build_api_key_section(parent: VBoxContainer) -> void:
	api_key_panel = VBoxContainer.new()
	api_key_panel.add_theme_constant_override("separation", 4)
	parent.add_child(api_key_panel)

	var sep := HSeparator.new()
	api_key_panel.add_child(sep)

	var key_title := Label.new()
	key_title.text = "\U0001F511 API Keys (for TTS voice reading)"
	var kts := LabelSettings.new()
	kts.font_size = 12
	kts.font_color = Color(0.5, 0.5, 0.6)
	key_title.label_settings = kts
	api_key_panel.add_child(key_title)

	var key_hbox := HBoxContainer.new()
	key_hbox.add_theme_constant_override("separation", 12)
	api_key_panel.add_child(key_hbox)

	var oai_label := Label.new()
	oai_label.text = "OpenAI:"
	var ols := LabelSettings.new()
	ols.font_size = 12
	ols.font_color = Color(0.6, 0.6, 0.7)
	oai_label.label_settings = ols
	key_hbox.add_child(oai_label)

	openai_input = LineEdit.new()
	openai_input.placeholder_text = "sk-..."
	openai_input.secret = true
	openai_input.custom_minimum_size = Vector2(200, 24)
	openai_input.add_theme_font_size_override("font_size", 11)
	key_hbox.add_child(openai_input)

	var el_label := Label.new()
	el_label.text = "ElevenLabs:"
	el_label.label_settings = ols
	key_hbox.add_child(el_label)

	elevenlabs_input = LineEdit.new()
	elevenlabs_input.placeholder_text = "xi-..."
	elevenlabs_input.secret = true
	elevenlabs_input.custom_minimum_size = Vector2(200, 24)
	elevenlabs_input.add_theme_font_size_override("font_size", 11)
	key_hbox.add_child(elevenlabs_input)

	var save_btn := Button.new()
	save_btn.text = "Save Keys"
	save_btn.custom_minimum_size = Vector2(80, 24)
	_style_btn(save_btn, Color(0.3, 0.5, 0.7))
	save_btn.pressed.connect(_on_save_keys)
	key_hbox.add_child(save_btn)

func _style_btn(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.08, 0.12)
	normal.border_color = accent * 0.5
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	normal.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.12, 0.18)
	hover.border_color = accent
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(5)
	hover.set_content_margin_all(4)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	btn.add_theme_font_size_override("font_size", 13)

func open_collection(tts_mgr: Node = null, reader: Node = null) -> void:
	tts_manager_ref = tts_mgr
	lore_reader_ref = reader
	is_open = true
	visible = true
	get_tree().paused = true
	_refresh_progress()
	_populate_categories()

	if tts_mgr:
		openai_input.text = tts_mgr.openai_api_key
		elevenlabs_input.text = tts_mgr.elevenlabs_api_key

	if selected_category != "":
		_populate_entries(selected_category)

func close_collection() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	if tts_manager_ref and is_instance_valid(tts_manager_ref) and tts_manager_ref.is_currently_playing():
		tts_manager_ref.stop()
	collection_closed.emit()

func _refresh_progress() -> void:
	var pct := LoreManager.get_completion_percentage()
	var total := LoreManager.total_entries
	var collected := LoreManager.total_collected
	progress_label.text = str(collected) + " / " + str(total) + " (" + str(int(pct)) + "%)"
	var bar_width: float = progress_bar_bg.size.x if progress_bar_bg.size.x > 0.0 else 1.0
	progress_bar.size.x = bar_width * (pct / 100.0)

func _populate_categories() -> void:
	var sorted_cats: Array = []
	for key in LoreDatabase.CATEGORIES:
		sorted_cats.append({"key": key, "order": LoreDatabase.CATEGORIES[key]["order"]})
	sorted_cats.sort_custom(func(a, b): return a["order"] < b["order"])

	var count := mini(category_buttons.size(), sorted_cats.size())
	for i in range(count):
		var key: String = sorted_cats[i]["key"]
		var progress := LoreManager.get_category_progress(key)
		var cat: Dictionary = LoreDatabase.CATEGORIES[key]
		category_buttons[i].text = cat["icon"] + " " + cat["name"] + " (" + str(progress["collected"]) + "/" + str(progress["total"]) + ")"

func _on_category_selected(cat_key: String) -> void:
	selected_category = cat_key
	selected_entry_id = ""
	_populate_entries(cat_key)
	detail_title.text = "Select a lore entry"
	detail_content.text = ""
	read_aloud_button.visible = false

func _populate_entries(cat_key: String) -> void:
	for child in entry_list.get_children():
		child.queue_free()
	entry_buttons.clear()

	var all_entries := LoreManager.all_entries
	var entries_in_cat: Array = []
	for id in all_entries:
		if all_entries[id]["category"] == cat_key:
			entries_in_cat.append(all_entries[id])

	entries_in_cat.sort_custom(func(a, b): return a["title"] < b["title"])

	for entry in entries_in_cat:
		var id: String = entry["id"]
		var is_collected := LoreManager.has_collected(id)
		var is_read := LoreManager.has_read(id)
		var type_info: Dictionary = LoreDatabase.TYPE_INFO.get(entry["type"], {"emoji": "\U0001F4DD", "name": "Note"})

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 30)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		if is_collected:
			var new_marker := "" if is_read else " \u2728"
			btn.text = type_info["emoji"] + " " + entry["title"] + new_marker
			var rarity_color := _get_rarity_color(entry["rarity"])
			_style_btn(btn, rarity_color)
		else:
			btn.text = "\u2753 ???"
			_style_btn(btn, Color(0.2, 0.2, 0.25))
			btn.disabled = true

		btn.pressed.connect(_on_entry_selected.bind(id))
		entry_list.add_child(btn)
		entry_buttons.append(btn)

func _on_entry_selected(entry_id: String) -> void:
	selected_entry_id = entry_id
	var entry := LoreManager.get_entry(entry_id)
	if entry.is_empty():
		return

	LoreManager.mark_read(entry_id)
	var type_info: Dictionary = LoreDatabase.TYPE_INFO.get(entry["type"], {"emoji": "\U0001F4DD", "name": "Note"})
	detail_title.text = type_info["emoji"] + " " + entry["title"]
	detail_content.text = entry.get("content", "")
	detail_scroll.scroll_vertical = 0

	read_aloud_button.visible = tts_manager_ref != null
	status_label.text = ""

	_populate_entries(selected_category)

func _on_read_aloud() -> void:
	if not tts_manager_ref or not is_instance_valid(tts_manager_ref) or selected_entry_id.is_empty():
		return
	var entry := LoreManager.get_entry(selected_entry_id)
	if entry.is_empty():
		return

	if tts_manager_ref.is_currently_playing():
		tts_manager_ref.stop()
		status_label.text = ""
		read_aloud_button.text = "\u25B6 Read Aloud"
		return

	tts_manager_ref.speak_entry(entry)
	read_aloud_button.text = "\u25A0 Stop"
	status_label.text = "\U0001F50A Playing..."

	if not tts_manager_ref.tts_finished.is_connected(_on_tts_done):
		tts_manager_ref.tts_finished.connect(_on_tts_done)
		tts_manager_ref.tts_error.connect(_on_tts_err)

func _on_tts_done(_entry_id: String) -> void:
	read_aloud_button.text = "\u25B6 Read Aloud"
	status_label.text = "\u2705 Done"

func _on_tts_err(_entry_id: String, err: String) -> void:
	read_aloud_button.text = "\u25B6 Read Aloud"
	status_label.text = "\u26A0 " + err

func _on_save_keys() -> void:
	if tts_manager_ref:
		tts_manager_ref.set_openai_key(openai_input.text.strip_edges())
		tts_manager_ref.set_elevenlabs_key(elevenlabs_input.text.strip_edges())
		status_label.text = "\u2705 Keys saved"

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.5, 0.5, 0.5)
		"uncommon": return Color(0.3, 0.7, 0.3)
		"rare": return Color(0.3, 0.5, 0.9)
		"epic": return Color(0.6, 0.3, 0.9)
		"legendary": return Color(0.9, 0.65, 0.15)
	return Color(0.5, 0.5, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close_collection()
			get_viewport().set_input_as_handled()
