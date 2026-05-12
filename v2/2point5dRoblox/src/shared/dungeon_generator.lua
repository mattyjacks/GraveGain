local GameData = require(script.Parent:WaitForChild("game_data"))
local DungeonLootManager = require(script.Parent:WaitForChild("dungeon_loot_manager"))

local DungeonGenerator = {}
DungeonGenerator.__index = DungeonGenerator

function DungeonGenerator.new(seed, biome, floor)
	local self = setmetatable({}, DungeonGenerator)
	
	math.randomseed(seed)
	self.seed = seed
	self.biome = biome or "Crypt"
	self.floor = floor or 1
	self.width = 100
	self.height = 100
	self.tiles = {}
	self.rooms = {}
	self.enemies = {}
	self.loot = {}
	
	self:generateDungeon()
	
	return self
end

function DungeonGenerator:generateDungeon()
	self:initializeTiles()
	self:generateRooms()
	self:connectRooms()
	self:placeEnemies()
	
	self.lootManager = DungeonLootManager.new(self)
	self.lootManager:placeLoot()
	self.lootManager:placeAmmoCrates()
	self.lootManager:placeLoreItems()
end

function DungeonGenerator:initializeTiles()
	for x = 1, self.width do
		self.tiles[x] = {}
		for y = 1, self.height do
			self.tiles[x][y] = {
				type = "wall",
				walkable = false,
				enemy = nil,
				loot = nil,
			}
		end
	end
end

function DungeonGenerator:generateRooms()
	local config = GameData.DUNGEON_CONFIG
	-- Grid based layout
	local gridSizeX = 4
	local gridSizeY = 4
	local cellWidth = math.floor(self.width / gridSizeX)
	local cellHeight = math.floor(self.height / gridSizeY)
	
	-- We always start at (1, 1) in the grid for the entrance
	for gridX = 0, gridSizeX - 1 do
		for gridY = 0, gridSizeY - 1 do
			-- 70% chance to have a room in this cell, except (0,0) which is guaranteed
			if (gridX == 0 and gridY == 0) or math.random() < 0.7 then
				local roomWidth = config.minRoomWidth + math.random(config.maxRoomWidth - config.minRoomWidth)
				local roomHeight = config.minRoomHeight + math.random(config.maxRoomHeight - config.minRoomHeight)
				
				local minX = gridX * cellWidth + 2
				local maxX = (gridX + 1) * cellWidth - roomWidth - 2
				local minY = gridY * cellHeight + 2
				local maxY = (gridY + 1) * cellHeight - roomHeight - 2
				
				if maxX > minX and maxY > minY then
					local x = math.random(minX, maxX)
					local y = math.random(minY, maxY)
					
					local isCave = math.random() < 0.3 -- 30% chance for a natural cave part
					
					local room = {
						x = x,
						y = y,
						width = roomWidth,
						height = roomHeight,
						centerX = x + roomWidth / 2,
						centerY = y + roomHeight / 2,
						isCave = isCave,
						gridX = gridX,
						gridY = gridY
					}
					
					if self:canPlaceRoom(room) then
						if isCave then
							self:carveCaveRoom(room)
						else
							self:carveRoom(room)
						end
						table.insert(self.rooms, room)
					end
				end
			end
		end
	end
end

function DungeonGenerator:carveCaveRoom(room)
	-- Cellular Automata approach for this local room
	local map = {}
	for x = 0, room.width - 1 do
		map[x] = {}
		for y = 0, room.height - 1 do
			map[x][y] = math.random() > 0.45 and 1 or 0 -- 1 is wall, 0 is floor
		end
	end
	
	-- Smoothing
	for step = 1, 4 do
		local newMap = {}
		for x = 0, room.width - 1 do
			newMap[x] = {}
			for y = 0, room.height - 1 do
				local neighbors = 0
				for dx = -1, 1 do
					for dy = -1, 1 do
						local nx, ny = x + dx, y + dy
						if nx < 0 or nx >= room.width or ny < 0 or ny >= room.height then
							neighbors = neighbors + 1
						elseif map[nx][ny] == 1 then
							neighbors = neighbors + 1
						end
					end
				end
				newMap[x][y] = neighbors > 4 and 1 or 0
			end
		end
		map = newMap
	end
	
	for x = 1, room.width - 2 do
		for y = 1, room.height - 2 do
			if map[x][y] == 0 then
				local tx = room.x + x
				local ty = room.y + y
				if tx > 0 and tx <= self.width and ty > 0 and ty <= self.height then
					self.tiles[tx][ty].type = "floor"
					self.tiles[tx][ty].walkable = true
				end
			end
		end
	end
	
	-- Ensure center is clear for connections
	self.tiles[math.floor(room.centerX)][math.floor(room.centerY)].type = "floor"
	self.tiles[math.floor(room.centerX)][math.floor(room.centerY)].walkable = true
end

function DungeonGenerator:canPlaceRoom(room)
	return true -- Grid guarantees no overlap if configured properly
end

function DungeonGenerator:carveRoom(room)
	for x = room.x, room.x + room.width - 1 do
		for y = room.y, room.y + room.height - 1 do
			if x > 0 and x <= self.width and y > 0 and y <= self.height then
				self.tiles[x][y].type = "floor"
				self.tiles[x][y].walkable = true
			end
		end
	end
end

function DungeonGenerator:connectRooms()
	if #self.rooms < 2 then return end
	
	-- Sort rooms by grid position to ensure logical connections
	table.sort(self.rooms, function(a, b)
		if a.gridX == b.gridX then
			return a.gridY < b.gridY
		end
		return a.gridX < b.gridX
	end)
	
	for i = 1, #self.rooms - 1 do
		local room1 = self.rooms[i]
		local room2 = self.rooms[i + 1]
		
		-- Connect L-shape to avoid messy diagonals
		if math.random() > 0.5 then
			self:carveCorridor(room1.centerX, room1.centerY, room2.centerX, room1.centerY)
			self:carveCorridor(room2.centerX, room1.centerY, room2.centerX, room2.centerY)
		else
			self:carveCorridor(room1.centerX, room1.centerY, room1.centerX, room2.centerY)
			self:carveCorridor(room1.centerX, room2.centerY, room2.centerX, room2.centerY)
		end
	end
end

function DungeonGenerator:carveCorridor(x1, y1, x2, y2)
	local config = GameData.DUNGEON_CONFIG
	local corridorWidth = config.corridorWidth
	
	local startX = math.min(math.floor(x1), math.floor(x2))
	local endX = math.max(math.floor(x1), math.floor(x2))
	local startY = math.min(math.floor(y1), math.floor(y2))
	local endY = math.max(math.floor(y1), math.floor(y2))
	
	for x = startX - corridorWidth, endX + corridorWidth do
		for y = startY - corridorWidth, endY + corridorWidth do
			if x > 0 and x <= self.width and y > 0 and y <= self.height then
				if self.tiles[x][y].type == "wall" then
					self.tiles[x][y].type = "corridor"
					self.tiles[x][y].walkable = true
				end
			end
		end
	end
end

function DungeonGenerator:placeEnemies()
	local difficultyMult = GameData.DIFFICULTIES[GameData.DIFFICULTIES.Normal and "Normal" or "Normal"].multiplier
	local numEnemies = 5 + self.floor + math.random(3)
	numEnemies = math.floor(numEnemies * difficultyMult)
	
	local enemyTypes = { "Skeleton", "Zombie", "Spider", "Goblin" }
	if self.floor > 2 then table.insert(enemyTypes, "Demon") end
	
	for i = 1, numEnemies do
		local x, y = self:findRandomWalkableTile()
		if x and y then
			local enemyType = enemyTypes[math.random(#enemyTypes)]
			local enemyData = GameData.ENEMY_TYPES[enemyType]
			
			table.insert(self.enemies, {
				type = enemyType,
				x = x,
				y = y,
				health = enemyData.health * (1 + self.floor * 0.2),
				maxHealth = enemyData.health * (1 + self.floor * 0.2),
				damage = enemyData.damage * (1 + self.floor * 0.1),
				xp = enemyData.xp * (1 + self.floor * 0.1),
			})
		end
	end
	
	if self.floor % 3 == 0 then
		local x, y = self:findRandomWalkableTile()
		if x and y then
			table.insert(self.enemies, {
				type = "Boss",
				x = x,
				y = y,
				health = 100 * (1 + self.floor * 0.5),
				maxHealth = 100 * (1 + self.floor * 0.5),
				damage = 10 * (1 + self.floor * 0.2),
				xp = 500 * (1 + self.floor * 0.2),
				isBoss = true,
			})
		end
	end
end

function DungeonGenerator:findRandomWalkableTile()
	local attempts = 0
	while attempts < 100 do
		local x = math.random(1, self.width)
		local y = math.random(1, self.height)
		
		if self.tiles[x][y].walkable and not self.tiles[x][y].enemy and not self.tiles[x][y].loot then
			return x, y
		end
		
		attempts = attempts + 1
	end
	return nil, nil
end

function DungeonGenerator:getTile(x, y)
	if x > 0 and x <= self.width and y > 0 and y <= self.height then
		return self.tiles[x][y]
	end
	return nil
end

function DungeonGenerator:isWalkable(x, y)
	local tile = self:getTile(x, y)
	return tile and tile.walkable
end

return DungeonGenerator
