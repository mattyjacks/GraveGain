-- BattleSharks Inventory Manager (D8)
-- Server-side inventory and item management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local InventoryManager = {}

-- ITEM DATABASE
local ITEM_DATABASE = {
	-- Food
	SmallFish = { Id = "SmallFish", Name = "Small Fish", Type = GameEnums.ItemType.FOOD, Rarity = GameEnums.Rarity.COMMON, HungerRestore = 15, Cost = 10 },
	LargeFish = { Id = "LargeFish", Name = "Large Fish", Type = GameEnums.ItemType.FOOD, Rarity = GameEnums.Rarity.UNCOMMON, HungerRestore = 40, Cost = 25 },
	PremiumMeat = { Id = "PremiumMeat", Name = "Premium Meat", Type = GameEnums.ItemType.FOOD, Rarity = GameEnums.Rarity.RARE, HungerRestore = 80, Cost = 60 },
	
	-- Potions
	HealthPotion = { Id = "HealthPotion", Name = "Health Potion", Type = GameEnums.ItemType.POTION, Rarity = GameEnums.Rarity.UNCOMMON, HealAmount = 50, Cost = 30 },
	SpeedPotion = { Id = "SpeedPotion", Name = "Speed Potion", Type = GameEnums.ItemType.POTION, Rarity = GameEnums.Rarity.RARE, SpeedBoost = 1.5, Duration = 30, Cost = 75 },
	MutationStabilizer = { Id = "MutationStabilizer", Name = "Mutation Stabilizer", Type = GameEnums.ItemType.MUTATION_STABILIZER, Rarity = GameEnums.Rarity.EPIC, Cost = 200 },
	
	-- Cosmetics
	GoldSkin = { Id = "GoldSkin", Name = "Gold Skin", Type = GameEnums.ItemType.COSMETIC, Rarity = GameEnums.Rarity.LEGENDARY, Cost = 500 },
	NeonFin = { Id = "NeonFin", Name = "Neon Fin", Type = GameEnums.ItemType.COSMETIC, Rarity = GameEnums.Rarity.RARE, Cost = 150 },
	
	-- Decorations
	Coral = { Id = "Coral", Name = "Coral", Type = GameEnums.ItemType.DECORATION, Rarity = GameEnums.Rarity.COMMON, Cost = 50 },
	TreasureChest = { Id = "TreasureChest", Name = "Treasure Chest", Type = GameEnums.ItemType.DECORATION, Rarity = GameEnums.Rarity.UNCOMMON, Cost = 100 }
}

-- INITIALIZATION
function InventoryManager.Initialize()
	GameUtilities.DebugPrint("InventoryManager: Initialized")
end

-- INVENTORY OPERATIONS
function InventoryManager.AddItem(player, itemId, quantity)
	if not player then return false end
	quantity = quantity or 1
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	local itemData = ITEM_DATABASE[itemId]
	if not itemData then return false end
	
	-- Check inventory space
	if #data.Inventory >= GameConstants.INVENTORY_SLOTS then
		return false, "Inventory full"
	end
	
	-- Stack if same item exists (for consumables)
	if itemData.Type == GameEnums.ItemType.POTION or itemData.Type == GameEnums.ItemType.FOOD then
		for _, invItem in pairs(data.Inventory) do
			if invItem.Id == itemId then
				invItem.Quantity = (invItem.Quantity or 1) + quantity
				return true
			end
		end
	end
	
	-- Add new item
	local newItem = {
		Id = itemId,
		Name = itemData.Name,
		Type = itemData.Type,
		Rarity = itemData.Rarity,
		Quantity = quantity,
		AcquiredTime = GameUtilities.GetTimestamp()
	}
	
	table.insert(data.Inventory, newItem)
	
	-- Notify client
	InventoryManager.NotifyInventoryUpdate(player)
	return true
end

function InventoryManager.RemoveItem(player, itemId, quantity)
	if not player then return false end
	quantity = quantity or 1
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	for i, item in pairs(data.Inventory) do
		if item.Id == itemId then
			if (item.Quantity or 1) <= quantity then
				table.remove(data.Inventory, i)
			else
				item.Quantity = item.Quantity - quantity
			end
			
			InventoryManager.NotifyInventoryUpdate(player)
			return true
		end
	end
	
	return false
end

function InventoryManager.MoveItem(player, fromSlot, toSlot)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	if fromSlot < 1 or fromSlot > #data.Inventory then return false end
	if toSlot < 1 or toSlot > GameConstants.INVENTORY_SLOTS then return false end
	
	-- Swap items
	local temp = data.Inventory[toSlot]
	data.Inventory[toSlot] = data.Inventory[fromSlot]
	data.Inventory[fromSlot] = temp
	
	InventoryManager.NotifyInventoryUpdate(player)
	return true
end

function InventoryManager.UseItem(player, itemId)
	local itemData = ITEM_DATABASE[itemId]
	if not itemData then return false end
	
	-- Check if player has item
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local hasItem = false
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	for _, item in pairs(data.Inventory) do
		if item.Id == itemId then
			hasItem = true
			break
		end
	end
	
	if not hasItem then return false, "Item not found" end
	
	-- Apply effect
	if itemData.Type == GameEnums.ItemType.FOOD then
		PlayerDataManager.FeedShark(player, itemData.HungerRestore or 20)
		InventoryManager.RemoveItem(player, itemId, 1)
		
	elseif itemData.Type == GameEnums.ItemType.POTION then
		if itemData.HealAmount then
			PlayerDataManager.HealPlayer(player, itemData.HealAmount)
		end
		if itemData.SpeedBoost then
			-- Apply speed boost (would integrate with stat modifier system)
			data.Speed = data.Speed * itemData.SpeedBoost
			task.delay(itemData.Duration or 30, function()
				if data then data.Speed = data.Speed / itemData.SpeedBoost end
			end)
		end
		InventoryManager.RemoveItem(player, itemId, 1)
		
	elseif itemData.Type == GameEnums.ItemType.MUTATION_STABILIZER then
		-- Stabilize current mutations
		InventoryManager.RemoveItem(player, itemId, 1)
		return true, "Mutations stabilized"
		
	elseif itemData.Type == GameEnums.ItemType.COSMETIC then
		-- Equip cosmetic
		InventoryManager.EquipCosmetic(player, itemId)
		return true, "Cosmetic equipped"
		
	else
		return false, "Cannot use this item"
	end
	
	return true
end

function InventoryManager.EquipCosmetic(player, itemId)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	-- Unequip current cosmetic of same type
	-- (simplified - full system would track cosmetic slots)
	data.EquippedCosmetics = data.EquippedCosmetics or {}
	data.EquippedCosmetics[itemId] = true
end

function InventoryManager.UnequipCosmetic(player, itemId)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return end
	
	if data.EquippedCosmetics then
		data.EquippedCosmetics[itemId] = nil
	end
end

-- WAREHOUSE (extended storage)
function InventoryManager.MoveToWarehouse(player, itemId)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if not data then return false end
	
	-- Find item in inventory
	for i, item in pairs(data.Inventory) do
		if item.Id == itemId then
			-- Check warehouse space
			if #data.Warehouse >= GameConstants.WAREHOUSE_SLOTS then
				return false, "Warehouse full"
			end
			
			-- Move to warehouse
			table.remove(data.Inventory, i)
			table.insert(data.Warehouse, item)
			return true
		end
	end
	
	return false
end

-- SHOP
function InventoryManager.GetShopItems()
	local shopItems = {}
	
	for id, item in pairs(ITEM_DATABASE) do
		if item.Cost and item.Cost > 0 then
			table.insert(shopItems, {
				Id = id,
				Name = item.Name,
				Type = item.Type,
				Rarity = item.Rarity,
				Cost = item.Cost,
				Description = item.HungerRestore and "Restores " .. item.HungerRestore .. " hunger" or
				             item.HealAmount and "Restores " .. item.HealAmount .. " health" or
				             "Decoration for your aquarium"
			})
		end
	end
	
	return shopItems
end

function InventoryManager.BuyItem(player, itemId, quantity)
	quantity = quantity or 1
	
	local itemData = ITEM_DATABASE[itemId]
	if not itemData then return false, "Item not found" end
	if not itemData.Cost then return false, "Not for sale" end
	
	local totalCost = itemData.Cost * quantity
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	if not PlayerDataManager.CanAfford(player, GameEnums.CurrencyType.GOLD, totalCost) then
		return false, "Not enough gold"
	end
	
	-- Check inventory space
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	if #data.Inventory + quantity > GameConstants.INVENTORY_SLOTS then
		return false, "Not enough inventory space"
	end
	
	-- Purchase
	PlayerDataManager.SpendCurrency(player, GameEnums.CurrencyType.GOLD, totalCost)
	InventoryManager.AddItem(player, itemId, quantity)
	
	return true, "Purchase successful"
end

function InventoryManager.SellItem(player, itemId, quantity)
	quantity = quantity or 1
	
	local itemData = ITEM_DATABASE[itemId]
	if not itemData then return false end
	
	-- Calculate sell price (50% of buy price, minimum 1)
	local sellPrice = math.max(1, math.floor((itemData.Cost or 0) * 0.5)) * quantity
	
	-- Remove item
	if InventoryManager.RemoveItem(player, itemId, quantity) then
		-- Give gold
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, sellPrice)
		return true, "Sold for " .. sellPrice .. " gold"
	end
	
	return false, "Failed to sell item"
end

-- NOTIFICATIONS
function InventoryManager.NotifyInventoryUpdate(player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local event = remoteFolder:FindFirstChild("InventoryUpdated")
	if event then
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		local data = PlayerDataManager.GetPlayerData(player.UserId)
		event:FireClient(player, data and data.Inventory or {})
	end
end

-- PUBLIC API
function InventoryManager.GetItemData(itemId)
	return ITEM_DATABASE[itemId]
end

function InventoryManager.GetAllItems()
	return ITEM_DATABASE
end

return InventoryManager
