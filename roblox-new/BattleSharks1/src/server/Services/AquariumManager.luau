-- BattleSharks Aquarium Manager (D7)
-- Server-side aquarium environment and mechanics

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local AquariumManager = {}

-- PRIVATE VARIABLES
local aquariums = {} -- Player aquarium data
local aquariumUpdateConnection = nil

-- AQUARIUM CONFIG
local AQUARIUM_CONFIG = {
	UpdateInterval = 5, -- seconds
	HungerDecay = 0.3, -- per update
	CleanlinessDecay = 0.5, -- per update
	MaxDecorations = GameConstants.AQUARIUM_MAX_DECORATIONS or 20,
	FeedCooldown = GameConstants.AQUARIUM_FEED_COOLDOWN or 30,
	CleanCooldown = GameConstants.AQUARIUM_CLEANUP_COOLDOWN or 60
}

-- DECORATION DATA
local DECORATION_DATA = {
	Coral = { Name = "Coral", Cost = 50, Category = "Plants", Size = Vector3.new(2, 3, 2) },
	Rock = { Name = "Rock", Cost = 30, Category = "Structures", Size = Vector3.new(3, 2, 3) },
	Seaweed = { Name = "Seaweed", Cost = 25, Category = "Plants", Size = Vector3.new(1, 4, 1) },
	TreasureChest = { Name = "Treasure Chest", Cost = 100, Category = "Props", Size = Vector3.new(2, 2, 2) },
	Shipwreck = { Name = "Shipwreck", Cost = 200, Category = "Structures", Size = Vector3.new(10, 5, 15) },
	LightRays = { Name = "Light Rays", Cost = 75, Category = "Lighting", Size = Vector3.new(1, 10, 1) }
}

-- INITIALIZATION
function AquariumManager.Initialize()
	GameUtilities.DebugPrint("AquariumManager: Initializing")
	
	Players.PlayerAdded:Connect(AquariumManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(AquariumManager.OnPlayerRemoving)
	
	-- Start update loop
	aquariumUpdateConnection = RunService.Heartbeat:Connect(AquariumManager.UpdateLoop)
	
	GameUtilities.DebugPrint("AquariumManager: Initialized")
end

function AquariumManager.OnPlayerAdded(player)
	aquariums[player.UserId] = {
		Decorations = {},
		Background = "Default",
		Emotion = "Happy",
		Hunger = 100,
		Cleanliness = 100,
		LastFed = 0,
		LastCleaned = 0,
		SharkScale = 1.0
	}
end

function AquariumManager.OnPlayerRemoving(player)
	aquariums[player.UserId] = nil
end

-- UPDATE LOOP
function AquariumManager.UpdateLoop()
	for _, player in pairs(Players:GetPlayers()) do
		local data = aquariums[player.UserId]
		if data then
			-- Decay hunger and cleanliness
			data.Hunger = math.max(0, data.Hunger - AQUARIUM_CONFIG.HungerDecay)
			data.Cleanliness = math.max(0, data.Cleanliness - AQUARIUM_CONFIG.CleanlinessDecay)
			
			-- Update emotion based on stats
			data.Emotion = AquariumManager.CalculateEmotion(data)
			
			-- Sync to client
			AquariumManager.SyncToClient(player)
		end
	end
	task.wait(AQUARIUM_CONFIG.UpdateInterval)
end

function AquariumManager.CalculateEmotion(data)
	if data.Hunger < 20 or data.Cleanliness < 20 then
		return "Angry"
	elseif data.Hunger < 50 or data.Cleanliness < 50 then
		return "Hungry"
	elseif data.Hunger > 80 and data.Cleanliness > 80 then
		return "Happy"
	else
		return "Playful"
	end
end

-- ACTIONS
function AquariumManager.FeedShark(player)
	local data = aquariums[player.UserId]
	if not data then return false, "No aquarium found" end
	
	local currentTime = tick()
	if currentTime - data.LastFed < AQUARIUM_CONFIG.FeedCooldown then
		return false, "Feed on cooldown"
	end
	
	data.LastFed = currentTime
	data.Hunger = math.min(100, data.Hunger + 40)
	data.Emotion = "Happy"
	
	AquariumManager.SyncToClient(player)
	return true, "Shark fed!"
end

function AquariumManager.CleanAquarium(player)
	local data = aquariums[player.UserId]
	if not data then return false, "No aquarium found" end
	
	local currentTime = tick()
	if currentTime - data.LastCleaned < AQUARIUM_CONFIG.CleanCooldown then
		return false, "Clean on cooldown"
	end
	
	data.LastCleaned = currentTime
	data.Cleanliness = 100
	
	-- Award small XP
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	PlayerDataManager.AddXP(player, 5)
	
	AquariumManager.SyncToClient(player)
	return true, "Aquarium cleaned!"
end

function AquariumManager.PlaceDecoration(player, decorationId, position)
	local data = aquariums[player.UserId]
	if not data then return false end
	
	local decorationData = DECORATION_DATA[decorationId]
	if not decorationData then return false, "Invalid decoration" end
	
	-- Check if can afford
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	if not PlayerDataManager.CanAfford(player, GameEnums.CurrencyType.GOLD, decorationData.Cost) then
		return false, "Not enough gold"
	end
	
	-- Check decoration limit
	if #data.Decorations >= AQUARIUM_CONFIG.MaxDecorations then
		return false, "Max decorations reached"
	end
	
	-- Spend gold
	PlayerDataManager.SpendCurrency(player, GameEnums.CurrencyType.GOLD, decorationData.Cost)
	
	-- Place decoration
	table.insert(data.Decorations, {
		Id = decorationId,
		Position = position,
		Rotation = 0
	})
	
	AquariumManager.SyncToClient(player)
	return true, "Decoration placed"
end

function AquariumManager.RemoveDecoration(player, index)
	local data = aquariums[player.UserId]
	if not data then return false end
	
	if index > 0 and index <= #data.Decorations then
		table.remove(data.Decorations, index)
		AquariumManager.SyncToClient(player)
		return true
	end
	
	return false
end

function AquariumManager.ChangeBackground(player, backgroundId)
	local data = aquariums[player.UserId]
	if not data then return false end
	
	local backgrounds = {"Default", "Reef", "DeepSea", "Arctic", "Tropical"}
	for _, bg in pairs(backgrounds) do
		if bg == backgroundId then
			data.Background = backgroundId
			AquariumManager.SyncToClient(player)
			return true
		end
	end
	
	return false
end

-- SYNC
function AquariumManager.SyncToClient(player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local data = aquariums[player.UserId]
	if not data then return end
	
	local event = remoteFolder:FindFirstChild("AquariumStateChanged")
	if event then
		event:FireClient(player, {
			Emotion = data.Emotion,
			Hunger = data.Hunger,
			Cleanliness = data.Cleanliness,
			Background = data.Background,
			Decorations = data.Decorations
		})
	end
end

-- PUBLIC API
function AquariumManager.GetAquariumData(userId)
	return aquariums[userId]
end

function AquariumManager.GetAvailableDecorations()
	return DECORATION_DATA
end

function AquariumManager.Cleanup()
	if aquariumUpdateConnection then
		aquariumUpdateConnection:Disconnect()
		aquariumUpdateConnection = nil
	end
	aquariums = {}
end

return AquariumManager
