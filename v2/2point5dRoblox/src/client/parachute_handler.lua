-- parachute_handler.lua (CLIENT)
-- Handles the skydiving deployment and slowing effect.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ParachuteHandler = {}
ParachuteHandler.__index = ParachuteHandler

function ParachuteHandler.new(character)
	local self = setmetatable({}, ParachuteHandler)
	self.character = character
	self.hrp = character:WaitForChild("HumanoidRootPart")
	self.humanoid = character:WaitForChild("Humanoid")
	
	self.isDeployed = false
	self.parachuteModel = nil
	self.deployHeight = 250 -- Activate parachute at this height
	self.slowSpeed = 30 -- Max downward velocity with chute
	
	self:startLoop()
	return self
end

function ParachuteHandler:startLoop()
	RunService.Heartbeat:Connect(function(dt)
		if not self.hrp or not self.hrp.Parent then return end
		
		-- Don't deploy if in lobby or high altitude cinematic
		if self.hrp.Position.Y > 500 then return end
		
		local velocity = self.hrp.Velocity
		local pos = self.hrp.Position
		
		-- Check altitude using modern Raycast (longer range)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {self.character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local raycastResult = workspace:Raycast(pos, Vector3.new(0, -2000, 0), raycastParams)
		local altitude = raycastResult and (pos - raycastResult.Position).Magnitude or 2000
		
		-- Deploy chute if falling fast and close to ground
		if not self.isDeployed and velocity.Y < -40 and altitude < self.deployHeight then
			self:deploy()
		end
		
		if self.isDeployed then
			-- Apply upward force to slow fall
			local targetVel = Vector3.new(velocity.X, -self.slowSpeed, velocity.Z)
			self.hrp.Velocity = self.hrp.Velocity:Lerp(targetVel, 0.1)
			
			-- Remove if landed
			if self.humanoid.FloorMaterial ~= Enum.Material.Air or altitude < 5 then
				self:destroy()
			end
		end
	end)
end

function ParachuteHandler:deploy()
	if self.isDeployed then return end
	self.isDeployed = true
	print("Parachute Deployed!")
	
	-- Create Fancy Parachute Model
	local model = Instance.new("Model")
	model.Name = "FancyParachute"
	model.Parent = self.character
	self.parachuteModel = model
	
	-- Parachute Canopy (Large transparent part with particles)
	local canopy = Instance.new("Part")
	canopy.Size = Vector3.new(20, 2, 20)
	canopy.Shape = Enum.PartType.Ball
	canopy.Color = Color3.fromRGB(0, 150, 255)
	canopy.Material = Enum.Material.Neon
	canopy.Transparency = 0.6
	canopy.CanCollide = false
	canopy.Anchored = false
	canopy.Parent = model
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = self.hrp
	weld.Part1 = canopy
	weld.Parent = canopy
	canopy.CFrame = self.hrp.CFrame * CFrame.new(0, 15, 0)
	
	-- Particle Effects
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://244221446"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	particles.Size = NumberSequence.new(2, 0)
	particles.Rate = 100
	particles.Speed = NumberRange.new(5, 10)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Parent = canopy
	
	-- Sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12222084" -- wind/woosh
	sound.Volume = 0.5
	sound.Looped = true
	sound.Parent = canopy
	sound:Play()
end

function ParachuteHandler:destroy()
	if not self.isDeployed then return end
	self.isDeployed = false
	if self.parachuteModel then
		-- Smooth fade out
		local canopy = self.parachuteModel:FindFirstChildWhichIsA("BasePart")
		if canopy then
			local sound = canopy:FindFirstChildWhichIsA("Sound")
			if sound then sound:Stop() end
		end
		self.parachuteModel:Destroy()
		self.parachuteModel = nil
	end
end

return ParachuteHandler
