-- Client-side Lobby UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared:WaitForChild("constants"))
local LoreUI = require(ReplicatedStorage.Client:WaitForChild("lore_ui"))

local LobbyUI = {}
LobbyUI.__index = LobbyUI

local player = Players.LocalPlayer
local selected_race = Constants.RACES.HUMAN
local selected_class = Constants.CLASSES.DPS
local is_ready = false
local settings_open = false

function LobbyUI:initialize()
	print("[LobbyUI] Initializing...")
	
	local player_gui = player:WaitForChild("PlayerGui")
	print("[LobbyUI] PlayerGui found")
	
	-- Initialize lore UI
	LoreUI:initialize()
	
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
	
	-- Title bar
	local title_bar = Instance.new("Frame")
	title_bar.Name = "TitleBar"
	title_bar.Size = UDim2.new(1, 0, 0.08, 0)
	title_bar.Position = UDim2.new(0, 0, 0, 0)
	title_bar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title_bar.BorderSizePixel = 0
	title_bar.Parent = screen_gui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.7, 0, 1, 0)
	title.Position = UDim2.new(0.15, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.TextSize = 48
	title.Font = Enum.Font.GothamBold
	title.Text = Constants.GAME_NAME
	title.Parent = title_bar
	
	-- Lore button
	local lore_button = Instance.new("TextButton")
	lore_button.Name = "LoreButton"
	lore_button.Size = UDim2.new(0.12, 0, 0.7, 0)
	lore_button.Position = UDim2.new(0.71, 0, 0.15, 0)
	lore_button.BackgroundColor3 = Color3.fromRGB(100, 120, 150)
	lore_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	lore_button.TextSize = 16
	lore_button.Font = Enum.Font.GothamBold
	lore_button.Text = "📚 Lore"
	lore_button.Parent = title_bar
	
	lore_button.MouseButton1Click:Connect(function()
		LoreUI:toggle_lore_menu()
	end)
	
	-- Settings button
	local settings_button = Instance.new("TextButton")
	settings_button.Name = "SettingsButton"
	settings_button.Size = UDim2.new(0.12, 0, 0.7, 0)
	settings_button.Position = UDim2.new(0.85, 0, 0.15, 0)
	settings_button.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	settings_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	settings_button.TextSize = 16
	settings_button.Font = Enum.Font.GothamBold
	settings_button.Text = "⚙️ Settings"
	settings_button.Parent = title_bar
	
	settings_button.MouseButton1Click:Connect(function()
		self:toggle_settings()
	end)
	
	-- Main container with scrolling
	local main_container = Instance.new("Frame")
	main_container.Name = "MainContainer"
	main_container.Size = UDim2.new(1, 0, 0.92, 0)
	main_container.Position = UDim2.new(0, 0, 0.08, 0)
	main_container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	main_container.BorderSizePixel = 0
	main_container.Parent = screen_gui
	
	-- Content frame for scrolling
	local content_frame = Instance.new("Frame")
	content_frame.Name = "ContentFrame"
	content_frame.Size = UDim2.new(1, 0, 1, 0)
	content_frame.BackgroundTransparency = 1
	content_frame.Parent = main_container
	
	-- Layout for content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 20)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = content_frame
	
	-- Race selection panel
	local race_panel = self:create_selection_panel(
		"Select Race",
		Constants.RACES,
		Constants.RACE_NAMES,
		function(race) self:on_race_selected(race) end
	)
	race_panel.Parent = content_frame
	
	-- Class selection panel
	local class_panel = self:create_selection_panel(
		"Select Class",
		Constants.CLASSES,
		Constants.CLASS_NAMES,
		function(class_type) self:on_class_selected(class_type) end
	)
	class_panel.Parent = content_frame
	
	-- Bottom controls frame
	local controls_frame = Instance.new("Frame")
	controls_frame.Name = "ControlsFrame"
	controls_frame.Size = UDim2.new(0.8, 0, 0.15, 0)
	controls_frame.BackgroundTransparency = 1
	controls_frame.Parent = content_frame
	
	-- Ready button
	local ready_button = Instance.new("TextButton")
	ready_button.Name = "ReadyButton"
	ready_button.Size = UDim2.new(0.5, 0, 1, 0)
	ready_button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	ready_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	ready_button.TextSize = 24
	ready_button.Font = Enum.Font.GothamBold
	ready_button.Text = "READY"
	ready_button.Parent = controls_frame
	
	ready_button.MouseButton1Click:Connect(function()
		self:toggle_ready()
	end)
	
	-- Player list
	local player_list = Instance.new("TextLabel")
	player_list.Name = "PlayerList"
	player_list.Size = UDim2.new(0.8, 0, 0.25, 0)
	player_list.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	player_list.TextColor3 = Color3.fromRGB(200, 200, 200)
	player_list.TextSize = 14
	player_list.Font = Enum.Font.Gotham
	player_list.Text = "Players in Lobby:\n"
	player_list.TextXAlignment = Enum.TextXAlignment.Left
	player_list.TextYAlignment = Enum.TextYAlignment.Top
	player_list.TextWrapped = true
	player_list.Parent = content_frame
	
	screen_gui:SetAttribute("PlayerList", player_list)
	screen_gui:SetAttribute("SettingsButton", settings_button)
end

function LobbyUI:create_selection_panel(title, options, names, callback)
	local panel = Instance.new("Frame")
	panel.Name = title
	panel.Size = UDim2.new(0.8, 0, 0, 0)
	panel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	panel.BorderSizePixel = 0
	
	-- Title
	local title_label = Instance.new("TextLabel")
	title_label.Name = "Title"
	title_label.Size = UDim2.new(1, 0, 0.2, 0)
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
	
	-- Add UIListLayout to auto-size the panel
	local list_layout = Instance.new("UIListLayout")
	list_layout.Padding = UDim.new(0, 10)
	list_layout.FillDirection = Enum.FillDirection.Vertical
	list_layout.SortOrder = Enum.SortOrder.LayoutOrder
	list_layout.Parent = panel
	
	title_label.LayoutOrder = 0
	
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

function LobbyUI:toggle_settings()
	settings_open = not settings_open
	local player_gui = player:WaitForChild("PlayerGui")
	local lobby_ui = player_gui:FindFirstChild("LobbyUI")
	if not lobby_ui then return end
	
	local settings_menu = lobby_ui:FindFirstChild("SettingsMenu")
	if settings_open then
		if not settings_menu then
			self:create_settings_menu(lobby_ui)
		else
			settings_menu.Visible = true
		end
	else
		if settings_menu then
			settings_menu.Visible = false
		end
	end
end

function LobbyUI:create_settings_menu(parent)
	local settings_menu = Instance.new("Frame")
	settings_menu.Name = "SettingsMenu"
	settings_menu.Size = UDim2.new(0.4, 0, 0.6, 0)
	settings_menu.Position = UDim2.new(0.3, 0, 0.2, 0)
	settings_menu.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	settings_menu.BorderColor3 = Color3.fromRGB(100, 100, 120)
	settings_menu.BorderSizePixel = 2
	settings_menu.Parent = parent
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Text = "Settings"
	title.Parent = settings_menu
	
	-- Close button
	local close_button = Instance.new("TextButton")
	close_button.Name = "CloseButton"
	close_button.Size = UDim2.new(0.1, 0, 0.08, 0)
	close_button.Position = UDim2.new(0.88, 0, 0.01, 0)
	close_button.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	close_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	close_button.TextSize = 20
	close_button.Font = Enum.Font.GothamBold
	close_button.Text = "X"
	close_button.Parent = settings_menu
	
	close_button.MouseButton1Click:Connect(function()
		self:toggle_settings()
	end)
	
	-- Content frame
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0.9, 0)
	content.Position = UDim2.new(0, 0, 0.1, 0)
	content.BackgroundTransparency = 1
	content.Parent = settings_menu
	
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 15)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = content
	
	-- Difficulty setting
	local difficulty_frame = self:create_setting_item("Difficulty", {"Easy", "Normal", "Hard", "Nightmare"}, content)
	
	-- Graphics setting
	local graphics_frame = self:create_setting_item("Graphics", {"Low", "Medium", "High", "Ultra"}, content)
	
	-- Volume setting
	local volume_frame = self:create_setting_item("Volume", {"0%", "25%", "50%", "75%", "100%"}, content)
	
	-- Credits button
	local credits_button = Instance.new("TextButton")
	credits_button.Name = "CreditsButton"
	credits_button.Size = UDim2.new(0.8, 0, 0.08, 0)
	credits_button.BackgroundColor3 = Color3.fromRGB(100, 120, 150)
	credits_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	credits_button.TextSize = 16
	credits_button.Font = Enum.Font.GothamBold
	credits_button.Text = "Credits"
	credits_button.Parent = content
	
	credits_button.MouseButton1Click:Connect(function()
		print("[LobbyUI] Credits clicked")
	end)
end

function LobbyUI:create_setting_item(name, options, parent)
	local frame = Instance.new("Frame")
	frame.Name = name .. "Frame"
	frame.Size = UDim2.new(0.8, 0, 0.12, 0)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	frame.Parent = parent
	
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.Text = name
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	-- Dropdown
	local dropdown = Instance.new("TextButton")
	dropdown.Name = "Dropdown"
	dropdown.Size = UDim2.new(0.5, 0, 1, 0)
	dropdown.Position = UDim2.new(0.45, 0, 0, 0)
	dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
	dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	dropdown.TextSize = 14
	dropdown.Font = Enum.Font.Gotham
	dropdown.Text = options[1]
	dropdown.Parent = frame
	
	return frame
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
