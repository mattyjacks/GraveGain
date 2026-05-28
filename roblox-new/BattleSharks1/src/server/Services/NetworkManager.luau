-- BattleSharks Network Manager
-- Handles all client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteNames = require(script.Parent.Parent.Parent.Shared.Networking.RemoteNames)
local GameUtilities = require(script.Parent.Parent.Parent.Shared.Utilities.GameUtilities)

local NetworkManager = {}

-- PRIVATE VARIABLES
local remoteEvents = {}
local remoteFunctions = {}

-- INITIALIZATION
function NetworkManager.Initialize()
	GameUtilities.DebugPrint("NetworkManager: Initializing")
	
	-- Create remote events
	NetworkManager.CreateRemoteEvents()
	
	-- Create remote functions
	NetworkManager.CreateRemoteFunctions()
	
	-- Set up event handlers
	NetworkManager.SetupEventHandlers()
	
	GameUtilities.DebugPrint("NetworkManager: Initialized")
end

-- REMOTE EVENTS CREATION
function NetworkManager.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "BattleSharksRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end
	
	-- Create all client-to-server remote events
	for eventName, _ in pairs(RemoteNames.ClientToServer) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = remoteFolder
		remoteEvents[eventName] = remote
	end
	
	-- Create all server-to-client remote events
	for eventName, _ in pairs(RemoteNames.ServerToClient) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = remoteFolder
		remoteEvents[eventName] = remote
	end
	
	GameUtilities.DebugPrint("NetworkManager: Created " .. GameUtilities.GetTableSize(remoteEvents) .. " remote events")
end

function NetworkManager.CreateRemoteFunctions()
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	
	-- Create all client-to-server remote functions
	for functionName, _ in pairs(RemoteNames.ClientFunctions) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = functionName
		remote.Parent = remoteFolder
		remoteFunctions[functionName] = remote
	end
	
	-- Create all server-to-client remote functions
	for functionName, _ in pairs(RemoteNames.ServerFunctions) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = functionName
		remote.Parent = remoteFolder
		remoteFunctions[functionName] = remote
	end
	
	GameUtilities.DebugPrint("NetworkManager: Created " .. GameUtilities.GetTableSize(remoteFunctions) .. " remote functions")
end

-- EVENT HANDLERS
function NetworkManager.SetupEventHandlers()
	-- Player Actions
	NetworkManager.ConnectEvent("PlayerSpawn", NetworkManager.HandlePlayerSpawn)
	NetworkManager.ConnectEvent("PlayerMove", NetworkManager.HandlePlayerMove)
	NetworkManager.ConnectEvent("PlayerAttack", NetworkManager.HandlePlayerAttack)
	NetworkManager.ConnectEvent("PlayerBoost", NetworkManager.HandlePlayerBoost)
	NetworkManager.ConnectEvent("PlayerInteract", NetworkManager.HandlePlayerInteract)
	
	-- Game Systems
	NetworkManager.ConnectEvent("FeedShark", NetworkManager.HandleFeedShark)
	NetworkManager.ConnectEvent("CleanAquarium", NetworkManager.HandleCleanAquarium)
	NetworkManager.ConnectEvent("ApplyMutation", NetworkManager.HandleApplyMutation)
	NetworkManager.ConnectEvent("ChangeClass", NetworkManager.HandleChangeClass)
	NetworkManager.ConnectEvent("UseItem", NetworkManager.HandleUseItem)
	NetworkManager.ConnectEvent("BuyItem", NetworkManager.HandleBuyItem)
	NetworkManager.ConnectEvent("SellItem", NetworkManager.HandleSellItem)
	
	-- Inventory Management
	NetworkManager.ConnectEvent("MoveItem", NetworkManager.HandleMoveItem)
	NetworkManager.ConnectEvent("EquipItem", NetworkManager.HandleEquipItem)
	NetworkManager.ConnectEvent("UnequipItem", NetworkManager.HandleUnequipItem)
	
	-- Aquarium Management
	NetworkManager.ConnectEvent("PlaceDecoration", NetworkManager.HandlePlaceDecoration)
	NetworkManager.ConnectEvent("RemoveDecoration", NetworkManager.HandleRemoveDecoration)
	NetworkManager.ConnectEvent("ChangeBackground", NetworkManager.HandleChangeBackground)
	
	-- Daily Systems
	NetworkManager.ConnectEvent("ClaimDailyReward", NetworkManager.HandleClaimDailyReward)
	NetworkManager.ConnectEvent("ClaimWeeklyReward", NetworkManager.HandleClaimWeeklyReward)
	
	-- Save Systems
	NetworkManager.ConnectEvent("SaveGameData", NetworkManager.HandleSaveGameData)
	NetworkManager.ConnectEvent("LoadGameData", NetworkManager.HandleLoadGameData)
	
	-- Remote Functions
	NetworkManager.ConnectFunction("GetPlayerData", NetworkManager.HandleGetPlayerData)
	NetworkManager.ConnectFunction("GetInventory", NetworkManager.HandleGetInventory)
	NetworkManager.ConnectFunction("GetAquariumData", NetworkManager.HandleGetAquariumData)
	NetworkManager.ConnectFunction("GetShopItems", NetworkManager.HandleGetShopItems)
	NetworkManager.ConnectFunction("GetDailyRewards", NetworkManager.HandleGetDailyRewards)
	NetworkManager.ConnectFunction("CanAffordItem", NetworkManager.HandleCanAffordItem)
end

function NetworkManager.ConnectEvent(eventName, handler)
	local remote = remoteEvents[eventName]
	if remote then
		remote.OnServerEvent:Connect(handler)
	else
		GameUtilities.LogWarning("NetworkManager: RemoteEvent not found: " .. eventName)
	end
end

function NetworkManager.ConnectFunction(functionName, handler)
	local remote = remoteFunctions[functionName]
	if remote then
		remote.OnServerInvoke = handler
	else
		GameUtilities.LogWarning("NetworkManager: RemoteFunction not found: " .. functionName)
	end
end

-- EVENT HANDLERS - PLAYER ACTIONS
function NetworkManager.HandlePlayerSpawn(player, position, className)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " requested spawn at " .. tostring(position))
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if data then
		-- Apply class if specified
		if className and className ~= data.Class then
			PlayerDataManager.ApplyClassStats(player, className)
		end
		
		-- Spawn player (would integrate with character spawning system)
		NetworkManager.SendToClient(player, "UpdatePlayerStats", {
			Health = data.Health,
			MaxHealth = data.MaxHealth,
			Hunger = data.Hunger,
			MaxHunger = data.MaxHunger,
			Speed = data.Speed,
			Class = data.Class,
			Level = data.Level,
			XP = data.XP,
			Gold = data.Gold,
			Crystals = data.Crystals
		})
	end
end

function NetworkManager.HandlePlayerMove(player, position, direction)
	-- Validate movement (anti-cheat)
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	
	local currentPosition = character.PrimaryPart.Position
	local distance = (position - currentPosition).Magnitude
	
	-- Basic movement validation (max speed check)
	if distance > 100 then -- Too far, likely cheating
		GameUtilities.LogWarning("NetworkManager: " .. player.Name .. " attempted invalid movement")
		return
	end
	
	-- Update other clients about movement
	NetworkManager.SendToAllClients("PlayerMove", {
		PlayerId = player.UserId,
		Position = position,
		Direction = direction
	}, player)
end

function NetworkManager.HandlePlayerAttack(player, targetPosition, attackType)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " performed " .. attackType .. " attack")
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	-- Check attack cooldown
	local classData = require(script.Parent.Parent.Parent.Shared.Data.GameData).SharkClasses[data.Class]
	if not classData then return end
	
	local abilityData = classData.Abilities[attackType]
	if not abilityData then return end
	
	local cooldownKey = attackType .. "_Cooldown"
	local lastAttack = data.AbilityCooldowns[cooldownKey] or 0
	local currentTime = tick()
	
	if currentTime - lastAttack < abilityData.Cooldown then
		return -- Still on cooldown
	end
	
	-- Update cooldown
	data.AbilityCooldowns[cooldownKey] = currentTime
	
	-- Calculate damage
	local damage = abilityData.Damage or 0
	local classMultiplier = GameConstants.CLASS_STATS[data.Class].DamageMultiplier or 1
	damage = damage * classMultiplier
	
	-- Find targets in range
	local attackRange = abilityData.Range or 10
	local targets = NetworkManager.FindTargetsInRange(player, targetPosition, attackRange)
	
	-- Deal damage to targets
	local GameLoopManager = require(script.Parent.GameLoopManager)
	for _, target in pairs(targets) do
		if target:IsA("Player") then
			PlayerDataManager.DamagePlayer(target, damage, GameEnums.DamageType.PHYSICAL)
		elseif target:IsA("Model") then
			-- Handle enemy damage
			GameLoopManager.DamageEnemy(target, damage)
		end
	end
	
	-- Notify clients
	NetworkManager.SendToAllClients("PlayerAttack", {
		PlayerId = player.UserId,
		AttackType = attackType,
		Position = targetPosition,
		Targets = NetworkManager.GetTargetIds(targets)
	})
	
	-- Update statistics
	data.Statistics.TotalDamageDealt += damage
	data.Statistics.TotalAbilitiesUsed += 1
end

function NetworkManager.HandlePlayerBoost(player, direction)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " activated boost")
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	-- Check boost cooldown
	local lastBoost = data.AbilityCooldowns["Boost_Cooldown"] or 0
	local currentTime = tick()
	
	if currentTime - lastBoost < GameConstants.SHARK_BOOST_COOLDOWN then
		return -- Still on cooldown
	end
	
	-- Apply boost
	data.AbilityCooldowns["Boost_Cooldown"] = currentTime
	
	-- Notify clients
	NetworkManager.SendToAllClients("PlayerBoost", {
		PlayerId = player.UserId,
		Direction = direction
	})
	
	-- Update statistics
	data.Statistics.TotalBoostsUsed += 1
end

function NetworkManager.HandlePlayerInteract(player, interactableType, interactableId)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " interacted with " .. interactableType)
	
	-- Handle different interaction types
	if interactableType == "Food" then
		NetworkManager.HandleFoodPickup(player, interactableId)
	elseif interactableType == "Decoration" then
		NetworkManager.HandleDecorationInteraction(player, interactableId)
	elseif interactableType == "NPC" then
		NetworkManager.HandleNPCInteraction(player, interactableId)
	end
end

-- EVENT HANDLERS - GAME SYSTEMS
function NetworkManager.HandleFeedShark(player, foodType)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " fed shark with " .. foodType)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	-- Check if player has food
	local foodItem = nil
	for _, item in pairs(data.Inventory) do
		if item.Name == foodType and item.Type == GameEnums.ItemType.FOOD then
			foodItem = item
			break
		end
	end
	
	if not foodItem then
		NetworkManager.SendToClient(player, "Error", "You don't have this food")
		return
	end
	
	-- Remove food from inventory
	if PlayerDataManager.RemoveItem(player, foodItem.Id, 1) then
		-- Feed shark
		local foodData = GameData.Items[foodType]
		if foodData then
			PlayerDataManager.FeedShark(player, foodData.HungerRestore or 20)
			
			-- Heal if food provides healing
			if foodData.HealthRestore and foodData.HealthRestore > 0 then
				PlayerDataManager.HealPlayer(player, foodData.HealthRestore)
			end
		end
		
		-- Notify client
		NetworkManager.SendToClient(player, "UpdateHunger", data.Hunger)
		NetworkManager.SendToClient(player, "Success", "Shark fed successfully!")
	end
end

function NetworkManager.HandleCleanAquarium(player)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " cleaned aquarium")
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	-- Check cooldown
	local currentTime = GameUtilities.GetTimestamp()
	if currentTime - data.LastCleanedTime < GameConstants.AQUARIUM_CLEANUP_COOLDOWN then
		local remainingTime = GameConstants.AQUARIUM_CLEANUP_COOLDOWN - (currentTime - data.LastCleanedTime)
		NetworkManager.SendToClient(player, "Error", "Please wait " .. math.ceil(remainingTime) .. " seconds")
		return
	end
	
	-- Clean aquarium
	data.LastCleanedTime = currentTime
	data.SharkEmotion = GameEnums.EmotionState.HAPPY
	
	-- Award small amount of XP
	PlayerDataManager.AddXP(player, 5)
	
	-- Notify client
	NetworkManager.SendToClient(player, "AquariumStateChanged", {
		Emotion = data.SharkEmotion,
		LastCleanedTime = data.LastCleanedTime
	})
	NetworkManager.SendToClient(player, "Success", "Aquarium cleaned successfully!")
end

function NetworkManager.HandleApplyMutation(player, mutationType)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " applied mutation " .. mutationType)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	
	-- Apply mutation
	local success = PlayerDataManager.ApplyMutation(player, mutationType)
	
	if success then
		NetworkManager.SendToClient(player, "MutationApplied", {
			Type = mutationType,
			Duration = GameConstants.MUTATION_DURATION
		})
		NetworkManager.SendToClient(player, "Success", "Mutation applied successfully!")
	else
		NetworkManager.SendToClient(player, "Error", "Cannot apply this mutation")
	end
end

function NetworkManager.HandleChangeClass(player, newClass)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " changed class to " .. newClass)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	if data.Class == newClass then
		NetworkManager.SendToClient(player, "Error", "You already have this class")
		return
	end
	
	-- Check if player can afford class change
	local classChangeCost = 100 -- Gold cost
	if not PlayerDataManager.CanAfford(player, GameEnums.CurrencyType.GOLD, classChangeCost) then
		NetworkManager.SendToClient(player, "Error", "Not enough gold to change class")
		return
	end
	
	-- Change class
	PlayerDataManager.SpendCurrency(player, GameEnums.CurrencyType.GOLD, classChangeCost)
	PlayerDataManager.ApplyClassStats(player, newClass)
	
	-- Notify client
	NetworkManager.SendToClient(player, "ClassChanged", {
		NewClass = newClass,
		Stats = {
			Health = data.Health,
			MaxHealth = data.MaxHealth,
			Speed = data.Speed
		}
	})
	NetworkManager.SendToClient(player, "Success", "Class changed successfully!")
end

function NetworkManager.HandleUseItem(player, itemId)
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " used item " .. itemId)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	-- Find item in inventory
	local item = nil
	for _, invItem in pairs(data.Inventory) do
		if invItem.Id == itemId then
			item = invItem
			break
		end
	end
	
	if not item then
		NetworkManager.SendToClient(player, "Error", "Item not found")
		return
	end
	
	-- Use item based on type
	if item.Type == GameEnums.ItemType.POTION then
		-- Apply potion effect
		if item.Effect == "Heal" then
			PlayerDataManager.HealPlayer(player, item.Value or 50)
		elseif item.Effect == "SpeedBoost" then
			-- Apply speed boost (would need temporary effect system)
			data.Speed = data.Speed * (item.Value or 1.5)
		end
		
		-- Remove item
		PlayerDataManager.RemoveItem(player, itemId, 1)
		
		NetworkManager.SendToClient(player, "Success", "Item used successfully!")
	else
		NetworkManager.SendToClient(player, "Error", "This item cannot be used")
	end
end

function NetworkManager.HandleBuyItem(player, itemId, quantity)
	quantity = quantity or 1
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " bought " .. quantity .. "x " .. itemId)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	local itemData = GameData.Items[itemId]
	if not itemData then
		NetworkManager.SendToClient(player, "Error", "Item not found")
		return
	end
	
	local totalCost = itemData.Cost * quantity
	
	-- Check if player can afford
	if not PlayerDataManager.CanAfford(player, GameEnums.CurrencyType.GOLD, totalCost) then
		NetworkManager.SendToClient(player, "Error", "Not enough gold")
		return
	end
	
	-- Check inventory space
	if #data.Inventory >= GameConstants.INVENTORY_SLOTS then
		NetworkManager.SendToClient(player, "Error", "Inventory full")
		return
	end
	
	-- Purchase item
	PlayerDataManager.SpendCurrency(player, GameEnums.CurrencyType.GOLD, totalCost)
	PlayerDataManager.AddItem(player, itemData, quantity)
	
	-- Notify client
	NetworkManager.SendToClient(player, "UpdateGold", data.Gold)
	NetworkManager.SendToClient(player, "Success", "Item purchased successfully!")
end

function NetworkManager.HandleSellItem(player, itemId, quantity)
	quantity = quantity or 1
	GameUtilities.DebugPrint("NetworkManager: " .. player.Name .. " sold " .. quantity .. "x " .. itemId)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return end
	
	-- Find item in inventory
	local item = nil
	for _, invItem in pairs(data.Inventory) do
		if invItem.Id == itemId then
			item = invItem
			break
		end
	end
	
	if not item then
		NetworkManager.SendToClient(player, "Error", "Item not found")
		return
	end
	
	local itemData = GameData.Items[item.Name]
	if not itemData then
		NetworkManager.SendToClient(player, "Error", "Item data not found")
		return
	end
	
	-- Calculate sell price (50% of buy price)
	local sellPrice = math.floor((itemData.Cost or 0) * 0.5) * quantity
	
	-- Remove item and give gold
	if PlayerDataManager.RemoveItem(player, itemId, quantity) then
		PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, sellPrice)
		
		-- Notify client
		NetworkManager.SendToClient(player, "UpdateGold", data.Gold)
		NetworkManager.SendToClient(player, "Success", "Item sold for " .. sellPrice .. " gold!")
	end
end

-- UTILITY FUNCTIONS
function NetworkManager.FindTargetsInRange(player, centerPosition, range)
	local targets = {}
	
	-- Check enemy targets
	local GameLoopManager = require(script.Parent.GameLoopManager)
	for _, enemy in pairs(GameLoopManager.GetEnemies()) do
		if enemy.Model and enemy.Model.PrimaryPart then
			local distance = (enemy.Model.PrimaryPart.Position - centerPosition).Magnitude
			if distance <= range then
				table.insert(targets, enemy.Model)
			end
		end
	end
	
	-- Check player targets (for PvP if enabled)
	for _, otherPlayer in pairs(game.Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character.PrimaryPart then
			local distance = (otherPlayer.Character.PrimaryPart.Position - centerPosition).Magnitude
			if distance <= range then
				table.insert(targets, otherPlayer)
			end
		end
	end
	
	return targets
end

function NetworkManager.GetTargetIds(targets)
	local ids = {}
	for _, target in pairs(targets) do
		if target:IsA("Player") then
			table.insert(ids, "Player_" .. target.UserId)
		elseif target:IsA("Model") then
			table.insert(ids, "Model_" .. target:GetFullName())
		end
	end
	return ids
end

-- MESSAGE SENDING
function NetworkManager.SendToClient(player, eventName, data)
	local remote = remoteEvents[eventName]
	if remote then
		remote:FireClient(player, data)
	else
		GameUtilities.LogWarning("NetworkManager: RemoteEvent not found: " .. eventName)
	end
end

function NetworkManager.SendToAllClients(eventName, data, excludePlayer)
	local remote = remoteEvents[eventName]
	if remote then
		for _, player in pairs(game.Players:GetPlayers()) do
			if player ~= excludePlayer then
				remote:FireClient(player, data)
			end
		end
	else
		GameUtilities.LogWarning("NetworkManager: RemoteEvent not found: " .. eventName)
	end
end

-- REMOTE FUNCTION HANDLERS
function NetworkManager.HandleGetPlayerData(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	return PlayerDataManager.GetPlayerData(player.UserId)
end

function NetworkManager.HandleGetInventory(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	return data and data.Inventory or {}
end

function NetworkManager.HandleGetAquariumData(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return {} end
	
	return {
		Decorations = data.AquariumDecorations,
		Background = data.AquariumBackground,
		SharkEmotion = data.SharkEmotion,
		LastFedTime = data.LastFedTime,
		LastCleanedTime = data.LastCleanedTime
	}
end

function NetworkManager.HandleGetShopItems(player)
	local shopItems = {}
	
	for itemName, itemData in pairs(GameData.Items) do
		if itemData.Type == GameEnums.ItemType.POTION or itemData.Type == GameEnums.ItemType.FOOD then
			table.insert(shopItems, {
				Id = itemName,
				Name = itemData.DisplayName,
				Type = itemData.Type,
				Cost = itemData.Cost,
				Description = itemData.Description,
				Rarity = itemData.Rarity
			})
		end
	end
	
	return shopItems
end

function NetworkManager.HandleGetDailyRewards(player)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return {} end
	
	local currentTime = GameUtilities.GetTimestamp()
	local canClaimDaily = not GameUtilities.IsSameDay(currentTime, data.LastDailyReward)
	local canClaimWeekly = (currentTime - data.LastWeeklyReward) >= (7 * 24 * 60 * 60)
	
	return {
		CanClaimDaily = canClaimDaily,
		CanClaimWeekly = canClaimWeekly,
		DailyStreak = data.DailyRewardStreak,
		LastDailyReward = data.LastDailyReward,
		LastWeeklyReward = data.LastWeeklyReward
	}
end

function NetworkManager.HandleCanAffordItem(player, itemId, quantity)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if not data then return false end
	
	local itemData = GameData.Items[itemId]
	if not itemData then return false end
	
	local totalCost = itemData.Cost * (quantity or 1)
	return PlayerDataManager.CanAfford(player, GameEnums.CurrencyType.GOLD, totalCost)
end

-- PLACEHOLDER HANDLERS (to be implemented)
function NetworkManager.HandleMoveItem(player, fromSlot, toSlot)
	-- TODO: Implement inventory item movement
end

function NetworkManager.HandleEquipItem(player, itemId)
	-- TODO: Implement item equipping
end

function NetworkManager.HandleUnequipItem(player, itemId)
	-- TODO: Implement item unequipping
end

function NetworkManager.HandlePlaceDecoration(player, decorationId, position)
	-- TODO: Implement decoration placement
end

function NetworkManager.HandleRemoveDecoration(player, decorationId)
	-- TODO: Implement decoration removal
end

function NetworkManager.HandleChangeBackground(player, backgroundId)
	-- TODO: Implement background changing
end

function NetworkManager.HandleClaimDailyReward(player)
	-- TODO: Implement daily reward claiming
end

function NetworkManager.HandleClaimWeeklyReward(player)
	-- TODO: Implement weekly reward claiming
end

function NetworkManager.HandleSaveGameData(player)
	-- TODO: Implement manual save
end

function NetworkManager.HandleLoadGameData(player)
	-- TODO: Implement manual load
end

function NetworkManager.HandleFoodPickup(player, foodId)
	-- TODO: Implement food pickup
end

function NetworkManager.HandleDecorationInteraction(player, decorationId)
	-- TODO: Implement decoration interaction
end

function NetworkManager.HandleNPCInteraction(player, npcId)
	-- TODO: Implement NPC interaction
end

return NetworkManager
