-- main.client.lua (CLIENT)
-- Entry point for the GraveGain client. Orchestrates controllers, HUD, and world transitions.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientFolder = script.Parent
local CameraController = require(ClientFolder:WaitForChild("camera_controller"))
local MovementController = require(ClientFolder:WaitForChild("movement_controller"))
local InputHandler = require(ClientFolder:WaitForChild("input_handler"))
local PlayerStats = require(ClientFolder:WaitForChild("player_stats"))
local CombatSystem = require(ClientFolder:WaitForChild("combat_system"))
local WeaponGenerator   = require(ClientFolder:WaitForChild("weapon_generator"))
local AnimationController = require(ClientFolder:WaitForChild("animation_controller"))
local InventoryManager  = require(ClientFolder:WaitForChild("inventory_manager"))
local InventoryUI       = require(ClientFolder:WaitForChild("inventory_ui"))
local HUDSystem         = require(ClientFolder:WaitForChild("hud_system"))
local SM                = require(ClientFolder:WaitForChild("sound_manager"))
local SpaceEnv        = require(ClientFolder:WaitForChild("space_environment"))
local UtilityHandler  = require(ClientFolder:WaitForChild("utility_handler"))
local TalentUI        = require(ClientFolder:WaitForChild("talent_ui"))
local LobbyRacePicker = require(ClientFolder:WaitForChild("lobby_race_picker"))
local ParachuteHandler = require(ClientFolder:WaitForChild("parachute_handler"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))
local LoadingScreen     = require(ClientFolder:WaitForChild("loading_screen"))
local Minimap           = require(ClientFolder:WaitForChild("minimap"))
local EnemyHealthbars   = require(ClientFolder:WaitForChild("enemy_healthbars"))
local DeathScreen       = require(ClientFolder:WaitForChild("death_screen"))
local ZoneRenderer      = require(ClientFolder:WaitForChild("zone_renderer"))

-- ── State ──────────────────────────────────────────────────────────────────

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local selectedRace = "Human"
local gameState = "lobby"

local cameraController = CameraController.new()
local combatSystem       = CombatSystem.new()
local movementController = MovementController.new()
local inputHandler       = InputHandler.new(combatSystem)
local utilityHandler     = nil
local playerStats        = nil
local hud                = nil
local talentUI           = nil
local parachuteHandler   = nil

-- ── Initialization ─────────────────────────────────────────────────────────

LoadingScreen.show("Synchronizing Neural Link...")
EnemyHealthbars.start()
DeathScreen.setup()

local function applyRaceScale(char, raceName)
	local event = ReplicatedStorage:WaitForChild("RaceChanged")
	event:FireServer(raceName)
end

local function startChunkRequestLoop()
	task.spawn(function()
		local CHUNK_SIZE = GameData.WORLD_CONFIG.chunkSize
		local RENDER_DIST = GameData.WORLD_CONFIG.renderDistance
		local requestEvent = ReplicatedStorage:WaitForChild("RequestChunk")
		
		while true do
			local char = Players.LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local px, pz = hrp.Position.X, hrp.Position.Z
				local cx = math.floor(px / CHUNK_SIZE + 0.5)
				local cz = math.floor(pz / CHUNK_SIZE + 0.5)
				
				for dx = -RENDER_DIST, RENDER_DIST do
					for dz = -RENDER_DIST, RENDER_DIST do
						requestEvent:FireServer(cx + dx, cz + dz)
					end
				end
			end
			task.wait(1.5)
		end
	end)
end

local function initializeOpenWorld()
	gameState = "openworld"
	print("Entering Open World")
	
	SpaceEnv.applyExterior()
	
	playerStats = PlayerStats.new(character, selectedRace)
	combatSystem:setCharacter(character, playerStats)
	utilityHandler = UtilityHandler.new(playerStats)
	
	hud = HUDSystem.new(playerStats, inputHandler)
	hud:setObjective("Explore the biomes and find a dungeon portal")
	
	inputHandler.isEnabled = true
	inputHandler.character = character
	
	startChunkRequestLoop()
	applyRaceScale(character, selectedRace)
	
	talentUI = TalentUI.new(playerStats)
	parachuteHandler = ParachuteHandler.new(character)
end

local function initializeDungeon()
	gameState = "dungeon"
	print("Entering Dungeon")
	
	SpaceEnv.applyDungeon()
	
	if hud then
		hud:setObjective("Survive the dungeon and complete the mission")
	end
end

-- ── Main Loop ──────────────────────────────────────────────────────────────

RunService:BindToRenderStep("GameLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
	cameraController:update(dt)
	if gameState == "openworld" or gameState == "dungeon" then
		movementController:update(dt)
		inputHandler:update(dt)
		if playerStats then playerStats:update(dt) end
		if combatSystem then combatSystem:update(dt) end
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	cameraController:setCharacter(character)
	
	-- If we spawned high in the air, we are back in the lobby
	if character:GetPivot().Position.Y > 500 then
		gameState = "lobby"
	end
	
	if playerStats then
		playerStats = PlayerStats.new(character, selectedRace)
		combatSystem:setCharacter(character, playerStats)
	end
	if utilityHandler then
		utilityHandler.darkvisionActive = false -- Reset effects
	end
	applyRaceScale(character, selectedRace)
end)

-- ── Events ─────────────────────────────────────────────────────────────────

local isPickerOpen = false
ReplicatedStorage:WaitForChild("RaceSelectionRequested").OnClientEvent:Connect(function()
	LoadingScreen.hide(0.5) -- Show lobby immediately for race picking
	if (gameState == "lobby" or gameState == "openworld") and not isPickerOpen then
		isPickerOpen = true
		local racePicker = LobbyRacePicker.new()
		racePicker:show()
		
		task.spawn(function()
			while not racePicker:getSelectedRace() do task.wait(0.1) end
			selectedRace = racePicker:getSelectedRace()
			isPickerOpen = false
			initializeOpenWorld()
		end)
	end
end)

-- Start chunk loop early in the background
startChunkRequestLoop()

-- Sync stats from server
ReplicatedStorage:WaitForChild("SyncPlayerStats").OnClientEvent:Connect(function(level, xp, talentPoints, talents)
	if playerStats then
		playerStats.level = level
		playerStats.xp = xp
		playerStats.talentPoints = talentPoints
		playerStats.talents = talents
	end
end)

-- Visual unlock of holes
ReplicatedStorage:WaitForChild("UnlockLobbyHoles").OnClientEvent:Connect(function()
	local TweenService = game:GetService("TweenService")
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then return end
	
	for _, shield in ipairs(lobby:GetDescendants()) do
		if shield.Name == "HoleShield" and shield:IsA("BasePart") then
			TweenService:Create(shield, TweenInfo.new(1.5), {
				Transparency = 1,
				Color = Color3.fromRGB(50, 255, 100)
			}):Play()
		end
	end
end)

print("GraveGain 2.5D Client Fully Initialized")
