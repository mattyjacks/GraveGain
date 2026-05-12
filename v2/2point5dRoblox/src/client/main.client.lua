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
local WeaponGenerator = require(ClientFolder:WaitForChild("weapon_generator"))
local AnimationController = require(ClientFolder:WaitForChild("animation_controller"))
local InventoryManager = require(ClientFolder:WaitForChild("inventory_manager"))
local InventoryUI = require(ClientFolder:WaitForChild("inventory_ui"))

print("GraveGain 2.5D Client Started")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local selectedRace = "Human"
local selectedDifficulty = nil
local animationController = nil
local playerStats = nil
local lightActive = false
local gameState = "lobby"

local cameraController = CameraController.new()
cameraController:setCharacter(character)

local combatSystem = CombatSystem.new()
local movementController = MovementController.new()
local inputHandler = InputHandler.new(combatSystem)
local darkvision = Darkvision.new()

print("Player spawned as:", selectedRace)
applyRaceScale = function(char, raceName)
	local raceChangedEvent = ReplicatedStorage:WaitForChild("RaceChanged")
	raceChangedEvent:FireServer(raceName)
end
applyRaceScale(character, selectedRace)

local function setupReticule()
	local playerGui = player:WaitForChild("PlayerGui")
	local reticuleGui = playerGui:FindFirstChild("ReticuleGui")
	if not reticuleGui then
		reticuleGui = Instance.new("ScreenGui")
		reticuleGui.Name = "ReticuleGui"
		reticuleGui.Parent = playerGui

		local reticule = Instance.new("Frame")
		reticule.Name = "Reticule"
		reticule.Size = UDim2.new(0, 10, 0, 10)
		reticule.AnchorPoint = Vector2.new(0.5, 0.5)
		reticule.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		reticule.Position = UDim2.new(0.5, 0, 0.5, 0)
		reticule.BorderSizePixel = 0
		reticule.Parent = reticuleGui

		local mouse = player:GetMouse()
		RunService.RenderStepped:Connect(function()
			reticule.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
		end)
	end
end

-- Weld a model's PrimaryPart to a limb (called only when equipping, not at creation)
local function weldModelToLimb(model, limb, offset)
	-- Remove any old weld from this model
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("WeldConstraint") and desc.Part0 == limb then
			desc:Destroy()
		end
	end
	-- Unanchor all parts so welds take effect
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end
	model.Parent = character
	model.PrimaryPart.CFrame = limb.CFrame * (offset or CFrame.new())
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = limb
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
end

local function initializeDungeon()
	gameState = "dungeon"
	print("Entering dungeon as:", selectedRace)

	playerStats = PlayerStats.new(character, selectedRace)
	combatSystem:setCharacter(character, playerStats)

	animationController = AnimationController.new(character)
	inputHandler.animationController = animationController

	setupReticule()

	-- Race lights
	if selectedRace == "Dwarf" then
		darkvision:activate(character)
	elseif selectedRace == "Human" then
		local shoulder = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
		if shoulder then
			local light = Instance.new("SpotLight")
			light.Brightness = 3; light.Range = 40; light.Angle = 45
			light.Color = Color3.fromRGB(255, 240, 200)
			light.Parent = shoulder
		end
	elseif selectedRace == "Elf" then
		local head = character:FindFirstChild("Head")
		if head then
			local light1 = Instance.new("SpotLight")
			light1.Brightness = 2; light1.Range = 30; light1.Angle = 30
			light1.Color = Color3.fromRGB(200, 255, 255)
			light1.Face = Enum.NormalId.Front
			light1.Parent = head
			local light2 = light1:Clone()
			light2.Parent = head
		end
	end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")

	-- Create inventory and UI
	local inventoryManager = InventoryManager.new()
	local inventoryUI = InventoryUI.new(inventoryManager, inputHandler)
	inputHandler.inventoryUI = inventoryUI
	inputHandler.rightHand = rightHand

	-- Build all weapon models (unparented until equipped)
	local stick = WeaponGenerator.createStick()
	local bow = WeaponGenerator.createBow()
	local potion = WeaponGenerator.createPotion()
	local grenade = WeaponGenerator.createFragGrenade()
	local flash = WeaponGenerator.createFlashbang()
	local molotov = WeaponGenerator.createMolotov()

	-- Equip slots store: { name, w, h, model, type, color, offset }
	inventoryUI.equips.Primary = {
		name = "Wooden Stick", w = 1, h = 3, rotated = false, model = stick,
		color = Color3.fromRGB(150, 100, 50),
		offset = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
	}
	inventoryUI.equips.Secondary = {
		name = "Recurve Bow", w = 2, h = 3, rotated = false, model = bow,
		color = Color3.fromRGB(100, 150, 100),
		offset = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
	}
	inventoryUI.equips.Consumable = {
		name = "Health Potion", w = 1, h = 1, rotated = false, model = potion,
		color = Color3.fromRGB(50, 255, 50),
		offset = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	}
	inventoryUI.equips.Throwable = {
		name = "Frag Grenade", w = 1, h = 1, rotated = false, model = grenade,
		type = "Frag", color = Color3.fromRGB(100, 100, 100),
		offset = CFrame.new(0, -0.5, 0)
	}

	-- Add extras to the inventory grid
	inventoryManager:addItem({name = "Flashbang", w = 1, h = 1, rotated = false, model = flash, type = "Flash", color = Color3.fromRGB(200, 200, 255)})
	inventoryManager:addItem({name = "Molotov", w = 1, h = 2, rotated = false, model = molotov, type = "Molotov", color = Color3.fromRGB(255, 100, 50)})

	-- Always show shield in left hand
	if leftHand then
		local shield = WeaponGenerator.createShield()
		weldModelToLimb(shield, leftHand, CFrame.new(0.5, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
	end

	-- Start in Melee mode — show stick in right hand
	if rightHand then
		weldModelToLimb(stick, rightHand, CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0))
	end
	inputHandler.weaponMode = "Melee" -- set directly, no "swap" needed yet
	inputHandler.character = character
	inputHandler.rightHand = rightHand

	inventoryUI:renderItems()

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	inputHandler.isEnabled = true

	print("All client systems initialized")
	print("Controls: WASD-Move | Shift-Sprint | 1-4 Weapons | I-Inventory | F-Light")
end

local function showRacePickerLobby()
	local racePicker = LobbyRacePicker.new()
	racePicker:show()
	task.spawn(function()
		while not racePicker:getSelectedRace() do task.wait(0.1) end
		selectedRace = racePicker:getSelectedRace()
		print("Race changed to:", selectedRace)
		applyRaceScale(character, selectedRace)
	end)
end

local function showMissionSelectionUI(difficulty)
	if gameState ~= "lobby" then return end
	selectedDifficulty = difficulty

	local playerGui = player:WaitForChild("PlayerGui")
	-- Prevent duplicate UIs
	local existing = playerGui:FindFirstChild("MissionSelectionUI")
	if existing then existing:Destroy() end

	local ui = Instance.new("ScreenGui")
	ui.Name = "MissionSelectionUI"
	ui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 420, 0, 320)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.Parent = ui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Text = "Select Mission — " .. difficulty
	title.TextSize = 22
	title.TextColor3 = Color3.fromRGB(255, 220, 100)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local function makeBtn(text, desc, yPos, missionType, col)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.85, 0, 0, 60)
		btn.Position = UDim2.new(0.075, 0, 0, yPos)
		btn.BackgroundColor3 = col or Color3.fromRGB(60, 80, 120)
		btn.Text = text .. "\n" .. desc
		btn.TextSize = 15
		btn.TextWrapped = true
		btn.Font = Enum.Font.Gotham
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = frame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			ui:Destroy()
			local event = ReplicatedStorage:WaitForChild("EnterDungeon")
			event:FireServer(selectedRace, difficulty, missionType)
			gameState = "dungeon"
			initializeDungeon()
		end)
	end

	makeBtn("☠  Kill the Boss", "Slay the Giant Skull, then reach the Space Elevator", 70, "Boss", Color3.fromRGB(150, 30, 30))
	makeBtn("📦  Fetch Quest", "Retrieve the artifact and escape — enemies will flood in", 150, "Fetch", Color3.fromRGB(30, 100, 60))

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.new(0.4, 0, 0, 36)
	cancel.Position = UDim2.new(0.3, 0, 0, 240)
	cancel.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	cancel.Text = "Cancel"
	cancel.TextSize = 16
	cancel.Font = Enum.Font.Gotham
	cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancel.Parent = frame
	Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 6)
	cancel.MouseButton1Click:Connect(function() ui:Destroy() end)
end

local function setupEvents()
	local portalEvent = ReplicatedStorage:WaitForChild("DungeonPortalEntered")
	portalEvent.OnClientEvent:Connect(function(difficulty)
		showMissionSelectionUI(difficulty)
	end)

	local raceEvent = ReplicatedStorage:WaitForChild("RaceSelectionRequested")
	raceEvent.OnClientEvent:Connect(function()
		if gameState == "lobby" then showRacePickerLobby() end
	end)
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
		light.Brightness = 2; light.Range = 30
		light.Parent = hrp
	elseif race == "Elf" then
		local leftEye = Instance.new("Part")
		leftEye.Shape = Enum.PartType.Ball; leftEye.Size = Vector3.new(0.3, 0.3, 0.3)
		leftEye.Color = Color3.fromRGB(0, 255, 100); leftEye.Material = Enum.Material.Neon
		leftEye.CanCollide = false
		leftEye.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 2 + Vector3.new(-0.3, 0.5, 0)
		leftEye.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(0, 255, 100); light.Brightness = 2; light.Range = 25
		light.Parent = leftEye
	elseif race == "Dwarf" then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(200, 150, 100); light.Brightness = 1.5; light.Range = 20
		light.Parent = hrp
	elseif race == "Orc" then
		local torch = Instance.new("Part")
		torch.Shape = Enum.PartType.Cylinder; torch.Size = Vector3.new(0.3, 1, 0.3)
		torch.Color = Color3.fromRGB(100, 50, 20); torch.Material = Enum.Material.Wood
		torch.CanCollide = false
		torch.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
		torch.Parent = workspace
		local flame = Instance.new("Part")
		flame.Shape = Enum.PartType.Ball; flame.Size = Vector3.new(0.6, 0.6, 0.6)
		flame.Color = Color3.fromRGB(255, 150, 0); flame.Material = Enum.Material.Neon
		flame.CanCollide = false; flame.CFrame = torch.CFrame + Vector3.new(0, 0.8, 0)
		flame.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 0); light.Brightness = 2; light.Range = 28
		light.Parent = flame
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
		if playerStats then playerStats:update(dt) end
		if combatSystem then combatSystem:update(dt) end
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
