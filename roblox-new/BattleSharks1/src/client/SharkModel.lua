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
-- animState is a shared table updated by DriveShark each frame
function SharkModel.StartSwimAnimation(sharkModel, animState)
	local body = sharkModel:FindFirstChild("Body")
	if not body then return end

	-- Collect all motor references by part name
	local motors = {}
	for _, motor in ipairs(body:GetChildren()) do
		if motor:IsA("Motor6D") and motor.Part1 then
			motors[motor.Part1.Name] = motor
		end
	end

	-- Store base C0 offsets so we can compose on top of them
	local baseC0 = {}
	for name, motor in pairs(motors) do
		baseC0[name] = motor.C0
	end

	local t = 0
	task.spawn(function()
		while sharkModel.Parent ~= nil do
			local dt = task.wait(0.033) -- ~30 fps animation tick
			if not body or not body.Parent then break end

			local speed     = animState and animState.speed     or 0
			local turnRate  = animState and animState.turnRate  or 0
			local isSprint  = animState and animState.isSprint  or false

			-- Tail wag: faster + wider when sprinting
			local wagFreq   = 3.5 + speed * 0.08
			local wagAmp    = math.rad(isSprint and 22 or 15)
			t += dt
			local swing = math.sin(t * wagFreq) * wagAmp

			if motors["TailFinV"] and baseC0["TailFinV"] then
				motors["TailFinV"].C0 = baseC0["TailFinV"] * CFrame.Angles(0, swing, 0)
			end

			-- Horizontal tail lobe also wags in opposition
			if motors["TailFinH"] and baseC0["TailFinH"] then
				motors["TailFinH"].C0 = baseC0["TailFinH"] * CFrame.Angles(0, -swing * 0.6, 0)
			end

			-- Pectoral fins tilt into turns (bank)
			local bankAngle = math.clamp(turnRate * 0.4, -math.rad(25), math.rad(25))
			if motors["LeftFin"] and baseC0["LeftFin"] then
				motors["LeftFin"].C0 = baseC0["LeftFin"] * CFrame.Angles(0, 0, -bankAngle)
			end
			if motors["RightFin"] and baseC0["RightFin"] then
				motors["RightFin"].C0 = baseC0["RightFin"] * CFrame.Angles(0, 0, bankAngle)
			end

			-- Gentle undulating body pitch (swimming wave)
			local bodyWave = math.sin(t * wagFreq + math.pi * 0.5) * math.rad(3)
			if motors["Head"] and baseC0["Head"] then
				motors["Head"].C0 = baseC0["Head"] * CFrame.Angles(-bodyWave * 0.5, 0, 0)
			end
		end
	end)
end

-- Drive shark with mouse-look aim + always-forward movement.
-- S = 180-degree U-turn over 1 second. Shark never moves backward.
-- Shift = sprint. A/D = yaw steer. Mouse = pitch/yaw aim.
function SharkModel.DriveShark(sharkModel, player)
	local body = sharkModel:FindFirstChild("Body")
	if not body then return end

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable

	-- Tunables
	local SPEED_BASE   = 28
	local SPEED_SPRINT = 52
	local TURN_RATE    = 2.2      -- rad/s from A/D keys
	local MOUSE_YAW    = 0.0022
	local MOUSE_PITCH  = 0.0018
	local PITCH_MIN    = math.rad(-50)
	local PITCH_MAX    = math.rad(40)
	local UTURN_TIME   = 1.0      -- seconds for S-key 180 U-turn
	local CAM_DIST     = 22
	local CAM_HEIGHT   = 5
	local CAM_SMOOTH   = 9
	local SPEED_ACCEL  = 6
	local YAW_SMOOTH   = 7

	-- State
	local yaw         = 0
	local pitch       = 0
	local targetYaw   = 0
	local targetPitch = 0
	local currentSpeed = SPEED_BASE

	-- U-turn state
	local uTurnActive   = false
	local uTurnProgress = 0
	local uTurnFromYaw  = 0

	-- Animation state table shared with StartSwimAnimation
	local animState = { speed = SPEED_BASE, turnRate = 0, isSprint = false }

	local pos   = body.CFrame.Position
	local camCF = camera.CFrame

	-- Sink default jump
	ContextActionService:BindAction(
		"SharkSinkJump",
		function() return Enum.ContextActionResult.Sink end,
		false,
		Enum.KeyCode.Space
	)

	-- Lock mouse to center for mouse-look driving
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	-- Mouse delta drives yaw/pitch aim
	-- +pi body offset means rightward mouse drag = increasing targetYaw turns nose right
	local mouseCon = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			targetYaw   = targetYaw   + input.Delta.X * MOUSE_YAW
			targetPitch = math.clamp(
				targetPitch - input.Delta.Y * MOUSE_PITCH,
				PITCH_MIN, PITCH_MAX
			)
		end
	end)

	-- S key begins U-turn (180 degrees, no backward swimming)
	local sTurnCon = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.S and not uTurnActive then
			uTurnActive   = true
			uTurnProgress = 0
			uTurnFromYaw  = targetYaw
		end
	end)

	RunService:BindToRenderStep("SharkDrive", Enum.RenderPriority.Camera.Value, function(dt)
		if not body or not body.Parent then
			mouseCon:Disconnect()
			sTurnCon:Disconnect()
			ContextActionService:UnbindAction("SharkSinkJump")
			RunService:UnbindFromRenderStep("SharkDrive")
			return
		end

		-- U-turn: smoothstep 180-degree rotation over UTURN_TIME seconds
		if uTurnActive then
			uTurnProgress = math.min(uTurnProgress + dt / UTURN_TIME, 1)
			local ease = uTurnProgress * uTurnProgress * (3 - 2 * uTurnProgress)
			targetYaw = uTurnFromYaw + math.pi * ease
			if uTurnProgress >= 1 then
				uTurnActive   = false
				targetPitch   = 0  -- level out after U-turn
			end
		end

		-- A/D steering: D=nose right=targetYaw decreases, A=nose left=targetYaw increases
		if not uTurnActive then
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				targetYaw = targetYaw - TURN_RATE * dt
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				targetYaw = targetYaw + TURN_RATE * dt
			end
		end

		-- Smooth yaw and pitch towards targets
		local lerpT  = math.min(YAW_SMOOTH * dt, 1)
		local prevYaw = yaw
		yaw   = yaw   + (targetYaw   - yaw)   * lerpT
		pitch = pitch + (targetPitch - pitch) * lerpT

		local turnRate = (yaw - prevYaw) / (dt + 1e-6)

		-- Speed
		local isSprint    = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		local targetSpeed = isSprint and SPEED_SPRINT or SPEED_BASE
		currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * math.min(SPEED_ACCEL * dt, 1)

		-- Always-forward along shark aim vector (matches body CFrame which has +pi base rotation)
		local sharkCF  = CFrame.new(pos) * CFrame.Angles(0, yaw + math.pi, 0) * CFrame.Angles(-pitch, 0, 0)
		local fwd      = sharkCF.LookVector
		pos = pos + fwd * currentSpeed * dt
		pos = Vector3.new(pos.X, math.clamp(pos.Y, 2, 48), pos.Z)

		-- Body roll into turns for realism
		local rollAngle = math.clamp(-turnRate * 0.28, -math.rad(28), math.rad(28))

		-- Apply shark body CFrame
		-- math.pi base rotation: model nose is at -Z, yaw 0 = world +Z forward, so flip 180 to align
		body.CFrame = CFrame.new(pos)
			* CFrame.Angles(0, yaw + math.pi, 0)
			* CFrame.Angles(-pitch, 0, -rollAngle)

		-- Smooth third-person camera behind shark
		-- shark nose faces +Z at yaw=0, camera behind needs -Z offset, so camYaw=yaw+pi
		local camYaw = yaw + math.pi
		local camTargetPos = pos + Vector3.new(
			-math.sin(camYaw) * math.cos(pitch) * CAM_DIST,
			 math.sin(pitch) * CAM_DIST + CAM_HEIGHT,
			 math.cos(camYaw) * math.cos(pitch) * CAM_DIST
		)
		local camTargetCF = CFrame.new(camTargetPos, pos + Vector3.new(0, 1, 0))
		camCF  = camCF:Lerp(camTargetCF, math.min(CAM_SMOOTH * dt, 1))
		camera.CFrame = camCF

		-- Update animation state
		animState.speed    = currentSpeed
		animState.turnRate = turnRate
		animState.isSprint = isSprint
	end)

	return animState
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
	
	-- Disable humanoid movement
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
		-- Hide default character appearance
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	
	-- Hide every visual element in the character
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("UnionOperation") or obj:IsA("MeshPart") then
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CastShadow = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		elseif obj:IsA("SpecialMesh") or obj:IsA("BlockMesh") or obj:IsA("CylinderMesh") then
			obj.Scale = Vector3.new(0, 0, 0)
		elseif obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				handle.Transparency = 1
				handle.CanCollide = false
			end
		elseif obj:IsA("ShirtGraphic") or obj:IsA("Shirt") or obj:IsA("Pants") then
			obj:Destroy()
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
	
	-- Start WASD driving first so we get the animState handle
	local animState = SharkModel.DriveShark(sharkModel, player)

	-- Start swim animation, sharing the animState table
	SharkModel.StartSwimAnimation(sharkModel, animState)
	
	print("Shark model active for", player.Name)
	return sharkModel
end

-- (Bubble effects removed - handled by terrain service)

return SharkModel
