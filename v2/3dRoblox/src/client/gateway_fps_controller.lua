-- FPS Controller for Gateway-selected characters
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GatewayFPSController = {}
GatewayFPSController.__index = GatewayFPSController

local player = Players.LocalPlayer
local character
local humanoid_root_part
local humanoid
local head
local camera = workspace.CurrentCamera

local MOVE_SPEED = 24
local SPRINT_SPEED = 40
local MOUSE_SENSITIVITY = 0.002
local is_sprinting = false

-- Camera angles (radians)
local yaw = 0   -- left/right
local pitch = 0  -- up/down

function GatewayFPSController:initialize()
	print("[GatewayFPSController] Initializing...")

	-- Grab fresh character references
	character = player.Character or player.CharacterAdded:Wait()
	humanoid_root_part = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
	head = character:WaitForChild("Head")

	-- Hide head and face from local player
	head.LocalTransparencyModifier = 1
	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("Decal") then
			child.Transparency = 1
		end
	end

	-- Hide hair/hat accessories attached to the head
	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = 1
			end
		end
	end

	-- Keep head hidden every frame (Roblox resets LocalTransparencyModifier)
	RunService.RenderStepped:Connect(function()
		if head then
			head.LocalTransparencyModifier = 1
		end
	end)

	-- Switch camera to Scriptable so we fully control it
	camera.CameraType = Enum.CameraType.Scriptable

	-- Lock mouse to center of screen
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	-- Initialize yaw to match character facing direction
	local look = humanoid_root_part.CFrame.LookVector
	yaw = math.atan2(-look.X, -look.Z)

	-- Single RenderStepped for camera + movement
	RunService.RenderStepped:Connect(function(dt)
		self:update_mouse()
		self:update_camera()
		self:update_movement()
	end)

	-- Sprint input
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			is_sprinting = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			is_sprinting = false
		end
	end)

	print("[GatewayFPSController] Initialized")
end

function GatewayFPSController:update_mouse()
	local delta = UserInputService:GetMouseDelta()
	yaw   = yaw   - delta.X * MOUSE_SENSITIVITY
	pitch = math.clamp(pitch - delta.Y * MOUSE_SENSITIVITY, -math.rad(80), math.rad(80))
end

function GatewayFPSController:update_camera()
	if not head then return end
	-- Build camera CFrame: position at head, rotated by yaw then pitch
	camera.CFrame = CFrame.new(head.Position)
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(pitch, 0, 0)
end

function GatewayFPSController:update_movement()
	if not humanoid_root_part or not humanoid then return end

	-- Build flat (XZ-only) forward and right vectors from yaw
	local forward = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
	local right   = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))

	local move_dir = Vector3.new(0, 0, 0)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		move_dir = move_dir - forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		move_dir = move_dir + forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		move_dir = move_dir - right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		move_dir = move_dir + right
	end

	if move_dir.Magnitude > 0 then
		move_dir = move_dir.Unit
	end

	local speed = is_sprinting and SPRINT_SPEED or MOVE_SPEED
	humanoid:Move(move_dir * speed)

	-- Rotate character body to match yaw (horizontal only)
	humanoid_root_part.CFrame = CFrame.new(humanoid_root_part.Position)
		* CFrame.Angles(0, yaw, 0)
end

return GatewayFPSController
