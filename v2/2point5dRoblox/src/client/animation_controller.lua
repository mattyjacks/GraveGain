local RunService = game:GetService("RunService")

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(character)
	local self = setmetatable({}, AnimationController)
	self.character = character
	self.joints = {}
	self.baseC0s = {}
	self.targetC0s = {}
	self.animationState = "Idle" -- Idle, Swing, Block, BowDraw
	self.animationTimer = 0
	
	self:findJoints()
	
	RunService.RenderStepped:Connect(function(dt)
		self:update(dt)
	end)
	
	return self
end

function AnimationController:findJoints()
	local torso = self.character:FindFirstChild("UpperTorso") or self.character:FindFirstChild("Torso")
	if not torso then return end
	
	local rightShoulder = torso:FindFirstChild("RightShoulder") or self.character:FindFirstChild("Right Shoulder", true)
	local leftShoulder = torso:FindFirstChild("LeftShoulder") or self.character:FindFirstChild("Left Shoulder", true)
	local rootJoint = self.character:FindFirstChild("HumanoidRootPart") and self.character.HumanoidRootPart:FindFirstChild("RootJoint")
	
	if rightShoulder then
		self.joints.RightShoulder = rightShoulder
		self.baseC0s.RightShoulder = rightShoulder.C0
		self.targetC0s.RightShoulder = rightShoulder.C0
	end
	if leftShoulder then
		self.joints.LeftShoulder = leftShoulder
		self.baseC0s.LeftShoulder = leftShoulder.C0
		self.targetC0s.LeftShoulder = leftShoulder.C0
	end
	if rootJoint then
		self.joints.RootJoint = rootJoint
		self.baseC0s.RootJoint = rootJoint.C0
		self.targetC0s.RootJoint = rootJoint.C0
	end
end

function AnimationController:playSwing()
	self.animationState = "Swing"
	self.animationTimer = 0
end

function AnimationController:setBlocking(isBlocking)
	if self.animationState == "Swing" then return end
	if isBlocking then
		self.animationState = "Block"
	else
		self.animationState = "Idle"
	end
end

function AnimationController:playBowFire()
	self.animationState = "BowFire"
	self.animationTimer = 0
end

function AnimationController:setBowDraw(isDrawing)
	if isDrawing then
		self.animationState = "BowDraw"
	else
		self.animationState = "Idle"
	end
end

function AnimationController:update(dt)
	if not self.joints.RightShoulder then return end
	
	local rBase = self.baseC0s.RightShoulder
	local lBase = self.baseC0s.LeftShoulder
	local rootBase = self.baseC0s.RootJoint
	
	if self.animationState == "Idle" then
		self.targetC0s.RightShoulder = rBase
		self.targetC0s.LeftShoulder = lBase
		if rootBase then self.targetC0s.RootJoint = rootBase end
		
	elseif self.animationState == "Swing" then
		self.animationTimer = self.animationTimer + dt
		local progress = self.animationTimer / 0.35 -- Slightly longer for a full arc
		
		if progress < 0.25 then
			-- Wind up back and high
			self.targetC0s.RightShoulder = rBase * CFrame.Angles(math.rad(135), math.rad(45), math.rad(60))
			if rootBase then self.targetC0s.RootJoint = rootBase * CFrame.Angles(0, math.rad(-50), 0) end
		elseif progress < 0.65 then
			-- Fast sweeping strike across the front
			self.targetC0s.RightShoulder = rBase * CFrame.Angles(math.rad(20), math.rad(-45), math.rad(-60))
			if rootBase then self.targetC0s.RootJoint = rootBase * CFrame.Angles(0, math.rad(70), 0) end
		elseif progress < 1 then
			-- Recovery
			self.targetC0s.RightShoulder = rBase * CFrame.Angles(math.rad(10), math.rad(0), math.rad(-20))
			if rootBase then self.targetC0s.RootJoint = rootBase * CFrame.Angles(0, math.rad(20), 0) end
		else
			self.animationState = "Idle"
		end
		
	elseif self.animationState == "Block" then
		-- Raise left arm
		self.targetC0s.LeftShoulder = lBase * CFrame.Angles(math.rad(90), 0, math.rad(30))
		self.targetC0s.RightShoulder = rBase
		if rootBase then self.targetC0s.RootJoint = rootBase end
		
	elseif self.animationState == "BowDraw" then
		-- Left arm straight forward, Right arm pulled back
		self.targetC0s.LeftShoulder = lBase * CFrame.Angles(math.rad(90), 0, math.rad(10))
		self.targetC0s.RightShoulder = rBase * CFrame.Angles(math.rad(90), 0, math.rad(-60))
		if rootBase then self.targetC0s.RootJoint = rootBase * CFrame.Angles(0, math.rad(-45), 0) end
		
	elseif self.animationState == "BowFire" then
		self.animationTimer = self.animationTimer + dt
		local progress = self.animationTimer / 0.15
		
		if progress < 1 then
			-- Recoil arms backward quickly
			self.targetC0s.LeftShoulder = lBase * CFrame.Angles(math.rad(80), 0, math.rad(30))
			self.targetC0s.RightShoulder = rBase * CFrame.Angles(math.rad(100), 0, math.rad(-30))
			if rootBase then self.targetC0s.RootJoint = rootBase * CFrame.Angles(0, math.rad(-15), 0) end
		else
			self.animationState = "Idle"
		end
	end
	
	-- Lerp joints
	for name, joint in pairs(self.joints) do
		local target = self.targetC0s[name]
		if target then
			joint.C0 = joint.C0:Lerp(target, 15 * dt)
		end
	end
end

return AnimationController
