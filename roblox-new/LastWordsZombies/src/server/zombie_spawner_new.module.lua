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
	if #ZombieSpawner.ActiveZombies >= GameData.ZOMBIE.MAX_ZOMBIES then return false end

	local waveSettings = GameData.CalculateWaveSettings(ZombieSpawner.WaveNumber)
	local isBigWord    = math.random() < 0.20
	local difficulty   = isBigWord and NextDifficulty(waveSettings.wordDifficulty) or waveSettings.wordDifficulty
	local word         = WordDictionary.GetRandomWord(difficulty)

	local zombie = ZombieModel.Build(isBigWord)
	local wordDisplay = ZombieModel.CreateWordDisplay(zombie, word)

	-- Position: near cover 40%, random 60%
	local spawnX, spawnZ
	local covers = ZombieSpawner.CoverPositions
	if #covers > 0 and math.random() < 0.4 then
		local pick = covers[math.random(1, #covers)]
		spawnX = pick.X + math.random(-3, 3)
		spawnZ = pick.Z
	else
		local hw = math.floor(GameData.VISUALS.CORRIDOR_WIDTH / 2) - 4
		spawnX   = math.random(-hw, hw)
		spawnZ   = ZombieSpawner.SpawnPosition.Z - (#ZombieSpawner.ActiveZombies % 8) * 4 + math.random(-5, 5)
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
		if ZombieSpawner.SpawnZombie() then
			ZombieSpawner.NextSpawnTime = now + waveSettings.spawnRate
		end
	end

	if ZombieSpawner.ZombiesSpawnedThisWave >= waveSettings.zombiesPerWave and #ZombieSpawner.ActiveZombies == 0 then
		ZombieSpawner.CompleteWave()
	end
end

function ZombieSpawner.CompleteWave()
	ZombieSpawner.WaveNumber = ZombieSpawner.WaveNumber + 1
	ZombieSpawner.ZombiesSpawnedThisWave = 0
	game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("WaveComplete"):FireAllClients(ZombieSpawner.WaveNumber)
end

function ZombieSpawner.OnZombieReachedCamera(zombieData)
	if not zombieData.IsAlive then return end
	zombieData.IsAlive = false
	if ZombieSpawner.OnGameOver then
		ZombieSpawner.OnGameOver("zombie_reached")
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
	if not zombieData.IsAlive then return end
	zombieData.IsAlive = false
	if zombieData.MovementConnection then zombieData.MovementConnection:Disconnect() end

	local explodePos = pos or (zombieData.Model.PrimaryPart and zombieData.Model.PrimaryPart.Position) or Vector3.zero
	ZombieEffects.Explosion(explodePos, ZombieSpawner.ActiveZombies)
	ZombieEffects.Ragdoll(zombieData.Model)
	Debris:AddItem(zombieData.Model, GameData.ZOMBIE.RAGDOLL_DURATION)

	for i, z in ipairs(ZombieSpawner.ActiveZombies) do
		if z == zombieData then table.remove(ZombieSpawner.ActiveZombies, i) break end
	end
end

function ZombieSpawner.GetZombieByModel(model)
	for _, zd in ipairs(ZombieSpawner.ActiveZombies) do
		if zd.Model == model then return zd end
	end
	return nil
end

function ZombieSpawner.GetClosestZombieByLetter(letter)
	local best, bestDist = nil, math.huge
	for _, zd in ipairs(ZombieSpawner.ActiveZombies) do
		if zd.IsAlive and zd.Word:sub(1,1):lower() == letter:lower() then
			local dist = zd.Model.PrimaryPart.Position.Magnitude
			if dist < bestDist then bestDist = dist; best = zd end
		end
	end
	return best
end

function ZombieSpawner.Cleanup()
	for _, zd in ipairs(ZombieSpawner.ActiveZombies) do
		if zd.MovementConnection then zd.MovementConnection:Disconnect() end
		if zd.Model then zd.Model:Destroy() end
	end
	ZombieSpawner.ActiveZombies = {}
	ZombieSpawner.ZombiesSpawnedThisWave = 0
end

return ZombieSpawner
