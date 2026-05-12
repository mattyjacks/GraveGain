local LobbyRacePicker = {}
LobbyRacePicker.__index = LobbyRacePicker

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaceStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("race_stats"))

function LobbyRacePicker.new()
	local self = setmetatable({}, LobbyRacePicker)
	self.selectedRace = nil
	self.gui = nil
	return self
end

function LobbyRacePicker:show()
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LobbyRacePicker"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	background.BackgroundTransparency = 0.2
	background.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 800, 0, 600)
	panel.Position = UDim2.new(0.5, -400, 0.5, -300)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	panel.BorderSizePixel = 2
	panel.BorderColor3 = Color3.fromRGB(100, 150, 255)
	panel.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 80)
	title.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
	title.BackgroundTransparency = 0
	title.Text = "Choose Your Race"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 48
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 50)
	subtitle.Position = UDim2.new(0, 0, 0, 80)
	subtitle.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Select a race to customize your character"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = panel

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -40, 1, -160)
	container.Position = UDim2.new(0, 20, 0, 140)
	container.BackgroundTransparency = 1
	container.Parent = panel

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.5, -15, 0.5, -15)
	layout.CellPadding = UDim2.new(0, 30, 0, 30)
	layout.Parent = container

	local races = RaceStats.getAllRaces()
	for i, raceStats in ipairs(races) do
		local raceButton = Instance.new("TextButton")
		raceButton.Name = raceStats.name
		raceButton.BackgroundColor3 = raceStats.color
		raceButton.BackgroundTransparency = 0.4
		raceButton.BorderSizePixel = 2
		raceButton.BorderColor3 = raceStats.color
		local shieldText = raceStats.hasShield and ("\nShield: " .. raceStats.shieldMax) or ""
		raceButton.Text = raceStats.name .. "\n\nHP: " .. raceStats.hp .. shieldText .. "\nRegen: " .. raceStats.regenRate .. "/s\n\n" .. raceStats.description
		raceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		raceButton.TextWrapped = true
		raceButton.TextScaled = false
		raceButton.TextSize = 18
		raceButton.Font = Enum.Font.GothamBold
		raceButton.Parent = container

		raceButton.MouseButton1Click:Connect(function()
			self:selectRace(raceStats.name, screenGui)
		end)

		raceButton.MouseEnter:Connect(function()
			raceButton.BackgroundTransparency = 0.1
			raceButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
		end)

		raceButton.MouseLeave:Connect(function()
			raceButton.BackgroundTransparency = 0.4
			raceButton.BorderColor3 = raceStats.color
		end)
	end

	self.gui = screenGui
end

function LobbyRacePicker:selectRace(raceName, gui)
	self.selectedRace = raceName
	print("Selected race:", raceName)

	if gui then
		gui:Destroy()
	end
end

function LobbyRacePicker:getSelectedRace()
	return self.selectedRace
end

return LobbyRacePicker
