-- BattleSharks Camera Controller
-- Handles camera behavior for underwater and surface gameplay

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Temporary: Use placeholder values until shared modules are working
local GameConstants = {
	WATER_LEVEL = 0
}
local GameUtilities = {
	DebugPrint = function(message) print("[DEBUG]", message) end,
	Clamp = function(value, min, max) return math.max(min, math.min(max, value)) end,
	Lerp = function(a, b, t) return a + (b - a) * t end,
	RandomFloat = function(min, max) return math.random() * (max - min) + min end
}

local CameraController = {}

-- PRIVATE VARIABLES
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local character = nil
local humanoidRootPart = nil

-- Camera settings
local cameraConfig = {
	DefaultDistance = 15,
	MinDistance = 5,
	MaxDistance = 50,
	HeightOffset = 2,
	AngleX = 15, -- Tilt angle
	AngleY = 0,  -- Rotation angle
	SmoothSpeed = 8,
	ZoomSpeed = 2,
	RotationSpeed = 0.5,
	UnderwaterFog = {Start = 10, End = 50, Color = Color3.new(0, 0.2, 0.4)},
	SurfaceFog = {Start = 100, End = 500, Color = Color3.new(0.8, 0.9, 1)}
}

-- Camera state
local cameraState = {
	CurrentDistance = cameraConfig.DefaultDistance,
	TargetDistance = cameraConfig.DefaultDistance,
	CurrentAngleX = cameraConfig.AngleX,
	TargetAngleX = cameraConfig.AngleX,
	CurrentAngleY = cameraConfig.AngleY,
	TargetAngleY = cameraConfig.AngleY,
	IsUnderwater = false,
	IsDragging = false,
	LastMousePosition = Vector2.zero,
	CameraShake = Vector3.zero,
	ShakeDecay = 0.9
}

-- INITIALIZATION
function CameraController.Initialize()
	GameUtilities.DebugPrint("CameraController: Initializing")
	
	-- Set up character events
	player.CharacterAdded:Connect(CameraController.OnCharacterAdded)
	player.CharacterRemoving:Connect(CameraController.OnCharacterRemoving)
	
	-- Set up input events
	UserInputService.InputBegan:Connect(CameraController.OnInputBegan)
	UserInputService.InputEnded:Connect(CameraController.OnInputEnded)
	UserInputService.InputChanged:Connect(CameraController.OnInputChanged)
	
	-- Initialize camera
	CameraController.SetupCamera()
	
	-- Start update loop
	CameraController.StartUpdateLoop()
	
	-- Initialize character if already loaded
	if player.Character then
		CameraController.OnCharacterAdded(player.Character)
	end
	
	GameUtilities.DebugPrint("CameraController: Initialized")
end

function CameraController.SetupCamera()
	-- Configure camera properties
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 70
	camera.HeadScale = 1
	
	-- Set initial position
	CameraController.UpdateCameraPosition()
end

-- CHARACTER EVENTS
function CameraController.OnCharacterAdded(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	GameUtilities.DebugPrint("CameraController: Character loaded")
end

function CameraController.OnCharacterRemoving(oldCharacter)
	character = nil
	humanoidRootPart = nil
	
	GameUtilities.DebugPrint("CameraController: Character removed")
end

-- INPUT HANDLING
function CameraController.OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	
	local inputType = input.UserInputType
	local keyCode = input.KeyCode
	
	-- Mouse wheel for zoom
	if inputType == Enum.UserInputType.MouseWheel then
		local scrollDelta = input.Position.Z
		CameraController.HandleZoom(scrollDelta)
	end
	
	-- Middle mouse for rotation
	if inputType == Enum.UserInputType.MouseButton2 then
		cameraState.IsDragging = true
		cameraState.LastMousePosition = input.Position
		UserInputService.MouseIconEnabled = false
	end
	
	-- Keyboard controls
	if keyCode == Enum.KeyCode.PageUp then
		CameraController.HandleZoom(1)
	elseif keyCode == Enum.KeyCode.PageDown then
		CameraController.HandleZoom(-1)
	end
end

function CameraController.OnInputEnded(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		cameraState.IsDragging = false
		UserInputService.MouseIconEnabled = true
	end
end

function CameraController.OnInputChanged(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseMovement and cameraState.IsDragging then
		local mouseDelta = input.Position - cameraState.LastMousePosition
		CameraController.HandleRotation(mouseDelta)
		cameraState.LastMousePosition = input.Position
	end
end

-- CAMERA CONTROLS
function CameraController.HandleZoom(scrollDelta)
	local zoomAmount = scrollDelta * cameraConfig.ZoomSpeed
	cameraState.TargetDistance = GameUtilities.Clamp(
		cameraState.TargetDistance - zoomAmount,
		cameraConfig.MinDistance,
		cameraConfig.MaxDistance
	)
end

function CameraController.HandleRotation(mouseDelta)
	-- Horizontal rotation (Y axis)
	cameraState.TargetAngleY += mouseDelta.X * cameraConfig.RotationSpeed
	
	-- Vertical rotation (X axis) with clamping
	cameraState.TargetAngleX -= mouseDelta.Y * cameraConfig.RotationSpeed
	cameraState.TargetAngleX = GameUtilities.Clamp(
		cameraState.TargetAngleX,
		-60, -- Minimum tilt
		80   -- Maximum tilt
	)
end

-- CAMERA UPDATES
function CameraController.StartUpdateLoop()
	RunService.Heartbeat:Connect(function(deltaTime)
		CameraController.UpdateCamera(deltaTime)
		CameraController.UpdateEnvironment()
	end)
end

function CameraController.UpdateCamera(deltaTime)
	if not humanoidRootPart then return end
	
	-- Smooth distance transition
	cameraState.CurrentDistance = GameUtilities.Lerp(
		cameraState.CurrentDistance,
		cameraState.TargetDistance,
		cameraConfig.SmoothSpeed * deltaTime
	)
	
	-- Smooth angle transitions
	cameraState.CurrentAngleX = GameUtilities.Lerp(
		cameraState.CurrentAngleX,
		cameraState.TargetAngleX,
		cameraConfig.SmoothSpeed * deltaTime
	)
	
	cameraState.CurrentAngleY = GameUtilities.Lerp(
		cameraState.CurrentAngleY,
		cameraState.TargetAngleY,
		cameraConfig.SmoothSpeed * deltaTime
	)
	
	-- Update camera position
	CameraController.UpdateCameraPosition()
	
	-- Update camera shake
	CameraController.UpdateCameraShake()
end

function CameraController.UpdateCameraPosition()
	if not humanoidRootPart then return end
	
	local characterPosition = humanoidRootPart.Position
	
	-- Calculate camera offset based on angles and distance
	local angleXRad = math.rad(cameraState.CurrentAngleX)
	local angleYRad = math.rad(cameraState.CurrentAngleY)
	
	local offsetX = math.sin(angleYRad) * math.cos(angleXRad) * cameraState.CurrentDistance
	local offsetY = math.sin(angleXRad) * cameraState.CurrentDistance + cameraConfig.HeightOffset
	local offsetZ = math.cos(angleYRad) * math.cos(angleXRad) * cameraState.CurrentDistance
	
	local cameraPosition = characterPosition + Vector3.new(offsetX, offsetY, offsetZ)
	
	-- Apply camera shake
	cameraPosition += cameraState.CameraShake
	
	-- Update camera CFrame
	camera.CFrame = CFrame.new(cameraPosition, characterPosition + Vector3.new(0, cameraConfig.HeightOffset, 0))
end

function CameraController.UpdateCameraShake()
	-- Apply shake decay
	cameraState.CameraShake *= cameraState.ShakeDecay
	
	-- Stop shake when very small
	if cameraState.CameraShake.Magnitude < 0.01 then
		cameraState.CameraShake = Vector3.zero
	end
end

function CameraController.UpdateEnvironment()
	if not humanoidRootPart then return end
	
	local currentY = humanoidRootPart.Position.Y
	local wasUnderwater = cameraState.IsUnderwater
	cameraState.IsUnderwater = currentY <= GameConstants.WATER_LEVEL
	
	-- Update environment when crossing water surface
	if wasUnderwater ~= cameraState.IsUnderwater then
		CameraController.UpdateEnvironmentEffects()
	end
end

function CameraController.UpdateEnvironmentEffects()
	local Lighting = game:GetService("Lighting")
	
	if cameraState.IsUnderwater then
		-- Underwater effects
		Lighting.FogColor = cameraConfig.UnderwaterFog.Color
		Lighting.FogStart = cameraConfig.UnderwaterFog.Start
		Lighting.FogEnd = cameraConfig.UnderwaterFog.End
		
		-- Underwater lighting
		Lighting.Ambient = Color3.new(0, 0.1, 0.2)
		Lighting.Brightness = 0.8
		
		-- Underwater color correction
		camera.ColorCorrection = ColorCorrectionEffect.new()
		camera.ColorCorrection.TintColor = Color3.new(0.8, 0.9, 1)
		camera.ColorCorrection.Contrast = 0.1
		camera.ColorCorrection.Saturation = 0.8
		
		-- Underwater blur
		camera.Blur = BlurEffect.new()
		camera.Blur.Size = 2
		
	else
		-- Surface effects
		Lighting.FogColor = cameraConfig.SurfaceFog.Color
		Lighting.FogStart = cameraConfig.SurfaceFog.Start
		Lighting.FogEnd = cameraConfig.SurfaceFog.End
		
		-- Surface lighting
		Lighting.Ambient = Color3.new(0.2, 0.2, 0.2)
		Lighting.Brightness = 1.5
		
		-- Remove underwater effects
		if camera:FindFirstChild("ColorCorrection") then
			camera.ColorCorrection:Destroy()
		end
		if camera:FindFirstChild("Blur") then
			camera.Blur:Destroy()
		end
	end
end

-- CAMERA EFFECTS
function CameraController.AddCameraShake(intensity, duration)
	intensity = intensity or 5
	duration = duration or 0.5
	
	local shakeVector = Vector3.new(
		GameUtilities.RandomFloat(-intensity, intensity),
		GameUtilities.RandomFloat(-intensity, intensity),
		GameUtilities.RandomFloat(-intensity, intensity)
	)
	
	cameraState.CameraShake += shakeVector
	
	-- Auto-decay after duration
	task.delay(duration, function()
		cameraState.ShakeDecay = 0.9 -- Reset decay rate
	end)
end

function CameraController.SetCameraTarget(targetPosition, smoothTime)
	if not targetPosition then return end
	
	smoothTime = smoothTime or 1
	
	-- Create tween to target position
	local goalPosition = targetPosition + Vector3.new(0, cameraConfig.HeightOffset, 0)
	local goalCFrame = CFrame.new(
		goalPosition + Vector3.new(0, 0, cameraState.CurrentDistance),
		goalPosition
	)
	
	local tweenInfo = TweenInfo.new(smoothTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = goalCFrame})
	
	tween:Play()
end

function CameraController.ResetCamera()
	cameraState.TargetDistance = cameraConfig.DefaultDistance
	cameraState.TargetAngleX = cameraConfig.AngleX
	cameraState.TargetAngleY = cameraConfig.AngleY
end

-- UTILITY FUNCTIONS
function CameraController.GetCameraState()
	return cameraState
end

function CameraController.IsUnderwater()
	return cameraState.IsUnderwater
end

function CameraController.GetDistance()
	return cameraState.CurrentDistance
end

function CameraController.SetDistance(distance)
	cameraState.TargetDistance = GameUtilities.Clamp(distance, cameraConfig.MinDistance, cameraConfig.MaxDistance)
end

function CameraController.GetAngles()
	return cameraState.CurrentAngleX, cameraState.CurrentAngleY
end

function CameraController.SetAngles(angleX, angleY)
	cameraState.TargetAngleX = GameUtilities.Clamp(angleX, -60, 80)
	cameraState.TargetAngleY = angleY
end

function CameraController.GetCameraDirection()
	if not humanoidRootPart then return Vector3.forward end
	
	local cameraDirection = (camera.CFrame.Position - humanoidRootPart.Position).Unit
	return cameraDirection
end

function CameraController.WorldToScreenPoint(worldPosition)
	return camera:WorldToScreenPoint(worldPosition)
end

function CameraController.ScreenToWorldPoint(screenPosition)
	return camera:ScreenToWorldPoint(screenPosition)
end

-- CLEANUP
function CameraController.Cleanup()
	-- Reset camera to default
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	
	-- Remove effects
	if camera:FindFirstChild("ColorCorrection") then
		camera.ColorCorrection:Destroy()
	end
	if camera:FindFirstChild("Blur") then
		camera.Blur:Destroy()
	end
	
	-- Reset lighting
	local Lighting = game:GetService("Lighting")
	Lighting.FogColor = cameraConfig.SurfaceFog.Color
	Lighting.FogStart = cameraConfig.SurfaceFog.Start
	Lighting.FogEnd = cameraConfig.SurfaceFog.End
	Lighting.Ambient = Color3.new(0.2, 0.2, 0.2)
	Lighting.Brightness = 1.5
	
	-- Clear references
	character = nil
	humanoidRootPart = nil
	
	-- Reset state
	cameraState.CurrentDistance = cameraConfig.DefaultDistance
	cameraState.TargetDistance = cameraConfig.DefaultDistance
	cameraState.CurrentAngleX = cameraConfig.AngleX
	cameraState.TargetAngleX = cameraConfig.AngleX
	cameraState.CurrentAngleY = cameraConfig.AngleY
	cameraState.TargetAngleY = cameraConfig.AngleY
	cameraState.IsUnderwater = false
	cameraState.IsDragging = false
	cameraState.CameraShake = Vector3.zero
	
	GameUtilities.DebugPrint("CameraController: Cleaned up")
end

return CameraController
