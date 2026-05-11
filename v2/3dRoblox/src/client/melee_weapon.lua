-- Melee Weapon - Handles melee combat
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MeleeWeapon = {}
MeleeWeapon.__index = MeleeWeapon

function MeleeWeapon.new(weapon_data, player_data)
	local self = setmetatable({}, MeleeWeapon)
	
	self.weapon_data = weapon_data
	self.player_data = player_data
	
	self.damage = weapon_data.damage + player_data.melee_damage
	self.attack_speed = weapon_data.attack_speed
	self.range = weapon_data.range
	self.knockback = weapon_data.knockback
	self.crit_chance = weapon_data.crit_chance
	self.crit_multiplier = weapon_data.crit_multiplier
	
	self.attack_cooldown = 0
	self.is_attacking = false
	self.attack_duration = 0.3
	
	-- Visual
	self.weapon_model = nil
	self.attack_animation_speed = 1.0 / self.attack_speed
	
	return self
end

function MeleeWeapon:equip(camera)
	self.camera = camera
	self:create_weapon_model()
end

function MeleeWeapon:create_weapon_model()
	-- Create a simple weapon model (sword shape)
	local model = Instance.new("Model")
	model.Name = self.weapon_data.name
	
	-- Blade
	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Shape = Enum.PartType.Block
	blade.Size = Vector3.new(0.3, 2, 0.1)
	blade.Color = Color3.fromRGB(200, 200, 200)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.CFrame = CFrame.new(0.5, 0, -1)
	blade.Parent = model
	
	-- Handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.2, 0.8, 0.2)
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CFrame = CFrame.new(0.5, -0.5, -0.5)
	handle.Parent = model
	
	-- Guard
	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Shape = Enum.PartType.Block
	guard.Size = Vector3.new(1, 0.2, 0.2)
	guard.Color = Color3.fromRGB(184, 134, 11)
	guard.Material = Enum.Material.Metal
	guard.CanCollide = false
	guard.CFrame = CFrame.new(0.5, 0, -0.5)
	guard.Parent = model
	
	model.Parent = self.camera
	self.weapon_model = model
end

function MeleeWeapon:fire()
	if self.attack_cooldown > 0 then return end
	if self.is_attacking then return end
	
	self.is_attacking = true
	self.attack_cooldown = 1.0 / self.attack_speed
	
	self:perform_attack()
	
	task.wait(self.attack_duration)
	self.is_attacking = false
end

function MeleeWeapon:perform_attack()
	-- Play attack animation
	if self.weapon_model then
		self:play_attack_animation()
	end
	
	-- Raycast for hit detection
	local camera = self.camera
	local ray_origin = camera.CFrame.Position
	local ray_direction = camera.CFrame.LookVector * self.range
	
	local ray_result = workspace:FindPartOnRay(Ray.new(ray_origin, ray_direction))
	
	if ray_result and ray_result.Parent:FindFirstChild("Humanoid") then
		local hit_humanoid = ray_result.Parent:FindFirstChild("Humanoid")
		
		-- Calculate damage
		local damage = self.damage
		if math.random() < self.crit_chance then
			damage = damage * self.crit_multiplier
		end
		
		-- Apply damage (server-side in real implementation)
		hit_humanoid:TakeDamage(damage)
		
		-- Apply knockback
		local hit_root = ray_result.Parent:FindFirstChild("HumanoidRootPart")
		if hit_root then
			local knockback_dir = (hit_root.Position - ray_origin).Unit
			hit_root.AssemblyLinearVelocity = hit_root.AssemblyLinearVelocity + knockback_dir * self.knockback
		end
	end
end

function MeleeWeapon:play_attack_animation()
	if not self.weapon_model then return end
	
	-- Simple rotation animation
	local start_time = tick()
	local duration = self.attack_duration
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = math.min(elapsed / duration, 1.0)
		
		-- Swing animation
		local swing_angle = progress * math.pi
		self.weapon_model:SetPrimaryPartCFrame(
			CFrame.new(0.5, -0.2, -1) * CFrame.Angles(swing_angle, 0, 0)
		)
		
		if progress >= 1.0 then
			connection:Disconnect()
		end
	end)
end

function MeleeWeapon:update(delta_time)
	if self.attack_cooldown > 0 then
		self.attack_cooldown = self.attack_cooldown - delta_time
	end
end

function MeleeWeapon:cleanup()
	if self.weapon_model then
		self.weapon_model:Destroy()
	end
end

return MeleeWeapon
