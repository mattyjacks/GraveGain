-- Gateway System - Character Selection via Portals
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local StarterPlayerScripts = script.Parent

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
local AbilitySystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ability_system"))
local WeaponSystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("weapon_system"))
local GatewayFPSController = require(StarterPlayerScripts:WaitForChild("gateway_fps_controller"))
local SpaceshipLobby = require(StarterPlayerScripts:WaitForChild("spaceship_lobby"))
local WeaponCombat = require(StarterPlayerScripts:WaitForChild("weapon_combat"))

local GatewaySystem = {}
GatewaySystem.__index = GatewaySystem

local player = Players.LocalPlayer
local character
local humanoid_root_part
local camera = workspace.CurrentCamera

local gateways = {}
local selected_gateway = nil
local in_gateway = false

function GatewaySystem:initialize()
	print("[GatewaySystem] Initializing...")
	
	-- Create the spaceship lobby environment
	SpaceshipLobby:create_lobby_environment()
	
	-- Wait for character to load
	character = player.Character or player.CharacterAdded:Wait()
	humanoid_root_part = character:WaitForChild("HumanoidRootPart")
	print("[GatewaySystem] Character loaded: " .. character.Name)
	
	-- Teleport character to center of lobby
	humanoid_root_part.CFrame = CFrame.new(Vector3.new(0, 3, 0))
	
	-- Create 16 gateways (4 races × 4 classes)
	local races = AbilitySystem.get_all_races()
	local classes = AbilitySystem.get_all_classes()
	
	print("[GatewaySystem] Races: " .. table.concat(races, ", "))
	print("[GatewaySystem] Classes: " .. table.concat(classes, ", "))
	
	-- Position gateways in a proper semi-circle FACING THE PLAYER
	-- Center at origin, arc extends in positive Z direction (away from player at 0,0,0)
	local center_pos = Vector3.new(0, 8, 30)
	
	local gateway_index = 1
	local radius = 40  -- Distance from center to each gateway
	local arc_depth = 35  -- How far forward the arc extends
	local arc_height = 8  -- Height of arc
	
	-- 16 gateways in a semi-circle (180 degrees)
	-- Angle goes from -90 degrees (left) to +90 degrees (right)
	local angle_step = math.pi / 17  -- 180 degrees / 17 segments
	
	for i, race in ipairs(races) do
		for j, class_type in ipairs(classes) do
			-- Angle from -90 to +90 degrees (left to right)
			local angle = -math.pi / 2 + (gateway_index - 1) * angle_step
			
			-- Position on semi-circle arc
			-- x_offset: left-right spread using sin
			-- z_offset: forward depth using cos (creates arc bulge)
			local x_offset = math.sin(angle) * radius
			local z_offset = math.cos(angle) * arc_depth
			
			local gateway_pos = center_pos + Vector3.new(x_offset, 0, z_offset)
			
			print("[GatewaySystem] Creating gateway #" .. gateway_index .. ": " .. race .. " " .. class_type .. " at angle " .. math.deg(angle) .. " degrees, pos: " .. tostring(gateway_pos))
			
			local gateway = self:create_gateway(
				gateway_pos,
				race,
				class_type,
				gateway_index
			)
			
			table.insert(gateways, gateway)
			gateway_index = gateway_index + 1
		end
	end
	
	-- Create 17th random gateway in center of the semi-circle
	print("[GatewaySystem] Creating random gateway #17 at center")
	local random_gateway = self:create_gateway(
		center_pos,
		"random",
		"random",
		17
	)
	table.insert(gateways, random_gateway)
	
	-- Create reset gateway (always available, positioned to the side)
	print("[GatewaySystem] Creating reset gateway")
	local reset_pos = Vector3.new(-60, 8, 30)
	local reset_gateway = self:create_reset_gateway(reset_pos)
	table.insert(gateways, reset_gateway)
	
	-- Setup input handling
	self:setup_input_handling()
	
	-- Setup camera to look at the gateway semi-circle from player position
	camera.CFrame = CFrame.new(Vector3.new(0, 5, -20), center_pos)
	
	print("[GatewaySystem] Created " .. #gateways .. " gateways")
	print("[GatewaySystem] Initialized")
end

function GatewaySystem:create_gateway(position, race, class_type, index)
	local gateway = Instance.new("Model")
	gateway.Name = "Gateway_" .. index
	gateway.Parent = workspace
	
	-- Gateway frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Block
	frame.Size = Vector3.new(4, 6, 0.5)
	frame.Position = position
	frame.CanCollide = false
	frame.Material = Enum.Material.Neon
	frame.Anchored = true
	frame.TopSurface = Enum.SurfaceType.Smooth
	frame.BottomSurface = Enum.SurfaceType.Smooth
	
	-- Color based on race
	local colors = {
		human = Color3.fromRGB(100, 150, 255),
		elf = Color3.fromRGB(100, 255, 150),
		dwarf = Color3.fromRGB(200, 150, 100),
		orc = Color3.fromRGB(200, 100, 100),
		random = Color3.fromRGB(255, 200, 100)
	}
	frame.Color = colors[race] or colors.human
	frame.Parent = gateway
	
	-- Portal effect (inner glow)
	local portal = Instance.new("Part")
	portal.Name = "Portal"
	portal.Shape = Enum.PartType.Block
	portal.Size = Vector3.new(3.5, 5.5, 0.2)
	portal.Position = position + Vector3.new(0, 0, 0.2)
	portal.CanCollide = false
	portal.Material = Enum.Material.Neon
	portal.Color = frame.Color
	portal.Transparency = 0.3
	portal.Anchored = true
	portal.TopSurface = Enum.SurfaceType.Smooth
	portal.BottomSurface = Enum.SurfaceType.Smooth
	portal.Parent = gateway
	
	-- Top label (Race/Class friendly names)
	local top_label = Instance.new("Part")
	top_label.Name = "TopLabel"
	top_label.Shape = Enum.PartType.Block
	top_label.Size = Vector3.new(4.5, 0.8, 0.05)
	top_label.Position = position + Vector3.new(0, 3.8, 0.3)
	top_label.CanCollide = false
	top_label.Material = Enum.Material.Plastic
	top_label.Color = Color3.fromRGB(30, 30, 30)
	top_label.Anchored = true
	top_label.TopSurface = Enum.SurfaceType.Smooth
	top_label.BottomSurface = Enum.SurfaceType.Smooth
	top_label.Parent = gateway
	
	local top_gui = Instance.new("SurfaceGui")
	top_gui.Face = Enum.NormalId.Front
	top_gui.PixelsPerStud = 20
	top_gui.Parent = top_label
	
	local top_text = Instance.new("TextLabel")
	top_text.Size = UDim2.new(1, 0, 1, 0)
	top_text.BackgroundTransparency = 1
	top_text.TextColor3 = Color3.fromRGB(255, 255, 255)
	top_text.TextSize = 20
	top_text.Font = Enum.Font.GothamBold
	top_text.TextScaled = true
	
	if race == "random" then
		top_text.Text = "??? RANDOM ???"
	else
		top_text.Text = race:upper() .. " / " .. class_type:upper()
	end
	
	top_text.Parent = top_gui
	
	-- Bottom label (Friendly names)
	local bottom_label = Instance.new("Part")
	bottom_label.Name = "BottomLabel"
	bottom_label.Shape = Enum.PartType.Block
	bottom_label.Size = Vector3.new(4.5, 1.2, 0.05)
	bottom_label.Position = position + Vector3.new(0, -3.5, 0.3)
	bottom_label.CanCollide = false
	bottom_label.Material = Enum.Material.Plastic
	bottom_label.Color = Color3.fromRGB(30, 30, 30)
	bottom_label.Anchored = true
	bottom_label.TopSurface = Enum.SurfaceType.Smooth
	bottom_label.BottomSurface = Enum.SurfaceType.Smooth
	bottom_label.Parent = gateway
	
	local bottom_gui = Instance.new("SurfaceGui")
	bottom_gui.Face = Enum.NormalId.Front
	bottom_gui.PixelsPerStud = 20
	bottom_gui.Parent = bottom_label
	
	local bottom_text = Instance.new("TextLabel")
	bottom_text.Size = UDim2.new(1, 0, 1, 0)
	bottom_text.BackgroundTransparency = 1
	bottom_text.TextColor3 = Color3.fromRGB(200, 200, 200)
	bottom_text.TextSize = 18
	bottom_text.Font = Enum.Font.Gotham
	bottom_text.TextWrapped = true
	bottom_text.TextScaled = true
	
	-- Friendly names for each race/class combo
	local friendly_names = {
		human_dps = "Soldier",
		human_tank = "Guardian",
		human_support = "Medic",
		human_mage = "Technomancer",
		elf_dps = "Archer",
		elf_tank = "Sentinel",
		elf_support = "Healer",
		elf_mage = "Sorcerer",
		dwarf_dps = "Sharpshooter",
		dwarf_tank = "Ironforge",
		dwarf_support = "Alchemist",
		dwarf_mage = "Runesmith",
		orc_dps = "Berserker",
		orc_tank = "Warlord",
		orc_support = "Shaman",
		orc_mage = "Warlock",
		random = "MYSTERY"
	}
	
	if race == "random" then
		bottom_text.Text = friendly_names.random
	else
		local key = race .. "_" .. class_type
		bottom_text.Text = friendly_names[key] or (race .. " " .. class_type)
	end
	
	bottom_text.Parent = bottom_gui
	
	-- Store gateway data
	gateway:SetAttribute("Race", race)
	gateway:SetAttribute("Class", class_type)
	gateway:SetAttribute("Index", index)
	gateway:SetAttribute("Position", position)
	
	-- Add touch detection with debounce
	local last_touch_time = 0
	frame.Touched:Connect(function(hit)
		if hit.Parent == character then
			local current_time = tick()
			if current_time - last_touch_time > 0.5 then
				last_touch_time = current_time
				print("[GatewaySystem] Gateway touched! Race: " .. race .. ", Class: " .. class_type)
				self:enter_gateway(gateway, race, class_type)
			end
		end
	end)
	
	print("[GatewaySystem] Created gateway #" .. index .. " at " .. tostring(position))
	
	return gateway
end

function GatewaySystem:create_reset_gateway(position)
	local gateway = Instance.new("Model")
	gateway.Name = "ResetGateway"
	gateway.Parent = workspace
	
	-- Gateway frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Shape = Enum.PartType.Block
	frame.Size = Vector3.new(4, 6, 0.5)
	frame.Position = position
	frame.CanCollide = false
	frame.Material = Enum.Material.Neon
	frame.Anchored = true
	frame.TopSurface = Enum.SurfaceType.Smooth
	frame.BottomSurface = Enum.SurfaceType.Smooth
	frame.Color = Color3.fromRGB(200, 100, 200)  -- Purple/Magenta
	frame.Parent = gateway
	
	-- Portal effect (inner glow)
	local portal = Instance.new("Part")
	portal.Name = "Portal"
	portal.Shape = Enum.PartType.Block
	portal.Size = Vector3.new(3.5, 5.5, 0.2)
	portal.Position = position + Vector3.new(0, 0, 0.2)
	portal.CanCollide = false
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(200, 100, 200)
	portal.Transparency = 0.3
	portal.Anchored = true
	portal.TopSurface = Enum.SurfaceType.Smooth
	portal.BottomSurface = Enum.SurfaceType.Smooth
	portal.Parent = gateway
	
	-- Top label
	local top_label = Instance.new("Part")
	top_label.Name = "TopLabel"
	top_label.Shape = Enum.PartType.Block
	top_label.Size = Vector3.new(4.5, 0.8, 0.1)
	top_label.Position = position + Vector3.new(0, 3.8, 0.3)
	top_label.CanCollide = false
	top_label.Material = Enum.Material.Plastic
	top_label.Color = Color3.fromRGB(30, 30, 30)
	top_label.Anchored = true
	top_label.TopSurface = Enum.SurfaceType.Smooth
	top_label.BottomSurface = Enum.SurfaceType.Smooth
	top_label.Parent = gateway
	
	local top_gui = Instance.new("SurfaceGui")
	top_gui.Face = Enum.NormalId.Front
	top_gui.Parent = top_label
	
	local top_text = Instance.new("TextLabel")
	top_text.Size = UDim2.new(1, 0, 1, 0)
	top_text.BackgroundTransparency = 1
	top_text.TextColor3 = Color3.fromRGB(255, 255, 255)
	top_text.TextSize = 16
	top_text.Font = Enum.Font.GothamBold
	top_text.Text = "RESET"
	top_text.Parent = top_gui
	
	-- Bottom label
	local bottom_label = Instance.new("Part")
	bottom_label.Name = "BottomLabel"
	bottom_label.Shape = Enum.PartType.Block
	bottom_label.Size = Vector3.new(4.5, 1.2, 0.1)
	bottom_label.Position = position + Vector3.new(0, -3.5, 0.3)
	bottom_label.CanCollide = false
	bottom_label.Material = Enum.Material.Plastic
	bottom_label.Color = Color3.fromRGB(30, 30, 30)
	bottom_label.Anchored = true
	bottom_label.TopSurface = Enum.SurfaceType.Smooth
	bottom_label.BottomSurface = Enum.SurfaceType.Smooth
	bottom_label.Parent = gateway
	
	local bottom_gui = Instance.new("SurfaceGui")
	bottom_gui.Face = Enum.NormalId.Front
	bottom_gui.Parent = bottom_label
	
	local bottom_text = Instance.new("TextLabel")
	bottom_text.Size = UDim2.new(1, 0, 1, 0)
	bottom_text.BackgroundTransparency = 1
	bottom_text.TextColor3 = Color3.fromRGB(200, 200, 200)
	bottom_text.TextSize = 12
	bottom_text.Font = Enum.Font.Gotham
	bottom_text.TextWrapped = true
	bottom_text.Text = "Return to Lobby"
	bottom_text.Parent = bottom_gui
	
	-- Store gateway data
	gateway:SetAttribute("IsReset", true)
	gateway:SetAttribute("Position", position)
	
	-- Add touch detection with debounce
	local last_touch_time = 0
	frame.Touched:Connect(function(hit)
		if hit.Parent == character then
			local current_time = tick()
			if current_time - last_touch_time > 0.5 then
				last_touch_time = current_time
				print("[GatewaySystem] Reset gateway touched!")
				self:reset_character()
			end
		end
	end)
	
	print("[GatewaySystem] Created reset gateway at " .. tostring(position))
	
	return gateway
end

function GatewaySystem:reset_character()
	if in_gateway then return end
	
	in_gateway = true
	print("[GatewaySystem] Resetting character...")
	
	-- Clear attributes
	character:SetAttribute("SelectedRace", nil)
	character:SetAttribute("SelectedClass", nil)
	
	-- Destroy weapon
	local weapon = character:FindFirstChild("Weapon")
	if weapon then
		weapon:Destroy()
	end
	
	-- Destroy ability HUD
	local player_gui = player:WaitForChild("PlayerGui")
	local ability_hud = player_gui:FindFirstChild("AbilityHUD")
	if ability_hud then
		ability_hud:Destroy()
	end
	
	-- Reset camera to default
	camera.CameraType = Enum.CameraType.Custom
	
	-- Reset humanoid to default
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	
	-- Teleport back to center
	humanoid_root_part.CFrame = CFrame.new(Vector3.new(0, 3, 0))
	
	-- Destroy all gateways
	for _, gateway in ipairs(gateways) do
		if gateway and gateway.Parent then
			gateway:Destroy()
		end
	end
	gateways = {}
	
	-- Reinitialize gateway system
	task.wait(0.5)
	self:initialize()
end

function GatewaySystem:setup_input_handling()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			if selected_gateway then
				self:enter_gateway(selected_gateway)
			end
		end
	end)
	
	-- Raycast to detect nearby gateways
	RunService.RenderStepped:Connect(function()
		local camera_direction = camera.CFrame.LookVector
		local ray_origin = humanoid_root_part.Position
		
		local closest_gateway = nil
		local closest_distance = 50
		
		for _, gateway in ipairs(gateways) do
			local gateway_pos = gateway:GetAttribute("Position")
			local distance = (gateway_pos - ray_origin).Magnitude
			
			if distance < closest_distance then
				closest_distance = distance
				closest_gateway = gateway
			end
		end
		
		selected_gateway = closest_gateway
	end)
end

function GatewaySystem:enter_gateway(gateway, race, class_type)
	if in_gateway then return end
	
	in_gateway = true
	print("[GatewaySystem] Entering gateway... Race: " .. tostring(race) .. ", Class: " .. tostring(class_type))
	
	-- Use provided race/class or get from gateway attributes
	race = race or gateway:GetAttribute("Race")
	class_type = class_type or gateway:GetAttribute("Class")
	
	-- If random, pick random race and class
	if race == "random" then
		local races = AbilitySystem.get_all_races()
		local classes = AbilitySystem.get_all_classes()
		race = races[math.random(1, #races)]
		class_type = classes[math.random(1, #classes)]
	end
	
	print("[GatewaySystem] Entering gateway: " .. race .. " " .. class_type)
	
	-- Transition to first person
	self:setup_first_person(race, class_type)
	
	-- Hide gateways (except reset gateway)
	for _, gw in ipairs(gateways) do
		if not gw:GetAttribute("IsReset") then
			gw:Destroy()
		end
	end
	
	in_gateway = false
end

function GatewaySystem:setup_first_person(race, class_type)
	-- Get abilities for this combination
	local abilities = AbilitySystem.get_abilities(class_type, race)
	
	print("[GatewaySystem] Abilities: " .. abilities.name)
	print("[GatewaySystem] Primary: " .. abilities.primary)
	print("[GatewaySystem] Secondary: " .. abilities.secondary)
	print("[GatewaySystem] Ability 1: " .. abilities.ability1)
	print("[GatewaySystem] Ability 2: " .. abilities.ability2)
	print("[GatewaySystem] Ultimate: " .. abilities.ultimate)
	
	-- Create primary weapon model
	local weapon = WeaponSystem:create_weapon_model(race, class_type, character)
	weapon.Parent = character
	
	-- Find the main weapon part (first part created)
	local weapon_part = weapon:FindFirstChildOfClass("Part")
	if not weapon_part then
		print("[GatewaySystem] ERROR: Weapon has no parts!")
		return
	end
	
	-- Set weapon part as primary part
	weapon:SetPrimaryPartCFrame(weapon_part.CFrame)
	
	-- Create secondary weapon model
	local secondary_weapon = WeaponSystem:create_secondary_weapon_model(race, class_type, character)
	secondary_weapon.Parent = character
	
	-- Find the secondary weapon part
	local secondary_weapon_part = secondary_weapon:FindFirstChildOfClass("Part")
	if secondary_weapon_part then
		secondary_weapon:SetPrimaryPartCFrame(secondary_weapon_part.CFrame)
	end
	
	-- Weld both weapons to right hand
	local right_hand = character:FindFirstChild("RightHand") or character:FindFirstChild("RightLowerArm")
	if right_hand then
		-- Weld primary weapon parts to the hand
		for _, part in ipairs(weapon:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = right_hand
				weld.Part1 = part
				weld.Parent = part
			end
		end
		
		-- Weld secondary weapon parts to the hand
		for _, part in ipairs(secondary_weapon:GetDescendants()) do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = right_hand
				weld.Part1 = part
				weld.Parent = part
			end
		end
		
		-- Position weapons in front of hand
		weapon_part.Position = right_hand.Position + right_hand.CFrame.LookVector * 2
		weapon_part.CanCollide = false
		
		if secondary_weapon_part then
			secondary_weapon_part.Position = right_hand.Position + right_hand.CFrame.LookVector * 2
			secondary_weapon_part.CanCollide = false
		end
		
		print("[GatewaySystem] Both weapons welded to right hand")
	else
		print("[GatewaySystem] WARNING: Right hand not found, weapons may not be visible")
	end
	
	-- Setup race-specific mechanics
	self:setup_race_mechanics(race)
	
	-- Create HUD showing abilities
	self:create_ability_hud(abilities)
	
	-- Store current selection
	character:SetAttribute("SelectedRace", race)
	character:SetAttribute("SelectedClass", class_type)
	
	-- Initialize FPS controller and combat system
	task.spawn(function()
		print("[GatewaySystem] Initializing FPS controller...")
		GatewayFPSController:initialize()
		print("[GatewaySystem] FPS controller initialized")
	end)
	
	task.spawn(function()
		task.wait(0.2)
		print("[GatewaySystem] Initializing weapon combat system...")
		WeaponCombat:initialize(character, weapon, secondary_weapon)
		print("[GatewaySystem] Weapon combat system initialized")
	end)
end

function GatewaySystem:setup_race_mechanics(race)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
	
	if race == "human" then
		-- Jetpack mechanics
		self:setup_jetpack()
	elseif race == "dwarf" then
		-- Double jump mechanics
		self:setup_double_jump()
	elseif race == "orc" then
		-- Ground slam mechanics
		self:setup_ground_slam()
	elseif race == "elf" then
		-- Hover mechanics
		self:setup_hover()
	end
end

function GatewaySystem:setup_jetpack()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local hum = character:WaitForChild("Humanoid")

	local jetpack_active = false
	local jetpack_fuel = 100
	local MAX_FUEL = 100
	local FUEL_BURN = 0.8       -- per frame while active
	local FUEL_REGEN = 0.3      -- per frame while grounded
	local THRUST = 35            -- upward velocity

	-- BodyVelocity for smooth thrust (does not fight physics like setting velocity)
	local thrust_force = Instance.new("BodyVelocity")
	thrust_force.MaxForce = Vector3.new(0, 0, 0)
	thrust_force.Velocity = Vector3.new(0, 0, 0)
	thrust_force.P = 5000
	thrust_force.Parent = hrp

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Space then
			-- First press: normal jump (let Humanoid handle it)
			-- Hold: jetpack activates after leaving ground
			task.delay(0.15, function()
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) and jetpack_fuel > 0 then
					jetpack_active = true
				end
			end)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			jetpack_active = false
		end
	end)

	RunService.Heartbeat:Connect(function()
		if jetpack_active and jetpack_fuel > 0 then
			thrust_force.MaxForce = Vector3.new(0, math.huge, 0)
			thrust_force.Velocity = Vector3.new(0, THRUST, 0)
			jetpack_fuel = math.max(jetpack_fuel - FUEL_BURN, 0)
			if jetpack_fuel <= 0 then
				jetpack_active = false
			end
		else
			thrust_force.MaxForce = Vector3.new(0, 0, 0)
			thrust_force.Velocity = Vector3.new(0, 0, 0)
			-- Regen fuel when grounded
			if hum.FloorMaterial ~= Enum.Material.Air then
				jetpack_fuel = math.min(jetpack_fuel + FUEL_REGEN, MAX_FUEL)
			end
		end
	end)

	print("[GatewaySystem] Jetpack ready (Human)")
end

function GatewaySystem:setup_double_jump()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local hum = character:WaitForChild("Humanoid")

	local can_double_jump = false
	local has_double_jumped = false
	local DOUBLE_JUMP_POWER = 60

	hum.StateChanged:Connect(function(old_state, new_state)
		if new_state == Enum.HumanoidStateType.Landed then
			can_double_jump = false
			has_double_jumped = false
		elseif new_state == Enum.HumanoidStateType.Freefall then
			-- Allow double jump once we leave the ground
			if not has_double_jumped then
				can_double_jump = true
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Space then
			if can_double_jump and not has_double_jumped then
				has_double_jumped = true
				can_double_jump = false
				-- Apply upward impulse
				hrp.AssemblyLinearVelocity = Vector3.new(
					hrp.AssemblyLinearVelocity.X,
					DOUBLE_JUMP_POWER,
					hrp.AssemblyLinearVelocity.Z
				)
			end
		end
	end)

	print("[GatewaySystem] Double jump ready (Dwarf)")
end

function GatewaySystem:setup_ground_slam()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local hum = character:WaitForChild("Humanoid")

	local is_airborne = false
	local has_slammed = false
	local SLAM_SPEED = 120
	local JUMP_POWER = 70  -- Orcs jump high

	hum.JumpPower = JUMP_POWER

	hum.StateChanged:Connect(function(old_state, new_state)
		if new_state == Enum.HumanoidStateType.Freefall then
			is_airborne = true
			has_slammed = false
		elseif new_state == Enum.HumanoidStateType.Landed then
			is_airborne = false
			has_slammed = false
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Space and is_airborne and not has_slammed then
			has_slammed = true
			-- Slam straight down
			hrp.AssemblyLinearVelocity = Vector3.new(0, -SLAM_SPEED, 0)
		end
	end)

	print("[GatewaySystem] Ground slam ready (Orc, JumpPower=" .. JUMP_POWER .. ")")
end

function GatewaySystem:setup_hover()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local hum = character:WaitForChild("Humanoid")

	local hover_active = false
	local hover_start_y = 0
	local HOVER_DRIFT = -2        -- slow downward drift per second
	local HOVER_DURATION = 3      -- seconds before hover expires
	local hover_timer = 0

	-- BodyVelocity to counteract gravity smoothly
	local hover_force = Instance.new("BodyVelocity")
	hover_force.MaxForce = Vector3.new(0, 0, 0)
	hover_force.Velocity = Vector3.new(0, 0, 0)
	hover_force.P = 10000
	hover_force.Parent = hrp

	hum.StateChanged:Connect(function(old_state, new_state)
		if new_state == Enum.HumanoidStateType.Landed then
			hover_active = false
			hover_timer = 0
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Space then
			-- Only activate hover while airborne (after initial jump)
			task.delay(0.2, function()
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					local state = hum:GetState()
					if state == Enum.HumanoidStateType.Freefall then
						hover_active = true
						hover_start_y = hrp.Position.Y
						hover_timer = 0
					end
				end
			end)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			hover_active = false
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if hover_active then
			hover_timer = hover_timer + dt
			if hover_timer >= HOVER_DURATION then
				hover_active = false
				hover_force.MaxForce = Vector3.new(0, 0, 0)
				return
			end
			-- Lock vertical movement to a slow drift downward
			hover_force.MaxForce = Vector3.new(0, math.huge, 0)
			hover_force.Velocity = Vector3.new(0, HOVER_DRIFT, 0)
		else
			hover_force.MaxForce = Vector3.new(0, 0, 0)
			hover_force.Velocity = Vector3.new(0, 0, 0)
		end
	end)

	print("[GatewaySystem] Hover ready (Elf, duration=" .. HOVER_DURATION .. "s)")
end

function GatewaySystem:create_ability_hud(abilities)
	local player_gui = player:WaitForChild("PlayerGui")
	
	local ability_screen = Instance.new("ScreenGui")
	ability_screen.Name = "AbilityHUD"
	ability_screen.ResetOnSpawn = false
	ability_screen.Parent = player_gui
	
	-- Background frame (clickable to close)
	local bg_frame = Instance.new("TextButton")
	bg_frame.Name = "BackgroundFrame"
	bg_frame.Size = UDim2.new(1, 0, 1, 0)
	bg_frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg_frame.BackgroundTransparency = 0.5
	bg_frame.BorderSizePixel = 0
	bg_frame.Text = ""
	bg_frame.Parent = ability_screen
	
	-- Content frame
	local content_frame = Instance.new("Frame")
	content_frame.Name = "ContentFrame"
	content_frame.Size = UDim2.new(0.35, 0, 0.5, 0)
	content_frame.Position = UDim2.new(0.325, 0, 0.05, 0)
	content_frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	content_frame.BorderColor3 = Color3.fromRGB(100, 150, 200)
	content_frame.BorderSizePixel = 2
	content_frame.Parent = ability_screen
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.12, 0)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Text = abilities.name
	title.Parent = content_frame
	
	-- Abilities list
	local abilities_list = {
		{label = "Primary", value = abilities.primary},
		{label = "Secondary", value = abilities.secondary},
		{label = "Ability 1", value = abilities.ability1},
		{label = "Ability 2", value = abilities.ability2},
		{label = "Ultimate", value = abilities.ultimate}
	}
	
	for i, ability in ipairs(abilities_list) do
		local ability_label = Instance.new("TextLabel")
		ability_label.Name = ability.label
		ability_label.Size = UDim2.new(1, -10, 0, 50)
		ability_label.Position = UDim2.new(0, 5, 0.12 + (i - 1) * 0.16, 0)
		ability_label.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		ability_label.TextColor3 = Color3.fromRGB(200, 200, 200)
		ability_label.TextSize = 13
		ability_label.Font = Enum.Font.Gotham
		ability_label.Text = ability.label .. ": " .. ability.value
		ability_label.TextXAlignment = Enum.TextXAlignment.Left
		ability_label.TextWrapped = true
		ability_label.Parent = content_frame
	end
	
	-- Close instruction
	local close_label = Instance.new("TextLabel")
	close_label.Name = "CloseLabel"
	close_label.Size = UDim2.new(1, 0, 0.08, 0)
	close_label.Position = UDim2.new(0, 0, 0.92, 0)
	close_label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	close_label.TextColor3 = Color3.fromRGB(150, 150, 150)
	close_label.TextSize = 12
	close_label.Font = Enum.Font.Gotham
	close_label.Text = "Click Anywhere to Close"
	close_label.Parent = content_frame
	
	-- Close on background click
	bg_frame.MouseButton1Click:Connect(function()
		ability_screen:Destroy()
	end)
end

return GatewaySystem
