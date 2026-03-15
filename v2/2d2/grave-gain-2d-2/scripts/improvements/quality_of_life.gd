extends Node

# Quality of Life Improvements - tooltips, better UI, animations, audio feedback

class_name QualityOfLifeImprovements

# Tooltip system
var tooltip_enabled: bool = true
var tooltip_delay: float = 0.5
var tooltip_max_width: int = 200

# Audio feedback
var sfx_enabled: bool = true
var ui_click_volume: float = 0.3
var combat_volume: float = 0.5
var ambient_volume: float = 0.2

# Animation settings
var enable_animations: bool = true
var animation_speed: float = 1.0
var screen_shake_enabled: bool = true

# UI improvements
var show_damage_numbers: bool = true
var show_healing_numbers: bool = true
var show_xp_numbers: bool = true
var show_gold_numbers: bool = true
var show_enemy_health_bars: bool = true
var show_player_status_effects: bool = true

# Accessibility
var colorblind_mode: String = "none"
var text_scale: float = 1.0
var ui_opacity: float = 1.0

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://qol_settings.cfg") == OK:
		tooltip_enabled = config.get_value("ui", "tooltips", true)
		sfx_enabled = config.get_value("audio", "sfx", true)
		ui_click_volume = config.get_value("audio", "ui_volume", 0.3)
		combat_volume = config.get_value("audio", "combat_volume", 0.5)
		ambient_volume = config.get_value("audio", "ambient_volume", 0.2)
		enable_animations = config.get_value("graphics", "animations", true)
		animation_speed = config.get_value("graphics", "animation_speed", 1.0)
		screen_shake_enabled = config.get_value("graphics", "screen_shake", true)
		show_damage_numbers = config.get_value("ui", "damage_numbers", true)
		show_healing_numbers = config.get_value("ui", "healing_numbers", true)
		show_xp_numbers = config.get_value("ui", "xp_numbers", true)
		show_gold_numbers = config.get_value("ui", "gold_numbers", true)
		show_enemy_health_bars = config.get_value("ui", "enemy_health", true)
		show_player_status_effects = config.get_value("ui", "status_effects", true)
		colorblind_mode = config.get_value("accessibility", "colorblind", "none")
		text_scale = config.get_value("accessibility", "text_scale", 1.0)
		ui_opacity = config.get_value("accessibility", "ui_opacity", 1.0)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("ui", "tooltips", tooltip_enabled)
	config.set_value("audio", "sfx", sfx_enabled)
	config.set_value("audio", "ui_volume", ui_click_volume)
	config.set_value("audio", "combat_volume", combat_volume)
	config.set_value("audio", "ambient_volume", ambient_volume)
	config.set_value("graphics", "animations", enable_animations)
	config.set_value("graphics", "animation_speed", animation_speed)
	config.set_value("graphics", "screen_shake", screen_shake_enabled)
	config.set_value("ui", "damage_numbers", show_damage_numbers)
	config.set_value("ui", "healing_numbers", show_healing_numbers)
	config.set_value("ui", "xp_numbers", show_xp_numbers)
	config.set_value("ui", "gold_numbers", show_gold_numbers)
	config.set_value("ui", "enemy_health", show_enemy_health_bars)
	config.set_value("ui", "status_effects", show_player_status_effects)
	config.set_value("accessibility", "colorblind", colorblind_mode)
	config.set_value("accessibility", "text_scale", text_scale)
	config.set_value("accessibility", "ui_opacity", ui_opacity)
	config.save("user://qol_settings.cfg")

func play_ui_sound(sound_type: String = "click") -> void:
	if not sfx_enabled:
		return
	
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.bus = "UI"
	audio_player.volume_db = linear2db(ui_click_volume)
	
	match sound_type:
		"click":
			audio_player.pitch_scale = randf_range(0.95, 1.05)
		"success":
			audio_player.pitch_scale = 1.2
		"error":
			audio_player.pitch_scale = 0.8
		"hover":
			audio_player.pitch_scale = 1.1
	
	await get_tree().create_timer(0.1).timeout
	audio_player.queue_free()

func show_tooltip(text: String, position: Vector2) -> void:
	if not tooltip_enabled:
		return
	
	var tooltip = Label.new()
	tooltip.text = text
	tooltip.custom_minimum_size = Vector2(tooltip_max_width, 0)
	tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD
	tooltip.position = position + Vector2(10, 10)
	tooltip.modulate.a = 0.0
	add_child(tooltip)
	
	var tween = create_tween()
	tween.tween_property(tooltip, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(3.0).timeout
	tween = create_tween()
	tween.tween_property(tooltip, "modulate:a", 0.0, 0.2)
	await tween.finished
	tooltip.queue_free()

func create_floating_number(value: float, position: Vector2, color: Color, number_type: String = "damage") -> void:
	if number_type == "damage" and not show_damage_numbers:
		return
	if number_type == "healing" and not show_healing_numbers:
		return
	if number_type == "xp" and not show_xp_numbers:
		return
	if number_type == "gold" and not show_gold_numbers:
		return
	
	var label = Label.new()
	label.text = "%d" % value
	label.add_theme_color_override("font_color", color)
	label.position = position
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", position.y - 50, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.queue_free()

func apply_colorblind_filter(color: Color) -> Color:
	match colorblind_mode:
		"deuteranopia":
			return Color(color.r * 0.625 + color.g * 0.375, color.r * 0.7 + color.g * 0.3, color.b)
		"protanopia":
			return Color(color.r * 0.567 + color.g * 0.433, color.r * 0.558 + color.g * 0.442, color.b)
		"tritanopia":
			return Color(color.r, color.g * 0.95 + color.b * 0.05, color.r * 0.475 + color.b * 0.525)
		_:
			return color

func get_setting(setting_name: String) -> var:
	match setting_name:
		"tooltips": return tooltip_enabled
		"sfx": return sfx_enabled
		"animations": return enable_animations
		"screen_shake": return screen_shake_enabled
		"damage_numbers": return show_damage_numbers
		"colorblind": return colorblind_mode
		_: return null
