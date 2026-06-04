-- BattleSharks Server Initialization
-- Main entry point for the server-side game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Import services
local TerrainService = require(script.TerrainService)
local PlayerDataManager = require(script.Services.PlayerDataManager)
local GameLoopManager = require(script.Services.GameLoopManager)
local NetworkManager = require(script.Services.NetworkManager)
local PhysicsManager = require(script.Services.PhysicsManager)
local CombatManager = require(script.Services.CombatManager)
local AquariumManager = require(script.Services.AquariumManager)
local InventoryManager = require(script.Services.InventoryManager)
local DailyRewardsManager = require(script.Services.DailyRewardsManager)
local AntiCheatManager = require(script.Services.AntiCheatManager)
local OptimizationManager = require(script.Services.OptimizationManager)
local AchievementManager = require(script.Services.AchievementManager)
local LeaderboardManager = require(script.Services.LeaderboardManager)
local GuildManager = require(script.Services.GuildManager)
local SeasonalEventsManager = require(script.Services.SeasonalEventsManager)
local ReplayManager = require(script.Services.ReplayManager)

-- Game configuration
local GAME_CONFIG = {
	ENABLE_DEBUG = true,
	MAX_PLAYERS = 50,
	AUTO_SAVE_INTERVAL = 300, -- 5 minutes
	SERVER_VERSION = "0.1.0"
}

-- Set up the game environment
local function SetupGameEnvironment()
	print("Setting up game environment...")
	-- Note: FilteringEnabled is set in default.project.json
	print("Game environment configured")
end

-- Set up periodic tasks
local function SetupPeriodicTasks()
	-- Auto-save task
	task.spawn(function()
		while true do
			task.wait(GAME_CONFIG.AUTO_SAVE_INTERVAL)
			
			print("Performing auto-save...")
			PlayerDataManager.Cleanup()
			print("Auto-save completed")
		end
	end)
	
	-- Performance monitoring
	task.spawn(function()
		while true do
			task.wait(60) -- Every minute
			
			local stats = {
				PlayerCount = #Players:GetPlayers(),
				EnemyCount = GameLoopManager.GetEnemyCount(),
				ItemCount = GameLoopManager.GetItemCount(),
				ServerMemory = collectgarbage("count"),
				ElapsedTime = math.floor(tick())
			}
			
			print(string.format("Server Stats - Players: %d, Enemies: %d, Items: %d, Memory: %.2f MB", 
				stats.PlayerCount, stats.EnemyCount, stats.ItemCount, stats.ServerMemory / 1024))
		end
	end)
	
	print("Periodic tasks configured")
end

-- Set up server shutdown handling
local function SetupShutdownHandling()
	game:BindToClose(function()
		print("=== BattleSharks Server Shutting Down ===")
		
		-- Save all player data
		PlayerDataManager.Cleanup()
		
		-- Stop game loop
		GameLoopManager.Cleanup()
		PhysicsManager.Cleanup()
		CombatManager.Cleanup()
		AquariumManager.Cleanup()
		DailyRewardsManager.Cleanup()
		AntiCheatManager.Cleanup()
		OptimizationManager.Cleanup()
		AchievementManager.Cleanup()
		LeaderboardManager.Cleanup()
		GuildManager.Cleanup()
		SeasonalEventsManager.Cleanup()
		ReplayManager.Cleanup()
		
		print("=== BattleSharks Server Shutdown Complete ===")
	end)
end

-- Set up leaderstats
local function SetupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Level stat
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats
	
	-- XP stat (C7)
	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = leaderstats
	
	-- Gold stat
	local gold = Instance.new("IntValue")
	gold.Name = "🪙 Gold"
	gold.Value = 0
	gold.Parent = leaderstats
	
	-- Kills stat
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats
	
	-- Hunger stat (C8)
	local hunger = Instance.new("IntValue")
	hunger.Name = "🍖 Hunger"
	hunger.Value = 100
	hunger.Parent = leaderstats
end

-- Set up player-specific systems
local function SetupPlayerSystems(player)
	print("Setting up player systems for", player.Name)
	NetworkManager.OnPlayerAdded(player)
end

-- Player connection handling
local function OnPlayerAdded(player)
	print("Player joined:", player.Name, "(" .. player.UserId .. ")")
	
	-- Set up player-specific systems with error handling
	local success, errorMessage = pcall(function()
		TerrainService.OnPlayerAdded(player)
		SetupPlayerSystems(player)
		SetupLeaderstats(player)
	end)
	
	if not success then
		warn("Failed to setup player systems for " .. player.Name .. ":", errorMessage)
	end
end

local function OnPlayerRemoving(player)
	print("Player left:", player.Name, "(" .. player.UserId .. ")")
	
	-- Clean up terrain service for player
	local success, errorMessage = pcall(function()
		TerrainService.OnPlayerRemoved(player)
		NetworkManager.OnPlayerRemoving(player)
	end)
	
	if not success then
		warn("Failed to cleanup terrain service for " .. player.Name .. ":", errorMessage)
	end
end

-- Initialize all systems
local function InitializeGame()
	print("=== BattleSharks Server Starting ===")
	print("Version:", GAME_CONFIG.SERVER_VERSION)
	print("Max Players:", GAME_CONFIG.MAX_PLAYERS)
	
	-- Wait for shared modules to be available
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
	if not Shared then
		warn("Shared modules not found!")
		return
	end
	
	-- Set up game environment
	SetupGameEnvironment()
	
	-- Create BattleSharksRemotes folder for client
	local battleSharksRemotes = Instance.new("Folder")
	battleSharksRemotes.Name = "BattleSharksRemotes"
	battleSharksRemotes.Parent = ReplicatedStorage
	
	-- Initialize core services with error handling
	local success, errorMessage = pcall(function()
		TerrainService.Initialize()
		PlayerDataManager.Initialize()
		PhysicsManager.Initialize()
		CombatManager.Initialize()
		AquariumManager.Initialize()
		InventoryManager.Initialize()
		DailyRewardsManager.Initialize()
		AntiCheatManager.Initialize()
		OptimizationManager.Initialize()
		AchievementManager.Initialize()
		LeaderboardManager.Initialize()
		GuildManager.Initialize()
		SeasonalEventsManager.Initialize()
		ReplayManager.Initialize()
		GameLoopManager.Initialize()
		NetworkManager.Initialize()
	end)
	
	if not success then
		warn("Failed to initialize services:", errorMessage)
		return
	end
	
	-- Set up periodic tasks
	SetupPeriodicTasks()
	
	-- Set up server shutdown handling
	SetupShutdownHandling()
	
	print("=== BattleSharks Server Ready ===")
end


-- Configure player character
local function ConfigurePlayerCharacter(character)
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Configure humanoid properties
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.AutoRotate = true
	
	-- Set up character appearance
	SetCharacterAppearance(character)
end

-- Set character appearance based on class
local function SetCharacterAppearance(character)
	-- Default shark appearance
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Create shark model (placeholder)
	local sharkBody = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
	if sharkBody then
		-- Apply shark-like appearance
		sharkBody.BrickColor = BrickColor.new("Medium stone gray")
		
		-- Add fins (placeholder)
		local leftFin = Instance.new("Part")
		leftFin.Name = "LeftFin"
		leftFin.Size = Vector3.new(1, 3, 0.5)
		leftFin.BrickColor = BrickColor.new("Medium stone gray")
		leftFin.Material = Enum.Material.Plastic
		
		local leftFinWeld = Instance.new("Weld")
		leftFinWeld.Part0 = sharkBody
		leftFinWeld.Part1 = leftFin
		leftFinWeld.C0 = CFrame.new(-2, 0, 0)
		leftFinWeld.Parent = leftFin
		
		leftFin.Parent = character
		
		local rightFin = Instance.new("Part")
		rightFin.Name = "RightFin"
		rightFin.Size = Vector3.new(1, 3, 0.5)
		rightFin.BrickColor = BrickColor.new("Medium stone gray")
		rightFin.Material = Enum.Material.Plastic
		
		local rightFinWeld = Instance.new("Weld")
		rightFinWeld.Part0 = sharkBody
		rightFinWeld.Part1 = rightFin
		rightFinWeld.C0 = CFrame.new(2, 0, 0)
		rightFinWeld.Parent = rightFin
		
		rightFin.Parent = character
		
		-- Add tail fin
		local tailFin = Instance.new("Part")
		tailFin.Name = "TailFin"
		tailFin.Size = Vector3.new(0.5, 4, 2)
		tailFin.BrickColor = BrickColor.new("Medium stone gray")
		tailFin.Material = Enum.Material.Plastic
		
		local tailFinWeld = Instance.new("Weld")
		tailFinWeld.Part0 = sharkBody
		tailFinWeld.Part1 = tailFin
		tailFinWeld.C0 = CFrame.new(0, 0, -3)
		tailFinWeld.Parent = tailFin
		
		tailFin.Parent = character
	end
end

-- Update leaderstats
local function UpdateLeaderstats(player)
	local PlayerDataManager = require(script.Services.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	-- Update level
	local levelStat = leaderstats:FindFirstChild("Level")
	if levelStat then
		levelStat.Value = data.Level
	end
	
	-- Update XP (C7)
	local xpStat = leaderstats:FindFirstChild("XP")
	if xpStat then
		xpStat.Value = data.XP
	end
	
	-- Update gold
	local goldStat = leaderstats:FindFirstChild("🪙 Gold")
	if goldStat then
		goldStat.Value = data.Gold
	end
	
	-- Update kills
	local killsStat = leaderstats:FindFirstChild("Kills")
	if killsStat then
		killsStat.Value = data.EnemiesKilled
	end
	
	-- Update Hunger (C8)
	local hungerStat = leaderstats:FindFirstChild("🍖 Hunger")
	if hungerStat then
		hungerStat.Value = math.floor(data.Hunger)
	end
end


-- Connect player events
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Update leaderstats periodically
task.spawn(function()
	while true do
		task.wait(5) -- Update every 5 seconds
		
		for _, player in pairs(Players:GetPlayers()) do
			UpdateLeaderstats(player)
		end
	end
end)

-- Start the game
InitializeGame()
