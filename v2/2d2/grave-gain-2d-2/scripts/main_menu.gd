extends Control

var selected_race: int = GameData.Race.HUMAN
var selected_class: int = GameData.PlayerClass.DPS

var race_buttons: Array[Button] = []
var class_buttons: Array[Button] = []
var class_container: VBoxContainer = null
var start_button: Button = null
var title_label: Label = null
var subtitle_label: Label = null
var race_info_label: Label = null
var class_info_label: Label = null

var bg_timer: float = 0.0
var graphics_panel: Control = null

func _ready() -> void:
	_build_ui()
	_update_class_buttons()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-300, -350)
	center.size = Vector2(600, 700)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	add_child(center)

	title_label = Label.new()
	title_label.text = "\u26B0\uFE0F GraveGain 2D \u26B0\uFE0F"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 52
	title_settings.font_color = Color(0.85, 0.6, 1.0)
	title_settings.outline_size = 4
	title_settings.outline_color = Color(0.2, 0.0, 0.4)
	title_settings.font = GameData.emoji_font
	title_label.label_settings = title_settings
	center.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "CryptArtist - MoonRock Awaits"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub_settings := LabelSettings.new()
	sub_settings.font_size = 16
	sub_settings.font_color = Color(0.6, 0.6, 0.7)
	subtitle_label.label_settings = sub_settings
	center.add_child(subtitle_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	var race_title := Label.new()
	race_title.text = "Choose Your Race"
	race_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rt_settings := LabelSettings.new()
	rt_settings.font_size = 22
	rt_settings.font_color = Color(0.9, 0.85, 0.7)
	race_title.label_settings = rt_settings
	center.add_child(race_title)

	var race_grid := HBoxContainer.new()
	race_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	race_grid.add_theme_constant_override("separation", 16)
	center.add_child(race_grid)

	var races := [
		GameData.Race.HUMAN,
		GameData.Race.ELF,
		GameData.Race.DWARF,
		GameData.Race.ORC,
	]
	for r in races:
		var stats: Dictionary = GameData.race_stats[r]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 80)
		btn.text = stats["emoji"] + "\n" + stats["name"]
		btn.tooltip_text = stats["desc"]
		btn.add_theme_font_override("font", GameData.emoji_font)
		_style_button(btn, stats["color"])
		btn.pressed.connect(_on_race_selected.bind(r))
		race_grid.add_child(btn)
		race_buttons.append(btn)

	race_info_label = Label.new()
	race_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ri_settings := LabelSettings.new()
	ri_settings.font_size = 14
	ri_settings.font_color = Color(0.7, 0.7, 0.8)
	race_info_label.label_settings = ri_settings
	center.add_child(race_info_label)
	_update_race_info()

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	center.add_child(spacer2)

	var class_title := Label.new()
	class_title.text = "Choose Your Class"
	class_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ct_settings := LabelSettings.new()
	ct_settings.font_size = 22
	ct_settings.font_color = Color(0.9, 0.85, 0.7)
	class_title.label_settings = ct_settings
	center.add_child(class_title)

	class_container = VBoxContainer.new()
	class_container.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(class_container)

	var class_grid := HBoxContainer.new()
	class_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	class_grid.add_theme_constant_override("separation", 16)
	class_container.add_child(class_grid)

	var classes := [
		GameData.PlayerClass.DPS,
		GameData.PlayerClass.TANK,
		GameData.PlayerClass.SUPPORT,
		GameData.PlayerClass.MAGE,
	]
	for c in classes:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 70)
		btn.tooltip_text = GameData.class_descs[c]
		btn.add_theme_font_override("font", GameData.emoji_font)
		_style_button(btn, Color(0.5, 0.5, 0.6))
		btn.pressed.connect(_on_class_selected.bind(c))
		class_grid.add_child(btn)
		class_buttons.append(btn)

	class_info_label = Label.new()
	class_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ci_settings := LabelSettings.new()
	ci_settings.font_size = 14
	ci_settings.font_color = Color(0.7, 0.7, 0.8)
	class_info_label.label_settings = ci_settings
	class_container.add_child(class_info_label)

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer3)

	start_button = Button.new()
	start_button.text = "\u2694\uFE0F  START MISSION  \u2694\uFE0F"
	start_button.custom_minimum_size = Vector2(300, 55)
	_style_button(start_button, Color(0.2, 0.8, 0.3))
	start_button.pressed.connect(_on_start_pressed)
	center.add_child(start_button)

	var lore_button := Button.new()
	lore_button.text = "\U0001F4DA  LORE COLLECTION  \U0001F4DA"
	lore_button.custom_minimum_size = Vector2(300, 40)
	_style_button(lore_button, Color(0.5, 0.3, 0.7))
	lore_button.pressed.connect(_on_lore_pressed)
	center.add_child(lore_button)

	var lore_progress := Label.new()
	var pct := LoreManager.get_completion_percentage()
	lore_progress.text = str(LoreManager.total_collected) + "/" + str(LoreManager.total_entries) + " collected (" + str(int(pct)) + "%)"
	lore_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lp_settings := LabelSettings.new()
	lp_settings.font_size = 12
	lp_settings.font_color = Color(0.5, 0.4, 0.6)
	lore_progress.label_settings = lp_settings
	center.add_child(lore_progress)

	var settings_button := Button.new()
	settings_button.text = "\u2699\uFE0F  GRAPHICS SETTINGS  \u2699\uFE0F"
	settings_button.custom_minimum_size = Vector2(300, 40)
	_style_button(settings_button, Color(0.5, 0.5, 0.6))
	settings_button.pressed.connect(_on_settings_pressed)
	center.add_child(settings_button)

	var controls_label := Label.new()
	controls_label.text = "WASD: Move | Mouse: Aim | LMB: Attack | RMB: Block | Shift: Sprint | Space: Jump\nF: Ability | C: Light | E: Interact | 1-4: Slots | R: Reload | I/Tab: Lore | ESC: Quit"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cl_settings := LabelSettings.new()
	cl_settings.font_size = 12
	cl_settings.font_color = Color(0.4, 0.4, 0.5)
	controls_label.label_settings = cl_settings
	center.add_child(controls_label)

func _style_button(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.1, 0.15)
	normal.border_color = accent * 0.6
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.15, 0.15, 0.22)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = accent * 0.3
	pressed.border_color = accent
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 16)

func _on_race_selected(r: int) -> void:
	selected_race = r as GameData.Race
	_update_race_info()
	_update_class_buttons()
	_highlight_race_button()

func _on_class_selected(c: int) -> void:
	selected_class = c as GameData.PlayerClass
	_update_class_info()
	_highlight_class_button()

func _highlight_race_button() -> void:
	var races := [GameData.Race.HUMAN, GameData.Race.ELF, GameData.Race.DWARF, GameData.Race.ORC]
	for i in range(race_buttons.size()):
		var stats: Dictionary = GameData.race_stats[races[i]]
		if races[i] == selected_race:
			_style_button(race_buttons[i], stats["color"] * 1.5)
		else:
			_style_button(race_buttons[i], stats["color"] * 0.5)

func _highlight_class_button() -> void:
	var classes := [GameData.PlayerClass.DPS, GameData.PlayerClass.TANK, GameData.PlayerClass.SUPPORT, GameData.PlayerClass.MAGE]
	for i in range(class_buttons.size()):
		if classes[i] == selected_class:
			_style_button(class_buttons[i], Color(0.8, 0.7, 0.3))
		else:
			_style_button(class_buttons[i], Color(0.4, 0.4, 0.5))

func _update_race_info() -> void:
	var stats: Dictionary = GameData.race_stats[selected_race]
	race_info_label.text = stats["name"] + " - HP: " + str(int(stats["max_hp"])) + " | Regen: " + str(stats["hp_regen"]) + "/s | Speed: " + str(int(stats["run_speed"])) + " | " + stats["desc"]

func _update_class_info() -> void:
	var class_name_str: String = GameData.get_class_name_for(selected_race, selected_class)
	class_info_label.text = class_name_str + " - " + GameData.class_descs[selected_class]

func _update_class_buttons() -> void:
	var classes := [GameData.PlayerClass.DPS, GameData.PlayerClass.TANK, GameData.PlayerClass.SUPPORT, GameData.PlayerClass.MAGE]
	for i in range(class_buttons.size()):
		var class_name_str: String = GameData.get_class_name_for(selected_race, classes[i])
		var emoji: String = GameData.class_emojis[classes[i]]
		class_buttons[i].text = emoji + "\n" + class_name_str
	_update_class_info()
	_highlight_race_button()
	_highlight_class_button()

func _on_start_pressed() -> void:
	GameData.selected_race = selected_race
	GameData.selected_class = selected_class
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_lore_pressed() -> void:
	var LoreCollectionScript := preload("res://scripts/lore/lore_collection_ui.gd")
	var TtsManagerScript := preload("res://scripts/lore/tts_manager.gd")
	var tts := Node.new()
	tts.set_script(TtsManagerScript)
	add_child(tts)
	var collection := CanvasLayer.new()
	collection.set_script(LoreCollectionScript)
	add_child(collection)
	collection.collection_closed.connect(func():
		collection.queue_free()
		tts.queue_free()
	)
	collection.open_collection(tts)

func _on_settings_pressed() -> void:
	if graphics_panel and is_instance_valid(graphics_panel):
		graphics_panel.queue_free()
		graphics_panel = null
		return
	_build_graphics_panel()

func _build_graphics_panel() -> void:
	graphics_panel = Control.new()
	graphics_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	graphics_panel.add_child(dimmer)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_CENTER)
	outer.position = Vector2(-280, -340)
	outer.size = Vector2(560, 680)
	outer.add_theme_constant_override("separation", 0)
	graphics_panel.add_child(outer)

	var outer_bg := ColorRect.new()
	outer_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_bg.color = Color(0.06, 0.06, 0.1, 0.95)
	outer.add_child(outer_bg)
	outer.move_child(outer_bg, 0)

	var title := Label.new()
	title.text = "\u2699\uFE0F Graphics & Emoji Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 40)
	var ts := LabelSettings.new()
	ts.font_size = 22
	ts.font_color = Color(0.8, 0.8, 0.9)
	title.label_settings = ts
	outer.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(540, 580)
	outer.add_child(scroll)

	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	scroll.add_child(panel)

	# ===== EMOJI SET SECTION =====
	_add_section_header(panel, "\U0001F3A8 Emoji Style")
	_build_emoji_selector(panel)
	_add_separator(panel)

	# ===== QUALITY PRESET =====
	_add_section_header(panel, "\u2699\uFE0F Graphics Quality")
	var quality_names := ["Low", "Medium", "High", "Ultra"]
	var current_quality: int = GameSystems.get_setting("graphics_quality")
	_add_option_row(panel, "Quality Preset", quality_names, current_quality, func(idx: int):
		GameSystems.set_setting("graphics_quality", idx)
		_apply_quality_preset(idx)
		graphics_panel.queue_free()
		graphics_panel = null
		_build_graphics_panel()
	)

	_add_separator(panel)

	# Blood intensity
	var blood_names := ["Off", "Mild", "Normal", "Extreme"]
	_add_option_row(panel, "\U0001FA78 Blood Intensity", blood_names, GameSystems.get_setting("blood_intensity"), func(idx: int):
		GameSystems.set_setting("blood_intensity", idx)
		GameSystems.set_setting("blood_enabled", idx > 0)
	)

	# Gore
	_add_toggle_row(panel, "\U0001F480 Gore Effects", "gore_enabled")

	# Particles
	var particle_names := ["Low", "Medium", "High", "Ultra"]
	_add_option_row(panel, "\u2728 Particle Density", particle_names, GameSystems.get_setting("particle_density"), func(idx: int):
		GameSystems.set_setting("particle_density", idx)
	)

	_add_separator(panel)

	# Visual effects toggles
	_add_toggle_row(panel, "\U0001F4A1 Dynamic Lighting", "dynamic_lighting")
	_add_toggle_row(panel, "\U0001F300 Shadows", "shadows_enabled")
	_add_toggle_row(panel, "\u26A1 Hit Flash", "hit_flash_enabled")
	_add_toggle_row(panel, "\u2694\uFE0F Attack Trails", "trail_effects")
	_add_toggle_row(panel, "\U0001F4A5 Impact Effects", "impact_effects")
	_add_toggle_row(panel, "\U0001F32B\uFE0F Ambient Particles", "ambient_particles")

	_add_separator(panel)

	# Screen effects toggles
	_add_toggle_row(panel, "\U0001F4F7 Screen Shake", "screen_shake")
	_add_toggle_row(panel, "\U0001F3AF Camera Punch", "camera_punch")
	_add_toggle_row(panel, "\u23F8\uFE0F Hit Pause", "hit_pause_enabled")
	_add_toggle_row(panel, "\U0001F534 Vignette", "vignette_enabled")
	_add_toggle_row(panel, "\U0001F4A2 Hit Markers", "hit_markers")
	_add_toggle_row(panel, "\U0001F522 Damage Numbers", "damage_numbers")

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(200, 35)
	_style_button(close_btn, Color(0.6, 0.3, 0.3))
	close_btn.pressed.connect(func():
		graphics_panel.queue_free()
		graphics_panel = null
	)
	panel.add_child(close_btn)

	add_child(graphics_panel)

func _add_toggle_row(parent: VBoxContainer, label_text: String, setting_key: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(480, 28)
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ls := LabelSettings.new()
	ls.font_size = 14
	ls.font_color = Color(0.75, 0.75, 0.8)
	lbl.label_settings = ls
	row.add_child(lbl)

	var toggle := CheckButton.new()
	var setting_val = GameSystems.get_setting(setting_key)
	toggle.button_pressed = setting_val if setting_val is bool else false
	toggle.toggled.connect(func(pressed: bool):
		GameSystems.set_setting(setting_key, pressed)
	)
	row.add_child(toggle)

	parent.add_child(row)

func _add_option_row(parent: VBoxContainer, label_text: String, options: Array, current: int, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(480, 30)
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ls := LabelSettings.new()
	ls.font_size = 14
	ls.font_color = Color(0.75, 0.75, 0.8)
	lbl.label_settings = ls
	row.add_child(lbl)

	var btn_group := HBoxContainer.new()
	btn_group.add_theme_constant_override("separation", 4)
	for i in range(options.size()):
		var btn := Button.new()
		btn.text = options[i]
		btn.custom_minimum_size = Vector2(55, 25)
		if i == current:
			_style_button(btn, Color(0.3, 0.7, 0.9))
		else:
			_style_button(btn, Color(0.3, 0.3, 0.4))
		btn.add_theme_font_size_override("font_size", 11)
		var idx := i
		btn.pressed.connect(func(): callback.call(idx))
		btn_group.add_child(btn)
	row.add_child(btn_group)

	parent.add_child(row)

func _add_separator(parent: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(460, 1)
	sep.color = Color(0.3, 0.3, 0.4, 0.4)
	parent.add_child(sep)

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.custom_minimum_size = Vector2(0, 24)
	var ls := LabelSettings.new()
	ls.font_size = 15
	ls.font_color = Color(0.6, 0.7, 0.9)
	lbl.label_settings = ls
	parent.add_child(lbl)

func _build_emoji_selector(parent: VBoxContainer) -> void:
	var current_id: String = EmojiManager.current_set_id
	var all_ids: Array[String] = EmojiManager.get_all_set_ids()

	for set_id: String in all_ids:
		var info: Dictionary = EmojiManager.get_set_info(set_id)
		var is_available: bool = EmojiManager.is_set_available(set_id)
		var is_active: bool = (set_id == current_id)

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(520, 36)
		row.add_theme_constant_override("separation", 8)

		# Icon + name
		var name_lbl := Label.new()
		var status_text := ""
		if is_active:
			status_text = " [ACTIVE]"
		elif not is_available and set_id != "system":
			status_text = " [Not Installed]"
		name_lbl.text = info.get("icon", "") + " " + info.get("name", set_id) + status_text
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ns := LabelSettings.new()
		ns.font_size = 13
		if is_active:
			ns.font_color = Color(0.4, 0.9, 0.5)
		elif is_available:
			ns.font_color = Color(0.8, 0.8, 0.85)
		else:
			ns.font_color = Color(0.45, 0.45, 0.5)
		name_lbl.label_settings = ns
		row.add_child(name_lbl)

		if is_available and not is_active:
			var select_btn := Button.new()
			select_btn.text = "Use"
			select_btn.custom_minimum_size = Vector2(55, 28)
			_style_button(select_btn, Color(0.3, 0.6, 0.9))
			select_btn.add_theme_font_size_override("font_size", 11)
			var sid := set_id
			select_btn.pressed.connect(func():
				EmojiManager.apply_emoji_set(sid)
				# Rebuild panel to reflect change
				graphics_panel.queue_free()
				graphics_panel = null
				_build_graphics_panel()
				# Refresh the main menu visuals
				_refresh_menu_emojis()
			)
			row.add_child(select_btn)
		elif not is_available and set_id != "system":
			var info_btn := Button.new()
			info_btn.text = "Info"
			info_btn.custom_minimum_size = Vector2(55, 28)
			_style_button(info_btn, Color(0.4, 0.4, 0.5))
			info_btn.add_theme_font_size_override("font_size", 11)
			var s_info := info
			info_btn.pressed.connect(func():
				_show_emoji_install_info(s_info)
			)
			row.add_child(info_btn)

		parent.add_child(row)

	# Description of current set
	var cur_info: Dictionary = EmojiManager.get_set_info(current_id)
	var desc_lbl := Label.new()
	desc_lbl.text = "Current: " + cur_info.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(500, 0)
	var ds := LabelSettings.new()
	ds.font_size = 11
	ds.font_color = Color(0.5, 0.5, 0.6)
	desc_lbl.label_settings = ds
	parent.add_child(desc_lbl)

	# Rescan button
	var rescan_btn := Button.new()
	rescan_btn.text = "\U0001F504 Rescan for Fonts"
	rescan_btn.custom_minimum_size = Vector2(160, 28)
	_style_button(rescan_btn, Color(0.4, 0.5, 0.5))
	rescan_btn.add_theme_font_size_override("font_size", 11)
	rescan_btn.pressed.connect(func():
		EmojiManager.rescan()
		graphics_panel.queue_free()
		graphics_panel = null
		_build_graphics_panel()
	)
	parent.add_child(rescan_btn)

func _show_emoji_install_info(info: Dictionary) -> void:
	var popup := Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	popup.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-200, -120)
	box.size = Vector2(400, 240)
	box.add_theme_constant_override("separation", 8)
	popup.add_child(box)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.12, 0.95)
	box.add_child(bg)
	box.move_child(bg, 0)

	var title_lbl := Label.new()
	title_lbl.text = info.get("icon", "") + " " + info.get("name", "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tls := LabelSettings.new()
	tls.font_size = 18
	tls.font_color = Color(0.8, 0.8, 0.9)
	title_lbl.label_settings = tls
	box.add_child(title_lbl)

	var desc := Label.new()
	desc.text = info.get("desc", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(380, 0)
	var dls := LabelSettings.new()
	dls.font_size = 13
	dls.font_color = Color(0.7, 0.7, 0.75)
	desc.label_settings = dls
	box.add_child(desc)

	var file_lbl := Label.new()
	file_lbl.text = "Font file: " + info.get("font_file", "N/A")
	var fls := LabelSettings.new()
	fls.font_size = 12
	fls.font_color = Color(0.5, 0.7, 0.8)
	file_lbl.label_settings = fls
	box.add_child(file_lbl)

	var license_lbl := Label.new()
	license_lbl.text = "License: " + info.get("license", "Unknown")
	var lls := LabelSettings.new()
	lls.font_size = 12
	lls.font_color = Color(0.5, 0.6, 0.5)
	license_lbl.label_settings = lls
	box.add_child(license_lbl)

	var url_str: String = info.get("url", "")
	if url_str != "":
		var url_lbl := Label.new()
		url_lbl.text = "Download: " + url_str
		url_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		url_lbl.custom_minimum_size = Vector2(380, 0)
		var uls := LabelSettings.new()
		uls.font_size = 11
		uls.font_color = Color(0.4, 0.6, 0.9)
		url_lbl.label_settings = uls
		box.add_child(url_lbl)

	var path_lbl := Label.new()
	path_lbl.text = "Place .ttf in: res://fonts/emoji/ or user://fonts/emoji/"
	var pls := LabelSettings.new()
	pls.font_size = 11
	pls.font_color = Color(0.6, 0.5, 0.4)
	path_lbl.label_settings = pls
	box.add_child(path_lbl)

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(100, 28)
	_style_button(close, Color(0.5, 0.3, 0.3))
	close.pressed.connect(popup.queue_free)
	box.add_child(close)

	add_child(popup)

func _refresh_menu_emojis() -> void:
	# Update the title and race buttons to use the new font
	if title_label:
		title_label.label_settings.font = GameData.emoji_font
	for btn in race_buttons:
		if is_instance_valid(btn):
			btn.add_theme_font_override("font", GameData.emoji_font)
	for btn in class_buttons:
		if is_instance_valid(btn):
			btn.add_theme_font_override("font", GameData.emoji_font)

func _apply_quality_preset(quality: int) -> void:
	match quality:
		0: # Low
			GameSystems.set_setting("blood_enabled", false)
			GameSystems.set_setting("blood_intensity", 0)
			GameSystems.set_setting("gore_enabled", false)
			GameSystems.set_setting("particles_enabled", false)
			GameSystems.set_setting("particle_density", 0)
			GameSystems.set_setting("shadows_enabled", false)
			GameSystems.set_setting("dynamic_lighting", false)
			GameSystems.set_setting("hit_flash_enabled", false)
			GameSystems.set_setting("trail_effects", false)
			GameSystems.set_setting("impact_effects", false)
			GameSystems.set_setting("ambient_particles", false)
			GameSystems.set_setting("hit_pause_enabled", false)
			GameSystems.set_setting("camera_punch", false)
			GameSystems.set_setting("screen_shake", false)
			GameSystems.set_setting("vignette_enabled", false)
			GameSystems.set_setting("damage_numbers", true)
			GameSystems.set_setting("hit_markers", false)
		1: # Medium
			GameSystems.set_setting("blood_enabled", true)
			GameSystems.set_setting("blood_intensity", 1)
			GameSystems.set_setting("gore_enabled", false)
			GameSystems.set_setting("particles_enabled", true)
			GameSystems.set_setting("particle_density", 1)
			GameSystems.set_setting("shadows_enabled", true)
			GameSystems.set_setting("dynamic_lighting", true)
			GameSystems.set_setting("hit_flash_enabled", true)
			GameSystems.set_setting("trail_effects", false)
			GameSystems.set_setting("impact_effects", true)
			GameSystems.set_setting("ambient_particles", false)
			GameSystems.set_setting("hit_pause_enabled", false)
			GameSystems.set_setting("camera_punch", true)
			GameSystems.set_setting("screen_shake", true)
			GameSystems.set_setting("vignette_enabled", true)
			GameSystems.set_setting("damage_numbers", true)
			GameSystems.set_setting("hit_markers", true)
		2: # High
			GameSystems.set_setting("blood_enabled", true)
			GameSystems.set_setting("blood_intensity", 2)
			GameSystems.set_setting("gore_enabled", true)
			GameSystems.set_setting("particles_enabled", true)
			GameSystems.set_setting("particle_density", 2)
			GameSystems.set_setting("shadows_enabled", true)
			GameSystems.set_setting("dynamic_lighting", true)
			GameSystems.set_setting("hit_flash_enabled", true)
			GameSystems.set_setting("trail_effects", true)
			GameSystems.set_setting("impact_effects", true)
			GameSystems.set_setting("ambient_particles", true)
			GameSystems.set_setting("hit_pause_enabled", true)
			GameSystems.set_setting("camera_punch", true)
			GameSystems.set_setting("screen_shake", true)
			GameSystems.set_setting("vignette_enabled", true)
			GameSystems.set_setting("damage_numbers", true)
			GameSystems.set_setting("hit_markers", true)
		3: # Ultra
			GameSystems.set_setting("blood_enabled", true)
			GameSystems.set_setting("blood_intensity", 3)
			GameSystems.set_setting("gore_enabled", true)
			GameSystems.set_setting("particles_enabled", true)
			GameSystems.set_setting("particle_density", 3)
			GameSystems.set_setting("shadows_enabled", true)
			GameSystems.set_setting("dynamic_lighting", true)
			GameSystems.set_setting("hit_flash_enabled", true)
			GameSystems.set_setting("trail_effects", true)
			GameSystems.set_setting("impact_effects", true)
			GameSystems.set_setting("ambient_particles", true)
			GameSystems.set_setting("hit_pause_enabled", true)
			GameSystems.set_setting("camera_punch", true)
			GameSystems.set_setting("screen_shake", true)
			GameSystems.set_setting("vignette_enabled", true)
			GameSystems.set_setting("damage_numbers", true)
			GameSystems.set_setting("hit_markers", true)

func _process(delta: float) -> void:
	bg_timer += delta
	if not title_label or not title_label.label_settings:
		return
	var pulse := (sin(bg_timer * 0.5) + 1.0) * 0.5
	title_label.label_settings.font_color = Color(
		0.7 + pulse * 0.15,
		0.5 + pulse * 0.1,
		0.85 + pulse * 0.15
	)
