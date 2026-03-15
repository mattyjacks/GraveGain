extends CanvasLayer

# ===== PAUSE MENU =====
# Proper pause menu with resume, inventory, settings, and quit options

signal resumed()
signal quit_to_menu()

var is_open: bool = false

# UI nodes
var overlay: ColorRect
var panel: Panel
var title_label: Label
var resume_btn: Button
var inventory_btn: Button
var settings_btn: Button
var quit_btn: Button
var stats_label: RichTextLabel
var tips_label: Label

# Settings sub-panel
var settings_panel: Panel
var settings_open: bool = false

func _ready() -> void:
	layer = 99
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_stats()
	_show_random_tip()

func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	settings_panel.visible = false
	settings_open = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	resumed.emit()

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func _build_ui() -> void:
	# Dark overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Main panel
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(400, 500)
	panel.position = Vector2(-200, -250)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(0.5, 0.4, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# Title
	title_label = Label.new()
	title_label.text = "PAUSED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 20)
	title_label.size = Vector2(400, 40)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_label.add_theme_font_size_override("font_size", 28)
	panel.add_child(title_label)
	
	# Button container
	var btn_container := VBoxContainer.new()
	btn_container.position = Vector2(80, 80)
	btn_container.size = Vector2(240, 250)
	btn_container.add_theme_constant_override("separation", 12)
	panel.add_child(btn_container)
	
	# Resume button
	resume_btn = _create_menu_button("Resume", Color(0.3, 0.8, 0.3))
	resume_btn.pressed.connect(close)
	btn_container.add_child(resume_btn)
	
	# Inventory button
	inventory_btn = _create_menu_button("Inventory", Color(0.6, 0.7, 1.0))
	inventory_btn.pressed.connect(_on_inventory_pressed)
	btn_container.add_child(inventory_btn)
	
	# Settings button
	settings_btn = _create_menu_button("Settings", Color(0.7, 0.7, 0.8))
	settings_btn.pressed.connect(_on_settings_pressed)
	btn_container.add_child(settings_btn)
	
	# Quit to menu button
	quit_btn = _create_menu_button("Quit to Menu", Color(1.0, 0.4, 0.3))
	quit_btn.pressed.connect(_on_quit_pressed)
	btn_container.add_child(quit_btn)
	
	# Stats display
	stats_label = RichTextLabel.new()
	stats_label.position = Vector2(20, 340)
	stats_label.size = Vector2(360, 100)
	stats_label.bbcode_enabled = true
	stats_label.scroll_active = false
	stats_label.add_theme_font_size_override("normal_font_size", 11)
	panel.add_child(stats_label)
	
	# Loading tip at bottom
	tips_label = Label.new()
	tips_label.position = Vector2(20, 450)
	tips_label.size = Vector2(360, 40)
	tips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	tips_label.add_theme_font_size_override("font_size", 10)
	panel.add_child(tips_label)
	
	# Settings sub-panel
	_build_settings_panel()

func _create_menu_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 44)
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.9)
	normal_style.border_color = color * 0.6
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(6)
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.9)
	hover_style.border_color = color * 0.8
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	hover_style.content_margin_top = 8
	hover_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(color.r * 0.35, color.g * 0.35, color.b * 0.35, 0.9)
	pressed_style.border_color = color
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(6)
	pressed_style.content_margin_top = 8
	pressed_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color * 1.2)
	btn.add_theme_font_size_override("font_size", 16)
	
	return btn

func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.size = Vector2(500, 400)
	settings_panel.position = Vector2(-250, -200)
	settings_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	style.border_color = Color(0.5, 0.4, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	settings_panel.add_theme_stylebox_override("panel", style)
	add_child(settings_panel)
	
	var stitle := Label.new()
	stitle.text = "SETTINGS"
	stitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitle.position = Vector2(0, 15)
	stitle.size = Vector2(500, 30)
	stitle.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	stitle.add_theme_font_size_override("font_size", 20)
	settings_panel.add_child(stitle)
	
	var settings_container := VBoxContainer.new()
	settings_container.position = Vector2(30, 60)
	settings_container.size = Vector2(440, 280)
	settings_container.add_theme_constant_override("separation", 10)
	settings_panel.add_child(settings_container)
	
	# Volume slider
	_add_slider_setting(settings_container, "Master Volume", "master_volume", 0.0, 1.0, 0.8)
	_add_slider_setting(settings_container, "SFX Volume", "sfx_volume", 0.0, 1.0, 0.8)
	_add_slider_setting(settings_container, "Music Volume", "music_volume", 0.0, 1.0, 0.5)
	
	# Camera zoom slider
	_add_slider_setting(settings_container, "Camera Zoom", "camera_zoom", 0.5, 3.0, 1.5)
	
	# Toggle shadows
	_add_toggle_setting(settings_container, "Shadows", "shadows_enabled", true)
	
	# Toggle screen shake
	_add_toggle_setting(settings_container, "Screen Shake", "screen_shake_enabled", true)
	
	# Toggle auto-pickup
	_add_toggle_setting(settings_container, "Auto Pickup", "auto_pickup", true)
	
	# Back button
	var back_btn := _create_menu_button("Back", Color(0.7, 0.7, 0.8))
	back_btn.pressed.connect(func():
		settings_panel.visible = false
		settings_open = false
	)
	back_btn.position = Vector2(130, 350)
	back_btn.size = Vector2(240, 40)
	settings_panel.add_child(back_btn)

func _add_slider_setting(container: VBoxContainer, label_text: String, setting_key: String, min_val: float, max_val: float, default_val: float) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)
	
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	hbox.add_child(label)
	
	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.05
	var saved = GameSystems.get_setting(setting_key)
	slider.value = saved if saved != null else default_val
	slider.custom_minimum_size = Vector2(200, 20)
	slider.value_changed.connect(func(val: float): GameSystems.set_setting(setting_key, val))
	hbox.add_child(slider)
	
	var val_label := Label.new()
	val_label.text = str(snappedf(slider.value, 0.01))
	val_label.custom_minimum_size = Vector2(50, 0)
	val_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(val_label)
	slider.value_changed.connect(func(val: float): val_label.text = str(snappedf(val, 0.01)))

func _add_toggle_setting(container: VBoxContainer, label_text: String, setting_key: String, default_val: bool) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)
	
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	hbox.add_child(label)
	
	var checkbox := CheckButton.new()
	var saved = GameSystems.get_setting(setting_key)
	checkbox.button_pressed = saved if saved != null and saved is bool else default_val
	checkbox.toggled.connect(func(val: bool): GameSystems.set_setting(setting_key, val))
	hbox.add_child(checkbox)

func _update_stats() -> void:
	if not stats_label:
		return
	var text := "[color=#888888]Mission Stats:[/color]\n"
	var kills: int = GameSystems.stats.get("total_kills", 0)
	var gold_val: int = GameSystems.stats.get("total_gold_earned", 0)
	var dmg_dealt: float = GameSystems.stats.get("total_damage_dealt", 0.0)
	var dmg_taken: float = GameSystems.stats.get("total_damage_taken", 0.0)
	text += "Kills: [color=#FF8888]" + str(kills) + "[/color]  "
	text += "Gold: [color=#FFDD44]" + str(gold_val) + "[/color]\n"
	text += "Damage Dealt: [color=#88FF88]" + str(int(dmg_dealt)) + "[/color]  "
	text += "Damage Taken: [color=#FF6666]" + str(int(dmg_taken)) + "[/color]\n"
	text += "Level: [color=#AADDFF]" + str(GameSystems.player_level) + "[/color]  "
	text += "XP: [color=#AADDFF]" + str(GameSystems.player_xp) + "/" + str(GameSystems.xp_to_next_level) + "[/color]"
	stats_label.text = text

func _show_random_tip() -> void:
	if not tips_label:
		return
	var tips := GameSystems.loading_tips
	if tips.size() > 0:
		tips_label.text = "Tip: " + tips[randi() % tips.size()]
	else:
		tips_label.text = "Tip: Press ESC to resume"

# ===== ACTIONS =====

func _on_inventory_pressed() -> void:
	# The game.gd will connect this to open inventory
	close()
	# Let game handle opening inventory
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui and inv_ui.has_method("open"):
		inv_ui.open()

func _on_settings_pressed() -> void:
	settings_panel.visible = true
	settings_open = true

func _on_quit_pressed() -> void:
	is_open = false
	visible = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	quit_to_menu.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if settings_open:
				settings_panel.visible = false
				settings_open = false
				get_viewport().set_input_as_handled()
			elif is_open:
				close()
				get_viewport().set_input_as_handled()
