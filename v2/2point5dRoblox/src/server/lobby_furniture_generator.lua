local LobbyFurnitureGenerator = {}
LobbyFurnitureGenerator.__index = LobbyFurnitureGenerator

function LobbyFurnitureGenerator.new(lobbyGenerator)
	local self = setmetatable({}, LobbyFurnitureGenerator)
	self.lobby = lobbyGenerator
	return self
end

function LobbyFurnitureGenerator:placeFurniture(parent)
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

function LobbyFurnitureGenerator:createPortalWall(parent)
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

function LobbyFurnitureGenerator:createPortal(parent, position, diffData)
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

function LobbyFurnitureGenerator:createDresser(parent, position, index)
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

return LobbyFurnitureGenerator
