-- RunController: escape tunnel movement
-- Down Arrow / "Run Away" button  -> moves player backward into escape tunnel (+Z)
-- Up Arrow   / "Run Forwards" button -> moves player back toward spawn (-Z, clamped at Z=0)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService      = game:GetService("TweenService")

local RunController = {}

-- Config
local ESCAPE_SPEED      = 18   -- studs/sec
local FORWARD_SPEED     = 20   -- studs/sec (slightly faster returning)
local JUMP_VELOCITY     = 52   -- upward impulse when auto-jumping
local OBSTACLE_PROBE    = 2.0  -- studs ahead to probe for obstacles
local FLOOR_PROBE       = 3.5  -- studs down to probe for ground
local SPAWN_Z           = 0    -- minimum Z (cannot go past spawn point)
local TUNNEL_END_Z      = 195  -- maximum Z (just before end wall at Z=200)
local JUMP_COOLDOWN     = 0.5  -- seconds between auto-jumps

-- State
RunController.IsEnabled     = false
RunController.RunningAway   = false  -- +Z direction
RunController.RunningFwd    = false  -- -Z direction
RunController._lastJumpTime = 0
RunController._screenGui    = nil

local player = Players.LocalPlayer

-- ========== HELPERS ==========

local function GetHRP()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- Raycast helper: returns true if something is hit
local function Raycast(origin, direction, ignoreList)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList or {}
	return workspace:Raycast(origin, direction, params)
end

-- Check if the character is grounded
local function IsGrounded(hrp, ignoreList)
	local result = Raycast(hrp.Position, Vector3.new(0, -FLOOR_PROBE, 0), ignoreList)
	return result ~= nil
end

-- Check if there is an obstacle directly in the movement direction
local function HasObstacleAhead(hrp, dirZ, ignoreList)
	-- Probe from chest height forward
	local probeOrigin = hrp.Position + Vector3.new(0, 0.5, 0)
	local result = Raycast(probeOrigin, Vector3.new(0, 0, dirZ * OBSTACLE_PROBE), ignoreList)
	return result ~= nil
end

-- ========== MOVEMENT UPDATE ==========

function RunController._Update(dt)
	if not RunController.IsEnabled then return end
	if not RunController.RunningAway and not RunController.RunningFwd then return end

	local hrp = GetHRP()
	if not hrp then return end
	local humanoid = GetHumanoid()

	local char = player.Character
	local ignoreList = char and { char } or {}

	-- Determine direction (+Z = away, -Z = forward)
	local dirZ = RunController.RunningAway and 1 or -1
	local speed = RunController.RunningAway and ESCAPE_SPEED or FORWARD_SPEED

	-- Clamp to tunnel bounds
	local currentZ = hrp.Position.Z
	if (dirZ > 0 and currentZ >= TUNNEL_END_Z) or (dirZ < 0 and currentZ <= SPAWN_Z) then
		-- Hit the wall/spawn boundary - stop
		hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
		return
	end

	-- Auto-jump: if obstacle ahead and grounded, jump
	local now = tick()
	if HasObstacleAhead(hrp, dirZ, ignoreList) and IsGrounded(hrp, ignoreList) then
		if now - RunController._lastJumpTime > JUMP_COOLDOWN then
			RunController._lastJumpTime = now
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			hrp.AssemblyLinearVelocity = Vector3.new(
				hrp.AssemblyLinearVelocity.X,
				JUMP_VELOCITY,
				hrp.AssemblyLinearVelocity.Z
			)
		end
	end

	-- Drive movement by directly setting Z velocity on unanchored HRP
	hrp.AssemblyLinearVelocity = Vector3.new(
		0,
		hrp.AssemblyLinearVelocity.Y,  -- preserve vertical (gravity/jump)
		dirZ * speed
	)
end

-- ========== INPUT BINDINGS ==========

local function OnRunAway(actionName, inputState, _inputObj)
	if not RunController.IsEnabled then return Enum.ContextActionResult.Pass end
	if inputState == Enum.UserInputState.Begin then
		RunController.RunningAway = true
		RunController.RunningFwd  = false
		RunController._UpdateButtonVisuals()
	elseif inputState == Enum.UserInputState.End then
		RunController.RunningAway = false
		RunController._UpdateButtonVisuals()
	end
	return Enum.ContextActionResult.Sink
end

local function OnRunForwards(actionName, inputState, _inputObj)
	if not RunController.IsEnabled then return Enum.ContextActionResult.Pass end
	if inputState == Enum.UserInputState.Begin then
		RunController.RunningFwd  = true
		RunController.RunningAway = false
		RunController._UpdateButtonVisuals()
	elseif inputState == Enum.UserInputState.End then
		RunController.RunningFwd = false
		RunController._UpdateButtonVisuals()
	end
	return Enum.ContextActionResult.Sink
end

-- ========== UI ==========

function RunController._UpdateButtonVisuals()
	local gui = RunController._screenGui
	if not gui then return end
	local awayBtn = gui:FindFirstChild("RunAwayBtn")
	local fwdBtn  = gui:FindFirstChild("RunFwdBtn")
	if awayBtn then
		awayBtn.BackgroundColor3 = RunController.RunningAway
			and Color3.new(1, 0.3, 0.1)
			or  Color3.new(0.18, 0.18, 0.22)
	end
	if fwdBtn then
		fwdBtn.BackgroundColor3 = RunController.RunningFwd
			and Color3.new(0.1, 0.8, 0.4)
			or  Color3.new(0.18, 0.18, 0.22)
	end
end

local function MakeButton(parent, name, text, pos, normalColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 150, 0, 50)
	btn.Position = pos
	btn.BackgroundColor3 = normalColor
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 2
	btn.BorderColor3 = Color3.new(0.6, 0.6, 0.7)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.Font = Enum.Font.SourceSansBold
	btn.AutoButtonColor = false
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	return btn
end

function RunController._CreateUI()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RunControlUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	RunController._screenGui = screenGui

	local darkColor   = Color3.new(0.18, 0.18, 0.22)

	-- "Run Away" button (bottom-center-left)
	local awayBtn = MakeButton(screenGui, "RunAwayBtn",
		"v  RUN AWAY  v",
		UDim2.new(0.5, -170, 1, -130),
		darkColor)

	-- "Run Forwards" button (bottom-center-right)
	local fwdBtn = MakeButton(screenGui, "RunFwdBtn",
		"^  FORWARDS  ^",
		UDim2.new(0.5, 20, 1, -130),
		darkColor)

	-- Label above buttons
	local label = Instance.new("TextLabel")
	label.Name = "RunLabel"
	label.Size = UDim2.new(0, 340, 0, 24)
	label.Position = UDim2.new(0.5, -170, 1, -158)
	label.BackgroundTransparency = 1
	label.Text = "[ Down Arrow / Up Arrow ]"
	label.TextColor3 = Color3.new(0.7, 0.7, 0.8)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSans
	label.Parent = screenGui

	-- Button hold logic
	local awayHeld = false
	local fwdHeld  = false

	awayBtn.MouseButton1Down:Connect(function()
		awayHeld = true
		RunController.RunningAway = true
		RunController.RunningFwd  = false
		RunController._UpdateButtonVisuals()
	end)
	awayBtn.MouseButton1Up:Connect(function()
		awayHeld = false
		RunController.RunningAway = false
		RunController._UpdateButtonVisuals()
	end)
	awayBtn.MouseLeave:Connect(function()
		if awayHeld then
			awayHeld = false
			RunController.RunningAway = false
			RunController._UpdateButtonVisuals()
		end
	end)

	fwdBtn.MouseButton1Down:Connect(function()
		fwdHeld = true
		RunController.RunningFwd  = true
		RunController.RunningAway = false
		RunController._UpdateButtonVisuals()
	end)
	fwdBtn.MouseButton1Up:Connect(function()
		fwdHeld = false
		RunController.RunningFwd = false
		RunController._UpdateButtonVisuals()
	end)
	fwdBtn.MouseLeave:Connect(function()
		if fwdHeld then
			fwdHeld = false
			RunController.RunningFwd = false
			RunController._UpdateButtonVisuals()
		end
	end)
end

-- ========== PUBLIC API ==========

function RunController.Initialize()
	print("[RUN] RunController.Initialize()")
	RunController._CreateUI()

	-- Arrow key bindings via CAS (won't conflict with typing handler since we use different keys)
	ContextActionService:BindActionAtPriority(
		"RunAway",
		OnRunAway,
		false,
		2500,  -- below typing (3000) so letters still work
		Enum.KeyCode.Down
	)
	ContextActionService:BindActionAtPriority(
		"RunForwards",
		OnRunForwards,
		false,
		2500,
		Enum.KeyCode.Up
	)

	-- Per-frame movement update
	RunService.Heartbeat:Connect(RunController._Update)

	print("[RUN] RunController initialized - Down=RunAway, Up=RunForwards")
end

function RunController.SetEnabled(enabled)
	RunController.IsEnabled = enabled
	RunController.RunningAway = false
	RunController.RunningFwd  = false

	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChildOfClass("Humanoid")

	if enabled then
		-- Move character from hidden position (Y=-500) to corridor floor at spawn point
		if hrp then
			hrp.Anchored = false
			hrp.CFrame = CFrame.new(0, 3, 10)  -- just in front of camera, on corridor floor
			print("[RUN] Character moved to corridor floor for running")
		end
		if hum then
			hum.WalkSpeed  = 0   -- we drive movement manually via AssemblyLinearVelocity
			hum.JumpPower  = 50  -- allow Humanoid jumping
			hum.AutoRotate = false
		end
		-- Make character visible
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Transparency = 1  -- keep invisible (FPS game, no need to show)
				end
			end
		end
	else
		-- Stop movement and re-anchor/hide when game not active
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			hrp.Anchored = true
			hrp.CFrame = CFrame.new(0, -500, 0)
			print("[RUN] Character re-hidden at Y=-500")
		end
		if hum then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end
	end

	if RunController._screenGui then
		RunController._screenGui.Enabled = enabled
	end
	RunController._UpdateButtonVisuals()
	print("[RUN] SetEnabled(" .. tostring(enabled) .. ")")
end

return RunController
