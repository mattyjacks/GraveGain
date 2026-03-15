extends Node

# Visual Polish - particle effects, screen effects, animations, and visual feedback

class_name VisualPolish

signal effect_played(effect_name: String)

var particle_effects: Dictionary = {}
var screen_effects_enabled: bool = true
var animation_enabled: bool = true

func _ready() -> void:
	_initialize_effects()

func _initialize_effects() -> void:
	particle_effects = {
		"level_up": {
			"color": Color(1.0, 0.8, 0.0),
			"count": 20,
			"speed": 200.0,
			"lifetime": 1.0,
		},
		"critical_hit": {
			"color": Color(1.0, 0.0, 0.0),
			"count": 15,
			"speed": 300.0,
			"lifetime": 0.8,
		},
		"heal": {
			"color": Color(0.0, 1.0, 0.5),
			"count": 12,
			"speed": 150.0,
			"lifetime": 1.2,
		},
		"buff": {
			"color": Color(0.5, 0.8, 1.0),
			"count": 10,
			"speed": 100.0,
			"lifetime": 1.5,
		},
		"debuff": {
			"color": Color(0.8, 0.2, 0.8),
			"count": 10,
			"speed": 120.0,
			"lifetime": 1.3,
		},
		"gold_pickup": {
			"color": Color(1.0, 0.9, 0.0),
			"count": 8,
			"speed": 180.0,
			"lifetime": 0.9,
		},
	}

func play_particle_effect(effect_name: String, position: Vector2) -> void:
	if not particle_effects.has(effect_name):
		return
	
	var effect_data = particle_effects[effect_name]
	
	for i in range(effect_data["count"]):
		var angle = (i / float(effect_data["count"])) * TAU
		var velocity = Vector2(cos(angle), sin(angle)) * effect_data["speed"]
		
		var particle = await _create_particle(effect_data["color"], position, velocity, effect_data["lifetime"])
		add_child(particle)
	
	effect_played.emit(effect_name)

func _create_particle(color: Color, position: Vector2, velocity: Vector2, lifetime: float) -> Node2D:
	var particle = Node2D.new()
	particle.position = position
	
	var label = Label.new()
	label.text = "✨"
	label.add_theme_color_override("font_color", color)
	particle.add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "position", position + velocity * lifetime, lifetime)
	tween.tween_property(particle, "modulate:a", 0.0, lifetime)
	
	await tween.finished
	particle.queue_free()
	
	return particle

func apply_screen_flash(color: Color, duration: float = 0.2) -> void:
	if not screen_effects_enabled:
		return
	
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 999
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	await tween.finished
	flash.queue_free()

func apply_screen_shake(intensity: float, duration: float) -> void:
	if not screen_effects_enabled:
		return
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_pos = camera.global_position
	var elapsed = 0.0
	
	while elapsed < duration:
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		camera.global_position = original_pos + offset
		elapsed += get_physics_process_delta_time()
		await get_tree().process_frame
	
	camera.global_position = original_pos

func apply_chromatic_aberration(intensity: float, duration: float) -> void:
	if not screen_effects_enabled:
		return
	
	var canvas = get_canvas_layer()
	if not canvas:
		return
	
	var tween = create_tween()
	tween.tween_property(canvas, "offset", Vector2(intensity, 0), duration * 0.5)
	tween.tween_property(canvas, "offset", Vector2(0, 0), duration * 0.5)

func create_damage_indicator(position: Vector2, direction: float) -> void:
	var indicator = Node2D.new()
	indicator.position = position
	add_child(indicator)
	
	var arrow = Label.new()
	arrow.text = "→"
	arrow.rotation = direction
	indicator.add_child(arrow)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(indicator, "position:y", position.y - 40, 0.5)
	tween.tween_property(indicator, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	indicator.queue_free()

func create_combo_indicator(combo_count: int, position: Vector2) -> void:
	var combo_label = Label.new()
	combo_label.text = "COMBO x%d!" % combo_count
	combo_label.position = position
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	add_child(combo_label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(combo_label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	combo_label.queue_free()

func create_status_effect_indicator(effect_name: String, position: Vector2, duration: float) -> void:
	var indicator = Control.new()
	indicator.position = position
	add_child(indicator)
	
	var label = Label.new()
	label.text = effect_name
	label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.8))
	indicator.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(indicator, "position:y", position.y - 30, duration)
	tween.tween_property(indicator, "modulate:a", 0.0, duration)
	
	await tween.finished
	indicator.queue_free()

func get_canvas_layer() -> CanvasLayer:
	var layers = get_tree().get_nodes_in_group("canvas_layers")
	if layers.size() > 0:
		return layers[0]
	return null

func pulse_element(element: Node, scale_amount: float = 1.2, duration: float = 0.2) -> void:
	if not animation_enabled:
		return
	
	var original_scale = element.scale
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(element, "scale", original_scale * scale_amount, duration * 0.5)
	tween.tween_property(element, "scale", original_scale, duration * 0.5)

func bounce_element(element: Node, distance: float = 20.0, duration: float = 0.3) -> void:
	if not animation_enabled:
		return
	
	var original_pos = element.position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(element, "position:y", original_pos.y - distance, duration * 0.5)
	tween.tween_property(element, "position:y", original_pos.y, duration * 0.5)

func fade_in(element: Node, duration: float = 0.3) -> void:
	if not animation_enabled:
		return
	
	element.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(element, "modulate:a", 1.0, duration)

func fade_out(element: Node, duration: float = 0.3) -> void:
	if not animation_enabled:
		return
	
	var tween = create_tween()
	tween.tween_property(element, "modulate:a", 0.0, duration)
	await tween.finished
	element.queue_free()
