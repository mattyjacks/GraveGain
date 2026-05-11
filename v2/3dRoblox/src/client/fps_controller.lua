-- FPS Controller - Handles first-person camera, movement, and input
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local FPSController = {}
FPSController.__index = FPSController

local player = Players.LocalPlayer
local mouse = player:GetMouse()

function FPSController.new(character, player_data)
	local self = setmetatable({}, FPSController)
	
	self.character = character
	self.player_data = player_data
	self.humanoid = character:WaitForChild("Humanoid")
	self.root_part = character:WaitForChild("HumanoidRootPart")
	
	-- Camera setup
	self.camera = workspace.CurrentCamera
	self.camera.CFrame = self.root_part.CFrame + self.root_part.CFrame.LookVector * 0.6
	self.camera.Parent = self.root_part
	
	-- Movement
	self.move_direction = Vector3.new(0, 0, 0)
	self.velocity = Vector3.new(0, 0, 0)
	self.is_sprinting = false
	self.sprint_mult = 1.5
	self.acceleration = 50
	self.friction = 0.15
	
	-- Camera control
	self.camera_offset = Vector3.new(0, 0.6, 0)
	self.mouse_sensitivity = 0.003
	self.pitch = 0
	self.yaw = 0
	self.max_pitch = math.rad(90)
	self.min_pitch = math.rad(-90)
	
	-- Jumping
	self.can_jump = true
	self.jump_power = 50
	self.is_jumping = false
	
	-- Stamina
	self.stamina_drain_sprint = 20
	self.stamina_regen = 15
	
	-- Weapon
	self.current_weapon = nil
	self.is_aiming = false
	self.aim_fov = 40
	self.normal_fov = 70
	
	self:setup_character()
	self:setup_input()
	self:setup_rendering()
	
	return self
end

function FPSController:setup_character()
	-- Remove default camera behavior
	self.humanoid.CameraOffset = self.camera_offset
	
	-- Create humanoid root part if needed
	if not self.root_part then
		error("Character missing HumanoidRootPart")
	end
end

function FPSController:setup_input()
	-- Mouse movement for camera
	mouse.Move:Connect(function()
		self:update_camera_from_mouse()
	end)
	
	-- Keyboard input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:handle_input_began(input)
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		self:handle_input_ended(input)
	end)
end

function FPSController:setup_rendering()
	RunService.RenderStepped:Connect(function()
		self:update_movement()
		self:update_camera()
		self:update_stamina()
	end)
end

function FPSController:handle_input_began(input)
	local key = input.KeyCode
	
	-- Movement
	if key == Enum.KeyCode.W then
		self.move_direction = self.move_direction + Vector3.new(0, 0, -1)
	elseif key == Enum.KeyCode.S then
		self.move_direction = self.move_direction + Vector3.new(0, 0, 1)
	elseif key == Enum.KeyCode.A then
		self.move_direction = self.move_direction + Vector3.new(-1, 0, 0)
	elseif key == Enum.KeyCode.D then
		self.move_direction = self.move_direction + Vector3.new(1, 0, 0)
	end
	
	-- Sprint
	if key == Enum.KeyCode.LeftShift then
		self.is_sprinting = true
	end
	
	-- Jump
	if key == Enum.KeyCode.Space and self.can_jump then
		self:jump()
	end
	
	-- Aim
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		self.is_aiming = true
	end
	
	-- Fire weapon
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if self.current_weapon then
			self.current_weapon:fire()
		end
	end
end

function FPSController:handle_input_ended(input)
	local key = input.KeyCode
	
	-- Movement
	if key == Enum.KeyCode.W then
		self.move_direction = self.move_direction - Vector3.new(0, 0, -1)
	elseif key == Enum.KeyCode.S then
		self.move_direction = self.move_direction - Vector3.new(0, 0, 1)
	elseif key == Enum.KeyCode.A then
		self.move_direction = self.move_direction - Vector3.new(-1, 0, 0)
	elseif key == Enum.KeyCode.D then
		self.move_direction = self.move_direction - Vector3.new(1, 0, 0)
	end
	
	-- Sprint
	if key == Enum.KeyCode.LeftShift then
		self.is_sprinting = false
	end
	
	-- Aim
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		self.is_aiming = false
	end
end

function FPSController:update_camera_from_mouse()
	local delta = mouse.Hit.Position - mouse.UnitRay.Origin
	
	self.yaw = self.yaw + delta.X * self.mouse_sensitivity
	self.pitch = self.pitch - delta.Y * self.mouse_sensitivity
	
	self.pitch = math.clamp(self.pitch, self.min_pitch, self.max_pitch)
end

function FPSController:update_camera()
	-- Calculate camera rotation
	local camera_rotation = CFrame.Angles(self.pitch, self.yaw, 0)
	
	-- Position camera at root part + offset
	local camera_pos = self.root_part.Position + self.camera_offset
	self.camera.CFrame = CFrame.new(camera_pos) * camera_rotation
	
	-- Update FOV based on aiming
	local target_fov = self.is_aiming and self.aim_fov or self.normal_fov
	self.camera.FieldOfView = self.camera.FieldOfView + (target_fov - self.camera.FieldOfView) * 0.1
end

function FPSController:update_movement()
	-- Normalize movement direction
	local move_dir = self.move_direction
	if move_dir.Magnitude > 0 then
		move_dir = move_dir.Unit
	end
	
	-- Calculate speed
	local base_speed = self.player_data.run_speed
	local speed_mult = self.is_sprinting and self.sprint_mult or 1.0
	local target_speed = base_speed * speed_mult
	
	-- Apply acceleration
	local camera_forward = (self.camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
	local camera_right = self.camera.CFrame.RightVector
	
	local desired_velocity = (camera_forward * move_dir.Z + camera_right * move_dir.X) * target_speed
	desired_velocity = desired_velocity + Vector3.new(0, self.velocity.Y, 0)
	
	-- Smooth velocity
	self.velocity = self.velocity:Lerp(desired_velocity, self.acceleration * 0.016)
	
	-- Apply gravity
	self.velocity = self.velocity + Vector3.new(0, -9.81 * 0.016, 0)
	
	-- Move character
	self.humanoid:MoveTo(self.root_part.Position + self.velocity * 0.016)
end

function FPSController:update_stamina()
	if not self.player_data.stamina then return end
	
	local stamina_delta = 0
	
	if self.is_sprinting and self.move_direction.Magnitude > 0 then
		stamina_delta = -self.stamina_drain_sprint
	else
		stamina_delta = self.stamina_regen
	end
	
	self.player_data.stamina = math.clamp(
		self.player_data.stamina + stamina_delta * 0.016,
		0,
		self.player_data.max_stamina
	)
	
	-- Stop sprinting if out of stamina
	if self.player_data.stamina <= 0 then
		self.is_sprinting = false
	end
end

function FPSController:jump()
	if not self.can_jump then return end
	
	self.velocity = self.velocity + Vector3.new(0, self.jump_power, 0)
	self.can_jump = false
	self.is_jumping = true
	
	task.wait(0.1)
	
	-- Check if grounded
	local ray_origin = self.root_part.Position
	local ray_direction = Vector3.new(0, -5, 0)
	local ray_result = workspace:FindPartOnRay(Ray.new(ray_origin, ray_direction))
	
	if ray_result and ray_result.Parent ~= self.character then
		self.can_jump = true
		self.is_jumping = false
	end
end

function FPSController:equip_weapon(weapon)
	self.current_weapon = weapon
	if weapon then
		weapon:equip(self.camera)
	end
end

function FPSController:cleanup()
	-- Disconnect all events
	if self.render_connection then
		self.render_connection:Disconnect()
	end
end

return FPSController
