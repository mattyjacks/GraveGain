extends CanvasLayer

var hp_bar: ColorRect
var hp_bar_bg: ColorRect
var hp_bar_temp: ColorRect
var hp_label: Label
var stamina_bar: ColorRect
var stamina_bar_bg: ColorRect
var shield_bar: ColorRect
var shield_bar_bg: ColorRect
var mana_bar: ColorRect
var mana_bar_bg: ColorRect
var rage_bar: ColorRect
var rage_bar_bg: ColorRect
var resource_container: Control

var gold_label: Label
var ammo_label: Label
var slot_label: Label
var timer_label: Label
var kills_label: Label
var class_label: Label
var fps_label: Label

var minimap_rect: ColorRect
var minimap_texture_rect: TextureRect

var damage_numbers: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []
var notification_queue: Array[Dictionary] = []
var notification_timer: float = 0.0

var vignette_alpha: float = 0.0
var wounded_pulse: float = 0.0

# Improvement #66: Damage Direction Indicator
var damage_indicators: Array[Dictionary] = []
# Improvement #68: Kill Feed
var kill_feed_entries: Array[Dictionary] = []
var kill_feed_max: int = 5
# Improvement #71: Combo Counter
var combo_label: Label = null
var combo_timer: float = 0.0
# Improvement #73: XP Bar
var xp_bar_bg: ColorRect = null
var xp_bar: ColorRect = null
var level_label: Label = null
# Improvement #74: Boss HP Bar
var boss_bar_bg: ColorRect = null
var boss_bar: ColorRect = null
var boss_name_label: Label = null
var boss_visible: bool = false
# Improvement #72: Hit Marker
var hit_marker_timer: float = 0.0
var hit_marker_crit: bool = false
var crosshair_label: Label = null
# Improvement #78: Achievement Popup
var achievement_queue: Array[Dictionary] = []
# Improvement #79: Score Display
var score_label: Label = null
var streak_label: Label = null
# Improvement #96: Tutorial Hint
var tutorial_label: Label = null
var tutorial_timer: float = 0.0
# Improvement #67: Low HP Vignette
var vignette_rect: ColorRect = null
# Improvement: Room name display
var room_label: Label = null
var room_label_timer: float = 0.0

# Improvement #56: Health bar color transitions
var hp_bar_target_width: float = 0.0
var hp_bar_lerp_speed: float = 8.0
var hp_bar_damage_flash: float = 0.0

# Improvement #57: Stamina flash warning
var stamina_flash_timer: float = 0.0
var stamina_was_low: bool = false

# Improvement #58: Buff/debuff icon strip
var buff_container: Control = null
var active_buffs: Array[Dictionary] = []

# Improvement #59: DPS meter
var dps_label: Label = null
var dps_samples: Array[float] = []
var dps_timer: float = 0.0
var current_dps: float = 0.0

# Improvement #60: Gold pickup popup
var gold_popup_amount: int = 0
var gold_popup_timer: float = 0.0
var gold_popup_label: Label = null

# Improvement #61: Death screen
var death_panel: Control = null
var death_stats_label: Label = null
var death_visible: bool = false

# Improvement #62: Kill streak announcements
var streak_announce_label: Label = null
var streak_announce_timer: float = 0.0

# Improvement #63: Bloodlust indicator
var bloodlust_label: Label = null

# Improvement #64: Charge bar
var charge_bar_bg: ColorRect = null
var charge_bar: ColorRect = null

# Improvement #65: Minimap legend dots
var minimap_legend_visible: bool = true

var slot_icons: Dictionary = {
	1: "\u2694\uFE0F Melee",
	2: "\U0001F52B Ranged",
	3: "\U0001F4A3 Throwable",
	4: "\U0001F48A Consumable",
}

var bar_width: float = 240.0
var bar_height: float = 16.0

func _ready() -> void:
	layer = 100
	_build_hud()

func _build_hud() -> void:
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)

	_build_health_bars(anchor)
	_build_resource_bars(anchor)
	_build_info_labels(anchor)
	_build_minimap(anchor)
	_build_crosshair(anchor)
	_build_slot_display(anchor)
	_build_xp_bar(anchor)
	_build_combo_display(anchor)
	_build_boss_bar(anchor)
	_build_kill_feed(anchor)
	_build_score_display(anchor)
	_build_vignette(anchor)
	_build_tutorial_display(anchor)
	_build_room_label(anchor)
	_build_buff_display(anchor)
	_build_dps_meter(anchor)
	_build_gold_popup(anchor)
	_build_death_screen(anchor)
	_build_streak_announce(anchor)
	_build_bloodlust_display(anchor)
	_build_charge_bar(anchor)
	_connect_systems()

func _build_health_bars(parent: Control) -> void:
	var y_offset := 20.0
	var x_offset := 20.0

	hp_bar_bg = _make_bar(parent, x_offset, y_offset, bar_width, bar_height, Color(0.15, 0.0, 0.0, 0.8))
	hp_bar_temp = _make_bar(parent, x_offset, y_offset, bar_width, bar_height, Color(0.8, 0.6, 0.1, 0.7))
	hp_bar = _make_bar(parent, x_offset, y_offset, bar_width, bar_height, Color(0.8, 0.15, 0.1, 0.9))

	hp_label = Label.new()
	hp_label.position = Vector2(x_offset, y_offset - 2)
	hp_label.size = Vector2(bar_width, bar_height)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hp_settings := LabelSettings.new()
	hp_settings.font_size = 11
	hp_settings.font_color = Color.WHITE
	hp_settings.outline_size = 2
	hp_settings.outline_color = Color.BLACK
	hp_label.label_settings = hp_settings
	parent.add_child(hp_label)

	y_offset += bar_height + 4
	stamina_bar_bg = _make_bar(parent, x_offset, y_offset, bar_width, 10, Color(0.0, 0.1, 0.0, 0.8))
	stamina_bar = _make_bar(parent, x_offset, y_offset, bar_width, 10, Color(0.2, 0.7, 0.2, 0.9))

func _build_resource_bars(parent: Control) -> void:
	resource_container = Control.new()
	resource_container.position = Vector2(20, 52)
	parent.add_child(resource_container)

	var stats: Dictionary = GameData.race_stats[GameData.selected_race]

	if stats["has_shields"]:
		shield_bar_bg = _make_bar(resource_container, 0, 0, bar_width, 8, Color(0.0, 0.05, 0.15, 0.8))
		shield_bar = _make_bar(resource_container, 0, 0, bar_width, 8, Color(0.3, 0.5, 1.0, 0.9))

	if stats["has_mana"]:
		var y := 0.0 if not stats["has_shields"] else 12.0
		mana_bar_bg = _make_bar(resource_container, 0, y, bar_width, 8, Color(0.05, 0.0, 0.15, 0.8))
		mana_bar = _make_bar(resource_container, 0, y, bar_width, 8, Color(0.4, 0.2, 0.9, 0.9))

	if stats["has_rage"]:
		rage_bar_bg = _make_bar(resource_container, 0, 0, bar_width, 8, Color(0.15, 0.05, 0.0, 0.8))
		rage_bar = _make_bar(resource_container, 0, 0, bar_width, 8, Color(0.9, 0.3, 0.1, 0.9))

func _build_info_labels(parent: Control) -> void:
	var right_x := -260.0

	class_label = _make_label(parent, Vector2(20, 80), Vector2(300, 24))
	var race_name: String = GameData.race_stats[GameData.selected_race]["name"]
	var class_name_str: String = GameData.get_class_name_for(GameData.selected_race, GameData.selected_class)
	class_label.text = race_name + " " + class_name_str

	gold_label = _make_label(parent, Vector2(20, 102), Vector2(200, 20))
	gold_label.text = "\U0001FA99 0"

	ammo_label = _make_label(parent, Vector2(20, 122), Vector2(200, 20))
	ammo_label.text = "\U0001F4A5 30 / 30"

	timer_label = _make_label(parent, Vector2(0, 10), Vector2(200, 24))
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position.x = -100

	kills_label = _make_label(parent, Vector2(0, 34), Vector2(200, 20))
	kills_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.position.x = -100
	kills_label.text = "\U0001F480 0"

	fps_label = _make_label(parent, Vector2(-120, 10), Vector2(100, 20))
	fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _build_minimap(parent: Control) -> void:
	minimap_rect = ColorRect.new()
	minimap_rect.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_rect.position = Vector2(-170, 40)
	minimap_rect.size = Vector2(150, 150)
	minimap_rect.color = Color(0.0, 0.0, 0.0, 0.6)
	parent.add_child(minimap_rect)

	minimap_texture_rect = TextureRect.new()
	minimap_texture_rect.position = Vector2(0, 0)
	minimap_texture_rect.size = Vector2(150, 150)
	minimap_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	minimap_rect.add_child(minimap_texture_rect)

func _build_crosshair(parent: Control) -> void:
	crosshair_label = Label.new()
	crosshair_label.text = "+"
	crosshair_label.set_anchors_preset(Control.PRESET_CENTER)
	crosshair_label.position = Vector2(-6, -8)
	crosshair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ch_settings := LabelSettings.new()
	ch_settings.font_size = 16
	ch_settings.font_color = Color(1, 1, 1, 0.6)
	ch_settings.outline_size = 1
	ch_settings.outline_color = Color(0, 0, 0, 0.5)
	crosshair_label.label_settings = ch_settings
	crosshair_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(crosshair_label)

func _build_slot_display(parent: Control) -> void:
	slot_label = Label.new()
	slot_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	slot_label.position = Vector2(20, -50)
	slot_label.size = Vector2(300, 30)
	var sl_settings := LabelSettings.new()
	sl_settings.font_size = 14
	sl_settings.font_color = Color(0.9, 0.9, 0.9)
	sl_settings.outline_size = 2
	sl_settings.outline_color = Color(0, 0, 0)
	slot_label.label_settings = sl_settings
	slot_label.text = slot_icons.get(1, "Melee")
	parent.add_child(slot_label)

func _make_bar(parent: Control, x: float, y: float, w: float, h: float, color: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.position = Vector2(x, y)
	bar.size = Vector2(w, h)
	bar.color = color
	parent.add_child(bar)
	return bar

func _make_label(parent: Control, pos: Vector2, sz: Vector2) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	var settings := LabelSettings.new()
	settings.font_size = 13
	settings.font_color = Color(0.9, 0.9, 0.9)
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0)
	lbl.label_settings = settings
	parent.add_child(lbl)
	return lbl

func _process(delta: float) -> void:
	if GameSystems.get_setting("show_fps"):
		fps_label.text = str(Engine.get_frames_per_second()) + " FPS"
		fps_label.visible = true
	else:
		fps_label.visible = false

	_update_damage_numbers(delta)
	_update_notifications(delta)
	_update_damage_indicators(delta)
	_update_hit_marker(delta)
	_update_combo(delta)
	_update_achievement_popup(delta)
	_update_vignette(delta)
	_update_tutorial(delta)
	_update_room_label(delta)
	_update_kill_feed(delta)
	_update_buffs(delta)
	_update_dps(delta)
	_update_gold_popup(delta)
	_update_streak_announce(delta)
	_update_charge_bar(delta)

	# Improvement #56: Smooth HP bar lerp
	if hp_bar_damage_flash > 0:
		hp_bar_damage_flash -= delta * 3.0

	# Improvement #57: Stamina flash
	if stamina_flash_timer > 0:
		stamina_flash_timer -= delta
		var flash := sin(stamina_flash_timer * 15.0) * 0.5 + 0.5
		stamina_bar.color = Color(0.8, 0.2 + flash * 0.5, 0.2, 0.9)
	else:
		stamina_bar.color = Color(0.2, 0.7, 0.2, 0.9)

	wounded_pulse += delta * 3.0

func update_hp(current: float, temp: float, max_val: float) -> void:
	var total := current
	var real := current - temp
	var safe_max := maxf(max_val, 1.0)
	var target_w := clampf((real / safe_max) * bar_width, 0.0, bar_width)
	# Improvement #56: Smooth HP bar with color transitions
	hp_bar.size.x = lerpf(hp_bar.size.x, target_w, 0.15)
	hp_bar_temp.size.x = clampf((total / safe_max) * bar_width, 0.0, bar_width)
	hp_label.text = str(int(real)) + " + " + str(int(temp)) + " / " + str(int(max_val))
	# Color based on HP percentage
	var hp_pct := real / safe_max
	if hp_pct > 0.6:
		hp_bar.color = Color(0.2, 0.8, 0.2, 0.9)
	elif hp_pct > 0.3:
		hp_bar.color = Color(0.9, 0.7, 0.1, 0.9)
	else:
		hp_bar.color = Color(0.9, 0.15, 0.1, 0.9)
		hp_bar_damage_flash = 1.0
	# Update vignette intensity
	set_vignette_intensity(hp_pct)

func update_stamina(current: float, max_val: float) -> void:
	var target_w := clampf((current / maxf(max_val, 1.0)) * bar_width, 0.0, bar_width)
	stamina_bar.size.x = lerpf(stamina_bar.size.x, target_w, 0.2)
	# Improvement #57: Stamina flash warning when low
	var pct := current / maxf(max_val, 1.0)
	if pct < 0.2 and not stamina_was_low:
		stamina_was_low = true
		stamina_flash_timer = 1.0
	elif pct >= 0.3:
		stamina_was_low = false

func update_shields(current: float, max_val: float) -> void:
	if shield_bar:
		shield_bar.size.x = (current / maxf(max_val, 1.0)) * bar_width

func update_mana(current: float, max_val: float) -> void:
	if mana_bar:
		mana_bar.size.x = (current / maxf(max_val, 1.0)) * bar_width

func update_rage(current: float, max_val: float) -> void:
	if rage_bar:
		rage_bar.size.x = (current / maxf(max_val, 1.0)) * bar_width

func update_gold(amount: int) -> void:
	gold_label.text = "\U0001FA99 " + str(amount)

func update_ammo(current: int, max_val: int) -> void:
	ammo_label.text = "\U0001F4A5 " + str(current) + " / " + str(max_val)

func update_slot(slot: int) -> void:
	slot_label.text = slot_icons.get(slot, "???")

func update_timer(seconds: float) -> void:
	var mins := int(seconds) / 60.0
	var secs := int(seconds) % 60
	timer_label.text = "\u23F1 " + str(mins) + ":" + str(secs).pad_zeros(2)

func update_kills(count: int) -> void:
	kills_label.text = "\U0001F480 " + str(count)

func spawn_damage_number(pos: Vector2, amount: float, is_crit: bool = false) -> void:
	damage_numbers.append({
		"pos": pos,
		"amount": amount,
		"timer": 1.0,
		"vel": Vector2(randf_range(-30, 30), -60),
		"is_crit": is_crit,
	})

func show_notification(text: String, color: Color = Color.WHITE) -> void:
	notification_queue.append({"text": text, "color": color, "timer": 3.0})

func _update_damage_numbers(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(damage_numbers.size()):
		damage_numbers[i]["timer"] -= delta
		damage_numbers[i]["pos"] += damage_numbers[i]["vel"] * delta
		damage_numbers[i]["vel"].y += 80 * delta
		if damage_numbers[i]["timer"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		damage_numbers.remove_at(idx)

func _update_notifications(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(notification_queue.size()):
		notification_queue[i]["timer"] -= delta
		if notification_queue[i]["timer"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		notification_queue.remove_at(idx)

# ===== New HUD Build Functions =====

# Improvement #73: XP Bar
func _build_xp_bar(parent: Control) -> void:
	var y := 142.0
	xp_bar_bg = _make_bar(parent, 20, y, bar_width, 6, Color(0.05, 0.05, 0.15, 0.7))
	xp_bar = _make_bar(parent, 20, y, 0, 6, Color(0.3, 0.7, 1.0, 0.8))
	level_label = _make_label(parent, Vector2(20, y - 16), Vector2(200, 16))
	level_label.label_settings.font_size = 10
	level_label.text = "Lv.1"

# Improvement #71: Combo Counter
func _build_combo_display(parent: Control) -> void:
	combo_label = Label.new()
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.position = Vector2(80, -40)
	combo_label.size = Vector2(200, 40)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cl_settings := LabelSettings.new()
	cl_settings.font_size = 24
	cl_settings.font_color = Color(1.0, 0.9, 0.3)
	cl_settings.outline_size = 3
	cl_settings.outline_color = Color(0, 0, 0)
	combo_label.label_settings = cl_settings
	combo_label.visible = false
	parent.add_child(combo_label)

# Improvement #74: Boss HP Bar
func _build_boss_bar(parent: Control) -> void:
	boss_bar_bg = ColorRect.new()
	boss_bar_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar_bg.position = Vector2(-200, 60)
	boss_bar_bg.size = Vector2(400, 20)
	boss_bar_bg.color = Color(0.1, 0.0, 0.0, 0.8)
	boss_bar_bg.visible = false
	parent.add_child(boss_bar_bg)

	boss_bar = ColorRect.new()
	boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(-200, 60)
	boss_bar.size = Vector2(400, 20)
	boss_bar.color = Color(0.8, 0.1, 0.1, 0.9)
	boss_bar.visible = false
	parent.add_child(boss_bar)

	boss_name_label = Label.new()
	boss_name_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_name_label.position = Vector2(-200, 58)
	boss_name_label.size = Vector2(400, 24)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bn_settings := LabelSettings.new()
	bn_settings.font_size = 13
	bn_settings.font_color = Color.WHITE
	bn_settings.outline_size = 2
	bn_settings.outline_color = Color.BLACK
	boss_name_label.label_settings = bn_settings
	boss_name_label.visible = false
	parent.add_child(boss_name_label)

# Improvement #68: Kill Feed
func _build_kill_feed(_parent: Control) -> void:
	pass

# Improvement #79: Score Display
func _build_score_display(parent: Control) -> void:
	score_label = _make_label(parent, Vector2(0, 56), Vector2(200, 20))
	score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	score_label.position.x = -100
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.text = ""

	streak_label = _make_label(parent, Vector2(0, 76), Vector2(200, 20))
	streak_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	streak_label.position.x = -100
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_label.label_settings.font_color = Color(1.0, 0.6, 0.2)
	streak_label.text = ""

# Improvement #67: Low HP Vignette
func _build_vignette(parent: Control) -> void:
	vignette_rect = ColorRect.new()
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.color = Color(0.5, 0.0, 0.0, 0.0)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vignette_rect)

# Improvement #96: Tutorial Hint
func _build_tutorial_display(parent: Control) -> void:
	tutorial_label = Label.new()
	tutorial_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tutorial_label.position = Vector2(-250, -100)
	tutorial_label.size = Vector2(500, 40)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tut_settings := LabelSettings.new()
	tut_settings.font_size = 14
	tut_settings.font_color = Color(0.9, 0.85, 0.6)
	tut_settings.outline_size = 2
	tut_settings.outline_color = Color(0, 0, 0)
	tutorial_label.label_settings = tut_settings
	tutorial_label.visible = false
	parent.add_child(tutorial_label)

# Improvement: Room name display
func _build_room_label(parent: Control) -> void:
	room_label = Label.new()
	room_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	room_label.position = Vector2(-150, 90)
	room_label.size = Vector2(300, 30)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rl_settings := LabelSettings.new()
	rl_settings.font_size = 16
	rl_settings.font_color = Color(0.8, 0.75, 0.6, 0.9)
	rl_settings.outline_size = 2
	rl_settings.outline_color = Color(0, 0, 0)
	room_label.label_settings = rl_settings
	room_label.visible = false
	parent.add_child(room_label)

# Improvement #58: Buff/debuff strip
func _build_buff_display(parent: Control) -> void:
	buff_container = Control.new()
	buff_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	buff_container.position = Vector2(20, 160)
	buff_container.size = Vector2(300, 24)
	parent.add_child(buff_container)

# Improvement #59: DPS Meter
func _build_dps_meter(parent: Control) -> void:
	dps_label = _make_label(parent, Vector2(-220, 34), Vector2(200, 20))
	dps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dps_label.text = ""

# Improvement #60: Gold pickup popup
func _build_gold_popup(parent: Control) -> void:
	gold_popup_label = Label.new()
	gold_popup_label.set_anchors_preset(Control.PRESET_CENTER)
	gold_popup_label.position = Vector2(-50, 30)
	gold_popup_label.size = Vector2(100, 30)
	gold_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gp_settings := LabelSettings.new()
	gp_settings.font_size = 16
	gp_settings.font_color = Color(1.0, 0.85, 0.2)
	gp_settings.outline_size = 2
	gp_settings.outline_color = Color(0, 0, 0)
	gold_popup_label.label_settings = gp_settings
	gold_popup_label.visible = false
	parent.add_child(gold_popup_label)

# Improvement #61: Death screen
func _build_death_screen(parent: Control) -> void:
	death_panel = Control.new()
	death_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_panel.visible = false
	parent.add_child(death_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_panel.add_child(bg)

	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-150, -120)
	title.size = Vector2(300, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 32
	title_settings.font_color = Color(0.9, 0.2, 0.2)
	title_settings.outline_size = 3
	title_settings.outline_color = Color(0, 0, 0)
	title.label_settings = title_settings
	title.text = "YOU DIED"
	death_panel.add_child(title)

	death_stats_label = Label.new()
	death_stats_label.set_anchors_preset(Control.PRESET_CENTER)
	death_stats_label.position = Vector2(-150, -60)
	death_stats_label.size = Vector2(300, 200)
	death_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ds_settings := LabelSettings.new()
	ds_settings.font_size = 14
	ds_settings.font_color = Color(0.8, 0.8, 0.8)
	ds_settings.outline_size = 2
	ds_settings.outline_color = Color(0, 0, 0)
	death_stats_label.label_settings = ds_settings
	death_panel.add_child(death_stats_label)

# Improvement #62: Kill streak announce
func _build_streak_announce(parent: Control) -> void:
	streak_announce_label = Label.new()
	streak_announce_label.set_anchors_preset(Control.PRESET_CENTER)
	streak_announce_label.position = Vector2(-200, -80)
	streak_announce_label.size = Vector2(400, 50)
	streak_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sa_settings := LabelSettings.new()
	sa_settings.font_size = 28
	sa_settings.font_color = Color(1.0, 0.7, 0.2)
	sa_settings.outline_size = 3
	sa_settings.outline_color = Color(0, 0, 0)
	streak_announce_label.label_settings = sa_settings
	streak_announce_label.visible = false
	parent.add_child(streak_announce_label)

# Improvement #63: Bloodlust stacks indicator
func _build_bloodlust_display(parent: Control) -> void:
	bloodlust_label = _make_label(parent, Vector2(20, 180), Vector2(200, 20))
	bloodlust_label.text = ""
	bloodlust_label.label_settings.font_color = Color(1.0, 0.3, 0.3)

# Improvement #64: Charge bar
func _build_charge_bar(parent: Control) -> void:
	charge_bar_bg = ColorRect.new()
	charge_bar_bg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	charge_bar_bg.position = Vector2(-60, -60)
	charge_bar_bg.size = Vector2(120, 8)
	charge_bar_bg.color = Color(0.1, 0.1, 0.1, 0.6)
	charge_bar_bg.visible = false
	parent.add_child(charge_bar_bg)

	charge_bar = ColorRect.new()
	charge_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	charge_bar.position = Vector2(-60, -60)
	charge_bar.size = Vector2(0, 8)
	charge_bar.color = Color(1.0, 0.7, 0.2, 0.9)
	charge_bar.visible = false
	parent.add_child(charge_bar)

func _connect_systems() -> void:
	GameSystems.kill_streak_updated.connect(_on_streak_updated)
	GameSystems.combo_updated.connect(_on_combo_updated)
	GameSystems.score_changed.connect(_on_score_changed)
	GameSystems.boss_hp_updated.connect(_on_boss_hp_updated)
	GameSystems.achievement_unlocked.connect(_on_achievement_unlocked)
	GameSystems.tutorial_hint.connect(_on_tutorial_hint)
	GameSystems.kill_feed_entry.connect(_on_kill_feed_entry)
	GameSystems.level_up.connect(_on_level_up)

# ===== Signal Handlers =====

func _on_streak_updated(streak: int, mult: float) -> void:
	if streak >= 3:
		streak_label.text = "\U0001F525 " + str(streak) + "x STREAK (" + str(mult) + "x)"
		streak_label.visible = true
		# Improvement #62: Big announcement for milestones
		if streak == 5:
			_show_streak_announce("KILLING SPREE!")
		elif streak == 10:
			_show_streak_announce("UNSTOPPABLE!")
		elif streak == 15:
			_show_streak_announce("RAMPAGE!")
		elif streak == 20:
			_show_streak_announce("GODLIKE!")
		elif streak == 25:
			_show_streak_announce("LEGENDARY!")
	else:
		streak_label.text = ""
		streak_label.visible = false

func _show_streak_announce(text: String) -> void:
	if streak_announce_label:
		streak_announce_label.text = text
		streak_announce_label.visible = true
		streak_announce_label.scale = Vector2(1.5, 1.5)
		streak_announce_timer = 2.0

func _on_combo_updated(count: int, timer: float) -> void:
	if count >= 2:
		combo_label.text = str(count) + " HIT COMBO"
		combo_label.visible = true
		combo_timer = timer
		var scale_pulse := 1.0 + count * 0.03
		combo_label.scale = Vector2(scale_pulse, scale_pulse)
	else:
		combo_label.visible = false

func _on_score_changed(new_score: int) -> void:
	if score_label and new_score > 0:
		score_label.text = "\u2B50 " + str(new_score)

func _on_boss_hp_updated(bname: String, hp_pct: float, vis: bool) -> void:
	boss_visible = vis
	boss_bar_bg.visible = vis
	boss_bar.visible = vis
	boss_name_label.visible = vis
	if vis:
		boss_bar.size.x = clampf(hp_pct * 400.0, 0.0, 400.0)
		boss_name_label.text = bname
		if hp_pct < 0.3:
			boss_bar.color = Color(1.0, 0.3, 0.1, 0.9)
		else:
			boss_bar.color = Color(0.8, 0.1, 0.1, 0.9)

func _on_achievement_unlocked(id: String, title: String) -> void:
	var icon: String = GameSystems.achievements.get(id, {}).get("icon", "\U0001F3C6") as String
	achievement_queue.append({"title": icon + " " + title, "timer": 4.0})

func _on_tutorial_hint(text: String, duration: float) -> void:
	tutorial_label.text = text
	tutorial_label.visible = true
	tutorial_timer = duration

func _on_kill_feed_entry(killer: String, victim: String, weapon: String) -> void:
	kill_feed_entries.append({"text": killer + " [" + weapon + "] " + victim, "timer": 4.0})
	if kill_feed_entries.size() > kill_feed_max:
		kill_feed_entries.pop_front()

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv." + str(new_level)
	show_notification("\u2B50 LEVEL UP! Level " + str(new_level), Color(0.3, 0.7, 1.0))

# ===== Damage Direction Indicator =====

func show_damage_direction(angle: float) -> void:
	damage_indicators.append({"angle": angle, "timer": 0.8})

func _update_damage_indicators(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(damage_indicators.size()):
		damage_indicators[i]["timer"] -= delta
		if damage_indicators[i]["timer"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		damage_indicators.remove_at(idx)

# Improvement #72: Hit Marker
func show_hit_marker(is_crit: bool = false) -> void:
	hit_marker_timer = 0.15
	hit_marker_crit = is_crit

func _update_hit_marker(delta: float) -> void:
	if hit_marker_timer > 0:
		hit_marker_timer -= delta
		if crosshair_label:
			if hit_marker_crit:
				crosshair_label.label_settings.font_color = Color(1.0, 0.3, 0.3, 1.0)
				crosshair_label.label_settings.font_size = 20
			else:
				crosshair_label.label_settings.font_color = Color(1.0, 1.0, 0.3, 1.0)
				crosshair_label.label_settings.font_size = 18
	else:
		if crosshair_label:
			crosshair_label.label_settings.font_color = Color(1, 1, 1, 0.6)
			crosshair_label.label_settings.font_size = 16

func _update_combo(delta: float) -> void:
	if combo_timer > 0 and combo_label:
		combo_timer -= delta
		combo_label.modulate.a = minf(combo_timer * 2.0, 1.0)
		if combo_timer <= 0:
			combo_label.visible = false

func _update_achievement_popup(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(achievement_queue.size()):
		achievement_queue[i]["timer"] -= delta
		if achievement_queue[i]["timer"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		achievement_queue.remove_at(idx)

# Improvement #67: Low HP Vignette
func _update_vignette(_delta: float) -> void:
	if not vignette_rect or not GameSystems.get_setting("vignette_enabled"):
		return
	var pulse := (sin(wounded_pulse) + 1.0) * 0.5
	vignette_rect.color = Color(0.5, 0.0, 0.0, vignette_alpha * (0.5 + pulse * 0.5))

func set_vignette_intensity(hp_pct: float) -> void:
	if hp_pct < 0.25:
		vignette_alpha = clampf((0.25 - hp_pct) * 1.5, 0.0, 0.4)
	else:
		vignette_alpha = 0.0

func _update_tutorial(delta: float) -> void:
	if tutorial_timer > 0 and tutorial_label:
		tutorial_timer -= delta
		tutorial_label.modulate.a = minf(tutorial_timer, 1.0)
		if tutorial_timer <= 0:
			tutorial_label.visible = false

func _update_room_label(delta: float) -> void:
	if room_label_timer > 0 and room_label:
		room_label_timer -= delta
		room_label.modulate.a = minf(room_label_timer, 1.0)
		if room_label_timer <= 0:
			room_label.visible = false

func _update_kill_feed(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(kill_feed_entries.size()):
		kill_feed_entries[i]["timer"] -= delta
		if kill_feed_entries[i]["timer"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		kill_feed_entries.remove_at(idx)

# ===== New Update Functions =====

func _update_buffs(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(active_buffs.size()):
		active_buffs[i]["timer"] -= delta
		if active_buffs[i]["timer"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		active_buffs.remove_at(idx)

func _update_dps(delta: float) -> void:
	dps_timer += delta
	if dps_timer >= 1.0:
		dps_timer = 0.0
		if current_dps > 0:
			dps_label.text = "DPS: " + str(int(current_dps))
		else:
			dps_label.text = ""
		current_dps = 0.0

func add_dps_sample(damage: float) -> void:
	current_dps += damage

func _update_gold_popup(delta: float) -> void:
	if gold_popup_timer > 0:
		gold_popup_timer -= delta
		if gold_popup_label:
			gold_popup_label.visible = true
			gold_popup_label.text = "+" + str(gold_popup_amount) + " \U0001FA99"
			gold_popup_label.modulate.a = clampf(gold_popup_timer * 2.0, 0, 1)
			gold_popup_label.position.y = 30 - (1.0 - gold_popup_timer) * 20.0
	else:
		if gold_popup_label:
			gold_popup_label.visible = false
		gold_popup_amount = 0

func show_gold_popup(amount: int) -> void:
	gold_popup_amount += amount
	gold_popup_timer = 2.0

func _update_streak_announce(delta: float) -> void:
	if streak_announce_timer > 0 and streak_announce_label:
		streak_announce_timer -= delta
		streak_announce_label.scale = streak_announce_label.scale.lerp(Vector2.ONE, delta * 5.0)
		streak_announce_label.modulate.a = clampf(streak_announce_timer, 0, 1)
		if streak_announce_timer <= 0:
			streak_announce_label.visible = false

func _update_charge_bar(_delta: float) -> void:
	pass

func show_charge_progress(pct: float) -> void:
	if charge_bar_bg and charge_bar:
		if pct > 0:
			charge_bar_bg.visible = true
			charge_bar.visible = true
			charge_bar.size.x = 120.0 * pct
			if pct >= 1.0:
				charge_bar.color = Color(1.0, 0.3, 0.1, 0.9)
			else:
				charge_bar.color = Color(1.0, 0.7, 0.2, 0.9)
		else:
			charge_bar_bg.visible = false
			charge_bar.visible = false

func show_death_screen(stats_text: String) -> void:
	if death_panel:
		death_panel.visible = true
		death_visible = true
		if death_stats_label:
			death_stats_label.text = stats_text

func hide_death_screen() -> void:
	if death_panel:
		death_panel.visible = false
		death_visible = false

func update_bloodlust(stacks: int) -> void:
	if bloodlust_label:
		if stacks > 0:
			bloodlust_label.text = "\U0001F525 Bloodlust x" + str(stacks)
		else:
			bloodlust_label.text = ""

func add_buff(buff_name: String, duration: float, icon: String) -> void:
	active_buffs.append({"name": buff_name, "timer": duration, "icon": icon})

func show_room_name(room_type: String) -> void:
	var name_map := {
		"spawn": "\U0001F3E0 Entrance Hall",
		"normal": "\U0001F6AA Chamber",
		"armory": "\u2694\uFE0F Armory",
		"library": "\U0001F4DA Library",
		"treasury": "\U0001FA99 Treasury",
		"graveyard": "\U0001FAA6 Graveyard",
		"shrine": "\u2728 Shrine",
		"lab": "\u2697\uFE0F Laboratory",
		"prison": "\u26D3\uFE0F Prison",
		"arena": "\U0001F3DF\uFE0F Arena",
		"cathedral": "\u26EA Cathedral",
		"closet": "\U0001F6AA Closet",
	}
	room_label.text = name_map.get(room_type, room_type.capitalize())
	room_label.visible = true
	room_label_timer = 3.0

func update_xp(current_xp: int, xp_needed: int, level: int) -> void:
	level_label.text = "Lv." + str(level)
	if xp_needed > 0:
		xp_bar.size.x = (float(current_xp) / float(xp_needed)) * bar_width

func update_minimap(map_data: Array, player_pos: Vector2, enemies: Array, safespace_pos: Vector2) -> void:
	var img := Image.create(150, 150, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	if map_data.is_empty():
		return
	var map_w: int = map_data[0].size() if map_data[0] is Array and map_data[0].size() > 0 else 80
	var map_h: int = map_data.size()
	var scale_x := 150.0 / map_w
	var scale_y := 150.0 / map_h

	for y in range(map_h):
		for x in range(map_w):
			var px := int(x * scale_x)
			var py := int(y * scale_y)
			if px >= 150 or py >= 150:
				continue
			var tile_val: int = map_data[y][x]
			match tile_val:
				1:
					img.set_pixel(px, py, Color(0.2, 0.2, 0.2, 0.8))
				3:
					img.set_pixel(px, py, Color(0.3, 1.0, 0.5, 0.9))
				4: # Water
					img.set_pixel(px, py, Color(0.1, 0.3, 0.6, 0.8))
				5, 6: # Traps
					img.set_pixel(px, py, Color(0.6, 0.1, 0.1, 0.6))
				8: # Door
					img.set_pixel(px, py, Color(0.5, 0.4, 0.2, 0.8))

	var pp := Vector2(player_pos.x / 64.0 * scale_x, player_pos.y / 64.0 * scale_y)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var px_i := clampi(int(pp.x) + dx, 0, 149)
			var py_i := clampi(int(pp.y) + dy, 0, 149)
			img.set_pixel(px_i, py_i, Color(0.2, 0.5, 1.0))

	for enemy_pos in enemies:
		var ep := Vector2(enemy_pos.x / 64.0 * scale_x, enemy_pos.y / 64.0 * scale_y)
		var epx := clampi(int(ep.x), 0, 149)
		var epy := clampi(int(ep.y), 0, 149)
		img.set_pixel(epx, epy, Color(1.0, 0.2, 0.2))

	if safespace_pos != Vector2.ZERO:
		var sp := Vector2(safespace_pos.x / 64.0 * scale_x, safespace_pos.y / 64.0 * scale_y)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var spx := clampi(int(sp.x) + dx, 0, 149)
				var spy := clampi(int(sp.y) + dy, 0, 149)
				img.set_pixel(spx, spy, Color(0.2, 1.0, 0.4))

	minimap_texture_rect.texture = ImageTexture.create_from_image(img)
