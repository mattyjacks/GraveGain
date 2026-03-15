extends Node2D

# ===== STARSHIP RENDERER =====
# Renders the starship interior map with sci-fi themed tiles, lighting, and decorations

const StarshipMap = preload("res://scripts/starship/starship_map.gd")

var map_data: RefCounted = null
var wall_bodies: Array[StaticBody2D] = []

const TILE_SIZE: int = 32

# Sci-fi color palette
const FLOOR_COLOR := Color(0.15, 0.17, 0.22)
const FLOOR_ACCENT := Color(0.18, 0.20, 0.28)
const WALL_COLOR := Color(0.25, 0.27, 0.35)
const WALL_HIGHLIGHT := Color(0.35, 0.37, 0.45)
const HULL_COLOR := Color(0.12, 0.12, 0.16)
const GRID_COLOR := Color(0.2, 0.22, 0.3, 0.15)
const DOOR_COLOR := Color(0.3, 0.5, 0.7)

func set_map_data(data: RefCounted) -> void:
	map_data = data
	_build_wall_collisions()
	queue_redraw()

func _draw() -> void:
	if not map_data or not map_data.tiles:
		return
	
	var cam := get_viewport().get_camera_2d()
	if not cam:
		_draw_full_map()
		return
	
	# Culling: only draw visible area
	var vp_size := get_viewport_rect().size
	var cam_pos := cam.global_position
	var cam_zoom := cam.zoom
	var half_w := vp_size.x / (2.0 * cam_zoom.x)
	var half_h := vp_size.y / (2.0 * cam_zoom.y)
	
	var start_x := maxi(0, int((cam_pos.x - half_w) / TILE_SIZE) - 1)
	var start_y := maxi(0, int((cam_pos.y - half_h) / TILE_SIZE) - 1)
	var end_x := mini(map_data.MAP_WIDTH, int((cam_pos.x + half_w) / TILE_SIZE) + 2)
	var end_y := mini(map_data.MAP_HEIGHT, int((cam_pos.y + half_h) / TILE_SIZE) + 2)
	
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tile: int = map_data.tiles[y][x]
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			
			match tile:
				StarshipMap.TILE_FLOOR:
					_draw_floor_tile(x, y, rect)
				StarshipMap.TILE_WALL:
					_draw_wall_tile(x, y, rect)
				StarshipMap.TILE_HULL:
					draw_rect(rect, HULL_COLOR)

func _draw_full_map() -> void:
	if not map_data or not map_data.tiles:
		return
	for y in range(map_data.MAP_HEIGHT):
		for x in range(map_data.MAP_WIDTH):
			var tile: int = map_data.tiles[y][x]
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			match tile:
				StarshipMap.TILE_FLOOR:
					_draw_floor_tile(x, y, rect)
				StarshipMap.TILE_WALL:
					_draw_wall_tile(x, y, rect)
				StarshipMap.TILE_HULL:
					draw_rect(rect, HULL_COLOR)

func _draw_floor_tile(x: int, y: int, rect: Rect2) -> void:
	# Checkerboard pattern for sci-fi floor
	var checker := (x + y) % 2 == 0
	var base_color := FLOOR_COLOR if checker else FLOOR_ACCENT
	
	# Tint by room type
	var room: Dictionary = map_data.get_room_at(Vector2(x * TILE_SIZE + 16, y * TILE_SIZE + 16))
	if not room.is_empty():
		var room_color: Color = room.get("color", Color.GRAY)
		base_color = base_color.lerp(room_color, 0.15)
	
	draw_rect(rect, base_color)
	
	# Grid lines
	draw_line(
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x + TILE_SIZE, rect.position.y),
		GRID_COLOR
	)
	draw_line(
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x, rect.position.y + TILE_SIZE),
		GRID_COLOR
	)
	
	# Occasional floor detail
	var detail_seed := (x * 7 + y * 13) % 17
	if detail_seed == 0:
		# Small circle (rivet/vent)
		var center := Vector2(rect.position.x + TILE_SIZE / 2.0, rect.position.y + TILE_SIZE / 2.0)
		draw_circle(center, 2.0, Color(0.3, 0.32, 0.4, 0.4))
	elif detail_seed == 3:
		# Stripe marking
		draw_rect(Rect2(rect.position.x + 4, rect.position.y + 14, TILE_SIZE - 8, 4), Color(0.35, 0.3, 0.1, 0.2))

func _draw_wall_tile(x: int, y: int, rect: Rect2) -> void:
	draw_rect(rect, WALL_COLOR)
	
	# Check if wall faces a floor tile for highlight edge
	var has_floor_below: bool = y + 1 < map_data.MAP_HEIGHT and map_data.tiles[y + 1][x] == StarshipMap.TILE_FLOOR
	var has_floor_right: bool = x + 1 < map_data.MAP_WIDTH and map_data.tiles[y][x + 1] == StarshipMap.TILE_FLOOR
	
	if has_floor_below:
		draw_rect(Rect2(rect.position.x, rect.position.y + TILE_SIZE - 3, TILE_SIZE, 3), WALL_HIGHLIGHT)
	if has_floor_right:
		draw_rect(Rect2(rect.position.x + TILE_SIZE - 3, rect.position.y, 3, TILE_SIZE), WALL_HIGHLIGHT)
	
	# Wall panel detail
	var panel_seed := (x * 11 + y * 7) % 23
	if panel_seed < 3:
		var inset := Rect2(rect.position.x + 4, rect.position.y + 4, TILE_SIZE - 8, TILE_SIZE - 8)
		draw_rect(inset, Color(0.22, 0.24, 0.32), false, 1.0)
	
	# Occasional blinking light on wall
	if panel_seed == 5:
		var light_pos := Vector2(rect.position.x + TILE_SIZE / 2.0, rect.position.y + TILE_SIZE / 2.0)
		draw_circle(light_pos, 2.0, Color(0.2, 0.8, 0.3, 0.6))

func _build_wall_collisions() -> void:
	# Clear existing
	for body in wall_bodies:
		if is_instance_valid(body):
			body.queue_free()
	wall_bodies.clear()
	
	if not map_data:
		return
	
	# Build collision bodies for wall tiles
	for y in range(map_data.MAP_HEIGHT):
		for x in range(map_data.MAP_WIDTH):
			var tile: int = map_data.tiles[y][x]
			if tile == StarshipMap.TILE_WALL or tile == StarshipMap.TILE_HULL:
				var body := StaticBody2D.new()
				body.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0)
				body.collision_layer = 4  # Wall layer
				body.collision_mask = 0
				
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(TILE_SIZE, TILE_SIZE)
				shape.shape = rect
				body.add_child(shape)
				
				add_child(body)
				wall_bodies.append(body)
	
	# Add light occluders for walls
	_build_light_occluders()

func _build_light_occluders() -> void:
	if not map_data or not map_data.tiles:
		return
	for y in range(map_data.MAP_HEIGHT):
		for x in range(map_data.MAP_WIDTH):
			var tile: int = map_data.tiles[y][x]
			if tile != StarshipMap.TILE_WALL:
				continue
			
			# Only add occluders for walls adjacent to floor
			var adjacent_floor := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and nx < map_data.MAP_WIDTH and ny >= 0 and ny < map_data.MAP_HEIGHT:
						if map_data.tiles[ny][nx] == StarshipMap.TILE_FLOOR:
							adjacent_floor = true
							break
				if adjacent_floor:
					break
			
			if not adjacent_floor:
				continue
			
			var occ := LightOccluder2D.new()
			var poly := OccluderPolygon2D.new()
			var px: float = x * TILE_SIZE
			var py: float = y * TILE_SIZE
			poly.polygon = PackedVector2Array([
				Vector2(px, py),
				Vector2(px + TILE_SIZE, py),
				Vector2(px + TILE_SIZE, py + TILE_SIZE),
				Vector2(px, py + TILE_SIZE),
			])
			occ.occluder = poly
			add_child(occ)
