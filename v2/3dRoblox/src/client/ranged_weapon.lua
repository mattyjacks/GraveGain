-- Ranged Weapon - Handles ranged combat
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RangedWeapon = {}
RangedWeapon.__index = RangedWeapon

function RangedWeapon.new(weapon_data, player_data)
	local self = setmetatable({}, RangedWeapon)
	
	self.weapon_data = weapon_data
	self.player_data = player_data
	
	self.damage = weapon_data.damage + player_data.ranged_damage
	self.fire_rate = weapon_data.fire_rate
	self.ammo_per_shot = weapon_data.ammo_per_shot
	self.range = weapon_data.range
	self.accuracy = weapon_data.accuracy
	self.crit_chance = weapon_data.crit_chance
	self.crit_multiplier = weapon_data.crit_multiplier
	self.reload_time = weapon_data.reload_time
	
	self.ammo = 30
	self.max_ammo = 30
	self.fire_cooldown = 0
	self.reload_cooldown = 0
	self.is_reloading = false
	
	-- Visual
	self.weapon_model = nil
	self.muzzle_flash_duration = 0.1
	
	return self
end

function RangedWeapon:equip(camera)
	self.camera = camera
	self:create_weapon_model()
end

function RangedWeapon:create_weapon_model()
	-- Create a simple ranged weapon model (crossbow/gun shape)
	local model = Instance.new("Model")
	model.Name = self.weapon_data.name
	
	-- Stock
	local stock = Instance.new("Part")
	stock.Name = "Stock"
	stock.Shape = Enum.PartType.Block
	stock.Size = Vector3.new(0.2, 0.3, 1.5)
	stock.Color = Color3.fromRGB(139, 69, 19)
	stock.Material = Enum.Material.Wood
	stock.CanCollide = false
	stock.CFrame = CFrame.new(0.5, -0.1, -1)
	stock.Parent = model
	
	-- Barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(0.15, 0.15, 1.2)
	barrel.Color = Color3.fromRGB(50, 50, 50)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.CFrame = CFrame.new(0.5, 0.1, -0.8) * CFrame.Angles(0, 0, math.pi / 2)
	barrel.Parent = model
	
	-- Scope
	local scope = Instance.new("Part")
	scope.Name = "Scope"
	scope.Shape = Enum.PartType.Cylinder
	scope.Size = Vector3.new(0.1, 0.1, 0.5)
	scope.Color = Color3.fromRGB(100, 100, 100)
	scope.Material = Enum.Material.Glass
	scope.CanCollide = false
	scope.CFrame = CFrame.new(0.5, 0.2, -0.5) * CFrame.Angles(0, 0, math.pi / 2)
	scope.Parent = model
	
	model.Parent = self.camera
	self.weapon_model = model
end

function RangedWeapon:fire()
	if self.fire_cooldown > 0 then return end
	if self.is_reloading then return end
	if self.ammo <= 0 then
		self:reload()
		return
	end
	
	self.ammo = self.ammo - self.ammo_per_shot
	self.fire_cooldown = 1.0 / self.fire_rate
	
	self:perform_shot()
	
	if self.ammo <= 0 then
		self:reload()
	end
end

function RangedWeapon:perform_shot()
	-- Play muzzle flash
	self:show_muzzle_flash()
	
	-- Calculate shot with accuracy
	local camera = self.camera
	local ray_origin = camera.CFrame.Position
	local ray_direction = camera.CFrame.LookVector
	
	-- Add inaccuracy
	local inaccuracy = (1.0 - self.accuracy) * 0.1
	ray_direction = ray_direction + Vector3.new(
		(math.random() - 0.5) * inaccuracy,
		(math.random() - 0.5) * inaccuracy,
		(math.random() - 0.5) * inaccuracy
	)
	ray_direction = ray_direction.Unit
	
	-- Raycast
	local ray_result = workspace:FindPartOnRay(Ray.new(ray_origin, ray_direction * self.range))
	
	if ray_result and ray_result.Parent:FindFirstChild("Humanoid") then
		local hit_humanoid = ray_result.Parent:FindFirstChild("Humanoid")
		
		-- Calculate damage
		local damage = self.damage
		if math.random() < self.crit_chance then
			damage = damage * self.crit_multiplier
		end
		
		-- Apply damage
		hit_humanoid:TakeDamage(damage)
		
		-- Apply knockback
		local hit_root = ray_result.Parent:FindFirstChild("HumanoidRootPart")
		if hit_root then
			local knockback_dir = ray_direction
			hit_root.AssemblyLinearVelocity = hit_root.AssemblyLinearVelocity + knockback_dir * 5
		end
	end
end

function RangedWeapon:show_muzzle_flash()
	if not self.weapon_model then return end
	
	-- Create muzzle flash effect
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.3, 0.3, 0.3)
	flash.Color = Color3.fromRGB(255, 150, 0)
	flash.Material = Enum.Material.Neon
	flash.CanCollide = false
	flash.CFrame = self.weapon_model.PrimaryPart.CFrame + self.weapon_model.PrimaryPart.CFrame.LookVector * 2
	flash.Parent = workspace
	
	-- Fade out
	local start_time = tick()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start_time
		local progress = elapsed / self.muzzle_flash_duration
		
		if progress >= 1.0 then
			flash:Destroy()
			connection:Disconnect()
		else
			flash.Transparency = progress
		end
	end)
end

function RangedWeapon:reload()
	if self.is_reloading then return end
	
	self.is_reloading = true
	self.reload_cooldown = self.reload_time
	
	task.wait(self.reload_time)
	
	self.ammo = self.max_ammo
	self.is_reloading = false
end

function RangedWeapon:update(delta_time)
	if self.fire_cooldown > 0 then
		self.fire_cooldown = self.fire_cooldown - delta_time
	end
	
	if self.reload_cooldown > 0 then
		self.reload_cooldown = self.reload_cooldown - delta_time
	end
end

function RangedWeapon:get_ammo_text()
	return string.format("%d / %d", self.ammo, self.max_ammo)
end

function RangedWeapon:cleanup()
	if self.weapon_model then
		self.weapon_model:Destroy()
	end
end

return RangedWeapon
