-- BattleSharks Physics Manager
-- Handles per-player physics: buoyancy, drag, and water forces (C2)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Load shared modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local PhysicsManager = {}

-- PRIVATE VARIABLES
local playerPhysics = {} -- Per-player physics state
local physicsLoopConnection = nil

-- Per-player physics configuration
local PHYSICS_CONFIG = {
	BuoyancyForce = 85, -- Upward force in water
	WaterDragCoefficient = 0.15, -- Resistance in water
	AirDragCoefficient = 0.01, -- Resistance in air
	SurfaceTensionDistance = 5, -- Distance from surface to apply surface effects
	MaxVelocity = GameConstants.SHARK_BOOST_SPEED * 1.5 -- Hard velocity cap
}

-- INITIALIZATION
function PhysicsManager.Initialize()
	GameUtilities.DebugPrint("PhysicsManager: Initializing")
	
	-- Set up player events
	Players.PlayerAdded:Connect(PhysicsManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(PhysicsManager.OnPlayerRemoving)
	
	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		PhysicsManager.OnPlayerAdded(player)
	end
	
	-- Start physics loop
	PhysicsManager.StartPhysicsLoop()
	
	GameUtilities.DebugPrint("PhysicsManager: Initialized")
end

-- PLAYER EVENTS
function PhysicsManager.OnPlayerAdded(player)
	GameUtilities.DebugPrint("PhysicsManager: Setting up physics for " .. player.Name)
	
	playerPhysics[player.UserId] = {
		BuoyancyEnabled = true,
		DragEnabled = true,
		IsUnderwater = false,
		WaterEntryTime = 0,
		LastPosition = nil,
		Velocity = Vector3.zero,
		Mass = 100 -- Default shark mass
	}
	
	-- Set up character physics
	player.CharacterAdded:Connect(function(character)
		PhysicsManager.SetupCharacterPhysics(player, character)
	end)
	
	if player.Character then
		PhysicsManager.SetupCharacterPhysics(player, player.Character)
	end
end

function PhysicsManager.OnPlayerRemoving(player)
	GameUtilities.DebugPrint("PhysicsManager: Cleaning up physics for " .. player.Name)
	playerPhysics[player.UserId] = nil
end

-- CHARACTER PHYSICS SETUP
function PhysicsManager.SetupCharacterPhysics(player, character)
	local physicsData = playerPhysics[player.UserId]
	if not physicsData then return end
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end
	
	-- Configure part physical properties for better water interaction
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Set density for realistic water interaction
			part.CustomPhysicalProperties = PhysicalProperties.new(
				0.8, -- Density (slightly less than water for buoyancy)
				0.3, -- Friction
				0.1, -- Elasticity
				1.0, -- FrictionWeight
				1.0  -- ElasticityWeight
			)
		end
	end
	
	physicsData.LastPosition = humanoidRootPart.Position
	GameUtilities.DebugPrint("PhysicsManager: Physics configured for " .. player.Name)
end

-- PHYSICS LOOP
function PhysicsManager.StartPhysicsLoop()
	if physicsLoopConnection then return end
	
	physicsLoopConnection = RunService.Heartbeat:Connect(function(deltaTime)
		PhysicsManager.UpdateAllPlayers(deltaTime)
	end)
end

function PhysicsManager.StopPhysicsLoop()
	if physicsLoopConnection then
		physicsLoopConnection:Disconnect()
		physicsLoopConnection = nil
	end
end

function PhysicsManager.UpdateAllPlayers(deltaTime)
	for userId, physicsData in pairs(playerPhysics) do
		local player = Players:GetPlayerByUserId(userId)
		if player and player.Character then
			PhysicsManager.UpdatePlayerPhysics(player, physicsData, deltaTime)
		end
	end
end

function PhysicsManager.UpdatePlayerPhysics(player, physicsData, deltaTime)
	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local currentPosition = humanoidRootPart.Position
	local currentVelocity = humanoidRootPart.Velocity
	
	-- Calculate velocity for tracking
	if physicsData.LastPosition then
		physicsData.Velocity = (currentPosition - physicsData.LastPosition) / deltaTime
	end
	physicsData.LastPosition = currentPosition
	
	-- Check if underwater (C2 + boundary check)
	local waterLevel = GameConstants.WATER_LEVEL
	local oceanDepth = GameConstants.OCEAN_DEPTH
	local isUnderwater = currentPosition.Y <= waterLevel and currentPosition.Y >= oceanDepth
	
	-- Detect water entry/exit
	if isUnderwater ~= physicsData.IsUnderwater then
		physicsData.IsUnderwater = isUnderwater
		if isUnderwater then
			physicsData.WaterEntryTime = tick()
			PhysicsManager.OnPlayerEnteredWater(player, character)
		else
			PhysicsManager.OnPlayerExitedWater(player, character)
		end
	end
	
	-- Apply per-player forces (C2)
	if isUnderwater then
		PhysicsManager.ApplyUnderwaterForces(humanoidRootPart, physicsData, deltaTime)
	else
		PhysicsManager.ApplySurfaceForces(humanoidRootPart, physicsData, deltaTime)
	end
	
	-- Enforce max velocity (hard cap)
	if currentVelocity.Magnitude > PHYSICS_CONFIG.MaxVelocity then
		local clampedVelocity = currentVelocity.Unit * PHYSICS_CONFIG.MaxVelocity
		humanoidRootPart.Velocity = clampedVelocity
	end
end

-- UNDERWATER PHYSICS (C2)
function PhysicsManager.ApplyUnderwaterForces(humanoidRootPart, physicsData, deltaTime)
	if not physicsData.BuoyancyEnabled then return end
	
	-- Calculate depth for pressure effects
	local depth = math.abs(GameConstants.WATER_LEVEL - humanoidRootPart.Position.Y)
	local depthFactor = math.clamp(depth / 100, 0, 1) -- Full effect at 100+ studs depth
	
	-- Buoyancy force (upward) - increases with depth
	local buoyancyMultiplier = 1 + (depthFactor * 0.3) -- More buoyancy at depth
	local buoyancyForce = Vector3.new(0, PHYSICS_CONFIG.BuoyancyForce * buoyancyMultiplier * physicsData.Mass * deltaTime, 0)
	
	-- Apply buoyancy
	humanoidRootPart:ApplyImpulse(buoyancyForce)
	
	-- Drag force (opposes velocity) - reduces with depth
	local velocity = humanoidRootPart.Velocity
	if velocity.Magnitude > 0.1 then
		local dragMultiplier = 1 - (depthFactor * 0.3) -- Less drag at depth
		local dragForce = -velocity * PHYSICS_CONFIG.WaterDragCoefficient * dragMultiplier * deltaTime
		humanoidRootPart:ApplyImpulse(dragForce)
	end
	
	-- Surface tension when near surface
	local distanceFromSurface = math.abs(humanoidRootPart.Position.Y - GameConstants.WATER_LEVEL)
	if distanceFromSurface < PHYSICS_CONFIG.SurfaceTensionDistance then
		local surfaceTension = Vector3.new(0, -20 * (1 - distanceFromSurface / PHYSICS_CONFIG.SurfaceTensionDistance) * deltaTime, 0)
		humanoidRootPart:ApplyImpulse(surfaceTension)
	end
end

-- SURFACE PHYSICS (C2)
function PhysicsManager.ApplySurfaceForces(humanoidRootPart, physicsData, deltaTime)
	if not physicsData.DragEnabled then return end
	
	-- Air drag (much less than water)
	local velocity = humanoidRootPart.Velocity
	if velocity.Magnitude > 0.1 then
		local dragForce = -velocity * PHYSICS_CONFIG.AirDragCoefficient * deltaTime
		humanoidRootPart:ApplyImpulse(dragForce)
	end
	
	-- Gravity assist when above water (pull back down)
	if humanoidRootPart.Position.Y > GameConstants.WATER_LEVEL + 10 then
		local gravityForce = Vector3.new(0, -50 * deltaTime, 0)
		humanoidRootPart:ApplyImpulse(gravityForce)
	end
end

-- EVENT HANDLERS
function PhysicsManager.OnPlayerEnteredWater(player, character)
	GameUtilities.DebugPrint("PhysicsManager: " .. player.Name .. " entered water")
	
	-- Create splash effect
	PhysicsManager.CreateSplashEffect(character.PrimaryPart.Position, "entry")
	
	-- Notify client
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local waterEvent = remoteFolder:FindFirstChild("PlayerEnteredWater")
		if waterEvent then
			waterEvent:FireClient(player)
		end
	end
end

function PhysicsManager.OnPlayerExitedWater(player, character)
	GameUtilities.DebugPrint("PhysicsManager: " .. player.Name .. " exited water")
	
	-- Create splash effect
	PhysicsManager.CreateSplashEffect(character.PrimaryPart.Position, "exit")
end

-- VISUAL EFFECTS
function PhysicsManager.CreateSplashEffect(position, splashType)
	-- Simple splash effect - can be expanded
	local splash = Instance.new("Part")
	splash.Name = "SplashEffect"
	splash.Size = Vector3.new(4, 1, 4)
	splash.Position = position
	splash.BrickColor = BrickColor.new("Light blue")
	splash.Material = Enum.Material.Water
	splash.Transparency = 0.3
	splash.Anchored = true
	splash.CanCollide = false
	splash.Parent = Workspace
	
	-- Animate and destroy
	task.spawn(function()
		for i = 1, 10 do
			local progress = i / 10
			splash.Size = Vector3.new(4 + progress * 4, 1 + progress * 2, 4 + progress * 4)
			splash.Transparency = 0.3 + progress * 0.7
			task.wait(0.05)
		end
		splash:Destroy()
	end)
end

-- PUBLIC API
function PhysicsManager.SetPlayerBuoyancyEnabled(player, enabled)
	local physicsData = playerPhysics[player.UserId]
	if physicsData then
		physicsData.BuoyancyEnabled = enabled
	end
end

function PhysicsManager.SetPlayerDragEnabled(player, enabled)
	local physicsData = playerPhysics[player.UserId]
	if physicsData then
		physicsData.DragEnabled = enabled
	end
end

function PhysicsManager.IsPlayerUnderwater(player)
	local physicsData = playerPhysics[player.UserId]
	return physicsData and physicsData.IsUnderwater or false
end

function PhysicsManager.GetPlayerVelocity(player)
	local physicsData = playerPhysics[player.UserId]
	return physicsData and physicsData.Velocity or Vector3.zero
end

function PhysicsManager.ApplyForce(player, force)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	humanoidRootPart:ApplyImpulse(force)
end

-- CLEANUP
function PhysicsManager.Cleanup()
	PhysicsManager.StopPhysicsLoop()
	playerPhysics = {}
	GameUtilities.DebugPrint("PhysicsManager: Cleaned up")
end

return PhysicsManager
