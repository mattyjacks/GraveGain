local RacePicker = {}
RacePicker.__index = RacePicker

local RACES = {
	{name = "Human", color = Color3.fromRGB(200, 180, 150), light = "Flashlight"},
	{name = "Elf", color = Color3.fromRGB(100, 200, 100), light = "BrightEyes"},
	{name = "Dwarf", color = Color3.fromRGB(180, 140, 80), light = "Darkvision"},
	{name = "Orc", color = Color3.fromRGB(100, 180, 100), light = "Torch"},
}

function RacePicker.new()
	local self = setmetatable({}, RacePicker)
	self.selectedRace = nil
	self.gui = nil
	return self
end

function RacePicker:show()
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RacePicker"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	background.BackgroundTransparency = 0.3
	background.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 600, 0, 500)
	panel.Position = UDim2.new(0.5, -300, 0.5, -250)
	panel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	panel.BorderSizePixel = 2
	panel.BorderColor3 = Color3.fromRGB(100, 150, 255)
	panel.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
	title.BackgroundTransparency = 0
	title.Text = "Choose Your Race"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 40)
	subtitle.Position = UDim2.new(0, 0, 0, 60)
	subtitle.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Press F to use your race's light ability"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 14
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = panel

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -40, 1, -140)
	container.Position = UDim2.new(0, 20, 0, 110)
	container.BackgroundTransparency = 1
	container.Parent = panel

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.5, -10, 0.5, -10)
	layout.CellPadding = UDim2.new(0, 20, 0, 20)
	layout.Parent = container

	for i, race in ipairs(RACES) do
		local raceButton = Instance.new("TextButton")
		raceButton.Name = race.name
		raceButton.BackgroundColor3 = race.color
		raceButton.BackgroundTransparency = 0.3
		raceButton.BorderSizePixel = 2
		raceButton.BorderColor3 = race.color
		raceButton.Text = race.name .. "\n\nLight: " .. race.light
		raceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		raceButton.TextSize = 18
		raceButton.Font = Enum.Font.GothamBold
		raceButton.Parent = container

		raceButton.MouseButton1Click:Connect(function()
			self:selectRace(race.name, screenGui)
		end)

		raceButton.MouseEnter:Connect(function()
			raceButton.BackgroundTransparency = 0.1
			raceButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
		end)

		raceButton.MouseLeave:Connect(function()
			raceButton.BackgroundTransparency = 0.3
			raceButton.BorderColor3 = race.color
		end)
	end

	self.gui = screenGui
end

function RacePicker:selectRace(raceName, gui)
	self.selectedRace = raceName
	print("Selected race:", raceName)

	if gui then
		gui:Destroy()
	end
end

function RacePicker:getSelectedRace()
	return self.selectedRace
end

return RacePicker
