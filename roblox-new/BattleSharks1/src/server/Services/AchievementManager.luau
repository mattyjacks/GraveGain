-- BattleSharks Achievement Manager (E2)
-- Achievement tracking and rewards system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local AchievementManager = {}

-- ACHIEVEMENT DATABASE
local ACHIEVEMENTS = {
	-- Combat Achievements
	{
		Id = "first_blood",
		Name = "First Blood",
		Description = "Kill your first enemy",
		Category = "Combat",
		Target = 1,
		Reward = { Gold = 50 },
		Icon = "🩸"
	},
	{
		Id = "shark_hunter",
		Name = "Shark Hunter",
		Description = "Kill 100 enemies",
		Category = "Combat",
		Target = 100,
		Reward = { Gold = 500, Crystals = 10 },
		Icon = "🏆"
	},
	{
		Id = "apex_predator",
		Name = "Apex Predator",
		Description = "Kill 1000 enemies",
		Category = "Combat",
		Target = 1000,
		Reward = { Gold = 5000, Crystals = 100, Title = "Apex" },
		Icon = "👑"
	},
	
	-- Level Achievements
	{
		Id = "novice_shark",
		Name = "Novice Shark",
		Description = "Reach level 10",
		Category = "Progression",
		Target = 10,
		Reward = { Gold = 100 },
		Icon = "🦈"
	},
	{
		Id = "experienced_hunter",
		Name = "Experienced Hunter",
		Description = "Reach level 50",
		Category = "Progression",
		Target = 50,
		Reward = { Gold = 1000, Crystals = 25 },
		Icon = "⭐"
	},
	{
		Id = "legendary_beast",
		Name = "Legendary Beast",
		Description = "Reach level 100",
		Category = "Progression",
		Target = 100,
		Reward = { Gold = 10000, Crystals = 500, Title = "Legend" },
		Icon = "🌟"
	},
	
	-- Survival Achievements
	{
		Id = "survivor",
		Name = "Survivor",
		Description = "Survive for 10 minutes without dying",
		Category = "Survival",
		Target = 600, -- seconds
		Reward = { Gold = 200 },
		Icon = "⏱️"
	},
	{
		Id = "well_fed",
		Name = "Well Fed",
		Description = "Eat 50 fish",
		Category = "Survival",
		Target = 50,
		Reward = { Gold = 150 },
		Icon = "🍖"
	},
	
	-- Collection Achievements
	{
		Id = "collector",
		Name = "Collector",
		Description = "Collect 10 different items",
		Category = "Collection",
		Target = 10,
		Reward = { Gold = 300 },
		Icon = "📦"
	},
	{
		Id = "decorator",
		Name = "Decorator",
		Description = "Place 20 decorations in your aquarium",
		Category = "Collection",
		Target = 20,
		Reward = { Gold = 500, Crystals = 15 },
		Icon = "🎨"
	},
	
	-- Social Achievements
	{
		Id = "guild_member",
		Name = "Guild Member",
		Description = "Join a guild",
		Category = "Social",
		Target = 1,
		Reward = { Gold = 100 },
		Icon = "🤝"
	},
	{
		Id = "pvp_champion",
		Name = "PVP Champion",
		Description = "Win 10 PVP battles",
		Category = "Social",
		Target = 10,
		Reward = { Gold = 1000, Crystals = 50 },
		Icon = "⚔️"
	},
	
	-- Special Achievements
	{
		Id = "mutation_master",
		Name = "Mutation Master",
		Description = "Have 5 active mutations at once",
		Category = "Special",
		Target = 5,
		Reward = { Crystals = 100 },
		Icon = "🧬"
	},
	{
		Id = "daily_dedicated",
		Name = "Daily Dedicated",
		Description = "Claim 7 daily rewards in a row",
		Category = "Special",
		Target = 7,
		Reward = { Gold = 700, Crystals = 30 },
		Icon = "📅"
	}
}

-- INITIALIZATION
function AchievementManager.Initialize()
	GameUtilities.DebugPrint("AchievementManager: Initialized")
end

-- CHECK ACHIEVEMENTS
function AchievementManager.CheckAchievement(player, achievementId, currentValue)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	-- Get or initialize achievements
	data.Achievements = data.Achievements or {}
	
	if data.Achievements[achievementId] then
		return -- Already completed
	end
	
	-- Find achievement
	local achievement = nil
	for _, ach in pairs(ACHIEVEMENTS) do
		if ach.Id == achievementId then
			achievement = ach
			break
		end
	end
	
	if not achievement then return end
	
	-- Check progress
	if currentValue >= achievement.Target then
		-- Unlock achievement
		AchievementManager.UnlockAchievement(player, achievement)
	else
		-- Update progress
		data.Achievements[achievementId] = {
			Progress = currentValue,
			Completed = false
		}
	end
end

function AchievementManager.UnlockAchievement(player, achievement)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	data.Achievements = data.Achievements or {}
	data.Achievements[achievement.Id] = {
		Completed = true,
		CompletedTime = GameUtilities.GetTimestamp()
	}
	
	-- Give rewards
	if achievement.Reward.Gold then
		PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, achievement.Reward.Gold)
	end
	if achievement.Reward.Crystals then
		PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.CRYSTALS, achievement.Reward.Crystals)
	end
	if achievement.Reward.Title then
		data.UnlockedTitles = data.UnlockedTitles or {}
		table.insert(data.UnlockedTitles, achievement.Reward.Title)
	end
	
	-- Notify client
	AchievementManager.NotifyAchievementUnlocked(player, achievement)
	
	GameUtilities.DebugPrint("Achievement unlocked: " .. achievement.Name .. " for " .. player.Name)
end

function AchievementManager.NotifyAchievementUnlocked(player, achievement)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local event = remoteFolder:FindFirstChild("AchievementUnlocked")
	if event then
		event:FireClient(player, {
			Id = achievement.Id,
			Name = achievement.Name,
			Description = achievement.Description,
			Icon = achievement.Icon,
			Reward = achievement.Reward
		})
	end
end

-- TRACKING EVENTS
function AchievementManager.OnEnemyKilled(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	local kills = data.EnemiesKilled or 0
	
	AchievementManager.CheckAchievement(player, "first_blood", kills)
	AchievementManager.CheckAchievement(player, "shark_hunter", kills)
	AchievementManager.CheckAchievement(player, "apex_predator", kills)
end

function AchievementManager.OnLevelUp(player, newLevel)
	AchievementManager.CheckAchievement(player, "novice_shark", newLevel)
	AchievementManager.CheckAchievement(player, "experienced_hunter", newLevel)
	AchievementManager.CheckAchievement(player, "legendary_beast", newLevel)
end

function AchievementManager.OnFoodEaten(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	data.FoodEaten = (data.FoodEaten or 0) + 1
	AchievementManager.CheckAchievement(player, "well_fed", data.FoodEaten)
end

function AchievementManager.OnItemCollected(player, itemCount)
	AchievementManager.CheckAchievement(player, "collector", itemCount)
end

function AchievementManager.OnDecorationPlaced(player, decorationCount)
	AchievementManager.CheckAchievement(player, "decorator", decorationCount)
end

function AchievementManager.OnDailyRewardClaimed(player, streak)
	AchievementManager.CheckAchievement(player, "daily_dedicated", streak)
end

function AchievementManager.OnGuildJoined(player)
	AchievementManager.CheckAchievement(player, "guild_member", 1)
end

function AchievementManager.OnPVPWin(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	data.PVPWins = (data.PVPWins or 0) + 1
	AchievementManager.CheckAchievement(player, "pvp_champion", data.PVPWins)
end

-- PUBLIC API
function AchievementManager.GetAchievementData(userId)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(userId)
	if not data then return {} end
	
	return {
		Completed = data.Achievements or {},
		AllAchievements = ACHIEVEMENTS
	}
end

function AchievementManager.GetCompletedCount(userId)
	local data = AchievementManager.GetAchievementData(userId)
	local count = 0
	for _, ach in pairs(data.Completed) do
		if ach.Completed then count += 1 end
	end
	return count
end

function AchievementManager.Cleanup()
	GameUtilities.DebugPrint("AchievementManager: Cleaned up")
end

return AchievementManager
