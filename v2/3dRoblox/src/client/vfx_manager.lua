-- VFX Manager - Handles visual effects and particles
local RunService = game:GetService("RunService")

local VFXManager = {}
VFXManager.__index = VFXManager

function VFXManager.new()
	local self = setmetatable({}, VFXManager)
	
	self.vfx_folder = nil
	self.active_effects = {}
	
	return self
end

function VFXManager:initialize()
	self.vfx_folder = Instance.new("Folder")
	self.vfx_folder.Name = "VFX"
	self.vfx_folder.Parent = workspace
	
	print("[VFXManager] Initialized")
end

function VFXManager:create_hit_effect(position, color, intensity)
	color = color or Color3.fromRGB(255, 100, 100)
	intensity = intensity or 1.0
	
	local effect = Instance.new("Part")
	effect.Name = "HitEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(0.5, 0.5, 0.5) * intensity
	effect.Color = color
	effect.Material = Enum.Material.Neon
	effect.CanCollide = false
	effect.CFrame = CFrame.new(position)
	effect.Parent = self.vfx_folder
	
	local start_time = tick()
	local duration = 0.3
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			effect:Destroy()
			connection:Disconnect()
		else
			effect.Transparency = progress
			effect.Size = Vector3.new(0.5, 0.5, 0.5) * intensity * (1 + progress)
		end
	end)
end

function VFXManager:create_blood_splatter(position, color, count)
	color = color or Color3.fromRGB(200, 0, 0)
	count = count or 5
	
	for _ = 1, count do
		local particle = Instance.new("Part")
		particle.Name = "BloodParticle"
		particle.Shape = Enum.PartType.Ball
		particle.Size = Vector3.new(0.2, 0.2, 0.2)
		particle.Color = color
		particle.Material = Enum.Material.SmoothPlastic
		particle.CanCollide = false
		particle.CFrame = CFrame.new(position)
		particle.Parent = self.vfx_folder
		
		local velocity = Vector3.new(
			(math.random() - 0.5) * 20,
			math.random() * 15,
			(math.random() - 0.5) * 20
		)
		particle.AssemblyLinearVelocity = velocity
		
		local start_time = tick()
		local duration = 1.5
		
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - start_time
			local progress = elapsed / duration
			
			if progress >= 1.0 then
				particle:Destroy()
				connection:Disconnect()
			else
				particle.Transparency = progress * 0.8
			end
		end)
	end
end

function VFXManager:create_heal_effect(position)
	local effect = Instance.new("Part")
	effect.Name = "HealEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(1, 1, 1)
	effect.Color = Color3.fromRGB(100, 255, 100)
	effect.Material = Enum.Material.Neon
	effect.CanCollide = false
	effect.CFrame = CFrame.new(position)
	effect.Parent = self.vfx_folder
	
	local start_time = tick()
	local duration = 0.5
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			effect:Destroy()
			connection:Disconnect()
		else
			effect.Transparency = progress
			effect.Size = Vector3.new(1, 1, 1) * (1 + progress * 2)
		end
	end)
end

function VFXManager:create_critical_hit_effect(position)
	-- Create a burst effect
	local burst = Instance.new("Part")
	burst.Name = "CriticalHitBurst"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(0.8, 0.8, 0.8)
	burst.Color = Color3.fromRGB(255, 200, 0)
	burst.Material = Enum.Material.Neon
	burst.CanCollide = false
	burst.CFrame = CFrame.new(position)
	burst.Parent = self.vfx_folder
	
	local start_time = tick()
	local duration = 0.4
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			burst:Destroy()
			connection:Disconnect()
		else
			burst.Transparency = progress
			burst.Size = Vector3.new(0.8, 0.8, 0.8) * (1 + progress * 3)
		end
	end)
	
	-- Create surrounding particles
	for _ = 1, 8 do
		local particle = Instance.new("Part")
		particle.Name = "CritParticle"
		particle.Shape = Enum.PartType.Ball
		particle.Size = Vector3.new(0.3, 0.3, 0.3)
		particle.Color = Color3.fromRGB(255, 200, 0)
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.CFrame = CFrame.new(position)
		particle.Parent = self.vfx_folder
		
		local angle = (math.pi * 2 / 8) * _
		local velocity = Vector3.new(
			math.cos(angle) * 25,
			math.random() * 10,
			math.sin(angle) * 25
		)
		particle.AssemblyLinearVelocity = velocity
		
		local start_time = tick()
		local duration = 0.6
		
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - start_time
			local progress = elapsed / duration
			
			if progress >= 1.0 then
				particle:Destroy()
				connection:Disconnect()
			else
				particle.Transparency = progress
			end
		end)
	end
end

function VFXManager:create_loot_pickup_effect(position, rarity_color)
	rarity_color = rarity_color or Color3.fromRGB(100, 200, 100)
	
	local effect = Instance.new("Part")
	effect.Name = "LootPickupEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(0.6, 0.6, 0.6)
	effect.Color = rarity_color
	effect.Material = Enum.Material.Neon
	effect.CanCollide = false
	effect.CFrame = CFrame.new(position)
	effect.Parent = self.vfx_folder
	
	local start_time = tick()
	local duration = 0.4
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			effect:Destroy()
			connection:Disconnect()
		else
			effect.Transparency = progress
			effect.Size = Vector3.new(0.6, 0.6, 0.6) * (1 - progress * 0.5)
		end
	end)
end

function VFXManager:create_muzzle_flash(position, direction)
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.4, 0.4, 0.4)
	flash.Color = Color3.fromRGB(255, 150, 0)
	flash.Material = Enum.Material.Neon
	flash.CanCollide = false
	flash.CFrame = CFrame.new(position) * CFrame.new(direction * 2)
	flash.Parent = self.vfx_folder
	
	local start_time = tick()
	local duration = 0.1
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			flash:Destroy()
			connection:Disconnect()
		else
			flash.Transparency = progress
		end
	end)
end

function VFXManager:create_damage_number(position, damage, is_crit)
	local color = is_crit and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 100, 100)
	local size = is_crit and 20 or 14
	
	local text_label = Instance.new("TextLabel")
	text_label.Name = "DamageNumber"
	text_label.Size = UDim2.new(2, 0, 1, 0)
	text_label.Position = UDim2.new(-0.5, 0, 0, 0)
	text_label.BackgroundTransparency = 1
	text_label.TextColor3 = color
	text_label.TextSize = size
	text_label.Font = Enum.Font.GothamBold
	text_label.Text = is_crit and "CRIT " .. math.floor(damage) or math.floor(damage)
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumberBillboard"
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.MaxDistance = 100
	billboard.Parent = workspace
	
	text_label.Parent = billboard
	
	local start_time = tick()
	local duration = 1.0
	local start_pos = position
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			billboard:Destroy()
			connection:Disconnect()
		else
			billboard.Adornee = nil
			billboard.StudsOffset = (start_pos + Vector3.new(0, progress * 3, 0)) - position
			text_label.Transparency = progress
		end
	end)
end

function VFXManager:create_wave_indicator(wave_number)
	local player = game:GetService("Players").LocalPlayer
	local player_gui = player:WaitForChild("PlayerGui")
	
	local wave_label = Instance.new("TextLabel")
	wave_label.Name = "WaveIndicator"
	wave_label.Size = UDim2.new(0.3, 0, 0.1, 0)
	wave_label.Position = UDim2.new(0.35, 0, 0.05, 0)
	wave_label.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	wave_label.BackgroundTransparency = 0.3
	wave_label.BorderSizePixel = 1
	wave_label.BorderColor3 = Color3.fromRGB(200, 100, 100)
	wave_label.TextColor3 = Color3.fromRGB(255, 100, 100)
	wave_label.TextSize = 32
	wave_label.Font = Enum.Font.GothamBold
	wave_label.Text = "WAVE " .. wave_number
	wave_label.Parent = player_gui
	
	local start_time = tick()
	local duration = 2.0
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / duration
		
		if progress >= 1.0 then
			wave_label:Destroy()
			connection:Disconnect()
		else
			wave_label.BackgroundTransparency = 0.3 + progress * 0.7
			wave_label.TextTransparency = progress
		end
	end)
end

function VFXManager:cleanup()
	if self.vfx_folder then
		self.vfx_folder:Destroy()
	end
end

return VFXManager
