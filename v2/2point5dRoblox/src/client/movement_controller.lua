local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

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

	self.isDodging = false
	self.dodgeCooldown = 0
	
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Space then
			if self.isSprinting and self.moveDirection.Magnitude > 0 and self.dodgeCooldown <= 0 and not self.isDodging then
				self:performDodgeRoll()
			elseif self.humanoid then
				self.humanoid.Jump = true
			end
		end
	end)

	return self
end

function MovementController:performDodgeRoll()
	if not self.hrp then return end
	self.isDodging = true
	self.dodgeCooldown = 1.0
	
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000, 0, 100000)
	bv.Velocity = self.moveDirection * 80
	bv.Parent = self.hrp
	
	game:GetService("Debris"):AddItem(bv, 0.25)
	
	task.delay(0.25, function()
		self.isDodging = false
	end)
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

	if self.dodgeCooldown > 0 then
		self.dodgeCooldown = self.dodgeCooldown - dt
	end

	self.isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)

	local camera = workspace.CurrentCamera
	local cameraLook = camera.CFrame.LookVector
	local cameraRight = camera.CFrame.RightVector
	cameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
	cameraRight = Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit

	local moveInput = Vector3.new(0, 0, 0)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveInput = moveInput + cameraLook
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveInput = moveInput - cameraLook
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveInput = moveInput - cameraRight
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveInput = moveInput + cameraRight
	end

	if moveInput.Magnitude > 0 then
		moveInput = moveInput.Unit
		self.moveDirection = moveInput
		self.lastMoveDir = moveInput

		local speed = self.isSprinting and self.sprintSpeed or self.moveSpeed
		if self.isDodging then speed = 0 end -- disable normal movement while rolling
		self.humanoid:Move(moveInput, false)
		self.humanoid.WalkSpeed = speed
	else
		self.humanoid:Move(Vector3.new(0, 0, 0), false)
		self.moveDirection = Vector3.new(0, 0, 0)
	end
	
	-- Free-Aim: Character always faces the mouse
	local player = Players.LocalPlayer
	local mouse = player:GetMouse()
	if mouse.Hit then
		local hrpPos = self.hrp.Position
		local mousePos = mouse.Hit.Position
		local lookDir = Vector3.new(mousePos.X - hrpPos.X, 0, mousePos.Z - hrpPos.Z)
		if lookDir.Magnitude > 0.1 then
			self.hrp.CFrame = CFrame.lookAt(hrpPos, hrpPos + lookDir.Unit)
		end
	end
end

return MovementController
