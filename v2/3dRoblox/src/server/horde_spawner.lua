-- Horde Spawner - Manages enemy waves and director AI
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
local EnemyData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("enemy_data"))
local EnemyAI = require(script.Parent:WaitForChild("enemy_ai"))

local LootManager = require(script.Parent:WaitForChild("loot_manager"))

local HordeSpawner = {}
HordeSpawner.__index = HordeSpawner

function HordeSpawner.new(dungeon_data, difficulty)
	local self = setmetatable({}, HordeSpawner)
	
	self.dungeon_data = dungeon_data
	self.difficulty = difficulty
	self.difficulty_mult = Constants.DIFFICULTY_MULTIPLIERS[difficulty] or 1.0
	self.loot_manager = LootManager.new()
	
	self.active_enemies = {}
	self.wave_number = 0
	self.wave_timer = 0
	self.wave_duration = 30
	self.enemies_spawned = 0
	self.max_active_enemies = 20
	
	-- Director AI
	self.director_intensity = 0.3
	self.director_timer = 0
	self.director_update_interval = 5
	
	self.horde_folder = nil
	
	return self
end

function HordeSpawner:initialize()
	self.horde_folder = Instance.new("Folder")
	self.horde_folder.Name = "Horde"
	self.horde_folder.Parent = workspace
	
	self.loot_manager:initialize()
	
	print("[HordeSpawner] Initialized with difficulty multiplier:", self.difficulty_mult)
end

function HordeSpawner:update(delta_time, players)
	self.wave_timer = self.wave_timer + delta_time
	self.director_timer = self.director_timer + delta_time
	
	-- Update director AI
	if self.director_timer >= self.director_update_interval then
		self:_update_director(players)
		self.director_timer = 0
	end
	
	-- Spawn waves
	if self.wave_timer >= self.wave_duration then
		self:spawn_wave(players)
		self.wave_timer = 0
	end
	
	-- Update active enemies
	self:_update_enemies(delta_time, players)
	
	-- Clean up dead enemies
	self:_cleanup_dead_enemies()
end

function HordeSpawner:spawn_wave(players)
	self.wave_number = self.wave_number + 1
	
	local wave_size = math.floor(3 + self.wave_number * 0.5) * self.difficulty_mult
	wave_size = math.min(wave_size, self.max_active_enemies)
	
	print("[HordeSpawner] Spawning wave", self.wave_number, "with", math.floor(wave_size), "enemies")
	
	for _ = 1, math.floor(wave_size) do
		if #self.active_enemies < self.max_active_enemies then
			self:_spawn_enemy(players)
		end
	end
end

function HordeSpawner:_spawn_enemy(players)
	-- Select random spawn point
	if #self.dungeon_data.enemy_spawn_points == 0 then
		return
	end
	
	local spawn_point = self.dungeon_data.enemy_spawn_points[
		math.random(1, #self.dungeon_data.enemy_spawn_points)
	]
	
	-- Select enemy type (weighted towards standard enemies)
	local enemy_type = self:_select_enemy_type()
	local enemy_stats = EnemyData:get_enemy_stats(enemy_type)
	
	-- Create enemy model
	local enemy_model = self:_create_enemy_model(enemy_stats, spawn_point)
	
	-- Create AI
	local ai = EnemyAI.new(enemy_model, enemy_stats, self.dungeon_data)
	
	table.insert(self.active_enemies, {
		model = enemy_model,
		ai = ai,
		stats = enemy_stats,
		spawn_time = tick(),
	})
	
	self.enemies_spawned = self.enemies_spawned + 1
end

function HordeSpawner:_select_enemy_type()
	local roll = math.random()
	
	if roll < 0.6 then
		local standard = EnemyData:get_enemies_by_category("standard")
		return standard[math.random(1, #standard)]
	elseif roll < 0.85 then
		local special = EnemyData:get_enemies_by_category("special")
		if #special > 0 then
			return special[math.random(1, #special)]
		end
	else
		local elite = EnemyData:get_enemies_by_category("elite")
		if #elite > 0 then
			return elite[math.random(1, #elite)]
		end
	end
	
	return Constants.ENEMY_TYPES.GOBLIN_SKELETON
end

function HordeSpawner:_create_enemy_model(stats, spawn_point)
	local model = Instance.new("Model")
	model.Name = stats.name
	model.Parent = self.horde_folder
	
	-- Create humanoid root part
	local root_part = Instance.new("Part")
	root_part.Name = "HumanoidRootPart"
	root_part.Shape = Enum.PartType.Block
	root_part.Size = Vector3.new(1.5, 2, 1.5) * stats.size
	root_part.CanCollide = true
	root_part.CFrame = CFrame.new(spawn_point.x, 2, spawn_point.z)
	root_part.Parent = model
	
	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = stats.max_hp
	humanoid.Health = stats.max_hp
	humanoid.Parent = model
	
	-- Create body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(1.5, 1.5, 1) * stats.size
	body.Color = stats.color
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = true
	body.CFrame = root_part.CFrame
	body.Parent = model
	
	-- Weld body to root
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root_part
	weld.Part1 = body
	weld.Parent = root_part
	
	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1, 1, 1) * stats.size
	head.Color = stats.color
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = true
	head.CFrame = root_part.CFrame + Vector3.new(0, 1 * stats.size, 0)
	head.Parent = model
	
	-- Weld head to root
	local head_weld = Instance.new("WeldConstraint")
	head_weld.Part0 = root_part
	head_weld.Part1 = head
	head_weld.Parent = root_part
	
	return model
end

function HordeSpawner:_update_enemies(delta_time, players)
	for _, enemy_data in ipairs(self.active_enemies) do
		if enemy_data.ai.is_alive then
			enemy_data.ai:update(delta_time, players)
		end
	end
end

function HordeSpawner:_cleanup_dead_enemies()
	local i = 1
	while i <= #self.active_enemies do
		local enemy_data = self.active_enemies[i]
		if not enemy_data.ai.is_alive then
			-- Drop loot
			local enemy_pos = enemy_data.model:FindFirstChild("HumanoidRootPart")
			if enemy_pos then
				self.loot_manager:spawn_loot(enemy_pos.Position, enemy_data.stats, self.difficulty_mult)
			end
			
			enemy_data.model:Destroy()
			table.remove(self.active_enemies, i)
		else
			i = i + 1
		end
	end
end

function HordeSpawner:_update_director(players)
	-- Calculate player threat level
	local player_count = 0
	local total_player_hp = 0
	
	for _, player in ipairs(players) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player_count = player_count + 1
			total_player_hp = total_player_hp + player.Character.Humanoid.Health
		end
	end
	
	if player_count == 0 then return end
	
	-- Adjust intensity based on player health
	local avg_player_hp = total_player_hp / player_count
	local hp_ratio = avg_player_hp / 100
	
	if hp_ratio > 0.7 then
		self.director_intensity = math.min(1.0, self.director_intensity + 0.05)
	elseif hp_ratio < 0.3 then
		self.director_intensity = math.max(0.2, self.director_intensity - 0.1)
	end
	
	-- Adjust max active enemies based on intensity
	self.max_active_enemies = math.floor(15 + self.director_intensity * 15)
end

function HordeSpawner:get_active_enemy_count()
	return #self.active_enemies
end

function HordeSpawner:get_wave_number()
	return self.wave_number
end

function HordeSpawner:get_director_intensity()
	return self.director_intensity
end

return HordeSpawner
