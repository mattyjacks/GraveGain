-- objective_indicator.lua (CLIENT)
-- Displays a 👆 emoji at the edge of the screen pointing to the current objective.

local ObjectiveIndicator = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "ObjectiveGui"
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local indicator = Instance.new("TextLabel")
indicator.Size = UDim2.new(0, 60, 0, 60)
indicator.BackgroundTransparency = 1
indicator.Text = "👆"
indicator.TextColor3 = Color3.fromRGB(255, 255, 0)
indicator.TextStrokeTransparency = 0.5
indicator.TextSize = 50
indicator.ZIndex = 10
indicator.Visible = false
indicator.Parent = gui

local distanceLabel = Instance.new("TextLabel")
distanceLabel.Size = UDim2.new(2, 0, 0, 20)
distanceLabel.Position = UDim2.new(-0.5, 0, 1, 0)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = ""
distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceLabel.TextStrokeTransparency = 0.5
distanceLabel.Font = Enum.Font.GothamBold
distanceLabel.TextSize = 14
distanceLabel.ZIndex = 10
distanceLabel.Parent = indicator

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.new(0,0,0)
stroke.Parent = indicator

local function getObjective()
	-- 1. Priority: Active Boss
	local boss = workspace:FindFirstChild("GiantSkullBoss", true)
	if boss and boss:FindFirstChild("HumanoidRootPart") then return boss.HumanoidRootPart end
	
	-- 2. Priority: Artifact
	local art = workspace:FindFirstChild("ObjectiveArtifact", true)
	if art then return art end
	
	-- 3. Priority: Dungeon Entrance (if in wasteland)
	-- Look specifically in the Exterior folder if it exists
	local exterior = workspace:FindFirstChild("Exterior")
	if exterior then
		local arch = exterior:FindFirstChild("ArchRune", true)
		if arch then return arch end
	end
	
	-- Fallback: any ArchRune in workspace
	local fallback = workspace:FindFirstChild("ArchRune", true)
	if fallback then return fallback end
	
	-- 4. Priority: Elevator (if extracting)
	local elev = workspace:FindFirstChild("SpaceElevator", true)
	if elev then return elev end
	
	return nil
end

local lastTargetName = ""

function ObjectiveIndicator.start()
	print("Objective Indicator System Started")
	RunService.RenderStepped:Connect(function()
		local target = getObjective()
		if not target then
			if indicator.Visible then
				indicator.Visible = false
				print("Objective Indicator: Target lost")
			end
			return
		end

		if target.Name ~= lastTargetName then
			print("Objective Indicator: New target found ->", target.Name)
			lastTargetName = target.Name
		end

		-- Pulse animation
		local pulse = 1 + math.sin(tick() * 5) * 0.1
		indicator.Size = UDim2.new(0, 60 * pulse, 0, 60 * pulse)

		local screenPos, onScreen = camera:WorldToScreenPoint(target:GetPivot().Position)
		
		if onScreen and screenPos.Z > 0 then
			indicator.Visible = true
			indicator.Position = UDim2.new(0, screenPos.X - (30 * pulse), 0, screenPos.Y - (30 * pulse))
			indicator.Rotation = 180 -- pointing down at the object
		else
			indicator.Visible = true
			local viewportSize = camera.ViewportSize
			local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
			local dirX = screenPos.X - center.X
			local dirY = screenPos.Y - center.Y
			if screenPos.Z < 0 then
				dirX, dirY = -dirX, -dirY
			end
			local dir = Vector2.new(dirX, dirY).Unit
			local margin = 80
			local edgeX = math.clamp(center.X + dir.X * 2000, margin, viewportSize.X - margin)
			local edgeY = math.clamp(center.Y + dir.Y * 2000, margin, viewportSize.Y - margin)
			indicator.Position = UDim2.new(0, edgeX - (30 * pulse), 0, edgeY - (30 * pulse))
			
			local angle = math.atan2(dir.Y, dir.X)
			indicator.Rotation = math.deg(angle) + 90
		end

		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local targetPos = target:GetPivot().Position
			local dist = (targetPos - hrp.Position).Magnitude
			distanceLabel.Text = string.format("%d STUDS", math.ceil(dist))
			distanceLabel.Rotation = -indicator.Rotation
		else
			distanceLabel.Text = ""
		end
	end)
end

return ObjectiveIndicator
