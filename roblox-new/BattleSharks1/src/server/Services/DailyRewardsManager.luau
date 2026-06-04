-- BattleSharks Daily Rewards Manager (D10)
-- Server-side daily and weekly rewards system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local DailyRewardsManager = {}

-- REWARD CONFIGURATION
local REWARDS_CONFIG = {
	StreakResetDays = 2, -- Reset streak if missed more than 2 days
	MaxStreakBonus = 7, -- Max days for streak bonus
	
	DailyRewards = {
		{ Day = 1, Gold = 50, XP = 25 },
		{ Day = 2, Gold = 75, XP = 35 },
		{ Day = 3, Gold = 100, XP = 50 },
		{ Day = 4, Gold = 150, XP = 75 },
		{ Day = 5, Gold = 200, XP = 100 },
		{ Day = 6, Gold = 250, XP = 125, Crystals = 5 },
		{ Day = 7, Gold = 500, XP = 200, Crystals = 10, Special = "MysteryBox" },
	}
}

-- INITIALIZATION
function DailyRewardsManager.Initialize()
	GameUtilities.DebugPrint("DailyRewardsManager: Initialized")
end

-- DAILY REWARD LOGIC
function DailyRewardsManager.CanClaimDaily(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	local currentTime = GameUtilities.GetTimestamp()
	local lastClaim = data.LastDailyReward or 0
	
	-- Check if same day
	return not GameUtilities.IsSameDay(currentTime, lastClaim)
end

function DailyRewardsManager.CanClaimWeekly(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	local currentTime = GameUtilities.GetTimestamp()
	local lastClaim = data.LastWeeklyReward or 0
	
	-- Check if 7 days passed
	return (currentTime - lastClaim) >= (7 * 24 * 60 * 60)
end

function DailyRewardsManager.ClaimDailyReward(player)
	if not DailyRewardsManager.CanClaimDaily(player) then
		return false, "Already claimed today"
	end
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false, "No player data" end
	
	local currentTime = GameUtilities.GetTimestamp()
	local lastClaim = data.LastDailyReward or 0
	
	-- Check streak continuity
	local daysSinceLastClaim = math.floor((currentTime - lastClaim) / 86400)
	
	if daysSinceLastClaim > REWARDS_CONFIG.StreakResetDays then
		-- Streak broken
		data.DailyRewardStreak = 0
	else
		-- Continue streak
		data.DailyRewardStreak = (data.DailyRewardStreak or 0) + 1
	end
	
	-- Cap streak
	data.DailyRewardStreak = math.min(data.DailyRewardStreak, REWARDS_CONFIG.MaxStreakBonus)
	
	-- Get reward for current day
	local dayIndex = ((data.DailyRewardStreak - 1) % #REWARDS_CONFIG.DailyRewards) + 1
	local reward = REWARDS_CONFIG.DailyRewards[dayIndex]
	
	-- Apply streak bonus
	local streakMultiplier = 1 + (data.DailyRewardStreak * 0.1) -- 10% per streak day
	
	-- Give rewards
	local goldReward = math.floor(reward.Gold * streakMultiplier)
	local xpReward = math.floor(reward.XP * streakMultiplier)
	
	PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, goldReward)
	PlayerDataManager.AddXP(player, xpReward)
	
	if reward.Crystals then
		PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.CRYSTALS, reward.Crystals)
	end
	
	if reward.Special then
		-- Give special reward
		local InventoryManager = require(script.Parent.InventoryManager)
		if reward.Special == "MysteryBox" then
			-- Random premium item
			local possibleItems = {"GoldSkin", "NeonFin", "MutationStabilizer", "PremiumMeat"}
			local randomItem = possibleItems[math.random(1, #possibleItems)]
			InventoryManager.AddItem(player, randomItem, 1)
		end
	end
	
	-- Update last claim
	data.LastDailyReward = currentTime
	
	-- Notify client
	DailyRewardsManager.NotifyRewardClaimed(player, "Daily", reward, data.DailyRewardStreak)
	
	return true, {
		Gold = goldReward,
		XP = xpReward,
		Crystals = reward.Crystals,
		Streak = data.DailyRewardStreak,
		Special = reward.Special
	}
end

function DailyRewardsManager.ClaimWeeklyReward(player)
	if not DailyRewardsManager.CanClaimWeekly(player) then
		return false, "Weekly reward not available"
	end
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	local currentTime = GameUtilities.GetTimestamp()
	
	-- Weekly rewards are more substantial
	local goldReward = 1000
	local xpReward = 500
	local crystalReward = 25
	
	PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, goldReward)
	PlayerDataManager.AddXP(player, xpReward)
	PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.CRYSTALS, crystalReward)
	
	-- Rare item
	local InventoryManager = require(script.Parent.InventoryManager)
	InventoryManager.AddItem(player, "MutationStabilizer", 1)
	
	data.LastWeeklyReward = currentTime
	
	DailyRewardsManager.NotifyRewardClaimed(player, "Weekly", {
		Gold = goldReward,
		XP = xpReward,
		Crystals = crystalReward
	}, 0)
	
	return true, {
		Gold = goldReward,
		XP = xpReward,
		Crystals = crystalReward
	}
end

-- DATA ACCESS
function DailyRewardsManager.GetRewardData(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return nil end
	
	local currentTime = GameUtilities.GetTimestamp()
	
	return {
		CanClaimDaily = DailyRewardsManager.CanClaimDaily(player),
		CanClaimWeekly = DailyRewardsManager.CanClaimWeekly(player),
		DailyStreak = data.DailyRewardStreak or 0,
		LastDailyReward = data.LastDailyReward or 0,
		LastWeeklyReward = data.LastWeeklyReward or 0,
		TimeUntilNextDaily = DailyRewardsManager.GetTimeUntilNextDaily(data.LastDailyReward),
		TimeUntilNextWeekly = DailyRewardsManager.GetTimeUntilNextWeekly(data.LastWeeklyReward),
		Rewards = REWARDS_CONFIG.DailyRewards
	}
end

function DailyRewardsManager.GetTimeUntilNextDaily(lastClaim)
	if not lastClaim or lastClaim == 0 then return 0 end
	
	local currentTime = GameUtilities.GetTimestamp()
	local lastClaimDay = math.floor(lastClaim / 86400)
	local currentDay = math.floor(currentTime / 86400)
	
	if lastClaimDay < currentDay then
		return 0 -- Can claim now
	end
	
	-- Calculate time until next midnight
	local nextMidnight = (currentDay + 1) * 86400
	return nextMidnight - currentTime
end

function DailyRewardsManager.GetTimeUntilNextWeekly(lastClaim)
	if not lastClaim or lastClaim == 0 then return 0 end
	
	local currentTime = GameUtilities.GetTimestamp()
	local daysSince = (currentTime - lastClaim) / 86400
	
	if daysSince >= 7 then
		return 0 -- Can claim now
	end
	
	return (7 - daysSince) * 86400
end

-- NOTIFICATIONS
function DailyRewardsManager.NotifyRewardClaimed(player, rewardType, rewardData, streak)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local event = remoteFolder:FindFirstChild("DailyRewardClaimed")
	if event then
		event:FireClient(player, {
			Type = rewardType,
			Reward = rewardData,
			Streak = streak
		})
	end
end

-- CLEANUP
function DailyRewardsManager.Cleanup()
	GameUtilities.DebugPrint("DailyRewardsManager: Cleaned up")
end

return DailyRewardsManager
