-- Game State Manager - Handles client-side game state and transitions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared:WaitForChild("constants"))
local FPSController = require(script.Parent:WaitForChild("fps_controller"))
local MeleeWeapon = require(script.Parent:WaitForChild("melee_weapon"))
local RangedWeapon = require(script.Parent:WaitForChild("ranged_weapon"))
local WeaponData = require(ReplicatedStorage.Shared:WaitForChild("weapon_data"))

local GameStateManager = {}
GameStateManager.__index = GameStateManager

local player = Players.LocalPlayer
local current_state = Constants.GAME_STATES.LOBBY
local fps_controller = nil
local current_weapon = nil
local player_data = nil

function GameStateManager:initialize()
	print("[GameStateManager] Initializing...")
	
	self:setup_event_listeners()
	
	print("[GameStateManager] Initialized")
end

function GameStateManager:setup_event_listeners()
	local events = ReplicatedStorage:WaitForChild("Events")
	local state_changed = events:WaitForChild("GameStateChanged")
	
	state_changed.OnClientEvent:Connect(function(new_state, difficulty)
		self:on_game_state_changed(new_state, difficulty)
	end)
end

function GameStateManager:on_game_state_changed(new_state, difficulty)
	print("[GameStateManager] State changed:", new_state)
	current_state = new_state
	
	if new_state == Constants.GAME_STATES.LOADING then
		self:on_loading_start()
	elseif new_state == Constants.GAME_STATES.IN_GAME then
		self:on_game_start()
	elseif new_state == Constants.GAME_STATES.MISSION_COMPLETE then
		self:on_mission_complete()
	elseif new_state == Constants.GAME_STATES.MISSION_FAILED then
		self:on_mission_failed()
	end
end

function GameStateManager:on_loading_start()
	print("[GameStateManager] Loading mission...")
	
	-- Hide lobby UI
	local lobby_ui = player.PlayerGui:FindFirstChild("LobbyUI")
	if lobby_ui then
		lobby_ui:Destroy()
	end
	
	-- Create loading screen
	self:show_loading_screen()
	
	-- Wait for character to load
	task.wait(2)
	
	-- Spawn character
	self:spawn_player_character()
end

function GameStateManager:on_game_start()
	print("[GameStateManager] Game started!")
	
	-- Hide loading screen
	local loading_screen = player.PlayerGui:FindFirstChild("LoadingScreen")
	if loading_screen then
		loading_screen:Destroy()
	end
	
	-- Initialize FPS controller
	if player.Character then
		self:initialize_fps_controller()
	end
end

function GameStateManager:on_mission_complete()
	print("[GameStateManager] Mission complete!")
	self:show_mission_complete_screen()
end

function GameStateManager:on_mission_failed()
	print("[GameStateManager] Mission failed!")
	self:show_mission_failed_screen()
end

function GameStateManager:show_loading_screen()
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "LoadingScreen"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player.PlayerGui
	
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	background.BorderSizePixel = 0
	background.Parent = screen_gui
	
	local loading_text = Instance.new("TextLabel")
	loading_text.Size = UDim2.new(1, 0, 0.2, 0)
	loading_text.Position = UDim2.new(0, 0, 0.4, 0)
	loading_text.BackgroundTransparency = 1
	loading_text.TextColor3 = Color3.fromRGB(200, 200, 255)
	loading_text.TextSize = 48
	loading_text.Font = Enum.Font.GothamBold
	loading_text.Text = "Loading Mission..."
	loading_text.Parent = screen_gui
	
	local spinner = Instance.new("TextLabel")
	spinner.Size = UDim2.new(0.1, 0, 0.1, 0)
	spinner.Position = UDim2.new(0.45, 0, 0.6, 0)
	spinner.BackgroundTransparency = 1
	spinner.TextColor3 = Color3.fromRGB(100, 200, 100)
	spinner.TextSize = 32
	spinner.Font = Enum.Font.GothamBold
	spinner.Parent = screen_gui
	
	-- Animate spinner
	local spinner_frames = { "|", "/", "-", "\\" }
	local frame_index = 1
	
	local spinner_task = task.spawn(function()
		while screen_gui.Parent do
			spinner.Text = spinner_frames[frame_index]
			frame_index = (frame_index % #spinner_frames) + 1
			task.wait(0.1)
		end
	end)
end

function GameStateManager:spawn_player_character()
	-- Get player data from PlayerData folder
	local player_data_folder = player:WaitForChild("PlayerData")
	local race = player_data_folder:WaitForChild("Race").Value
	local class_type = player_data_folder:WaitForChild("Class").Value
	
	-- Create player data object
	local PlayerData = require(ReplicatedStorage.Shared:WaitForChild("player_data"))
	player_data = PlayerData.new(player.UserId, player.Name, race, class_type)
	
	-- Wait for character to be created by server
	local character = player.Character or player.CharacterAdded:Wait()
	print("[GameStateManager] Character spawned:", character.Name)
end

function GameStateManager:initialize_fps_controller()
	if fps_controller then return end
	
	local character = player.Character
	if not character then return end
	
	-- Create FPS controller
	fps_controller = FPSController.new(character, player_data)
	print("[GameStateManager] FPS Controller initialized")
	
	-- Equip default weapon (melee)
	local melee_data = WeaponData:get_melee_weapon("SWORD")
	current_weapon = MeleeWeapon.new(melee_data, player_data)
	fps_controller:equip_weapon(current_weapon)
	
	print("[GameStateManager] Equipped weapon: Sword")
end

function GameStateManager:show_mission_complete_screen()
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "MissionCompleteScreen"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player.PlayerGui
	
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
	background.BorderSizePixel = 0
	background.Parent = screen_gui
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 0.2, 0)
	text.Position = UDim2.new(0, 0, 0.4, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(100, 255, 100)
	text.TextSize = 64
	text.Font = Enum.Font.GothamBold
	text.Text = "MISSION COMPLETE!"
	text.Parent = screen_gui
end

function GameStateManager:show_mission_failed_screen()
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "MissionFailedScreen"
	screen_gui.ResetOnSpawn = false
	screen_gui.Parent = player.PlayerGui
	
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
	background.BorderSizePixel = 0
	background.Parent = screen_gui
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 0.2, 0)
	text.Position = UDim2.new(0, 0, 0.4, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 100, 100)
	text.TextSize = 64
	text.Font = Enum.Font.GothamBold
	text.Text = "MISSION FAILED!"
	text.Parent = screen_gui
end

function GameStateManager:get_current_state()
	return current_state
end

function GameStateManager:get_fps_controller()
	return fps_controller
end

function GameStateManager:get_player_data()
	return player_data
end

return GameStateManager
