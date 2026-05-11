-- Dungeon Generator - Procedural 3D dungeon creation
local DungeonGenerator = {}
DungeonGenerator.__index = DungeonGenerator

local TILE_SIZE = 10
local ROOM_MIN_SIZE = 3
local ROOM_MAX_SIZE = 8
local NUM_ROOMS = 15
local CORRIDOR_WIDTH = 2
local WALL_HEIGHT = 5

function DungeonGenerator.new(seed)
	local self = setmetatable({}, DungeonGenerator)
	
	self.seed = seed or math.random(1, 999999)
	self.rng = Random.new(self.seed)
	
	self.tiles = {}
	self.rooms = {}
	self.corridors = {}
	self.spawn_position = Vector3.new(0, 0, 0)
	self.enemy_spawn_points = {}
	self.item_spawn_points = {}
	self.trap_positions = {}
	
	return self
end

function DungeonGenerator:generate()
	self:_init_tiles()
	self:_place_rooms()
	self:_create_corridors()
	self:_place_features()
	
	return {
		tiles = self.tiles,
		rooms = self.rooms,
		corridors = self.corridors,
		spawn_position = self.spawn_position,
		enemy_spawn_points = self.enemy_spawn_points,
		item_spawn_points = self.item_spawn_points,
		trap_positions = self.trap_positions,
	}
end

function DungeonGenerator:_init_tiles()
	local width = 100
	local height = 100
	
	for x = 1, width do
		self.tiles[x] = {}
		for z = 1, height do
			self.tiles[x][z] = 0
		end
	end
end

function DungeonGenerator:_place_rooms()
	for _ = 1, NUM_ROOMS do
		local width = self.rng:NextInteger(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		local height = self.rng:NextInteger(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
		local x = self.rng:NextInteger(1, 100 - width)
		local z = self.rng:NextInteger(1, 100 - height)
		
		local room = {
			x = x,
			z = z,
			width = width,
			height = height,
			center_x = x + math.floor(width / 2),
			center_z = z + math.floor(height / 2),
		}
		
		if self:_can_place_room(room) then
			self:_carve_room(room)
			table.insert(self.rooms, room)
		end
	end
	
	if #self.rooms > 0 then
		self.spawn_position = Vector3.new(
			self.rooms[1].center_x * TILE_SIZE,
			2,
			self.rooms[1].center_z * TILE_SIZE
		)
	end
end

function DungeonGenerator:_can_place_room(room)
	for x = room.x - 1, room.x + room.width do
		for z = room.z - 1, room.z + room.height do
			if x < 1 or x > 100 or z < 1 or z > 100 then
				return false
			end
			if self.tiles[x] and self.tiles[x][z] and self.tiles[x][z] == 1 then
				return false
			end
		end
	end
	return true
end

function DungeonGenerator:_carve_room(room)
	for x = room.x, room.x + room.width - 1 do
		for z = room.z, room.z + room.height - 1 do
			self.tiles[x][z] = 1
		end
	end
end

function DungeonGenerator:_create_corridors()
	for i = 1, #self.rooms - 1 do
		local room1 = self.rooms[i]
		local room2 = self.rooms[i + 1]
		
		self:_carve_corridor(room1.center_x, room1.center_z, room2.center_x, room2.center_z)
	end
end

function DungeonGenerator:_carve_corridor(x1, z1, x2, z2)
	local current_x = x1
	local current_z = z1
	
	while current_x ~= x2 do
		self:_carve_tile(current_x, current_z)
		current_x = current_x + (current_x < x2 and 1 or -1)
	end
	
	while current_z ~= z2 do
		self:_carve_tile(current_x, current_z)
		current_z = current_z + (current_z < z2 and 1 or -1)
	end
end

function DungeonGenerator:_carve_tile(x, z)
	if x >= 1 and x <= 100 and z >= 1 and z <= 100 then
		self.tiles[x][z] = 1
	end
end

function DungeonGenerator:_place_features()
	for _, room in ipairs(self.rooms) do
		local feature_type = self.rng:NextInteger(1, 3)
		
		if feature_type == 1 then
			table.insert(self.enemy_spawn_points, {
				x = room.center_x * TILE_SIZE,
				z = room.center_z * TILE_SIZE,
				room = room,
			})
		elseif feature_type == 2 then
			table.insert(self.item_spawn_points, {
				x = room.center_x * TILE_SIZE,
				z = room.center_z * TILE_SIZE,
				room = room,
			})
		else
			table.insert(self.trap_positions, {
				x = room.center_x * TILE_SIZE,
				z = room.center_z * TILE_SIZE,
				room = room,
			})
		end
	end
end

function DungeonGenerator:get_tile_size()
	return TILE_SIZE
end

function DungeonGenerator:get_wall_height()
	return WALL_HEIGHT
end

function DungeonGenerator:is_walkable(x, z)
	local tile_x = math.floor(x / TILE_SIZE) + 1
	local tile_z = math.floor(z / TILE_SIZE) + 1
	
	if tile_x < 1 or tile_x > 100 or tile_z < 1 or tile_z > 100 then
		return false
	end
	
	return self.tiles[tile_x] and self.tiles[tile_x][tile_z] == 1
end

return DungeonGenerator
