-- BattleSharks Leaderboard Manager (E3)
-- Global and friend leaderboards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local LeaderboardManager = {}

-- DATA STORES
local leaderboardsDataStore = DataStoreService:GetOrderedDataStore("BattleSharksLeaderboards")

-- LEADERBOARD CONFIG
local LEADERBOARD_CONFIG = {
	UpdateInterval = 300, -- 5 minutes
	MaxEntries = 100,
	Categories = {
		"Level",
		"Kills",
		"Gold",
		"XP",
		"PlayTime"
	}
}

-- CACHE
local leaderboardCache = {
	Level = {},
	Kills = {},
	Gold = {},
	XP = {},
	PlayTime = {}
}
local lastUpdate = 0

-- INITIALIZATION
function LeaderboardManager.Initialize()
	GameUtilities.DebugPrint("LeaderboardManager: Initializing")
	
	-- Update loop
	task.spawn(function()
		while true do
			task.wait(LEADERBOARD_CONFIG.UpdateInterval)
			LeaderboardManager.UpdateAllLeaderboards()
		end
	end)
	
	-- Initial update
	LeaderboardManager.UpdateAllLeaderboards()
	
	GameUtilities.DebugPrint("LeaderboardManager: Initialized")
end

-- UPDATE LEADERBOARDS
function LeaderboardManager.UpdateAllLeaderboards()
	local success, err = pcall(function()
		for _, category in pairs(LEADERBOARD_CONFIG.Categories) do
			LeaderboardManager.UpdateCategory(category)
		end
	end)
	
	if not success then
		GameUtilities.LogWarning("Leaderboard update failed: " .. tostring(err))
	end
	
	lastUpdate = tick()
end

function LeaderboardManager.UpdateCategory(category)
	-- Get top entries from DataStore
	local success, pages = pcall(function()
		return leaderboardsDataStore:GetSortedAsync(false, LEADERBOARD_CONFIG.MaxEntries)
	end)
	
	if not success then return end
	
	local entries = {}
	local page = pages:GetCurrentPage()
	
	for _, entry in pairs(page) do
		table.insert(entries, {
			UserId = entry.key,
			Value = entry.value
		})
	end
	
	leaderboardCache[category] = entries
end

-- SUBMIT SCORES
function LeaderboardManager.SubmitScore(userId, category, value)
	local success, err = pcall(function()
		leaderboardsDataStore:SetAsync(tostring(userId) .. "_" .. category, value)
	end)
	
	if not success then
		GameUtilities.LogWarning("Failed to submit score: " .. tostring(err))
	end
end

function LeaderboardManager.UpdatePlayerStats(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	-- Update all relevant categories
	LeaderboardManager.SubmitScore(player.UserId, "Level", data.Level)
	LeaderboardManager.SubmitScore(player.UserId, "Kills", data.EnemiesKilled or 0)
	LeaderboardManager.SubmitScore(player.UserId, "Gold", data.Gold)
	LeaderboardManager.SubmitScore(player.UserId, "XP", data.TotalXP or data.XP)
	LeaderboardManager.SubmitScore(player.UserId, "PlayTime", data.TimePlayed or 0)
end

-- GET LEADERBOARDS
function LeaderboardManager.GetGlobalLeaderboard(category, count)
	count = count or 50
	local entries = {}
	
	local cached = leaderboardCache[category]
	if cached then
		for i = 1, math.min(count, #cached) do
			local entry = cached[i]
			if entry then
				-- Get player name
				local name = "Unknown"
				local player = Players:GetPlayerByUserId(entry.UserId)
				if player then
					name = player.Name
				end
				
				table.insert(entries, {
					Rank = i,
					UserId = entry.UserId,
					Name = name,
					Value = entry.Value
				})
			end
		end
	end
	
	return entries
end

function LeaderboardManager.GetFriendsLeaderboard(player, category)
	local entries = {}
	local playerData = {}
	
	-- Get player's own score
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if data then
		playerData = {
			UserId = player.UserId,
			Name = player.Name,
			IsPlayer = true,
			Value = LeaderboardManager.GetCategoryValue(data, category)
		}
	end
	
	-- Get friends scores (simplified - would need FriendsService)
	-- For now, just return player vs top 10
	local global = LeaderboardManager.GetGlobalLeaderboard(category, 10)
	
	-- Insert player if not in top 10
	local playerInTop10 = false
	for _, entry in pairs(global) do
		if entry.UserId == player.UserId then
			playerInTop10 = true
			break
		end
	end
	
	if not playerInTop10 then
		table.insert(global, playerData)
	end
	
	-- Sort
	table.sort(global, function(a, b) return a.Value > b.Value end)
	
	-- Add ranks
	for i, entry in pairs(global) do
		entry.Rank = i
	end
	
	return global
end

function LeaderboardManager.GetPlayerRank(userId, category)
	local cached = leaderboardCache[category]
	if not cached then return nil end
	
	for i, entry in pairs(cached) do
		if entry.UserId == userId then
			return i
		end
	end
	
	return nil -- Not ranked
end

function LeaderboardManager.GetCategoryValue(data, category)
	local values = {
		Level = data.Level,
		Kills = data.EnemiesKilled or 0,
		Gold = data.Gold,
		XP = data.TotalXP or data.XP,
		PlayTime = data.TimePlayed or 0
	}
	
	return values[category] or 0
end

-- PUBLIC API
function LeaderboardManager.GetAllCategories()
	return LEADERBOARD_CONFIG.Categories
end

function LeaderboardManager.Cleanup()
	leaderboardCache = {}
end

return LeaderboardManager
