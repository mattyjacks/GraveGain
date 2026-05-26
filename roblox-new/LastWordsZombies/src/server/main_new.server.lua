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

print("[SERVER BOOT] All modules required successfully")
print("[SERVER BOOT] GameData.ZOMBIE.SPEED_BASE =", GameData.ZOMBIE.SPEED_BASE)
print("[SERVER BOOT] GameData.ZOMBIE.MAX_ZOMBIES =", GameData.ZOMBIE.MAX_ZOMBIES)
print("[SERVER BOOT] GameData.ZOMBIE.SPAWN_RATE_BASE =", GameData.ZOMBIE.SPAWN_RATE_BASE)
print("[SERVER BOOT] GameData.WAVES.ZOMBIES_PER_WAVE =", GameData.WAVES.ZOMBIES_PER_WAVE)

-- Build RemoteEvents folder
print("[SERVER BOOT] Creating RemoteEvents folder with", #RemoteNames, "events")
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage
for _, name in ipairs(RemoteNames) do
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = RemoteEvents
	print("[SERVER BOOT] Created RemoteEvent:", name)
end
print("[SERVER BOOT] RemoteEvents folder ready in ReplicatedStorage")

local RE = RemoteEvents

-- Environment
local function SetupLighting()
	print("[LIGHTING] Setting up lighting - killing sky, baseplate, setting dark ambient")
	Lighting.Ambient         = Color3.new(0.06, 0.04, 0.04)
	Lighting.OutdoorAmbient  = Color3.new(0.04, 0.02, 0.02)
	Lighting.Brightness      = 0
	Lighting.GlobalShadows   = true
	Lighting.FogColor        = Color3.new(0.05, 0.02, 0.02)
	Lighting.FogEnd          = 120
	Lighting.FogStart        = 40
	-- Kill the default sky so it doesn't bleed red
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		print("[LIGHTING] Sky found and destroyed:", sky.Name)
		sky:Destroy()
	else
		print("[LIGHTING] WARNING: No Sky found in Lighting - sky may still be bleeding ambient")
	end
	-- Remove Baseplate so it doesn't cast red light upward
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		print("[LIGHTING] Baseplate found and destroyed")
		baseplate:Destroy()
	else
		print("[LIGHTING] No Baseplate found (already gone or never existed)")
	end
	print("[LIGHTING] Final values: Ambient=", Lighting.Ambient, "OutdoorAmbient=", Lighting.OutdoorAmbient, "Brightness=", Lighting.Brightness)
end

-- Game flow
local function StartGame()
	print("[STARTGAME] ====== GAME STARTING ======")
	print("[STARTGAME] Players online:", #game:GetService("Players"):GetPlayers())
	print("[STARTGAME] Previous GameState.isRunning:", GameState.isRunning)
	print("[STARTGAME] Previous score:", GameState.score, "wave:", GameState.currentWave)
	print("[STARTGAME] Active zombies before cleanup:", #ZombieSpawner.ActiveZombies)
	print("[STARTGAME] ZombieSpawner.NextSpawnTime before reset:", ZombieSpawner.NextSpawnTime, "(tick is", tick(), ")")
	GameState.Reset()
	ZombieSpawner.WaveNumber = 1
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	ZombieSpawner.Cleanup()
	ZombieSpawner.OnGameOver = function(reason) EndGame(reason) end
	print("[STARTGAME] ZombieSpawner.NextSpawnTime after reset:", ZombieSpawner.NextSpawnTime)
	print("[STARTGAME] CoverPositions available:", #ZombieSpawner.CoverPositions)
	local ws = GameData.CalculateWaveSettings(1)
	print("[STARTGAME] Wave 1 settings: speed=", ws.zombieSpeed, "spawnRate=", ws.spawnRate, "zombiesPerWave=", ws.zombiesPerWave, "difficulty=", ws.wordDifficulty)
	RE.GameStart:FireAllClients()
	print("[STARTGAME] GameStart RemoteEvent fired to all clients")
end

function EndGame(reason)
	print("[ENDGAME] ====== GAME OVER ======")
	print("[ENDGAME] Reason:", reason)
	print("[ENDGAME] Final score:", GameState.score)
	print("[ENDGAME] Wave reached:", GameState.currentWave)
	print("[ENDGAME] Active zombies at game over:", #ZombieSpawner.ActiveZombies)
	local defeatedList = GameState.GetDefeatedWordsList()
	print("[ENDGAME] Defeated words count:", #defeatedList)
	for i, wd in ipairs(defeatedList) do
		print("[ENDGAME]   Word", i, ":", wd.word, "by", wd.defeatedBy, "on wave", wd.wave)
	end
	GameState.isRunning = false
	ZombieSpawner.Cleanup()
	RE.GameOver:FireAllClients(reason, GameState.score, defeatedList)
	print("[ENDGAME] GameOver event fired to all clients")
end

-- Remote event handlers
local function OnZombieTargeted(player, prefix)
	print("[TARGET] Player", player.Name, "targeting with prefix='" .. tostring(prefix) .. "'")
	print("[TARGET] Active zombies to search:", #ZombieSpawner.ActiveZombies)
	for i, zd in ipairs(ZombieSpawner.ActiveZombies) do
		if zd.IsAlive and zd.Model and zd.Model.PrimaryPart then
			print("[TARGET]   Zombie", i, "word='" .. zd.Word .. "' Z=", string.format("%.1f", zd.Model.PrimaryPart.Position.Z), "starts_with_prefix=", zd.Word:sub(1,#prefix):lower()==(prefix or ""):lower())
		end
	end
	local zd = ZombieSpawner.GetClosestZombieByPrefix(prefix)
	if zd then
		print("[TARGET] FOUND target: word='" .. zd.Word .. "' Z=", zd.Model.PrimaryPart and string.format("%.1f", zd.Model.PrimaryPart.Position.Z))
		RE.ZombieTargetResponse:FireClient(player, zd.Model, zd.Word)
	else
		print("[TARGET] NO MATCH for prefix='" .. tostring(prefix) .. "' - fired nil response")
		RE.ZombieTargetResponse:FireClient(player, nil, nil)
	end
end

local function OnWordProgress(player, zombieModel, typedLetters)
	local zd = ZombieSpawner.GetZombieByModel(zombieModel)
	if zd then
		print("[PROGRESS] Player", player.Name, "typed '" .. typedLetters .. "' on word '" .. zd.Word .. "' (" .. #typedLetters .. "/" .. #zd.Word .. " letters)")
		ZombieSpawner.UpdateZombieWord(zd, typedLetters)
	else
		print("[PROGRESS] WARNING: WordProgress received but zombie model not found in ActiveZombies - model may be dead or stale")
	end
end

local function OnWordComplete(player, zombieModel)
	print("[WORDCOMPLETE] Player", player.Name, "completed a word")
	local zd = ZombieSpawner.GetZombieByModel(zombieModel)
	if not zd then
		print("[WORDCOMPLETE] ERROR: Zombie model not found in ActiveZombies - already dead or wrong model reference")
		return
	end
	print("[WORDCOMPLETE] Word='" .. zd.Word .. "' Z=", zd.Model.PrimaryPart and string.format("%.1f", zd.Model.PrimaryPart.Position.Z))
	print("[WORDCOMPLETE] Score before:", GameState.score, "+ base", GameData.SCORE.WORD_COMPLETE_BASE)
	GameState.AddDefeatedWord(zd.Word, player.Name, GameState.currentWave)
	local pos = zd.Model.PrimaryPart and zd.Model.PrimaryPart.Position
	ZombieSpawner.DestroyZombie(zd, pos)
	GameState.score = GameState.score + GameData.SCORE.WORD_COMPLETE_BASE
	print("[WORDCOMPLETE] Score after:", GameState.score, "| Active zombies remaining:", #ZombieSpawner.ActiveZombies)
	-- Fire ScoreUpdate (per-kill score push) NOT WaveComplete (wave-end event)
	RE.ScoreUpdate:FireAllClients(GameState.score)
	-- Broadcast updated active word list so client hints refresh
	local activeWords = {}
	for _, z in ipairs(ZombieSpawner.ActiveZombies) do
		if z.IsAlive then table.insert(activeWords, z.Word) end
	end
	print("[WORDCOMPLETE] Broadcasting ActiveWordsUpdate:", #activeWords, "words remaining")
	RE.ActiveWordsUpdate:FireAllClients(activeWords)
end

local function OnGameStart(player)
	print("[RESTART] Restart requested by:", player.Name)
	print("[RESTART] GameState.isRunning:", GameState.isRunning, "hasEverStarted:", GameState.hasEverStarted)
	StartGame()
end

local function OnPlayerReady(player)
	print("[PLAYERREADY] Player", player.Name, "sent PlayerReady")
	print("[PLAYERREADY] GameState.isRunning=", GameState.isRunning, "hasEverStarted=", GameState.hasEverStarted)
	if GameState.isRunning or GameState.hasEverStarted then
		print("[PLAYERREADY] Ignored - game already running or has started before")
		return
	end
	GameState.playersReady[player.UserId] = true
	local total, ready = #Players:GetPlayers(), 0
	for _ in pairs(GameState.playersReady) do ready = ready + 1 end
	print("[PLAYERREADY]", ready, "/", total, "players ready")
	if ready >= total and total > 0 then StartGame() end
end

-- Player events
local characterAddedCooldowns = {}
local function OnPlayerAdded(player)
	print("[PLAYER] Player joined:", player.Name, "userId=", player.UserId)
	player.CharacterAdded:Connect(function(character)
		-- Debounce: ignore rapid duplicate fires (Studio sometimes fires twice)
		local now = tick()
		if characterAddedCooldowns[player.UserId] and (now - characterAddedCooldowns[player.UserId]) < 0.5 then
			print("[PLAYER] CharacterAdded DUPLICATE SUPPRESSED for", player.Name, "(fired", string.format("%.3f", now - characterAddedCooldowns[player.UserId]), "s after last)")
			return
		end
		characterAddedCooldowns[player.UserId] = now
		print("[PLAYER] Character added for", player.Name, "- character name:", character.Name)
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(Vector3.new(0, 5, 20), Vector3.new(0, 5, 0))
		print("[PLAYER] Camera set to Scriptable for", player.Name)
	end)
	if not player.Character then
		print("[PLAYER] No character yet for", player.Name, "- calling LoadCharacter")
		player:LoadCharacter()
	end
end

-- Update loop
local lastSurvivalBonus = 0
local lastHeartbeatDebug = 0
RunService.Heartbeat:Connect(function(dt)
	if not GameState.isRunning then return end
	ZombieSpawner.Update(dt)
	-- Survival bonus every 5 seconds
	local t = math.floor(tick() - GameState.startTime)
	if t > lastSurvivalBonus and t % 5 == 0 then
		lastSurvivalBonus = t
		GameState.score = GameState.score + GameData.SCORE.SURVIVAL_TIME_BONUS
		print("[SURVIVAL] Survival bonus awarded at t=", t, "s | score now:", GameState.score)
	end
	-- Print game state snapshot every 10 seconds
	if t > lastHeartbeatDebug and t % 10 == 0 then
		lastHeartbeatDebug = t
		print("[SNAPSHOT] ---- GAME STATE at t=" .. t .. "s ----")
		print("[SNAPSHOT] Wave:", GameState.currentWave, "| Score:", GameState.score)
		print("[SNAPSHOT] Active zombies:", #ZombieSpawner.ActiveZombies, "| Spawned this wave:", ZombieSpawner.ZombiesSpawnedThisWave)
		print("[SNAPSHOT] NextSpawnTime in:", string.format("%.2f", ZombieSpawner.NextSpawnTime - tick()), "s")
		local ws = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)
		print("[SNAPSHOT] Wave settings: speed=", ws.zombieSpeed, "spawnRate=", ws.spawnRate, "zombiesPerWave=", ws.zombiesPerWave)
		for i, zd in ipairs(ZombieSpawner.ActiveZombies) do
			if zd.IsAlive and zd.Model and zd.Model.PrimaryPart then
				local pos = zd.Model.PrimaryPart.Position
				print("[SNAPSHOT]   Zombie", i, "word='" .. zd.Word .. "' pos=(" .. string.format("%.1f,%.1f,%.1f", pos.X, pos.Y, pos.Z) .. ") typed='" .. zd.TypedLetters .. "'")
			end
		end
		print("[SNAPSHOT] ----------------------------------")
	end
end)

-- Wire everything up
print("[SERVER BOOT] Calling SetupLighting...")
SetupLighting()
print("[SERVER BOOT] Calling Corridor.Build...")
local coverPositions = Corridor.Build()
print("[SERVER BOOT] Corridor built. Cover positions found:", #coverPositions)
for i, cp in ipairs(coverPositions) do
	print("[SERVER BOOT]   CoverPos", i, "= (", string.format("%.1f, %.1f, %.1f", cp.X, cp.Y, cp.Z), ")")
end
ZombieSpawner.CoverPositions = coverPositions

RE.ZombieTargeted.OnServerEvent:Connect(OnZombieTargeted)
RE.WordProgress.OnServerEvent:Connect(OnWordProgress)
RE.WordComplete.OnServerEvent:Connect(OnWordComplete)
RE.GameStart.OnServerEvent:Connect(OnGameStart)
RE.PlayerReady.OnServerEvent:Connect(OnPlayerReady)
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(function(p)
	print("[PLAYER] Player left:", p.Name)
	GameState.playersReady[p.UserId] = nil
end)

print("[SERVER BOOT] ====== SERVER FULLY INITIALIZED ====== tick=", tick())
print("[SERVER BOOT] All RemoteEvents wired. Waiting for players.")

return {}
