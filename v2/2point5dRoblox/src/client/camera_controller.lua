local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
	local self = setmetatable({}, CameraController)

	self.player = Players.LocalPlayer
	self.character = nil
	self.hrp = nil
	self.height = 40
	self.distance = 30
	self.angle = math.rad(45)
	self.rotationX = 0
	self.rotationY = 0
	self.smoothSpeed = 6
	self.currentPosition = nil
	self.isRotating = false
	self.lastMousePos = nil
	self.zoomMin = 15
	self.zoomMax = 80

	self.camera = workspace.CurrentCamera
	if not self.camera then
		self.camera = Instance.new("Camera")
		self.camera.Parent = workspace
		workspace.CurrentCamera = self.camera
	end
	self.camera.CameraType = Enum.CameraType.Scriptable
	self.camera.CameraSubject = nil
	
	self:setupInputs()

	return self
end

function CameraController:setCharacter(character)
	self.character = character
	self.hrp = character:FindFirstChild("HumanoidRootPart")
	self.currentPosition = nil
end

function CameraController:setupInputs()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.isRotating = true
			self.lastMousePos = UserInputService:GetMouseLocation()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.isRotating = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			if input.Position.Z > 0 then
				self.distance = math.max(self.zoomMin, self.distance - 5)
			else
				self.distance = math.min(self.zoomMax, self.distance + 5)
			end
		end
	end)
end

function CameraController:update(dt)
	if workspace.CurrentCamera ~= self.camera then
		self.camera = workspace.CurrentCamera
	end
	if not self.camera then return end
	
	if not self.character or not self.hrp then
		self.character = self.player.Character
		if not self.character then return end
		self.hrp = self.character:FindFirstChild("HumanoidRootPart")
		if not self.hrp then return end
	end

	if self.isRotating then
		local currentMousePos = UserInputService:GetMouseLocation()
		local delta = currentMousePos - self.lastMousePos
		self.rotationY = self.rotationY + delta.X * 0.005
		self.rotationX = self.rotationX - delta.Y * 0.005
		self.rotationX = math.max(-math.rad(80), math.min(math.rad(30), self.rotationX))
		self.lastMousePos = currentMousePos
	end

	local targetPos = self.hrp.Position

	if not self.currentPosition then
		self.currentPosition = targetPos
	else
		self.currentPosition = self.currentPosition:Lerp(targetPos, math.min(1, self.smoothSpeed * dt))
	end

	-- Zoom-dependent behavior
	local zoomProgress = (self.distance - self.zoomMin) / (self.zoomMax - self.zoomMin)
	-- Drop height as we zoom in, and flatten the rotationX influence
	local effectiveHeight = 2 + (self.height - 2) * math.sqrt(zoomProgress)
	local effectiveRotationX = self.rotationX * math.clamp(zoomProgress * 1.5, 0, 1)

	local offsetX = math.sin(self.rotationY) * math.cos(effectiveRotationX) * self.distance
	local offsetY = math.sin(effectiveRotationX) * self.distance + effectiveHeight
	local offsetZ = math.cos(self.rotationY) * math.cos(effectiveRotationX) * self.distance

	local cameraPos = self.currentPosition + Vector3.new(offsetX, offsetY, offsetZ)

	-- Raycast to prevent camera clipping through terrain
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {self.character}
	local rayResult = workspace:Raycast(self.currentPosition + Vector3.new(0, 2, 0), cameraPos - (self.currentPosition + Vector3.new(0, 2, 0)), rayParams)
	if rayResult then
		cameraPos = rayResult.Position + rayResult.Normal * 0.5
	end

	self.camera.CameraType = Enum.CameraType.Scriptable
	self.camera.CFrame = CFrame.new(cameraPos, self.currentPosition + Vector3.new(0, 2 + (1-zoomProgress), 0))
end

return CameraController
