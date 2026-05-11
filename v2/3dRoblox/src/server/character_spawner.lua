-- Character Spawner - Creates and manages player characters
local Players = game:GetService("Players")

local CharacterSpawner = {}
CharacterSpawner.__index = CharacterSpawner

function CharacterSpawner:spawn_character(player, player_data, spawn_position)
	-- Remove old character if exists
	if player.Character then
		player.Character:Destroy()
	end
	
	-- Create new character
	local character = Instance.new("Model")
	character.Name = player.Name
	character.Parent = workspace
	
	-- Create humanoid root part
	local root_part = Instance.new("Part")
	root_part.Name = "HumanoidRootPart"
	root_part.Shape = Enum.PartType.Block
	root_part.Size = Vector3.new(2, 2, 1)
	root_part.CanCollide = true
	root_part.CFrame = spawn_position or CFrame.new(0, 5, 0)
	root_part.Parent = character
	
	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	humanoid.MaxHealth = player_data.max_hp
	humanoid.Health = player_data.hp
	
	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1, 1, 1)
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.CanCollide = true
	head.CFrame = root_part.CFrame + Vector3.new(0, 1, 0)
	head.Parent = character
	
	-- Create torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Shape = Enum.PartType.Block
	torso.Size = Vector3.new(2, 2, 1)
	torso.TopSurface = Enum.SurfaceType.Smooth
	torso.BottomSurface = Enum.SurfaceType.Smooth
	torso.CanCollide = true
	torso.CFrame = root_part.CFrame
	torso.Parent = character
	
	-- Create left arm
	local left_arm = Instance.new("Part")
	left_arm.Name = "Left Arm"
	left_arm.Shape = Enum.PartType.Block
	left_arm.Size = Vector3.new(1, 2, 1)
	left_arm.CanCollide = true
	left_arm.CFrame = root_part.CFrame + Vector3.new(-1.5, 0, 0)
	left_arm.Parent = character
	
	-- Create right arm
	local right_arm = Instance.new("Part")
	right_arm.Name = "Right Arm"
	right_arm.Shape = Enum.PartType.Block
	right_arm.Size = Vector3.new(1, 2, 1)
	right_arm.CanCollide = true
	right_arm.CFrame = root_part.CFrame + Vector3.new(1.5, 0, 0)
	right_arm.Parent = character
	
	-- Create left leg
	local left_leg = Instance.new("Part")
	left_leg.Name = "Left Leg"
	left_leg.Shape = Enum.PartType.Block
	left_leg.Size = Vector3.new(1, 2, 1)
	left_leg.CanCollide = true
	left_leg.CFrame = root_part.CFrame + Vector3.new(-0.5, -2, 0)
	left_leg.Parent = character
	
	-- Create right leg
	local right_leg = Instance.new("Part")
	right_leg.Name = "Right Leg"
	right_leg.Shape = Enum.PartType.Block
	right_leg.Size = Vector3.new(1, 2, 1)
	right_leg.CanCollide = true
	right_leg.CFrame = root_part.CFrame + Vector3.new(0.5, -2, 0)
	right_leg.Parent = character
	
	-- Create joints
	self:create_joints(character, root_part, head, torso, left_arm, right_arm, left_leg, right_leg)
	
	-- Store player data in character
	local data_folder = Instance.new("Folder")
	data_folder.Name = "PlayerData"
	data_folder.Parent = character
	
	local race_value = Instance.new("IntValue")
	race_value.Name = "Race"
	race_value.Value = player_data.race
	race_value.Parent = data_folder
	
	local class_value = Instance.new("IntValue")
	class_value.Name = "Class"
	class_value.Value = player_data.class_type
	class_value.Parent = data_folder
	
	-- Set player character
	player.Character = character
	
	return character
end

function CharacterSpawner:create_joints(character, root_part, head, torso, left_arm, right_arm, left_leg, right_leg)
	-- Root to Torso
	local root_weld = Instance.new("WeldConstraint")
	root_weld.Part0 = root_part
	root_weld.Part1 = torso
	root_weld.Parent = root_part
	
	-- Torso to Head
	local neck = Instance.new("WeldConstraint")
	neck.Part0 = torso
	neck.Part1 = head
	neck.Parent = torso
	
	-- Torso to Left Arm
	local left_shoulder = Instance.new("WeldConstraint")
	left_shoulder.Part0 = torso
	left_shoulder.Part1 = left_arm
	left_shoulder.Parent = torso
	
	-- Torso to Right Arm
	local right_shoulder = Instance.new("WeldConstraint")
	right_shoulder.Part0 = torso
	right_shoulder.Part1 = right_arm
	right_shoulder.Parent = torso
	
	-- Torso to Left Leg
	local left_hip = Instance.new("WeldConstraint")
	left_hip.Part0 = torso
	left_hip.Part1 = left_leg
	left_hip.Parent = torso
	
	-- Torso to Right Leg
	local right_hip = Instance.new("WeldConstraint")
	right_hip.Part0 = torso
	right_hip.Part1 = right_leg
	right_hip.Parent = torso
end

function CharacterSpawner:get_spawn_position(team)
	-- Team 1 spawns at (0, 5, 0)
	-- Team 2 spawns at (50, 5, 0)
	if team == "team_1" then
		return CFrame.new(0, 5, 0)
	else
		return CFrame.new(50, 5, 0)
	end
end

return CharacterSpawner
