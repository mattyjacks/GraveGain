-- BattleSharks Player Data Manager
-- Handles all player data storage, loading, and saving

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Temporary: Use placeholder values until shared modules are working
local GameConstants = {
	WATER_LEVEL = 0,
	UNDERWATER_GRAVITY = 10,
	WATER_DENSITY = 1,
	SHARK_TURN_SPEED = 5,
	SHARK_BASE_SPEED = 16,
	SHARK_BOOST_SPEED = 32,
	SHARK_BOOST_COOLDOWN = 3,
	SHARK_LEAP_FORCE = 100,
	BITE_RANGE = 10
}
local GameEnums = {
	EnemyType = {
		SmallFish = "SmallFish",
		MediumFish = "MediumFish",
		LargeFish = "LargeFish",
		Jellyfish = "Jellyfish",
		Shark = "Shark"
	},
	ItemType = {
		Food = "Food",
		HealthPotion = "HealthPotion",
		SpeedBoost = "SpeedBoost",
		Treasure = "Treasure"
	}
}
local GameData = {
	EnemyData = {
		SmallFish = {Health = 20, Damage = 5, Speed = 15, XP = 10},
		MediumFish = {Health = 50, Damage = 10, Speed = 12, XP = 25},
		LargeFish = {Health = 100, Damage = 20, Speed = 8, XP = 50}
	}
}
local GameUtilities = {
	DebugPrint = function(message) print("[DEBUG]", message) end,
	LogWarning = function(message) warn("[WARNING]", message) end,
	Clamp = function(value, min, max) return math.max(min, math.min(max, value)) end,
	Lerp = function(a, b, t) return a + (b - a) * t end,
	RandomFloat = function(min, max) return math.random() * (max - min) + min end,
	DeepCopy = function(tbl)
		local copy = {}
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				copy[k] = GameUtilities.DeepCopy(v)
			else
				copy[k] = v
			end
		end
		return copy
	end,
	GetTimestamp = function() return os.time() end,
	IsSameDay = function(timestamp1, timestamp2)
		if not timestamp1 or not timestamp2 then return false end
		local day1 = math.floor(timestamp1 / 86400)
		local day2 = math.floor(timestamp2 / 86400)
		return day1 == day2
	end
}

local PlayerDataManager = {}

-- PRIVATE VARIABLES
local playerData = {}
local dataStoreService = nil
local playerDataStore = nil

-- DEFAULT PLAYER DATA
local function getDefaultPlayerData()
	return {
		-- Basic Info
		UserId = 0,
		Username = "",
		Level = 1,
		XP = 0,
		TotalXP = 0,
		
		-- Stats
		Health = GameConstants.SHARK_BASE_HEALTH,
		MaxHealth = GameConstants.SHARK_BASE_HEALTH,
		Hunger = GameConstants.HUNGER_MAX,
		MaxHunger = GameConstants.HUNGER_MAX,
		Speed = GameConstants.SHARK_BASE_SPEED,
		
		-- Class System
		Class = GameEnums.SharkClass.FIGHTER,
		ClassLevel = 1,
		ClassXP = 0,
		
		-- Currency
		Gold = GameConstants.STARTING_GOLD,
		Crystals = GameConstants.STARTING_CRYSTALS,
		
		-- Abilities
		AbilityCooldowns = {},
		UnlockedAbilities = {"BasicAttack"},
		
		-- Inventory
		Inventory = {},
		EquippedItems = {},
		Warehouse = {},
		
		-- Aquarium
		AquariumDecorations = {},
		AquariumBackground = "Default",
		SharkEmotion = GameEnums.EmotionState.HAPPY,
		LastFedTime = 0,
		LastCleanedTime = 0,
		
		-- Mutations
		ActiveMutations = {},
		MutationHistory = {},
		LastMutationReset = 0,
		
		-- Cosmetics
		UnlockedCosmetics = {},
		EquippedCosmetics = {},
		
		-- Progress
		EnemiesKilled = 0,
		FoodEaten = 0,
		TimePlayed = 0,
		SessionsPlayed = 0,
		
		-- Daily Rewards
		LastDailyReward = 0,
		LastWeeklyReward = 0,
		DailyRewardStreak = 0,
		
		-- Social
		Friends = {},
		GuildId = nil,
		GuildRank = nil,
		
		-- Settings
		GraphicsQuality = "Medium",
		MasterVolume = 0.8,
		SFXVolume = 0.7,
		MusicVolume = 0.5,
		ControlScheme = "Keyboard",
		
		-- Statistics
		Statistics = {
			TotalDamageDealt = 0,
			TotalDamageTaken = 0,
			TotalHealingDone = 0,
			TotalDistanceTraveled = 0,
			TotalBoostsUsed = 0,
			TotalAbilitiesUsed = 0,
			DeathCount = 0,
			HighestLevelReached = 1,
			MostGoldOwned = GameConstants.STARTING_GOLD,
			LargestMealEaten = 0,
			FastestSpeed = 0
		},
		
		-- Timestamps
		CreatedTime = GameUtilities.GetTimestamp(),
		LastLoginTime = GameUtilities.GetTimestamp(),
		LastSaveTime = GameUtilities.GetTimestamp()
	}
end

-- INITIALIZATION
function PlayerDataManager.Initialize()
	if RunService:IsStudio() then
		-- In studio, use memory storage
		GameUtilities.DebugPrint("PlayerDataManager: Using in-studio memory storage")
	else
		-- In production, use DataStore
		dataStoreService = game:GetService("DataStoreService")
		playerDataStore = dataStoreService:GetDataStore("BattleSharksPlayerData")
		GameUtilities.DebugPrint("PlayerDataManager: Using DataStore storage")
	end
	
	-- Set up player events
	Players.PlayerAdded:Connect(PlayerDataManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerDataManager.OnPlayerRemoving)
	
	GameUtilities.DebugPrint("PlayerDataManager: Initialized")
end

-- PLAYER EVENTS
function PlayerDataManager.OnPlayerAdded(player)
	GameUtilities.DebugPrint("PlayerDataManager: Loading data for " .. player.Name)
	
	local success, data = pcall(function()
		return PlayerDataManager.LoadPlayerData(player.UserId)
	end)
	
	if not success then
		GameUtilities.LogWarning("Failed to load player data for " .. player.Name .. ": " .. tostring(data))
		data = getDefaultPlayerData()
	end
	
	-- Set basic info
	data.UserId = player.UserId
	data.Username = player.Name
	data.LastLoginTime = GameUtilities.GetTimestamp()
	data.SessionsPlayed = (data.SessionsPlayed or 0) + 1
	
	-- Store in memory
	playerData[player.UserId] = data
	
	-- Apply class stats
	PlayerDataManager.ApplyClassStats(player, data.Class)
	
	-- Initialize hunger system
	PlayerDataManager.StartHungerSystem(player)
	
	GameUtilities.DebugPrint("PlayerDataManager: Data loaded for " .. player.Name)
end

function PlayerDataManager.OnPlayerRemoving(player)
	GameUtilities.DebugPrint("PlayerDataManager: Saving data for " .. player.Name)
	
	local data = playerData[player.UserId]
	if data then
		data.LastSaveTime = GameUtilities.GetTimestamp()
		data.TimePlayed = data.TimePlayed + (GameUtilities.GetTimestamp() - data.LastLoginTime)
		
		local success, errorMessage = pcall(function()
			PlayerDataManager.SavePlayerData(player.UserId, data)
		end)
		
		if not success then
			GameUtilities.LogWarning("Failed to save player data for " .. player.Name .. ": " .. tostring(errorMessage))
		end
		
		playerData[player.UserId] = nil
	end
end

-- DATA STORAGE
function PlayerDataManager.LoadPlayerData(userId)
	if RunService:IsStudio() then
		-- In studio, return default data
		return getDefaultPlayerData()
	else
		-- In production, load from DataStore
		return playerDataStore:GetAsync(tostring(userId))
	end
end

function PlayerDataManager.SavePlayerData(userId, data)
	if RunService:IsStudio() then
		-- In studio, no need to save
		return true
	else
		-- In production, save to DataStore
		local success, result = pcall(function()
			return playerDataStore:SetAsync(tostring(userId), data)
		end)
		
		return success, result
	end
end

-- DATA ACCESS
function PlayerDataManager.GetPlayerData(userId)
	return playerData[userId]
end

function PlayerDataManager.UpdatePlayerData(userId, updates)
	local data = playerData[userId]
	if not data then
		GameUtilities.LogWarning("Attempted to update data for non-existent player: " .. tostring(userId))
		return false
	end
	
	for key, value in pairs(updates) do
		if type(value) == "table" and type(data[key]) == "table" then
			-- Merge tables
			for subKey, subValue in pairs(value) do
				data[key][subKey] = subValue
			end
		else
			data[key] = value
		end
	end
	
	return true
end

-- STATS MANAGEMENT
function PlayerDataManager.ApplyClassStats(player, className)
	local data = playerData[player.UserId]
	if not data then return end
	
	local classData = GameData.SharkClasses[className]
	if not classData then return end
	
	-- Apply class multipliers
	local statsMultiplier = GameConstants.CLASS_STATS[className]
	
	data.MaxHealth = classData.StartingHealth * (statsMultiplier.HealthMultiplier or 1)
	data.Speed = classData.StartingSpeed * (statsMultiplier.SpeedMultiplier or 1)
	
	-- Update current health if it exceeds max
	if data.Health > data.MaxHealth then
		data.Health = data.MaxHealth
	end
	
	data.Class = className
	
	GameUtilities.DebugPrint("PlayerDataManager: Applied " .. className .. " stats to " .. player.Name)
end

function PlayerDataManager.AddXP(player, amount)
	local data = playerData[player.UserId]
	if not data then return end
	
	amount = math.floor(amount)
	data.XP += amount
	data.TotalXP += amount
	
	-- Check for level up
	local xpForNextLevel = GameUtilities.CalculateXPForLevel(data.Level)
	while data.XP >= xpForNextLevel and data.Level < GameConstants.MAX_LEVEL do
		data.XP -= xpForNextLevel
		data.Level += 1
		
		-- Level up rewards
		PlayerDataManager.OnLevelUp(player, data.Level)
		
		xpForNextLevel = GameUtilities.CalculateXPForLevel(data.Level)
	end
	
	GameUtilities.DebugPrint("PlayerDataManager: Added " .. amount .. " XP to " .. player.Name)
end

function PlayerDataManager.OnLevelUp(player, newLevel)
	local data = playerData[player.UserId]
	if not data then return end
	
	-- Level up rewards
	local goldReward = newLevel * 10
	local crystalReward = math.floor(newLevel / 5)
	
	data.Gold += goldReward
	data.Crystals += crystalReward
	
	-- Increase stats
	data.MaxHealth += 5
	data.Health = data.MaxHealth -- Full heal on level up
	
	-- Notify client (would connect to RemoteEvent)
	GameUtilities.DebugPrint("PlayerDataManager: " .. player.Name .. " reached level " .. newLevel)
end

-- HUNGER SYSTEM
function PlayerDataManager.StartHungerSystem(player)
	local data = playerData[player.UserId]
	if not data then return end
	
	-- Create hunger decay loop
	task.spawn(function()
		while player.Parent == Players do
			task.wait(1) -- Every second
			
			data = playerData[player.UserId]
			if not data then break end
			
			-- Decay hunger
			data.Hunger = math.max(0, data.Hunger - GameConstants.HUNGER_DECAY_RATE)
			
			-- Apply hunger damage if too hungry
			if data.Hunger <= GameConstants.HUNGER_DAMAGE_THRESHOLD then
				PlayerDataManager.DamagePlayer(player, GameConstants.HUNGER_DAMAGE_RATE, "Hunger")
			end
		end
	end)
end

function PlayerDataManager.FeedShark(player, amount)
	local data = playerData[player.UserId]
	if not data then return end
	
	data.Hunger = math.min(data.MaxHunger, data.Hunger + amount)
	data.LastFedTime = GameUtilities.GetTimestamp()
	
	-- Update emotion
	if data.Hunger >= data.MaxHunger * 0.8 then
		data.SharkEmotion = GameEnums.EmotionState.HAPPY
	elseif data.Hunger >= data.MaxHunger * 0.4 then
		data.SharkEmotion = GameEnums.EmotionState.PLAYFUL
	else
		data.SharkEmotion = GameEnums.EmotionState.HUNGRY
	end
end

-- COMBAT SYSTEM
function PlayerDataManager.DamagePlayer(player, damage, damageType)
	local data = playerData[player.UserId]
	if not data then return end
	
	data.Health = math.max(0, data.Health - damage)
	data.Statistics.TotalDamageTaken += damage
	
	-- Update statistics
	if data.Health <= 0 then
		data.Statistics.DeathCount += 1
		PlayerDataManager.OnPlayerDied(player)
	end
end

function PlayerDataManager.HealPlayer(player, amount)
	local data = playerData[player.UserId]
	if not data then return end
	
	local actualHeal = math.min(amount, data.MaxHealth - data.Health)
	data.Health += actualHeal
	data.Statistics.TotalHealingDone += actualHeal
end

function PlayerDataManager.OnPlayerDied(player)
	local data = playerData[player.UserId]
	if not data then return end
	
	-- Reset player state
	data.Hunger = data.MaxHunger * 0.5
	data.Health = data.MaxHealth
	
	-- Clear some temporary effects
	data.ActiveMutations = {}
	
	GameUtilities.DebugPrint("PlayerDataManager: " .. player.Name .. " died and respawned")
end

-- INVENTORY SYSTEM
function PlayerDataManager.AddItem(player, itemData, quantity)
	quantity = quantity or 1
	local data = playerData[player.UserId]
	if not data then return false end
	
	-- Check if item already exists in inventory
	for _, item in pairs(data.Inventory) do
		if item.Id == itemData.Id and item.Type == GameEnums.ItemType.POTION then
			-- Stack potions
			item.Quantity = (item.Quantity or 1) + quantity
			return true
		end
	end
	
	-- Add new item
	local newItem = GameUtilities.DeepCopy(itemData)
	newItem.Quantity = quantity
	newItem.AcquiredTime = GameUtilities.GetTimestamp()
	
	table.insert(data.Inventory, newItem)
	return true
end

function PlayerDataManager.RemoveItem(player, itemId, quantity)
	quantity = quantity or 1
	local data = playerData[player.UserId]
	if not data then return false end
	
	for i, item in pairs(data.Inventory) do
		if item.Id == itemId then
			if item.Quantity <= quantity then
				-- Remove entire item
				table.remove(data.Inventory, i)
				return true
			else
				-- Reduce quantity
				item.Quantity -= quantity
				return true
			end
		end
	end
	
	return false
end

-- CURRENCY SYSTEM
function PlayerDataManager.AddCurrency(player, currencyType, amount)
	local data = playerData[player.UserId]
	if not data then return false end
	
	if currencyType == GameEnums.CurrencyType.GOLD then
		data.Gold += amount
		data.Statistics.MostGoldOwned = math.max(data.Statistics.MostGoldOwned, data.Gold)
	elseif currencyType == GameEnums.CurrencyType.CRYSTALS then
		data.Crystals += amount
	end
	
	return true
end

function PlayerDataManager.CanAfford(player, currencyType, amount)
	local data = playerData[player.UserId]
	if not data then return false end
	
	if currencyType == GameEnums.CurrencyType.GOLD then
		return data.Gold >= amount
	elseif currencyType == GameEnums.CurrencyType.CRYSTALS then
		return data.Crystals >= amount
	end
	
	return false
end

function PlayerDataManager.SpendCurrency(player, currencyType, amount)
	if not PlayerDataManager.CanAfford(player, currencyType, amount) then
		return false
	end
	
	local data = playerData[player.UserId]
	if not data then return false end
	
	if currencyType == GameEnums.CurrencyType.GOLD then
		data.Gold -= amount
	elseif currencyType == GameEnums.CurrencyType.CRYSTALS then
		data.Crystals -= amount
	end
	
	return true
end

-- MUTATION SYSTEM
function PlayerDataManager.ApplyMutation(player, mutationType)
	local data = playerData[player.UserId]
	if not data then return false end
	
	-- Check if player already has this mutation
	for _, mutation in pairs(data.ActiveMutations) do
		if mutation.Type == mutationType then
			return false -- Already has this mutation
		end
	end
	
	-- Apply mutation
	local mutationData = GameData.Mutations[mutationType]
	if not mutationData then return false end
	
	local newMutation = {
		Type = mutationType,
		AppliedTime = GameUtilities.GetTimestamp(),
		Duration = GameConstants.MUTATION_DURATION,
		StatEffects = mutationData.StatEffect or {}
	}
	
	table.insert(data.ActiveMutations, newMutation)
	table.insert(data.MutationHistory, {
		Type = mutationType,
		AppliedTime = GameUtilities.GetTimestamp()
	})
	
	return true
end

function PlayerDataManager.ClearExpiredMutations(player)
	local data = playerData[player.UserId]
	if not data then return end
	
	local currentTime = GameUtilities.GetTimestamp()
	local remainingMutations = {}
	
	for _, mutation in pairs(data.ActiveMutations) do
		if currentTime - mutation.AppliedTime < mutation.Duration then
			table.insert(remainingMutations, mutation)
		end
	end
	
	data.ActiveMutations = remainingMutations
end

-- CLEANUP
function PlayerDataManager.Cleanup()
	for userId, data in pairs(playerData) do
		PlayerDataManager.SavePlayerData(userId, data)
	end
	playerData = {}
end

return PlayerDataManager
