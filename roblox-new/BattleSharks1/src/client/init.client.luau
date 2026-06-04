-- BattleSharks Client Initialization
-- Main entry point for the client-side game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Import controllers and systems
local TerrainRenderer = require(script.TerrainRenderer)
local SharkModel = require(script.SharkModel)
local SharkController = require(script.Controllers.SharkController)
local CameraController = require(script.Controllers.CameraController)
local AbilityController = require(script.Controllers.AbilityController)
local UIManager = require(script.UI.UIManager)
local TutorialManager = require(script.UI.TutorialManager)
local SoundManager = require(script.Systems.SoundManager)
local ParticleManager = require(script.Systems.ParticleManager)
local SettingsManager = require(script.Systems.SettingsManager)
local ClientOptimizationManager = require(script.Systems.ClientOptimizationManager)

-- Client configuration
local CLIENT_CONFIG = {
	ENABLE_DEBUG = true,
	NETWORK_UPDATE_RATE = 20,
	CLIENT_VERSION = "0.1.0"
}

-- Event handler functions (must be defined before SetupNetworkHandlers)
local function OnPlayerStatsUpdated(stats)
	print("Player stats updated:", stats)
end

local function OnHungerUpdated(hunger)
	print("Hunger updated:", hunger)
end

local function OnHealthUpdated(health)
	print("Health updated:", health)
end

local function OnXPUpdated(xp)
	print("XP updated:", xp)
end

local function OnLevelUpdated(level)
	print("Level updated:", level)
end

local function OnGoldUpdated(gold)
	print("Gold updated:", gold)
end

local function OnAbilityCooldown(abilityName, cooldown)
	print("Ability cooldown:", abilityName, cooldown)
end

local function OnGameMessage(message)
	print("Game message:", message)
end

local function OnErrorMessage(error)
	print("Error:", error)
end

local function OnSuccessMessage(success)
	print("Success:", success)
end

-- Set up network event handlers
local function SetupNetworkHandlers()
	print("Setting up network handlers...")
	
	local remoteFolder = ReplicatedStorage:WaitForChild("BattleSharksRemotes", 10)
	if not remoteFolder then
		warn("BattleSharksRemotes folder not found!")
		return
	end
	
	-- Connect to server-to-client events
	local eventMap = {
		["UpdatePlayerStats"] = OnPlayerStatsUpdated,
		["UpdateHunger"] = OnHungerUpdated,
		["UpdateHealth"] = OnHealthUpdated,
		["UpdateXP"] = OnXPUpdated,
		["UpdateLevel"] = OnLevelUpdated,
		["UpdateGold"] = OnGoldUpdated,
		["AbilityCooldown"] = OnAbilityCooldown,
		["GameMessage"] = OnGameMessage,
		["Error"] = OnErrorMessage,
		["Success"] = OnSuccessMessage,
	}
	
	for eventName, handler in pairs(eventMap) do
		local remote = remoteFolder:FindFirstChild(eventName)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(handler)
			print("Connected to", eventName)
		else
			warn("RemoteEvent not found:", eventName)
		end
	end
	
	print("Network handlers configured")
end

-- Set up periodic tasks
local function SetupPeriodicTasks()
	print("Setting up periodic tasks...")
	-- Simplified for testing
end

-- Set up user interface
local function SetupUserInterface()
	print("Setting up user interface...")
	-- Simplified for testing
end

-- Initialize all client systems
local function InitializeClient()
	print("=== BattleSharks Client Starting ===")
	print("Version:", CLIENT_CONFIG.CLIENT_VERSION)
	print("Player:", Players.LocalPlayer.Name)
	
	-- Wait for game to load
	ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	
	-- Initialize terrain and controllers
	TerrainRenderer.Initialize()
	SharkController.Initialize()
	CameraController.Initialize()
	
	-- Initialize new systems (D1-D4)
	UIManager.Initialize()
	TutorialManager.Initialize()
	SoundManager.Initialize()
	ParticleManager.Initialize()
	AbilityController.Initialize()
	
	-- Initialize optimization (F)
	ClientOptimizationManager.Initialize()
	
	-- Initialize settings (E7)
	SettingsManager.Initialize()
	
	-- Transform player into shark
	print("Transforming player into shark...")
	local player = Players.LocalPlayer
	if player then
		-- Wait for character to load
		local character = player.Character or player.CharacterAdded:Wait()
		
		-- Transform into shark
		local sharkModel = SharkModel.TransformPlayer(player)
		if sharkModel then
			print("Successfully transformed player into shark!")
		else
			warn("Failed to transform player into shark")
		end
	end
	
	-- Set up network event handlers
	SetupNetworkHandlers()
	
	-- Set up periodic tasks
	SetupPeriodicTasks()
	
	-- Hide default GUI
	SetupUserInterface()
	
	print("=== BattleSharks Client Ready ===")
end

-- Start the client
InitializeClient()
