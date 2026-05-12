local LobbyBookGenerator = {}
LobbyBookGenerator.__index = LobbyBookGenerator

function LobbyBookGenerator.new(lobbyGenerator)
	local self = setmetatable({}, LobbyBookGenerator)
	self.lobby = lobbyGenerator
	return self
end

function LobbyBookGenerator:createBigBook(parent, position)
	local bookModel = Instance.new("Model")
	bookModel.Name = "BigLoreBook"
	bookModel.Parent = parent

	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Shape = Enum.PartType.Block
	pedestal.Size = Vector3.new(6, 4, 6)
	pedestal.Color = Color3.fromRGB(60, 60, 70)
	pedestal.Material = Enum.Material.Slate
	pedestal.Anchored = true
	pedestal.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	pedestal.Parent = bookModel
	
	local pillar = Instance.new("Part")
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(4, 5, 5)
	pillar.Color = Color3.fromRGB(50, 50, 60)
	pillar.Material = Enum.Material.Slate
	pillar.Anchored = true
	pillar.CFrame = CFrame.new(position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Parent = bookModel

	local leftCover = Instance.new("Part")
	leftCover.Shape = Enum.PartType.Block
	leftCover.Size = Vector3.new(4, 0.4, 6)
	leftCover.Color = Color3.fromRGB(100, 50, 20)
	leftCover.Material = Enum.Material.Wood
	leftCover.Anchored = true
	leftCover.CFrame = CFrame.new(position + Vector3.new(-2, 8.5, 0)) * CFrame.Angles(0, 0, math.rad(15))
	leftCover.Parent = bookModel
	
	local rightCover = Instance.new("Part")
	rightCover.Shape = Enum.PartType.Block
	rightCover.Size = Vector3.new(4, 0.4, 6)
	rightCover.Color = Color3.fromRGB(100, 50, 20)
	rightCover.Material = Enum.Material.Wood
	rightCover.Anchored = true
	rightCover.CFrame = CFrame.new(position + Vector3.new(2, 8.5, 0)) * CFrame.Angles(0, 0, math.rad(-15))
	rightCover.Parent = bookModel
	
	local spine = Instance.new("Part")
	spine.Shape = Enum.PartType.Cylinder
	spine.Size = Vector3.new(6, 1, 1)
	spine.Color = Color3.fromRGB(80, 40, 10)
	spine.Material = Enum.Material.Wood
	spine.Anchored = true
	spine.CFrame = CFrame.new(position + Vector3.new(0, 8.2, 0))
	spine.Parent = bookModel
	
	local leftPages = Instance.new("Part")
	leftPages.Shape = Enum.PartType.Block
	leftPages.Size = Vector3.new(3.8, 0.6, 5.8)
	leftPages.Color = Color3.fromRGB(240, 230, 200)
	leftPages.Material = Enum.Material.SmoothPlastic
	leftPages.Anchored = true
	leftPages.CFrame = CFrame.new(position + Vector3.new(-1.9, 8.8, 0)) * CFrame.Angles(0, 0, math.rad(15))
	leftPages.Parent = bookModel
	
	local rightPages = Instance.new("Part")
	rightPages.Shape = Enum.PartType.Block
	rightPages.Size = Vector3.new(3.8, 0.6, 5.8)
	rightPages.Color = Color3.fromRGB(240, 230, 200)
	rightPages.Material = Enum.Material.SmoothPlastic
	rightPages.Anchored = true
	rightPages.CFrame = CFrame.new(position + Vector3.new(1.9, 8.8, 0)) * CFrame.Angles(0, 0, math.rad(-15))
	rightPages.Parent = bookModel
	
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(400, 600)
	gui.Parent = leftPages
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(0.9, 0, 0.9, 0)
	text.Position = UDim2.new(0.05, 0, 0.05, 0)
	text.BackgroundTransparency = 1
	text.Text = "Chronicles of GraveGain\n\nThe dungeons hold many secrets. Seek the lost lore pages to uncover the truth and gain great power."
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(50, 30, 10)
	text.Font = Enum.Font.Garamond
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.Parent = gui
	
	local gui2 = Instance.new("SurfaceGui")
	gui2.Face = Enum.NormalId.Top
	gui2.CanvasSize = Vector2.new(400, 600)
	gui2.Parent = rightPages
	
	local text2 = Instance.new("TextLabel")
	text2.Size = UDim2.new(0.9, 0, 0.9, 0)
	text2.Position = UDim2.new(0.05, 0, 0.05, 0)
	text2.BackgroundTransparency = 1
	text2.Text = "A wise adventurer always seeks knowledge. For knowledge is the greatest weapon against the dark."
	text2.TextScaled = true
	text2.TextColor3 = Color3.fromRGB(50, 30, 10)
	text2.Font = Enum.Font.Garamond
	text2.TextYAlignment = Enum.TextYAlignment.Top
	text2.Parent = gui2

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 100)
	light.Range = 15
	light.Brightness = 2
	light.Parent = spine

	return bookModel
end

return LobbyBookGenerator
