-- Main server script for Dead-Letter Drop
-- Coordinates all game systems and handles networking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Require modules
local ZombieSpawner = require(script.Parent.ZombieSpawner)
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

-- Create remote events
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

-- Create required remote events
local events = {
	"ZombieTargeted",
	"ZombieTargetResponse",
	"WordProgress", 
	"WordComplete",
	"GameOver",
	"WaveComplete",
	"GameStart",
	"PlayerReady"
}

for _, eventName in ipairs(events) do
	local event = Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = RemoteEvents
end

-- Game state
local gameState = {
	isRunning = false,
	currentWave = 1,
	score = 0,
	startTime = 0,
	playersReady = {},
	defeatedWords = {} -- Track all words players have defeated
}

-- Initialize game
function InitializeGame()
	print("Dead-Letter Drop Server Initialized")
	
	-- Set up environment
	SetupEnvironment()
	
	-- Connect player events
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	
	-- Connect remote events
	ConnectRemoteEvents()
	
	-- Start game loop
	RunService.Heartbeat:Connect(UpdateGame)
end

-- Set up game environment
function SetupEnvironment()
	-- Set lighting
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.new(GameData.VISUALS.AMBIENT_LIGHT, GameData.VISUALS.AMBIENT_LIGHT, GameData.VISUALS.AMBIENT_LIGHT)
	lighting.FogColor = GameData.VISUALS.FOG_COLOR
	lighting.FogEnd = GameData.VISUALS.FOG_END
	lighting.FogStart = GameData.VISUALS.FOG_END * 0.5
	
	-- Create corridor environment
	CreateCorridor()
	-- Share cover positions with zombie spawner
	ZombieSpawner.CoverPositions = CoverPositions
end

-- Shared cover positions for zombie spawning (set during corridor creation)
CoverPositions = {}

-- Helper: anchored part
local function MakePart(parent, name, size, pos, color, material, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.Concrete
	p.Anchored = true
	p.CanCollide = canCollide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Create corridor environment
function CreateCorridor()
	local corridor = Instance.new("Model")
	corridor.Name = "Corridor"
	corridor.Parent = workspace

	local W = GameData.VISUALS.CORRIDOR_WIDTH
	local H = GameData.VISUALS.CORRIDOR_HEIGHT
	local L = GameData.VISUALS.CORRIDOR_LENGTH
	local hw = W / 2

	-- Floor tiles (alternating dark concrete)
	local tileSize = 10
	for tx = -hw, hw - tileSize, tileSize do
		for tz = -L/2, L/2 - tileSize, tileSize do
			local isDark = ((math.floor(tx/tileSize) + math.floor(tz/tileSize)) % 2 == 0)
			MakePart(corridor, "FloorTile",
				Vector3.new(tileSize, 1, tileSize),
				Vector3.new(tx + tileSize/2, -0.5, tz + tileSize/2),
				isDark and Color3.new(0.18, 0.18, 0.22) or Color3.new(0.28, 0.28, 0.32),
				Enum.Material.SmoothPlastic)
		end
	end

	-- Left wall
	MakePart(corridor, "LeftWall", Vector3.new(1, H, L), Vector3.new(-hw - 0.5, H/2, 0), Color3.new(0.2, 0.2, 0.25))
	-- Right wall
	MakePart(corridor, "RightWall", Vector3.new(1, H, L), Vector3.new(hw + 0.5, H/2, 0), Color3.new(0.2, 0.2, 0.25))
	-- Ceiling
	MakePart(corridor, "Ceiling", Vector3.new(W + 2, 1, L), Vector3.new(0, H + 0.5, 0), Color3.new(0.15, 0.15, 0.18))

	-- Wall trim strips (neon red accent along base and top of walls)
	for _, side in ipairs({-hw - 0.3, hw + 0.3}) do
		local strip = MakePart(corridor, "WallStrip", Vector3.new(0.3, 0.4, L), Vector3.new(side, 0.7, 0), Color3.new(0.8, 0.05, 0.05), Enum.Material.Neon, false)
		local strip2 = MakePart(corridor, "WallStrip", Vector3.new(0.3, 0.4, L), Vector3.new(side, H - 1, 0), Color3.new(0.6, 0.03, 0.03), Enum.Material.Neon, false)
	end

	AddCorridorDetails(corridor)
end

-- Add visual details to corridor
function AddCorridorDetails(corridor)
	local W = GameData.VISUALS.CORRIDOR_WIDTH
	local H = GameData.VISUALS.CORRIDOR_HEIGHT
	local L = GameData.VISUALS.CORRIDOR_LENGTH
	local hw = W / 2

	-- Ceiling pipes (run full length)
	local pipeColors = {Color3.new(0.35,0.25,0.18), Color3.new(0.28,0.28,0.32), Color3.new(0.4,0.18,0.1)}
	for i = 1, 6 do
		local px = -hw + (i * W/7)
		local pipe = MakePart(corridor, "Pipe",
			Vector3.new(0.6, 0.6, L),
			Vector3.new(px, H - 1.5, 0),
			pipeColors[(i % 3) + 1], Enum.Material.Metal, false)
	end

	-- Hanging cables between pipes
	for i = 1, 12 do
		local cz = -L/2 + (i * L/13)
		local cable = MakePart(corridor, "Cable",
			Vector3.new(W * 0.6, 0.2, 0.2),
			Vector3.new(0, H - 3, cz),
			Color3.new(0.1, 0.1, 0.1), Enum.Material.Metal, false)
	end

	-- Emergency lights
	for i = 1, 14 do
		local lx = (i % 2 == 0) and -hw * 0.5 or hw * 0.5
		local lz = -L/2 + (i * L/15)
		local lp = MakePart(corridor, "LightFixture",
			Vector3.new(1.5, 0.4, 1.5),
			Vector3.new(lx, H - 0.5, lz),
			Color3.new(0.25, 0.08, 0.08), Enum.Material.Neon, false)
		local light = Instance.new("PointLight")
		light.Color = Color3.new(1, 0.15, 0.08)
		light.Brightness = 3
		light.Range = 28
		light.Parent = lp
	end

	-- Wall damage / graffiti strips
	for i = 1, 20 do
		local side = (i % 2 == 0) and -hw or hw
		local wz = -L/2 + math.random() * L
		local wy = 1 + math.random() * (H * 0.6)
		local wh = 0.5 + math.random() * 2
		local ww = 1 + math.random() * 4
		MakePart(corridor, "WallDamage",
			Vector3.new(0.2, wh, ww),
			Vector3.new(side, wy, wz),
			Color3.new(0.12, 0.04, 0.04), Enum.Material.SmoothPlastic, false)
	end

	-- Pillars (pairs, every ~25 studs along corridor)
	for iz = 1, 7 do
		local pz = -L/2 + 20 + (iz - 1) * 25
		for _, side in ipairs({-hw * 0.75, hw * 0.75}) do
			MakePart(corridor, "Pillar",
				Vector3.new(3, H, 3),
				Vector3.new(side, H/2, pz),
				Color3.new(0.22, 0.22, 0.27), Enum.Material.Concrete)
			-- Neon trim on pillar
			MakePart(corridor, "PillarTrim",
				Vector3.new(3.2, 0.3, 3.2),
				Vector3.new(side, 0.8, pz),
				Color3.new(0.7, 0.05, 0.05), Enum.Material.Neon, false)
		end
	end

	-- Crates / cover objects (track positions for zombie spawning)
	CoverPositions = {}
	local crateData = {
		-- {x, z, w, d, h}
		{-hw*0.5, -80, 4, 4, 5}, { hw*0.5, -70, 3, 6, 4},
		{-hw*0.6, -50, 5, 3, 4}, { hw*0.55, -40, 4, 4, 5},
		{-hw*0.4, -20, 3, 3, 3}, { hw*0.4, -10, 6, 3, 4},
		{ hw*0.3, -95, 4, 5, 5}, {-hw*0.35, -60, 3, 4, 4},
		{-hw*0.5, -130, 5, 4, 6}, { hw*0.5,-120, 4, 4, 5},
	}
	for _, cd in ipairs(crateData) do
		local cx, cz, cw, cd2, ch = cd[1], cd[2], cd[3], cd[4], cd[5]
		MakePart(corridor, "Crate",
			Vector3.new(cw, ch, cd2),
			Vector3.new(cx, ch/2, cz),
			Color3.new(0.35, 0.25, 0.12), Enum.Material.Wood)
		-- Neon hazard stripe
		MakePart(corridor, "CrateStripe",
			Vector3.new(cw + 0.1, 0.3, cd2 + 0.1),
			Vector3.new(cx, ch * 0.6, cz),
			Color3.new(0.9, 0.5, 0), Enum.Material.Neon, false)
		-- Store as cover spawn position (slightly behind crate)
		table.insert(CoverPositions, Vector3.new(cx, 3, cz - 2))
	end

	-- Barrels
	for i = 1, 8 do
		local bx = (math.random() - 0.5) * W * 0.7
		local bz = -L/2 + 15 + math.random() * (L - 30)
		MakePart(corridor, "Barrel",
			Vector3.new(2, 3, 2),
			Vector3.new(bx, 1.5, bz),
			Color3.new(0.3, 0.1, 0.05), Enum.Material.Metal)
		table.insert(CoverPositions, Vector3.new(bx, 3, bz - 1))
	end
end

-- Handle player joining
function OnPlayerAdded(player)
	print("Player joined:", player.Name)
	
	-- Set up player camera
	player.CharacterAdded:Connect(function(character)
		SetupPlayerCamera(player)
	end)
	
	-- Create starter character if none exists
	if not player.Character then
		player:LoadCharacter()
	end
end

-- Handle player leaving
function OnPlayerRemoving(player)
	print("Player left:", player.Name)
	
	-- Remove from ready list
	gameState.playersReady[player.UserId] = nil
end

-- Set up player camera
function SetupPlayerCamera(player)
	local character = player.Character
	if not character then return end
	
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
end

-- Connect remote events
function ConnectRemoteEvents()
	RemoteEvents.ZombieTargeted.OnServerEvent:Connect(OnZombieTargeted)
	RemoteEvents.WordProgress.OnServerEvent:Connect(OnWordProgress)
	RemoteEvents.WordComplete.OnServerEvent:Connect(OnWordComplete)
	RemoteEvents.GameStart.OnServerEvent:Connect(OnGameStart)
	RemoteEvents.PlayerReady.OnServerEvent:Connect(OnPlayerReady)
end

-- Handle zombie targeting request
function OnZombieTargeted(player, firstLetter)
	local zombie = ZombieSpawner.GetClosestZombieByLetter(firstLetter)
	
	if zombie then
		-- Send back: Model reference + word so client can track progress
		RemoteEvents.ZombieTargetResponse:FireClient(player, zombie.Model, zombie.Word)
	else
		RemoteEvents.ZombieTargetResponse:FireClient(player, nil, nil)
	end
end

-- Handle word progress
function OnWordProgress(player, zombieModel, typedLetters)
	local zombieData = ZombieSpawner.GetZombieByModel(zombieModel)
	if zombieData then
		ZombieSpawner.UpdateZombieWord(zombieData, typedLetters)
	end
end

-- Handle word completion
function OnWordComplete(player, zombieModel)
	local zombieData = ZombieSpawner.GetZombieByModel(zombieModel)
	if zombieData then
		-- Track the defeated word
		local word = zombieData.Word
		if word and not gameState.defeatedWords[word] then
			gameState.defeatedWords[word] = {
				word = word,
				defeatedBy = player.Name,
				time = tick(),
				wave = gameState.currentWave
			}
		end
		
		-- Destroy zombie with explosion
		local pos = zombieData.Model.PrimaryPart and zombieData.Model.PrimaryPart.Position
		ZombieSpawner.DestroyZombie(zombieData, pos)
		
		-- Update score
		gameState.score = gameState.score + GameData.SCORE.WORD_COMPLETE_BASE
		
		-- Send score update to all clients
		RemoteEvents.WaveComplete:FireAllClients(gameState.currentWave, gameState.score)
	end
end

-- Handle game start (restart button)
function OnGameStart(player)
	print("Game start requested by:", player.Name)
	-- Always allow restart regardless of isRunning state
	StartGame()
end

-- Handle player ready (initial start only)
function OnPlayerReady(player)
	-- Only used for the first start - if already running or started, ignore
	if gameState.isRunning or gameState.hasEverStarted then return end
	gameState.playersReady[player.UserId] = true
	
	local playerCount = #Players:GetPlayers()
	local readyCount = 0
	for _, _ in pairs(gameState.playersReady) do
		readyCount = readyCount + 1
	end
	
	if readyCount == playerCount and playerCount > 0 then
		StartGame()
	end
end

-- Start the game
function StartGame()
	print("Starting Last Words Zombies!")
	
	gameState.isRunning = true
	gameState.hasEverStarted = true
	gameState.currentWave = 1
	gameState.score = 0
	gameState.defeatedWords = {} -- reset between games
	gameState.playersReady = {}
	gameState.startTime = tick()
	
	-- Reset zombie spawner
	ZombieSpawner.WaveNumber = 1
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	ZombieSpawner.Cleanup()

	-- Wire game over callback so spawner uses real score + words
	ZombieSpawner.OnGameOver = function(reason)
		EndGame(reason)
	end
	
	-- Notify clients
	RemoteEvents.GameStart:FireAllClients()
end

-- End the game
function EndGame(reason)
	print("Game ended:", reason)
	
	gameState.isRunning = false
	
	-- Clean up zombies
	ZombieSpawner.Cleanup()
	
	-- Prepare defeated words data for clients
	local defeatedWordsList = {}
	for word, data in pairs(gameState.defeatedWords) do
		table.insert(defeatedWordsList, data)
	end
	
	-- Sort words alphabetically
	table.sort(defeatedWordsList, function(a, b)
		return a.word < b.word
	end)
	
	-- Notify clients with defeated words
	RemoteEvents.GameOver:FireAllClients(reason, gameState.score, defeatedWordsList)
end

-- Update game loop
function UpdateGame(deltaTime)
	if not gameState.isRunning then return end
	
	-- Update zombie spawner
	ZombieSpawner.Update(deltaTime)
	
	-- Check wave completion
	-- (Handled in ZombieSpawner)
	
	-- Check survival time bonus
	local survivalTime = tick() - gameState.startTime
	if survivalTime > 0 then
		-- Add survival bonus every second
		local timeBonus = math.floor(survivalTime)
		if timeBonus > 0 and timeBonus % 5 == 0 then
			gameState.score = gameState.score + GameData.SCORE.SURVIVAL_TIME_BONUS
		end
	end
end

-- Handle wave completion
function OnWaveComplete(waveNumber)
	print("Wave", waveNumber, "completed!")
	
	-- Award wave completion bonus
	gameState.score = gameState.score + GameData.SCORE.WAVE_COMPLETE
	
	-- Notify clients
	RemoteEvents.WaveComplete:FireAllClients(waveNumber, gameState.score)
end

-- Initialize the game
InitializeGame()

return {}
