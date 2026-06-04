-- BattleSharks Game Loop Manager
-- Manages the main game loop, enemy spawning, and world state

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Load shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameData = require(Shared:WaitForChild("Data"):WaitForChild("GameData"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local GameLoopManager = {}

-- PRIVATE VARIABLES
local isRunning = false
local gameLoopConnection = nil
local enemies = {}
local items = {}
local worldObjects = {}

-- SPAWN CONFIGURATION
local spawnConfig = {
	EnemySpawnRate = 2.0, -- seconds between spawns
	MaxEnemies = 50,
	SpawnRadius = 500, -- studs from player
	DespawnRadius = 1000, -- studs to despawn
	ItemSpawnRate = 1.5, -- seconds between item spawns
	MaxItems = 30
}

-- INITIALIZATION
function GameLoopManager.Initialize()
	GameUtilities.DebugPrint("GameLoopManager: Initializing")
	
	-- Create ocean environment
	GameLoopManager.CreateOceanEnvironment()
	
	-- Set up game loop
	GameLoopManager.StartGameLoop()
	
	GameUtilities.DebugPrint("GameLoopManager: Initialized")
end

-- OCEAN ENVIRONMENT
function GameLoopManager.CreateOceanEnvironment()
	-- Create ocean floor
	local oceanFloor = Instance.new("Part")
	oceanFloor.Name = "OceanFloor"
	oceanFloor.Size = Vector3.new(GameConstants.OCEAN_SIZE.X, 20, GameConstants.OCEAN_SIZE.Y)
	oceanFloor.Position = Vector3.new(0, GameConstants.OCEAN_DEPTH, 0)
	oceanFloor.Anchored = true
	oceanFloor.Locked = true
	oceanFloor.BrickColor = BrickColor.new("Sand blue")
	oceanFloor.TopSurface = Enum.SurfaceType.Smooth
	oceanFloor.BottomSurface = Enum.SurfaceType.Smooth
	oceanFloor.Parent = Workspace
	
	-- Create water boundaries
	local boundaries = {
		{Vector3.new(0, 0, GameConstants.OCEAN_SIZE.Y/2), Vector3.new(GameConstants.OCEAN_SIZE.X, 100, 20), "North"},
		{Vector3.new(0, 0, -GameConstants.OCEAN_SIZE.Y/2), Vector3.new(GameConstants.OCEAN_SIZE.X, 100, 20), "South"},
		{Vector3.new(GameConstants.OCEAN_SIZE.X/2, 0, 0), Vector3.new(20, 100, GameConstants.OCEAN_SIZE.Y), "East"},
		{Vector3.new(-GameConstants.OCEAN_SIZE.X/2, 0, 0), Vector3.new(20, 100, GameConstants.OCEAN_SIZE.Y), "West"}
	}
	
	for _, boundary in pairs(boundaries) do
		local wall = Instance.new("Part")
		wall.Name = "Boundary_" .. boundary[3]
		wall.Position = boundary[1]
		wall.Size = boundary[2]
		wall.Anchored = true
		wall.Locked = true
		wall.BrickColor = BrickColor.new("Rock")
		wall.Transparency = 0.8
		wall.CanCollide = true
		wall.Parent = Workspace
	end
	
	-- Create decorative elements
	GameLoopManager.CreateDecorativeElements()
end

function GameLoopManager.CreateDecorativeElements()
	-- Create coral formations
	for i = 1, 20 do
		local coral = Instance.new("Model")
		coral.Name = "Coral_" .. i
		
		-- Simple coral shape
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Size = Vector3.new(2, 4, 2)
		base.BrickColor = BrickColor.new("Pink")
		base.Material = Enum.Material.Neon
		base.Anchored = true
		
		-- Random position within ocean
		local x = GameUtilities.RandomFloat(-GameConstants.OCEAN_SIZE.X/3, GameConstants.OCEAN_SIZE.X/3)
		local z = GameUtilities.RandomFloat(-GameConstants.OCEAN_SIZE.Y/3, GameConstants.OCEAN_SIZE.Y/3)
		base.Position = Vector3.new(x, GameConstants.OCEAN_DEPTH + 10, z)
		
		base.Parent = coral
		coral.Parent = Workspace
	end
	
	-- Create seaweed
	for i = 1, 30 do
		local seaweed = Instance.new("Model")
		seaweed.Name = "Seaweed_" .. i
		
		for j = 1, 3 do
			local segment = Instance.new("Part")
			segment.Name = "Segment_" .. j
			segment.Size = Vector3.new(1, 3, 1)
			segment.BrickColor = BrickColor.new("Dark green")
			segment.Material = Enum.Material.Grass
			segment.Anchored = true
			
			local x = GameUtilities.RandomFloat(-GameConstants.OCEAN_SIZE.X/3, GameConstants.OCEAN_SIZE.X/3)
			local z = GameUtilities.RandomFloat(-GameConstants.OCEAN_SIZE.Y/3, GameConstants.OCEAN_SIZE.Y/3)
			segment.Position = Vector3.new(x, GameConstants.OCEAN_DEPTH + 5 + j * 3, z)
			
			segment.Parent = seaweed
		end
		
		seaweed.Parent = Workspace
	end
	
	-- Create bubbles
	GameLoopManager.CreateBubbleSystem()
end

function GameLoopManager.CreateBubbleSystem()
	-- Create bubble spawner
	task.spawn(function()
		while true do
			task.wait(GameUtilities.RandomFloat(1, 3))
			
			-- Create bubble
			local bubble = Instance.new("Part")
			bubble.Name = "Bubble"
			bubble.Size = Vector3.new(0.5, 0.5, 0.5)
			bubble.Shape = Enum.PartType.Ball
			bubble.Material = Enum.Material.Glass
			bubble.Transparency = 0.3
			bubble.BrickColor = BrickColor.new("Light blue")
			bubble.CanCollide = false
			bubble.Anchored = false
			
			-- Random position
			local x = GameUtilities.RandomFloat(-GameConstants.OCEAN_SIZE.X/2, GameConstants.OCEAN_SIZE.X/2)
			local z = GameUtilities.RandomFloat(-GameConstants.OCEAN_SIZE.Y/2, GameConstants.OCEAN_SIZE.Y/2)
			bubble.Position = Vector3.new(x, GameConstants.OCEAN_DEPTH, z)
			
			-- Add upward force
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 5, 0)
			bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
			bodyVelocity.Parent = bubble
			
			bubble.Parent = Workspace
			
			-- Remove bubble after it reaches surface
			task.wait(10)
			if bubble then
				bubble:Destroy()
			end
		end
	end)
end

-- GAME LOOP
function GameLoopManager.StartGameLoop()
	if isRunning then
		GameUtilities.LogWarning("GameLoopManager: Game loop is already running")
		return
	end
	
	isRunning = true
	GameUtilities.DebugPrint("GameLoopManager: Starting game loop")
	
	gameLoopConnection = RunService.Heartbeat:Connect(function(deltaTime)
		GameLoopManager.UpdateGameLoop(deltaTime)
	end)
end

function GameLoopManager.StopGameLoop()
	if not isRunning then
		return
	end
	
	isRunning = false
	if gameLoopConnection then
		gameLoopConnection:Disconnect()
		gameLoopConnection = nil
	end
	
	GameUtilities.DebugPrint("GameLoopManager: Stopped game loop")
end

function GameLoopManager.UpdateGameLoop(deltaTime)
	-- Update enemies
	GameLoopManager.UpdateEnemies(deltaTime)
	
	-- Update items
	GameLoopManager.UpdateItems(deltaTime)
	
	-- Spawn new enemies
	if #enemies < spawnConfig.MaxEnemies then
		GameLoopManager.TrySpawnEnemy()
	end
	
	-- Spawn new items
	if #items < spawnConfig.MaxItems then
		GameLoopManager.TrySpawnItem()
	end
	
	-- Clean up distant objects
	GameLoopManager.CleanupDistantObjects()
end

-- ENEMY MANAGEMENT
function GameLoopManager.TrySpawnEnemy()
	local player = GameLoopManager.GetRandomPlayer()
	if not player then return end
	
	local character = player.Character
	if not character then return end
	
	local primaryPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("PrimaryPart")
	if not primaryPart then return end
	
	local playerPosition = primaryPart.Position
	
	-- Find spawn position
	local spawnPosition = GameLoopManager.FindSpawnPosition(playerPosition, spawnConfig.SpawnRadius)
	if not spawnPosition then return end
	
	-- Choose enemy type
	local enemyType = GameLoopManager.ChooseEnemyType()
	
	-- Spawn enemy
	GameLoopManager.SpawnEnemy(enemyType, spawnPosition)
end

function GameLoopManager.FindSpawnPosition(centerPosition, radius)
	local maxAttempts = 10
	
	for attempt = 1, maxAttempts do
		local angle = math.random() * math.pi * 2
		local distance = GameUtilities.RandomFloat(radius * 0.5, radius)
		
		local x = centerPosition.X + math.cos(angle) * distance
		local z = centerPosition.Z + math.sin(angle) * distance
		local y = GameUtilities.RandomFloat(GameConstants.OCEAN_DEPTH + 10, GameConstants.WATER_LEVEL - 10)
		
		local spawnPosition = Vector3.new(x, y, z)
		
		-- Check if position is valid (not too close to other enemies)
		local valid = true
		for _, enemy in pairs(enemies) do
			if enemy.Model and enemy.Model.PrimaryPart then
				local distance = (spawnPosition - enemy.Model.PrimaryPart.Position).Magnitude
				if distance < 20 then
					valid = false
					break
				end
			end
		end
		
		if valid then
			return spawnPosition
		end
	end
	
	return nil
end

function GameLoopManager.ChooseEnemyType()
	-- Weighted random selection based on player level
	local player = GameLoopManager.GetRandomPlayer()
	local playerLevel = 1
	
	if player then
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		local data = PlayerDataManager.GetPlayerData(player.UserId)
		if data then
			playerLevel = data.Level
		end
	end
	
	local choices = {}
	
	-- Add common enemies
	for enemyType, enemyData in pairs(GameData.Enemies) do
		local weight = 1
		
		-- Adjust weight based on player level
		if enemyData.XP <= playerLevel * 5 then
			weight = 3 -- More likely to spawn weaker enemies
		elseif enemyData.XP <= playerLevel * 15 then
			weight = 2 -- Medium chance for balanced enemies
		else
			weight = 0.5 -- Less likely for strong enemies
		end
		
		table.insert(choices, {Value = enemyType, Weight = weight})
	end
	
	return GameUtilities.WeightedRandomChoice(choices)
end

function GameLoopManager.SpawnEnemy(enemyType, position)
	local enemyData = GameData.Enemies[enemyType]
	if not enemyData then return nil end
	
	-- Create enemy model
	local model = Instance.new("Model")
	model.Name = enemyData.DisplayName
	
	-- Create main part
	local mainPart = Instance.new("Part")
	mainPart.Name = "Head"
	mainPart.Size = enemyData.Size
	mainPart.Position = position
	mainPart.BrickColor = BrickColor.new("Medium stone gray")
	mainPart.Material = Enum.Material.Plastic
	mainPart.Anchored = false
	mainPart.CanCollide = true
	
	-- Add humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = enemyData.Health
	humanoid.Health = enemyData.Health
	humanoid.WalkSpeed = enemyData.Speed
	humanoid.Parent = model
	
	-- Add health display
	local healthTag = Instance.new("BillboardGui")
	healthTag.Name = "HealthTag"
	healthTag.Size = UDim2.new(0, 100, 0, 20)
	healthTag.StudsOffset = Vector3.new(0, 3, 0)
	healthTag.Parent = mainPart
	
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
	healthBar.Parent = healthTag
	
	mainPart.Parent = model
	model.PrimaryPart = mainPart
	model.Parent = Workspace
	
	-- Create enemy object
	local enemy = {
		Type = enemyType,
		Model = model,
		Data = enemyData,
		Health = enemyData.Health,
		MaxHealth = enemyData.Health,
		State = "Idle",
		Target = nil,
		SpawnTime = tick(),
		LastAttack = 0
	}
	
	table.insert(enemies, enemy)
	
	-- Start AI
	GameLoopManager.StartEnemyAI(enemy)
	
	return enemy
end

function GameLoopManager.StartEnemyAI(enemy)
	task.spawn(function()
		while enemy.Model and enemy.Model.Parent do
			task.wait(0.1) -- AI update rate
			
			if not enemy.Model or not enemy.Model.Parent then break end
			
			-- Update AI state
			GameLoopManager.UpdateEnemyAI(enemy)
		end
		
		-- Clean up
		GameLoopManager.RemoveEnemy(enemy)
	end)
end

function GameLoopManager.UpdateEnemyAI(enemy)
	if not enemy.Model or not enemy.Model.PrimaryPart then return end
	
	local enemyPosition = enemy.Model.PrimaryPart.Position
	
	-- Find nearest player
	local nearestPlayer = GameLoopManager.GetNearestPlayer(enemyPosition)
	
	if nearestPlayer and nearestPlayer.Character then
		local targetPart = nearestPlayer.Character:FindFirstChild("HumanoidRootPart") or nearestPlayer.Character:FindFirstChild("PrimaryPart")
		if not targetPart then return end
		local playerPosition = targetPart.Position
		local distance = (playerPosition - enemyPosition).Magnitude
		
		enemy.Target = nearestPlayer
		
		if distance <= enemy.Data.Range or distance <= 50 then
			-- Attack state
			enemy.State = "Attack"
			GameLoopManager.EnemyAttack(enemy, nearestPlayer)
		elseif distance <= 200 then
			-- Chase state
			enemy.State = "Chase"
			GameLoopManager.EnemyChase(enemy, nearestPlayer)
		else
			-- Idle state
			enemy.State = "Idle"
			GameLoopManager.EnemyIdle(enemy)
		end
	else
		-- No target, idle
		enemy.State = "Idle"
		enemy.Target = nil
		GameLoopManager.EnemyIdle(enemy)
	end
end

function GameLoopManager.EnemyIdle(enemy)
	-- Random movement
	if math.random() < 0.1 then -- 10% chance to change direction
		local humanoid = enemy.Model:FindFirstChild("Humanoid")
		if humanoid then
			local direction = Vector3.new(
				GameUtilities.RandomFloat(-1, 1),
				0,
				GameUtilities.RandomFloat(-1, 1)
			).Unit
			
			humanoid:Move(direction * enemy.Data.Speed * 0.3)
		end
	end
end

function GameLoopManager.EnemyChase(enemy, target)
	if not target or not target.Character then return end
	
	local humanoid = enemy.Model:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	if not enemy.Model or not enemy.Model.PrimaryPart then return end
	local targetPart = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("PrimaryPart")
	if not targetPart then return end
	
	local enemyPosition = enemy.Model.PrimaryPart.Position
	local targetPosition = targetPart.Position
	local distance = (targetPosition - enemyPosition).Magnitude
	
	-- Pathfinding with obstacle avoidance (C6)
	local moveDirection = GameLoopManager.CalculatePathDirection(enemy, enemyPosition, targetPosition, distance)
	
	-- Adjust speed based on behavior
	local speed = enemy.Data.Speed
	if enemy.Data.Behavior == "Aggressive" and distance < 50 then
		speed = speed * 1.3 -- Sprint when close
	end
	
	humanoid:Move(moveDirection * speed)
end

-- PATHFINDING SYSTEM (C6)
function GameLoopManager.CalculatePathDirection(enemy, startPos, targetPos, distance)
	local directDirection = (targetPos - startPos).Unit
	
	-- If very close, just go directly
	if distance < 10 then
		return directDirection
	end
	
	-- Check for obstacles using raycast
	local rayOrigin = startPos
	local rayDirection = directDirection * math.min(distance, 30)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {enemy.Model, Workspace:FindFirstChild("Terrain")}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	
	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		-- Obstacle detected, try to navigate around
		return GameLoopManager.FindAvoidanceDirection(enemy, startPos, targetPos, directDirection, raycastResult.Position, raycastResult.Normal)
	end
	
	-- No obstacle, direct path is clear
	return directDirection
end

function GameLoopManager.FindAvoidanceDirection(enemy, startPos, targetPos, directDir, hitPos, hitNormal)
	-- Try multiple angles to find clear path
	local bestDirection = directDir
	local bestScore = -math.huge
	
	for angle = -90, 90, 30 do
		local radians = math.rad(angle)
		local rotatedDir = Vector3.new(
			directDir.X * math.cos(radians) - directDir.Z * math.sin(radians),
			0,
			directDir.X * math.sin(radians) + directDir.Z * math.cos(radians)
		).Unit
		
		-- Test this direction
		local testRay = rotatedDir * 20
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {enemy.Model}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		
		local result = Workspace:Raycast(startPos, testRay, raycastParams)
		
		-- Score based on clear path and progress toward target
		local score = 0
		if not result then
			score += 50 -- Clear path bonus
		else
			score -= 20 -- Obstacle penalty
		end
		
		-- Bonus for directions toward target
		local toTarget = (targetPos - startPos).Unit
		local alignment = rotatedDir:Dot(toTarget)
		score += alignment * 30
		
		if score > bestScore then
			bestScore = score
			bestDirection = rotatedDir
		end
	end
	
	return bestDirection
end

-- DAMAGE SYSTEM INTEGRATION
function GameLoopManager.DamageEnemy(enemyModel, damage)
	-- Find enemy by model
	for _, enemy in pairs(enemies) do
		if enemy.Model == enemyModel then
			enemy.Health -= damage
			
			-- Visual feedback
			if enemy.Model and enemy.Model.PrimaryPart then
				GameLoopManager.ShowEnemyDamage(enemy, damage)
			end
			
			-- Check death
			if enemy.Health <= 0 then
				GameLoopManager.OnEnemyDied(enemy)
			end
			
			return true
		end
	end
	
	return false
end

function GameLoopManager.ShowEnemyDamage(enemy, damage)
	local position = enemy.Model.PrimaryPart.Position
	
	-- Flash the enemy red
	for _, part in pairs(enemy.Model:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalColor = part.BrickColor
			part.BrickColor = BrickColor.new("Bright red")
			
			task.delay(0.2, function()
				if part then
					part.BrickColor = originalColor
				end
			end)
		end
	end
end

function GameLoopManager.EnemyAttack(enemy, target)
	if not target or not target.Character then return end
	
	local currentTime = tick()
	local attackCooldown = enemy.Data.Cooldown or 2.0
	
	if currentTime - enemy.LastAttack < attackCooldown then return end
	
	if not enemy.Model or not enemy.Model.PrimaryPart then return end
	local targetPart = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("PrimaryPart")
	if not targetPart then return end
	
	local enemyPosition = enemy.Model.PrimaryPart.Position
	local targetPosition = targetPart.Position
	local distance = (targetPosition - enemyPosition).Magnitude
	
	if distance <= (enemy.Data.Range or 10) then
		-- Deal damage
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		PlayerDataManager.DamagePlayer(target, enemy.Data.Damage, GameEnums.DamageType.PHYSICAL)
		
		enemy.LastAttack = currentTime
		
		-- Visual effect
		GameLoopManager.CreateAttackEffect(enemyPosition, targetPosition)
	end
end

function GameLoopManager.CreateAttackEffect(from, to)
	-- Create simple attack trail
	local trail = Instance.new("Part")
	trail.Name = "AttackTrail"
	trail.Size = Vector3.new(1, 1, (from - to).Magnitude)
	trail.Position = from:Lerp(to, 0.5)
	trail.BrickColor = BrickColor.new("Bright red")
	trail.Material = Enum.Material.Neon
	trail.Transparency = 0.5
	trail.Anchored = true
	trail.CanCollide = false
	
	-- Point towards target
	trail.CFrame = CFrame.new(trail.Position, to)
	
	trail.Parent = Workspace
	
	-- Remove after short time
	task.wait(0.2)
	if trail then
		trail:Destroy()
	end
end

function GameLoopManager.UpdateEnemies(deltaTime)
	for i = #enemies, 1, -1 do
		local enemy = enemies[i]
		
		if not enemy.Model or not enemy.Model.Parent then
			table.remove(enemies, i)
		elseif enemy.Health <= 0 then
			GameLoopManager.OnEnemyDied(enemy)
			table.remove(enemies, i)
		end
	end
end

function GameLoopManager.OnEnemyDied(enemy)
	-- Award XP and gold to nearby players
	local enemyPosition = enemy.Model.PrimaryPart.Position
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local distance = (player.Character.PrimaryPart.Position - enemyPosition).Magnitude
			if distance <= 200 then -- Award range
				local PlayerDataManager = require(script.Parent.PlayerDataManager)
				PlayerDataManager.AddXP(player, enemy.Data.XP)
				PlayerDataManager.AddCurrency(player, GameEnums.CurrencyType.GOLD, enemy.Data.Gold)
				
				-- Update statistics
				local data = PlayerDataManager.GetPlayerData(player.UserId)
				if data then
					data.Statistics.TotalDamageDealt += enemy.Data.MaxHealth
					data.EnemiesKilled += 1
				end
			end
		end
	end
	
	-- Drop loot
	GameLoopManager.DropLoot(enemy)
	
	-- Visual effects
	GameLoopManager.CreateDeathEffect(enemy)
	
	-- Remove model
	if enemy.Model then
		enemy.Model:Destroy()
	end
end

function GameLoopManager.DropLoot(enemy)
	-- Chance to drop items
	if math.random() < 0.3 then -- 30% chance
		local lootPosition = enemy.Model.PrimaryPart.Position
		
		-- Choose random item
		local itemChoices = {}
		for itemName, itemData in pairs(GameData.Items) do
			if itemData.Type == GameEnums.ItemType.FOOD or itemData.Type == GameEnums.ItemType.POTION then
				table.insert(itemChoices, itemName)
			end
		end
		
		if #itemChoices > 0 then
			local chosenItem = itemChoices[math.random(1, #itemChoices)]
			GameLoopManager.SpawnItem(chosenItem, lootPosition)
		end
	end
end

function GameLoopManager.CreateDeathEffect(enemy)
	-- Simple death effect
	local position = enemy.Model.PrimaryPart.Position
	
	for i = 1, 5 do
		local particle = Instance.new("Part")
		particle.Name = "DeathParticle"
		particle.Size = Vector3.new(0.5, 0.5, 0.5)
		particle.Shape = Enum.PartType.Ball
		particle.BrickColor = BrickColor.new("Bright red")
		particle.Material = Enum.Material.Neon
		particle.Anchored = false
		particle.CanCollide = false
		
		local offset = Vector3.new(
			GameUtilities.RandomFloat(-2, 2),
			GameUtilities.RandomFloat(0, 3),
			GameUtilities.RandomFloat(-2, 2)
		)
		particle.Position = position + offset
		
		-- Add random velocity
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(
			GameUtilities.RandomFloat(-5, 5),
			GameUtilities.RandomFloat(2, 8),
			GameUtilities.RandomFloat(-5, 5)
		)
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.Parent = particle
		
		particle.Parent = Workspace
		
		-- Remove after time
		task.delay(2, function()
			if particle then
				particle:Destroy()
			end
		end)
	end
end

function GameLoopManager.RemoveEnemy(enemy)
	for i, e in pairs(enemies) do
		if e == enemy then
			table.remove(enemies, i)
			break
		end
	end
	
	if enemy.Model then
		enemy.Model:Destroy()
	end
end

-- ITEM MANAGEMENT
function GameLoopManager.TrySpawnItem()
	local player = GameLoopManager.GetRandomPlayer()
	if not player then return end
	
	local character = player.Character
	if not character then return end
	
	local primaryPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("PrimaryPart")
	if not primaryPart then return end
	
	local playerPosition = primaryPart.Position
	
	-- Find spawn position
	local spawnPosition = GameLoopManager.FindSpawnPosition(playerPosition, spawnConfig.SpawnRadius * 0.7)
	if not spawnPosition then return end
	
	-- Choose item type
	local itemChoices = {}
	for itemName, itemData in pairs(GameData.Items) do
		if itemData.Type == GameEnums.ItemType.FOOD then
			table.insert(itemChoices, itemName)
		end
	end
	
	if #itemChoices == 0 then return end
	
	local chosenItem = itemChoices[math.random(1, #itemChoices)]
	
	-- Spawn item
	GameLoopManager.SpawnItem(chosenItem, spawnPosition)
end

function GameLoopManager.SpawnItem(itemName, position)
	local itemData = GameData.Items[itemName]
	if not itemData then return nil end
	
	-- Create item model
	local model = Instance.new("Model")
	model.Name = itemData.DisplayName
	
	-- Create main part
	local mainPart = Instance.new("Part")
	mainPart.Name = "Item"
	mainPart.Size = Vector3.new(2, 2, 2)
	mainPart.Position = position
	mainPart.BrickColor = BrickColor.new("Bright green")
	mainPart.Material = Enum.Material.Neon
	mainPart.Anchored = true
	mainPart.CanCollide = false
	
	-- Add floating animation
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, 1, 0)
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Parent = mainPart
	
	-- Add glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.new(0, 1, 0)
	pointLight.Range = 10
	pointLight.Brightness = 2
	pointLight.Parent = mainPart
	
	mainPart.Parent = model
	model.Parent = Workspace
	
	-- Create item object
	local item = {
		Name = itemName,
		Data = itemData,
		Model = model,
		SpawnTime = tick()
	}
	
	table.insert(items, item)
	
	-- Set up collection
	GameLoopManager.SetupItemCollection(item)
	
	return item
end

function GameLoopManager.SetupItemCollection(item)
	local collectionRadius = 5
	
	-- Check for player proximity
	task.spawn(function()
		while item.Model and item.Model.Parent do
			task.wait(0.5)
			
			if not item.Model or not item.Model.PrimaryPart then break end
			
			local itemPosition = item.Model.PrimaryPart.Position
			
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character.PrimaryPart then
					local distance = (player.Character.PrimaryPart.Position - itemPosition).Magnitude
					if distance <= collectionRadius then
						GameLoopManager.CollectItem(player, item)
						break
					end
				end
			end
		end
		
		-- Clean up
		GameLoopManager.RemoveItem(item)
	end)
end

function GameLoopManager.CollectItem(player, item)
	local PlayerDataManager = require(script.Parent.PlayerDataManager)
	
	-- Add item to player inventory
	local success = PlayerDataManager.AddItem(player, item.Data, 1)
	
	if success then
		-- Update statistics
		local data = PlayerDataManager.GetPlayerData(player.UserId)
		if data then
			data.FoodEaten += 1
		end
		
		-- Visual effect
		GameLoopManager.CreateCollectionEffect(item.Model.PrimaryPart.Position)
		
		-- Remove item
		GameLoopManager.RemoveItem(item)
		
		GameUtilities.DebugPrint("GameLoopManager: " .. player.Name .. " collected " .. item.Data.DisplayName)
	end
end

function GameLoopManager.CreateCollectionEffect(position)
	-- Simple collection effect
	local effect = Instance.new("Part")
	effect.Name = "CollectionEffect"
	effect.Size = Vector3.new(1, 1, 1)
	effect.Shape = Enum.PartType.Ball
	effect.BrickColor = BrickColor.new("Bright green")
	effect.Material = Enum.Material.Neon
	effect.Anchored = true
	effect.CanCollide = false
	effect.Position = position
	
	-- Animate
	local startSize = effect.Size
	local endSize = Vector3.new(5, 5, 5)
	
	for i = 1, 20 do
		local progress = i / 20
		effect.Size = startSize:Lerp(endSize, progress)
		effect.Transparency = progress
		task.wait(0.05)
	end
	
	effect:Destroy()
end

function GameLoopManager.UpdateItems(deltaTime)
	for i = #items, 1, -1 do
		local item = items[i]
		
		if not item.Model or not item.Model.Parent then
			table.remove(items, i)
		elseif tick() - item.SpawnTime > 300 then -- Despawn after 5 minutes
			GameLoopManager.RemoveItem(item)
			table.remove(items, i)
		end
	end
end

function GameLoopManager.RemoveItem(item)
	for i, it in pairs(items) do
		if it == item then
			table.remove(items, i)
			break
		end
	end
	
	if item.Model then
		item.Model:Destroy()
	end
end

-- UTILITY FUNCTIONS
function GameLoopManager.GetRandomPlayer()
	local playerList = Players:GetPlayers()
	if #playerList == 0 then return nil end
	
	return playerList[math.random(1, #playerList)]
end

function GameLoopManager.GetNearestPlayer(position)
	local nearestPlayer = nil
	local nearestDistance = math.huge
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local distance = (player.Character.PrimaryPart.Position - position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestPlayer = player
			end
		end
	end
	
	return nearestPlayer
end

function GameLoopManager.CleanupDistantObjects()
	local player = GameLoopManager.GetRandomPlayer()
	if not player then return end
	
	local character = player.Character
	if not character then return end
	
	local primaryPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("PrimaryPart")
	if not primaryPart then return end
	
	local playerPosition = primaryPart.Position
	
	-- Clean up distant enemies
	for i = #enemies, 1, -1 do
		local enemy = enemies[i]
		if enemy.Model and enemy.Model.PrimaryPart then
			local distance = (enemy.Model.PrimaryPart.Position - playerPosition).Magnitude
			if distance > spawnConfig.DespawnRadius then
				GameLoopManager.RemoveEnemy(enemy)
				table.remove(enemies, i)
			end
		end
	end
	
	-- Clean up distant items
	for i = #items, 1, -1 do
		local item = items[i]
		if item.Model and item.Model.PrimaryPart then
			local distance = (item.Model.PrimaryPart.Position - playerPosition).Magnitude
			if distance > spawnConfig.DespawnRadius then
				GameLoopManager.RemoveItem(item)
				table.remove(items, i)
			end
		end
	end
end

-- PUBLIC API
function GameLoopManager.GetEnemies()
	return enemies
end

function GameLoopManager.GetItems()
	return items
end

function GameLoopManager.GetEnemyCount()
	return #enemies
end

function GameLoopManager.GetItemCount()
	return #items
end

-- CLEANUP
function GameLoopManager.Cleanup()
	GameLoopManager.StopGameLoop()
	
	-- Clean up all enemies
	for _, enemy in pairs(enemies) do
		if enemy.Model then
			enemy.Model:Destroy()
		end
	end
	enemies = {}
	
	-- Clean up all items
	for _, item in pairs(items) do
		if item.Model then
			item.Model:Destroy()
		end
	end
	items = {}
	
	GameUtilities.DebugPrint("GameLoopManager: Cleaned up")
end

return GameLoopManager
