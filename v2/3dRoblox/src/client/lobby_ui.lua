-- Client-side Lobby UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared:WaitForChild("constants"))

local LobbyUI = {}
LobbyUI.__index = LobbyUI

local player = Players.LocalPlayer
local selected_race = Constants.RACES.HUMAN
local selected_class = Constants.CLASSES.DPS
local is_ready = false

function LobbyUI:initialize()
	print("[LobbyUI] Initializing...")
	
	local player_gui = player:WaitForChild("PlayerGui")
	print("[LobbyUI] PlayerGui found")
	
	self:create_lobby_screen(player_gui)
	self:setup_event_listeners()
	
	print("[LobbyUI] Initialized")
end

function LobbyUI:create_lobby_screen(player_gui)
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "LobbyUI"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player_gui
	
	print("[LobbyUI] Screen GUI created")
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.TextSize = 48
	title.Font = Enum.Font.GothamBold
	title.Text = Constants.GAME_NAME
	title.Parent = screen_gui
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 0.9, 0)
	container.Position = UDim2.new(0, 0, 0.1, 0)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	container.BorderSizePixel = 0
	container.Parent = screen_gui
	
	-- Left panel - Race selection
	local race_panel = self:create_selection_panel(
		"Select Race",
		Constants.RACES,
		Constants.RACE_NAMES,
		0,
		0.5,
		function(race) self:on_race_selected(race) end
	)
	race_panel.Parent = container
	
	-- Right panel - Class selection
	local class_panel = self:create_selection_panel(
		"Select Class",
		Constants.CLASSES,
		Constants.CLASS_NAMES,
		0.5,
		0.5,
		function(class_type) self:on_class_selected(class_type) end
	)
	class_panel.Parent = container
	
	-- Bottom panel - Ready button
	local bottom_panel = Instance.new("Frame")
	bottom_panel.Name = "BottomPanel"
	bottom_panel.Size = UDim2.new(1, 0, 0.15, 0)
	bottom_panel.Position = UDim2.new(0, 0, 0.85, 0)
	bottom_panel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	bottom_panel.BorderSizePixel = 0
	bottom_panel.Parent = container
	
	-- Ready button
	local ready_button = Instance.new("TextButton")
	ready_button.Name = "ReadyButton"
	ready_button.Size = UDim2.new(0.3, 0, 0.6, 0)
	ready_button.Position = UDim2.new(0.35, 0, 0.2, 0)
	ready_button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	ready_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	ready_button.TextSize = 24
	ready_button.Font = Enum.Font.GothamBold
	ready_button.Text = "READY"
	ready_button.Parent = bottom_panel
	
	ready_button.MouseButton1Click:Connect(function()
		self:toggle_ready()
	end)
	
	-- Player list
	local player_list = Instance.new("TextLabel")
	player_list.Name = "PlayerList"
	player_list.Size = UDim2.new(0.3, 0, 0.8, 0)
	player_list.Position = UDim2.new(0.7, 0, 0.05, 0)
	player_list.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	player_list.TextColor3 = Color3.fromRGB(200, 200, 200)
	player_list.TextSize = 16
	player_list.Font = Enum.Font.Gotham
	player_list.Text = "Players in Lobby:\n"
	player_list.TextXAlignment = Enum.TextXAlignment.Left
	player_list.TextYAlignment = Enum.TextYAlignment.Top
	player_list.Parent = container
	
	screen_gui:SetAttribute("PlayerList", player_list)
end

function LobbyUI:create_selection_panel(title, options, names, x_pos, width, callback)
	local panel = Instance.new("Frame")
	panel.Name = title
	panel.Size = UDim2.new(width, 0, 0.8, 0)
	panel.Position = UDim2.new(x_pos, 0, 0.05, 0)
	panel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	panel.BorderSizePixel = 0
	
	-- Title
	local title_label = Instance.new("TextLabel")
	title_label.Name = "Title"
	title_label.Size = UDim2.new(1, 0, 0.15, 0)
	title_label.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	title_label.TextColor3 = Color3.fromRGB(200, 200, 255)
	title_label.TextSize = 24
	title_label.Font = Enum.Font.GothamBold
	title_label.Text = title
	title_label.Parent = panel
	
	-- Grid layout
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.45, 0, 0.35, 0)
	grid.CellPadding = UDim2.new(0.05, 0, 0.05, 0)
	grid.Parent = panel
	
	-- Create buttons for each option
	for key, value in pairs(options) do
		local button = Instance.new("TextButton")
		button.Name = names[value]
		button.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 18
		button.Font = Enum.Font.GothamBold
		button.Text = names[value]
		button.Parent = panel
		
		button.MouseButton1Click:Connect(function()
			callback(value)
			button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		end)
	end
	
	return panel
end

function LobbyUI:on_race_selected(race)
	selected_race = race
	local player_data = player:FindFirstChild("PlayerData")
	if player_data then
		local race_value = player_data:FindFirstChild("Race")
		if race_value then
			race_value.Value = race
		end
	end
	print("[LobbyUI] Race selected:", Constants.RACE_NAMES[race])
end

function LobbyUI:on_class_selected(class_type)
	selected_class = class_type
	local player_data = player:FindFirstChild("PlayerData")
	if player_data then
		local class_value = player_data:FindFirstChild("Class")
		if class_value then
			class_value.Value = class_type
		end
	end
	print("[LobbyUI] Class selected:", Constants.CLASS_NAMES[class_type])
end

function LobbyUI:toggle_ready()
	is_ready = not is_ready
	local player_data = player:FindFirstChild("PlayerData")
	if player_data then
		local ready_value = player_data:FindFirstChild("Ready")
		if ready_value then
			ready_value.Value = is_ready
		end
	end
	print("[LobbyUI] Player ready:", is_ready)
end

function LobbyUI:setup_event_listeners()
	local events = ReplicatedStorage:WaitForChild("Events")
	local player_joined = events:WaitForChild("PlayerJoined")
	
	player_joined.OnClientEvent:Connect(function(lobby_state)
		self:update_player_list(lobby_state)
	end)
end

function LobbyUI:update_player_list(lobby_state)
	local player_gui = player:WaitForChild("PlayerGui")
	local screen_gui = player_gui:FindFirstChild("LobbyUI")
	if not screen_gui then return end
	
	local player_list = screen_gui:GetAttribute("PlayerList")
	if not player_list then return end
	
	local text = "Players in Lobby:\n"
	for _, player_info in ipairs(lobby_state) do
		local race_name = Constants.RACE_NAMES[player_info.race]
		local class_name = Constants.CLASS_NAMES[player_info.class_type]
		local status = player_info.ready and "[READY]" or "[WAITING]"
		text = text .. string.format("%s (%s %s) %s\n", player_info.username, race_name, class_name, status)
	end
	
	player_list.Text = text
end

return LobbyUI
