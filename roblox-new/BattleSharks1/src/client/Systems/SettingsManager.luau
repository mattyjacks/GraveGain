-- BattleSharks Settings Manager (E7)
-- Graphics and gameplay settings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local SettingsManager = {}

local player = Players.LocalPlayer
local settings = {}
local defaultSettings = {
	-- Graphics
	GraphicsQuality = "High",
	RenderDistance = 1000,
	Shadows = true,
	Particles = true,
	PostProcessing = true,
	WaterReflections = true,
	
	-- Audio
	MasterVolume = 0.8,
	MusicVolume = 0.5,
	SFXVolume = 0.7,
	AmbientSounds = true,
	
	-- Gameplay
	ShowFPS = false,
	ShowPing = false,
	AutoSave = true,
	TutorialEnabled = true,
	QuickCast = false,
	
	-- Controls
	MouseSensitivity = 1.0,
	InvertY = false,
	Keybinds = {
		MoveForward = Enum.KeyCode.W,
		MoveBackward = Enum.KeyCode.S,
		MoveLeft = Enum.KeyCode.A,
		MoveRight = Enum.KeyCode.D,
		Boost = Enum.KeyCode.LeftShift,
		Attack = Enum.UserInputType.MouseButton1,
		Ability1 = Enum.KeyCode.Q,
		Inventory = Enum.KeyCode.I,
		Aquarium = Enum.KeyCode.A
	}
}

-- INITIALIZATION
function SettingsManager.Initialize()
	GameUtilities.DebugPrint("SettingsManager: Initializing")
	
	-- Load saved settings
	SettingsManager.LoadSettings()
	
	-- Apply initial settings
	SettingsManager.ApplyGraphicsSettings()
	
	GameUtilities.DebugPrint("SettingsManager: Initialized")
end

function SettingsManager.LoadSettings()
	-- Load from DataStore or local storage
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local getSettingsFunc = remoteFolder:FindFirstChild("GetSettings")
		if getSettingsFunc then
			local success, saved = pcall(function() return getSettingsFunc:InvokeServer() end)
			if success and saved then
				for key, value in pairs(saved) do
					settings[key] = value
				end
			end
		end
	end
	
	-- Fill defaults for missing
	for key, value in pairs(defaultSettings) do
		if settings[key] == nil then
			settings[key] = value
		end
	end
end

function SettingsManager.SaveSettings()
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local saveSettingsEvent = remoteFolder:FindFirstChild("SaveSettings")
		if saveSettingsEvent then
			saveSettingsEvent:FireServer(settings)
		end
	end
end

-- GRAPHICS SETTINGS
function SettingsManager.ApplyGraphicsSettings()
	local quality = settings.GraphicsQuality
	
	if quality == "Low" then
		settings.RenderDistance = 500
		settings.Shadows = false
		settings.Particles = false
		settings.PostProcessing = false
		settings.WaterReflections = false
		Workspace.Terrain.Decoration = false
		Lighting.GlobalShadows = false
		
	elseif quality == "Medium" then
		settings.RenderDistance = 750
		settings.Shadows = true
		settings.Particles = true
		settings.PostProcessing = false
		settings.WaterReflections = false
		Workspace.Terrain.Decoration = true
		Lighting.GlobalShadows = true
		
	elseif quality == "High" then
		settings.RenderDistance = 1000
		settings.Shadows = true
		settings.Particles = true
		settings.PostProcessing = true
		settings.WaterReflections = true
		Workspace.Terrain.Decoration = true
		Lighting.GlobalShadows = true
	end
	
	-- Apply render distance
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			player.Character.HumanoidRootPart.StreamingMode = Enum.StreamingMode.LowPriority
		end
	end
end

function SettingsManager.SetGraphicsQuality(quality)
	settings.GraphicsQuality = quality
	SettingsManager.ApplyGraphicsSettings()
	SettingsManager.SaveSettings()
end

function SettingsManager.SetRenderDistance(distance)
	settings.RenderDistance = math.clamp(distance, 100, 2000)
	SettingsManager.SaveSettings()
end

-- AUDIO SETTINGS
function SettingsManager.SetMasterVolume(volume)
	settings.MasterVolume = math.clamp(volume, 0, 1)
	SettingsManager.SaveSettings()
end

function SettingsManager.SetMusicVolume(volume)
	settings.MusicVolume = math.clamp(volume, 0, 1)
	
	-- Update sound manager if available
	local SoundManager = require(script.Parent.SoundManager)
	if SoundManager.SetMusicVolume then
		SoundManager.SetMusicVolume(settings.MusicVolume)
	end
	
	SettingsManager.SaveSettings()
end

function SettingsManager.SetSFXVolume(volume)
	settings.SFXVolume = math.clamp(volume, 0, 1)
	
	local SoundManager = require(script.Parent.SoundManager)
	if SoundManager.SetSFXVolume then
		SoundManager.SetSFXVolume(settings.SFXVolume)
	end
	
	SettingsManager.SaveSettings()
end

-- GAMEPLAY SETTINGS
function SettingsManager.SetMouseSensitivity(sensitivity)
	settings.MouseSensitivity = math.clamp(sensitivity, 0.1, 3.0)
	SettingsManager.SaveSettings()
end

function SettingsManager.SetInvertY(invert)
	settings.InvertY = invert
	SettingsManager.SaveSettings()
end

function SettingsManager.SetKeybind(action, keyCode)
	if settings.Keybinds[action] then
		settings.Keybinds[action] = keyCode
		SettingsManager.SaveSettings()
		return true
	end
	return false
end

-- DISPLAY SETTINGS
function SettingsManager.ToggleFPS()
	settings.ShowFPS = not settings.ShowFPS
	
	local fpsUI = player.PlayerGui:FindFirstChild("FPSCounter")
	if settings.ShowFPS then
		if not fpsUI then
			SettingsManager.CreateFPSCounter()
		end
	else
		if fpsUI then
			fpsUI:Destroy()
		end
	end
	
	SettingsManager.SaveSettings()
end

function SettingsManager.CreateFPSCounter()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FPSCounter"
	screenGui.Parent = player.PlayerGui
	
	local label = Instance.new("TextLabel")
	label.Name = "FPSLabel"
	label.Size = UDim2.new(0, 100, 0, 30)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Parent = screenGui
	
	-- Update loop
	task.spawn(function()
		while screenGui and screenGui.Parent do
			local fps = math.floor(1 / RunService.RenderStepped:Wait())
			label.Text = "FPS: " .. fps
			task.wait(0.5)
		end
	end)
end

-- GETTERS
function SettingsManager.GetSetting(key)
	return settings[key]
end

function SettingsManager.GetAllSettings()
	return settings
end

function SettingsManager.GetDefaultSettings()
	return defaultSettings
end

-- RESET
function SettingsManager.ResetToDefaults()
	for key, value in pairs(defaultSettings) do
		settings[key] = value
	end
	
	SettingsManager.ApplyGraphicsSettings()
	SettingsManager.SaveSettings()
end

-- CLEANUP
function SettingsManager.Cleanup()
	SettingsManager.SaveSettings()
end

return SettingsManager
