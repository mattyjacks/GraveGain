-- minimap.lua (CLIENT)
-- Top-down dot minimap in the top-right corner showing player position,
-- enemies, and the current objective.

local Minimap = {}

local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAP_SIZE   = 160  -- pixels
local MAP_RADIUS = 120  -- world studs shown per side (zoomed view)

local gui = nil
local mapFrame = nil
local playerDot = nil

local enemyDots    = {}  -- { [enemy] = dot }
local objectiveDot = nil

local function createUI()
	gui = Instance.new("ScreenGui")
	gui.Name = "MinimapGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = playerGui

	-- Background panel
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, MAP_SIZE + 16, 0, MAP_SIZE + 30)
	panel.Position = UDim2.new(1, -(MAP_SIZE + 24), 0, 10)
	panel.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	panel.BackgroundTransparency = 0.2
	panel.BorderSizePixel = 0
	panel.Parent = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(60, 70, 110)
	stroke.Thickness = 1.5

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Position = UDim2.new(0, 0, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = "MAP"
	title.TextColor3 = Color3.fromRGB(120, 140, 200)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.Parent = panel

	-- Map viewport (circular clip)
	mapFrame = Instance.new("Frame")
	mapFrame.Size = UDim2.new(0, MAP_SIZE, 0, MAP_SIZE)
	mapFrame.Position = UDim2.new(0, 8, 0, 22)
	mapFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 14)
	mapFrame.BorderSizePixel = 0
	mapFrame.ClipsDescendants = true
	mapFrame.Parent = panel
	Instance.new("UICorner", mapFrame).CornerRadius = UDim.new(0.5, 0)  -- circular

	-- Subtle grid
	for i = 1, 3 do
		local gridLine = Instance.new("Frame")
		gridLine.Size = UDim2.new(1, 0, 0, 1)
		gridLine.Position = UDim2.new(0, 0, i / 4, 0)
		gridLine.BackgroundColor3 = Color3.fromRGB(40, 60, 30)
		gridLine.BorderSizePixel = 0
		gridLine.Parent = mapFrame

		local gridLine2 = Instance.new("Frame")
		gridLine2.Size = UDim2.new(0, 1, 1, 0)
		gridLine2.Position = UDim2.new(i / 4, 0, 0, 0)
		gridLine2.BackgroundColor3 = Color3.fromRGB(40, 60, 30)
		gridLine2.BorderSizePixel = 0
		gridLine2.Parent = mapFrame
	end

	-- Player dot (white, center of map)
	playerDot = Instance.new("Frame")
	playerDot.Size = UDim2.new(0, 10, 0, 10)
	playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	playerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
	playerDot.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	playerDot.BorderSizePixel = 0
	playerDot.ZIndex = 10
	Instance.new("UICorner", playerDot).CornerRadius = UDim.new(1, 0)
	playerDot.Parent = mapFrame

	-- Player direction indicator (small triangle)
	local dirIndicator = Instance.new("Frame")
	dirIndicator.Size = UDim2.new(0, 4, 0, 8)
	dirIndicator.AnchorPoint = Vector2.new(0.5, 1)
	dirIndicator.Position = UDim2.new(0.5, 0, 0, -1)
	dirIndicator.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
	dirIndicator.BorderSizePixel = 0
	dirIndicator.ZIndex = 11
	dirIndicator.Parent = playerDot
	Instance.new("UICorner", dirIndicator).CornerRadius = UDim.new(0.5, 0)

	-- Compass ring border
	local ring = Instance.new("UIStroke", mapFrame)
	ring.Color = Color3.fromRGB(80, 100, 150)
	ring.Thickness = 2

	-- Objective dot (yellow star)
	objectiveDot = Instance.new("TextLabel")
	objectiveDot.Size = UDim2.new(0, 16, 0, 16)
	objectiveDot.AnchorPoint = Vector2.new(0.5, 0.5)
	objectiveDot.BackgroundTransparency = 1
	objectiveDot.Text = "★"
	objectiveDot.TextColor3 = Color3.fromRGB(255, 220, 50)
	objectiveDot.Font = Enum.Font.GothamBold
	objectiveDot.TextSize = 14
	objectiveDot.ZIndex = 9
	objectiveDot.Visible = false
	objectiveDot.Parent = mapFrame

	return gui
end

local function getOrCreateEnemyDot(enemy)
	if enemyDots[enemy] then return enemyDots[enemy] end

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 7, 0, 7)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	dot.BorderSizePixel = 0
	dot.ZIndex = 8
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	dot.Parent = mapFrame
	enemyDots[enemy] = dot

	-- Clean up when enemy is removed
	enemy.AncestryChanged:Connect(function()
		if not enemy.Parent then
			dot:Destroy()
			enemyDots[enemy] = nil
		end
	end)

	return dot
end

local function worldToMap(playerPos, targetPos)
	local dx = targetPos.X - playerPos.X
	local dz = targetPos.Z - playerPos.Z

	local mapX = 0.5 + (dx / MAP_RADIUS) * 0.5
	local mapY = 0.5 + (dz / MAP_RADIUS) * 0.5

	return math.clamp(mapX, 0, 1), math.clamp(mapY, 0, 1)
end

function Minimap.start()
	createUI()

	RunService.RenderStepped:Connect(function()
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local playerPos = hrp.Position

		-- Rotate player dot to face movement direction
		local lookVector = hrp.CFrame.LookVector
		local angle = math.deg(math.atan2(lookVector.X, lookVector.Z))
		playerDot.Rotation = -angle

		-- Update enemies
		local enemyFolder = workspace:FindFirstChild("Enemies")
		if enemyFolder then
			for _, enemy in ipairs(enemyFolder:GetChildren()) do
				local eHRP = enemy:FindFirstChild("HumanoidRootPart")
				if eHRP then
					local dot = getOrCreateEnemyDot(enemy)
					local mx, my = worldToMap(playerPos, eHRP.Position)
					dot.Position = UDim2.new(mx, 0, my, 0)
					dot.Visible = true
				end
			end
		end

		-- Update objective
		local objective = workspace:FindFirstChild("ArchRune", true)
			or workspace:FindFirstChild("ObjectiveArtifact", true)
			or workspace:FindFirstChild("GiantSkullBoss", true)
			or workspace:FindFirstChild("SpaceElevator", true)

		if objective then
			objectiveDot.Visible = true
			local ox, oy = worldToMap(playerPos, objective:GetPivot().Position)
			objectiveDot.Position = UDim2.new(ox, 0, oy, 0)
		else
			objectiveDot.Visible = false
		end
	end)
end

function Minimap.show()
	if gui then gui.Enabled = true end
end

function Minimap.hide()
	if gui then gui.Enabled = false end
end

return Minimap
