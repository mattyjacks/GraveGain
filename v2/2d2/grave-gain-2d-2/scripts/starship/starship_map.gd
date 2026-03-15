extends RefCounted

# ===== STARSHIP MAP GENERATOR =====
# Generates a starship interior as the player's starting area before descending to dungeons.
# The starship has: bridge, armory, medbay, cargo bay, engine room, crew quarters,
# hangar bay (exit to dungeon), corridors connecting all rooms.

const TILE_VOID: int = 0
const TILE_FLOOR: int = 1
const TILE_WALL: int = 2
const TILE_HULL: int = 3  # Outer hull - indestructible
const TILE_DOOR: int = 4
const TILE_CONSOLE: int = 5
const TILE_WINDOW: int = 6

const TILE_SIZE: int = 32
const MAP_WIDTH: int = 80
const MAP_HEIGHT: int = 60

# Room definitions - each room has a purpose and specific features
enum RoomType { BRIDGE, ARMORY, MEDBAY, CARGO_BAY, ENGINE_ROOM, CREW_QUARTERS, HANGAR, CORRIDOR, AIRLOCK, LAB, MESS_HALL, STORAGE }

const ROOM_DEFINITIONS: Dictionary = {
	RoomType.BRIDGE: {
		"name": "Bridge",
		"emoji": "\U0001F4BB",
		"min_size": Vector2i(12, 10),
		"max_size": Vector2i(16, 12),
		"description": "Command center of the starship. Navigation consoles and viewscreens.",
		"color": Color(0.2, 0.3, 0.5),
	},
	RoomType.ARMORY: {
		"name": "Armory",
		"emoji": "\u2694\uFE0F",
		"min_size": Vector2i(8, 6),
		"max_size": Vector2i(12, 8),
		"description": "Weapons storage. Equip before your mission.",
		"color": Color(0.5, 0.2, 0.2),
	},
	RoomType.MEDBAY: {
		"name": "Medbay",
		"emoji": "\U0001FA7A",
		"min_size": Vector2i(8, 6),
		"max_size": Vector2i(10, 8),
		"description": "Medical bay. Heal up before departure.",
		"color": Color(0.2, 0.5, 0.3),
	},
	RoomType.CARGO_BAY: {
		"name": "Cargo Bay",
		"emoji": "\U0001F4E6",
		"min_size": Vector2i(10, 10),
		"max_size": Vector2i(16, 14),
		"description": "Main cargo storage. Trade goods and store loot.",
		"color": Color(0.4, 0.35, 0.2),
	},
	RoomType.ENGINE_ROOM: {
		"name": "Engine Room",
		"emoji": "\u2699\uFE0F",
		"min_size": Vector2i(10, 8),
		"max_size": Vector2i(14, 10),
		"description": "FTL drive and power core. Danger: radiation.",
		"color": Color(0.5, 0.3, 0.1),
	},
	RoomType.CREW_QUARTERS: {
		"name": "Crew Quarters",
		"emoji": "\U0001F6CF\uFE0F",
		"min_size": Vector2i(8, 6),
		"max_size": Vector2i(12, 8),
		"description": "Living quarters. Rest to save your game.",
		"color": Color(0.3, 0.3, 0.4),
	},
	RoomType.HANGAR: {
		"name": "Hangar Bay",
		"emoji": "\U0001F680",
		"min_size": Vector2i(14, 12),
		"max_size": Vector2i(18, 14),
		"description": "Launch bay. Board your drop pod to descend to the surface.",
		"color": Color(0.25, 0.25, 0.35),
	},
	RoomType.AIRLOCK: {
		"name": "Airlock",
		"emoji": "\U0001F6AA",
		"min_size": Vector2i(4, 4),
		"max_size": Vector2i(6, 6),
		"description": "Emergency airlock. Don't open this in space.",
		"color": Color(0.4, 0.1, 0.1),
	},
	RoomType.LAB: {
		"name": "Research Lab",
		"emoji": "\U0001F52C",
		"min_size": Vector2i(8, 6),
		"max_size": Vector2i(10, 8),
		"description": "Analyze artifacts and research upgrades.",
		"color": Color(0.2, 0.4, 0.5),
	},
	RoomType.MESS_HALL: {
		"name": "Mess Hall",
		"emoji": "\U0001F37D\uFE0F",
		"min_size": Vector2i(8, 8),
		"max_size": Vector2i(12, 10),
		"description": "Crew dining area. Eat to restore health.",
		"color": Color(0.4, 0.3, 0.2),
	},
	RoomType.STORAGE: {
		"name": "Storage",
		"emoji": "\U0001F4E6",
		"min_size": Vector2i(6, 4),
		"max_size": Vector2i(8, 6),
		"description": "Extra storage compartment.",
		"color": Color(0.3, 0.3, 0.3),
	},
}

# Generated data
var tiles: Array = []
var rooms: Array[Dictionary] = []  # {position: Vector2i, size: Vector2i, type: RoomType, name: String}
var corridors: Array[Dictionary] = []
var spawn_position: Vector2 = Vector2.ZERO
var hangar_position: Vector2 = Vector2.ZERO  # Exit to dungeon
var npc_positions: Array[Dictionary] = []  # {position: Vector2, type: String, name: String}
var interactable_positions: Array[Dictionary] = []  # {position: Vector2, type: String, data: Dictionary}
var light_positions: Array[Vector2] = []
var decoration_positions: Array[Dictionary] = []
var item_positions: Array[Dictionary] = []
var lore_positions: Array[Dictionary] = []

var rng := RandomNumberGenerator.new()

func generate(seed_val: int = -1) -> void:
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()
	
	_init_tiles()
	_place_rooms()
	_connect_rooms()
	_add_hull()
	_place_lights()
	_place_npcs()
	_place_interactables()
	_place_decorations()
	_place_starting_items()
	_place_lore()
	_set_spawn_position()

func _init_tiles() -> void:
	tiles.clear()
	for y in range(MAP_HEIGHT):
		var row: Array = []
		for x in range(MAP_WIDTH):
			row.append(TILE_VOID)
		tiles.append(row)

func _place_rooms() -> void:
	rooms.clear()
	
	# Fixed room layout for the starship - symmetrical ship design
	# Bridge at the front (top), hangar at the back (bottom)
	var room_configs: Array[Dictionary] = [
		{"type": RoomType.BRIDGE, "target_pos": Vector2i(32, 5)},
		{"type": RoomType.CREW_QUARTERS, "target_pos": Vector2i(15, 10)},
		{"type": RoomType.MEDBAY, "target_pos": Vector2i(50, 10)},
		{"type": RoomType.MESS_HALL, "target_pos": Vector2i(32, 18)},
		{"type": RoomType.ARMORY, "target_pos": Vector2i(12, 25)},
		{"type": RoomType.LAB, "target_pos": Vector2i(52, 25)},
		{"type": RoomType.CARGO_BAY, "target_pos": Vector2i(32, 32)},
		{"type": RoomType.ENGINE_ROOM, "target_pos": Vector2i(32, 44)},
		{"type": RoomType.STORAGE, "target_pos": Vector2i(15, 38)},
		{"type": RoomType.AIRLOCK, "target_pos": Vector2i(55, 38)},
		{"type": RoomType.HANGAR, "target_pos": Vector2i(32, 52)},
	]
	
	for config in room_configs:
		var room_type: int = config["type"]
		var target: Vector2i = config["target_pos"]
		var def: Dictionary = ROOM_DEFINITIONS.get(room_type, ROOM_DEFINITIONS[RoomType.STORAGE])
		
		var w: int = rng.randi_range(def["min_size"].x, def["max_size"].x)
		var h: int = rng.randi_range(def["min_size"].y, def["max_size"].y)
		var x: int = clampi(target.x - w / 2, 1, MAP_WIDTH - w - 1)
		var y: int = clampi(target.y - h / 2, 1, MAP_HEIGHT - h - 1)
		
		# Carve room
		for ry in range(y, y + h):
			for rx in range(x, x + w):
				if ry >= 0 and ry < MAP_HEIGHT and rx >= 0 and rx < MAP_WIDTH:
					tiles[ry][rx] = TILE_FLOOR
		
		rooms.append({
			"position": Vector2i(x, y),
			"size": Vector2i(w, h),
			"type": room_type,
			"name": def.get("name", "Room"),
			"emoji": def.get("emoji", ""),
			"description": def.get("description", ""),
			"color": def.get("color", Color.GRAY),
		})

func _connect_rooms() -> void:
	# Connect rooms sequentially with corridors (3-wide)
	for i in range(rooms.size() - 1):
		var room_a := rooms[i]
		var room_b := rooms[i + 1]
		var ca := Vector2i(
			room_a["position"].x + room_a["size"].x / 2,
			room_a["position"].y + room_a["size"].y / 2
		)
		var cb := Vector2i(
			room_b["position"].x + room_b["size"].x / 2,
			room_b["position"].y + room_b["size"].y / 2
		)
		_carve_corridor(ca, cb)
	
	# Extra connections for accessibility
	if rooms.size() > 3:
		# Connect bridge to mess hall directly
		_carve_corridor(
			_room_center(0), _room_center(3)
		)
		# Connect armory to cargo bay
		if rooms.size() > 6:
			_carve_corridor(_room_center(4), _room_center(6))
			# Connect lab to cargo bay
			_carve_corridor(_room_center(5), _room_center(6))

func _room_center(index: int) -> Vector2i:
	if index < 0 or index >= rooms.size():
		return Vector2i(MAP_WIDTH / 2, MAP_HEIGHT / 2)
	var room := rooms[index]
	return Vector2i(
		room["position"].x + room["size"].x / 2,
		room["position"].y + room["size"].y / 2
	)

func _carve_corridor(from: Vector2i, to: Vector2i) -> void:
	var corridor_width: int = 3
	# L-shaped corridor
	if rng.randf() > 0.5:
		_carve_h_line(from.x, to.x, from.y, corridor_width)
		_carve_v_line(from.y, to.y, to.x, corridor_width)
	else:
		_carve_v_line(from.y, to.y, from.x, corridor_width)
		_carve_h_line(from.x, to.x, to.y, corridor_width)

func _carve_h_line(x1: int, x2: int, y: int, width: int) -> void:
	var sx := mini(x1, x2)
	var ex := maxi(x1, x2)
	for x in range(sx, ex + 1):
		for dy in range(-width / 2, width / 2 + 1):
			var ty := y + dy
			if ty >= 0 and ty < MAP_HEIGHT and x >= 0 and x < MAP_WIDTH:
				tiles[ty][x] = TILE_FLOOR

func _carve_v_line(y1: int, y2: int, x: int, width: int) -> void:
	var sy := mini(y1, y2)
	var ey := maxi(y1, y2)
	for y in range(sy, ey + 1):
		for dx in range(-width / 2, width / 2 + 1):
			var tx := x + dx
			if y >= 0 and y < MAP_HEIGHT and tx >= 0 and tx < MAP_WIDTH:
				tiles[y][tx] = TILE_FLOOR

func _add_hull() -> void:
	# Add walls around all floor tiles, then hull around walls
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if tiles[y][x] == TILE_FLOOR:
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var ny := y + dy
						var nx := x + dx
						if ny >= 0 and ny < MAP_HEIGHT and nx >= 0 and nx < MAP_WIDTH:
							if tiles[ny][nx] == TILE_VOID:
								tiles[ny][nx] = TILE_WALL

func _place_lights() -> void:
	light_positions.clear()
	for room in rooms:
		var cx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
		var cy: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
		light_positions.append(Vector2(cx, cy))
		
		# Corner lights for larger rooms
		if room["size"].x > 8:
			var x1: float = (room["position"].x + 2) * TILE_SIZE
			var x2: float = (room["position"].x + room["size"].x - 2) * TILE_SIZE
			var y1: float = (room["position"].y + 2) * TILE_SIZE
			var y2: float = (room["position"].y + room["size"].y - 2) * TILE_SIZE
			light_positions.append(Vector2(x1, y1))
			light_positions.append(Vector2(x2, y1))
			light_positions.append(Vector2(x1, y2))
			light_positions.append(Vector2(x2, y2))

func _place_npcs() -> void:
	npc_positions.clear()
	
	# Captain on the bridge
	if rooms.size() > 0:
		var bridge := rooms[0]
		var bx: float = (bridge["position"].x + bridge["size"].x / 2.0) * TILE_SIZE
		var by: float = (bridge["position"].y + 2) * TILE_SIZE
		npc_positions.append({
			"position": Vector2(bx, by),
			"type": "captain",
			"name": "Captain Voss",
			"emoji": "\U0001F468\u200D\U0001F680",
			"dialogue": [
				"Welcome aboard, soldier. We're in orbit above the graveworld.",
				"Head to the Armory to gear up, then the Hangar to deploy.",
				"The surface is crawling with the undead. Stay sharp down there.",
			]
		})
	
	# Medic in medbay
	for room in rooms:
		if room["type"] == RoomType.MEDBAY:
			var mx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var my: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			npc_positions.append({
				"position": Vector2(mx, my),
				"type": "medic",
				"name": "Dr. Chen",
				"emoji": "\U0001F469\u200D\u2695\uFE0F",
				"dialogue": [
					"I can patch you up before you head down.",
					"Come back if you're injured. I'll be here.",
				]
			})
			break
	
	# Quartermaster in armory
	for room in rooms:
		if room["type"] == RoomType.ARMORY:
			var ax: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var ay: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			npc_positions.append({
				"position": Vector2(ax, ay),
				"type": "quartermaster",
				"name": "Sgt. Drake",
				"emoji": "\U0001F482",
				"dialogue": [
					"Pick your loadout carefully. The graveworld doesn't give second chances.",
					"I've stocked the latest weapons. Take what you need.",
				]
			})
			break
	
	# Engineer in engine room
	for room in rooms:
		if room["type"] == RoomType.ENGINE_ROOM:
			var ex: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var ey: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			npc_positions.append({
				"position": Vector2(ex, ey),
				"type": "engineer",
				"name": "Chief Torres",
				"emoji": "\U0001F477",
				"dialogue": [
					"FTL drive is stable. We can hold orbit as long as you need.",
					"Watch out for radiation pockets on the surface.",
				]
			})
			break
	
	# Scientist in lab
	for room in rooms:
		if room["type"] == RoomType.LAB:
			var lx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var ly: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			npc_positions.append({
				"position": Vector2(lx, ly),
				"type": "scientist",
				"name": "Prof. Nakamura",
				"emoji": "\U0001F468\u200D\U0001F52C",
				"dialogue": [
					"Bring me artifacts from the surface. I can analyze them.",
					"The graveworld holds ancient secrets. Find lore entries for me.",
				]
			})
			break

func _place_interactables() -> void:
	interactable_positions.clear()
	
	for room in rooms:
		var cx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
		var cy: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
		var room_type: int = room["type"]
		
		match room_type:
			RoomType.BRIDGE:
				# Navigation console
				interactable_positions.append({
					"position": Vector2(cx, cy - 40),
					"type": "console",
					"name": "Navigation Console",
					"emoji": "\U0001F4BB",
					"action": "view_map",
				})
				# Comms console
				interactable_positions.append({
					"position": Vector2(cx + 60, cy - 40),
					"type": "console",
					"name": "Communications",
					"emoji": "\U0001F4E1",
					"action": "comms",
				})
			RoomType.ARMORY:
				# Weapon rack
				interactable_positions.append({
					"position": Vector2(cx - 40, cy),
					"type": "weapon_rack",
					"name": "Weapon Rack",
					"emoji": "\u2694\uFE0F",
					"action": "equip_weapons",
				})
				# Armor locker
				interactable_positions.append({
					"position": Vector2(cx + 40, cy),
					"type": "armor_locker",
					"name": "Armor Locker",
					"emoji": "\U0001F6E1\uFE0F",
					"action": "equip_armor",
				})
			RoomType.MEDBAY:
				# Healing station
				interactable_positions.append({
					"position": Vector2(cx, cy + 30),
					"type": "heal_station",
					"name": "Healing Station",
					"emoji": "\U0001FA7A",
					"action": "full_heal",
				})
			RoomType.CARGO_BAY:
				# Storage crates
				for i in range(3):
					var ox := rng.randf_range(-60, 60)
					var oy := rng.randf_range(-40, 40)
					interactable_positions.append({
						"position": Vector2(cx + ox, cy + oy),
						"type": "crate",
						"name": "Supply Crate",
						"emoji": "\U0001F4E6",
						"action": "loot_crate",
					})
			RoomType.CREW_QUARTERS:
				# Bed (save point)
				interactable_positions.append({
					"position": Vector2(cx, cy),
					"type": "bed",
					"name": "Bunk",
					"emoji": "\U0001F6CF\uFE0F",
					"action": "save_game",
				})
			RoomType.HANGAR:
				# Drop pod (exit to dungeon)
				interactable_positions.append({
					"position": Vector2(cx, cy),
					"type": "drop_pod",
					"name": "Drop Pod",
					"emoji": "\U0001F680",
					"action": "deploy_to_surface",
				})
				hangar_position = Vector2(cx, cy)
			RoomType.MESS_HALL:
				# Food dispenser
				interactable_positions.append({
					"position": Vector2(cx, cy - 20),
					"type": "food_dispenser",
					"name": "Food Dispenser",
					"emoji": "\U0001F37D\uFE0F",
					"action": "eat_food",
				})
			RoomType.LAB:
				# Research terminal
				interactable_positions.append({
					"position": Vector2(cx, cy - 20),
					"type": "terminal",
					"name": "Research Terminal",
					"emoji": "\U0001F52C",
					"action": "research",
				})

func _place_decorations() -> void:
	decoration_positions.clear()
	
	for room in rooms:
		var x: int = room["position"].x
		var y: int = room["position"].y
		var w: int = room["size"].x
		var h: int = room["size"].y
		var room_type: int = room["type"]
		
		# Room label
		decoration_positions.append({
			"position": Vector2((x + w / 2.0) * TILE_SIZE, (y + 1) * TILE_SIZE),
			"emoji": room.get("emoji", ""),
			"text": room.get("name", ""),
			"type": "room_label",
		})
		
		# Room-specific decorations
		match room_type:
			RoomType.BRIDGE:
				# Viewscreen at top
				decoration_positions.append({
					"position": Vector2((x + w / 2.0) * TILE_SIZE, y * TILE_SIZE + 16),
					"emoji": "\U0001F30D",
					"text": "",
					"type": "viewscreen",
				})
			RoomType.ENGINE_ROOM:
				# Power core
				decoration_positions.append({
					"position": Vector2((x + w / 2.0) * TILE_SIZE, (y + h / 2.0) * TILE_SIZE),
					"emoji": "\u2622\uFE0F",
					"text": "",
					"type": "power_core",
				})
			RoomType.HANGAR:
				# Ships
				decoration_positions.append({
					"position": Vector2((x + 3) * TILE_SIZE, (y + h / 2.0) * TILE_SIZE),
					"emoji": "\U0001F6F8",
					"text": "",
					"type": "shuttle",
				})

func _place_starting_items() -> void:
	item_positions.clear()
	
	# Place some starter items in the armory
	for room in rooms:
		if room["type"] == RoomType.ARMORY:
			var rx: float = room["position"].x * TILE_SIZE
			var ry: float = room["position"].y * TILE_SIZE
			var rw: float = room["size"].x * TILE_SIZE
			var rh: float = room["size"].y * TILE_SIZE
			
			item_positions.append({"position": Vector2(rx + 30, ry + rh - 30), "type": "health_potion"})
			item_positions.append({"position": Vector2(rx + 60, ry + rh - 30), "type": "health_potion"})
			item_positions.append({"position": Vector2(rx + rw - 30, ry + rh - 30), "type": "speed_boost"})
			break
	
	# Place food in mess hall
	for room in rooms:
		if room["type"] == RoomType.MESS_HALL:
			var cx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var cy: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			item_positions.append({"position": Vector2(cx - 30, cy + 20), "type": "food_apple"})
			item_positions.append({"position": Vector2(cx + 30, cy + 20), "type": "food_meat"})
			break

func _place_lore() -> void:
	lore_positions.clear()
	
	# Ship logs on the bridge
	for room in rooms:
		if room["type"] == RoomType.BRIDGE:
			var cx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var cy: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			lore_positions.append({
				"position": Vector2(cx - 50, cy),
				"type": "tablet",
				"category": "world",
			})
			break
	
	# Research notes in lab
	for room in rooms:
		if room["type"] == RoomType.LAB:
			var cx: float = (room["position"].x + room["size"].x / 2.0) * TILE_SIZE
			var cy: float = (room["position"].y + room["size"].y / 2.0) * TILE_SIZE
			lore_positions.append({
				"position": Vector2(cx + 40, cy + 20),
				"type": "journal",
				"category": "personal",
			})
			break

func _set_spawn_position() -> void:
	# Player spawns in the bridge
	if rooms.size() > 0:
		var bridge := rooms[0]
		spawn_position = Vector2(
			(bridge["position"].x + bridge["size"].x / 2.0) * TILE_SIZE,
			(bridge["position"].y + bridge["size"].y / 2.0) * TILE_SIZE
		)

# ===== UTILITY =====

func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT:
		return TILE_VOID
	return tiles[y][x]

func is_floor(x: int, y: int) -> bool:
	return get_tile(x, y) == TILE_FLOOR

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0, tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0)

func get_room_at(world_pos: Vector2) -> Dictionary:
	var tp := world_to_tile(world_pos)
	for room in rooms:
		var rp: Vector2i = room["position"]
		var rs: Vector2i = room["size"]
		if tp.x >= rp.x and tp.x < rp.x + rs.x and tp.y >= rp.y and tp.y < rp.y + rs.y:
			return room
	return {}

func get_rooms_by_type(room_type: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room in rooms:
		if room["type"] == room_type:
			result.append(room)
	return result
