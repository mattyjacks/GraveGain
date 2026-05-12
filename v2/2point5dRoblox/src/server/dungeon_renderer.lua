local DungeonDecorator = require(script.Parent:WaitForChild("dungeon_decorator"))

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

	self.decorator = DungeonDecorator.new(self)
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
	self.decorator:renderDecorations(folder)
	self.decorator:renderLoot(folder)
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
					self.decorator:addFlowerOrDetail(x, y, floorFolder)
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
						self.decorator:addVine(x, y, wallFolder)
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
