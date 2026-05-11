-- Dungeon Renderer - Renders procedural dungeon in workspace
local DungeonRenderer = {}
DungeonRenderer.__index = DungeonRenderer

function DungeonRenderer.new(dungeon_data)
	local self = setmetatable({}, DungeonRenderer)
	
	self.dungeon_data = dungeon_data
	self.tile_size = dungeon_data.tiles and 10 or 10
	self.wall_height = 5
	self.dungeon_folder = nil
	
	return self
end

function DungeonRenderer:render()
	-- Create dungeon folder
	self.dungeon_folder = Instance.new("Folder")
	self.dungeon_folder.Name = "Dungeon"
	self.dungeon_folder.Parent = workspace
	
	-- Render floor and walls
	self:_render_tiles()
	
	-- Render room features
	self:_render_rooms()
	
	print("[DungeonRenderer] Dungeon rendered with", #self.dungeon_data.rooms, "rooms")
end

function DungeonRenderer:_render_tiles()
	local tiles_folder = Instance.new("Folder")
	tiles_folder.Name = "Tiles"
	tiles_folder.Parent = self.dungeon_folder
	
	for x = 1, 100 do
		for z = 1, 100 do
			if self.dungeon_data.tiles[x] and self.dungeon_data.tiles[x][z] == 1 then
				self:_create_floor_tile(x, z, tiles_folder)
				self:_create_walls(x, z, tiles_folder)
			end
		end
	end
end

function DungeonRenderer:_create_floor_tile(x, z, parent)
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Shape = Enum.PartType.Block
	floor.Size = Vector3.new(self.tile_size, 0.5, self.tile_size)
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Material = Enum.Material.Concrete
	floor.Color = Color3.fromRGB(100, 100, 100)
	floor.CanCollide = true
	floor.CFrame = CFrame.new(
		(x - 0.5) * self.tile_size,
		0.25,
		(z - 0.5) * self.tile_size
	)
	floor.Parent = parent
end

function DungeonRenderer:_create_walls(x, z, parent)
	local tile_size = self.tile_size
	local wall_height = self.wall_height
	
	-- Check adjacent tiles
	local neighbors = {
		{dx = -1, dz = 0},
		{dx = 1, dz = 0},
		{dx = 0, dz = -1},
		{dx = 0, dz = 1},
	}
	
	for _, neighbor in ipairs(neighbors) do
		local nx = x + neighbor.dx
		local nz = z + neighbor.dz
		
		local is_wall = not (self.dungeon_data.tiles[nx] and self.dungeon_data.tiles[nx][nz] == 1)
		
		if is_wall then
			self:_create_wall_segment(x, z, neighbor.dx, neighbor.dz, parent)
		end
	end
end

function DungeonRenderer:_create_wall_segment(x, z, dx, dz, parent)
	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Shape = Enum.PartType.Block
	wall.Material = Enum.Material.Brick
	wall.Color = Color3.fromRGB(80, 80, 80)
	wall.CanCollide = true
	
	local tile_size = self.tile_size
	local wall_height = self.wall_height
	
	if dx ~= 0 then
		wall.Size = Vector3.new(0.5, wall_height, tile_size)
		wall.CFrame = CFrame.new(
			(x - 0.5 + dx * 0.5) * tile_size,
			wall_height / 2,
			(z - 0.5) * tile_size
		)
	else
		wall.Size = Vector3.new(tile_size, wall_height, 0.5)
		wall.CFrame = CFrame.new(
			(x - 0.5) * tile_size,
			wall_height / 2,
			(z - 0.5 + dz * 0.5) * tile_size
		)
	end
	
	wall.Parent = parent
end

function DungeonRenderer:_render_rooms()
	local rooms_folder = Instance.new("Folder")
	rooms_folder.Name = "Rooms"
	rooms_folder.Parent = self.dungeon_folder
	
	for i, room in ipairs(self.dungeon_data.rooms) do
		local room_folder = Instance.new("Folder")
		room_folder.Name = "Room_" .. i
		room_folder.Parent = rooms_folder
		
		-- Create room marker
		local marker = Instance.new("Part")
		marker.Name = "RoomMarker"
		marker.Shape = Enum.PartType.Ball
		marker.Size = Vector3.new(1, 1, 1)
		marker.Color = Color3.fromRGB(100, 200, 100)
		marker.Material = Enum.Material.Neon
		marker.CanCollide = false
		marker.CFrame = CFrame.new(
			room.center_x * self.tile_size,
			1,
			room.center_z * self.tile_size
		)
		marker.Parent = room_folder
	end
end

function DungeonRenderer:cleanup()
	if self.dungeon_folder then
		self.dungeon_folder:Destroy()
	end
end

return DungeonRenderer
