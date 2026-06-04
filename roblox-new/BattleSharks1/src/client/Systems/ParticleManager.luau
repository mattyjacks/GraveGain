-- BattleSharks Particle Manager (D3)
-- Visual effects system for particles and VFX

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local ParticleManager = {}

-- PRIVATE VARIABLES
local player = Players.LocalPlayer
local particleFolder = nil
local activeParticles = {}
local particlePool = {}
local poolSize = 50

-- PARTICLE CONFIGURATION
local PARTICLE_CONFIG = {
	MaxConcurrent = 100,
	DefaultLifetime = 2.0,
	PoolEnabled = true
}

-- PARTICLE TEMPLATES
local PARTICLE_TEMPLATES = {
	-- Combat effects
	Blood = {
		Color = Color3.new(0.8, 0, 0),
		Size = Vector3.new(0.3, 0.3, 0.3),
		Count = 8,
		Lifetime = 1.0,
		Velocity = 10,
		Gravity = true
	},
	HitSpark = {
		Color = Color3.new(1, 0.8, 0),
		Size = Vector3.new(0.2, 0.2, 0.2),
		Count = 5,
		Lifetime = 0.5,
		Velocity = 15,
		Gravity = false
	},
	
	-- Movement effects
	WaterSplash = {
		Color = Color3.new(0.5, 0.7, 1),
		Size = Vector3.new(0.5, 0.5, 0.5),
		Count = 12,
		Lifetime = 1.5,
		Velocity = 8,
		Gravity = true
	},
	Bubble = {
		Color = Color3.new(0.7, 0.9, 1),
		Size = Vector3.new(0.2, 0.2, 0.2),
		Count = 3,
		Lifetime = 3.0,
		Velocity = 2,
		Gravity = false,
		Rise = true
	},
	SpeedTrail = {
		Color = Color3.new(0, 0.5, 1),
		Size = Vector3.new(0.1, 0.5, 0.1),
		Count = 1,
		Lifetime = 0.3,
		Velocity = 0,
		Gravity = false
	},
	
	-- Mutation effects
	MutationGlow = {
		Color = Color3.new(0.5, 1, 0.5),
		Size = Vector3.new(0.4, 0.4, 0.4),
		Count = 10,
		Lifetime = 2.0,
		Velocity = 5,
		Gravity = false,
		Glow = true
	},
	
	-- Environmental
	Dust = {
		Color = Color3.new(0.8, 0.7, 0.6),
		Size = Vector3.new(0.2, 0.2, 0.2),
		Count = 6,
		Lifetime = 2.0,
		Velocity = 3,
		Gravity = true
	},
	
	-- Reward/Level up
	XPOrb = {
		Color = Color3.new(0.2, 1, 0.2),
		Size = Vector3.new(0.3, 0.3, 0.3),
		Count = 8,
		Lifetime = 1.5,
		Velocity = 12,
		Gravity = false,
		Glow = true
	},
	GoldSparkle = {
		Color = Color3.new(1, 0.8, 0),
		Size = Vector3.new(0.2, 0.2, 0.2),
		Count = 10,
		Lifetime = 1.0,
		Velocity = 8,
		Gravity = false
	}
}

-- INITIALIZATION
function ParticleManager.Initialize()
	GameUtilities.DebugPrint("ParticleManager: Initializing")
	
	particleFolder = Instance.new("Folder")
	particleFolder.Name = "BattleSharksParticles"
	particleFolder.Parent = Workspace
	
	-- Initialize particle pool
	ParticleManager.InitializePool()
	
	-- Start cleanup loop
	RunService.Heartbeat:Connect(ParticleManager.CleanupExpiredParticles)
	
	GameUtilities.DebugPrint("ParticleManager: Initialized")
end

function ParticleManager.InitializePool()
	for i = 1, poolSize do
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Anchored = false
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Transparency = 0.3
		part.Parent = particleFolder
		part.PoolIndex = i
		part.InUse = false
		
		table.insert(particlePool, part)
	end
end

function ParticleManager.GetPooledPart()
	for _, part in pairs(particlePool) do
		if not part.InUse then
			part.InUse = true
			return part
		end
	end
	
	-- Pool exhausted, create new
	local newPart = Instance.new("Part")
	newPart.Shape = Enum.PartType.Ball
	newPart.Anchored = false
	newPart.CanCollide = false
	newPart.Material = Enum.Material.Neon
	newPart.Transparency = 0.3
	newPart.Parent = particleFolder
	return newPart
end

function ParticleManager.ReturnToPool(part)
	part.InUse = false
	part.Transparency = 1
	part.Velocity = Vector3.zero
	part:ClearAllChildren()
end

-- PARTICLE EMISSION
function ParticleManager.EmitParticles(effectType, position, direction, customCount)
	local template = PARTICLE_TEMPLATES[effectType]
	if not template then return end
	
	local count = customCount or template.Count
	
	for i = 1, count do
		local part = ParticleManager.GetPooledPart()
		
		-- Configure particle
		part.Color = template.Color
		part.Size = template.Size * (0.8 + math.random() * 0.4)
		part.Position = position + Vector3.new(
			math.random(-2, 2) * 0.5,
			math.random(-2, 2) * 0.5,
			math.random(-2, 2) * 0.5
		)
		part.Transparency = 0.3
		part.Parent = particleFolder
		
		-- Calculate velocity
		local velocity
		if direction then
			local spread = Vector3.new(
				math.random(-10, 10) * 0.1,
				math.random(-10, 10) * 0.1,
				math.random(-10, 10) * 0.1
			)
			velocity = (direction + spread).Unit * template.Velocity * (0.8 + math.random() * 0.4)
		else
			local angle = math.random() * math.pi * 2
			local elevation = math.random(-0.5, 0.5)
			velocity = Vector3.new(
				math.cos(angle) * template.Velocity,
				elevation * template.Velocity,
				math.sin(angle) * template.Velocity
			)
		end
		
		-- Special behaviors
		if template.Rise then
			velocity = Vector3.new(velocity.X * 0.3, template.Velocity, velocity.Z * 0.3)
		end
		
		if template.Glow then
			local pointLight = Instance.new("PointLight")
			pointLight.Color = template.Color
			pointLight.Range = 5
			pointLight.Brightness = 2
			pointLight.Parent = part
		end
		
		-- Apply impulse
		part:ApplyImpulse(velocity * part.AssemblyMass)
		
		-- Track for cleanup
		table.insert(activeParticles, {
			Part = part,
			StartTime = tick(),
			Lifetime = template.Lifetime * (0.8 + math.random() * 0.4)
		})
	end
end

-- SPECIFIC EFFECTS
function ParticleManager.PlayHitEffect(position, normal)
	ParticleManager.EmitParticles("HitSpark", position, normal, 5)
end

function ParticleManager.PlayBloodEffect(position)
	ParticleManager.EmitParticles("Blood", position, nil, 8)
end

function ParticleManager.PlayWaterSplash(position, intensity)
	local count = intensity == "large" and 20 or 12
	ParticleManager.EmitParticles("WaterSplash", position, Vector3.new(0, 1, 0), count)
end

function ParticleManager.PlayBubbles(position, count)
	ParticleManager.EmitParticles("Bubble", position, Vector3.new(0, 1, 0), count or 3)
end

function ParticleManager.PlaySpeedTrail(position, direction)
	ParticleManager.EmitParticles("SpeedTrail", position, direction, 1)
end

function ParticleManager.PlayMutationEffect(position)
	ParticleManager.EmitParticles("MutationGlow", position, nil, 10)
end

function ParticleManager.PlayXPGain(position, amount)
	local count = math.min(math.floor(amount / 10), 15)
	ParticleManager.EmitParticles("XPOrb", position, Vector3.new(0, 1, 0), count)
end

function ParticleManager.PlayGoldGain(position, amount)
	local count = math.min(math.floor(amount / 20), 12)
	ParticleManager.EmitParticles("GoldSparkle", position, nil, count)
end

function ParticleManager.PlayLevelUp(position)
	-- Large celebration effect
	for i = 1, 3 do
		task.delay(i * 0.1, function()
			ParticleManager.EmitParticles("XPOrb", position + Vector3.new(0, i * 2, 0), Vector3.new(0, 1, 0), 10)
			ParticleManager.EmitParticles("GoldSparkle", position + Vector3.new(0, i * 2, 0), nil, 8)
		end)
	end
end

-- ATTACHED PARTICLES (for continuous effects)
function ParticleManager.AttachParticleEmitter(parent, effectType)
	local emitter = Instance.new("ParticleEmitter")
	
	if effectType == "UnderwaterBubbles" then
		emitter.Color = ColorSequence.new(Color3.new(0.7, 0.9, 1))
		emitter.Size = NumberSequence.new(0.5, 1.5)
		emitter.Transparency = NumberSequence.new(0.3, 1)
		emitter.Lifetime = NumberRange.new(1, 3)
		emitter.Rate = 5
		emitter.Speed = NumberRange.new(2, 5)
		emitter.Acceleration = Vector3.new(0, 5, 0)
		emitter.Parent = parent
	elseif effectType == "MutationAura" then
		emitter.Color = ColorSequence.new(Color3.new(0.5, 1, 0.5))
		emitter.Size = NumberSequence.new(1, 2)
		emitter.Transparency = NumberSequence.new(0.5, 1)
		emitter.Lifetime = NumberRange.new(0.5, 1)
		emitter.Rate = 10
		emitter.Speed = NumberRange.new(1, 3)
		emitter.Parent = parent
	elseif effectType == "SpeedBoost" then
		emitter.Color = ColorSequence.new(Color3.new(0, 0.5, 1))
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.Lifetime = NumberRange.new(0.3, 0.5)
		emitter.Rate = 20
		emitter.Speed = NumberRange.new(5, 10)
		emitter.Parent = parent
	end
	
	return emitter
end

-- CLEANUP
function ParticleManager.CleanupExpiredParticles()
	local currentTime = tick()
	local i = 1
	
	while i <= #activeParticles do
		local particle = activeParticles[i]
		local elapsed = currentTime - particle.StartTime
		
		-- Update transparency for fade out
		if elapsed > particle.Lifetime * 0.7 then
			local fadeProgress = (elapsed - particle.Lifetime * 0.7) / (particle.Lifetime * 0.3)
			particle.Part.Transparency = 0.3 + fadeProgress * 0.7
		end
		
		-- Remove expired
		if elapsed >= particle.Lifetime then
			ParticleManager.ReturnToPool(particle.Part)
			table.remove(activeParticles, i)
		else
			i += 1
		end
	end
end

function ParticleManager.Cleanup()
	if particleFolder then
		particleFolder:Destroy()
	end
	particlePool = {}
	activeParticles = {}
	GameUtilities.DebugPrint("ParticleManager: Cleaned up")
end

return ParticleManager
