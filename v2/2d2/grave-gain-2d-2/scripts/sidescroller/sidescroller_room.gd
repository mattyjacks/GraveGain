extends RefCounted

# Sidescroller interior room generator
# Generates platformer-style layouts for building interiors

enum BuildingType { HOUSE, CAVE, FORTRESS, CASTLE }

const TILE_SIZE := 32
const SS_TILE_AIR := 0
const SS_TILE_SOLID := 1
const SS_TILE_PLATFORM := 2
const SS_TILE_LADDER := 3
const SS_TILE_SPIKE := 4
const SS_TILE_DOOR_ENTRY := 5
const SS_TILE_DOOR_EXIT := 6
const SS_TILE_CHEST := 7
const SS_TILE_TORCH := 8
const SS_TILE_BACKGROUND := 9

var building_type: BuildingType = BuildingType.HOUSE
var width: int = 30
var height: int = 20
var tiles: Array[Array] = []
var bg_tiles: Array[Array] = []
var enemy_spawns: Array[Vector2] = []
var item_spawns: Array[Vector2] = []
var torch_positions: Array[Vector2] = []
var entry_pos: Vector2 = Vector2.ZERO
var exit_pos: Vector2 = Vector2.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Building-specific theming
var wall_color: Color = Color(0.15, 0.13, 0.12)
var floor_color: Color = Color(0.2, 0.18, 0.15)
var bg_color: Color = Color(0.08, 0.07, 0.06)
var accent_color: Color = Color(0.3, 0.25, 0.2)
var building_emoji: String = "\U0001F3E0"
var building_name: String = "House"

# Layout config per building type
const BUILDING_CONFIGS: Dictionary = {
	BuildingType.HOUSE: {
		"name": "House",
		"emoji": "\U0001F3E0",
		"width_range": [20, 30],
		"height_range": [12, 16],
		"floors": [1, 2],
		"platform_density": 0.2,
		"enemy_count": [2, 5],
		"item_count": [1, 3],
		"wall_color": Color(0.2, 0.17, 0.14),
		"floor_color": Color(0.25, 0.2, 0.15),
		"bg_color": Color(0.1, 0.08, 0.07),
		"accent_color": Color(0.35, 0.28, 0.2),
	},
	BuildingType.CAVE: {
		"name": "Cave",
		"emoji": "\U0001F5FB",
		"width_range": [30, 50],
		"height_range": [15, 25],
		"floors": [1, 3],
		"platform_density": 0.35,
		"enemy_count": [4, 8],
		"item_count": [2, 5],
		"wall_color": Color(0.12, 0.11, 0.1),
		"floor_color": Color(0.15, 0.13, 0.12),
		"bg_color": Color(0.05, 0.04, 0.04),
		"accent_color": Color(0.18, 0.16, 0.14),
	},
	BuildingType.FORTRESS: {
		"name": "Fortress",
		"emoji": "\U0001F3F0",
		"width_range": [35, 50],
		"height_range": [18, 25],
		"floors": [2, 4],
		"platform_density": 0.25,
		"enemy_count": [6, 12],
		"item_count": [3, 6],
		"wall_color": Color(0.18, 0.16, 0.15),
		"floor_color": Color(0.22, 0.2, 0.18),
		"bg_color": Color(0.08, 0.07, 0.07),
		"accent_color": Color(0.3, 0.25, 0.22),
	},
	BuildingType.CASTLE: {
		"name": "Castle",
		"emoji": "\U0001F3F0",
		"width_range": [40, 60],
		"height_range": [20, 30],
		"floors": [3, 5],
		"platform_density": 0.3,
		"enemy_count": [8, 16],
		"item_count": [4, 8],
		"wall_color": Color(0.2, 0.18, 0.17),
		"floor_color": Color(0.25, 0.22, 0.2),
		"bg_color": Color(0.06, 0.05, 0.06),
		"accent_color": Color(0.35, 0.3, 0.28),
	},
}

func generate(type: BuildingType, seed_val: int = -1) -> void:
	building_type = type
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	var config: Dictionary = BUILDING_CONFIGS[type]
	building_name = config["name"]
	building_emoji = config["emoji"]
	wall_color = config["wall_color"]
	floor_color = config["floor_color"]
	bg_color = config["bg_color"]
	accent_color = config["accent_color"]

	width = rng.randi_range(config["width_range"][0], config["width_range"][1])
	height = rng.randi_range(config["height_range"][0], config["height_range"][1])
	var num_floors: int = rng.randi_range(config["floors"][0], config["floors"][1])

	_init_tiles()
	_carve_interior()
	_place_floors(num_floors)
	_place_platforms(config["platform_density"])
	_place_ladders()
	_place_entry_exit()
	_place_torches()
	_place_enemies(rng.randi_range(config["enemy_count"][0], config["enemy_count"][1]))
	_place_items(rng.randi_range(config["item_count"][0], config["item_count"][1]))

	if type == BuildingType.CAVE:
		_roughen_walls()

func _init_tiles() -> void:
	tiles.clear()
	bg_tiles.clear()
	for y in range(height):
		var row: Array = []
		var bg_row: Array = []
		for x in range(width):
			row.append(SS_TILE_SOLID)
			bg_row.append(SS_TILE_BACKGROUND)
		tiles.append(row)
		bg_tiles.append(bg_row)

func _carve_interior() -> void:
	# Carve the main interior space (leave 2-tile border for walls)
	for y in range(2, height - 2):
		for x in range(2, width - 2):
			tiles[y][x] = SS_TILE_AIR

func _place_floors(num_floors: int) -> void:
	if num_floors <= 0:
		return
	var floor_spacing: int = maxi(int(float(height - 4) / float(num_floors + 1)), 3)

	for f in range(num_floors):
		var floor_y: int = height - 2 - (f + 1) * floor_spacing
		if floor_y < 3:
			continue

		# Each floor is a solid row with gaps for access
		var gap_count: int = rng.randi_range(1, 3)
		var gap_positions: Array[int] = []
		for _g in range(gap_count):
			gap_positions.append(rng.randi_range(4, width - 5))

		for x in range(2, width - 2):
			var is_gap := false
			for gp in gap_positions:
				if absi(x - gp) <= 1:
					is_gap = true
					break
			if not is_gap:
				tiles[floor_y][x] = SS_TILE_SOLID

func _place_platforms(density: float) -> void:
	# Scatter floating platforms in air spaces
	var attempts := int(width * height * density * 0.1)
	for _i in range(attempts):
		var px: int = rng.randi_range(4, width - 5)
		var py: int = rng.randi_range(3, height - 4)

		# Only place in air with solid below within 3-6 tiles
		if tiles[py][px] != SS_TILE_AIR:
			continue

		var has_floor_below := false
		for check_y in range(py + 1, mini(py + 7, height)):
			if tiles[check_y][px] == SS_TILE_SOLID:
				has_floor_below = true
				break
		if not has_floor_below:
			continue

		# Place a 3-5 tile wide platform
		var plat_width: int = rng.randi_range(3, 5)
		var can_place := true
		for dx in range(plat_width):
			var check_x: int = px + dx
			if check_x >= width - 2:
				can_place = false
				break
			if tiles[py][check_x] != SS_TILE_AIR:
				can_place = false
				break

		if can_place:
			for dx in range(plat_width):
				tiles[py][px + dx] = SS_TILE_PLATFORM

func _place_ladders() -> void:
	# Place ladders near floor gaps for vertical movement
	for y in range(3, height - 3):
		for x in range(3, width - 3):
			if tiles[y][x] == SS_TILE_SOLID and tiles[y - 1][x] == SS_TILE_AIR:
				# Check if there's a gap nearby
				var has_gap := false
				for dx in range(-2, 3):
					var cx: int = x + dx
					if cx >= 0 and cx < width and tiles[y][cx] == SS_TILE_AIR:
						has_gap = true
						break

				if has_gap and rng.randf() < 0.15:
					# Place ladder going up
					var ladder_height: int = rng.randi_range(3, 6)
					for ly in range(ladder_height):
						var ly_pos: int = y - 1 - ly
						if ly_pos >= 2 and tiles[ly_pos][x] == SS_TILE_AIR:
							tiles[ly_pos][x] = SS_TILE_LADDER

func _place_entry_exit() -> void:
	# Entry door at bottom-left area
	var entry_x := 3
	var entry_y := height - 3
	# Find ground level
	for y in range(height - 3, 1, -1):
		if tiles[y][entry_x] == SS_TILE_SOLID and tiles[y - 1][entry_x] == SS_TILE_AIR:
			entry_y = y - 1
			break
	tiles[entry_y][entry_x] = SS_TILE_DOOR_ENTRY
	entry_pos = Vector2(entry_x * TILE_SIZE + TILE_SIZE * 0.5, entry_y * TILE_SIZE + TILE_SIZE * 0.5)

	# Exit door at top-right area or far right
	var exit_x: int = width - 4
	var exit_y: int = 3
	for y in range(3, height - 2):
		if tiles[y][exit_x] == SS_TILE_SOLID and tiles[y - 1][exit_x] == SS_TILE_AIR:
			exit_y = y - 1
			break
	tiles[exit_y][exit_x] = SS_TILE_DOOR_EXIT
	exit_pos = Vector2(exit_x * TILE_SIZE + TILE_SIZE * 0.5, exit_y * TILE_SIZE + TILE_SIZE * 0.5)

func _place_torches() -> void:
	torch_positions.clear()
	for y in range(3, height - 3):
		for x in range(3, width - 3):
			if tiles[y][x] == SS_TILE_AIR:
				# Place torch on walls
				var on_wall := false
				if x > 0 and tiles[y][x - 1] == SS_TILE_SOLID:
					on_wall = true
				elif x < width - 1 and tiles[y][x + 1] == SS_TILE_SOLID:
					on_wall = true
				if on_wall and rng.randf() < 0.08:
					tiles[y][x] = SS_TILE_TORCH
					torch_positions.append(Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + TILE_SIZE * 0.5))

func _place_enemies(count: int) -> void:
	enemy_spawns.clear()
	var attempts := 0
	while enemy_spawns.size() < count and attempts < count * 10:
		attempts += 1
		var ex: int = rng.randi_range(5, width - 5)
		var ey: int = rng.randi_range(3, height - 4)

		if tiles[ey][ex] != SS_TILE_AIR:
			continue
		# Must have solid ground below
		if ey + 1 >= height or (tiles[ey + 1][ex] != SS_TILE_SOLID and tiles[ey + 1][ex] != SS_TILE_PLATFORM):
			continue
		# Not too close to entry
		var pos := Vector2(ex * TILE_SIZE, ey * TILE_SIZE)
		if pos.distance_to(entry_pos) < 128.0:
			continue

		enemy_spawns.append(pos)

func _place_items(count: int) -> void:
	item_spawns.clear()
	var attempts := 0
	while item_spawns.size() < count and attempts < count * 10:
		attempts += 1
		var ix: int = rng.randi_range(4, width - 4)
		var iy: int = rng.randi_range(3, height - 4)

		if tiles[iy][ix] != SS_TILE_AIR:
			continue
		if iy + 1 >= height or (tiles[iy + 1][ix] != SS_TILE_SOLID and tiles[iy + 1][ix] != SS_TILE_PLATFORM):
			continue

		item_spawns.append(Vector2(ix * TILE_SIZE, iy * TILE_SIZE))

func _roughen_walls() -> void:
	# Make cave walls look organic by randomly eroding edges
	var changes: Array[Vector3i] = []
	for y in range(2, height - 2):
		for x in range(2, width - 2):
			if tiles[y][x] == SS_TILE_SOLID:
				var air_neighbors := 0
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							if tiles[ny][nx] == SS_TILE_AIR:
								air_neighbors += 1
				if air_neighbors >= 3 and rng.randf() < 0.3:
					changes.append(Vector3i(x, y, SS_TILE_AIR))
			elif tiles[y][x] == SS_TILE_AIR:
				var solid_neighbors := 0
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							if tiles[ny][nx] == SS_TILE_SOLID:
								solid_neighbors += 1
				if solid_neighbors >= 5 and rng.randf() < 0.2:
					changes.append(Vector3i(x, y, SS_TILE_SOLID))

	for c in changes:
		tiles[c.y][c.x] = c.z

func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= width or y < 0 or y >= height:
		return SS_TILE_SOLID
	return tiles[y][x]

func is_solid(x: int, y: int) -> bool:
	var t := get_tile(x, y)
	return t == SS_TILE_SOLID

func is_platform(x: int, y: int) -> bool:
	return get_tile(x, y) == SS_TILE_PLATFORM

func is_ladder(x: int, y: int) -> bool:
	return get_tile(x, y) == SS_TILE_LADDER

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / float(TILE_SIZE)), int(world_pos.y / float(TILE_SIZE)))

func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5, tile_pos.y * TILE_SIZE + TILE_SIZE * 0.5)
