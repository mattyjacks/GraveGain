-- ZombieSpawner: spawn control, word tracking, destruction
-- Movement -> zombie_movement.lua  |  Model -> zombie_model.lua  |  Effects -> zombie_effects.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local GameData      = require(ReplicatedStorage:WaitForChild("GameData"))
local WordDictionary = require(ReplicatedStorage:WaitForChild("WordDictionary"))
local ZombieModel   = require(script.Parent.ZombieModel)
local ZombieMovement = require(script.Parent.ZombieMovement)
local ZombieEffects = require(script.Parent.ZombieEffects)

local ZombieSpawner = {}

ZombieSpawner.ActiveZombies         = {}
ZombieSpawner.NextSpawnTime         = 0
ZombieSpawner.WaveNumber            = 1
ZombieSpawner.ZombiesSpawnedThisWave = 0
ZombieSpawner.SpawnPosition         = Vector3.new(0, 0, -150)
ZombieSpawner.CoverPositions        = {}
ZombieSpawner.OnGameOver            = nil -- set by main.server

local DIFFICULTY_TIERS = {"Easy", "Medium", "Hard", "Extreme"}

local function NextDifficulty(current)
	for i, t in ipairs(DIFFICULTY_TIERS) do
		if t == current then return DIFFICULTY_TIERS[math.min(i + 1, #DIFFICULTY_TIERS)] end
	end
	return current
end

-- Spawn a single zombie
function ZombieSpawner.SpawnZombie()
	if #ZombieSpawner.ActiveZombies >= GameData.ZOMBIE.MAX_ZOMBIES then
		print("[SPAWN] Spawn BLOCKED - at MAX_ZOMBIES (", GameData.ZOMBIE.MAX_ZOMBIES, ")")
		return false
	end

	local waveSettings = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)
	local isBigWord    = math.random() < 0.20
	local difficulty   = isBigWord and NextDifficulty(waveSettings.wordDifficulty) or waveSettings.wordDifficulty
	local word         = WordDictionary.GetRandomWord(difficulty)

	print("[SPAWN] Spawning zombie #" .. (ZombieSpawner.ZombiesSpawnedThisWave + 1) .. " wave=" .. ZombieSpawner.WaveNumber)
	print("[SPAWN]   word='" .. word .. "' difficulty='" .. difficulty .. "' isBigWord=" .. tostring(isBigWord))
	print("[SPAWN]   speed=", waveSettings.zombieSpeed, "| active so far:", #ZombieSpawner.ActiveZombies)

	local zombie = ZombieModel.Build(isBigWord)
	local wordDisplay = ZombieModel.CreateWordDisplay(zombie, word)

	-- Position: near cover 40%, random 60%
	-- Only use cover positions that are in the valid spawn zone (behind Z=-20)
	local SPAWN_Z_MAX = -20
	local spawnX, spawnZ
	local covers = ZombieSpawner.CoverPositions
	local validCovers = {}
	for _, cp in ipairs(covers) do
		if cp.Z < SPAWN_Z_MAX then table.insert(validCovers, cp) end
	end
	if #validCovers > 0 and math.random() < 0.4 then
		local pick = validCovers[math.random(1, #validCovers)]
		spawnX = pick.X + math.random(-3, 3)
		spawnZ = math.min(pick.Z, SPAWN_Z_MAX)
		print("[SPAWN]   Spawn position: COVER-BASED x=", string.format("%.1f", spawnX), "z=", string.format("%.1f", spawnZ), "(validCovers=", #validCovers, ")")
	else
		local hw = math.floor(GameData.VISUALS.CORRIDOR_WIDTH / 2) - 4
		spawnX   = math.random(-hw, hw)
		spawnZ   = math.min(ZombieSpawner.SpawnPosition.Z - (#ZombieSpawner.ActiveZombies % 8) * 4 + math.random(-5, 5), SPAWN_Z_MAX)
		print("[SPAWN]   Spawn position: RANDOM x=", string.format("%.1f", spawnX), "z=", string.format("%.1f", spawnZ))
	end

	zombie:SetPrimaryPartCFrame(CFrame.new(spawnX, 3, spawnZ) * CFrame.Angles(0, math.pi, 0))
	zombie.Parent = workspace

	local zombieData = {
		Model       = zombie,
		Word        = word,
		WordDisplay = wordDisplay,
		Speed       = waveSettings.zombieSpeed,
		IsAlive     = true,
		TypedLetters = "",
	}

	table.insert(ZombieSpawner.ActiveZombies, zombieData)
	ZombieSpawner.ZombiesSpawnedThisWave = ZombieSpawner.ZombiesSpawnedThisWave + 1
	print("[SPAWN]   Total active zombies now:", #ZombieSpawner.ActiveZombies, "| Spawned this wave:", ZombieSpawner.ZombiesSpawnedThisWave, "/", waveSettings.zombiesPerWave)

	ZombieMovement.Start(zombieData, function()
		ZombieSpawner.OnZombieReachedCamera(zombieData)
	end)

	return zombieData
end

-- Per-frame update (called from main.server Heartbeat)
function ZombieSpawner.Update(deltaTime)
	local now = tick()
	local waveSettings = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)

	if now >= ZombieSpawner.NextSpawnTime then
		print("[UPDATE] Spawn timer elapsed. Attempting spawn (active=", #ZombieSpawner.ActiveZombies, "spawnedThisWave=", ZombieSpawner.ZombiesSpawnedThisWave, "/", waveSettings.zombiesPerWave, ")")
		if ZombieSpawner.SpawnZombie() then
			ZombieSpawner.NextSpawnTime = now + waveSettings.spawnRate
			print("[UPDATE] Next spawn in", string.format("%.2f", waveSettings.spawnRate), "s")
		end
	end

	if ZombieSpawner.ZombiesSpawnedThisWave >= waveSettings.zombiesPerWave and #ZombieSpawner.ActiveZombies == 0 then
		print("[UPDATE] Wave completion condition met: spawned=", ZombieSpawner.ZombiesSpawnedThisWave, "/", waveSettings.zombiesPerWave, "active=0")
		ZombieSpawner.CompleteWave()
	end
end

function ZombieSpawner.CompleteWave()
	print("[WAVE] ====== WAVE COMPLETE ====== was wave", ZombieSpawner.WaveNumber)
	ZombieSpawner.WaveNumber = ZombieSpawner.WaveNumber + 1
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	local nextWs = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)
	print("[WAVE] Starting wave", ZombieSpawner.WaveNumber, "| speed=", nextWs.zombieSpeed, "spawnRate=", nextWs.spawnRate, "zombiesPerWave=", nextWs.zombiesPerWave, "difficulty=", nextWs.wordDifficulty)
	game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WaveComplete"):FireAllClients(ZombieSpawner.WaveNumber)
end

function ZombieSpawner.OnZombieReachedCamera(zombieData)
	if not zombieData.IsAlive then
		print("[REACHED] Zombie reached camera but IsAlive=false (already killed) - word='" .. zombieData.Word .. "' IGNORED")
		return
	end
	print("[REACHED] ZOMBIE REACHED CAMERA! word='" .. zombieData.Word .. "' typed='" .. zombieData.TypedLetters .. "'")
	print("[REACHED] Active zombies at time of reach:", #ZombieSpawner.ActiveZombies)
	zombieData.IsAlive = false
	if ZombieSpawner.OnGameOver then
		print("[REACHED] Calling OnGameOver callback")
		ZombieSpawner.OnGameOver("zombie_reached")
	else
		print("[REACHED] ERROR: OnGameOver callback is nil - game over won't trigger!")
	end
end

-- Update word display text (typed letters highlighted green)
function ZombieSpawner.UpdateZombieWord(zombieData, typedLetters)
	zombieData.TypedLetters = typedLetters
	local display = zombieData.WordDisplay
	if not display then return end
	local label = display:FindFirstChild("Frame") and display.Frame:FindFirstChild("TextLabel")
	if not label then return end
	local result = ""
	for i = 1, #zombieData.Word do
		local ch = zombieData.Word:sub(i, i)
		if i <= #typedLetters then
			result = result .. '<font color="rgb(0,255,0)">' .. ch .. '</font>'
		else
			result = result .. ch
		end
	end
	label.RichText = true
	label.Text = result
end

-- Destroy zombie with effects
function ZombieSpawner.DestroyZombie(zombieData, pos)
	if not zombieData.IsAlive then
		print("[DESTROY] DestroyZombie called but IsAlive=false for word='" .. zombieData.Word .. "' - double-kill attempt, ignoring")
		return
	end
	print("[DESTROY] Destroying zombie word='" .. zombieData.Word .. "' at pos", pos and string.format("(%.1f,%.1f,%.1f)", pos.X, pos.Y, pos.Z) or "nil")
	zombieData.IsAlive = false
	if zombieData.MovementConnection then
		zombieData.MovementConnection:Disconnect()
		print("[DESTROY] Movement connection disconnected")
	else
		print("[DESTROY] WARNING: No MovementConnection to disconnect for word='" .. zombieData.Word .. "'")
	end

	local explodePos = pos or (zombieData.Model.PrimaryPart and zombieData.Model.PrimaryPart.Position) or Vector3.zero
	ZombieEffects.Explosion(explodePos, ZombieSpawner.ActiveZombies)
	ZombieEffects.Ragdoll(zombieData.Model)
	Debris:AddItem(zombieData.Model, GameData.ZOMBIE.RAGDOLL_DURATION)

	local removedIdx = nil
	for i, z in ipairs(ZombieSpawner.ActiveZombies) do
		if z == zombieData then
			table.remove(ZombieSpawner.ActiveZombies, i)
			removedIdx = i
			break
		end
	end
	if removedIdx then
		print("[DESTROY] Removed from ActiveZombies at index", removedIdx, "| Remaining:", #ZombieSpawner.ActiveZombies)
	else
		print("[DESTROY] ERROR: Zombie word='" .. zombieData.Word .. "' was not found in ActiveZombies during removal!")
	end
end

function ZombieSpawner.GetZombieByModel(model)
	for _, zd in ipairs(ZombieSpawner.ActiveZombies) do
		if zd.Model == model then return zd end
	end
	return nil
end

-- Find closest zombie whose word starts with the given typed prefix (full prefix match)
function ZombieSpawner.GetClosestZombieByPrefix(prefix)
	prefix = prefix:lower()
	local best, bestZ = nil, -math.huge
	local matchCount = 0
	for _, zd in ipairs(ZombieSpawner.ActiveZombies) do
		if not zd.IsAlive then continue end
		if zd.Word:sub(1, #prefix):lower() == prefix then
			matchCount = matchCount + 1
			local z = zd.Model.PrimaryPart and zd.Model.PrimaryPart.Position.Z or -math.huge
			if z > bestZ then bestZ = z; best = zd end
		end
	end
	print("[PREFIX] GetClosestZombieByPrefix(prefix='" .. prefix .. "') found", matchCount, "matches | chose: ", best and ("'" .. best.Word .. "' Z=" .. string.format("%.1f", bestZ)) or "nil")
	return best
end

function ZombieSpawner.Cleanup()
	print("[CLEANUP] Cleaning up", #ZombieSpawner.ActiveZombies, "active zombies")
	for i, zd in ipairs(ZombieSpawner.ActiveZombies) do
		print("[CLEANUP]   Removing zombie", i, "word='" .. zd.Word .. "' IsAlive=", zd.IsAlive)
		if zd.MovementConnection then zd.MovementConnection:Disconnect() end
		if zd.Model then zd.Model:Destroy() end
	end
	ZombieSpawner.ActiveZombies = {}
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	ZombieSpawner.NextSpawnTime = 0
	print("[CLEANUP] Done. ActiveZombies cleared, NextSpawnTime reset to 0")
end

return ZombieSpawner
