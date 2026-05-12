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
	self:placeFurniture(lobbyFolder)
	self:setupLighting(lobbyFolder)

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

function LobbyGenerator:placeFurniture(parent)
	local furnitureFolder = Instance.new("Folder")
	furnitureFolder.Name = "Furniture"
	furnitureFolder.Parent = parent

	local dresserPositions = {
		Vector3.new(-20, 1, -20),
		Vector3.new(20, 1, -20),
		Vector3.new(-20, 1, 20),
		Vector3.new(20, 1, 20),
	}

	for i, pos in ipairs(dresserPositions) do
		self:createDresser(furnitureFolder, pos, i)
	end

	local spawnPad = Instance.new("Part")
	spawnPad.Name = "SpawnPad"
	spawnPad.Shape = Enum.PartType.Block
	spawnPad.Size = Vector3.new(10, 1, 10)
	spawnPad.Color = Color3.fromRGB(100, 150, 200)
	spawnPad.Material = Enum.Material.Neon
	spawnPad.Transparency = 0.3
	spawnPad.Anchored = true
	spawnPad.CanCollide = false
	spawnPad.CFrame = CFrame.new(0, 1, 0)
	spawnPad.Parent = furnitureFolder

	self:createPortalWall(furnitureFolder)
end

function LobbyGenerator:createPortalWall(parent)
	local portalFolder = Instance.new("Folder")
	portalFolder.Name = "Portals"
	portalFolder.Parent = parent

	local difficulties = {
		{name = "Beginner Dungeon", difficulty = "Beginner", color = Color3.fromRGB(100, 200, 100)},
		{name = "Easy Dungeon", difficulty = "Easy", color = Color3.fromRGB(100, 150, 255)},
		{name = "Normal Dungeon", difficulty = "Normal", color = Color3.fromRGB(200, 150, 100)},
		{name = "Hard Dungeon", difficulty = "Hard", color = Color3.fromRGB(255, 100, 100)},
		{name = "Nightmare Dungeon", difficulty = "Nightmare", color = Color3.fromRGB(150, 50, 200)},
	}

	local wallX = -45
	local baseY = 3
	local baseZ = 0
	local spacing = 8

	for i, diffData in ipairs(difficulties) do
		local portalZ = baseZ + (i - 3) * spacing
		self:createPortal(portalFolder, Vector3.new(wallX, baseY, portalZ), diffData)
	end
end

function LobbyGenerator:createPortal(parent, position, diffData)
	local portal = Instance.new("Model")
	portal.Name = diffData.difficulty .. "Portal"
	portal.Parent = parent

	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Block
	frame.Size = Vector3.new(0.5, 4, 4)
	frame.Color = diffData.color
	frame.Material = Enum.Material.Neon
	frame.Anchored = true
	frame.CanCollide = false
	frame.CFrame = CFrame.new(position)
	frame.Parent = portal

	local vortex = Instance.new("Part")
	vortex.Name = "Vortex"
	vortex.Shape = Enum.PartType.Ball
	vortex.Size = Vector3.new(3.5, 3.5, 3.5)
	vortex.Color = diffData.color
	vortex.Material = Enum.Material.Neon
	vortex.Transparency = 0.3
	vortex.Anchored = true
	vortex.CanCollide = false
	vortex.CFrame = CFrame.new(position + Vector3.new(0.5, 0, 0))
	vortex.Parent = portal

	local touchPart = Instance.new("Part")
	touchPart.Name = "TouchPart"
	touchPart.Shape = Enum.PartType.Block
	touchPart.Size = Vector3.new(4, 4, 4)
	touchPart.Color = diffData.color
	touchPart.Material = Enum.Material.Neon
	touchPart.Transparency = 1
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.CFrame = CFrame.new(position + Vector3.new(0.5, 0, 0))
	touchPart.Parent = portal

	local label = Instance.new("Part")
	label.Name = "Label"
	label.Shape = Enum.PartType.Block
	label.Size = Vector3.new(4, 1, 0.2)
	label.Color = Color3.fromRGB(30, 30, 30)
	label.Material = Enum.Material.SmoothPlastic
	label.Anchored = true
	label.CanCollide = false
	label.CFrame = CFrame.new(position + Vector3.new(0.5, -2.5, 0))
	label.Parent = portal

	local textLabel = Instance.new("SurfaceGui")
	textLabel.Face = Enum.NormalId.Front
	textLabel.Parent = label

	local textBox = Instance.new("TextLabel")
	textBox.Size = UDim2.new(1, 0, 1, 0)
	textBox.BackgroundTransparency = 0
	textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	textBox.Text = diffData.name
	textBox.TextColor3 = diffData.color
	textBox.TextSize = 24
	textBox.Font = Enum.Font.GothamBold
	textBox.TextScaled = true
	textBox.Parent = textLabel

	local debounce = {}
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if player and not debounce[player.UserId] then
				debounce[player.UserId] = true
				
				print("Player entered portal:", diffData.difficulty)
				
				local event = game:GetService("ReplicatedStorage"):WaitForChild("DungeonPortalEntered")
				event:FireClient(player, diffData.difficulty)
				
				task.wait(1)
				debounce[player.UserId] = nil
			end
		end
	end)

	return portal
end

function LobbyGenerator:createDresser(parent, position, index)
	local dresser = Instance.new("Model")
	dresser.Name = "Dresser" .. index
	dresser.Parent = parent

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Block
	base.Size = Vector3.new(5, 4, 2.5)
	base.Color = Color3.fromRGB(120, 90, 50)
	base.Material = Enum.Material.Wood
	base.Anchored = true
	base.CanCollide = true
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	base.Parent = dresser

	local mirror = Instance.new("Part")
	mirror.Name = "Mirror"
	mirror.Shape = Enum.PartType.Block
	mirror.Size = Vector3.new(4, 3, 0.1)
	mirror.Color = Color3.fromRGB(100, 150, 255)
	mirror.Material = Enum.Material.Neon
	mirror.Anchored = true
	mirror.CanCollide = false
	mirror.Transparency = 0.2
	mirror.CFrame = CFrame.new(position + Vector3.new(0, 2.5, -1.3))
	mirror.Parent = dresser

	local mirrorFrame = Instance.new("Part")
	mirrorFrame.Name = "MirrorFrame"
	mirrorFrame.Shape = Enum.PartType.Block
	mirrorFrame.Size = Vector3.new(4.3, 3.3, 0.15)
	mirrorFrame.Color = Color3.fromRGB(200, 150, 80)
	mirrorFrame.Material = Enum.Material.Wood
	mirrorFrame.Anchored = true
	mirrorFrame.CanCollide = false
	mirrorFrame.CFrame = CFrame.new(position + Vector3.new(0, 2.5, -1.25))
	mirrorFrame.Parent = dresser

	local drawer1 = Instance.new("Part")
	drawer1.Name = "Drawer1"
	drawer1.Shape = Enum.PartType.Block
	drawer1.Size = Vector3.new(4.5, 0.8, 0.5)
	drawer1.Color = Color3.fromRGB(100, 70, 40)
	drawer1.Material = Enum.Material.Wood
	drawer1.Anchored = true
	drawer1.CanCollide = false
	drawer1.CFrame = CFrame.new(position + Vector3.new(0, 0.8, 0.2))
	drawer1.Parent = dresser

	local drawer2 = Instance.new("Part")
	drawer2.Name = "Drawer2"
	drawer2.Shape = Enum.PartType.Block
	drawer2.Size = Vector3.new(4.5, 0.8, 0.5)
	drawer2.Color = Color3.fromRGB(100, 70, 40)
	drawer2.Material = Enum.Material.Wood
	drawer2.Anchored = true
	drawer2.CanCollide = false
	drawer2.CFrame = CFrame.new(position + Vector3.new(0, 2, 0.2))
	drawer2.Parent = dresser

	local touchPart = Instance.new("Part")
	touchPart.Name = "TouchPart"
	touchPart.Shape = Enum.PartType.Block
	touchPart.Size = Vector3.new(5, 4, 2.5)
	touchPart.Color = Color3.fromRGB(100, 80, 60)
	touchPart.Material = Enum.Material.Wood
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.Transparency = 1
	touchPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	touchPart.Parent = dresser

	local debounce = {}
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if player and not debounce[player.UserId] then
				debounce[player.UserId] = true
				
				print("Player touched dresser:", player.Name)
				
				local event = game:GetService("ReplicatedStorage"):FindFirstChild("RaceSelectionRequested")
				if event then
					event:FireClient(player)
				end
				
				task.wait(1)
				debounce[player.UserId] = nil
			end
		end
	end)

	return dresser
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
