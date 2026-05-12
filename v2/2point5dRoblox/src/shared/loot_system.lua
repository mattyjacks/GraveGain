local GameData = require(script.Parent:WaitForChild("game_data"))

local LootSystem = {}
LootSystem.__index = LootSystem

function LootSystem.new()
	local self = setmetatable({}, LootSystem)
	return self
end

function LootSystem:generateLoot(enemyType, enemyLevel)
	local isBoss = enemyType == "Boss"
	local dropChance = isBoss and GameData.GAME_BALANCE.bossLootDropRate or GameData.GAME_BALANCE.lootDropRate
	
	if math.random() > dropChance then
		return self:generateGold(enemyLevel, isBoss)
	end
	
	local lootType = math.random()
	if lootType < 0.6 then
		return self:generateWeapon(enemyLevel, isBoss)
	elseif lootType < 0.85 then
		return self:generateArmor(enemyLevel, isBoss)
	else
		return self:generatePotion()
	end
end

function LootSystem:generateWeapon(level, isBoss)
	local weaponKeys = {}
	for key, _ in pairs(GameData.WEAPON_TYPES) do
		table.insert(weaponKeys, key)
	end
	
	local weaponType = weaponKeys[math.random(#weaponKeys)]
	local weaponData = GameData.WEAPON_TYPES[weaponType]
	local rarity = self:determineRarity(level, isBoss)
	
	local item = {
		type = "weapon",
		weaponType = weaponType,
		name = self:generateItemName(weaponType, rarity),
		rarity = rarity,
		damage = weaponData.damage * (1 + level * 0.1) * self:getRarityMultiplier(rarity),
		speed = weaponData.speed,
		range = weaponData.range,
		value = 10 * level * self:getRarityMultiplier(rarity),
		affixes = self:generateAffixes(rarity),
	}
	
	return item
end

function LootSystem:generateArmor(level, isBoss)
	local slots = { "Head", "Chest", "Legs", "Feet", "Gloves" }
	local slot = slots[math.random(#slots)]
	local rarity = self:determineRarity(level, isBoss)
	
	local item = {
		type = "armor",
		slot = slot,
		name = self:generateItemName(slot, rarity),
		rarity = rarity,
		armor = 5 * level * self:getRarityMultiplier(rarity),
		value = 8 * level * self:getRarityMultiplier(rarity),
		affixes = self:generateAffixes(rarity),
	}
	
	return item
end

function LootSystem:generatePotion()
	local potionTypes = {
		{ name = "Health Potion", type = "health", value = 10, effect = 50 },
		{ name = "Mana Potion", type = "mana", value = 10, effect = 30 },
		{ name = "Speed Potion", type = "speed", value = 15, effect = 2 },
		{ name = "Damage Potion", type = "damage", value = 20, effect = 1.2 },
	}
	
	local potion = potionTypes[math.random(#potionTypes)]
	return {
		type = "potion",
		potionType = potion.type,
		name = potion.name,
		rarity = "common",
		value = potion.value,
		effect = potion.effect,
		stackable = true,
		quantity = 1,
	}
end

function LootSystem:generateGold(level, isBoss)
	local baseGold = 5 * level
	local variance = baseGold * 0.5
	local amount = baseGold + math.random() * variance
	
	if isBoss then
		amount = amount * 3
	end
	
	return {
		type = "gold",
		name = "Gold",
		rarity = "common",
		value = math.floor(amount),
		stackable = true,
		quantity = math.floor(amount),
	}
end

function LootSystem:determineRarity(level, isBoss)
	local roll = math.random()
	local multiplier = isBoss and 1.5 or 1.0
	
	if roll < 0.5 * multiplier then
		return "common"
	elseif roll < 0.75 * multiplier then
		return "uncommon"
	elseif roll < 0.9 * multiplier then
		return "rare"
	elseif roll < 0.97 * multiplier then
		return "epic"
	else
		return "legendary"
	end
end

function LootSystem:getRarityMultiplier(rarity)
	local multipliers = {
		common = 1.0,
		uncommon = 1.5,
		rare = 2.0,
		epic = 3.0,
		legendary = 4.0,
		unique = 5.0,
	}
	return multipliers[rarity] or 1.0
end

function LootSystem:generateItemName(baseType, rarity)
	local prefix = GameData.ITEM_PREFIXES[math.random(#GameData.ITEM_PREFIXES)]
	local suffix = GameData.ITEM_SUFFIXES[math.random(#GameData.ITEM_SUFFIXES)]
	
	if rarity == "common" then
		return baseType
	elseif rarity == "uncommon" then
		return prefix .. " " .. baseType
	else
		return prefix .. " " .. baseType .. " " .. suffix
	end
end

function LootSystem:generateAffixes(rarity)
	local affixCount = 0
	if rarity == "uncommon" then affixCount = 1
	elseif rarity == "rare" then affixCount = 2
	elseif rarity == "epic" then affixCount = 3
	elseif rarity == "legendary" then affixCount = 4
	end
	
	local affixes = {}
	for i = 1, affixCount do
		local stat = GameData.STAT_NAMES[math.random(#GameData.STAT_NAMES)]
		local bonus = 1 + (rarity == "uncommon" and 0.1 or rarity == "rare" and 0.2 or rarity == "epic" and 0.3 or 0.4)
		table.insert(affixes, { stat = stat, bonus = bonus })
	end
	
	return affixes
end

function LootSystem:canPickupItem(inventory, item)
	local usedSlots = 0
	for _, slot in ipairs(inventory) do
		if slot then usedSlots = usedSlots + 1 end
	end
	
	return usedSlots < GameData.GAME_BALANCE.inventorySlots
end

function LootSystem:addItemToInventory(inventory, item)
	if item.stackable then
		for i, slot in ipairs(inventory) do
			if slot and slot.type == item.type and slot.potionType == item.potionType then
				slot.quantity = (slot.quantity or 1) + (item.quantity or 1)
				return true
			end
		end
	end
	
	for i, slot in ipairs(inventory) do
		if not slot then
			inventory[i] = item
			return true
		end
	end
	
	return false
end

return LootSystem
