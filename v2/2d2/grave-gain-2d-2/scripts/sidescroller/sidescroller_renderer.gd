extends Node2D

# Renders sidescroller building interiors with platformer-style visuals

const SidescrollerRoom = preload("res://scripts/sidescroller/sidescroller_room.gd")

const TILE_SIZE := 32

var room_data: RefCounted = null
var wall_body: StaticBody2D = null
var platform_bodies: Array[StaticBody2D] = []
var light_nodes: Array[PointLight2D] = []

# Cached color arrays for fast drawing
var tile_colors: Array[Array] = []
var detail_seeds: Array[Array] = []

func set_room(room: RefCounted) -> void:
	if not room:
		return
	room_data = room
	_precalculate_colors()
	_create_collision()
	_create_lights()
	queue_redraw()

func clear_room() -> void:
	if wall_body and is_instance_valid(wall_body):
		wall_body.queue_free()
		wall_body = null
	for body in platform_bodies:
		if is_instance_valid(body):
			body.queue_free()
	platform_bodies.clear()
	for light in light_nodes:
		if is_instance_valid(light):
			light.queue_free()
	light_nodes.clear()
	tile_colors.clear()
	detail_seeds.clear()
	room_data = null
	queue_redraw()

func _precalculate_colors() -> void:
	tile_colors.clear()
	detail_seeds.clear()
	if not room_data:
		return

	for y in range(room_data.height):
		var color_row: Array = []
		var seed_row: Array = []
		for x in range(room_data.width):
			var hash1 := sin(x * 17.31 + y * 9.73) * 43758.5453
			hash1 = hash1 - floorf(hash1)
			seed_row.append(hash1)

			var tile: int = room_data.tiles[y][x]
			match tile:
				SidescrollerRoom.SS_TILE_SOLID:
					var variation := hash1 * 0.03
					var base: Color = room_data.wall_color
					color_row.append(Color(base.r + variation, base.g + variation, base.b + variation))
				SidescrollerRoom.SS_TILE_PLATFORM:
					var base: Color = room_data.accent_color
					color_row.append(Color(base.r + hash1 * 0.02, base.g + hash1 * 0.02, base.b + hash1 * 0.01))
				_:
					color_row.append(room_data.bg_color)

		tile_colors.append(color_row)
		detail_seeds.append(seed_row)

func _create_collision() -> void:
	if not room_data:
		return

	# Solid wall collision
	wall_body = StaticBody2D.new()
	wall_body.collision_layer = 4
	wall_body.collision_mask = 0
	add_child(wall_body)

	for y in range(room_data.height):
		for x in range(room_data.width):
			var tile: int = room_data.tiles[y][x]
			if tile == SidescrollerRoom.SS_TILE_SOLID:
				# Check if it has an air neighbor (only create collision for exposed walls)
				var exposed := false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < room_data.width and ny >= 0 and ny < room_data.height:
							var neighbor: int = room_data.tiles[ny][nx]
							if neighbor != SidescrollerRoom.SS_TILE_SOLID:
								exposed = true
								break
					if exposed:
						break

				if exposed:
					var shape := CollisionShape2D.new()
					var rect := RectangleShape2D.new()
					rect.size = Vector2(TILE_SIZE, TILE_SIZE)
					shape.shape = rect
					shape.position = Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + TILE_SIZE * 0.5)
					wall_body.add_child(shape)

	# Platform collision (one-way platforms)
	for y in range(room_data.height):
		for x in range(room_data.width):
			if room_data.tiles[y][x] == SidescrollerRoom.SS_TILE_PLATFORM:
				var plat_body := StaticBody2D.new()
				plat_body.collision_layer = 4
				plat_body.collision_mask = 0

				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(TILE_SIZE, 4.0)
				shape.shape = rect
				shape.position = Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + 2.0)
				shape.one_way_collision = true
				plat_body.add_child(shape)
				add_child(plat_body)
				platform_bodies.append(plat_body)

func _create_lights() -> void:
	if not room_data:
		return

	for torch_pos in room_data.torch_positions:
		var light := PointLight2D.new()
		light.texture = GameData.point_light_texture
		light.texture_scale = 2.5 + randf_range(-0.2, 0.2)
		light.energy = 0.7 + randf_range(-0.1, 0.1)
		light.color = Color(1.0, 0.7, 0.35)
		light.shadow_enabled = GameSystems.get_setting("shadows_enabled")
		light.position = torch_pos
		add_child(light)
		light_nodes.append(light)

func _draw() -> void:
	if not room_data or tile_colors.is_empty():
		return

	# Culling based on viewport
	var canvas_transform := get_canvas_transform()
	var viewport_size := get_viewport_rect().size
	var inv_transform := canvas_transform.affine_inverse()
	var top_left := inv_transform * Vector2.ZERO
	var bottom_right := inv_transform * viewport_size

	var margin := TILE_SIZE * 2.0
	var start_x := maxi(0, int((top_left.x - margin) / float(TILE_SIZE)))
	var start_y := maxi(0, int((top_left.y - margin) / float(TILE_SIZE)))
	var end_x := mini(room_data.width, int((bottom_right.x + margin) / float(TILE_SIZE)) + 1)
	var end_y := mini(room_data.height, int((bottom_right.y + margin) / float(TILE_SIZE)) + 1)

	# Draw background first
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var pos := Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var tile: int = room_data.tiles[y][x]

			match tile:
				SidescrollerRoom.SS_TILE_AIR, SidescrollerRoom.SS_TILE_LADDER, SidescrollerRoom.SS_TILE_TORCH, SidescrollerRoom.SS_TILE_DOOR_ENTRY, SidescrollerRoom.SS_TILE_DOOR_EXIT:
					_draw_bg_tile(x, y, pos)
				SidescrollerRoom.SS_TILE_SOLID:
					_draw_solid_tile(x, y, pos)
				SidescrollerRoom.SS_TILE_PLATFORM:
					_draw_bg_tile(x, y, pos)
					_draw_platform_tile(x, y, pos)

	# Draw foreground elements on top
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var pos := Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var tile: int = room_data.tiles[y][x]

			match tile:
				SidescrollerRoom.SS_TILE_LADDER:
					_draw_ladder_tile(x, y, pos)
				SidescrollerRoom.SS_TILE_TORCH:
					_draw_torch_tile(x, y, pos)
				SidescrollerRoom.SS_TILE_DOOR_ENTRY:
					_draw_door_tile(x, y, pos, Color(0.3, 0.6, 0.3))
				SidescrollerRoom.SS_TILE_DOOR_EXIT:
					_draw_door_tile(x, y, pos, Color(0.6, 0.3, 0.3))

func _draw_bg_tile(_x: int, _y: int, pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), room_data.bg_color)
	# Subtle grid lines
	draw_rect(Rect2(pos.x, pos.y, TILE_SIZE, 1), Color(1, 1, 1, 0.02))
	draw_rect(Rect2(pos.x, pos.y, 1, TILE_SIZE), Color(1, 1, 1, 0.02))

func _draw_solid_tile(x: int, y: int, pos: Vector2) -> void:
	var col: Color = tile_colors[y][x]
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), col)

	var detail: int = detail_seeds[y][x]

	# Check for exposed edges and draw highlights/shadows
	if y > 0 and room_data.tiles[y - 1][x] != SidescrollerRoom.SS_TILE_SOLID:
		# Top edge highlight
		draw_rect(Rect2(pos.x, pos.y, TILE_SIZE, 2), Color(1, 1, 1, 0.08))
	if y < room_data.height - 1 and room_data.tiles[y + 1][x] != SidescrollerRoom.SS_TILE_SOLID:
		# Bottom edge shadow
		draw_rect(Rect2(pos.x, pos.y + TILE_SIZE - 2, TILE_SIZE, 2), Color(0, 0, 0, 0.15))
	if x > 0 and room_data.tiles[y][x - 1] != SidescrollerRoom.SS_TILE_SOLID:
		# Left edge
		draw_rect(Rect2(pos.x, pos.y, 2, TILE_SIZE), Color(1, 1, 1, 0.05))
	if x < room_data.width - 1 and room_data.tiles[y][x + 1] != SidescrollerRoom.SS_TILE_SOLID:
		# Right edge shadow
		draw_rect(Rect2(pos.x + TILE_SIZE - 2, pos.y, 2, TILE_SIZE), Color(0, 0, 0, 0.08))

	# Brick pattern for fortress/castle
	if room_data.building_type == SidescrollerRoom.BuildingType.FORTRESS or room_data.building_type == SidescrollerRoom.BuildingType.CASTLE:
		var brick_h := 16
		var row_idx := y % 2
		var mortar := Color(0, 0, 0, 0.15)
		draw_rect(Rect2(pos.x, pos.y + brick_h, TILE_SIZE, 1), mortar)
		var x_off := 0.0 if row_idx == 0 else TILE_SIZE * 0.5
		draw_rect(Rect2(pos.x + x_off, pos.y, 1, TILE_SIZE), mortar)

	# Surface noise for caves
	if room_data.building_type == SidescrollerRoom.BuildingType.CAVE:
		if detail > 0.5:
			draw_rect(Rect2(pos.x + detail * 10.0, pos.y + detail * 8.0, 6, 4), Color(0, 0, 0, 0.06))
		if detail > 0.7:
			draw_rect(Rect2(pos.x + 2.0, pos.y + detail * 12.0, 4, 3), Color(1, 1, 1, 0.03))

func _draw_platform_tile(_x: int, _y: int, pos: Vector2) -> void:
	# Main platform surface (thin)
	var plat_color: Color = room_data.accent_color
	draw_rect(Rect2(pos.x, pos.y, TILE_SIZE, 6), plat_color)
	# Top highlight
	draw_rect(Rect2(pos.x, pos.y, TILE_SIZE, 1), Color(1, 1, 1, 0.12))
	# Bottom shadow
	draw_rect(Rect2(pos.x, pos.y + 5, TILE_SIZE, 1), Color(0, 0, 0, 0.2))
	# Support brackets underneath
	draw_rect(Rect2(pos.x + 4, pos.y + 6, 3, 8), Color(plat_color.r * 0.7, plat_color.g * 0.7, plat_color.b * 0.7, 0.6))
	draw_rect(Rect2(pos.x + TILE_SIZE - 7, pos.y + 6, 3, 8), Color(plat_color.r * 0.7, plat_color.g * 0.7, plat_color.b * 0.7, 0.6))

func _draw_ladder_tile(_x: int, _y: int, pos: Vector2) -> void:
	var ladder_color := Color(0.45, 0.3, 0.15, 0.9)
	# Side rails
	draw_rect(Rect2(pos.x + 8, pos.y, 3, TILE_SIZE), ladder_color)
	draw_rect(Rect2(pos.x + TILE_SIZE - 11, pos.y, 3, TILE_SIZE), ladder_color)
	# Rungs
	for i in range(4):
		var ry := pos.y + 4.0 + i * 8.0
		draw_rect(Rect2(pos.x + 10, ry, TILE_SIZE - 20, 2), ladder_color)

func _draw_torch_tile(_x: int, _y: int, pos: Vector2) -> void:
	# Torch holder
	var holder_color := Color(0.4, 0.3, 0.2)
	draw_rect(Rect2(pos.x + 13, pos.y + 12, 6, 14), holder_color)
	# Flame glow
	var t := fmod(Time.get_ticks_msec() / 200.0, TAU)
	var flicker := (sin(t) + 1.0) * 0.5
	var flame_color := Color(1.0, 0.6 + flicker * 0.2, 0.2, 0.8 + flicker * 0.2)
	draw_rect(Rect2(pos.x + 11, pos.y + 4, 10, 10), flame_color)
	# Outer glow
	draw_rect(Rect2(pos.x + 8, pos.y + 2, 16, 14), Color(1.0, 0.5, 0.1, 0.15 + flicker * 0.1))

func _draw_door_tile(_x: int, _y: int, pos: Vector2, tint: Color) -> void:
	# Door frame
	var frame := Color(0.35, 0.25, 0.15)
	draw_rect(Rect2(pos.x + 4, pos.y, 24, TILE_SIZE), frame)
	# Door panel
	draw_rect(Rect2(pos.x + 6, pos.y + 2, 20, TILE_SIZE - 4), tint)
	# Door knob
	draw_rect(Rect2(pos.x + 22, pos.y + 16, 3, 3), Color(0.8, 0.7, 0.3))
	# Arch top
	draw_rect(Rect2(pos.x + 4, pos.y, 24, 3), Color(frame.r * 1.2, frame.g * 1.2, frame.b * 1.2))

func update_torch_flicker(_delta: float) -> void:
	# Called from game.gd to animate torches
	queue_redraw()
