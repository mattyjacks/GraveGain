-- Loot Manager - Handles item drops and loot distribution
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("item_data"))

local LootManager = {}
LootManager.__index = LootManager

function LootManager.new()
	local self = setmetatable({}, LootManager)
	
	self.active_items = {}
	self.items_folder = nil
	
	return self
end

function LootManager:initialize()
	self.items_folder = Instance.new("Folder")
	self.items_folder.Name = "Items"
	self.items_folder.Parent = workspace
	
	print("[LootManager] Initialized")
end

function LootManager:spawn_loot(position, enemy_stats, difficulty_mult)
	local loot_table = self:_generate_loot_table(enemy_stats, difficulty_mult)
	
	for _, item_id in ipairs(loot_table) do
		self:_spawn_item(item_id, position)
	end
end

function LootManager:_generate_loot_table(enemy_stats, difficulty_mult)
	local loot = {}
	
	-- Always drop gold
	local gold_amount = math.floor(enemy_stats.gold_drop * difficulty_mult)
	for _ = 1, gold_amount do
		table.insert(loot, "gold_coin")
	end
	
	-- Chance for health potion
	if math.random() < 0.3 then
		table.insert(loot, "health_potion_small")
	end
	
	-- Chance for ammo
	if math.random() < 0.25 then
		table.insert(loot, "ammo_box_small")
	end
	
	-- Rare chance for artifact
	if math.random() < 0.05 * difficulty_mult then
		local artifacts = ItemData:get_items_by_type(ItemData.ITEM_TYPES.ARTIFACT)
		if #artifacts > 0 then
			table.insert(loot, artifacts[math.random(1, #artifacts)])
		end
	end
	
	return loot
end

function LootManager:_spawn_item(item_id, position)
	local item_data = ItemData:get_item(item_id)
	if not item_data then return end
	
	local item_model = Instance.new("Model")
	item_model.Name = item_data.name
	item_model.Parent = self.items_folder
	
	-- Create item body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(0.5, 0.5, 0.5)
	body.Color = ItemData.RARITY_COLORS[item_data.rarity]
	body.Material = Enum.Material.Neon
	body.CanCollide = true
	body.CFrame = CFrame.new(position + Vector3.new(
		(math.random() - 0.5) * 3,
		2,
		(math.random() - 0.5) * 3
	))
	body.Parent = item_model
	
	-- Add velocity for spread
	body.AssemblyLinearVelocity = Vector3.new(
		(math.random() - 0.5) * 10,
		5,
		(math.random() - 0.5) * 10
	)
	
	-- Store item data
	local data_folder = Instance.new("Folder")
	data_folder.Name = "ItemData"
	data_folder.Parent = item_model
	
	local id_value = Instance.new("StringValue")
	id_value.Name = "ItemID"
	id_value.Value = item_id
	id_value.Parent = data_folder
	
	local rarity_value = Instance.new("IntValue")
	rarity_value.Name = "Rarity"
	rarity_value.Value = item_data.rarity
	rarity_value.Parent = data_folder
	
	table.insert(self.active_items, item_model)
	
	-- Auto-despawn after 30 seconds
	task.delay(30, function()
		if item_model.Parent then
			item_model:Destroy()
		end
	end)
end

function LootManager:collect_item(player, item_model)
	local item_data_folder = item_model:FindFirstChild("ItemData")
	if not item_data_folder then return end
	
	local item_id_value = item_data_folder:FindFirstChild("ItemID")
	if not item_id_value then return end
	
	local item_id = item_id_value.Value
	local item_data = ItemData:get_item(item_id)
	
	if not item_data then return end
	
	-- Apply item effects
	if item_data.type == ItemData.ITEM_TYPES.GOLD then
		self:_apply_gold(player, item_data.value)
	elseif item_data.type == ItemData.ITEM_TYPES.HEALTH_POTION then
		self:_apply_health(player, item_data.heal_amount)
	elseif item_data.type == ItemData.ITEM_TYPES.AMMO_BOX then
		self:_apply_ammo(player, item_data.ammo_amount)
	elseif item_data.type == ItemData.ITEM_TYPES.FOOD then
		self:_apply_health(player, item_data.heal_amount)
	elseif item_data.type == ItemData.ITEM_TYPES.ARTIFACT then
		self:_apply_artifact(player, item_data)
	end
	
	-- Remove item
	item_model:Destroy()
	
	print("[LootManager] Player", player.Name, "collected", item_data.name)
end

function LootManager:_apply_gold(player, amount)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local player_data_folder = player.Character:FindFirstChild("PlayerData")
		if player_data_folder then
			local gold_value = player_data_folder:FindFirstChild("Gold")
			if not gold_value then
				gold_value = Instance.new("IntValue")
				gold_value.Name = "Gold"
				gold_value.Parent = player_data_folder
			end
			gold_value.Value = gold_value.Value + amount
		end
	end
end

function LootManager:_apply_health(player, amount)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local humanoid = player.Character.Humanoid
		humanoid.Health = math.min(humanoid.Health + amount, humanoid.MaxHealth)
	end
end

function LootManager:_apply_ammo(player, amount)
	if player.Character and player.Character:FindFirstChild("PlayerData") then
		local player_data_folder = player.Character.PlayerData
		local ammo_value = player_data_folder:FindFirstChild("Ammo")
		if not ammo_value then
			ammo_value = Instance.new("IntValue")
			ammo_value.Name = "Ammo"
			ammo_value.Parent = player_data_folder
		end
		ammo_value.Value = ammo_value.Value + amount
	end
end

function LootManager:_apply_artifact(player, item_data)
	if item_data.stat_bonus then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if item_data.stat_bonus.hp then
				player.Character.Humanoid.MaxHealth = player.Character.Humanoid.MaxHealth + item_data.stat_bonus.hp
			end
		end
	end
end

function LootManager:cleanup()
	if self.items_folder then
		self.items_folder:Destroy()
	end
end

return LootManager
