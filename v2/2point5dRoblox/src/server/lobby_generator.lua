local LobbyBookGenerator = require(script.Parent:WaitForChild("lobby_book_generator"))
local LobbyFurnitureGenerator = require(script.Parent:WaitForChild("lobby_furniture_generator"))

local LobbyGenerator = {}
LobbyGenerator.__index = LobbyGenerator

function LobbyGenerator.new(parent)
	local self = setmetatable({}, LobbyGenerator)
	self.parent = parent or workspace
	self.rng = Random.new(12345)
	return self
end

function LobbyGenerator:generateLobby()
	local existing = self.parent:FindFirstChild("Lobby")
	if existing then existing:Destroy() end

	local lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name = "Lobby"
	lobbyFolder.Parent = self.parent

	self:buildSpaceship(lobbyFolder)
	
	self.furnitureGenerator = LobbyFurnitureGenerator.new(self)
	self.furnitureGenerator:placeFurniture(lobbyFolder)
	
	self:setupLighting(lobbyFolder)
	
	self.bookGenerator = LobbyBookGenerator.new(self)
	self.bookGenerator:createBigBook(lobbyFolder, Vector3.new(0, 0, -30))

	return lobbyFolder
end

function LobbyGenerator:buildSpaceship(parent)
	local hull = Instance.new("Part")
	hull.Name = "HullFloor"
	hull.Shape = Enum.PartType.Block
	hull.Size = Vector3.new(100, 2, 100)
	hull.Color = Color3.fromRGB(50, 50, 70)
	hull.Material = Enum.Material.Metal
	hull.Anchored = true
	hull.CanCollide = true
	hull.TopSurface = Enum.SurfaceType.Smooth
	hull.BottomSurface = Enum.SurfaceType.Smooth
	hull.CFrame = CFrame.new(0, 0, 0)
	hull.Parent = parent

	local wallNorth = Instance.new("Part")
	wallNorth.Name = "WallNorth"
	wallNorth.Shape = Enum.PartType.Block
	wallNorth.Size = Vector3.new(100, 15, 2)
	wallNorth.Color = Color3.fromRGB(60, 60, 80)
	wallNorth.Material = Enum.Material.Metal
	wallNorth.Anchored = true
	wallNorth.CanCollide = true
	wallNorth.CFrame = CFrame.new(0, 7.5, -51)
	wallNorth.Parent = parent

	local wallSouth = Instance.new("Part")
	wallSouth.Name = "WallSouth"
	wallSouth.Shape = Enum.PartType.Block
	wallSouth.Size = Vector3.new(100, 15, 2)
	wallSouth.Color = Color3.fromRGB(60, 60, 80)
	wallSouth.Material = Enum.Material.Metal
	wallSouth.Anchored = true
	wallSouth.CanCollide = true
	wallSouth.CFrame = CFrame.new(0, 7.5, 51)
	wallSouth.Parent = parent

	local wallEast = Instance.new("Part")
	wallEast.Name = "WallEast"
	wallEast.Shape = Enum.PartType.Block
	wallEast.Size = Vector3.new(2, 15, 100)
	wallEast.Color = Color3.fromRGB(60, 60, 80)
	wallEast.Material = Enum.Material.Metal
	wallEast.Anchored = true
	wallEast.CanCollide = true
	wallEast.CFrame = CFrame.new(51, 7.5, 0)
	wallEast.Parent = parent

	local wallWest = Instance.new("Part")
	wallWest.Name = "WallWest"
	wallWest.Shape = Enum.PartType.Block
	wallWest.Size = Vector3.new(2, 15, 100)
	wallWest.Color = Color3.fromRGB(60, 60, 80)
	wallWest.Material = Enum.Material.Metal
	wallWest.Anchored = true
	wallWest.CanCollide = true
	wallWest.CFrame = CFrame.new(-51, 7.5, 0)
	wallWest.Parent = parent
end

function LobbyGenerator:setupLighting(parent)
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(120, 120, 140)
	lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 140)
	lighting.Brightness = 1
	lighting.ClockTime = 12
	lighting.FogEnd = 500
	lighting.FogColor = Color3.fromRGB(60, 60, 80)

	local light1 = Instance.new("PointLight")
	light1.Color = Color3.fromRGB(200, 200, 255)
	light1.Brightness = 2
	light1.Range = 40
	light1.Parent = parent
	local lightPart1 = Instance.new("Part")
	lightPart1.Shape = Enum.PartType.Ball
	lightPart1.Size = Vector3.new(1, 1, 1)
	lightPart1.CanCollide = false
	lightPart1.Anchored = true
	lightPart1.Transparency = 1
	lightPart1.CFrame = CFrame.new(-30, 10, -30)
	lightPart1.Parent = parent
	light1.Parent = lightPart1

	local light2 = Instance.new("PointLight")
	light2.Color = Color3.fromRGB(200, 200, 255)
	light2.Brightness = 2
	light2.Range = 40
	light2.Parent = parent
	local lightPart2 = Instance.new("Part")
	lightPart2.Shape = Enum.PartType.Ball
	lightPart2.Size = Vector3.new(1, 1, 1)
	lightPart2.CanCollide = false
	lightPart2.Anchored = true
	lightPart2.Transparency = 1
	lightPart2.CFrame = CFrame.new(30, 10, 30)
	lightPart2.Parent = parent
	light2.Parent = lightPart2
end

return LobbyGenerator
