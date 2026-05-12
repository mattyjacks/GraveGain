local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game_data"))
local LoreEntries1 = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("lore_entries_1"))

local DungeonLootManager = {}
DungeonLootManager.__index = DungeonLootManager

function DungeonLootManager.new(dungeonGenerator)
	local self = setmetatable({}, DungeonLootManager)
	self.dungeon = dungeonGenerator
	return self
end

function DungeonLootManager:placeLoot()
	local numLoot = 3 + math.random(3)
	
	for i = 1, numLoot do
		local x, y = self.dungeon:findRandomWalkableTile()
		if x and y then
			local rarity = math.random() > 0.7 and "rare" or (math.random() > 0.5 and "uncommon" or "common")
			
			table.insert(self.dungeon.loot, {
				x = x,
				y = y,
				type = "weapon",
				rarity = rarity,
				value = 10 * (rarity == "common" and 1 or rarity == "uncommon" and 2 or 5),
			})
		end
	end
end

function DungeonLootManager:placeAmmoCrates()
	for i = 1, #self.dungeon.rooms do
		if math.random() < 0.5 then
			local x, y = self.dungeon:findRandomWalkableTile()
			if x and y then
				table.insert(self.dungeon.loot, {
					x = x,
					y = y,
					type = "ammo_crate",
				})
			end
		end
	end
end

function DungeonLootManager:placeLoreItems()
	for i = 1, #self.dungeon.rooms do
		if math.random() < 0.3 then
			local x, y = self.dungeon:findRandomWalkableTile()
			if x and y then
				local loreIds = {}
				for id, _ in pairs(LoreEntries1) do
					table.insert(loreIds, id)
				end
				local randomLoreId = loreIds[math.random(1, #loreIds)]
				
				table.insert(self.dungeon.loot, {
					x = x,
					y = y,
					type = "lore_item",
					loreId = randomLoreId
				})
			end
		end
	end
end

return DungeonLootManager
