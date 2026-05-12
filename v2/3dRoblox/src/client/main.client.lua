-- GraveGain 3D - Client Entry Point
print("[Client] Client script started!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Get the StarterPlayerScripts folder (parent of this script)
local StarterPlayerScripts = script.Parent
print("[Client] StarterPlayerScripts folder:", StarterPlayerScripts:GetFullName())

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
print("[Client] Constants loaded")

local GatewaySystem = require(StarterPlayerScripts:WaitForChild("gateway_system"))
print("[Client] GatewaySystem loaded")

local GameStateManager = require(StarterPlayerScripts:WaitForChild("game_state_manager"))
print("[Client] GameStateManager loaded")

local MissionHUD = require(StarterPlayerScripts:WaitForChild("mission_hud"))
print("[Client] MissionHUD loaded")

local AdvancedHUD = require(StarterPlayerScripts:WaitForChild("advanced_hud"))
print("[Client] AdvancedHUD loaded")

local Inventory = require(StarterPlayerScripts:WaitForChild("inventory"))
print("[Client] Inventory loaded")

local VFXManager = require(StarterPlayerScripts:WaitForChild("vfx_manager"))
print("[Client] VFXManager loaded")

local AudioManager = require(StarterPlayerScripts:WaitForChild("audio_manager"))
print("[Client] AudioManager loaded")

local SettingsManager = require(StarterPlayerScripts:WaitForChild("settings_manager"))
print("[Client] SettingsManager loaded")

local ResultsScreen = require(StarterPlayerScripts:WaitForChild("results_screen"))
print("[Client] ResultsScreen loaded")

local player = Players.LocalPlayer

print("[Client] GraveGain 3D Client Started")
print("[Client] Player:", player.Name)
print("[Client] Version:", Constants.VERSION)

-- Wait for PlayerGui to exist
local player_gui = player:WaitForChild("PlayerGui")
print("[Client] PlayerGui ready")

-- Initialize systems asynchronously to prevent blocking
task.spawn(function()
	print("[Client] Initializing GatewaySystem...")
	GatewaySystem:initialize()
	print("[Client] GatewaySystem initialized")
end)

task.spawn(function()
	print("[Client] Initializing GameStateManager...")
	GameStateManager:initialize()
	print("[Client] GameStateManager initialized")
end)

task.spawn(function()
	print("[Client] Initializing MissionHUD...")
	MissionHUD:initialize()
	print("[Client] MissionHUD initialized")
end)

task.spawn(function()
	print("[Client] Initializing AdvancedHUD...")
	AdvancedHUD:initialize()
	print("[Client] AdvancedHUD initialized")
end)

task.spawn(function()
	print("[Client] Initializing ResultsScreen...")
	ResultsScreen:initialize()
	print("[Client] ResultsScreen initialized")
end)

task.spawn(function()
	print("[Client] Initializing Inventory...")
	local inventory = Inventory.new()
	inventory:initialize()
	print("[Client] Inventory initialized")
end)

task.spawn(function()
	print("[Client] Initializing VFXManager...")
	local vfx_manager = VFXManager.new()
	vfx_manager:initialize()
	print("[Client] VFXManager initialized")
end)

task.spawn(function()
	print("[Client] Initializing AudioManager...")
	local audio_manager = AudioManager.new()
	audio_manager:initialize()
	print("[Client] AudioManager initialized")
end)

task.spawn(function()
	print("[Client] Initializing SettingsManager...")
	local settings_manager = SettingsManager.new()
	settings_manager:initialize()
	print("[Client] SettingsManager initialized")
	
	-- Setup settings hotkey
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			settings_manager:toggle_settings()
		end
	end)
end)

print("[Client] All systems queued for initialization")
