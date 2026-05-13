-- animation_controller.lua (REWRITE)
-- Proper hand-keyed animations via Motor6D C0 manipulation.
-- States: Idle (breathing bob), Swing (3-phase), Block, BowDraw, BowFire.

local RunService = game:GetService("RunService")

local AnimationController = {}
AnimationController.__index = AnimationController

-- ── Helpers ────────────────────────────────────────────────────────────────

local function cf(x, y, z, rx, ry, rz)
	return CFrame.new(x or 0, y or 0, z or 0)
		* CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

function AnimationController.new(character)
	local self = setmetatable({}, AnimationController)
	self.character      = character
	self.joints         = {}
	self.baseC0s        = {}
	self.targetC0s      = {}
	self.state          = "Idle"
	self.timer          = 0
	self.idleTime       = 0
	self.lerpSpeed      = 18

	self:findJoints()

	RunService.RenderStepped:Connect(function(dt) self:update(dt) end)
	return self
end

-- ── Joint discovery ────────────────────────────────────────────────────────

function AnimationController:findJoints()
	local c = self.character

	-- Support both R15 and R6
	local torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
	if not torso then return end

	local names = {
		RightShoulder = torso:FindFirstChild("RightShoulder")
			or c:FindFirstChild("Right Shoulder", true),
		LeftShoulder  = torso:FindFirstChild("LeftShoulder")
			or c:FindFirstChild("Left Shoulder", true),
		RootJoint     = (c:FindFirstChild("HumanoidRootPart") or torso)
			:FindFirstChild("RootJoint"),
		Neck          = torso:FindFirstChild("Neck")
			or c:FindFirstChild("Neck", true),
	}

	for k, joint in pairs(names) do
		if joint then
			self.joints[k]    = joint
			self.baseC0s[k]   = joint.C0
			self.targetC0s[k] = joint.C0
		end
	end
end

-- ── Public state setters ────────────────────────────────────────────────────

function AnimationController:playSwing()
	self.state = "Swing"; self.timer = 0
end

function AnimationController:setBlocking(on)
	if self.state == "Swing" then return end
	self.state = on and "Block" or "Idle"
end

function AnimationController:setBowDraw(on)
	if self.state == "Swing" then return end
	self.state = on and "BowDraw" or "Idle"
end

function AnimationController:playBowFire()
	self.state = "BowFire"; self.timer = 0
end

-- ── Update ─────────────────────────────────────────────────────────────────

function AnimationController:update(dt)
	local rs = self.joints.RightShoulder
	if not rs then return end

	local R  = self.baseC0s.RightShoulder
	local L  = self.baseC0s.LeftShoulder
	local RJ = self.baseC0s.RootJoint
	local N  = self.baseC0s.Neck

	self.idleTime = self.idleTime + dt

	-- ── Idle: subtle breathing bob ───────────────────────────────────────
	if self.state == "Idle" then
		local breathe = math.sin(self.idleTime * 1.4) * 0.04
		local sway    = math.sin(self.idleTime * 0.7) * 0.015
		self.targetC0s.RightShoulder = R * cf(0,0,0,  -5 + breathe*10, sway*20, 0)
		if self.joints.LeftShoulder  then
			self.targetC0s.LeftShoulder  = L * cf(0,0,0, -5 + breathe*10, -sway*20, 0)
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0, breathe * 0.5, 0, 0,0,0) end
		if N  then self.targetC0s.Neck      = N  * cf(0,0,0, sway*5, 0, 0) end

	-- ── Swing: wind-up → strike → recover ───────────────────────────────
	-- ── Swing: Overhead Slam ──────────────────────────────
	elseif self.state == "Swing" then
		self.timer = self.timer + dt
		local p = self.timer / 0.42

		if p < 0.25 then
			-- Wind-up: Lift high
			local t = p / 0.25
			self.targetC0s.RightShoulder = R * cf(0, 0.5, 0, 165, 0, 10)
			if RJ then self.targetC0s.RootJoint = RJ * cf(0, 0, 0, -10 * t, 0, 0) end
		elseif p < 0.65 then
			-- Strike: Slam down
			local t = (p - 0.25) / 0.4
			self.targetC0s.RightShoulder = R * cf(0, -0.5, -1, -40, 0, 0)
			if RJ then self.targetC0s.RootJoint = RJ * cf(0, -0.2, 0, 20 * t, 0, 0) end
		elseif p < 1 then
			-- Recover
			local t = (p - 0.65) / 0.35
			self.targetC0s.RightShoulder = R * cf(0, -0.5 + 0.5*t, -1 + t, -40 + 40*t, 0, 0)
		else
			self.state = "Idle"
		end

	-- ── Block: Hunker Down ────────────────────────────────
	elseif self.state == "Block" then
		self.targetC0s.RightShoulder = R * cf(0,0,0, 20, 0, -15)
		if self.joints.LeftShoulder then
			self.targetC0s.LeftShoulder  = L * cf(0.2, 0.2, -0.5, 95, 20, 45)
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0, -0.4, 0, 5, 25, 0) end
		if N  then self.targetC0s.Neck = N * cf(0,0,0, -10, -20, 0) end

	-- ── BowDraw: Dynamic Pull ──────────────────────────────
	elseif self.state == "BowDraw" then
		local tremble = math.sin(tick() * 40) * 0.02
		self.targetC0s.RightShoulder = R * cf(-0.5 + tremble, 0, -0.8, 90, -30, -85)
		if self.joints.LeftShoulder then
			self.targetC0s.LeftShoulder  = L * cf(0.5, 0, -0.5, 88, 10, 5)
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 0, -45, 0) end
		if N  then self.targetC0s.Neck = N * cf(0,0,0, 0, 40, 0) end

	-- ── BowFire: Snap Release ─────────────────────────────
	elseif self.state == "BowFire" then
		self.timer = self.timer + dt
		local p = self.timer / 0.22

		if p < 0.3 then
			-- Recoil
			self.targetC0s.RightShoulder = R * cf(0.2, 0, 0.2, 70, -10, -30)
			if self.joints.LeftShoulder then
				self.targetC0s.LeftShoulder = L * cf(0, 0, 0.5, 100, 40, 10)
			end
		elseif p < 1 then
			local t = (p - 0.3) / 0.7
			self.targetC0s.RightShoulder = R * cf(0.2 - 0.2*t, 0, 0.2 - 0.2*t, 70 - 70*t, -10 + 10*t, -30 + 30*t)
		else
			self.state = "Idle"
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0, 0, 0, 0, -20, 0) end
	end

	-- ── Lerp all joints to targets ───────────────────────────────────────
	local speed = self.lerpSpeed * dt
	for name, joint in pairs(self.joints) do
		local target = self.targetC0s[name]
		if target then
			joint.C0 = joint.C0:Lerp(target, math.min(speed, 1))
		end
	end
end

return AnimationController
