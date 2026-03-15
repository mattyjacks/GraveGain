extends Node2D

const MapGenerator = preload("res://scripts/map_generator.gd")

const TILE_SIZE := 64
const WALL_HEIGHT := 16.0

var map_data: RefCounted = null
var tiles: Array[Array] = []
var map_width: int = 80
var map_height: int = 80

var floor_colors: Array[Array] = []
var wall_colors: Array[Array] = []
var ao_mask: Array[Array] = []  # Ambient occlusion near walls
var floor_detail: Array[Array] = []  # Per-tile detail seed

var cached_viewport_rect: Rect2 = Rect2()
var needs_full_redraw: bool = true

var wall_body: StaticBody2D = null

func set_map_data(gen: RefCounted) -> void:
	if not gen:
		return
	map_data = gen
	tiles = gen.tiles
	map_width = gen.MAP_WIDTH
	map_height = gen.MAP_HEIGHT
	if tiles.is_empty():
		return
	_precalculate_colors()
	_create_wall_collision()
	queue_redraw()

func _precalculate_colors() -> void:
	floor_colors.clear()
	wall_colors.clear()
	ao_mask.clear()
	floor_detail.clear()

	# Precompute per-tile data
	for y in range(map_height):
		var floor_row: Array = []
		var wall_row: Array = []
		var ao_row: Array = []
		var detail_row: Array = []
		for x in range(map_width):
			# Stone floor with color variation (warm dungeon tones)
			var hash1 := sin(x * 13.37 + y * 7.77) * 43758.5453
			hash1 = hash1 - floorf(hash1)
			var hash2 := sin(x * 3.71 + y * 11.13 + 5.3) * 43758.5453
			hash2 = hash2 - floorf(hash2)

			var fbase := 0.115 + hash1 * 0.025
			# Slight warm/cool variation per stone
			var warm := hash2 * 0.015 - 0.005
			floor_row.append(Color(fbase + warm, fbase * 0.92 + warm * 0.5, fbase * 0.82))

			# Wall with brick-like variation
			var wbase := 0.175 + hash1 * 0.02
			var wshift := hash2 * 0.01
			wall_row.append(Color(wbase + wshift, wbase * 0.88, wbase * 0.82))

			# Ambient occlusion: count adjacent walls
			var wall_count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or nx >= map_width or ny < 0 or ny >= map_height:
						wall_count += 1
					elif tiles[ny][nx] == 2 or tiles[ny][nx] == 0 or tiles[ny][nx] == 7:
						wall_count += 1
			ao_row.append(wall_count)

			# Detail seed for per-tile decoration
			detail_row.append(hash1)

		floor_colors.append(floor_row)
		wall_colors.append(wall_row)
		ao_mask.append(ao_row)
		floor_detail.append(detail_row)

func _create_wall_collision() -> void:
	wall_body = StaticBody2D.new()
	wall_body.collision_layer = 4
	wall_body.collision_mask = 0

	for y in range(map_height):
		for x in range(map_width):
			var tile_val: int = tiles[y][x]
			if tile_val == 2 or tile_val == 7:
				var has_floor_neighbor := false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
							if tiles[ny][nx] != 2 and tiles[ny][nx] != 0 and tiles[ny][nx] != 7:
								has_floor_neighbor = true
								break
					if has_floor_neighbor:
						break

				if has_floor_neighbor:
					var shape := CollisionShape2D.new()
					var rect := RectangleShape2D.new()
					rect.size = Vector2(TILE_SIZE, TILE_SIZE)
					shape.shape = rect
					shape.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0)
					wall_body.add_child(shape)

	add_child(wall_body)

	_create_light_occluders()

func _create_light_occluders() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile_occ: int = tiles[y][x]
			if tile_occ == 2 or tile_occ == 7:
				var has_floor_neighbor := false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
							if tiles[ny][nx] != 2 and tiles[ny][nx] != 0 and tiles[ny][nx] != 7:
								has_floor_neighbor = true
								break
					if has_floor_neighbor:
						break

				if has_floor_neighbor:
					var occluder := LightOccluder2D.new()
					var poly := OccluderPolygon2D.new()
					var px := x * TILE_SIZE
					var py := y * TILE_SIZE
					poly.polygon = PackedVector2Array([
						Vector2(px, py),
						Vector2(px + TILE_SIZE, py),
						Vector2(px + TILE_SIZE, py + TILE_SIZE),
						Vector2(px, py + TILE_SIZE),
					])
					occluder.occluder = poly
					add_child(occluder)

func _draw() -> void:
	if tiles.is_empty():
		return

	var canvas_transform := get_canvas_transform()
	var viewport_size := get_viewport_rect().size
	var inv_transform := canvas_transform.affine_inverse()

	var top_left := inv_transform * Vector2.ZERO
	var bottom_right := inv_transform * viewport_size

	var margin := TILE_SIZE * 2
	var start_x := maxi(0, int((top_left.x - margin) / TILE_SIZE))
	var start_y := maxi(0, int((top_left.y - margin) / TILE_SIZE))
	var end_x := mini(map_width, int((bottom_right.x + margin) / TILE_SIZE) + 1)
	var end_y := mini(map_height, int((bottom_right.y + margin) / TILE_SIZE) + 1)

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tile: int = tiles[y][x]
			var pos := Vector2(x * TILE_SIZE, y * TILE_SIZE)

			match tile:
				1:
					_draw_floor_tile(x, y, pos)
				2:
					_draw_wall_tile(x, y, pos)
				3:
					_draw_safespace_tile(x, y, pos)
				4:
					_draw_water_tile(x, y, pos)
				5:
					_draw_spike_trap_tile(x, y, pos)
				6:
					_draw_poison_trap_tile(x, y, pos)
				7:
					_draw_secret_wall_tile(x, y, pos)
				8:
					_draw_door_tile(x, y, pos)
				9:
					_draw_building_entry_tile(x, y, pos)

# ===== Enhanced Tile Drawing Functions =====

func _draw_floor_tile(x: int, y: int, pos: Vector2) -> void:
	var base_color: Color = floor_colors[y][x]
	var detail: float = floor_detail[y][x]
	var ao: int = ao_mask[y][x]

	# Base stone floor
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), base_color)

	# Stone tile grid lines (subtle mortar)
	var mortar := Color(0.07, 0.065, 0.06, 0.4)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, 1)), mortar)
	draw_rect(Rect2(pos, Vector2(1, TILE_SIZE)), mortar)

	# Subtle stone highlight on top-left edge
	draw_rect(Rect2(pos.x + 1, pos.y + 1, TILE_SIZE - 2, 1), Color(1, 1, 1, 0.03))
	draw_rect(Rect2(pos.x + 1, pos.y + 1, 1, TILE_SIZE - 2), Color(1, 1, 1, 0.02))

	# Per-tile detail: occasional stone cracks or pebble marks
	if detail > 0.75:
		var cx := pos.x + 8 + detail * 40
		var cy := pos.y + 12 + (1.0 - detail) * 30
		draw_rect(Rect2(cx, cy, int(detail * 12) + 3, 1), Color(0.06, 0.055, 0.05, 0.35))
	elif detail < 0.15:
		# Small pebble/debris mark
		var px := pos.x + 20 + detail * 200
		var py := pos.y + 16 + detail * 180
		draw_rect(Rect2(px, py, 2, 2), Color(0.09, 0.085, 0.08, 0.3))

	# Ambient occlusion from nearby walls - darkens floor near walls
	if ao > 0:
		var ao_strength := minf(ao * 0.02, 0.12)
		draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color(0, 0, 0, ao_strength))

		# Directional AO edges (darken the side facing a wall)
		if y > 0 and x < map_width and (tiles[y - 1][x] == 2 or tiles[y - 1][x] == 0 or tiles[y - 1][x] == 7):
			draw_rect(Rect2(pos, Vector2(TILE_SIZE, 6)), Color(0, 0, 0, 0.08))
			draw_rect(Rect2(pos, Vector2(TILE_SIZE, 3)), Color(0, 0, 0, 0.05))
		if y + 1 < map_height and (tiles[y + 1][x] == 2 or tiles[y + 1][x] == 0):
			draw_rect(Rect2(pos.x, pos.y + TILE_SIZE - 6, TILE_SIZE, 6), Color(0, 0, 0, 0.06))
		if x > 0 and (tiles[y][x - 1] == 2 or tiles[y][x - 1] == 0 or tiles[y][x - 1] == 7):
			draw_rect(Rect2(pos, Vector2(6, TILE_SIZE)), Color(0, 0, 0, 0.07))
			draw_rect(Rect2(pos, Vector2(3, TILE_SIZE)), Color(0, 0, 0, 0.04))
		if x + 1 < map_width and (tiles[y][x + 1] == 2 or tiles[y][x + 1] == 0):
			draw_rect(Rect2(pos.x + TILE_SIZE - 6, pos.y, 6, TILE_SIZE), Color(0, 0, 0, 0.06))

func _draw_wall_tile(x: int, y: int, pos: Vector2) -> void:
	var wc: Color = wall_colors[y][x]
	var detail: float = floor_detail[y][x]

	# Base wall
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), wc)

	# Brick pattern: horizontal mortar lines
	var mortar_color := Color(0.10, 0.09, 0.08, 0.5)
	var brick_h := 16  # brick height
	for row_i in range(4):
		var my := pos.y + row_i * brick_h
		draw_rect(Rect2(pos.x, my, TILE_SIZE, 1), mortar_color)
		# Vertical mortar offset per row (staggered bricks)
		var x_off := 0.0 if (row_i + y) % 2 == 0 else TILE_SIZE / 2.0
		for col_i in range(3):
			var mx := pos.x + x_off + col_i * float(TILE_SIZE)
			if mx >= pos.x and mx < pos.x + TILE_SIZE:
				draw_rect(Rect2(mx, my, 1, brick_h), mortar_color)

	# Top highlight edge
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, 2)), Color(0.25, 0.22, 0.20, 0.7))

	# Subtle surface variation
	if detail > 0.6:
		draw_rect(Rect2(pos.x + 4, pos.y + 8, 8, 6), Color(0, 0, 0, 0.04))

	# South wall face (3D depth effect)
	if y + 1 < map_height and tiles[y + 1][x] != 2 and tiles[y + 1][x] != 0 and tiles[y + 1][x] != 7:
		# Gradient from dark to very dark on the wall face
		for i in range(int(WALL_HEIGHT)):
			var t := float(i) / float(WALL_HEIGHT)
			var shade := 0.08 - t * 0.04
			draw_rect(Rect2(pos.x, pos.y + TILE_SIZE + i, TILE_SIZE, 1), Color(shade, shade * 0.9, shade * 0.85))
		# Top edge highlight of the face
		draw_rect(Rect2(pos.x, pos.y + TILE_SIZE, TILE_SIZE, 1), Color(0.14, 0.12, 0.10))
		# Bottom shadow at base of wall face
		draw_rect(Rect2(pos.x, pos.y + TILE_SIZE + WALL_HEIGHT - 1, TILE_SIZE, 2), Color(0, 0, 0, 0.15))

func _draw_safespace_tile(_x: int, _y: int, pos: Vector2) -> void:
	var t := fmod(Time.get_ticks_msec() / 1000.0, TAU)
	var pulse := (sin(t) + 1.0) * 0.5
	var r := 0.13 + pulse * 0.04
	var g := 0.22 + pulse * 0.06
	var b := 0.13 + pulse * 0.03
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color(r, g, b))

	# Glowing border with pulse
	var border_a := 0.5 + pulse * 0.3
	var border_color := Color(0.3, 0.9, 0.5, border_a)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, 2)), border_color)
	draw_rect(Rect2(pos, Vector2(2, TILE_SIZE)), border_color)
	draw_rect(Rect2(pos.x + TILE_SIZE - 2, pos.y, 2, TILE_SIZE), border_color)
	draw_rect(Rect2(pos.x, pos.y + TILE_SIZE - 2, TILE_SIZE, 2), border_color)

	# Inner glow
	var inner := Color(0.2, 0.7, 0.4, 0.08 + pulse * 0.06)
	draw_rect(Rect2(pos.x + 4, pos.y + 4, TILE_SIZE - 8, TILE_SIZE - 8), inner)

	# Center rune mark
	var rune_a := 0.15 + sin(t * 1.5) * 0.1
	draw_rect(Rect2(pos.x + 28, pos.y + 20, 8, 2), Color(0.4, 1.0, 0.6, rune_a))
	draw_rect(Rect2(pos.x + 28, pos.y + 28, 8, 2), Color(0.4, 1.0, 0.6, rune_a))
	draw_rect(Rect2(pos.x + 30, pos.y + 20, 2, 10), Color(0.4, 1.0, 0.6, rune_a * 0.8))

func _draw_water_tile(x: int, y: int, pos: Vector2) -> void:
	var tw := fmod(Time.get_ticks_msec() / 1200.0, TAU)

	# Deep water base with variation
	var depth := sin(x * 0.7 + y * 0.5) * 0.02
	var wr := 0.03 + depth
	var wg := 0.08 + sin(tw * 0.5 + x * 0.3) * 0.015 + depth
	var wb := 0.18 + sin(tw * 0.3 + y * 0.4) * 0.02
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color(wr, wg, wb))

	# Multiple ripple layers
	var ripple1 := sin(tw * 1.8 + x * 1.5 + y * 0.8) * 0.5 + 0.5
	var ripple2 := sin(tw * 1.2 + x * 0.9 + y * 1.3 + 2.0) * 0.5 + 0.5
	var ripple3 := sin(tw * 2.5 + x * 2.0 + y * 0.4 + 4.0) * 0.5 + 0.5

	if ripple1 > 0.65:
		var ra := (ripple1 - 0.65) * 2.0
		draw_rect(Rect2(pos.x + 6, pos.y + 10, 16, 1), Color(0.25, 0.45, 0.7, ra * 0.35))
	if ripple2 > 0.7:
		var ra := (ripple2 - 0.7) * 2.0
		draw_rect(Rect2(pos.x + 28, pos.y + 32, 20, 1), Color(0.3, 0.5, 0.75, ra * 0.3))
	if ripple3 > 0.75:
		var ra := (ripple3 - 0.75) * 2.0
		draw_rect(Rect2(pos.x + 14, pos.y + 48, 10, 1), Color(0.2, 0.4, 0.65, ra * 0.25))

	# Caustic light pattern
	var caustic := sin(tw * 3.0 + x * 2.5 + y * 1.8) * 0.5 + 0.5
	if caustic > 0.8:
		var ca := (caustic - 0.8) * 3.0
		draw_rect(Rect2(pos.x + 20 + sin(tw) * 8, pos.y + 24 + cos(tw * 0.7) * 6, 4, 4), Color(0.3, 0.5, 0.8, ca * 0.15))

func _draw_spike_trap_tile(_x: int, _y: int, pos: Vector2) -> void:
	var base_col: Color = floor_colors[_y][_x] if _y < floor_colors.size() and _x < floor_colors[_y].size() else Color(0.12, 0.11, 0.09)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), base_col)
	var ts := fmod(Time.get_ticks_msec() / 800.0, TAU)
	var spike_phase := sin(ts)
	var spike_a := 0.12 + spike_phase * 0.12

	# Spike plate base
	draw_rect(Rect2(pos.x + 6, pos.y + 6, TILE_SIZE - 12, TILE_SIZE - 12), Color(0.25, 0.08, 0.08, spike_a * 0.7))

	# Individual spike dots
	var spike_height := maxf(spike_phase, 0.0)
	for sy in range(3):
		for sx in range(3):
			var spx := pos.x + 14 + sx * 14
			var spy := pos.y + 14 + sy * 14
			var sp_size := 2.0 + spike_height * 3.0
			draw_rect(Rect2(spx - sp_size * 0.5, spy - sp_size * 0.5, sp_size, sp_size), Color(0.5, 0.15, 0.1, spike_a))

	# Warning border
	if spike_phase > 0.3:
		draw_rect(Rect2(pos.x + 4, pos.y + 4, TILE_SIZE - 8, 1), Color(0.6, 0.15, 0.1, spike_a * 0.5))
		draw_rect(Rect2(pos.x + 4, pos.y + TILE_SIZE - 5, TILE_SIZE - 8, 1), Color(0.6, 0.15, 0.1, spike_a * 0.5))

func _draw_poison_trap_tile(_x: int, _y: int, pos: Vector2) -> void:
	var base_col: Color = floor_colors[_y][_x] if _y < floor_colors.size() and _x < floor_colors[_y].size() else Color(0.12, 0.11, 0.09)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), base_col)
	var tp := fmod(Time.get_ticks_msec() / 900.0, TAU)
	var poison_pulse := (sin(tp) + 1.0) * 0.5

	# Poison pool base
	var pool_a := 0.08 + poison_pulse * 0.1
	draw_rect(Rect2(pos.x + 8, pos.y + 8, TILE_SIZE - 16, TILE_SIZE - 16), Color(0.1, 0.35, 0.08, pool_a))

	# Bubbles
	var bubble1 := sin(tp * 2.0 + 1.0) * 0.5 + 0.5
	var bubble2 := sin(tp * 1.5 + 3.0) * 0.5 + 0.5
	if bubble1 > 0.6:
		var ba := (bubble1 - 0.6) * 2.0
		draw_rect(Rect2(pos.x + 20, pos.y + 18 - ba * 4, 3, 3), Color(0.2, 0.6, 0.15, ba * 0.4))
	if bubble2 > 0.65:
		var ba := (bubble2 - 0.65) * 2.0
		draw_rect(Rect2(pos.x + 38, pos.y + 30 - ba * 3, 2, 2), Color(0.15, 0.5, 0.1, ba * 0.35))

	# Drip stain at edges
	draw_rect(Rect2(pos.x + 10, pos.y + 6, 4, 2), Color(0.12, 0.3, 0.08, 0.15))
	draw_rect(Rect2(pos.x + 42, pos.y + 50, 6, 2), Color(0.12, 0.3, 0.08, 0.12))

func _draw_secret_wall_tile(x: int, y: int, pos: Vector2) -> void:
	# Looks like a normal wall but with subtle crack hints
	_draw_wall_tile(x, y, pos)

	# Subtle vertical crack
	var crack_x := pos.x + TILE_SIZE * 0.5 - 1
	draw_rect(Rect2(crack_x, pos.y + 4, 1, TILE_SIZE - 8), Color(0.07, 0.065, 0.06, 0.35))
	draw_rect(Rect2(crack_x + 1, pos.y + 6, 1, TILE_SIZE - 12), Color(0.09, 0.08, 0.07, 0.2))

	# Tiny light leak at crack
	var t := fmod(Time.get_ticks_msec() / 2000.0, TAU)
	var leak := (sin(t) + 1.0) * 0.5
	draw_rect(Rect2(crack_x - 1, pos.y + TILE_SIZE * 0.5 - 2, 3, 4), Color(0.3, 0.25, 0.15, leak * 0.08))

func _draw_door_tile(_x: int, _y: int, pos: Vector2) -> void:
	# Door frame
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color(0.14, 0.09, 0.04))

	# Door panel
	var panel_rect := Rect2(pos.x + 3, pos.y + 3, TILE_SIZE - 6, TILE_SIZE - 6)
	draw_rect(panel_rect, Color(0.22, 0.15, 0.07))

	# Wood grain lines
	for i in range(5):
		var gy := pos.y + 6 + i * 11
		var grain_a := 0.08 + sin(i * 2.3) * 0.03
		draw_rect(Rect2(pos.x + 5, gy, TILE_SIZE - 10, 1), Color(0.15, 0.10, 0.05, grain_a))

	# Cross planks
	draw_rect(Rect2(pos.x + 4, pos.y + TILE_SIZE / 3, TILE_SIZE - 8, 2), Color(0.28, 0.19, 0.09))
	draw_rect(Rect2(pos.x + 4, pos.y + TILE_SIZE * 2 / 3, TILE_SIZE - 8, 2), Color(0.28, 0.19, 0.09))

	# Door handle
	draw_rect(Rect2(pos.x + TILE_SIZE * 0.65, pos.y + TILE_SIZE * 0.5 - 3, 5, 6), Color(0.5, 0.4, 0.2))
	draw_rect(Rect2(pos.x + TILE_SIZE * 0.65 + 1, pos.y + TILE_SIZE * 0.5 - 2, 3, 4), Color(0.6, 0.5, 0.25))

	# Door hinges
	draw_rect(Rect2(pos.x + 4, pos.y + 10, 3, 6), Color(0.35, 0.3, 0.2))
	draw_rect(Rect2(pos.x + 4, pos.y + TILE_SIZE - 16, 3, 6), Color(0.35, 0.3, 0.2))

func _draw_building_entry_tile(x: int, y: int, pos: Vector2) -> void:
	# Special floor tile marking a building entrance
	var base_color: Color = floor_colors[y][x] if y < floor_colors.size() and x < floor_colors[y].size() else Color(0.12, 0.11, 0.09)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), base_color)

	# Warm inviting glow
	var t := fmod(Time.get_ticks_msec() / 1500.0, TAU)
	var pulse := (sin(t) + 1.0) * 0.5
	var glow_a := 0.06 + pulse * 0.06
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Color(0.4, 0.3, 0.15, glow_a))

	# Decorative border - stone threshold
	var border_color := Color(0.25, 0.2, 0.12, 0.4 + pulse * 0.2)
	draw_rect(Rect2(pos, Vector2(TILE_SIZE, 2)), border_color)
	draw_rect(Rect2(pos, Vector2(2, TILE_SIZE)), border_color)
	draw_rect(Rect2(pos.x + TILE_SIZE - 2, pos.y, 2, TILE_SIZE), border_color)
	draw_rect(Rect2(pos.x, pos.y + TILE_SIZE - 2, TILE_SIZE, 2), border_color)

	# Corner stones
	var corner := Color(0.3, 0.25, 0.15, 0.5)
	draw_rect(Rect2(pos.x, pos.y, 6, 6), corner)
	draw_rect(Rect2(pos.x + TILE_SIZE - 6, pos.y, 6, 6), corner)
	draw_rect(Rect2(pos.x, pos.y + TILE_SIZE - 6, 6, 6), corner)
	draw_rect(Rect2(pos.x + TILE_SIZE - 6, pos.y + TILE_SIZE - 6, 6, 6), corner)

func _process(_delta: float) -> void:
	queue_redraw()
