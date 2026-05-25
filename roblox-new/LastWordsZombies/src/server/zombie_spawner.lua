-- Zombie spawner and management system
-- Handles zombie creation, movement, and word assignment

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WordDictionary = require(ReplicatedStorage:WaitForChild("WordDictionary"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local ZombieSpawner = {}

-- Zombie storage
ZombieSpawner.ActiveZombies = {}
ZombieSpawner.ZombieModels = {}
ZombieSpawner.NextSpawnTime = 0
ZombieSpawner.WaveNumber = 1
ZombieSpawner.ZombiesSpawnedThisWave = 0
ZombieSpawner.SpawnPosition = Vector3.new(0, 0, -150) -- Far end of corridor
ZombieSpawner.CoverPositions = {} -- populated by main.server after corridor creation

-- Zombie appearance configuration
local ZombieConfig = {
	Colors = {
		Body = Color3.new(0.3, 0.2, 0.2), -- Dark brown/grey
		Eyes = Color3.new(1, 0, 0), -- Red eyes
		Clothing = Color3.new(0.1, 0.1, 0.1) -- Black clothing
	},
	Sizes = {
		Min = Vector3.new(0.8, 1.7, 0.8),
		Max = Vector3.new(1.2, 2.0, 1.2)
	}
}

-- Create zombie model
function ZombieSpawner.CreateZombieModel(isBigWord)
	local zombie = Instance.new("Model")
	zombie.Name = isBigWord and "BigWordZombie" or "Zombie"

	-- Big Word zombies are 1.6x larger with purple color scheme
	local bigScale = isBigWord and 1.6 or 1.0

	-- Random size variation applied BEFORE welding
	local scaleX = (math.random(80, 120) / 100) * bigScale
	local scaleY = (math.random(85, 115) / 100) * bigScale
	local scaleZ = scaleX

	local function makePart(name, size, color, material, parent)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(size.X * scaleX, size.Y * scaleY, size.Z * scaleZ)
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or zombie
		return p
	end

	-- Big Word zombies use a dark purple color
	local bodyColor = isBigWord and Color3.new(0.35, 0.1, 0.5) or ZombieConfig.Colors.Body
	local eyeColor = isBigWord and Color3.new(0.8, 0, 1) or ZombieConfig.Colors.Eyes
	local clothColor = isBigWord and Color3.new(0.2, 0.05, 0.35) or ZombieConfig.Colors.Clothing

	-- Main body (PrimaryPart)
	local torso = makePart("Torso", Vector3.new(2, 2, 1), bodyColor, Enum.Material.Plastic)
	zombie.PrimaryPart = torso

	-- Head
	local head = makePart("Head", Vector3.new(1.5, 1.5, 1.5), bodyColor, Enum.Material.Plastic)

	-- Eyes (glowing parts)
	local leftEye = makePart("LeftEye", Vector3.new(0.3, 0.3, 0.1), eyeColor, Enum.Material.Neon)
	local rightEye = makePart("RightEye", Vector3.new(0.3, 0.3, 0.1), eyeColor, Enum.Material.Neon)

	-- Arms
	local leftArm = makePart("LeftArm", Vector3.new(0.8, 2, 0.8), bodyColor, Enum.Material.Plastic)
	local rightArm = makePart("RightArm", Vector3.new(0.8, 2, 0.8), bodyColor, Enum.Material.Plastic)

	-- Legs
	local leftLeg = makePart("LeftLeg", Vector3.new(0.8, 2.5, 0.8), clothColor, Enum.Material.Plastic)
	local rightLeg = makePart("RightLeg", Vector3.new(0.8, 2.5, 0.8), clothColor, Enum.Material.Plastic)

	-- Position all parts relative to torso origin (0,0,0), then weld
	-- torso center = 0,0,0 (reference)
	local torsoHalfY = torso.Size.Y / 2
	local headHalfY = head.Size.Y / 2
	local armHalfY = leftArm.Size.Y / 2
	local legHalfY = leftLeg.Size.Y / 2

	local partOffsets = {
		{head,     CFrame.new(0,  torsoHalfY + headHalfY, 0)},
		{leftArm,  CFrame.new(-(torso.Size.X/2 + leftArm.Size.X/2),  torsoHalfY - armHalfY, 0)},
		{rightArm, CFrame.new( (torso.Size.X/2 + rightArm.Size.X/2), torsoHalfY - armHalfY, 0)},
		{leftLeg,  CFrame.new(-torso.Size.X/4, -(torsoHalfY + legHalfY), 0)},
		{rightLeg, CFrame.new( torso.Size.X/4, -(torsoHalfY + legHalfY), 0)},
		{leftEye,  CFrame.new(-0.3 * scaleX, 0.2 * scaleY, -(head.Size.Z/2 + 0.01))},
		{rightEye, CFrame.new( 0.3 * scaleX, 0.2 * scaleY, -(head.Size.Z/2 + 0.01))},
	}

	torso.CFrame = CFrame.new(0, 0, 0)
	for _, data in ipairs(partOffsets) do
		local part, offset = data[1], data[2]
		part.CFrame = torso.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = part
		weld.Parent = torso
	end

	-- Eye light (purple for big word)
	local eyeLight = Instance.new("PointLight")
	eyeLight.Color = isBigWord and Color3.new(0.6, 0, 1) or Color3.new(1, 0, 0)
	eyeLight.Brightness = isBigWord and 4 or 2
	eyeLight.Range = isBigWord and 14 or 8
	eyeLight.Parent = torso

	-- Crown for Big Word zombies
	if isBigWord then
		local crown = makePart("Crown", Vector3.new(1.6 * scaleX, 0.4 * scaleY, 1.6 * scaleZ), Color3.new(0.8, 0.6, 0), Enum.Material.Neon)
		local headHY = head.Size.Y / 2
		crown.CFrame = head.CFrame * CFrame.new(0, headHY + 0.2 * scaleY, 0)
		local crownWeld = Instance.new("WeldConstraint")
		crownWeld.Part0 = torso
		crownWeld.Part1 = crown
		crownWeld.Parent = torso
	end

	return zombie
end

-- Create word display above zombie
function ZombieSpawner.CreateWordDisplay(zombie, word)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WordDisplay"
	billboard.Size = UDim2.new(0, 240, 0, 56)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	billboard.Parent = zombie:FindFirstChild("Head") or zombie.PrimaryPart
	
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.25
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.new(0.8, 0, 0)
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.new(1, -12, 1, -10)
	label.Position = UDim2.new(0, 6, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = word
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = frame
	
	return billboard
end

-- Spawn new zombie
function ZombieSpawner.SpawnZombie()
	if #ZombieSpawner.ActiveZombies >= GameData.ZOMBIE.MAX_ZOMBIES then
		return false
	end
	
	-- Get wave settings
	local waveSettings = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)

	-- 20% chance of Big Word zombie (harder word, bigger model)
	local isBigWord = math.random() < 0.20

	-- Get random word - Big Word uses next difficulty tier
	local difficulty = waveSettings.wordDifficulty
	if isBigWord then
		local tiers = {"Easy", "Medium", "Hard", "Extreme"}
		for i, tier in ipairs(tiers) do
			if tier == difficulty then
				difficulty = tiers[math.min(i + 1, #tiers)]
				break
			end
		end
	end
	local word = WordDictionary.GetRandomWord(difficulty)
	
	-- Create zombie
	local zombie = ZombieSpawner.CreateZombieModel(isBigWord)
	
	-- Decide spawn position: 40% chance near cover, 60% open spawn
	local spawnX, spawnY, spawnZ
	spawnY = 3
	local covers = ZombieSpawner.CoverPositions
	if #covers > 0 and math.random() < 0.4 then
		local pick = covers[math.random(1, #covers)]
		spawnX = pick.X + math.random(-3, 3)
		spawnZ = pick.Z
	else
		local halfWidth = math.floor(GameData.VISUALS.CORRIDOR_WIDTH / 2) - 4
		spawnX = math.random(-halfWidth, halfWidth)
		local zStagger = (#ZombieSpawner.ActiveZombies % 8) * 4
		spawnZ = ZombieSpawner.SpawnPosition.Z - zStagger + math.random(-5, 5)
	end

	zombie:SetPrimaryPartCFrame(CFrame.new(spawnX, spawnY, spawnZ) * CFrame.Angles(0, math.pi, 0))
	
	-- Parent to workspace
	zombie.Parent = workspace
	
	-- Add word display
	local wordDisplay = ZombieSpawner.CreateWordDisplay(zombie, word)
	
	-- Create zombie data
	local zombieData = {
		Model = zombie,
		Word = word,
		WordDisplay = wordDisplay,
		Speed = waveSettings.zombieSpeed,
		Health = GameData.ZOMBIE.HEALTH,
		IsAlive = true,
		SpawnTime = tick(),
		TypedLetters = "",
		Targeted = false
	}
	
	-- Add to active zombies
	table.insert(ZombieSpawner.ActiveZombies, zombieData)
	ZombieSpawner.ZombiesSpawnedThisWave = ZombieSpawner.ZombiesSpawnedThisWave + 1
	
	-- Start movement
	ZombieSpawner.StartZombieMovement(zombieData)
	
	return zombieData
end

-- Start zombie movement toward camera
function ZombieSpawner.StartZombieMovement(zombieData)
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not zombieData.IsAlive then
			connection:Disconnect()
			return
		end
		local model = zombieData.Model
		if not model or not model.Parent or not model.PrimaryPart then
			connection:Disconnect()
			return
		end
		
		local currentPos = model.PrimaryPart.Position

		-- Already past the player - trigger game over
		if currentPos.Z >= 12 then
			ZombieSpawner.OnZombieReachedCamera(zombieData)
			return
		end

		-- Bob offset for shambling look
		local bobOffset = math.sin(tick() * 6) * 0.05

		-- Advance straight along Z toward positive (camera end)
		local newPos = Vector3.new(
			currentPos.X,
			3 + bobOffset,
			currentPos.Z + zombieData.Speed * deltaTime
		)
		model:SetPrimaryPartCFrame(CFrame.new(newPos) * CFrame.Angles(0, math.pi, 0))
	end)
	
	zombieData.MovementConnection = connection
end

-- Callback set by main.server.lua so it can pass real score + words
ZombieSpawner.OnGameOver = nil

-- Handle zombie reaching camera
function ZombieSpawner.OnZombieReachedCamera(zombieData)
	if not zombieData.IsAlive then return end
	zombieData.IsAlive = false -- prevent repeated triggers
	if zombieData.MovementConnection then
		zombieData.MovementConnection:Disconnect()
	end
	-- Delegate to main server so it can send real score + words
	if ZombieSpawner.OnGameOver then
		ZombieSpawner.OnGameOver("zombie_reached")
	else
		game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GameOver"):FireAllClients("zombie_reached", 0, {})
	end
end

-- Update zombie word display (show typed letters)
function ZombieSpawner.UpdateZombieWord(zombieData, typedLetters)
	zombieData.TypedLetters = typedLetters
	
	if zombieData.WordDisplay and zombieData.WordDisplay:FindFirstChild("Frame") then
		local label = zombieData.WordDisplay.Frame:FindFirstChild("TextLabel")
		if label then
			local fullWord = zombieData.Word
			local displayText = ""
			
			for i = 1, #fullWord do
				local char = fullWord:sub(i, i)
				if i <= #typedLetters then
					-- Show typed letters in green
					displayText = displayText .. '<font color="rgb(0,255,0)">' .. char .. '</font>'
				else
					-- Show untyped letters in white
					displayText = displayText .. char
				end
			end
			
			label.RichText = true
			label.Text = displayText
		end
	end
end

-- Destroy zombie with explosion
function ZombieSpawner.DestroyZombie(zombieData, explosionPosition)
	if not zombieData.IsAlive then return end
	
	zombieData.IsAlive = false
	
	-- Disconnect movement
	if zombieData.MovementConnection then
		zombieData.MovementConnection:Disconnect()
	end
	
	-- Create explosion effect
	ZombieSpawner.CreateExplosion(explosionPosition or zombieData.Model.PrimaryPart.Position)
	
	-- Convert to ragdoll
	ZombieSpawner.CreateRagdoll(zombieData)
	
	-- Remove from active zombies
	for i, z in ipairs(ZombieSpawner.ActiveZombies) do
		if z == zombieData then
			table.remove(ZombieSpawner.ActiveZombies, i)
			break
		end
	end
	
	-- Clean up after delay
	Debris:AddItem(zombieData.Model, GameData.ZOMBIE.RAGDOLL_DURATION)
end

-- Create explosion effect
function ZombieSpawner.CreateExplosion(position)
	-- Visual explosion
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = GameData.EXPLOSION.RADIUS
	explosion.BlastPressure = GameData.EXPLOSION.PRESSURE
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Parent = workspace
	
	-- Custom particle effects
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(GameData.VISUALS.EXPLOSION_COLOR)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Lifetime = NumberRange.new(0.5, 1.0)
	particles.Rate = 100
	particles.Enabled = true
	particles.Speed = NumberRange.new(10, 50)
	particles.SpreadAngle = Vector2.new(0, 360)
	particles.Parent = workspace.Terrain or workspace
	
	-- Emit particles
	particles:Emit(GameData.VISUALS.EXPLOSION_PARTICLES)
	
	-- Remove particles after emission
	game:GetService("Debris"):AddItem(particles, 2)
	
	-- Apply knockback to nearby zombies
	ZombieSpawner.ApplyKnockback(position)
end

-- Apply knockback to nearby zombies
function ZombieSpawner.ApplyKnockback(explosionPosition)
	local blastRadius = GameData.EXPLOSION.RADIUS
	local blastPressure = GameData.EXPLOSION.PRESSURE
	
	for _, zombieData in ipairs(ZombieSpawner.ActiveZombies) do
		if not zombieData.IsAlive then continue end
		
		local zombiePos = zombieData.Model.PrimaryPart.Position
		local distance = (zombiePos - explosionPosition).Magnitude
		
		if distance <= blastRadius then
			-- Calculate knockback force
			local direction = (zombiePos - explosionPosition).Unit
			local forceMultiplier = (1 - distance / blastRadius) * GameData.EXPLOSION.KNOCKBACK_MULTIPLIER
			local knockbackForce = direction * blastPressure * forceMultiplier
			
			-- Apply impulse to zombie
			local rootPart = zombieData.Model.PrimaryPart
			if rootPart and rootPart.CanCollide then
				-- Make zombie unanchored for physics
				rootPart.Anchored = false
				
				-- Apply impulse
				local assembly = rootPart:FindFirstChildWhichIsA("BasePart")
				if assembly then
					assembly:ApplyImpulse(knockbackForce * assembly.AssemblyMass)
				end
				
				-- Re-anchor after a short delay
				task.delay(0.5, function()
					if rootPart and rootPart.Parent then
						rootPart.Anchored = true
					end
				end)
			end
		end
	end
end

-- Create ragdoll effect
function ZombieSpawner.CreateRagdoll(zombieData)
	local zombie = zombieData.Model
	
	-- Blood effect before breaking welds
	local primaryPart = zombie.PrimaryPart
	if primaryPart then
		ZombieSpawner.CreateBloodEffect(primaryPart.Position)
	end

	-- Break welds first, then unanchor so parts scatter
	for _, weld in ipairs(zombie:GetDescendants()) do
		if weld:IsA("WeldConstraint") or weld:IsA("Weld") then
			weld:Destroy()
		end
	end

	-- Unanchor all parts and apply random impulse
	for _, part in ipairs(zombie:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
			part.AssemblyLinearVelocity = Vector3.new(
				math.random(-10, 10),
				math.random(5, 15),
				math.random(-5, 5)
			)
			part.AssemblyAngularVelocity = Vector3.new(
				math.random(-8, 8),
				math.random(-8, 8),
				math.random(-8, 8)
			)
		end
	end
end

-- Create blood particle effect
function ZombieSpawner.CreateBloodEffect(position)
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(GameData.VISUALS.BLOOD_COLOR)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	particles.Lifetime = NumberRange.new(1.0, 2.0)
	particles.Rate = 50
	particles.Enabled = true
	particles.Speed = NumberRange.new(5, 20)
	particles.SpreadAngle = Vector2.new(0, 180)
	particles.Acceleration = Vector3.new(0, -10, 0) -- Gravity
	
	-- Create attachment for particles
	local attachment = Instance.new("Attachment")
	attachment.Position = position
	attachment.Parent = workspace.Terrain or workspace
	particles.Parent = attachment
	
	-- Emit particles
	particles:Emit(GameData.VISUALS.BLOOD_PARTICLES)
	
	-- Clean up
	game:GetService("Debris"):AddItem(attachment, 3)
end

-- Update spawner (called each frame)
function ZombieSpawner.Update(deltaTime)
	local currentTime = tick()
	local waveSettings = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)
	
	-- Check if it's time to spawn
	if currentTime >= ZombieSpawner.NextSpawnTime then
		if ZombieSpawner.SpawnZombie() then
			-- Schedule next spawn
			ZombieSpawner.NextSpawnTime = currentTime + waveSettings.spawnRate
		end
	end
	
	-- Check wave completion
	if ZombieSpawner.ZombiesSpawnedThisWave >= waveSettings.zombiesPerWave then
		if #ZombieSpawner.ActiveZombies == 0 then
			ZombieSpawner.CompleteWave()
		end
	end
end

-- Complete current wave
function ZombieSpawner.CompleteWave()
	ZombieSpawner.WaveNumber = ZombieSpawner.WaveNumber + 1
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	
	-- Notify clients
	game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WaveComplete"):FireAllClients(ZombieSpawner.WaveNumber)
end

-- Get zombie data by Model instance
function ZombieSpawner.GetZombieByModel(model)
	if not model then return nil end
	for _, zombieData in ipairs(ZombieSpawner.ActiveZombies) do
		if zombieData.Model == model then
			return zombieData
		end
	end
	return nil
end

-- Get closest zombie matching first letter
function ZombieSpawner.GetClosestZombieByLetter(firstLetter)
	local closestZombie = nil
	local closestDistance = math.huge
	
	for _, zombieData in ipairs(ZombieSpawner.ActiveZombies) do
		if not zombieData.IsAlive then continue end
		
		-- Check if word starts with the letter
		if zombieData.Word:sub(1, 1):lower() == firstLetter:lower() then
			local zombiePos = zombieData.Model.PrimaryPart.Position
			local distance = zombiePos.Magnitude -- Distance from origin (camera)
			
			if distance < closestDistance then
				closestDistance = distance
				closestZombie = zombieData
			end
		end
	end
	
	return closestZombie
end

-- Clean up all zombies
function ZombieSpawner.Cleanup()
	for _, zombieData in ipairs(ZombieSpawner.ActiveZombies) do
		if zombieData.MovementConnection then
			zombieData.MovementConnection:Disconnect()
		end
		if zombieData.Model then
			zombieData.Model:Destroy()
		end
	end
	
	ZombieSpawner.ActiveZombies = {}
	ZombieSpawner.ZombiesSpawnedThisWave = 0
end

return ZombieSpawner
