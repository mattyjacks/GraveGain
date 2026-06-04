-- BattleSharks Client Optimization Manager (F4, F5)
-- Client-side frustum culling and prediction

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local ClientOptimizationManager = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local frustumCulledObjects = {}
local predictionData = {}

-- CONFIGURATION
local OPTIMIZATION_CONFIG = {
	FrustumCheckInterval = 0.1,
	PredictionSmoothing = 0.3,
	MaxPredictionDistance = 100,
	LOD0Distance = 200,
	LOD1Distance = 500,
	LOD2Distance = 1000
}

-- INITIALIZATION
function ClientOptimizationManager.Initialize()
	GameUtilities.DebugPrint("ClientOptimizationManager: Initializing")
	
	-- Start frustum culling
	ClientOptimizationManager.StartFrustumCulling()
	
	-- Start prediction system
	ClientOptimizationManager.StartPredictionSystem()
	
	GameUtilities.DebugPrint("ClientOptimizationManager: Initialized")
end

-- FRUSTUM CULLING (F4)
function ClientOptimizationManager.StartFrustumCulling()
	task.spawn(function()
		while true do
			task.wait(OPTIMIZATION_CONFIG.FrustumCheckInterval)
			ClientOptimizationManager.UpdateFrustumCulling()
		end
	end)
end

function ClientOptimizationManager.UpdateFrustumCulling()
	local cameraCFrame = camera.CFrame
	local cameraPosition = cameraCFrame.Position
	local cameraLook = cameraCFrame.LookVector
	local fov = math.rad(camera.FieldOfView)
	
	-- Check all visual objects
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name:find("Visual") or obj.Name:find("Enemy") or obj.Name:find("Effect") then
			local pos = obj.Position
			local dist = (pos - cameraPosition).Magnitude
			
			-- Distance culling first
			if dist > OPTIMIZATION_CONFIG.LOD2Distance then
				obj.Transparency = 1
				continue
			end
			
			-- Frustum check
			local toObject = (pos - cameraPosition).Unit
			local angle = math.acos(math.clamp(cameraLook:Dot(toObject), -1, 1))
			
			if angle > fov * 0.6 then -- Outside frustum
				obj.Transparency = 1
				frustumCulledObjects[obj] = true
			else
				-- In frustum - apply LOD based on distance
				if dist < OPTIMIZATION_CONFIG.LOD0Distance then
					obj.Transparency = 0
				elseif dist < OPTIMIZATION_CONFIG.LOD1Distance then
					obj.Transparency = 0.3
				else
					obj.Transparency = 0.6
				end
				frustumCulledObjects[obj] = nil
			end
		end
	end
end

-- CLIENT-SIDE PREDICTION (F5)
function ClientOptimizationManager.StartPredictionSystem()
	-- Store position history for other players
	local remoteFolder = ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	
	local playerMoveEvent = remoteFolder:FindFirstChild("PlayerMove")
	if playerMoveEvent then
		playerMoveEvent.OnClientEvent:Connect(function(data)
			ClientOptimizationManager.OnRemotePlayerMove(data)
		end)
	end
	
	-- Interpolation loop
	RunService.Heartbeat:Connect(function(deltaTime)
		ClientOptimizationManager.InterpolateRemotePlayers(deltaTime)
	end)
end

function ClientOptimizationManager.OnRemotePlayerMove(data)
	local targetPlayer = Players:GetPlayerByUserId(data.PlayerId)
	if not targetPlayer or targetPlayer == player then return end
	
	if not predictionData[data.PlayerId] then
		predictionData[data.PlayerId] = {
			lastPosition = data.Position,
			lastDirection = data.Direction,
			lastUpdate = tick(),
			targetPosition = data.Position,
			velocity = Vector3.zero
		}
	else
		local pred = predictionData[data.PlayerId]
		local now = tick()
		local dt = now - pred.lastUpdate
		
		if dt > 0 then
			-- Calculate velocity from position change
			pred.velocity = (data.Position - pred.lastPosition) / dt
		end
		
		pred.lastPosition = data.Position
		pred.lastDirection = data.Direction
		pred.lastUpdate = now
		pred.targetPosition = data.Position
	end
end

function ClientOptimizationManager.InterpolateRemotePlayers(deltaTime)
	for userId, pred in pairs(predictionData) do
		local targetPlayer = Players:GetPlayerByUserId(userId)
		if not targetPlayer or not targetPlayer.Character then continue end
		
		local character = targetPlayer.Character
		local primaryPart = character.PrimaryPart
		if not primaryPart then continue end
		
		local now = tick()
		local timeSinceUpdate = now - pred.lastUpdate
		
		-- Predict position
		local predictedPosition = pred.targetPosition + (pred.velocity * timeSinceUpdate)
		
		-- Smooth interpolation
		local currentPosition = primaryPart.Position
		local lerpAlpha = math.clamp(deltaTime / OPTIMIZATION_CONFIG.PredictionSmoothing, 0, 1)
		
		-- Check prediction error
		local predictionError = (predictedPosition - currentPosition).Magnitude
		
		if predictionError > OPTIMIZATION_CONFIG.MaxPredictionDistance then
			-- Snap to predicted if too far
			primaryPart.CFrame = CFrame.new(predictedPosition)
		else
			-- Smooth interpolate
			primaryPart.CFrame = CFrame.new(currentPosition:Lerp(predictedPosition, lerpAlpha))
		end
	end
end

-- LOD FOR CLIENT OBJECTS
function ClientOptimizationManager.SetObjectLOD(object, distance)
	if distance < OPTIMIZATION_CONFIG.LOD0Distance then
		-- Full detail
		if object:IsA("Model") then
			for _, part in pairs(object:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
				end
			end
		end
	elseif distance < OPTIMIZATION_CONFIG.LOD1Distance then
		-- Medium detail
		if object:IsA("Model") then
			for _, part in pairs(object:GetDescendants()) do
				if part:IsA("BasePart") and not part.Name:find("Important") then
					part.Transparency = 0.5
				end
			end
		end
	else
		-- Low detail / culled
		if object:IsA("Model") then
			for _, part in pairs(object:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0.9
				end
			end
		end
	end
end

-- CLEANUP
function ClientOptimizationManager.Cleanup()
	predictionData = {}
	frustumCulledObjects = {}
end

return ClientOptimizationManager
