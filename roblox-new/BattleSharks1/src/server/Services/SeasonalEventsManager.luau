-- BattleSharks Seasonal Events Manager (E5)
-- Time-limited events and challenges

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local SeasonalEventsManager = {}

-- EVENT DEFINITIONS
local SEASONAL_EVENTS = {
	{
		Id = "halloween_2024",
		Name = "Spooky Seas",
		Description = "Collect pumpkin fish and earn exclusive Halloween rewards!",
		StartDate = { Month = 10, Day = 1 },
		EndDate = { Month = 11, Day = 7 },
		Type = "Collection",
		Target = 50,
		Rewards = {
			{ Type = "Cosmetic", Id = "PumpkinShark", Name = "Pumpkin Shark Skin" },
			{ Type = "Currency", Gold = 1000, Crystals = 50 }
		},
		SpecialEnemy = "PumpkinFish",
		Theme = {
			WaterColor = Color3.new(0.2, 0.1, 0.3),
			FogColor = Color3.new(0.1, 0.05, 0.1),
			Lighting = "Dark"
		}
	},
	{
		Id = "christmas_2024",
		Name = "Frozen Waters",
		Description = "Defeat the Ice King Shark for holiday treasures!",
		StartDate = { Month = 12, Day = 15 },
		EndDate = { Month = 1, Day = 5 },
		Type = "Boss",
		Target = 1,
		Rewards = {
			{ Type = "Cosmetic", Id = "IceCrown", Name = "Ice Crown" },
			{ Type = "Currency", Gold = 2000, Crystals = 100 }
		},
		SpecialBoss = "IceKing",
		Theme = {
			WaterColor = Color3.new(0.7, 0.9, 1),
			FogColor = Color3.new(0.8, 0.9, 1),
			Lighting = "Bright"
		}
	},
	{
		Id = "summer_splash",
		Name = "Summer Splash",
		Description = "Complete water challenges and earn beach-themed rewards!",
		StartDate = { Month = 6, Day = 21 },
		EndDate = { Month = 8, Day = 31 },
		Type = "Challenge",
		Challenges = {
			{ Name = "Leap Master", Description = "Perform 100 leaps", Target = 100 },
			{ Name = "Speed Demon", Description = "Use boost 200 times", Target = 200 },
			{ Name = "Wave Rider", Description = "Stay at surface for 5 minutes", Target = 300 }
		},
		Rewards = {
			{ Type = "Cosmetic", Id = "SurfboardFin", Name = "Surfboard Fin" },
			{ Type = "Currency", Gold = 1500, Crystals = 75 }
		}
	},
	{
		Id = "double_xp_weekend",
		Name = "Double XP Weekend",
		Description = "Earn double XP all weekend long!",
		Type = "Passive",
		IsRecurring = true,
		DayOfWeek = { 6, 7 }, -- Saturday, Sunday
		Multiplier = { XP = 2.0 }
	}
}

-- ACTIVE EVENTS
local activeEvents = {}
local playerProgress = {} -- UserId -> EventId -> Progress

-- INITIALIZATION
function SeasonalEventsManager.Initialize()
	GameUtilities.DebugPrint("SeasonalEventsManager: Initializing")
	
	-- Check for active events
	SeasonalEventsManager.UpdateActiveEvents()
	
	-- Start check loop
	task.spawn(function()
		while true do
			task.wait(3600) -- Check every hour
			SeasonalEventsManager.UpdateActiveEvents()
		end
	end)
	
	GameUtilities.DebugPrint("SeasonalEventsManager: Initialized")
end

function SeasonalEventsManager.UpdateActiveEvents()
	local currentTime = GameUtilities.GetTimestamp()
	local date = os.date("*t", currentTime)
	
	activeEvents = {}
	
	for _, event in pairs(SEASONAL_EVENTS) do
		local isActive = false
		
		if event.IsRecurring then
			-- Check day of week for recurring events
			for _, day in pairs(event.DayOfWeek) do
				if date.wday == day then
					isActive = true
					break
				end
			end
		else
			-- Check date range
			local startMonth = event.StartDate.Month
			local startDay = event.StartDate.Day
			local endMonth = event.EndDate.Month
			local endDay = event.EndDate.Day
			
			local currentMonthDay = date.month * 100 + date.day
			local startMonthDay = startMonth * 100 + startDay
			local endMonthDay = endMonth * 100 + endDay
			
			-- Handle year wrap
			if endMonthDay < startMonthDay then
				-- Event spans new year
				isActive = currentMonthDay >= startMonthDay or currentMonthDay <= endMonthDay
			else
				isActive = currentMonthDay >= startMonthDay and currentMonthDay <= endMonthDay
			end
		end
		
		if isActive and not activeEvents[event.Id] then
			activeEvents[event.Id] = event
			SeasonalEventsManager.OnEventStart(event)
		end
	end
	
	-- Notify all players
	for _, player in pairs(Players:GetPlayers()) do
		SeasonalEventsManager.SyncActiveEvents(player)
	end
end

function SeasonalEventsManager.OnEventStart(event)
	GameUtilities.DebugPrint("Seasonal event started: " .. event.Name)
	
	-- Apply world theme if applicable
	if event.Theme then
		-- Would apply to game environment
	end
	
	-- Spawn special enemies
	if event.SpecialEnemy or event.SpecialBoss then
		-- Would spawn in GameLoopManager
	end
	
	-- Announce to all players
	for _, player in pairs(Players:GetPlayers()) do
		SeasonalEventsManager.AnnounceEvent(player, event)
	end
end

function SeasonalEventsManager.AnnounceEvent(player, event)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local eventNotify = remoteFolder:FindFirstChild("EventAnnouncement")
	if eventNotify then
		eventNotify:FireClient(player, {
			EventId = event.Id,
			Name = event.Name,
			Description = event.Description,
			Type = event.Type,
			Rewards = event.Rewards
		})
	end
end

function SeasonalEventsManager.SyncActiveEvents(player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local eventSync = remoteFolder:FindFirstChild("ActiveEvents")
	if eventSync then
		eventSync:FireClient(player, activeEvents)
	end
end

-- PROGRESS TRACKING
function SeasonalEventsManager.UpdateProgress(player, eventId, amount)
	if not activeEvents[eventId] then return end
	
	playerProgress[player.UserId] = playerProgress[player.UserId] or {}
	playerProgress[player.UserId][eventId] = (playerProgress[player.UserId][eventId] or 0) + amount
	
	local event = activeEvents[eventId]
	local progress = playerProgress[player.UserId][eventId]
	
	-- Check completion
	if event.Target and progress >= event.Target then
		SeasonalEventsManager.CompleteEvent(player, eventId)
	end
	
	-- Sync progress
	SeasonalEventsManager.SyncProgress(player, eventId, progress)
end

function SeasonalEventsManager.CompleteEvent(player, eventId)
	local event = activeEvents[eventId]
	if not event then return end
	
	-- Check if already completed
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	data.CompletedEvents = data.CompletedEvents or {}
	if data.CompletedEvents[eventId] then return end
	
	-- Mark completed
	data.CompletedEvents[eventId] = GameUtilities.GetTimestamp()
	
	-- Give rewards
	for _, reward in pairs(event.Rewards) do
		if reward.Type == "Currency" then
			if reward.Gold then
				PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, reward.Gold)
			end
			if reward.Crystals then
				PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.CRYSTALS, reward.Crystals)
			end
		elseif reward.Type == "Cosmetic" then
			-- Unlock cosmetic
			data.UnlockedCosmetics = data.UnlockedCosmetics or {}
			data.UnlockedCosmetics[reward.Id] = true
		end
	end
	
	-- Notify
	SeasonalEventsManager.NotifyEventComplete(player, event)
	
	GameUtilities.DebugPrint("Event completed: " .. event.Name .. " by " .. player.Name)
end

function SeasonalEventsManager.NotifyEventComplete(player, event)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local notify = remoteFolder:FindFirstChild("EventComplete")
	if notify then
		notify:FireClient(player, {
			EventId = event.Id,
			Name = event.Name,
			Rewards = event.Rewards
		})
	end
end

function SeasonalEventsManager.SyncProgress(player, eventId, progress)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local sync = remoteFolder:FindFirstChild("EventProgress")
	if sync then
		sync:FireClient(player, {
			EventId = eventId,
			Progress = progress,
			Target = activeEvents[eventId] and activeEvents[eventId].Target
		})
	end
end

-- GET ACTIVE MULTIPLIERS
function SeasonalEventsManager.GetMultipliers()
	local multipliers = {}
	
	for _, event in pairs(activeEvents) do
		if event.Multiplier then
			for stat, value in pairs(event.Multiplier) do
				multipliers[stat] = (multipliers[stat] or 1) * value
			end
		end
	end
	
	return multipliers
end

-- PUBLIC API
function SeasonalEventsManager.GetActiveEvents()
	return activeEvents
end

function SeasonalEventsManager.GetPlayerProgress(userId)
	return playerProgress[userId] or {}
end

function SeasonalEventsManager.Cleanup()
	activeEvents = {}
	playerProgress = {}
end

return SeasonalEventsManager
