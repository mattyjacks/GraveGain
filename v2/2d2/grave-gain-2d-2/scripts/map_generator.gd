extends RefCounted

const TILE_EMPTY := 0
const TILE_FLOOR := 1
const TILE_WALL := 2
const TILE_SAFESPACE := 3
const TILE_WATER := 4
const TILE_TRAP_SPIKE := 5
const TILE_TRAP_POISON := 6
const TILE_SECRET_WALL := 7
const TILE_DOOR := 8
const TILE_BUILDING_ENTRY := 9

const TILE_SIZE := 64
const MAP_WIDTH := 80
const MAP_HEIGHT := 80
const MIN_ROOM_SIZE := 6
const MAX_ROOM_SIZE := 14
const NUM_ROOMS := 12
const CORRIDOR_WIDTH := 3
const WALL_HEIGHT := 16.0

var tiles: Array[Array] = []
var rooms: Array[Rect2i] = []
var torch_positions: Array[Vector2] = []
var spawn_position: Vector2 = Vector2.ZERO
var safespace_position: Vector2 = Vector2.ZERO
var enemy_spawn_rooms: Array[Dictionary] = []
var item_positions: Array[Dictionary] = []
var food_positions: Array[Dictionary] = []
var lore_positions: Array[Dictionary] = []

# Improvement #36: Room Types
var room_types: Array[String] = []
# Improvement #37: Destructibles
var destructible_positions: Array[Dictionary] = []
# Improvement #38: Traps
var trap_positions: Array[Dictionary] = []
# Improvement #39: Secret Rooms
var secret_room_indices: Array[int] = []
# Improvement #48: Chests
var chest_positions: Array[Dictionary] = []
# Improvement #44: Ambient Particles
var particle_positions: Array[Dictionary] = []
# Improvement #49: Door positions
var door_positions: Array[Dictionary] = []
# Improvement: Patrol routes for enemies
var patrol_routes: Array[Dictionary] = []
# Improvement: Room discovery tracking
var room_explored: Array[bool] = []
# Sidescroller buildings
var building_positions: Array[Dictionary] = []

# Improvement #76: Fountain room positions (healing zones)
var fountain_positions: Array[Dictionary] = []
# Improvement #77: Altar room positions (buff shrines)
var altar_positions: Array[Dictionary] = []
# Improvement #78: Room decorations (pillars, statues, rugs)
var decoration_positions: Array[Dictionary] = []
# Improvement #79: Corridor ambush spawn points
var corridor_ambush_points: Array[Dictionary] = []
# Improvement #80: Dead-end treasure caches
var dead_end_treasures: Array[Dictionary] = []
# Improvement #81: Environmental hazard zones
var hazard_zones: Array[Dictionary] = []
# Improvement #82: Room difficulty rating by distance
var room_difficulties: Array[float] = []
# Improvement #83: Themed room item placements
var themed_item_positions: Array[Dictionary] = []

var rng := RandomNumberGenerator.new()

func generate(seed_val: int = -1) -> void:
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	_init_tiles()
	_place_rooms()
	_connect_rooms()
	_assign_room_types()
	_place_safespace()
	_place_secret_rooms()
	_calculate_room_difficulties()
	_place_torches()
	_place_items()
	_place_food()
	_place_lore()
	_place_destructibles()
	_place_traps()
	_place_chests()
	_place_doors()
	_place_water()
	_place_particles()
	_place_fountains()
	_place_altars()
	_place_decorations()
	_place_corridor_ambushes()
	_place_dead_end_treasures()
	_place_hazard_zones()
	_place_themed_items()
	_generate_patrol_routes()
	_place_buildings()
	_setup_enemy_spawns()

func _init_tiles() -> void:
	tiles.clear()
	for y in range(MAP_HEIGHT):
		var row: Array = []
		row.resize(MAP_WIDTH)
		row.fill(TILE_WALL)
		tiles.append(row)

func _place_rooms() -> void:
	rooms.clear()
	var attempts := 0
	while rooms.size() < NUM_ROOMS and attempts < 200:
		attempts += 1
		var w := rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var h := rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var x := rng.randi_range(2, MAP_WIDTH - w - 2)
		var y := rng.randi_range(2, MAP_HEIGHT - h - 2)
		var room := Rect2i(x, y, w, h)
		var overlaps := false
		for existing in rooms:
			if room.grow(2).intersects(existing):
				overlaps = true
				break
		if not overlaps:
			rooms.append(room)
			_carve_room(room)

	if rooms.size() > 0:
		var first_room := rooms[0]
		spawn_position = Vector2(
			(first_room.position.x + first_room.size.x / 2.0) * TILE_SIZE,
			(first_room.position.y + first_room.size.y / 2.0) * TILE_SIZE
		)

func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				tiles[y][x] = TILE_FLOOR

func _connect_rooms() -> void:
	if rooms.size() < 2:
		return
	for i in range(rooms.size() - 1):
		var room_a := rooms[i]
		var room_b := rooms[i + 1]
		var center_a := Vector2i(
			room_a.position.x + int(room_a.size.x / 2.0),
			room_a.position.y + int(room_a.size.y / 2.0)
		)
		var center_b := Vector2i(
			room_b.position.x + int(room_b.size.x / 2.0),
			room_b.position.y + int(room_b.size.y / 2.0)
		)
		if rng.randf() > 0.5:
			_carve_h_corridor(center_a.x, center_b.x, center_a.y)
			_carve_v_corridor(center_a.y, center_b.y, center_b.x)
		else:
			_carve_v_corridor(center_a.y, center_b.y, center_a.x)
			_carve_h_corridor(center_a.x, center_b.x, center_b.y)

	if rooms.size() > 2:
		var extra_connections := rng.randi_range(1, 3)
		for _i in range(extra_connections):
			var a := rng.randi_range(0, rooms.size() - 1)
			var b := rng.randi_range(0, rooms.size() - 1)
			if a != b:
				var ca := Vector2i(rooms[a].position.x + int(rooms[a].size.x / 2.0), rooms[a].position.y + int(rooms[a].size.y / 2.0))
				var cb := Vector2i(rooms[b].position.x + int(rooms[b].size.x / 2.0), rooms[b].position.y + int(rooms[b].size.y / 2.0))
				_carve_h_corridor(ca.x, cb.x, ca.y)
				_carve_v_corridor(ca.y, cb.y, cb.x)

func _carve_h_corridor(x1: int, x2: int, y: int) -> void:
	var start_x := mini(x1, x2)
	var end_x := maxi(x1, x2)
	for x in range(start_x, end_x + 1):
		for dy in range(-int(CORRIDOR_WIDTH / 2.0), int(CORRIDOR_WIDTH / 2.0) + 1):
			var ty := y + dy
			if ty >= 0 and ty < MAP_HEIGHT and x >= 0 and x < MAP_WIDTH:
				tiles[ty][x] = TILE_FLOOR

func _carve_v_corridor(y1: int, y2: int, x: int) -> void:
	var start_y := mini(y1, y2)
	var end_y := maxi(y1, y2)
	for y in range(start_y, end_y + 1):
		for dx in range(-int(CORRIDOR_WIDTH / 2.0), int(CORRIDOR_WIDTH / 2.0) + 1):
			var tx := x + dx
			if tx >= 0 and tx < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				tiles[y][tx] = TILE_FLOOR

# Improvement #36: Assign room types based on size and position
func _assign_room_types() -> void:
	room_types.clear()
	room_explored.clear()
	var type_pool := ["normal", "normal", "normal", "armory", "library", "treasury", "graveyard", "shrine", "lab", "prison"]
	for i in range(rooms.size()):
		room_explored.append(false)
		if i == 0:
			room_types.append("spawn")
			continue
		var room := rooms[i]
		var area := room.size.x * room.size.y
		if area > 120:
			var big_types := ["arena", "treasury", "cathedral"]
			room_types.append(big_types.pick_random())
		elif area < 30:
			var small_types := ["closet", "shrine", "prison"]
			room_types.append(small_types.pick_random())
		else:
			room_types.append(type_pool.pick_random())

func get_room_type(index: int) -> String:
	if index >= 0 and index < room_types.size():
		return room_types[index]
	return "normal"

func mark_room_explored(index: int) -> void:
	if index >= 0 and index < room_explored.size():
		room_explored[index] = true
		GameSystems.track("rooms_explored")

func get_room_at_world_pos(world_pos: Vector2) -> int:
	var tp := world_to_tile(world_pos)
	for i in range(rooms.size()):
		var r := rooms[i]
		if tp.x >= r.position.x and tp.x < r.position.x + r.size.x and tp.y >= r.position.y and tp.y < r.position.y + r.size.y:
			return i
	return -1

func _place_safespace() -> void:
	if rooms.size() < 2:
		return
	var farthest_room := rooms[0]
	var max_dist := 0.0
	var spawn_tile := Vector2(spawn_position.x / TILE_SIZE, spawn_position.y / TILE_SIZE)
	for room in rooms:
		var center := Vector2(room.position.x + room.size.x / 2.0, room.position.y + room.size.y / 2.0)
		var dist := center.distance_to(spawn_tile)
		if dist > max_dist:
			max_dist = dist
			farthest_room = room
	var cx := farthest_room.position.x + farthest_room.size.x / 2
	var cy := farthest_room.position.y + farthest_room.size.y / 2
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var tx := cx + dx
			var ty := cy + dy
			if tx >= 0 and tx < MAP_WIDTH and ty >= 0 and ty < MAP_HEIGHT:
				tiles[ty][tx] = TILE_SAFESPACE
	safespace_position = Vector2(cx * TILE_SIZE + TILE_SIZE / 2.0, cy * TILE_SIZE + TILE_SIZE / 2.0)

func _place_torches() -> void:
	torch_positions.clear()
	for room in rooms:
		var corners := [
			Vector2(room.position.x, room.position.y),
			Vector2(room.position.x + room.size.x - 1, room.position.y),
			Vector2(room.position.x, room.position.y + room.size.y - 1),
			Vector2(room.position.x + room.size.x - 1, room.position.y + room.size.y - 1),
		]
		for corner in corners:
			if rng.randf() > 0.3:
				torch_positions.append(Vector2(
					corner.x * TILE_SIZE + TILE_SIZE / 2.0,
					corner.y * TILE_SIZE + TILE_SIZE / 2.0
				))
		if room.size.x > 8 or room.size.y > 8:
			var mid_wall_positions := [
				Vector2(room.position.x + room.size.x / 2, room.position.y),
				Vector2(room.position.x + room.size.x / 2, room.position.y + room.size.y - 1),
				Vector2(room.position.x, room.position.y + room.size.y / 2),
				Vector2(room.position.x + room.size.x - 1, room.position.y + room.size.y / 2),
			]
			for pos in mid_wall_positions:
				if rng.randf() > 0.5:
					torch_positions.append(Vector2(
						pos.x * TILE_SIZE + TILE_SIZE / 2.0,
						pos.y * TILE_SIZE + TILE_SIZE / 2.0
					))

func _place_items() -> void:
	item_positions.clear()
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var num_items := rng.randi_range(0, 3)
		for _j in range(num_items):
			var ix := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var iy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var roll := rng.randf()
			var item_type: String
			if roll < 0.5:
				item_type = "gold_coin"
			elif roll < 0.7:
				item_type = "ammo_small"
			elif roll < 0.82:
				item_type = "health_potion"
			elif roll < 0.88:
				item_type = "artifact_ring"
			elif roll < 0.93:
				item_type = "artifact_vase"
			elif roll < 0.97:
				item_type = "gold_bar"
			else:
				item_type = "gold_cube"
			item_positions.append({
				"pos": Vector2(ix * TILE_SIZE + TILE_SIZE / 2.0, iy * TILE_SIZE + TILE_SIZE / 2.0),
				"type": item_type,
			})

func _place_food() -> void:
	food_positions.clear()
	var food_keys := GameData.food_defs.keys()
	for i in range(1, rooms.size()):
		var room := rooms[i]
		if rng.randf() > 0.4:
			continue
		var fx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
		var fy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
		if food_keys.is_empty():
			continue
		var food_type: String = food_keys.pick_random()
		food_positions.append({
			"pos": Vector2(fx * TILE_SIZE + TILE_SIZE / 2.0, fy * TILE_SIZE + TILE_SIZE / 2.0),
			"type": food_type,
		})

# Improvement #37: Place destructible objects (barrels, crates)
func _place_destructibles() -> void:
	destructible_positions.clear()
	var types := ["barrel", "crate", "vase", "tombstone", "crystal"]
	var emojis := {"barrel": "\U0001FAD9", "crate": "\U0001F4E6", "vase": "\U0001F3FA", "tombstone": "\U0001FAA6", "crystal": "\U0001F48E"}
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var count := rng.randi_range(0, 4)
		var rt := get_room_type(i)
		if rt == "treasury": count += 2
		if rt == "graveyard": count += 1
		for _j in range(count):
			var dx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var dy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var dtype: String = types.pick_random()
			if rt == "graveyard": dtype = "tombstone"
			destructible_positions.append({
				"pos": Vector2(dx * TILE_SIZE + TILE_SIZE / 2.0, dy * TILE_SIZE + TILE_SIZE / 2.0),
				"type": dtype,
				"emoji": emojis.get(dtype, "\U0001F4E6"),
				"hp": rng.randi_range(10, 50),
			})

# Improvement #38: Place traps
func _place_traps() -> void:
	trap_positions.clear()
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var rt := get_room_type(i)
		if rt == "spawn" or rt == "shrine": continue
		if rng.randf() < 0.35:
			var tx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var ty := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var trap_type := "spike" if rng.randf() < 0.6 else "poison"
			trap_positions.append({
				"pos": Vector2(tx * TILE_SIZE + TILE_SIZE / 2.0, ty * TILE_SIZE + TILE_SIZE / 2.0),
				"type": trap_type,
				"damage": 15.0 if trap_type == "spike" else 5.0,
				"duration": 0.0 if trap_type == "spike" else 5.0,
				"triggered": false,
			})

# Improvement #39: Place secret rooms
func _place_secret_rooms() -> void:
	secret_room_indices.clear()
	if rooms.size() < 5: return
	var num_secrets := rng.randi_range(1, 2)
	for _i in range(num_secrets):
		var room_idx := rng.randi_range(2, rooms.size() - 1)
		if room_idx in secret_room_indices: continue
		secret_room_indices.append(room_idx)
		var room := rooms[room_idx]
		# Place a secret wall tile on one edge
		var side := rng.randi_range(0, 3)
		var sx: int
		var sy: int
		match side:
			0: # top
				sx = room.position.x + room.size.x / 2
				sy = room.position.y - 1
			1: # bottom
				sx = room.position.x + room.size.x / 2
				sy = room.position.y + room.size.y
			2: # left
				sx = room.position.x - 1
				sy = room.position.y + room.size.y / 2
			_: # right
				sx = room.position.x + room.size.x
				sy = room.position.y + room.size.y / 2
		if sx >= 1 and sx < MAP_WIDTH - 1 and sy >= 1 and sy < MAP_HEIGHT - 1:
			tiles[sy][sx] = TILE_SECRET_WALL

# Improvement #48: Place chests
func _place_chests() -> void:
	chest_positions.clear()
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var rt := get_room_type(i)
		var chance := 0.2
		if rt == "treasury": chance = 0.8
		if rt == "armory": chance = 0.5
		if i in secret_room_indices: chance = 1.0
		if rng.randf() < chance:
			var cx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var cy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var rarity := "common"
			var r := rng.randf()
			if i in secret_room_indices: rarity = "legendary" if r < 0.3 else "epic"
			elif rt == "treasury": rarity = "rare" if r < 0.5 else "epic" if r < 0.8 else "legendary"
			elif r < 0.5: rarity = "common"
			elif r < 0.8: rarity = "uncommon"
			else: rarity = "rare"
			chest_positions.append({
				"pos": Vector2(cx * TILE_SIZE + TILE_SIZE / 2.0, cy * TILE_SIZE + TILE_SIZE / 2.0),
				"rarity": rarity,
				"opened": false,
			})

# Improvement #49: Place doors between corridors and rooms
func _place_doors() -> void:
	door_positions.clear()
	for i in range(1, rooms.size()):
		if rng.randf() < 0.3: continue
		var room := rooms[i]
		# Check each edge for corridor entrances
		var edges := [
			Vector2i(room.position.x + room.size.x / 2, room.position.y),
			Vector2i(room.position.x + room.size.x / 2, room.position.y + room.size.y - 1),
			Vector2i(room.position.x, room.position.y + room.size.y / 2),
			Vector2i(room.position.x + room.size.x - 1, room.position.y + room.size.y / 2),
		]
		for edge in edges:
			if edge.x > 0 and edge.x < MAP_WIDTH - 1 and edge.y > 0 and edge.y < MAP_HEIGHT - 1:
				if tiles[edge.y][edge.x] == TILE_FLOOR and rng.randf() < 0.3:
					door_positions.append({
						"pos": Vector2(edge.x * TILE_SIZE + TILE_SIZE / 2.0, edge.y * TILE_SIZE + TILE_SIZE / 2.0),
						"is_open": false,
						"is_locked": rng.randf() < 0.15,
					})
					break

# Improvement #42: Place water pools
func _place_water() -> void:
	for i in range(1, rooms.size()):
		var rt := get_room_type(i)
		if rt != "normal" and rt != "cathedral": continue
		if rng.randf() > 0.2: continue
		var room := rooms[i]
		var wx := rng.randi_range(room.position.x + 2, room.position.x + room.size.x - 3)
		var wy := rng.randi_range(room.position.y + 2, room.position.y + room.size.y - 3)
		var pool_size := rng.randi_range(1, 2)
		for dy in range(-pool_size, pool_size + 1):
			for dx in range(-pool_size, pool_size + 1):
				var tx := wx + dx
				var ty := wy + dy
				if tx > 0 and tx < MAP_WIDTH - 1 and ty > 0 and ty < MAP_HEIGHT - 1:
					if tiles[ty][tx] == TILE_FLOOR:
						tiles[ty][tx] = TILE_WATER

# Improvement #44: Place ambient particle emitter positions
func _place_particles() -> void:
	particle_positions.clear()
	for i in range(rooms.size()):
		var room := rooms[i]
		var rt := get_room_type(i)
		var ptype := "dust"
		match rt:
			"graveyard": ptype = "mist"
			"shrine": ptype = "sparkle"
			"treasury": ptype = "sparkle"
			"lab": ptype = "smoke"
			"cathedral": ptype = "mist"
		particle_positions.append({
			"pos": Vector2(
				(room.position.x + room.size.x / 2.0) * TILE_SIZE,
				(room.position.y + room.size.y / 2.0) * TILE_SIZE
			),
			"type": ptype,
			"room_index": i,
		})

# Improvement: Generate patrol routes for enemies
func _generate_patrol_routes() -> void:
	patrol_routes.clear()
	if rooms.size() < 2:
		return
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var points: Array[Vector2] = []
		var rx: int = room.position.x
		var ry: int = room.position.y
		var rw: int = room.size.x
		var rh: int = room.size.y
		var corners := [
			Vector2((rx + 1) * TILE_SIZE, (ry + 1) * TILE_SIZE),
			Vector2((rx + rw - 2) * TILE_SIZE, (ry + 1) * TILE_SIZE),
			Vector2((rx + rw - 2) * TILE_SIZE, (ry + rh - 2) * TILE_SIZE),
			Vector2((rx + 1) * TILE_SIZE, (ry + rh - 2) * TILE_SIZE),
		]
		for c in corners:
			if rng.randf() < 0.7:
				points.append(c)
		if points.size() >= 2:
			patrol_routes.append({"room_index": i, "points": points})

func _setup_enemy_spawns() -> void:
	enemy_spawn_rooms.clear()
	var spawn_rate := GameSystems.get_diff_mult("spawn_rate")
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var is_safespace_room := false
		var room_center := Vector2(
			(room.position.x + room.size.x / 2.0) * TILE_SIZE,
			(room.position.y + room.size.y / 2.0) * TILE_SIZE
		)
		if room_center.distance_to(safespace_position) < TILE_SIZE * 3:
			is_safespace_room = true
		var room_area := room.size.x * room.size.y
		var difficulty: String
		var enemy_count: int
		var rt := get_room_type(i)
		if is_safespace_room:
			difficulty = "boss"
			enemy_count = rng.randi_range(15, 25)
		elif rt == "arena":
			difficulty = "hard"
			enemy_count = rng.randi_range(15, 25)
		elif rt == "treasury":
			difficulty = "hard"
			enemy_count = rng.randi_range(8, 15)
		elif room_area > 100:
			difficulty = "hard"
			enemy_count = rng.randi_range(10, 20)
		elif room_area > 50:
			difficulty = "medium"
			enemy_count = rng.randi_range(5, 12)
		else:
			difficulty = "easy"
			enemy_count = rng.randi_range(3, 8)
		enemy_count = int(enemy_count * spawn_rate)
		# Improvement #23: Elite enemy chance
		var has_elite := rng.randf() < 0.15 and difficulty != "easy"
		var spawn_points: Array[Vector2] = []
		for _j in range(enemy_count):
			var sx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var sy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			spawn_points.append(Vector2(sx * TILE_SIZE + TILE_SIZE / 2.0, sy * TILE_SIZE + TILE_SIZE / 2.0))
		enemy_spawn_rooms.append({
			"room_index": i,
			"room_center": room_center,
			"difficulty": difficulty,
			"spawn_points": spawn_points,
			"triggered": false,
			"room_type": rt,
			"has_elite": has_elite,
		})

func _place_lore() -> void:
	lore_positions.clear()

	for i in range(1, rooms.size()):
		var room := rooms[i]
		if rng.randf() < 0.65:
			var lx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var ly := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var entry_id: String = LoreManager.pick_room_lore(rng)
			if entry_id != "":
				lore_positions.append({
					"pos": Vector2(lx * TILE_SIZE + TILE_SIZE / 2.0, ly * TILE_SIZE + TILE_SIZE / 2.0),
					"entry_id": entry_id,
				})

		if room.size.x * room.size.y > 80 and rng.randf() < 0.35:
			var lx2 := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var ly2 := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var entry_id2: String = LoreManager.pick_room_lore(rng)
			if entry_id2 != "":
				lore_positions.append({
					"pos": Vector2(lx2 * TILE_SIZE + TILE_SIZE / 2.0, ly2 * TILE_SIZE + TILE_SIZE / 2.0),
					"entry_id": entry_id2,
				})

	for i in range(rooms.size() - 1):
		if rng.randf() < 0.25:
			var room_a := rooms[i]
			var room_b := rooms[i + 1]
			var mid_x := (room_a.position.x + room_a.size.x / 2 + room_b.position.x + room_b.size.x / 2) / 2
			var mid_y := (room_a.position.y + room_a.size.y / 2 + room_b.position.y + room_b.size.y / 2) / 2
			mid_x = clampi(mid_x, 2, MAP_WIDTH - 2)
			mid_y = clampi(mid_y, 2, MAP_HEIGHT - 2)
			if tiles[mid_y][mid_x] == TILE_FLOOR:
				var entry_id: String = LoreManager.pick_corridor_lore(rng)
				if entry_id != "":
					lore_positions.append({
						"pos": Vector2(mid_x * TILE_SIZE + TILE_SIZE / 2.0, mid_y * TILE_SIZE + TILE_SIZE / 2.0),
						"entry_id": entry_id,
					})

	for i in range(rooms.size()):
		var room := rooms[i]
		if rng.randf() < 0.3:
			var gx := room.position.x + room.size.x - 2
			var gy := room.position.y + 1
			if gx >= 0 and gx < MAP_WIDTH and gy >= 0 and gy < MAP_HEIGHT and tiles[gy][gx] == TILE_FLOOR:
				var entry_id: String = LoreManager.pick_gravestone_lore(rng)
				if entry_id != "":
					lore_positions.append({
						"pos": Vector2(gx * TILE_SIZE + TILE_SIZE / 2.0, gy * TILE_SIZE + TILE_SIZE / 2.0),
						"entry_id": entry_id,
					})

	if rng.randf() < 0.2 and rooms.size() > 3:
		var rare_room := rooms[rng.randi_range(2, rooms.size() - 1)]
		var rx := rng.randi_range(rare_room.position.x + 1, rare_room.position.x + rare_room.size.x - 2)
		var ry := rng.randi_range(rare_room.position.y + 1, rare_room.position.y + rare_room.size.y - 2)
		var entry_id: String = LoreManager.pick_rare_lore(rng)
		if entry_id != "":
			lore_positions.append({
				"pos": Vector2(rx * TILE_SIZE + TILE_SIZE / 2.0, ry * TILE_SIZE + TILE_SIZE / 2.0),
				"entry_id": entry_id,
			})

func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT:
		return TILE_WALL
	return tiles[y][x]

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0, tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func is_walkable(world_pos: Vector2) -> bool:
	var tp := world_to_tile(world_pos)
	var t := get_tile(tp.x, tp.y)
	return t == TILE_FLOOR or t == TILE_SAFESPACE

# ===== Improvement #76: Fountain Rooms =====
func _place_fountains() -> void:
	fountain_positions.clear()
	for i in range(1, rooms.size()):
		var rt := get_room_type(i)
		if rt == "shrine" or (rt == "normal" and rng.randf() < 0.15):
			var room := rooms[i]
			var cx := room.position.x + room.size.x / 2
			var cy := room.position.y + room.size.y / 2
			fountain_positions.append({
				"pos": Vector2(cx * TILE_SIZE + TILE_SIZE / 2.0, cy * TILE_SIZE + TILE_SIZE / 2.0),
				"room_index": i,
				"heal_per_sec": 3.0,
				"radius": TILE_SIZE * 2.0,
				"emoji": "\u26F2",
				"uses_left": rng.randi_range(3, 8),
			})

# ===== Improvement #77: Altar Rooms =====
func _place_altars() -> void:
	altar_positions.clear()
	var altar_types := [
		{"name": "Altar of Strength", "emoji": "\u2694\uFE0F", "buff": "damage", "value": 1.2, "duration": 60.0},
		{"name": "Altar of Swiftness", "emoji": "\u26A1", "buff": "speed", "value": 1.25, "duration": 60.0},
		{"name": "Altar of Protection", "emoji": "\U0001F6E1\uFE0F", "buff": "defense", "value": 0.8, "duration": 60.0},
		{"name": "Altar of Fury", "emoji": "\U0001F4A2", "buff": "crit_chance", "value": 0.15, "duration": 45.0},
		{"name": "Altar of Life", "emoji": "\u2764\uFE0F", "buff": "regen", "value": 2.0, "duration": 90.0},
	]
	for i in range(1, rooms.size()):
		var rt := get_room_type(i)
		var chance := 0.0
		if rt == "shrine": chance = 0.8
		elif rt == "cathedral": chance = 0.5
		elif i in secret_room_indices: chance = 0.6
		else: chance = 0.05
		if rng.randf() < chance:
			var room := rooms[i]
			var cx := room.position.x + room.size.x / 2
			var cy := room.position.y + room.size.y / 2
			var altar: Dictionary = altar_types[rng.randi_range(0, altar_types.size() - 1)].duplicate()
			altar["pos"] = Vector2(cx * TILE_SIZE + TILE_SIZE / 2.0, cy * TILE_SIZE + TILE_SIZE / 2.0)
			altar["room_index"] = i
			altar["activated"] = false
			altar_positions.append(altar)

# ===== Improvement #78: Room Decorations =====
func _place_decorations() -> void:
	decoration_positions.clear()
	var deco_types := {
		"pillar": {"emoji": "\U0001F3DB\uFE0F", "blocking": true, "size": 1},
		"statue": {"emoji": "\U0001FABBF", "blocking": true, "size": 1},
		"rug": {"emoji": "\U0001F9F6", "blocking": false, "size": 2},
		"candle": {"emoji": "\U0001F56F\uFE0F", "blocking": false, "size": 1},
		"skull": {"emoji": "\U0001F480", "blocking": false, "size": 1},
		"bone_pile": {"emoji": "\U0001F9B4", "blocking": false, "size": 1},
		"web": {"emoji": "\U0001F578\uFE0F", "blocking": false, "size": 1},
	}
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var rt := get_room_type(i)
		var count := rng.randi_range(0, 3)
		# Themed decorations
		var valid_decos: Array[String] = []
		match rt:
			"cathedral", "shrine":
				valid_decos = ["pillar", "candle", "rug"]
				count += 2
			"graveyard":
				valid_decos = ["skull", "bone_pile", "web"]
				count += 1
			"lab":
				valid_decos = ["candle", "skull", "web"]
			"treasury":
				valid_decos = ["pillar", "rug", "statue"]
				count += 1
			_:
				valid_decos = ["pillar", "skull", "candle", "web", "bone_pile"]
		for _j in range(count):
			var dx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var dy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			if valid_decos.is_empty():
				continue
			var dtype: String = valid_decos[rng.randi_range(0, valid_decos.size() - 1)]
			var info: Dictionary = deco_types.get(dtype, deco_types["skull"])
			decoration_positions.append({
				"pos": Vector2(dx * TILE_SIZE + TILE_SIZE / 2.0, dy * TILE_SIZE + TILE_SIZE / 2.0),
				"type": dtype,
				"emoji": info["emoji"],
				"blocking": info["blocking"],
				"room_index": i,
			})

# ===== Improvement #79: Corridor Ambush Points =====
func _place_corridor_ambushes() -> void:
	corridor_ambush_points.clear()
	# Find corridor tiles that are narrow (surrounded by walls on 2 sides)
	for y in range(2, MAP_HEIGHT - 2):
		for x in range(2, MAP_WIDTH - 2):
			if tiles[y][x] != TILE_FLOOR:
				continue
			# Check if in a room
			var in_room := false
			for room in rooms:
				if x >= room.position.x and x < room.position.x + room.size.x and y >= room.position.y and y < room.position.y + room.size.y:
					in_room = true
					break
			if in_room:
				continue
			# Corridor tile - chance to mark as ambush
			if rng.randf() < 0.03:
				corridor_ambush_points.append({
					"pos": Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0),
					"triggered": false,
					"enemy_count": rng.randi_range(2, 4),
				})

# ===== Improvement #80: Dead-End Treasure =====
func _place_dead_end_treasures() -> void:
	dead_end_treasures.clear()
	# Find floor tiles with only 1 adjacent floor tile (dead ends)
	for y in range(1, MAP_HEIGHT - 1):
		for x in range(1, MAP_WIDTH - 1):
			if tiles[y][x] != TILE_FLOOR:
				continue
			var adj_floor := 0
			if tiles[y - 1][x] == TILE_FLOOR or tiles[y - 1][x] == TILE_SAFESPACE: adj_floor += 1
			if tiles[y + 1][x] == TILE_FLOOR or tiles[y + 1][x] == TILE_SAFESPACE: adj_floor += 1
			if tiles[y][x - 1] == TILE_FLOOR or tiles[y][x - 1] == TILE_SAFESPACE: adj_floor += 1
			if tiles[y][x + 1] == TILE_FLOOR or tiles[y][x + 1] == TILE_SAFESPACE: adj_floor += 1
			if adj_floor == 1 and rng.randf() < 0.5:
				var rarity := "uncommon"
				if rng.randf() < 0.2: rarity = "rare"
				if rng.randf() < 0.05: rarity = "epic"
				dead_end_treasures.append({
					"pos": Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0),
					"rarity": rarity,
					"collected": false,
				})

# ===== Improvement #81: Environmental Hazard Zones =====
func _place_hazard_zones() -> void:
	hazard_zones.clear()
	var hazard_types := ["fire", "poison_gas", "lightning", "ice"]
	for i in range(1, rooms.size()):
		var rt := get_room_type(i)
		if rt == "spawn" or rt == "shrine":
			continue
		if rng.randf() < 0.12:
			var room := rooms[i]
			var hx := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
			var hy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			var htype: String = hazard_types[rng.randi_range(0, hazard_types.size() - 1)]
			# Match hazard to room theme
			if rt == "lab": htype = "poison_gas"
			elif rt == "graveyard": htype = "fire"
			hazard_zones.append({
				"pos": Vector2(hx * TILE_SIZE + TILE_SIZE / 2.0, hy * TILE_SIZE + TILE_SIZE / 2.0),
				"type": htype,
				"radius": TILE_SIZE * rng.randf_range(1.5, 3.0),
				"damage": 3.0 + room_difficulties[i] * 2.0 if i < room_difficulties.size() else 3.0,
				"room_index": i,
			})

# ===== Improvement #82: Room Difficulty by Distance =====
func _calculate_room_difficulties() -> void:
	room_difficulties.clear()
	var spawn_tile := Vector2(spawn_position.x / TILE_SIZE, spawn_position.y / TILE_SIZE)
	var max_dist := 1.0
	# First pass: find max distance
	for room in rooms:
		var center := Vector2(room.position.x + room.size.x / 2.0, room.position.y + room.size.y / 2.0)
		var dist := center.distance_to(spawn_tile)
		if dist > max_dist:
			max_dist = dist
	# Second pass: normalize to 0-1 range
	for room in rooms:
		var center := Vector2(room.position.x + room.size.x / 2.0, room.position.y + room.size.y / 2.0)
		var dist := center.distance_to(spawn_tile)
		room_difficulties.append(clampf(dist / max_dist, 0.0, 1.0))

func get_room_difficulty(index: int) -> float:
	if index >= 0 and index < room_difficulties.size():
		return room_difficulties[index]
	return 0.5

# ===== Improvement #83: Themed Room Items =====
func _place_themed_items() -> void:
	themed_item_positions.clear()
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var rt := get_room_type(i)
		var items_to_place: Array[Dictionary] = []
		match rt:
			"armory":
				items_to_place = [
					{"type": "damage_boost", "chance": 0.3},
					{"type": "shield_orb", "chance": 0.2},
				]
			"library":
				items_to_place = [
					{"type": "xp_multiplier", "chance": 0.15},
				]
			"treasury":
				items_to_place = [
					{"type": "gold_multiplier", "chance": 0.25},
					{"type": "gold_bar", "chance": 0.4},
					{"type": "gold_coin", "chance": 0.6},
				]
			"lab":
				items_to_place = [
					{"type": "rage_potion", "chance": 0.2},
					{"type": "speed_boost", "chance": 0.15},
				]
			"graveyard":
				items_to_place = [
					{"type": "health_orb", "chance": 0.25},
				]
		for item_info in items_to_place:
			if rng.randf() < item_info["chance"]:
				var ix := rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
				var iy := rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
				themed_item_positions.append({
					"pos": Vector2(ix * TILE_SIZE + TILE_SIZE / 2.0, iy * TILE_SIZE + TILE_SIZE / 2.0),
					"type": item_info["type"],
					"room_index": i,
				})

func get_floor_color(x: int, y: int) -> Color:
	var base := 0.12
	var variation := sin(x * 13.37 + y * 7.77) * 0.015
	var v := base + variation
	return Color(v, v * 0.92, v * 0.85)

func get_wall_top_color(x: int, y: int) -> Color:
	var base := 0.18
	var variation := cos(x * 11.13 + y * 9.31) * 0.01
	var v := base + variation
	return Color(v, v * 0.9, v * 0.85)

# ===== SIDESCROLLER BUILDINGS =====
# Places enterable buildings in larger rooms that switch to sidescroller view

const BUILDING_TYPES := {
	"house": {
		"emoji": "\U0001F3E0",
		"building_type": 0,  # BuildingType.HOUSE
		"min_room_area": 40,
		"tile_size": 3,
	},
	"cave": {
		"emoji": "\U0001F5FB",
		"building_type": 1,  # BuildingType.CAVE
		"min_room_area": 60,
		"tile_size": 4,
	},
	"fortress": {
		"emoji": "\U0001F3F0",
		"building_type": 2,  # BuildingType.FORTRESS
		"min_room_area": 80,
		"tile_size": 5,
	},
	"castle": {
		"emoji": "\U0001F451",
		"building_type": 3,  # BuildingType.CASTLE
		"min_room_area": 100,
		"tile_size": 6,
	},
}

func _place_buildings() -> void:
	building_positions.clear()

	# Determine which rooms get buildings based on size and type
	var available_rooms: Array[int] = []
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var area := room.size.x * room.size.y
		var rt := get_room_type(i)
		# Don't place buildings in special rooms
		if rt == "spawn" or rt == "shrine" or rt == "prison":
			continue
		if area >= 40:
			available_rooms.append(i)

	# Place 1-3 buildings depending on map size
	var num_buildings: int = mini(rng.randi_range(1, 3), available_rooms.size())
	available_rooms.shuffle()

	for b in range(num_buildings):
		var room_idx: int = available_rooms[b]
		var room := rooms[room_idx]
		var area := room.size.x * room.size.y
		var rt := get_room_type(room_idx)

		# Pick building type based on room characteristics
		var btype: String = _pick_building_type(area, rt)
		var binfo: Dictionary = BUILDING_TYPES[btype]

		# Place building entry in center-ish of room
		var bx: int = room.position.x + int(room.size.x / 2.0)
		var by: int = room.position.y + int(room.size.y / 2.0)

		# Mark entry tiles
		var half: int = int(binfo["tile_size"] / 2.0)
		for dy in range(-half, half + 1):
			for dx in range(-half, half + 1):
				var tx: int = bx + dx
				var ty: int = by + dy
				if tx >= 0 and tx < MAP_WIDTH and ty >= 0 and ty < MAP_HEIGHT:
					if tiles[ty][tx] == TILE_FLOOR:
						tiles[ty][tx] = TILE_BUILDING_ENTRY

		var world_pos := Vector2(
			bx * TILE_SIZE + TILE_SIZE * 0.5,
			by * TILE_SIZE + TILE_SIZE * 0.5
		)

		building_positions.append({
			"pos": world_pos,
			"building_type": binfo["building_type"],
			"building_name": btype,
			"emoji": binfo["emoji"],
			"room_index": room_idx,
			"seed": rng.randi(),
			"tile_pos": Vector2i(bx, by),
			"tile_radius": half,
		})

func _pick_building_type(area: int, room_type: String) -> String:
	# Themed building selection
	if room_type == "cathedral" or room_type == "arena":
		if area >= 100:
			return "castle"
		return "fortress"
	if room_type == "treasury" or room_type == "armory":
		return "fortress"
	if room_type == "graveyard":
		return "cave"

	# Size-based selection
	if area >= 100:
		var roll := rng.randf()
		if roll < 0.3:
			return "castle"
		elif roll < 0.6:
			return "fortress"
		return "cave"
	elif area >= 60:
		var roll := rng.randf()
		if roll < 0.4:
			return "fortress"
		elif roll < 0.7:
			return "cave"
		return "house"
	else:
		var roll := rng.randf()
		if roll < 0.5:
			return "house"
		return "cave"
