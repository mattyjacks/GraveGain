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
	elseif self.state == "Swing" then
		self.timer = self.timer + dt
		local p = self.timer / 0.38   -- total duration

		if p < 0.22 then
			-- Wind-up: arm high-back, torso rotates away from strike
			local t = p / 0.22
			self.targetC0s.RightShoulder = R * cf(0,0,0, 160 - t*20, 40, 70)
			if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 0,-55*t, 0) end
			if N  then self.targetC0s.Neck = N * cf(0,0,0, 0, 30*t, 0) end

		elseif p < 0.60 then
			-- Strike: fast sweep across — arm drives forward and down
			local t = (p - 0.22) / 0.38
			self.targetC0s.RightShoulder = R * cf(0,0,0,
				140 - t*170, 40 - t*90, 70 - t*130)
			if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 0, -55 + t*125, 0) end
			if N  then self.targetC0s.Neck = N * cf(0,0,0, 0, 30 - t*60, 0) end

		elseif p < 1 then
			-- Recovery: spring back to neutral
			local t = (p - 0.60) / 0.40
			self.targetC0s.RightShoulder = R * cf(0,0,0, -30 + t*30, -50 + t*50, -60 + t*60)
			if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 0, 70 - t*70, 0) end
			if N  then self.targetC0s.Neck = N * cf(0,0,0, 0, -30 + t*30, 0) end
		else
			self.state = "Idle"
		end

	-- ── Block: shield raised, body angled ───────────────────────────────
	elseif self.state == "Block" then
		self.targetC0s.RightShoulder = R * cf(0,0,0, 30, 0, -20)
		if self.joints.LeftShoulder then
			self.targetC0s.LeftShoulder  = L * cf(0,0,0, 90, 0, 35)
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 8, 25, 0) end
		if N  then self.targetC0s.Neck = N * cf(0,0,0, -5, -20, 0) end

	-- ── BowDraw: left arm forward, right arm drawn back ─────────────────
	elseif self.state == "BowDraw" then
		local tension = 0.5 + math.sin(self.idleTime * 3) * 0.03  -- tiny tremble
		self.targetC0s.RightShoulder = R * cf(0,0,0, 85*tension, -20, -65)
		if self.joints.LeftShoulder then
			self.targetC0s.LeftShoulder  = L * cf(0,0,0, 85*tension, 15, 10)
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 0, -40, 0) end
		if N  then self.targetC0s.Neck = N * cf(0,0,0, 0, 35, 0) end

	-- ── BowFire: snap release recoil ────────────────────────────────────
	elseif self.state == "BowFire" then
		self.timer = self.timer + dt
		local p = self.timer / 0.18

		if p < 0.4 then
			-- Snap arms back
			self.targetC0s.RightShoulder = R * cf(0,0,0, 100, -30, -80)
			if self.joints.LeftShoulder then
				self.targetC0s.LeftShoulder  = L * cf(0,0,0, 80, 30, 20)
			end
		elseif p < 1 then
			-- Recover
			local t = (p - 0.4) / 0.6
			self.targetC0s.RightShoulder = R * cf(0,0,0, 100 - t*100, -30 + t*30, -80 + t*80)
		else
			self.state = "Idle"
		end
		if RJ then self.targetC0s.RootJoint = RJ * cf(0,0,0, 0, -20, 0) end
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
