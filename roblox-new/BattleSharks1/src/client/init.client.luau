-- BattleSharks Client Initialization
-- Main entry point for the client-side game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Import controllers
local SharkController = require(script.Controllers.SharkController)
local CameraController = require(script.Controllers.CameraController)

-- Client configuration
local CLIENT_CONFIG = {
	ENABLE_DEBUG = true,
	NETWORK_UPDATE_RATE = 20,
	CLIENT_VERSION = "0.1.0"
}

-- Initialize all client systems
local function InitializeClient()
	print("=== BattleSharks Client Starting ===")
	print("Version:", CLIENT_CONFIG.CLIENT_VERSION)
	print("Player:", Players.LocalPlayer.Name)
	
	-- Wait for game to load
	ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	
	-- Initialize controllers
	SharkController.Initialize()
	CameraController.Initialize()
	
	-- Set up network event handlers
	SetupNetworkHandlers()
	
	-- Set up periodic tasks
	SetupPeriodicTasks()
	
	-- Hide default GUI
	SetupUserInterface()
	
	print("=== BattleSharks Client Ready ===")
end

-- Set up network event handlers
local function SetupNetworkHandlers()
	local remoteFolder = ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	
	-- Player stat updates
	local updateStatsEvent = remoteFolder:WaitForChild("UpdatePlayerStats")
	updateStatsEvent.OnClientEvent:Connect(OnPlayerStatsUpdated)
	
	-- Hunger updates
	local hungerEvent = remoteFolder:WaitForChild("UpdateHunger")
	hungerEvent.OnClientEvent:Connect(OnHungerUpdated)
	
	-- Health updates
	local healthEvent = remoteFolder:WaitForChild("UpdateHealth")
	healthEvent.OnClientEvent:Connect(OnHealthUpdated)
	
	-- XP updates
	local xpEvent = remoteFolder:WaitForChild("UpdateXP")
	xpEvent.OnClientEvent:Connect(OnXPUpdated)
	
	-- Level updates
	local levelEvent = remoteFolder:WaitForChild("UpdateLevel")
	levelEvent.OnClientEvent:Connect(OnLevelUpdated)
	
	-- Currency updates
	local goldEvent = remoteFolder:WaitForChild("UpdateGold")
	goldEvent.OnClientEvent:Connect(OnGoldUpdated)
	
	-- Ability cooldowns
	local cooldownEvent = remoteFolder:WaitForChild("AbilityCooldown")
	cooldownEvent.OnClientEvent:Connect(OnAbilityCooldown)
	
	-- Game messages
	local messageEvent = remoteFolder:WaitForChild("GameMessage")
	messageEvent.OnClientEvent:Connect(OnGameMessage)
	
	-- Error messages
	local errorEvent = remoteFolder:WaitForChild("Error")
	errorEvent.OnClientEvent:Connect(OnErrorMessage)
	
	-- Success messages
	local successEvent = remoteFolder:WaitForChild("Success")
	successEvent.OnClientEvent:Connect(OnSuccessMessage)
	
	print("Network handlers configured")
end

-- Set up periodic tasks
local function SetupPeriodicTasks()
	-- Network sync task
	task.spawn(function()
		while true do
			task.wait(1 / CLIENT_CONFIG.NETWORK_UPDATE_RATE)
			
			-- Send periodic updates to server
			SendPeriodicUpdates()
		end
	end)
	
	-- Performance monitoring
	task.spawn(function()
		while true do
			task.wait(60) -- Every minute
			
			local stats = {
				ClientMemory = collectgarbage("count"),
				FPS = math.floor(1 / RunService.Heartbeat:Wait()),
				Ping = GetPing()
			}
			
			print(string.format("Client Stats - Memory: %.2f MB, FPS: %d, Ping: %d ms", 
				stats.ClientMemory / 1024, stats.FPS, stats.Ping))
		end
	end)
	
	print("Periodic tasks configured")
end

-- Set up user interface
local function SetupUserInterface()
	-- Hide default Roblox GUI
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	
	-- Create custom HUD (placeholder)
	CreateBasicHUD()
end

function CreateBasicHUD()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Create main HUD frame
	local hudFrame = Instance.new("ScreenGui")
	hudFrame.Name = "BattleSharksHUD"
	hudFrame.ResetOnSpawn = false
	hudFrame.Parent = playerGui
	
	-- Health bar
	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthFrame"
	healthFrame.Size = UDim2.new(0, 200, 0, 20)
	healthFrame.Position = UDim2.new(0, 10, 0, 10)
	healthFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	healthFrame.BorderSizePixel = 2
	healthFrame.BorderColor3 = Color3.new(1, 1, 1)
	healthFrame.Parent = hudFrame
	
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
	healthBar.Parent = healthFrame
	
	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = "100/100"
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.SourceSansBold
	healthText.Parent = healthFrame
	
	-- Hunger bar
	local hungerFrame = Instance.new("Frame")
	hungerFrame.Name = "HungerFrame"
	hungerFrame.Size = UDim2.new(0, 200, 0, 20)
	hungerFrame.Position = UDim2.new(0, 10, 0, 40)
	hungerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	hungerFrame.BorderSizePixel = 2
	hungerFrame.BorderColor3 = Color3.new(1, 1, 1)
	hungerFrame.Parent = hudFrame
	
	local hungerBar = Instance.new("Frame")
	hungerBar.Name = "HungerBar"
	hungerBar.Size = UDim2.new(1, 0, 1, 0)
	hungerBar.Position = UDim2.new(0, 0, 0, 0)
	hungerBar.BackgroundColor3 = Color3.new(1, 0.5, 0)
	hungerBar.Parent = hungerFrame
	
	local hungerText = Instance.new("TextLabel")
	hungerText.Name = "HungerText"
	hungerText.Size = UDim2.new(1, 0, 1, 0)
	hungerText.BackgroundTransparency = 1
	hungerText.Text = "100/100"
	hungerText.TextColor3 = Color3.new(1, 1, 1)
	hungerText.TextScaled = true
	hungerText.Font = Enum.Font.SourceSansBold
	hungerText.Parent = hungerFrame
	
	-- Level and XP
	local levelFrame = Instance.new("Frame")
	levelFrame.Name = "LevelFrame"
	levelFrame.Size = UDim2.new(0, 200, 0, 40)
	levelFrame.Position = UDim2.new(0, 10, 0, 70)
	levelFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	levelFrame.BorderSizePixel = 2
	levelFrame.BorderColor3 = Color3.new(1, 1, 1)
	levelFrame.Parent = hudFrame
	
	local levelText = Instance.new("TextLabel")
	levelText.Name = "LevelText"
	levelText.Size = UDim2.new(1, 0, 0, 20)
	levelText.Position = UDim2.new(0, 0, 0, 0)
	levelText.BackgroundTransparency = 1
	levelText.Text = "Level 1"
	levelText.TextColor3 = Color3.new(1, 1, 1)
	levelText.TextScaled = true
	levelText.Font = Enum.Font.SourceSansBold
	levelText.Parent = levelFrame
	
	local xpBar = Instance.new("Frame")
	xpBar.Name = "XPBar"
	xpBar.Size = UDim2.new(0.8, 0, 0, 10)
	xpBar.Position = UDim2.new(0.1, 0, 0, 25)
	xpBar.BackgroundColor3 = Color3.new(0, 0.5, 1)
	xpBar.Parent = levelFrame
	
	-- Controls info
	local controlsFrame = Instance.new("Frame")
	controlsFrame.Name = "ControlsFrame"
	controlsFrame.Size = UDim2.new(0, 300, 0, 150)
	controlsFrame.Position = UDim2.new(1, -310, 0, 10)
	controlsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	controlsFrame.BorderSizePixel = 2
	controlsFrame.BorderColor3 = Color3.new(1, 1, 1)
	controlsFrame.Parent = hudFrame
	
	local controlsTitle = Instance.new("TextLabel")
	controlsTitle.Name = "Title"
	controlsTitle.Size = UDim2.new(1, 0, 0, 30)
	controlsTitle.Position = UDim2.new(0, 0, 0, 0)
	controlsTitle.BackgroundTransparency = 1
	controlsTitle.Text = "CONTROLS"
	controlsTitle.TextColor3 = Color3.new(1, 1, 1)
	controlsTitle.TextScaled = true
	controlsTitle.Font = Enum.Font.SourceSansBold
	controlsTitle.Parent = controlsFrame
	
	local controlsText = Instance.new("TextLabel")
	controlsText.Name = "Text"
	controlsText.Size = UDim2.new(1, -10, 1, -40)
	controlsText.Position = UDim2.new(0, 5, 0, 35)
	controlsText.BackgroundTransparency = 1
	controlsText.Text = "WASD - Move\nShift - Boost\nSpace - Leap\nE - Attack\nMouse Wheel - Zoom\nMiddle Mouse - Rotate Camera"
	controlsText.TextColor3 = Color3.new(1, 1, 1)
	controlsText.TextScaled = false
	controlsText.Font = Enum.Font.SourceSans
	controlsText.TextXAlignment = Enum.TextXAlignment.Left
	controlsText.TextYAlignment = Enum.TextYAlignment.Top
	controlsText.Parent = controlsFrame
end

-- NETWORK EVENT HANDLERS
function OnPlayerStatsUpdated(stats)
	print("Player stats updated:", stats)
	
	-- Update HUD
	UpdateHUD(stats)
end

function OnHungerUpdated(hunger)
	print("Hunger updated:", hunger)
	
	local hudFrame = Players.LocalPlayer.PlayerGui:FindFirstChild("BattleSharksHUD")
	if hudFrame then
		local hungerFrame = hudFrame:FindFirstChild("HungerFrame")
		if hungerFrame then
			local hungerBar = hungerFrame:FindFirstChild("HungerBar")
			local hungerText = hungerFrame:FindFirstChild("HungerText")
			
			if hungerBar then
				hungerBar.Size = UDim2.new(hunger / 100, 0, 1, 0)
			end
			if hungerText then
				hungerText.Text = math.floor(hunger) .. "/100"
			end
		end
	end
end

function OnHealthUpdated(health)
	print("Health updated:", health)
	
	local hudFrame = Players.LocalPlayer.PlayerGui:FindFirstChild("BattleSharksHUD")
	if hudFrame then
		local healthFrame = hudFrame:FindFirstChild("HealthFrame")
		if healthFrame then
			local healthBar = healthFrame:FindFirstChild("HealthBar")
			local healthText = healthFrame:FindFirstChild("HealthText")
			
			if healthBar then
				healthBar.Size = UDim2.new(health / 100, 0, 1, 0)
			end
			if healthText then
				healthText.Text = math.floor(health) .. "/100"
			end
		end
	end
end

function OnXPUpdated(xp)
	print("XP updated:", xp)
end

function OnLevelUpdated(level)
	print("Level updated:", level)
	
	local hudFrame = Players.LocalPlayer.PlayerGui:FindFirstChild("BattleSharksHUD")
	if hudFrame then
		local levelFrame = hudFrame:FindFirstChild("LevelFrame")
		if levelFrame then
			local levelText = levelFrame:FindFirstChild("LevelText")
			if levelText then
				levelText.Text = "Level " .. level
			end
		end
	end
end

function OnGoldUpdated(gold)
	print("Gold updated:", gold)
end

function OnAbilityCooldown(abilityName, cooldown)
	print("Ability cooldown:", abilityName, cooldown)
end

function OnGameMessage(message)
	print("Game message:", message)
	StarterGui:SetCore("ChatMakeSystemMessage", {
		Text = "[BattleSharks] " .. message,
		Color = Color3.new(1, 1, 1),
		Font = Enum.Font.SourceSansBold
	})
end

function OnErrorMessage(error)
	print("Error:", error)
	StarterGui:SetCore("ChatMakeSystemMessage", {
		Text = "[ERROR] " .. error,
		Color = Color3.new(1, 0, 0),
		Font = Enum.Font.SourceSansBold
	})
end

function OnSuccessMessage(message)
	print("Success:", message)
	StarterGui:SetCore("ChatMakeSystemMessage", {
		Text = "[SUCCESS] " .. message,
		Color = Color3.new(0, 1, 0),
		Font = Enum.Font.SourceSansBold
	})
end

-- UTILITY FUNCTIONS
function UpdateHUD(stats)
	-- Update HUD elements with new stats
	if stats.Health then
		OnHealthUpdated(stats.Health)
	end
	if stats.Hunger then
		OnHungerUpdated(stats.Hunger)
	end
	if stats.Level then
		OnLevelUpdated(stats.Level)
	end
	if stats.Gold then
		OnGoldUpdated(stats.Gold)
	end
end

function SendPeriodicUpdates()
	-- Send periodic updates to server
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	-- Example: Send position updates (handled by SharkController)
end

function GetPing()
	-- Simple ping calculation
	local startTime = tick()
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local pingFunction = remoteFolder:FindFirstChild("PingClient")
		if pingFunction then
			pingFunction:InvokeServer()
			return math.floor((tick() - startTime) * 1000)
		end
	end
	return 0
end

-- Start the client
InitializeClient()
