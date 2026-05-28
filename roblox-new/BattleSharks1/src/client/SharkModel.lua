-- BattleSharks Shark Model System
-- Creates realistic shark model with animations

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local SharkModel = {}

-- Shark configuration
SharkModel.CONFIG = {
	SIZE = Vector3.new(8, 3, 20),
	SPEED = 25,
	TURN_SPEED = 2,
	ANIMATION_SPEED = 1,
	MATERIAL = Enum.Material.SmoothPlastic,
	COLOR = Color3.new(0.7, 0.7, 0.8)
}

-- Create main shark model - all parts welded to body
function SharkModel.CreateSharkModel()
	local model = Instance.new("Model")
	model.Name = "SharkModel"
	
	-- Body is the root part
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4, 2, 10)
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.new(0.55, 0.55, 0.65)
	body.CanCollide = false
	body.Anchored = false
	body.CastShadow = false
	body.Parent = model
	model.PrimaryPart = body
	
	-- Head / snout
	local head = Instance.new("WedgePart")
	head.Name = "Head"
	head.Size = Vector3.new(2.5, 1.8, 4)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.new(0.55, 0.55, 0.65)
	head.CanCollide = false
	head.CastShadow = false
	SharkModel.WeldOffset(body, head, CFrame.new(0, -0.1, -6.5))
	head.Parent = model
	
	-- Belly (lighter color)
	local belly = Instance.new("Part")
	belly.Name = "Belly"
	belly.Size = Vector3.new(3.5, 1.5, 8)
	belly.Material = Enum.Material.SmoothPlastic
	belly.Color = Color3.new(0.9, 0.9, 0.92)
	belly.CanCollide = false
	belly.CastShadow = false
	SharkModel.WeldOffset(body, belly, CFrame.new(0, -0.6, 0))
	belly.Parent = model
	
	-- Dorsal fin
	local dorsalFin = Instance.new("WedgePart")
	dorsalFin.Name = "DorsalFin"
	dorsalFin.Size = Vector3.new(0.4, 2.5, 2.5)
	dorsalFin.Material = Enum.Material.SmoothPlastic
	dorsalFin.Color = Color3.new(0.45, 0.45, 0.55)
	dorsalFin.CanCollide = false
	dorsalFin.CastShadow = false
	SharkModel.WeldOffset(body, dorsalFin, CFrame.new(0, 1.8, -1))
	dorsalFin.Parent = model
	
	-- Left pectoral fin
	local leftFin = Instance.new("WedgePart")
	leftFin.Name = "LeftFin"
	leftFin.Size = Vector3.new(3, 0.4, 1.8)
	leftFin.Material = Enum.Material.SmoothPlastic
	leftFin.Color = Color3.new(0.45, 0.45, 0.55)
	leftFin.CanCollide = false
	leftFin.CastShadow = false
	SharkModel.WeldOffset(body, leftFin, CFrame.new(-2.5, -0.3, -1) * CFrame.Angles(0, 0, math.rad(-20)))
	leftFin.Parent = model
	
	-- Right pectoral fin
	local rightFin = Instance.new("WedgePart")
	rightFin.Name = "RightFin"
	rightFin.Size = Vector3.new(3, 0.4, 1.8)
	rightFin.Material = Enum.Material.SmoothPlastic
	rightFin.Color = Color3.new(0.45, 0.45, 0.55)
	rightFin.CanCollide = false
	rightFin.CastShadow = false
	SharkModel.WeldOffset(body, rightFin, CFrame.new(2.5, -0.3, -1) * CFrame.Angles(0, 0, math.rad(20)))
	rightFin.Parent = model
	
	-- Tail fin (vertical)
	local tailV = Instance.new("WedgePart")
	tailV.Name = "TailFinV"
	tailV.Size = Vector3.new(0.4, 3.5, 2.5)
	tailV.Material = Enum.Material.SmoothPlastic
	tailV.Color = Color3.new(0.45, 0.45, 0.55)
	tailV.CanCollide = false
	tailV.CastShadow = false
	SharkModel.WeldOffset(body, tailV, CFrame.new(0, 0, 5.5))
	tailV.Parent = model
	
	-- Tail fin (horizontal lower)
	local tailH = Instance.new("WedgePart")
	tailH.Name = "TailFinH"
	tailH.Size = Vector3.new(3, 0.4, 2)
	tailH.Material = Enum.Material.SmoothPlastic
	tailH.Color = Color3.new(0.45, 0.45, 0.55)
	tailH.CanCollide = false
	tailH.CastShadow = false
	SharkModel.WeldOffset(body, tailH, CFrame.new(0, -0.5, 5) * CFrame.Angles(0, 0, math.rad(10)))
	tailH.Parent = model
	
	-- Eyes
	for _, side in ipairs({{-1.8, 0.4, -5}, {1.8, 0.4, -5}}) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.6, 0.6, 0.6)
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.new(0.05, 0.05, 0.05)
		eye.CanCollide = false
		eye.CastShadow = false
		SharkModel.WeldOffset(body, eye, CFrame.new(side[1], side[2], side[3]))
		eye.Parent = model
	end
	
	return model
end

-- Helper: weld a part to the body at a CFrame offset
function SharkModel.WeldOffset(body, part, offset)
	part.CFrame = body.CFrame * offset
	local weld = Instance.new("Motor6D")
	weld.Part0 = body
	weld.Part1 = part
	weld.C0 = offset
	weld.C1 = CFrame.new()
	weld.Parent = body
	return weld
end

-- (Welding is handled inside CreateSharkModel via WeldOffset/Motor6D)

-- Animate tail fin using Motor6D
function SharkModel.StartSwimAnimation(sharkModel)
	local body = sharkModel:FindFirstChild("Body")
	if not body then return end
	
	-- Find tail motor
	local tailMotor = nil
	for _, motor in ipairs(body:GetChildren()) do
		if motor:IsA("Motor6D") and motor.Part1 and motor.Part1.Name == "TailFinV" then
			tailMotor = motor
			break
		end
	end
	
	task.spawn(function()
		local t = 0
		while sharkModel.Parent ~= nil do
			t += 0.05
			local swing = math.sin(t * 5) * math.rad(18)
			if tailMotor then
				tailMotor.C0 = CFrame.new(0, 0, 5.5) * CFrame.Angles(0, swing, 0)
			end
			task.wait(0.05)
		end
	end)
end

-- Drive shark with WASD + mouse look
function SharkModel.DriveShark(sharkModel, player)
	local body = sharkModel:FindFirstChild("Body")
	if not body then return end
	
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	
	local yaw = 0
	local pitch = 0
	local SPEED = 28
	local CAM_DIST = 20
	local CAM_HEIGHT = 6
	
	-- Track position explicitly to avoid CFrame Y drift
	local pos = body.Position
	
	-- Sink the default jump action so Space doesn't teleport the humanoid
	ContextActionService:BindAction(
		"SharkSinkJump",
		function() return Enum.ContextActionResult.Sink end,
		false,
		Enum.KeyCode.Space
	)
	
	-- Mouse look
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	
	local mouseCon = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			yaw -= input.Delta.X * 0.003
			pitch = math.clamp(pitch - input.Delta.Y * 0.003, math.rad(-40), math.rad(30))
		end
	end)
	
	RunService:BindToRenderStep("SharkDrive", Enum.RenderPriority.Camera.Value, function(dt)
		if not body or not body.Parent then
			mouseCon:Disconnect()
			ContextActionService:UnbindAction("SharkSinkJump")
			RunService:UnbindFromRenderStep("SharkDrive")
			return
		end
		
		-- WASD + Space (up) + LeftControl (down)
		-- Space is sunk above so it won't jump; Q/E are backup
		local forward = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or
			(UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0)
		local strafe = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or
			(UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0)
		local riseUp = (UserInputService:IsKeyDown(Enum.KeyCode.Space) or
			UserInputService:IsKeyDown(Enum.KeyCode.E)) and 1 or 0
		local riseDown = (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
			UserInputService:IsKeyDown(Enum.KeyCode.Q)) and 1 or 0
		local rise = riseUp - riseDown
		
		-- Horizontal movement in camera-yaw space
		local flatCF = CFrame.Angles(0, yaw, 0)
		local horiz = flatCF:VectorToWorldSpace(Vector3.new(strafe, 0, -forward))
		
		-- Update tracked position
		pos = pos + (horiz + Vector3.new(0, rise, 0)) * SPEED * dt
		pos = Vector3.new(pos.X, math.clamp(pos.Y, 3, 45), pos.Z)
		
		-- Apply to body
		body.CFrame = CFrame.new(pos)
			* CFrame.Angles(0, yaw, 0)
			* CFrame.Angles(pitch * 0.4, 0, 0)
		
		-- Third-person camera behind shark
		local camOffset = body.CFrame:VectorToWorldSpace(Vector3.new(0, CAM_HEIGHT, CAM_DIST))
		local camPos = body.Position + camOffset
		camera.CFrame = CFrame.new(camPos, body.Position + Vector3.new(0, 1, 0))
	end)
end

-- Transform player into shark - waits for character to be ready
function SharkModel.TransformPlayer(player)
	if not player then return end
	
	-- Wait for character and HumanoidRootPart to exist
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = character:WaitForChild("HumanoidRootPart", 10)
	end
	if not rootPart then
		warn("SharkModel: HumanoidRootPart never appeared")
		return
	end
	
	-- Hide humanoid body
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide = false
		end
	end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("Decal") or obj:IsA("SpecialMesh") then
			obj.Transparency = 1
		end
	end
	
	-- Build shark in workspace directly so it renders correctly
	local sharkModel = SharkModel.CreateSharkModel()
	sharkModel.Name = "PlayerShark_" .. player.UserId
	
	local sharkBody = sharkModel:FindFirstChild("Body")
	sharkBody.CFrame = rootPart.CFrame * CFrame.new(0, 0, 0)
	sharkBody.Anchored = false
	
	-- Link rootPart to shark so character moves with it
	local rootWeld = Instance.new("WeldConstraint")
	rootWeld.Part0 = sharkBody
	rootWeld.Part1 = rootPart
	rootWeld.Parent = sharkBody
	
	sharkModel.Parent = workspace
	
	-- Start swim animation
	SharkModel.StartSwimAnimation(sharkModel)
	
	-- Start WASD driving
	SharkModel.DriveShark(sharkModel, player)
	
	print("Shark model active for", player.Name)
	return sharkModel
end

-- (Bubble effects removed - handled by terrain service)

return SharkModel
