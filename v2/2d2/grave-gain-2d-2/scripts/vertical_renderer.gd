extends CanvasLayer

# Vertical Renderer - handles 2.5D rendering of multi-floor dungeons with depth effects

class_name VerticalRenderer

const FLOOR_HEIGHT: float = 256.0
const DEPTH_OFFSET_SCALE: float = 0.15

var vertical_dungeon: VerticalDungeonGenerator = null
var current_floor: int = 0
var visible_floors: Array[int] = []

var floor_layers: Dictionary = {}
var depth_modulates: Dictionary = {}

func _ready() -> void:
	layer = 10
	name = "VerticalRenderer"

func set_dungeon(dungeon: VerticalDungeonGenerator) -> void:
	vertical_dungeon = dungeon
	_initialize_floor_layers()

func _initialize_floor_layers() -> void:
	if not vertical_dungeon:
		return
	
	for floor_num in range(vertical_dungeon.max_floors):
		var floor_layer = CanvasLayer.new()
		floor_layer.layer = 5 + floor_num
		floor_layer.name = "Floor_%d" % floor_num
		add_child(floor_layer)
		floor_layers[floor_num] = floor_layer

func update_visible_floors(current: int, visibility_range: int = 2) -> void:
	current_floor = current
	visible_floors = vertical_dungeon.get_visible_floors(current, visibility_range)
	_update_floor_visibility()

func _update_floor_visibility() -> void:
	for floor_num in range(vertical_dungeon.max_floors):
		var layer = floor_layers.get(floor_num)
		if not layer:
			continue
		
		var is_visible = floor_num in visible_floors
		layer.visible = is_visible
		
		if is_visible:
			var alpha = _get_floor_alpha(floor_num)
			_set_layer_modulate(floor_num, Color(1.0, 1.0, 1.0, alpha))

func _get_floor_alpha(floor_num: int) -> float:
	var diff = abs(floor_num - current_floor)
	match diff:
		0:
			return 1.0
		1:
			return 0.8
		2:
			return 0.5
		_:
			return 0.2

func _set_layer_modulate(floor_num: int, color: Color) -> void:
	depth_modulates[floor_num] = color

func get_render_position(world_pos: Vector2, floor_num: int) -> Vector2:
	var depth_offset = (current_floor - floor_num) * DEPTH_OFFSET_SCALE * FLOOR_HEIGHT
	return world_pos + Vector2(0, depth_offset * 0.25)

func get_render_scale(floor_num: int) -> float:
	var diff = float(current_floor - floor_num)
	return 1.0 - (diff * 0.05)

func get_render_modulate(floor_num: int) -> Color:
	return depth_modulates.get(floor_num, Color.WHITE)

func draw_floor_indicator(floor_num: int, position: Vector2) -> void:
	if not visible_floors.has(floor_num):
		return
	
	var layer = floor_layers.get(floor_num)
	if not layer:
		return
	
	var indicator = Label.new()
	indicator.text = "F%d" % (floor_num + 1)
	indicator.global_position = position
	indicator.modulate = get_render_modulate(floor_num)
	layer.add_child(indicator)

func is_floor_visible(floor_num: int) -> bool:
	return floor_num in visible_floors
