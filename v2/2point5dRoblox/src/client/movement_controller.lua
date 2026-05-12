local UserInputService = game:GetService("UserInputService")

local MovementController = {}
MovementController.__index = MovementController

function MovementController.new()
	local self = setmetatable({}, MovementController)

	self.moveSpeed = 20
	self.sprintSpeed = 32
	self.isSprinting = false
	self.moveDirection = Vector3.new(0, 0, 0)
	self.lastMoveDir = Vector3.new(0, 0, -1)
	self.humanoid = nil
	self.hrp = nil
	self.character = nil

	return self
end

function MovementController:update(dt)
	if not self.character or not self.humanoid or not self.hrp then
		local player = game:GetService("Players").LocalPlayer
		self.character = player.Character
		if not self.character then return end
		self.humanoid = self.character:FindFirstChild("Humanoid")
		self.hrp = self.character:FindFirstChild("HumanoidRootPart")
		if not self.humanoid or not self.hrp then return end
	end

	self.isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)

	local moveInput = Vector3.new(0, 0, 0)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveInput = moveInput + Vector3.new(0, 0, -1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveInput = moveInput + Vector3.new(0, 0, 1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveInput = moveInput + Vector3.new(-1, 0, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveInput = moveInput + Vector3.new(1, 0, 0)
	end

	if moveInput.Magnitude > 0 then
		moveInput = moveInput.Unit
		self.moveDirection = moveInput
		self.lastMoveDir = moveInput

		local speed = self.isSprinting and self.sprintSpeed or self.moveSpeed
		self.humanoid:Move(moveInput, false)
		self.humanoid.WalkSpeed = speed

		local angle = math.atan2(moveInput.X, -moveInput.Z)
		self.hrp.CFrame = CFrame.new(self.hrp.Position) * CFrame.Angles(0, angle, 0)
	else
		self.humanoid:Move(Vector3.new(0, 0, 0), false)
		self.moveDirection = Vector3.new(0, 0, 0)
	end
end

return MovementController
