-- BattleSharks Combat Manager
-- Handles damage, health, death, and collision detection (C3, C5)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Load shared modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameData = require(Shared:WaitForChild("Data"):WaitForChild("GameData"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local CombatManager = {}

-- PRIVATE VARIABLES
local activeAttacks = {} -- Track ongoing attacks
local damageNumbers = {} -- Pool for damage number visuals
local combatLoopConnection = nil

-- COLLISION CONFIGURATION (C3)
local COLLISION_CONFIG = {
	AttackHitboxRadius = 3,
	EnemyCollisionRadius = 5,
	TerrainCollisionPadding = 2,
	CollisionCheckFrequency = 5, -- Hz
	MaxAttackRange = 15
}

-- INITIALIZATION
function CombatManager.Initialize()
	GameUtilities.DebugPrint("CombatManager: Initializing")
	
	-- Set up player death handling
	Players.PlayerAdded:Connect(CombatManager.OnPlayerAdded)
	
	-- Start collision detection loop (C3)
	CombatManager.StartCollisionLoop()
	
	GameUtilities.DebugPrint("CombatManager: Initialized")
end

function CombatManager.OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		CombatManager.SetupCharacterCollision(character)
	end)
end

-- COLLISION DETECTION SYSTEM (C3)
function CombatManager.StartCollisionLoop()
	if combatLoopConnection then return end
	
	combatLoopConnection = RunService.Heartbeat:Connect(function(deltaTime)
		CombatManager.CheckAllCollisions()
	end)
end

function CombatManager.StopCollisionLoop()
	if combatLoopConnection then
		combatLoopConnection:Disconnect()
		combatLoopConnection = nil
	end
end

function CombatManager.SetupCharacterCollision(character)
	-- Add collision detection to character parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			-- Set up collision groups if needed
			part.Touched:Connect(function(hit)
				CombatManager.OnPartTouched(character, part, hit)
			end)
		end
	end
end

function CombatManager.OnPartTouched(character, part, hit)
	-- Handle terrain collision (C3)
	if hit:IsA("BasePart") and not hit.Parent:FindFirstChild("Humanoid") then
		-- Check if it's a terrain/wall collision
		if hit.Name == "OceanFloor" or hit.Name:find("Boundary") or hit.Name:find("Wall") then
			CombatManager.HandleTerrainCollision(character, part, hit)
		end
	end
end

function CombatManager.HandleTerrainCollision(character, part, terrain)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	local velocity = part.Velocity
	local impactSpeed = velocity.Magnitude
	
	-- Damage from high-speed impacts
	if impactSpeed > 50 then
		local damage = math.floor((impactSpeed - 50) / 5)
		if damage > 0 then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				local PlayerDataManager = require(script.Parent.PlayerDataManager)
				PlayerDataManager.DamagePlayer(player, damage, "Terrain")
				
				-- Visual feedback
				CombatManager.ShowDamageNumber(part.Position, damage, "physical")
			end
		end
	end
end

function CombatManager.CheckAllCollisions()
	-- Check player-enemy collisions
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			CombatManager.CheckPlayerEnemyCollisions(player)
		end
	end
end

function CombatManager.CheckPlayerEnemyCollisions(player)
	local GameLoopManager = require(script.Parent.GameLoopManager)
	local enemies = GameLoopManager.GetEnemies()
	local character = player.Character
	local playerPos = character.PrimaryPart.Position
	
	for _, enemy in pairs(enemies) do
		if enemy.Model and enemy.Model.PrimaryPart then
			local enemyPos = enemy.Model.PrimaryPart.Position
			local distance = (playerPos - enemyPos).Magnitude
			
			-- Collision with enemy
			if distance < COLLISION_CONFIG.EnemyCollisionRadius then
				CombatManager.HandlePlayerEnemyCollision(player, character, enemy)
			end
		end
	end
end

function CombatManager.HandlePlayerEnemyCollision(player, character, enemy)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Apply contact damage from enemy
	local damage = enemy.Data.Damage or 5
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	PlayerDataManager.DamagePlayer(player, damage, "Physical")
	
	-- Knockback
	local playerPos = character.PrimaryPart.Position
	local enemyPos = enemy.Model.PrimaryPart.Position
	local knockbackDir = (playerPos - enemyPos).Unit
	local knockbackForce = knockbackDir * 50 + Vector3.new(0, 30, 0)
	
	character.PrimaryPart:ApplyImpulse(knockbackForce)
	
	-- Visual
	CombatManager.ShowDamageNumber(playerPos, damage, "physical")
	CombatManager.CreateCollisionEffect((playerPos + enemyPos) / 2)
end

-- COMBAT SYSTEM (C5)
function CombatManager.PerformAttack(player, targetPosition, attackType)
	local character = player.Character
	if not character or not character.PrimaryPart then return false end
	
	local playerPos = character.PrimaryPart.Position
	local attackRange = GameConstants.BITE_RANGE
	local attackDamage = GameConstants.BITE_DAMAGE
	local attackCooldown = GameConstants.BITE_COOLDOWN
	
	-- Get player data for stat modifications
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	-- Apply class damage multiplier
	if data and data.Class then
		local classStats = GameConstants.CLASS_STATS[data.Class]
		if classStats then
			attackDamage = attackDamage * (classStats.DamageMultiplier or 1)
		end
	end
	
	-- Find targets in range
	local targets = CombatManager.FindTargetsInRange(playerPos, attackRange, player)
	
	if #targets == 0 then
		return false -- Missed
	end
	
	-- Apply damage to all targets
	local totalDamage = 0
	for _, target in pairs(targets) do
		local damage = CombatManager.ApplyDamage(player, target, attackDamage, attackType)
		totalDamage += damage
	end
	
	-- Update statistics
	if data and totalDamage > 0 then
		data.Statistics.TotalDamageDealt += totalDamage
		data.Statistics.TotalAbilitiesUsed += 1
	end
	
	return true, targets
end

function CombatManager.ApplyDamage(attacker, target, baseDamage, damageType)
	local damage = math.floor(baseDamage)
	
	if target:IsA("Player") then
		-- Player vs Player damage
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		local targetData = PlayerDataManager.GetPlayerData(target.UserId)
		
		if targetData then
			-- Apply armor/mitigation here if implemented
			PlayerDataManager.DamagePlayer(target, damage, damageType)
			
			-- Show damage number
			if target.Character and target.Character.PrimaryPart then
				CombatManager.ShowDamageNumber(target.Character.PrimaryPart.Position, damage, "physical")
			end
		end
		
	elseif target:IsA("Model") and target:FindFirstChild("Humanoid") then
		-- Enemy damage
		local GameLoopManager = require(script.Parent.GameLoopManager)
		GameLoopManager.DamageEnemy(target, damage)
		
		-- Show damage number
		CombatManager.ShowDamageNumber(target.PrimaryPart.Position, damage, "physical")
	end
	
	return damage
end

function CombatManager.FindTargetsInRange(center, range, excludePlayer)
	local targets = {}
	
	-- Check enemies
	local GameLoopManager = require(script.Parent.GameLoopManager)
	for _, enemy in pairs(GameLoopManager.GetEnemies()) do
		if enemy.Model and enemy.Model.PrimaryPart then
			local distance = (enemy.Model.PrimaryPart.Position - center).Magnitude
			if distance <= range then
				table.insert(targets, enemy.Model)
			end
		end
	end
	
	-- Check other players (PvP)
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= excludePlayer and otherPlayer.Character and otherPlayer.Character.PrimaryPart then
			local distance = (otherPlayer.Character.PrimaryPart.Position - center).Magnitude
			if distance <= range then
				table.insert(targets, otherPlayer)
			end
		end
	end
	
	return targets
end

-- DEATH SYSTEM (C5)
function CombatManager.OnPlayerDied(player, killer)
	GameUtilities.DebugPrint("CombatManager: " .. player.Name .. " died")
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local data = PlayerDataManager.GetPlayerData(player.UserId)
	
	if data then
		data.Statistics.DeathCount += 1
		
		-- Death penalty (optional)
		local goldLoss = math.floor(data.Gold * 0.05) -- 5% gold loss
		if goldLoss > 0 then
			PlayerDataManager.SpendCurrency(player, GameEnums.CurrencyType.GOLD, goldLoss)
		end
	end
	
	-- Death visual effects
	CombatManager.CreateDeathEffect(player)
	
	-- Notify killer
	if killer and killer:IsA("Player") then
		CombatManager.OnPlayerKill(killer, player)
	end
	
	-- Respawn delay
	task.delay(3, function()
		if player then
			player:LoadCharacter()
		end
	end)
end

function CombatManager.OnPlayerKill(killer, victim)
	GameUtilities.DebugPrint("CombatManager: " .. killer.Name .. " killed " .. victim.Name)
	
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	local killerData = PlayerDataManager.GetPlayerData(killer.UserId)
	
	if killerData then
		killerData.EnemiesKilled += 1
		-- XP reward for PvP kill
		PlayerDataManager.AddXP(killer, 50)
	end
	
	-- Notify clients
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local killEvent = remoteFolder:FindFirstChild("PlayerKilled")
		if killEvent then
			killEvent:FireAllClients({
				Killer = killer.Name,
				Victim = victim.Name
			})
		end
	end
end

-- VISUAL EFFECTS
function CombatManager.ShowDamageNumber(position, damage, damageType)
	-- Simple visual - can be expanded with BillboardGui
	local color = Color3.new(1, 0, 0) -- Red for damage
	if damageType == "magical" then
		color = Color3.new(0.5, 0, 1) -- Purple for magical
	elseif damageType == "heal" then
		color = Color3.new(0, 1, 0) -- Green for healing
	end
	
	-- Create floating text (simplified)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position + Vector3.new(0, 5, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	-- Animate upward
	task.spawn(function()
		for i = 1, 20 do
			part.Position += Vector3.new(0, 0.2, 0)
			task.wait(0.03)
		end
		part:Destroy()
	end)
end

function CombatManager.CreateCollisionEffect(position)
	local effect = Instance.new("Part")
	effect.Name = "CollisionEffect"
	effect.Size = Vector3.new(2, 2, 2)
	effect.Shape = Enum.PartType.Ball
	effect.BrickColor = BrickColor.new("Bright orange")
	effect.Material = Enum.Material.Neon
	effect.Position = position
	effect.Anchored = true
	effect.CanCollide = false
	effect.Parent = Workspace
	
	task.spawn(function()
		for i = 1, 10 do
			local progress = i / 10
			effect.Size = Vector3.new(2, 2, 2) * (1 + progress * 2)
			effect.Transparency = progress
			task.wait(0.05)
		end
		effect:Destroy()
	end)
end

function CombatManager.CreateDeathEffect(player)
	if not player.Character then return end
	
	local position = player.Character.PrimaryPart.Position
	
	-- Death explosion effect
	for i = 1, 8 do
		local particle = Instance.new("Part")
		particle.Size = Vector3.new(1, 1, 1)
		particle.Shape = Enum.PartType.Ball
		particle.BrickColor = BrickColor.new("Really red")
		particle.Material = Enum.Material.Neon
		particle.Position = position
		particle.Anchored = false
		particle.CanCollide = false
		
		local angle = (i / 8) * math.pi * 2
		local velocity = Vector3.new(
			math.cos(angle) * 20,
			math.random(10, 30),
			math.sin(angle) * 20
		)
		
		particle.Parent = Workspace
		particle:ApplyImpulse(velocity)
		
		task.delay(2, function()
			if particle then
				particle:Destroy()
			end
		end)
	end
end

-- PUBLIC API
function CombatManager.DamageEnemy(enemyModel, damage)
	-- This is called by GameLoopManager, implemented there
	local GameLoopManager = require(script.Parent.GameLoopManager)
	return GameLoopManager.DamageEnemy(enemyModel, damage)
end

function CombatManager.HealPlayer(player, amount)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	PlayerDataManager.HealPlayer(player, amount)
	
	-- Visual
	if player.Character and player.Character.PrimaryPart then
		CombatManager.ShowDamageNumber(player.Character.PrimaryPart.Position, amount, "heal")
	end
end

-- CLEANUP
function CombatManager.Cleanup()
	CombatManager.StopCollisionLoop()
	GameUtilities.DebugPrint("CombatManager: Cleaned up")
end

return CombatManager
