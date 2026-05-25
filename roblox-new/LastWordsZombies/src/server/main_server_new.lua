-- Main server orchestrator for Last Words Zombies
-- Thin: delegates to corridor, zombie_spawner, game_state

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")

local GameData      = require(ReplicatedStorage:WaitForChild("GameData"))
local RemoteNames   = require(ReplicatedStorage:WaitForChild("RemoteNames"))
local Corridor      = require(script.Parent.Corridor)
local ZombieSpawner = require(script.Parent.ZombieSpawnerNew)
local GameState     = require(script.Parent.GameState)

-- Build RemoteEvents folder
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage
for _, name in ipairs(RemoteNames) do
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = RemoteEvents
end

local RE = RemoteEvents

-- Environment
local function SetupLighting()
	Lighting.Ambient  = Color3.new(GameData.VISUALS.AMBIENT_LIGHT, GameData.VISUALS.AMBIENT_LIGHT, GameData.VISUALS.AMBIENT_LIGHT)
	Lighting.FogColor = GameData.VISUALS.FOG_COLOR
	Lighting.FogEnd   = GameData.VISUALS.FOG_END
	Lighting.FogStart = GameData.VISUALS.FOG_END * 0.5
end

-- Game flow
local function StartGame()
	print("Starting Last Words Zombies!")
	GameState.Reset()
	ZombieSpawner.WaveNumber = 1
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	ZombieSpawner.Cleanup()
	ZombieSpawner.OnGameOver = function(reason) EndGame(reason) end
	RE.GameStart:FireAllClients()
end

function EndGame(reason)
	print("Game ended:", reason)
	GameState.isRunning = false
	ZombieSpawner.Cleanup()
	RE.GameOver:FireAllClients(reason, GameState.score, GameState.GetDefeatedWordsList())
end

-- Remote event handlers
local function OnZombieTargeted(player, firstLetter)
	local zd = ZombieSpawner.GetClosestZombieByLetter(firstLetter)
	if zd then
		RE.ZombieTargetResponse:FireClient(player, zd.Model, zd.Word)
	else
		RE.ZombieTargetResponse:FireClient(player, nil, nil)
	end
end

local function OnWordProgress(player, zombieModel, typedLetters)
	local zd = ZombieSpawner.GetZombieByModel(zombieModel)
	if zd then ZombieSpawner.UpdateZombieWord(zd, typedLetters) end
end

local function OnWordComplete(player, zombieModel)
	local zd = ZombieSpawner.GetZombieByModel(zombieModel)
	if not zd then return end
	GameState.AddDefeatedWord(zd.Word, player.Name, GameState.currentWave)
	local pos = zd.Model.PrimaryPart and zd.Model.PrimaryPart.Position
	ZombieSpawner.DestroyZombie(zd, pos)
	GameState.score = GameState.score + GameData.SCORE.WORD_COMPLETE_BASE
	RE.WaveComplete:FireAllClients(GameState.currentWave, GameState.score)
end

local function OnGameStart(player)
	print("Restart requested by:", player.Name)
	StartGame()
end

local function OnPlayerReady(player)
	if GameState.isRunning or GameState.hasEverStarted then return end
	GameState.playersReady[player.UserId] = true
	local total, ready = #Players:GetPlayers(), 0
	for _ in pairs(GameState.playersReady) do ready = ready + 1 end
	if ready >= total and total > 0 then StartGame() end
end

-- Player events
local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
	end)
	if not player.Character then player:LoadCharacter() end
end

-- Update loop
local lastSurvivalBonus = 0
RunService.Heartbeat:Connect(function(dt)
	if not GameState.isRunning then return end
	ZombieSpawner.Update(dt)
	-- Survival bonus every 5 seconds
	local t = math.floor(tick() - GameState.startTime)
	if t > lastSurvivalBonus and t % 5 == 0 then
		lastSurvivalBonus = t
		GameState.score = GameState.score + GameData.SCORE.SURVIVAL_TIME_BONUS
	end
end)

-- Wire everything up
SetupLighting()
local coverPositions = Corridor.Build()
ZombieSpawner.CoverPositions = coverPositions

RE.ZombieTargeted.OnServerEvent:Connect(OnZombieTargeted)
RE.WordProgress.OnServerEvent:Connect(OnWordProgress)
RE.WordComplete.OnServerEvent:Connect(OnWordComplete)
RE.GameStart.OnServerEvent:Connect(OnGameStart)
RE.PlayerReady.OnServerEvent:Connect(OnPlayerReady)
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(function(p) GameState.playersReady[p.UserId] = nil end)

return {}
