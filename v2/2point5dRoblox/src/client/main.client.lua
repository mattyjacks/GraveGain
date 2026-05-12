local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientFolder = script.Parent
local CameraController = require(ClientFolder:WaitForChild("camera_controller"))
local MovementController = require(ClientFolder:WaitForChild("movement_controller"))
local InputHandler = require(ClientFolder:WaitForChild("input_handler"))
local LobbyRacePicker = require(ClientFolder:WaitForChild("lobby_race_picker"))
local Darkvision = require(ClientFolder:WaitForChild("darkvision"))
local PlayerStats = require(ClientFolder:WaitForChild("player_stats"))
local CombatSystem = require(ClientFolder:WaitForChild("combat_system"))
local RaceStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("race_stats"))

local function applyRaceScale(char, raceName)
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	local raceData = RaceStats.getRaceStats(raceName)
	if not raceData or not raceData.scale then return end
	
	local scale = raceData.scale
	
	local function setScale(name, value)
		local valObj = humanoid:FindFirstChild(name)
		if valObj and valObj:IsA("NumberValue") then
			valObj.Value = value
		end
	end
	
	setScale("BodyDepthScale", scale.Z)
	setScale("BodyHeightScale", scale.Y)
	setScale("BodyWidthScale", scale.X)
	setScale("HeadScale", scale.Y)
end

print("GraveGain 2.5D Client Started")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local races = {"Human", "Orc", "Dwarf", "Elf"}
local selectedRace = races[math.random(1, #races)]
local selectedDifficulty = nil
local playerStats = nil
local lightActive = false
local gameState = "lobby"

print("Player spawned as:", selectedRace)
print("Character:", character.Name)

applyRaceScale(character, selectedRace)

local cameraController = CameraController.new()
print("Camera controller created, setting character...")
cameraController:setCharacter(character)
print("Camera controller character set")

local combatSystem = CombatSystem.new()
local movementController = MovementController.new()
local inputHandler = InputHandler.new(combatSystem)
local darkvision = Darkvision.new()

local function initializeDungeon()
	gameState = "dungeon"
	print("Entering dungeon as:", selectedRace)

	playerStats = PlayerStats.new(character, selectedRace)
	combatSystem:setCharacter(character, playerStats)

	if selectedRace == "Dwarf" then
		darkvision:activate(character)
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	inputHandler.isEnabled = true

	print("All client systems initialized")
	print("Controls:")
	print("  WASD - Move")
	print("  Shift - Sprint")
	print("  Right Click - Block")
	print("  Left Click (while blocking) - Push (tap) / Charged Push (hold)")
	print("  F - Race Light Ability")
	print("  Mouse Wheel - Zoom")
	print("  Middle Mouse Drag - Rotate Camera")
end

local function showRacePickerLobby()
	local racePicker = LobbyRacePicker.new()
	racePicker:show()

	task.spawn(function()
		while not racePicker:getSelectedRace() do
			task.wait(0.1)
		end
		selectedRace = racePicker:getSelectedRace()
		print("Race changed to:", selectedRace)
		applyRaceScale(character, selectedRace)
	end)
end

local function handlePortalEntry(difficulty)
	if gameState ~= "lobby" then return end
	selectedDifficulty = difficulty
	print("Entering dungeon with difficulty:", difficulty, "as race:", selectedRace)
	
	local event = ReplicatedStorage:WaitForChild("EnterDungeon")
	event:FireServer(selectedRace, selectedDifficulty)
	
	gameState = "dungeon"
	initializeDungeon()
end

local function setupEvents()
	print("Setting up client events...")
	
	local portalEvent = ReplicatedStorage:WaitForChild("DungeonPortalEntered")
	print("Portal event found, connecting...")
	portalEvent.OnClientEvent:Connect(function(difficulty)
		print("CLIENT: Portal event received:", difficulty)
		handlePortalEntry(difficulty)
	end)
	
	local raceEvent = ReplicatedStorage:WaitForChild("RaceSelectionRequested")
	print("Race event found, connecting...")
	raceEvent.OnClientEvent:Connect(function()
		print("CLIENT: Race selection requested")
		if gameState == "lobby" then
			showRacePickerLobby()
		end
	end)
	
	print("All client events connected!")
end

setupEvents()

local function createLightAbility(race)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if race == "Human" then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 255, 200)
		light.Brightness = 2
		light.Range = 30
		light.Parent = hrp
		return light
	elseif race == "Elf" then
		local leftEye = Instance.new("Part")
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Size = Vector3.new(0.3, 0.3, 0.3)
		leftEye.Color = Color3.fromRGB(0, 255, 100)
		leftEye.Material = Enum.Material.Neon
		leftEye.CanCollide = false
		leftEye.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 2 + Vector3.new(-0.3, 0.5, 0)
		leftEye.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(0, 255, 100)
		light.Brightness = 2
		light.Range = 25
		light.Parent = leftEye
		return leftEye
	elseif race == "Dwarf" then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(200, 150, 100)
		light.Brightness = 1.5
		light.Range = 20
		light.Parent = hrp
		return light
	elseif race == "Orc" then
		local torch = Instance.new("Part")
		torch.Shape = Enum.PartType.Cylinder
		torch.Size = Vector3.new(0.3, 1, 0.3)
		torch.Color = Color3.fromRGB(100, 50, 20)
		torch.Material = Enum.Material.Wood
		torch.CanCollide = false
		torch.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
		torch.Parent = workspace
		local flame = Instance.new("Part")
		flame.Shape = Enum.PartType.Ball
		flame.Size = Vector3.new(0.6, 0.6, 0.6)
		flame.Color = Color3.fromRGB(255, 150, 0)
		flame.Material = Enum.Material.Neon
		flame.CanCollide = false
		flame.CFrame = torch.CFrame + Vector3.new(0, 0.8, 0)
		flame.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 0)
		light.Brightness = 2
		light.Range = 28
		light.Parent = flame
		return {torch, flame}
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or gameState ~= "dungeon" then return end
	if input.KeyCode == Enum.KeyCode.F then
		lightActive = not lightActive
		if lightActive then
			createLightAbility(selectedRace)
			print(selectedRace .. " light activated!")
		else
			print(selectedRace .. " light deactivated!")
		end
	end
end)

RunService:BindToRenderStep("GameLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
	cameraController:update(dt)
	if gameState == "dungeon" then
		movementController:update(dt)
		inputHandler:update(dt)
		darkvision:update(dt)
		if playerStats then
			playerStats:update(dt)
		end
		if combatSystem then
			combatSystem:update(dt)
		end
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	cameraController:setCharacter(character)
	cameraController.currentPosition = nil
	lightActive = false
	if gameState == "dungeon" then
		playerStats = PlayerStats.new(character, selectedRace)
		combatSystem:setCharacter(character, playerStats)
	end
	applyRaceScale(character, selectedRace)
	print("Character respawned")
end)
