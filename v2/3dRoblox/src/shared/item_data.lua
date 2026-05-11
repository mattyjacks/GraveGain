-- Item Data - Defines all item types and loot
local ItemData = {}

ItemData.ITEM_TYPES = {
	GOLD = "gold",
	HEALTH_POTION = "health_potion",
	AMMO_BOX = "ammo_box",
	ARTIFACT = "artifact",
	FOOD = "food",
}

ItemData.RARITIES = {
	COMMON = 1,
	UNCOMMON = 2,
	RARE = 3,
	EPIC = 4,
	LEGENDARY = 5,
}

ItemData.RARITY_NAMES = {
	[ItemData.RARITIES.COMMON] = "Common",
	[ItemData.RARITIES.UNCOMMON] = "Uncommon",
	[ItemData.RARITIES.RARE] = "Rare",
	[ItemData.RARITIES.EPIC] = "Epic",
	[ItemData.RARITIES.LEGENDARY] = "Legendary",
}

ItemData.RARITY_COLORS = {
	[ItemData.RARITIES.COMMON] = Color3.fromRGB(200, 200, 200),
	[ItemData.RARITIES.UNCOMMON] = Color3.fromRGB(100, 200, 100),
	[ItemData.RARITIES.RARE] = Color3.fromRGB(100, 150, 255),
	[ItemData.RARITIES.EPIC] = Color3.fromRGB(200, 100, 255),
	[ItemData.RARITIES.LEGENDARY] = Color3.fromRGB(255, 200, 0),
}

ItemData.ITEMS = {
	-- Gold
	gold_coin = {
		name = "Gold Coin",
		type = ItemData.ITEM_TYPES.GOLD,
		rarity = ItemData.RARITIES.COMMON,
		value = 10,
		weight = 0.1,
	},
	gold_bar = {
		name = "Gold Bar",
		type = ItemData.ITEM_TYPES.GOLD,
		rarity = ItemData.RARITIES.UNCOMMON,
		value = 100,
		weight = 0.5,
	},
	gold_cube = {
		name = "Gold Cube",
		type = ItemData.ITEM_TYPES.GOLD,
		rarity = ItemData.RARITIES.RARE,
		value = 500,
		weight = 1.0,
	},
	
	-- Health Potions
	health_potion_small = {
		name = "Small Health Potion",
		type = ItemData.ITEM_TYPES.HEALTH_POTION,
		rarity = ItemData.RARITIES.COMMON,
		heal_amount = 25,
		weight = 0.2,
	},
	health_potion_medium = {
		name = "Health Potion",
		type = ItemData.ITEM_TYPES.HEALTH_POTION,
		rarity = ItemData.RARITIES.UNCOMMON,
		heal_amount = 50,
		weight = 0.3,
	},
	health_potion_large = {
		name = "Large Health Potion",
		type = ItemData.ITEM_TYPES.HEALTH_POTION,
		rarity = ItemData.RARITIES.RARE,
		heal_amount = 100,
		weight = 0.4,
	},
	
	-- Ammo Boxes
	ammo_box_small = {
		name = "Small Ammo Box",
		type = ItemData.ITEM_TYPES.AMMO_BOX,
		rarity = ItemData.RARITIES.COMMON,
		ammo_amount = 15,
		weight = 0.3,
	},
	ammo_box_medium = {
		name = "Ammo Box",
		type = ItemData.ITEM_TYPES.AMMO_BOX,
		rarity = ItemData.RARITIES.UNCOMMON,
		ammo_amount = 30,
		weight = 0.5,
	},
	ammo_box_large = {
		name = "Large Ammo Box",
		type = ItemData.ITEM_TYPES.AMMO_BOX,
		rarity = ItemData.RARITIES.RARE,
		ammo_amount = 60,
		weight = 0.8,
	},
	
	-- Artifacts
	ancient_ring = {
		name = "Ancient Ring",
		type = ItemData.ITEM_TYPES.ARTIFACT,
		rarity = ItemData.RARITIES.RARE,
		value = 500,
		weight = 0.1,
		stat_bonus = { damage = 5 },
	},
	ornate_vase = {
		name = "Ornate Vase",
		type = ItemData.ITEM_TYPES.ARTIFACT,
		rarity = ItemData.RARITIES.RARE,
		value = 600,
		weight = 0.5,
		stat_bonus = { hp = 20 },
	},
	golden_trident = {
		name = "Golden Trident",
		type = ItemData.ITEM_TYPES.ARTIFACT,
		rarity = ItemData.RARITIES.EPIC,
		value = 1000,
		weight = 1.0,
		stat_bonus = { damage = 15, speed = 10 },
	},
	
	-- Food
	bread = {
		name = "Bread",
		type = ItemData.ITEM_TYPES.FOOD,
		rarity = ItemData.RARITIES.COMMON,
		heal_amount = 15,
		weight = 0.2,
	},
	meat = {
		name = "Meat",
		type = ItemData.ITEM_TYPES.FOOD,
		rarity = ItemData.RARITIES.UNCOMMON,
		heal_amount = 40,
		weight = 0.3,
	},
	cheese = {
		name = "Cheese",
		type = ItemData.ITEM_TYPES.FOOD,
		rarity = ItemData.RARITIES.UNCOMMON,
		heal_amount = 30,
		weight = 0.2,
	},
}

function ItemData:get_item(item_id)
	return self.ITEMS[item_id]
end

function ItemData:get_random_item()
	local items = {}
	for id, _ in pairs(self.ITEMS) do
		table.insert(items, id)
	end
	return items[math.random(1, #items)]
end

function ItemData:get_items_by_rarity(rarity)
	local items = {}
	for id, data in pairs(self.ITEMS) do
		if data.rarity == rarity then
			table.insert(items, id)
		end
	end
	return items
end

function ItemData:get_items_by_type(item_type)
	local items = {}
	for id, data in pairs(self.ITEMS) do
		if data.type == item_type then
			table.insert(items, id)
		end
	end
	return items
end

return ItemData
