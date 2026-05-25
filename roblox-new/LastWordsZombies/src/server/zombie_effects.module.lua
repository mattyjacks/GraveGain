-- Zombie death effects: explosion, ragdoll, blood particles

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local ZombieEffects = {}

function ZombieEffects.Explosion(position, activeZombies)
	local explosion = Instance.new("Explosion")
	explosion.Position      = position
	explosion.BlastRadius   = GameData.EXPLOSION.RADIUS
	explosion.BlastPressure = GameData.EXPLOSION.PRESSURE
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Parent        = workspace

	local particles = Instance.new("ParticleEmitter")
	particles.Color    = ColorSequence.new(GameData.VISUALS.EXPLOSION_COLOR)
	particles.Size     = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0)})
	particles.Lifetime = NumberRange.new(0.5, 1.0)
	particles.Rate     = 0
	particles.Speed    = NumberRange.new(10, 50)
	particles.SpreadAngle = Vector2.new(0, 360)
	particles.Parent   = workspace.Terrain
	particles:Emit(GameData.VISUALS.EXPLOSION_PARTICLES)
	Debris:AddItem(particles, 2)

	-- Knockback nearby zombies
	for _, zd in ipairs(activeZombies) do
		if not zd.IsAlive then continue end
		local zPos = zd.Model.PrimaryPart.Position
		local dist = (zPos - position).Magnitude
		if dist <= GameData.EXPLOSION.RADIUS then
			local dir    = (zPos - position).Unit
			local force  = (1 - dist / GameData.EXPLOSION.RADIUS) * GameData.EXPLOSION.PRESSURE * GameData.EXPLOSION.KNOCKBACK_MULTIPLIER
			local root   = zd.Model.PrimaryPart
			if root then
				root.Anchored = false
				root:ApplyImpulse(dir * force * root.AssemblyMass)
				task.delay(0.5, function()
					if root and root.Parent then root.Anchored = true end
				end)
			end
		end
	end
end

function ZombieEffects.Ragdoll(model)
	local primary = model.PrimaryPart
	if primary then
		-- Blood burst
		local att = Instance.new("Attachment")
		att.Position = primary.Position
		att.Parent   = workspace.Terrain
		local blood = Instance.new("ParticleEmitter")
		blood.Color       = ColorSequence.new(GameData.VISUALS.BLOOD_COLOR)
		blood.Size        = NumberSequence.new({NumberSequenceKeypoint.new(0,2), NumberSequenceKeypoint.new(1,0.5)})
		blood.Lifetime    = NumberRange.new(1, 2)
		blood.Rate        = 0
		blood.Speed       = NumberRange.new(5, 20)
		blood.SpreadAngle = Vector2.new(0, 180)
		blood.Acceleration = Vector3.new(0, -10, 0)
		blood.Parent      = att
		blood:Emit(GameData.VISUALS.BLOOD_PARTICLES)
		Debris:AddItem(att, 3)
	end

	-- Break welds then scatter parts
	for _, w in ipairs(model:GetDescendants()) do
		if w:IsA("WeldConstraint") or w:IsA("Weld") then w:Destroy() end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored  = false
			p.CanCollide = true
			p.AssemblyLinearVelocity  = Vector3.new(math.random(-10,10), math.random(5,15), math.random(-5,5))
			p.AssemblyAngularVelocity = Vector3.new(math.random(-8,8), math.random(-8,8), math.random(-8,8))
		end
	end
end

return ZombieEffects
