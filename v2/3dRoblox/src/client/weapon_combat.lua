-- Weapon Combat System
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local WeaponCombat = {}
WeaponCombat.__index = WeaponCombat

local player = Players.LocalPlayer
local character
local humanoid_root_part
local humanoid
local weapon_model
local secondary_weapon_model

local is_attacking = false
local is_blocking = false
local attack_cooldown = 0
local block_cooldown = 0
local current_weapon = 1  -- 1 = primary, 2 = secondary

-- Animation timings (in seconds)
local ATTACK_DURATION = 0.6
local BLOCK_DURATION = 0.4
local PUSH_DURATION = 0.5
local PUSH_ATTACK_DURATION = 0.8

-- Weapon-specific attack patterns
local WEAPON_ATTACKS = {
	human = {
		name = "Laser Rifle",
		type = "ranged",
		attack_duration = 0.4,
		attack_animation = "rifle_burst",
		block_animation = "rifle_aim",
		push_animation = "rifle_shove",
		push_attack_animation = "rifle_charged_shot"
	},
	elf = {
		name = "Elven Bow",
		type = "ranged",
		attack_duration = 0.5,
		attack_animation = "bow_draw_release",
		block_animation = "bow_ready",
		push_animation = "bow_bash",
		push_attack_animation = "bow_power_shot"
	},
	dwarf = {
		name = "Crossbow",
		type = "ranged",
		attack_duration = 0.6,
		attack_animation = "crossbow_fire",
		block_animation = "crossbow_brace",
		push_animation = "crossbow_strike",
		push_attack_animation = "crossbow_piercing_shot"
	},
	orc = {
		name = "Orc Axe",
		type = "melee",
		attack_duration = 0.7,
		attack_animation = "axe_swing",
		block_animation = "axe_guard",
		push_animation = "axe_shove",
		push_attack_animation = "axe_overhead_slam"
	}
}

function WeaponCombat:initialize(char, weapon, secondary_weapon)
	print("[WeaponCombat] Initializing combat system...")
	
	character = char
	humanoid_root_part = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
	weapon_model = weapon
	secondary_weapon_model = secondary_weapon
	
	-- Get race and class from character
	local race = character:GetAttribute("SelectedRace") or "human"
	local class_type = character:GetAttribute("SelectedClass") or "dps"
	local weapon_config = WEAPON_ATTACKS[race]
	
	if not weapon_config then
		print("[WeaponCombat] ERROR: No weapon config for race: " .. race)
		return
	end
	
	print("[WeaponCombat] Primary Weapon: " .. weapon_config.name .. " (" .. weapon_config.type .. ")")
	print("[WeaponCombat] Secondary Weapon: " .. (weapon_config.melee or weapon_config.ranged or "None"))
	
	-- Hide secondary weapon initially
	if secondary_weapon_model then
		for _, part in ipairs(secondary_weapon_model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end
	
	-- Setup input handling
	self:setup_input_handling(weapon_config)
	
	-- Setup animation loop
	RunService.RenderStepped:Connect(function(dt)
		self:update_combat(dt, weapon_config)
	end)
	
	print("[WeaponCombat] Combat system ready - Press 1 or 2 to switch weapons")
end

function WeaponCombat:setup_input_handling(weapon_config)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Left click: Attack or Push (if blocking)
			if is_blocking then
				-- Push while blocking
				self:perform_push(weapon_config)
			else
				-- Normal attack
				self:perform_attack(weapon_config)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			-- Right click: Start blocking
			is_blocking = true
			self:play_block_animation(weapon_config)
		elseif input.KeyCode == Enum.KeyCode.One then
			-- Press 1: Switch to primary weapon
			self:switch_weapon(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			-- Press 2: Switch to secondary weapon
			self:switch_weapon(2)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			-- Right click released: Stop blocking
			is_blocking = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Left click released: Check if we were doing push-attack
			if is_blocking and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				-- This will be handled in the held check
			end
		end
	end)
end

function WeaponCombat:perform_attack(weapon_config)
	if is_attacking or attack_cooldown > 0 then return end
	
	is_attacking = true
	attack_cooldown = weapon_config.attack_duration + 0.2  -- Add cooldown buffer
	
	print("[WeaponCombat] Attack: " .. weapon_config.attack_animation)
	
	-- Play attack animation
	self:play_attack_animation(weapon_config)
	
	-- Create visual swing effect
	self:create_swing_effect(weapon_config)
	
	-- Reset attack state after duration
	task.wait(weapon_config.attack_duration)
	is_attacking = false
end

function WeaponCombat:perform_push(weapon_config)
	if is_attacking or attack_cooldown > 0 then return end
	
	is_attacking = true
	attack_cooldown = PUSH_DURATION + 0.1
	
	print("[WeaponCombat] Push: " .. weapon_config.push_animation)
	
	-- Play push animation
	self:play_push_animation(weapon_config)
	
	-- Create push effect
	self:create_push_effect(weapon_config)
	
	task.wait(PUSH_DURATION)
	is_attacking = false
end

function WeaponCombat:perform_push_attack(weapon_config)
	if is_attacking or attack_cooldown > 0 then return end
	
	is_attacking = true
	attack_cooldown = PUSH_ATTACK_DURATION + 0.2
	
	print("[WeaponCombat] Push-Attack: " .. weapon_config.push_attack_animation)
	
	-- Play push-attack animation
	self:play_push_attack_animation(weapon_config)
	
	-- Create powerful effect
	self:create_push_attack_effect(weapon_config)
	
	task.wait(PUSH_ATTACK_DURATION)
	is_attacking = false
end

function WeaponCombat:update_combat(dt, weapon_config)
	-- Update cooldowns
	attack_cooldown = math.max(attack_cooldown - dt, 0)
	block_cooldown = math.max(block_cooldown - dt, 0)
	
	-- Check for held left-click while blocking (push-attack)
	if is_blocking and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		if not is_attacking then
			self:perform_push_attack(weapon_config)
		end
	end
	
	-- Keep weapon oriented toward camera
	if weapon_model then
		self:orient_weapon()
	end
end

function WeaponCombat:play_attack_animation(weapon_config)
	if not weapon_model then return end
	
	-- Rotate weapon for swing animation
	local start_cframe = weapon_model:GetPrimaryPartCFrame()
	local swing_angle = math.rad(90)
	
	for i = 0, 1, 0.1 do
		if not weapon_model then break end
		local current_angle = swing_angle * i
		local new_cframe = start_cframe * CFrame.Angles(current_angle, 0, 0)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
		RunService.RenderStepped:Wait()
	end
	
	-- Return to neutral position
	weapon_model:SetPrimaryPartCFrame(start_cframe)
end

function WeaponCombat:play_block_animation(weapon_config)
	if not weapon_model then return end
	
	-- Rotate weapon to blocking position
	local start_cframe = weapon_model:GetPrimaryPartCFrame()
	local block_angle = math.rad(45)
	
	for i = 0, 1, 0.15 do
		if not is_blocking then break end
		local current_angle = block_angle * i
		local new_cframe = start_cframe * CFrame.Angles(0, current_angle, 0)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
		RunService.RenderStepped:Wait()
	end
end

function WeaponCombat:play_push_animation(weapon_config)
	if not weapon_model then return end
	
	local start_cframe = weapon_model:GetPrimaryPartCFrame()
	
	-- Push forward motion
	for i = 0, 1, 0.2 do
		if not weapon_model then break end
		local forward_offset = i * 3
		local new_cframe = start_cframe * CFrame.new(forward_offset, 0, 0)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
		RunService.RenderStepped:Wait()
	end
	
	-- Return to position
	for i = 1, 0, -0.2 do
		if not weapon_model then break end
		local forward_offset = i * 3
		local new_cframe = start_cframe * CFrame.new(forward_offset, 0, 0)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
		RunService.RenderStepped:Wait()
	end
	
	weapon_model:SetPrimaryPartCFrame(start_cframe)
end

function WeaponCombat:play_push_attack_animation(weapon_config)
	if not weapon_model then return end
	
	local start_cframe = weapon_model:GetPrimaryPartCFrame()
	
	-- Charge up (pull back)
	for i = 0, 1, 0.15 do
		if not weapon_model then break end
		local back_offset = i * 2
		local new_cframe = start_cframe * CFrame.new(-back_offset, 0, 0)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
		RunService.RenderStepped:Wait()
	end
	
	-- Release (swing forward with rotation)
	for i = 0, 1, 0.12 do
		if not weapon_model then break end
		local forward_offset = (1 - i) * 2
		local swing_angle = i * math.rad(120)
		local new_cframe = start_cframe * CFrame.new(forward_offset, 0, 0) * CFrame.Angles(swing_angle, 0, 0)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
		RunService.RenderStepped:Wait()
	end
	
	weapon_model:SetPrimaryPartCFrame(start_cframe)
end

function WeaponCombat:switch_weapon(weapon_slot)
	if weapon_slot == current_weapon then
		print("[WeaponCombat] Already using weapon " .. weapon_slot)
		return
	end
	
	if weapon_slot == 1 then
		-- Switch to primary weapon
		if weapon_model then
			print("[WeaponCombat] Switching to PRIMARY weapon")
			-- Show primary weapon
			for _, part in ipairs(weapon_model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
				end
			end
			-- Hide secondary weapon
			if secondary_weapon_model then
				for _, part in ipairs(secondary_weapon_model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end
			end
			current_weapon = 1
		end
	elseif weapon_slot == 2 then
		-- Switch to secondary weapon
		if secondary_weapon_model then
			print("[WeaponCombat] Switching to SECONDARY weapon")
			-- Hide primary weapon
			if weapon_model then
				for _, part in ipairs(weapon_model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end
			end
			-- Show secondary weapon
			for _, part in ipairs(secondary_weapon_model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
				end
			end
			current_weapon = 2
		else
			print("[WeaponCombat] No secondary weapon available")
		end
	end
end

function WeaponCombat:orient_weapon()
	if not weapon_model or not humanoid_root_part then return end
	
	local camera = workspace.CurrentCamera
	local weapon_part = weapon_model:FindFirstChildOfClass("Part")
	
	if not weapon_part then return end
	
	-- Orient weapon toward camera direction
	local right_hand = character:FindFirstChild("RightHand") or character:FindFirstChild("RightLowerArm")
	if right_hand then
		local hand_pos = right_hand.Position
		local forward = camera.CFrame.LookVector
		local new_cframe = CFrame.new(hand_pos + forward * 2, hand_pos + forward * 3)
		weapon_model:SetPrimaryPartCFrame(new_cframe)
	end
end

function WeaponCombat:create_swing_effect(weapon_config)
	-- Create visual trail effect for attack
	local weapon_part = weapon_model:FindFirstChildOfClass("Part")
	if not weapon_part then return end
	
	local trail = Instance.new("Part")
	trail.Name = "AttackTrail"
	trail.Shape = Enum.PartType.Block
	trail.Size = Vector3.new(0.3, 0.3, 3)
	trail.Color = Color3.fromRGB(255, 150, 100)
	trail.Material = Enum.Material.Neon
	trail.CanCollide = false
	trail.CFrame = weapon_part.CFrame
	trail.Parent = workspace
	
	-- Fade out
	for i = 1, 0, -0.2 do
		if trail then
			trail.Transparency = 1 - i
		end
		task.wait(0.05)
	end
	
	if trail then
		trail:Destroy()
	end
end

function WeaponCombat:create_push_effect(weapon_config)
	-- Create shove effect
	local weapon_part = weapon_model:FindFirstChildOfClass("Part")
	if not weapon_part then return end
	
	local shove = Instance.new("Part")
	shove.Name = "ShoveEffect"
	shove.Shape = Enum.PartType.Ball
	shove.Size = Vector3.new(2, 2, 2)
	shove.Color = Color3.fromRGB(100, 200, 255)
	shove.Material = Enum.Material.Neon
	shove.CanCollide = false
	shove.CFrame = weapon_part.CFrame
	shove.Parent = workspace
	
	-- Expand and fade
	for i = 1, 0, -0.2 do
		if shove then
			shove.Size = Vector3.new(2 + (1 - i) * 3, 2 + (1 - i) * 3, 2 + (1 - i) * 3)
			shove.Transparency = 1 - i
		end
		task.wait(0.05)
	end
	
	if shove then
		shove:Destroy()
	end
end

function WeaponCombat:create_push_attack_effect(weapon_config)
	-- Create powerful attack effect
	local weapon_part = weapon_model:FindFirstChildOfClass("Part")
	if not weapon_part then return end
	
	local impact = Instance.new("Part")
	impact.Name = "PushAttackEffect"
	impact.Shape = Enum.PartType.Ball
	impact.Size = Vector3.new(3, 3, 3)
	impact.Color = Color3.fromRGB(255, 100, 100)
	impact.Material = Enum.Material.Neon
	impact.CanCollide = false
	impact.CFrame = weapon_part.CFrame
	impact.Parent = workspace
	
	-- Pulse effect
	for i = 1, 0, -0.15 do
		if impact then
			impact.Size = Vector3.new(3 + (1 - i) * 5, 3 + (1 - i) * 5, 3 + (1 - i) * 5)
			impact.Transparency = 1 - i
		end
		task.wait(0.04)
	end
	
	if impact then
		impact:Destroy()
	end
end

return WeaponCombat
