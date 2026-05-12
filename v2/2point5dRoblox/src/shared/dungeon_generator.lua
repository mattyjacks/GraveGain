local GameData = require(script.Parent:WaitForChild("game_data"))

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
	self:placeLoot()
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
	local numRooms = 8 + math.random(4)
	
	for i = 1, numRooms do
		local width = config.minRoomWidth + math.random(config.maxRoomWidth - config.minRoomWidth)
		local height = config.minRoomHeight + math.random(config.maxRoomHeight - config.minRoomHeight)
		local x = math.random(1, self.width - width - 1)
		local y = math.random(1, self.height - height - 1)
		
		local room = {
			x = x,
			y = y,
			width = width,
			height = height,
			centerX = x + width / 2,
			centerY = y + height / 2,
		}
		
		if self:canPlaceRoom(room) then
			self:carveRoom(room)
			table.insert(self.rooms, room)
		end
	end
end

function DungeonGenerator:canPlaceRoom(room)
	local padding = 3
	for x = room.x - padding, room.x + room.width + padding do
		for y = room.y - padding, room.y + room.height + padding do
			if x > 0 and x <= self.width and y > 0 and y <= self.height then
				if self.tiles[x][y].type ~= "wall" then
					return false
				end
			end
		end
	end
	return true
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
	
	for i = 1, #self.rooms - 1 do
		local room1 = self.rooms[i]
		local room2 = self.rooms[i + 1]
		
		self:carveCorridor(room1.centerX, room1.centerY, room2.centerX, room2.centerY)
	end
end

function DungeonGenerator:carveCorridor(x1, y1, x2, y2)
	local config = GameData.DUNGEON_CONFIG
	local corridorWidth = config.corridorWidth
	
	local currentX = math.floor(x1)
	local currentY = math.floor(y1)
	local targetX = math.floor(x2)
	local targetY = math.floor(y2)
	
	local maxIterations = 1000
	local iterations = 0
	
	while (currentX ~= targetX or currentY ~= targetY) and iterations < maxIterations do
		iterations = iterations + 1
		
		if currentX < targetX then
			currentX = currentX + 1
		elseif currentX > targetX then
			currentX = currentX - 1
		end
		
		if currentY < targetY then
			currentY = currentY + 1
		elseif currentY > targetY then
			currentY = currentY - 1
		end
		
		for dx = -corridorWidth, corridorWidth do
			for dy = -corridorWidth, corridorWidth do
				local tx = currentX + dx
				local ty = currentY + dy
				if tx > 0 and tx <= self.width and ty > 0 and ty <= self.height then
					if self.tiles[tx] and self.tiles[tx][ty] and self.tiles[tx][ty].type == "wall" then
						self.tiles[tx][ty].type = "corridor"
						self.tiles[tx][ty].walkable = true
					end
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

function DungeonGenerator:placeLoot()
	local numLoot = 3 + math.random(3)
	
	for i = 1, numLoot do
		local x, y = self:findRandomWalkableTile()
		if x and y then
			local rarity = math.random() > 0.7 and "rare" or (math.random() > 0.5 and "uncommon" or "common")
			
			table.insert(self.loot, {
				x = x,
				y = y,
				type = "weapon",
				rarity = rarity,
				value = 10 * (rarity == "common" and 1 or rarity == "uncommon" and 2 or 5),
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
