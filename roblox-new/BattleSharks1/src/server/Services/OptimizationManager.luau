-- BattleSharks Optimization Manager (F)
-- Server and client optimization systems

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local OptimizationManager = {}

-- PRIVATE VARIABLES
local spatialGrid = {}
local gridSize = 100
local updateQueue = {}
local lodDistances = {100, 300, 600} -- LOD levels
local pooledEnemies = {}
local pooledEffects = {}
local networkCullingDistance = 500

-- PERFORMANCE CONFIG
local OPTIMIZATION_CONFIG = {
	MaxUpdatesPerFrame = 50,
	SpatialGridCellSize = 100,
	EnemyUpdateInterval = 0.1, -- 10Hz for enemies
	NetworkUpdateRate = 20, -- 20Hz for network
	CullingCheckInterval = 0.5,
	PoolSize = 30
}

-- INITIALIZATION
function OptimizationManager.Initialize()
	GameUtilities.DebugPrint("OptimizationManager: Initializing")
	
	-- Start optimization systems
	OptimizationManager.StartSpatialPartitioning()
	OptimizationManager.StartLODSystem()
	OptimizationManager.StartNetworkCulling()
	OptimizationManager.InitializeObjectPools()
	OptimizationManager.StartBatchUpdateSystem()
	
	GameUtilities.DebugPrint("OptimizationManager: Initialized")
end

-- SPATIAL PARTITIONING (F2)
function OptimizationManager.StartSpatialPartitioning()
	RunService.Heartbeat:Connect(function()
		OptimizationManager.UpdateSpatialGrid()
	end)
end

function OptimizationManager.UpdateSpatialGrid()
	spatialGrid = {}
	
	-- Add players to grid
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local pos = player.Character.PrimaryPart.Position
			local cell = OptimizationManager.GetCell(pos)
			spatialGrid[cell] = spatialGrid[cell] or {}
			table.insert(spatialGrid[cell], {Type = "Player", Object = player})
		end
	end
	
	-- Add enemies to grid
	local GameLoopManager = require(script.Parent.GameLoopManager)
	for _, enemy in pairs(GameLoopManager.GetEnemies()) do
		if enemy.Model and enemy.Model.PrimaryPart then
			local pos = enemy.Model.PrimaryPart.Position
			local cell = OptimizationManager.GetCell(pos)
			spatialGrid[cell] = spatialGrid[cell] or {}
			table.insert(spatialGrid[cell], {Type = "Enemy", Object = enemy})
		end
	end
end

function OptimizationManager.GetCell(position)
	local x = math.floor(position.X / OPTIMIZATION_CONFIG.SpatialGridCellSize)
	local z = math.floor(position.Z / OPTIMIZATION_CONFIG.SpatialGridCellSize)
	return x .. "," .. z
end

function OptimizationManager.GetNearbyObjects(position, radius)
	local nearby = {}
	local centerCell = OptimizationManager.GetCell(position)
	local cellRadius = math.ceil(radius / OPTIMIZATION_CONFIG.SpatialGridCellSize)
	
	local cx, cz = centerCell:match("(-?%d+),(-?%d+)")
	cx, cz = tonumber(cx), tonumber(cz)
	
	for x = cx - cellRadius, cx + cellRadius do
		for z = cz - cellRadius, cz + cellRadius do
			local cell = x .. "," .. z
			if spatialGrid[cell] then
				for _, obj in pairs(spatialGrid[cell]) do
					if obj.Object and obj.Object.PrimaryPart then
						local dist = (obj.Object.PrimaryPart.Position - position).Magnitude
						if dist <= radius then
							table.insert(nearby, obj)
						end
					end
				end
			end
		end
	end
	
	return nearby
end

-- OBJECT POOLING (F1)
function OptimizationManager.InitializeObjectPools()
	-- Pre-create enemy models in a hidden storage
	local storage = Instance.new("Folder")
	storage.Name = "EnemyPool"
	storage.Parent = ReplicatedStorage
	
	for i = 1, OPTIMIZATION_CONFIG.PoolSize do
		local enemyTemplate = OptimizationManager.CreateEnemyTemplate()
		enemyTemplate.Name = "PooledEnemy_" .. i
		enemyTemplate.Parent = storage
		table.insert(pooledEnemies, enemyTemplate)
	end
	
	-- Effect pool
	local effectStorage = Instance.new("Folder")
	effectStorage.Name = "EffectPool"
	effectStorage.Parent = ReplicatedStorage
	
	for i = 1, OPTIMIZATION_CONFIG.PoolSize do
		local effectTemplate = OptimizationManager.CreateEffectTemplate()
		effectTemplate.Name = "PooledEffect_" .. i
		effectTemplate.Parent = effectStorage
		table.insert(pooledEffects, effectTemplate)
	end
end

function OptimizationManager.CreateEnemyTemplate()
	local model = Instance.new("Model")
	
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4, 2, 8)
	body.BrickColor = BrickColor.new("Medium stone gray")
	body.Parent = model
	model.PrimaryPart = body
	
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	
	return model
end

function OptimizationManager.CreateEffectTemplate()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	return part
end

function OptimizationManager.GetPooledEnemy()
	for _, enemy in pairs(pooledEnemies) do
		if enemy.Parent == ReplicatedStorage:FindFirstChild("EnemyPool") then
			return enemy
		end
	end
	return nil -- Pool exhausted
end

function OptimizationManager.ReturnEnemyToPool(enemy)
	local storage = ReplicatedStorage:FindFirstChild("EnemyPool")
	if storage then
		enemy:ClearAllChildren()
		enemy.Parent = storage
	end
end

function OptimizationManager.GetPooledEffect()
	for _, effect in pairs(pooledEffects) do
		if effect.Parent == ReplicatedStorage:FindFirstChild("EffectPool") then
			return effect
		end
	end
	return nil
end

-- BATCH UPDATE SYSTEM (F6)
function OptimizationManager.StartBatchUpdateSystem()
	local updatesThisFrame = 0
	
	RunService.Heartbeat:Connect(function()
		updatesThisFrame = 0
		
		-- Process queued updates
		while #updateQueue > 0 and updatesThisFrame < OPTIMIZATION_CONFIG.MaxUpdatesPerFrame do
			local update = table.remove(updateQueue, 1)
			if update and update.Function then
				update.Function(update.Data)
				updatesThisFrame += 1
			end
		end
	end)
end

function OptimizationManager.QueueUpdate(func, data)
	table.insert(updateQueue, {Function = func, Data = data})
end

-- NETWORK CULLING (F7)
function OptimizationManager.StartNetworkCulling()
	task.spawn(function()
		while true do
			task.wait(OPTIMIZATION_CONFIG.CullingCheckInterval)
			OptimizationManager.UpdateNetworkVisibility()
		end
	end)
end

function OptimizationManager.UpdateNetworkVisibility()
	local players = Players:GetPlayers()
	
	for i, player1 in pairs(players) do
		if not player1.Character or not player1.Character.PrimaryPart then continue end
		
		local pos1 = player1.Character.PrimaryPart.Position
		
		for j, player2 in pairs(players) do
			if i == j then continue end
			if not player2.Character or not player2.Character.PrimaryPart then continue end
			
			local pos2 = player2.Character.PrimaryPart.Position
			local distance = (pos2 - pos1).Magnitude
			
			-- Set network ownership based on distance
			if distance > networkCullingDistance then
				-- Cull - don't send updates
				OptimizationManager.SetPlayerVisibility(player1, player2, false)
			else
				OptimizationManager.SetPlayerVisibility(player1, player2, true)
			end
		end
	end
end

function OptimizationManager.SetPlayerVisibility(observer, target, visible)
	-- This would integrate with your network replication system
	-- For now, it's a placeholder for the concept
end

-- LOD SYSTEM (F3)
function OptimizationManager.StartLODSystem()
	task.spawn(function()
		while true do
			task.wait(0.5)
			OptimizationManager.UpdateLOD()
		end
	end)
end

function OptimizationManager.UpdateLOD()
	for _, player in pairs(Players:GetPlayers()) do
		if not player.Character or not player.Character.PrimaryPart then continue end
		
		local playerPos = player.Character.PrimaryPart.Position
		
		-- Update terrain LOD
		for _, part in pairs(Workspace:GetDescendants()) do
			if part:IsA("BasePart") and part.Name:find("Terrain") or part.Name:find("Decor") then
				local dist = (part.Position - playerPos).Magnitude
				
				if dist < lodDistances[1] then
					part.Transparency = 0
				elseif dist < lodDistances[2] then
					part.Transparency = 0.3
				elseif dist < lodDistances[3] then
					part.Transparency = 0.7
				else
					part.Transparency = 1
				end
			end
		end
	end
end

-- PERFORMANCE MONITORING
function OptimizationManager.GetPerformanceStats()
	return {
		SpatialGridCells = 0,
		PooledEnemiesAvailable = 0,
		PooledEffectsAvailable = 0,
		UpdateQueueLength = #updateQueue,
		ServerMemory = collectgarbage("count"),
		ActivePlayers = #Players:GetPlayers()
	}
end

-- CLEANUP
function OptimizationManager.Cleanup()
	spatialGrid = {}
	updateQueue = {}
	
	local enemyPool = ReplicatedStorage:FindFirstChild("EnemyPool")
	if enemyPool then enemyPool:Destroy() end
	
	local effectPool = ReplicatedStorage:FindFirstChild("EffectPool")
	if effectPool then effectPool:Destroy() end
	
	pooledEnemies = {}
	pooledEffects = {}
end

return OptimizationManager
