local DungeonRenderer = {}
DungeonRenderer.__index = DungeonRenderer

local TILE = 4
local WALL_HEIGHT = 6
local FLOOR_THICKNESS = 1
local SUB_LAYERS = 3

local BIOME_PALETTES = {
	Crypt = {
		floor = {
			{Color3.fromRGB(34, 139, 34), Enum.Material.Grass},
			{Color3.fromRGB(50, 160, 50), Enum.Material.Grass},
			{Color3.fromRGB(80, 180, 40), Enum.Material.LeafyGrass},
		},
		corridor = {
			{Color3.fromRGB(139, 119, 83), Enum.Material.Cobblestone},
			{Color3.fromRGB(160, 140, 100), Enum.Material.Cobblestone},
		},
		wall = {
			{Color3.fromRGB(60, 60, 60), Enum.Material.Slate},
			{Color3.fromRGB(75, 75, 75), Enum.Material.Basalt},
			{Color3.fromRGB(50, 50, 60), Enum.Material.Rock},
		},
		wallTop = {
			{Color3.fromRGB(34, 100, 34), Enum.Material.Grass},
			{Color3.fromRGB(20, 80, 20), Enum.Material.LeafyGrass},
		},
		accent = {
			{Color3.fromRGB(255, 200, 0), Enum.Material.Neon},
			{Color3.fromRGB(0, 200, 255), Enum.Material.Neon},
			{Color3.fromRGB(180, 50, 255), Enum.Material.Neon},
		},
		sub = {
			{Color3.fromRGB(101, 67, 33), Enum.Material.Ground},
			{Color3.fromRGB(80, 50, 25), Enum.Material.Ground},
			{Color3.fromRGB(60, 40, 20), Enum.Material.Rock},
		},
	}
}

function DungeonRenderer.new(dungeon, parent)
	local self = setmetatable({}, DungeonRenderer)
	self.dungeon = dungeon
	self.parent = parent or workspace
	self.biome = dungeon.biome or "Crypt"
	self.palette = BIOME_PALETTES[self.biome] or BIOME_PALETTES.Crypt
	self.rng = Random.new(dungeon.seed or tick())

	local existing = self.parent:FindFirstChild("Dungeon")
	if existing then existing:Destroy() end

	self:renderDungeon()
	return self
end

function DungeonRenderer:pick(list)
	return list[self.rng:NextInteger(1, #list)]
end

function DungeonRenderer:renderDungeon()
	local folder = Instance.new("Folder")
	folder.Name = "Dungeon"
	folder.Parent = self.parent

	self.folder = folder
	self:renderSubLayers(folder)
	self:renderFloor(folder)
	self:renderWalls(folder)
	self:renderDecorations(folder)
	self:renderLighting(folder)
end

function DungeonRenderer:renderSubLayers(parent)
	local sub = Instance.new("Folder")
	sub.Name = "SubLayers"
	sub.Parent = parent

	for layer = 1, SUB_LAYERS do
		local yPos = -layer * FLOOR_THICKNESS
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Block
		part.Size = Vector3.new(self.dungeon.width * TILE, FLOOR_THICKNESS, self.dungeon.height * TILE)
		part.Anchored = true
		part.CanCollide = true
		local pick = self:pick(self.palette.sub)
		part.Color = pick[1]
		part.Material = pick[2]
		part.CFrame = CFrame.new(
			(self.dungeon.width / 2) * TILE,
			yPos - FLOOR_THICKNESS / 2,
			(self.dungeon.height / 2) * TILE
		)
		part.Parent = sub
	end
end

function DungeonRenderer:renderFloor(parent)
	local floorFolder = Instance.new("Folder")
	floorFolder.Name = "Floor"
	floorFolder.Parent = parent

	for x = 1, self.dungeon.width do
		for y = 1, self.dungeon.height do
			local tile = self.dungeon:getTile(x, y)
			if tile and tile.walkable then
				local part = Instance.new("Part")
				part.Shape = Enum.PartType.Block
				part.Anchored = true
				part.Size = Vector3.new(TILE, FLOOR_THICKNESS, TILE)
				part.CanCollide = true
				part.TopSurface = Enum.SurfaceType.Smooth
				part.BottomSurface = Enum.SurfaceType.Smooth

				local pick
				if tile.type == "corridor" then
					pick = self:pick(self.palette.corridor)
				else
					pick = self:pick(self.palette.floor)
				end
				part.Color = pick[1]
				part.Material = pick[2]
				part.CFrame = CFrame.new(x * TILE, -FLOOR_THICKNESS / 2, y * TILE)
				part.Parent = floorFolder

				if self.rng:NextNumber() < 0.03 then
					self:addFlowerOrDetail(x, y, floorFolder)
				end
			end
		end
	end
end

function DungeonRenderer:renderWalls(parent)
	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "Walls"
	wallFolder.Parent = parent

	for x = 1, self.dungeon.width do
		for y = 1, self.dungeon.height do
			local tile = self.dungeon:getTile(x, y)
			if tile and not tile.walkable then
				local adjacentWalkable = self:hasAdjacentWalkable(x, y)
				if adjacentWalkable then
					local wallPick = self:pick(self.palette.wall)
					local wall = Instance.new("Part")
					wall.Shape = Enum.PartType.Block
					wall.Anchored = true
					wall.Size = Vector3.new(TILE, WALL_HEIGHT, TILE)
					wall.CanCollide = true
					wall.Color = wallPick[1]
					wall.Material = wallPick[2]
					wall.CFrame = CFrame.new(x * TILE, WALL_HEIGHT / 2, y * TILE)
					wall.Parent = wallFolder

					local topPick = self:pick(self.palette.wallTop)
					local top = Instance.new("Part")
					top.Shape = Enum.PartType.Block
					top.Anchored = true
					top.Size = Vector3.new(TILE, 0.5, TILE)
					top.CanCollide = true
					top.Color = topPick[1]
					top.Material = topPick[2]
					top.CFrame = CFrame.new(x * TILE, WALL_HEIGHT + 0.25, y * TILE)
					top.Parent = wallFolder

					if self.rng:NextNumber() < 0.08 then
						self:addVine(x, y, wallFolder)
					end
				end
			end
		end
	end
end

function DungeonRenderer:hasAdjacentWalkable(x, y)
	local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
	for _, d in ipairs(dirs) do
		local nx, ny = x + d[1], y + d[2]
		if nx >= 1 and nx <= self.dungeon.width and ny >= 1 and ny <= self.dungeon.height then
			local t = self.dungeon:getTile(nx, ny)
			if t and t.walkable then return true end
		end
	end
	return false
end

function DungeonRenderer:addFlowerOrDetail(x, y, parent)
	local flower = Instance.new("Part")
	flower.Shape = Enum.PartType.Ball
	flower.Anchored = true
	flower.CanCollide = false
	flower.Size = Vector3.new(0.6, 0.6, 0.6)
	local colors = {
		Color3.fromRGB(255, 50, 50),
		Color3.fromRGB(255, 255, 50),
		Color3.fromRGB(255, 100, 200),
		Color3.fromRGB(100, 200, 255),
		Color3.fromRGB(255, 150, 0),
	}
	flower.Color = colors[self.rng:NextInteger(1, #colors)]
	flower.Material = Enum.Material.SmoothPlastic
	local ox = (self.rng:NextNumber() - 0.5) * TILE * 0.7
	local oz = (self.rng:NextNumber() - 0.5) * TILE * 0.7
	flower.CFrame = CFrame.new(x * TILE + ox, 0.3, y * TILE + oz)
	flower.Parent = parent
end

function DungeonRenderer:addVine(x, y, parent)
	local vine = Instance.new("Part")
	vine.Shape = Enum.PartType.Block
	vine.Anchored = true
	vine.CanCollide = false
	local h = self.rng:NextNumber() * 3 + 1
	vine.Size = Vector3.new(0.4, h, 0.4)
	vine.Color = Color3.fromRGB(20, 120 + self.rng:NextInteger(0, 40), 20)
	vine.Material = Enum.Material.Grass
	local side = self.rng:NextInteger(1, 4)
	local ox, oz = 0, 0
	if side == 1 then ox = TILE / 2 - 0.2
	elseif side == 2 then ox = -TILE / 2 + 0.2
	elseif side == 3 then oz = TILE / 2 - 0.2
	else oz = -TILE / 2 + 0.2 end
	vine.CFrame = CFrame.new(x * TILE + ox, WALL_HEIGHT - h / 2, y * TILE + oz)
	vine.Parent = parent
end

function DungeonRenderer:renderDecorations(parent)
	local decoFolder = Instance.new("Folder")
	decoFolder.Name = "Decorations"
	decoFolder.Parent = parent

	for i, room in ipairs(self.dungeon.rooms) do
		if self.rng:NextNumber() < 0.6 then
			self:addTorch(room.centerX, room.centerY, decoFolder)
		end

		if self.rng:NextNumber() < 0.3 then
			self:addCrystal(room, decoFolder)
		end

		if self.rng:NextNumber() < 0.4 then
			self:addWaterPool(room, decoFolder)
		end
	end
end

function DungeonRenderer:addTorch(x, y, parent)
	local pole = Instance.new("Part")
	pole.Shape = Enum.PartType.Cylinder
	pole.Anchored = true
	pole.CanCollide = false
	pole.Size = Vector3.new(3, 0.3, 0.3)
	pole.Color = Color3.fromRGB(101, 67, 33)
	pole.Material = Enum.Material.Wood
	pole.CFrame = CFrame.new(x * TILE, 1.5, y * TILE) * CFrame.Angles(0, 0, math.rad(90))
	pole.Parent = parent

	local flame = Instance.new("Part")
	flame.Shape = Enum.PartType.Ball
	flame.Anchored = true
	flame.CanCollide = false
	flame.Size = Vector3.new(0.8, 0.8, 0.8)
	flame.Color = Color3.fromRGB(255, 150, 0)
	flame.Material = Enum.Material.Neon
	flame.CFrame = CFrame.new(x * TILE, 3.2, y * TILE)
	flame.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 50)
	light.Brightness = 2
	light.Range = 20
	light.Parent = flame
end

function DungeonRenderer:addCrystal(room, parent)
	local cx = room.x + self.rng:NextInteger(1, math.max(1, room.width - 1))
	local cy = room.y + self.rng:NextInteger(1, math.max(1, room.height - 1))

	local crystal = Instance.new("Part")
	crystal.Shape = Enum.PartType.Block
	crystal.Anchored = true
	crystal.CanCollide = false
	local h = self.rng:NextNumber() * 2 + 1
	crystal.Size = Vector3.new(0.6, h, 0.6)
	local pick = self:pick(self.palette.accent)
	crystal.Color = pick[1]
	crystal.Material = pick[2]
	crystal.CFrame = CFrame.new(cx * TILE, h / 2, cy * TILE) * CFrame.Angles(
		math.rad(self.rng:NextNumber() * 20 - 10),
		math.rad(self.rng:NextNumber() * 360),
		math.rad(self.rng:NextNumber() * 20 - 10)
	)
	crystal.Parent = parent

	local glow = Instance.new("PointLight")
	glow.Color = pick[1]
	glow.Brightness = 0.7
	glow.Range = 6
	glow.Parent = crystal
end

function DungeonRenderer:addWaterPool(room, parent)
	local px = room.x + self.rng:NextInteger(1, math.max(1, room.width - 2))
	local py = room.y + self.rng:NextInteger(1, math.max(1, room.height - 2))
	local w = self.rng:NextInteger(2, math.min(4, room.width - 1))
	local h = self.rng:NextInteger(2, math.min(4, room.height - 1))

	local pool = Instance.new("Part")
	pool.Shape = Enum.PartType.Block
	pool.Anchored = true
	pool.CanCollide = false
	pool.Size = Vector3.new(w * TILE * 0.5, 0.3, h * TILE * 0.5)
	pool.Color = Color3.fromRGB(30, 120, 200)
	pool.Material = Enum.Material.Glass
	pool.Transparency = 0.4
	pool.CFrame = CFrame.new(px * TILE, -0.1, py * TILE)
	pool.Parent = parent
end

function DungeonRenderer:renderLighting(parent)
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(100, 100, 120)
	lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 120)
	lighting.Brightness = 0.7
	lighting.ClockTime = 0
	lighting.FogEnd = 400
	lighting.FogColor = Color3.fromRGB(40, 40, 60)
end

return DungeonRenderer
