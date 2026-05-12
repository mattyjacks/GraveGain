local RunService = game:GetService("RunService")

local AudioVFXManager = {}
AudioVFXManager.__index = AudioVFXManager

function AudioVFXManager.new()
	local self = setmetatable({}, AudioVFXManager)
	
	self.soundEffects = {}
	self.particles = {}
	self.damageNumbers = {}
	
	return self
end

function AudioVFXManager:playSoundEffect(name, volume, pitch)
	volume = volume or 0.5
	pitch = pitch or 1.0
	
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.Volume = volume
	sound.PlayOnRemove = false
	sound.Parent = workspace
	
	table.insert(self.soundEffects, sound)
	
	return sound
end

function AudioVFXManager:createHitEffect(position, damageType)
	damageType = damageType or "Physical"
	
	local colors = {
		Physical = Color3.fromRGB(255, 200, 100),
		Fire = Color3.fromRGB(255, 100, 0),
		Ice = Color3.fromRGB(100, 200, 255),
		Lightning = Color3.fromRGB(255, 255, 0),
		Poison = Color3.fromRGB(100, 255, 100),
		Holy = Color3.fromRGB(255, 255, 200),
		Dark = Color3.fromRGB(100, 100, 150),
	}
	
	local color = colors[damageType] or colors.Physical
	
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Color = color
	part.CanCollide = false
	part.CFrame = CFrame.new(position)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = workspace
	
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = Vector3.new(math.random(-5, 5), math.random(5, 15), math.random(-5, 5))
	velocity.Parent = part
	
	game:GetService("Debris"):AddItem(part, 0.5)
	
	return part
end

function AudioVFXManager:createDamageNumber(position, damage, isCrit)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(4, 0, 2, 0)
	billboardGui.MaxDistance = 100
	billboardGui.Parent = workspace
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = tostring(math.floor(damage))
	textLabel.TextColor3 = isCrit and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(255, 255, 255)
	textLabel.Parent = billboardGui
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, 10, 0)
	bodyVelocity.Parent = billboardGui
	
	local part = Instance.new("Part")
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(position)
	part.Parent = workspace
	
	billboardGui.Adornee = part
	
	game:GetService("Debris"):AddItem(part, 2)
	game:GetService("Debris"):AddItem(billboardGui, 2)
	
	return billboardGui
end

function AudioVFXManager:createExplosion(position, radius, color)
	color = color or Color3.fromRGB(255, 100, 0)
	
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(0.1, 0.1, 0.1)
	explosion.Color = color
	explosion.CanCollide = false
	explosion.CFrame = CFrame.new(position)
	explosion.TopSurface = Enum.SurfaceType.Smooth
	explosion.BottomSurface = Enum.SurfaceType.Smooth
	explosion.Parent = workspace
	
	local startSize = 0.1
	local maxSize = radius * 2
	local duration = 0.3
	local elapsed = 0
	
	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		elapsed = elapsed + deltaTime
		local progress = elapsed / duration
		
		if progress >= 1 then
			connection:Disconnect()
			explosion:Destroy()
			return
		end
		
		local size = startSize + (maxSize - startSize) * progress
		explosion.Size = Vector3.new(size, size, size)
		explosion.Transparency = progress
	end)
	
	return explosion
end

function AudioVFXManager:createScreenShake(intensity, duration)
	local camera = workspace.CurrentCamera
	local originalCFrame = camera.CFrame
	
	local elapsed = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		elapsed = elapsed + deltaTime
		
		if elapsed >= duration then
			connection:Disconnect()
			camera.CFrame = originalCFrame
			return
		end
		
		local progress = 1 - (elapsed / duration)
		local shakeAmount = intensity * progress
		
		local offset = Vector3.new(
			(math.random() - 0.5) * shakeAmount,
			(math.random() - 0.5) * shakeAmount,
			(math.random() - 0.5) * shakeAmount
		)
		
		camera.CFrame = originalCFrame * CFrame.new(offset)
	end)
end

function AudioVFXManager:createAuraEffect(position, color, radius)
	color = color or Color3.fromRGB(100, 200, 255)
	
	local aura = Instance.new("Part")
	aura.Shape = Enum.PartType.Ball
	aura.Size = Vector3.new(radius, radius, radius)
	aura.Color = color
	aura.Material = Enum.Material.Neon
	aura.CanCollide = false
	aura.CFrame = CFrame.new(position)
	aura.TopSurface = Enum.SurfaceType.Smooth
	aura.BottomSurface = Enum.SurfaceType.Smooth
	aura.Transparency = 0.5
	aura.Parent = workspace
	
	return aura
end

function AudioVFXManager:playAmbientSound(biome)
	local soundMap = {
		Crypt = "rbxassetid://1234567890",
		Forest = "rbxassetid://1234567891",
		Cave = "rbxassetid://1234567892",
		Hellscape = "rbxassetid://1234567893",
		Ruins = "rbxassetid://1234567894",
	}
	
	local soundId = soundMap[biome] or soundMap.Crypt
	
	local sound = self:playSoundEffect("Ambient_" .. biome, 0.3, 1.0)
	sound.SoundId = soundId
	sound.Looped = true
	sound:Play()
	
	return sound
end

return AudioVFXManager
