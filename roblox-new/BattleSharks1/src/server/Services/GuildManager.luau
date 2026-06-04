-- BattleSharks Guild Manager (E4)
-- Guild/clan system with ranks and storage

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local GuildManager = {}

-- GUILD DATA STORE
local guildsDataStore = DataStoreService:GetDataStore("BattleSharksGuilds")

-- GUILD CONFIG
local GUILD_CONFIG = {
	MaxGuildNameLength = 30,
	MinGuildNameLength = 3,
	MaxMembers = 50,
	MaxOfficers = 5,
	CreateCost = 1000, -- Gold
	
	Ranks = {
		LEADER = 3,
		OFFICER = 2,
		MEMBER = 1,
		RECRUIT = 0
	}
}

-- ACTIVE GUILDS (in-memory cache)
local activeGuilds = {}

-- INITIALIZATION
function GuildManager.Initialize()
	GameUtilities.DebugPrint("GuildManager: Initialized")
end

-- GUILD CREATION
function GuildManager.CreateGuild(player, guildName, description)
	-- Validate name
	if not GuildManager.ValidateGuildName(guildName) then
		return false, "Invalid guild name"
	end
	
	-- Check if name exists
	if GuildManager.GuildNameExists(guildName) then
		return false, "Guild name already taken"
	end
	
	-- Check cost
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	if not PlayerDataManager.CanAfford(player, GameEnums.CurrencyType.GOLD, GUILD_CONFIG.CreateCost) then
		return false, "Not enough gold (need " .. GUILD_CONFIG.CreateCost .. ")"
	end
	
	-- Deduct cost
	PlayerDataManager.SpendCurrency(player, GameEnums.CurrencyType.GOLD, GUILD_CONFIG.CreateCost)
	
	-- Create guild
	local guildId = tostring(player.UserId) .. "_" .. tostring(GameUtilities.GetTimestamp())
	local guild = {
		Id = guildId,
		Name = guildName,
		Description = description or "",
		CreatedAt = GameUtilities.GetTimestamp(),
		LeaderId = player.UserId,
		Members = {
			[player.UserId] = {
				UserId = player.UserId,
				Name = player.Name,
				Rank = GUILD_CONFIG.Ranks.LEADER,
				JoinedAt = GameUtilities.GetTimestamp()
			}
		},
		Officers = {},
		TotalXP = 0,
		Level = 1,
		MessageOfTheDay = "",
		Tags = {},
		Settings = {
			InviteOnly = false,
			MinLevel = 1
		}
	}
	
	-- Save
	activeGuilds[guildId] = guild
	GuildManager.SaveGuild(guildId)
	
	-- Update player
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if data then
		data.GuildId = guildId
		data.GuildRank = GUILD_CONFIG.Ranks.LEADER
	end
	
	GameUtilities.DebugPrint("Guild created: " .. guildName .. " by " .. player.Name)
	return true, guild
end

function GuildManager.ValidateGuildName(name)
	if not name or #name < GUILD_CONFIG.MinGuildNameLength then return false end
	if #name > GUILD_CONFIG.MaxGuildNameLength then return false end
	
	-- Check for invalid characters
	if name:match("[^%w%s]") then return false end
	
	return true
end

function GuildManager.GuildNameExists(name)
	for _, guild in pairs(activeGuilds) do
		if guild.Name:lower() == name:lower() then
			return true
		end
	end
	return false
end

-- MEMBER MANAGEMENT
function GuildManager.JoinGuild(player, guildId)
	local guild = activeGuilds[guildId]
	if not guild then return false, "Guild not found" end
	
	-- Check if already in guild
	if guild.Members[player.UserId] then
		return false, "Already in guild"
	end
	
	-- Check invite settings
	if guild.Settings.InviteOnly then
		return false, "Guild is invite only"
	end
	
	-- Check level requirement
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if data and data.Level < guild.Settings.MinLevel then
		return false, "Level too low"
	end
	
	-- Check member limit
	if GuildManager.GetMemberCount(guild) >= GUILD_CONFIG.MaxMembers then
		return false, "Guild is full"
	end
	
	-- Add member
	guild.Members[player.UserId] = {
		UserId = player.UserId,
		Name = player.Name,
		Rank = GUILD_CONFIG.Ranks.RECRUIT,
		JoinedAt = GameUtilities.GetTimestamp()
	}
	
	-- Update player
	if data then
		data.GuildId = guildId
		data.GuildRank = GUILD_CONFIG.Ranks.RECRUIT
	end
	
	GuildManager.SaveGuild(guildId)
	GuildManager.NotifyGuildMembers(guildId, player.Name .. " joined the guild!")
	
	return true
end

function GuildManager.LeaveGuild(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data or not data.GuildId then return false end
	
	local guild = activeGuilds[data.GuildId]
	if not guild then return false end
	
	-- Remove from members
	guild.Members[player.UserId] = nil
	
	-- If leader leaving, disband or transfer
	if data.GuildRank == GUILD_CONFIG.Ranks.LEADER then
		local newLeader = nil
		for _, member in pairs(guild.Members) do
			if member.Rank == GUILD_CONFIG.Ranks.OFFICER then
				newLeader = member
				break
			end
		end
		
		if newLeader then
			newLeader.Rank = GUILD_CONFIG.Ranks.LEADER
			guild.LeaderId = newLeader.UserId
		else
			-- Disband guild
			activeGuilds[data.GuildId] = nil
			GuildManager.DeleteGuild(data.GuildId)
			return true
		end
	end
	
	-- Update player
	data.GuildId = nil
	data.GuildRank = nil
	
	GuildManager.SaveGuild(guild.Id)
	GuildManager.NotifyGuildMembers(guild.Id, player.Name .. " left the guild")
	
	return true
end

function GuildManager.GetMemberCount(guild)
	local count = 0
	for _ in pairs(guild.Members) do count += 1 end
	return count
end

-- RANK MANAGEMENT
function GuildManager.PromoteMember(leader, targetUserId)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local leaderData = PlayerDataManager.GetPlayerData(leader.UserId)
	if not leaderData or not leaderData.GuildId then return false end
	
	local guild = activeGuilds[leaderData.GuildId]
	if not guild then return false end
	
	-- Check leader rank
	if leaderData.GuildRank < GUILD_CONFIG.Ranks.LEADER then return false end
	
	local member = guild.Members[targetUserId]
	if not member then return false end
	
	-- Promote
	if member.Rank < GUILD_CONFIG.Ranks.OFFICER then
		-- Check officer limit
		local officerCount = 0
		for _, m in pairs(guild.Members) do
			if m.Rank == GUILD_CONFIG.Ranks.OFFICER then
				officerCount += 1
			end
		end
		
		if officerCount >= GUILD_CONFIG.MaxOfficers then
			return false, "Max officers reached"
		end
		
		member.Rank = GUILD_CONFIG.Ranks.OFFICER
		guild.Officers[targetUserId] = true
		
		-- Update target player
		local targetData = PlayerDataManager.GetPlayerData(targetUserId)
		if targetData then
			targetData.GuildRank = GUILD_CONFIG.Ranks.OFFICER
		end
		
		GuildManager.SaveGuild(guild.Id)
		return true
	end
	
	return false
end

-- GUILD XP AND LEVELS
function GuildManager.AddGuildXP(guildId, amount)
	local guild = activeGuilds[guildId]
	if not guild then return end
	
	guild.TotalXP += amount
	
	-- Level up check
	local xpForNextLevel = guild.Level * 1000
	while guild.TotalXP >= xpForNextLevel do
		guild.TotalXP -= xpForNextLevel
		guild.Level += 1
		xpForNextLevel = guild.Level * 1000
		
		GuildManager.NotifyGuildMembers(guildId, "Guild leveled up to " .. guild.Level .. "!")
	end
	
	GuildManager.SaveGuild(guildId)
end

-- PERSISTENCE
function GuildManager.SaveGuild(guildId)
	local guild = activeGuilds[guildId]
	if not guild then return end
	
	local success, err = pcall(function()
		guildsDataStore:SetAsync(guildId, guild)
	end)
	
	if not success then
		GameUtilities.LogWarning("Failed to save guild: " .. tostring(err))
	end
end

function GuildManager.LoadGuild(guildId)
	local success, guild = pcall(function()
		return guildsDataStore:GetAsync(guildId)
	end)
	
	if success and guild then
		activeGuilds[guildId] = guild
		return guild
	end
	
	return nil
end

function GuildManager.DeleteGuild(guildId)
	local success, err = pcall(function()
		guildsDataStore:RemoveAsync(guildId)
	end)
	
	if not success then
		GameUtilities.LogWarning("Failed to delete guild: " .. tostring(err))
	end
end

-- NOTIFICATIONS
function GuildManager.NotifyGuildMembers(guildId, message)
	local guild = activeGuilds[guildId]
	if not guild then return end
	
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local event = remoteFolder:FindFirstChild("GuildMessage")
	if not event then return end
	
	for userId, _ in pairs(guild.Members) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			event:FireClient(player, message)
		end
	end
end

-- PUBLIC API
function GuildManager.GetGuild(guildId)
	return activeGuilds[guildId] or GuildManager.LoadGuild(guildId)
end

function GuildManager.GetPlayerGuild(userId)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(userId)
	if data and data.GuildId then
		return GuildManager.GetGuild(data.GuildId)
	end
	return nil
end

function GuildManager.Cleanup()
	-- Save all active guilds
	for guildId, _ in pairs(activeGuilds) do
		GuildManager.SaveGuild(guildId)
	end
	activeGuilds = {}
end

return GuildManager
