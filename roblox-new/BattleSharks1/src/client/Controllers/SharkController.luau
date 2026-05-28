-- BattleSharks Shark Controller
-- Handles player shark movement, abilities, and physics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GameConstants = require(script.Parent.Parent.Parent.Shared.Constants.GameConstants)
local GameEnums = require(script.Parent.Parent.Parent.Shared.Enums.GameEnums)
local GameUtilities = require(script.Parent.Parent.Parent.Shared.Utilities.GameUtilities)

local SharkController = {}

-- PRIVATE VARIABLES
local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local humanoidRootPart = nil

-- Movement state
local movementState = {
	IsMoving = false,
	IsBoosting = false,
	IsUnderwater = false,
	CurrentSpeed = 0,
	TargetVelocity = Vector3.zero,
	LastBoostTime = 0,
	BoostCooldown = 0
}

-- Input state
local inputState = {
	Forward = false,
	Backward = false,
	Left = false,
	Right = false,
	Boost = false,
	Attack = false,
	MousePosition = Vector2.zero
}

-- Physics parameters
local physics = {
	Gravity = Workspace.Gravity,
	WaterGravity = GameConstants.UNDERWATER_GRAVITY,
	WaterDensity = GameConstants.WATER_DENSITY,
	WaterLevel = GameConstants.WATER_LEVEL,
	BuoyancyForce = 50,
	DragCoefficient = 0.1,
	TurnSpeed = GameConstants.SHARK_TURN_SPEED
}

-- INITIALIZATION
function SharkController.Initialize()
	GameUtilities.DebugPrint("SharkController: Initializing")
	
	-- Set up character events
	player.CharacterAdded:Connect(SharkController.OnCharacterAdded)
	player.CharacterRemoving:Connect(SharkController.OnCharacterRemoving)
	
	-- Set up input events
	UserInputService.InputBegan:Connect(SharkController.OnInputBegan)
	UserInputService.InputEnded:Connect(SharkController.OnInputEnded)
	UserInputService.InputChanged:Connect(SharkController.OnInputChanged)
	
	-- Initialize character if already loaded
	if player.Character then
		SharkController.OnCharacterAdded(player.Character)
	end
	
	-- Start update loop
	SharkController.StartUpdateLoop()
	
	GameUtilities.DebugPrint("SharkController: Initialized")
end

-- CHARACTER EVENTS
function SharkController.OnCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Configure humanoid for shark movement
	SharkController.ConfigureHumanoid()
	
	-- Set up physics
	SharkController.SetupPhysics()
	
	-- Apply initial stats
	SharkController.ApplyPlayerStats()
	
	GameUtilities.DebugPrint("SharkController: Character configured")
end

function SharkController.OnCharacterRemoving(oldCharacter)
	character = nil
	humanoid = nil
	humanoidRootPart = nil
	
	GameUtilities.DebugPrint("SharkController: Character removed")
end

function SharkController.ConfigureHumanoid()
	if not humanoid then return end
	
	-- Disable default Roblox movement
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
	
	-- Set movement properties
	humanoid.JumpPower = 0 -- Sharks don't jump normally
	humanoid.UseJumpPower = false
	
	-- Set state to swimming
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
	humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
end

function SharkController.SetupPhysics()
	if not humanoidRootPart then return end
	
	-- Configure body parts for water physics
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Set material for water interaction
			part.Material = Enum.Material.Plastic
			part.CustomPhysicalProperties = PhysicalProperties.new(
				1.0, -- Density
				0.3, -- Friction
				0.5, -- Elasticity
				0.5, -- FrictionWeight
				0.5  -- ElasticityWeight
			)
		end
	end
end

function SharkController.ApplyPlayerStats()
	-- Request player data from server
	local NetworkManager = require(script.Parent.Parent.Parent.Shared.Networking.RemoteNames)
	local remoteFolder = ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	
	local getStatsFunction = remoteFolder:WaitForChild("GetPlayerData")
	local playerData = getStatsFunction:InvokeServer()
	
	if playerData then
		movementState.CurrentSpeed = playerData.Speed or GameConstants.SHARK_BASE_SPEED
		
		-- Update humanoid health
		if humanoid then
			humanoid.MaxHealth = playerData.MaxHealth or 100
			humanoid.Health = playerData.Health or 100
		end
	end
end

-- INPUT HANDLING
function SharkController.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	
	local inputType = input.UserInputType
	local keyCode = input.KeyCode
	
	-- Movement keys
	if keyCode == Enum.KeyCode.W then
		inputState.Forward = true
	elseif keyCode == Enum.KeyCode.S then
		inputState.Backward = true
	elseif keyCode == Enum.KeyCode.A then
		inputState.Left = true
	elseif keyCode == Enum.KeyCode.D then
		inputState.Right = true
	elseif keyCode == Enum.KeyCode.LeftShift then
		inputState.Boost = true
	elseif keyCode == Enum.KeyCode.Space then
		SharkController.PerformLeap()
	elseif keyCode == Enum.KeyCode.E then
		SharkController.PerformAttack()
	end
	
	-- Mouse input
	if inputType == Enum.UserInputType.MouseButton1 then
		inputState.Attack = true
		SharkController.PerformAttack()
	elseif inputType == Enum.UserInputType.MouseButton2 then
		SharkController.PerformSecondaryAction()
	end
end

function SharkController.OnInputEnded(input, gameProcessed)
	if gameProcessed then return end
	
	local keyCode = input.KeyCode
	
	if keyCode == Enum.KeyCode.W then
		inputState.Forward = false
	elseif keyCode == Enum.KeyCode.S then
		inputState.Backward = false
	elseif keyCode == Enum.KeyCode.A then
		inputState.Left = false
	elseif keyCode == Enum.KeyCode.D then
		inputState.Right = false
	elseif keyCode == Enum.KeyCode.LeftShift then
		inputState.Boost = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		inputState.Attack = false
	end
end

function SharkController.OnInputChanged(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		inputState.MousePosition = input.Position
	end
end

-- MOVEMENT SYSTEM
function SharkController.StartUpdateLoop()
	RunService.Heartbeat:Connect(function(deltaTime)
		SharkController.UpdateMovement(deltaTime)
		SharkController.UpdatePhysics(deltaTime)
		SharkController.UpdateAnimation(deltaTime)
	end)
end

function SharkController.UpdateMovement(deltaTime)
	if not humanoidRootPart then return end
	
	-- Calculate movement direction
	local moveDirection = Vector3.zero
	
	if inputState.Forward then
		moveDirection += humanoidRootPart.CFrame.LookVector
	end
	if inputState.Backward then
		moveDirection -= humanoidRootPart.CFrame.LookVector
	end
	if inputState.Left then
		moveDirection -= humanoidRootPart.CFrame.RightVector
	end
	if inputState.Right then
		moveDirection += humanoidRootPart.CFrame.RightVector
	end
	
	-- Normalize movement direction
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit
		movementState.IsMoving = true
	else
		movementState.IsMoving = false
	end
	
	-- Calculate target speed
	local targetSpeed = movementState.CurrentSpeed
	if inputState.Boost and SharkController.CanBoost() then
		targetSpeed = GameConstants.SHARK_BOOST_SPEED
		movementState.IsBoosting = true
	else
		movementState.IsBoosting = false
	end
	
	-- Apply boost cooldown
	if movementState.IsBoosting then
		movementState.LastBoostTime = tick()
		movementState.BoostCooldown = GameConstants.SHARK_BOOST_COOLDOWN
	end
	
	-- Update target velocity
	movementState.TargetVelocity = moveDirection * targetSpeed
	
	-- Apply movement
	if humanoid then
		humanoid:Move(movementState.TargetVelocity)
	end
	
	-- Check if underwater
	local currentY = humanoidRootPart.Position.Y
	movementState.IsUnderwater = currentY <= physics.WaterLevel
	
	-- Send movement to server
	if movementState.IsMoving then
		SharkController.SendMovementToServer()
	end
end

function SharkController.UpdatePhysics(deltaTime)
	if not humanoidRootPart then return end
	
	local currentY = humanoidRootPart.Position.Y
	
	-- Apply underwater physics
	if movementState.IsUnderwater then
		-- Apply buoyancy
		local buoyancy = Vector3.new(0, physics.BuoyancyForce * deltaTime, 0)
		humanoidRootPart:ApplyImpulse(buoyancy)
		
		-- Apply drag
		local velocity = humanoidRootPart.Velocity
		local drag = velocity * (-physics.DragCoefficient)
		humanoidRootPart:ApplyImpulse(drag * deltaTime)
		
		-- Reduce gravity effect
		Workspace.Gravity = physics.WaterGravity
	else
		-- Normal gravity
		Workspace.Gravity = physics.Gravity
	end
end

function SharkController.UpdateAnimation(deltaTime)
	if not humanoid then return end
	
	-- Update animation based on state
	if movementState.IsMoving then
		if movementState.IsBoosting then
			humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
		else
			humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
		end
	else
		humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	end
end

-- ABILITIES
function SharkController.CanBoost()
	local currentTime = tick()
	return currentTime - movementState.LastBoostTime >= movementState.BoostCooldown
end

function SharkController.PerformLeap()
	if not humanoidRootPart or not movementState.IsUnderwater then return end
	
	-- Only leap if near surface and moving upward
	local currentY = humanoidRootPart.Position.Y
	if currentY < physics.WaterLevel - 5 then return end
	
	-- Apply leap force
	local leapForce = Vector3.new(0, GameConstants.SHARK_LEAP_FORCE, 0)
	humanoidRootPart:ApplyImpulse(leapForce)
	
	-- Visual effect
	SharkController.CreateLeapEffect()
end

function SharkController.PerformAttack()
	if not humanoidRootPart then return end
	
	-- Calculate attack direction
	local camera = Workspace.CurrentCamera
	local lookDirection = camera.CFrame.LookVector
	local attackPosition = humanoidRootPart.Position + lookDirection * GameConstants.BITE_RANGE
	
	-- Send attack to server
	SharkController.SendAttackToServer(attackPosition, "BasicAttack")
	
	-- Visual effect
	SharkController.CreateAttackEffect(attackPosition)
end

function SharkController.PerformSecondaryAction()
	-- Placeholder for secondary action (block, special ability, etc.)
	GameUtilities.DebugPrint("SharkController: Secondary action performed")
end

function SharkController.CreateLeapEffect()
	if not humanoidRootPart then return end
	
	-- Create splash effect
	local splash = Instance.new("Part")
	splash.Name = "LeapSplash"
	splash.Size = Vector3.new(5, 1, 5)
	splash.Position = humanoidRootPart.Position
	splash.BrickColor = BrickColor.new("Light blue")
	splash.Material = Enum.Material.Water
	splash.Transparency = 0.5
	splash.Anchored = true
	splash.CanCollide = false
	
	splash.Parent = Workspace
	
	-- Remove effect after delay
	task.delay(2, function()
		if splash then
			splash:Destroy()
		end
	end)
end

function SharkController.CreateAttackEffect(position)
	-- Create bite effect
	local biteEffect = Instance.new("Part")
	biteEffect.Name = "BiteEffect"
	biteEffect.Size = Vector3.new(2, 2, 2)
	biteEffect.Position = position
	biteEffect.Shape = Enum.PartType.Ball
	biteEffect.BrickColor = BrickColor.new("Bright red")
	biteEffect.Material = Enum.Material.Neon
	biteEffect.Transparency = 0.3
	biteEffect.Anchored = true
	biteEffect.CanCollide = false
	
	biteEffect.Parent = Workspace
	
	-- Animate effect
	local startSize = biteEffect.Size
	local endSize = Vector3.new(4, 4, 4)
	
	for i = 1, 10 do
		local progress = i / 10
		biteEffect.Size = startSize:Lerp(endSize, progress)
		biteEffect.Transparency = 0.3 + (progress * 0.7)
		task.wait(0.05)
	end
	
	biteEffect:Destroy()
end

-- NETWORK COMMUNICATION
function SharkController.SendMovementToServer()
	if not humanoidRootPart then return end
	
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local moveEvent = remoteFolder:FindFirstChild("PlayerMove")
	if not moveEvent then return end
	
	local position = humanoidRootPart.Position
	local direction = humanoidRootPart.CFrame.LookVector
	
	moveEvent:FireServer(position, direction)
end

function SharkController.SendAttackToServer(targetPosition, attackType)
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local attackEvent = remoteFolder:FindFirstChild("PlayerAttack")
	if not attackEvent then return end
	
	attackEvent:FireServer(targetPosition, attackType)
end

function SharkController.SendBoostToServer()
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if not remoteFolder then return end
	
	local boostEvent = remoteFolder:FindFirstChild("PlayerBoost")
	if not boostEvent then return end
	
	local direction = humanoidRootPart and humanoidRootPart.CFrame.LookVector or Vector3.forward
	boostEvent:FireServer(direction)
end

-- UTILITY FUNCTIONS
function SharkController.GetMovementState()
	return movementState
end

function SharkController.GetInputState()
	return inputState
end

function SharkController.IsUnderwater()
	return movementState.IsUnderwater
end

function SharkController.GetCurrentSpeed()
	return movementState.CurrentSpeed
end

function SharkController.SetSpeed(newSpeed)
	movementState.CurrentSpeed = newSpeed
end

-- CLEANUP
function SharkController.Cleanup()
	-- Reset physics
	Workspace.Gravity = physics.Gravity
	
	-- Clear references
	character = nil
	humanoid = nil
	humanoidRootPart = nil
	
	-- Reset state
	movementState.IsMoving = false
	movementState.IsBoosting = false
	movementState.IsUnderwater = false
	movementState.CurrentSpeed = 0
	movementState.TargetVelocity = Vector3.zero
	
	GameUtilities.DebugPrint("SharkController: Cleaned up")
end

return SharkController
