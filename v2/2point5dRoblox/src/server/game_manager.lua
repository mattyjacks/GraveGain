local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))
local CharacterSystem = require(Shared:WaitForChild("character_system"))
local DungeonGenerator = require(Shared:WaitForChild("dungeon_generator"))
local CombatSystem = require(Shared:WaitForChild("combat_system"))
local LootSystem = require(Shared:WaitForChild("loot_system"))
local RaceStats = require(Shared:WaitForChild("race_stats"))

local ServerFolder = script.Parent
local DungeonRenderer = require(ServerFolder:WaitForChild("dungeon_renderer"))
local EnemySpawner = require(ServerFolder:WaitForChild("enemy_spawner"))
local LobbyGenerator = require(ServerFolder:WaitForChild("lobby_generator"))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameManager = {}
GameManager.playerData = {}
GameManager.dungeons = {}
GameManager.combatSystem = CombatSystem.new()
GameManager.lootSystem = LootSystem.new()
GameManager.enemySpawner = EnemySpawner.new()
GameManager.__index = GameManager

function GameManager:initializePlayer(player)
	print("Initializing player:", player.Name)
	
	local playerData = {
		player = player,
		character = nil,
		characterSystem = nil,
		currentDungeon = nil,
		currentFloor = 1,
		isAlive = true,
	}
	
	self.playerData[player.UserId] = playerData
	
	player.CharacterAdded:Connect(function(character)
		self:onCharacterSpawned(player, character)
	end)
	
	if player.Character then
		self:onCharacterSpawned(player, player.Character)
	end
end

function GameManager:onCharacterSpawned(player, character)
	print("Character spawned:", player.Name)
	
	local playerData = self.playerData[player.UserId]
	if not playerData then return end
	
	playerData.character = character
	playerData.characterSystem = CharacterSystem.new("Human", "Normal")
	playerData.isAlive = true
	
	self:spawnPlayerInLobby(player, character)
end

function GameManager:spawnPlayerInLobby(player, character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CFrame = CFrame.new(0, 3, 0)
	
	local playerData = self.playerData[player.UserId]
	if playerData then
		playerData.currentDungeon = nil
	end
	
	print("Player spawned in lobby")
end

function GameManager:spawnPlayerInDungeon(player, character, difficulty)
	local playerData = self.playerData[player.UserId]
	
	local dungeonSeed = tick() + player.UserId
	local dungeon = DungeonGenerator.new(dungeonSeed, "Crypt", playerData.currentFloor)
	
	playerData.currentDungeon = dungeon
	playerData.difficulty = difficulty or "Normal"
	self.dungeons[player.UserId] = dungeon
	
	local spawnX = dungeon.rooms[1].centerX * 4
	local spawnY = dungeon.rooms[1].centerY * 4
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CFrame = CFrame.new(Vector3.new(spawnX, 3, spawnY))
	
	DungeonRenderer.new(dungeon, workspace)
	self.enemySpawner:spawnInDungeon(dungeon)
	
	print("Player spawned in", playerData.difficulty, "dungeon at:", spawnX, spawnY)
end

function GameManager:handlePlayerDamage(player, damage, damageType)
	local playerData = self.playerData[player.UserId]
	if not playerData or not playerData.characterSystem then return end
	
	local isDead = playerData.characterSystem:takeDamage(damage, damageType)
	if isDead then
		playerData.isAlive = false
		print("Player died:", player.Name)
	end
end

function GameManager:handleEnemyKill(player, enemyType)
	local playerData = self.playerData[player.UserId]
	if not playerData or not playerData.characterSystem then return end
	
	local enemyData = GameData.ENEMY_TYPES[enemyType]
	if not enemyData then return end
	
	local xp = enemyData.xp * (1 + playerData.currentFloor * 0.1)
	playerData.characterSystem:gainExperience(xp)
	
	local loot = self.lootSystem:generateLoot(enemyType, playerData.characterSystem.level)
	
	print("Player killed enemy:", player.Name, enemyType, "XP:", xp)
	
	return loot
end

function GameManager:handleFloorComplete(player)
	local playerData = self.playerData[player.UserId]
	if not playerData then return end
	
	playerData.currentFloor = playerData.currentFloor + 1
	
	if playerData.currentFloor > GameData.DUNGEON_CONFIG.floorsPerAct then
		self:handleActComplete(player)
	else
		self:spawnPlayerInDungeon(player, playerData.character)
	end
end

function GameManager:handleActComplete(player)
	local playerData = self.playerData[player.UserId]
	if not playerData then return end
	
	print("Player completed act:", player.Name)
	playerData.currentFloor = 1
end

function GameManager:updateGame(deltaTime)
	self.enemySpawner:update(deltaTime)
	
	for userId, playerData in pairs(self.playerData) do
		if playerData.characterSystem then
			playerData.characterSystem:updateAbilityCooldowns(deltaTime)
			playerData.characterSystem:updateStatusEffects(deltaTime)
		end
	end
end

function GameManager:generateLobby()
	local lobbyGen = LobbyGenerator.new(workspace)
	lobbyGen:generateLobby()
	print("Lobby generated!")
end

local gameManager = setmetatable({}, GameManager)

gameManager:generateLobby()

local function setupRemoteEvents()
	local enterDungeonEvent = Instance.new("RemoteEvent")
	enterDungeonEvent.Name = "EnterDungeon"
	enterDungeonEvent.Parent = ReplicatedStorage
	
	local portalEvent = Instance.new("RemoteEvent")
	portalEvent.Name = "DungeonPortalEntered"
	portalEvent.Parent = ReplicatedStorage
	
	local raceEvent = Instance.new("RemoteEvent")
	raceEvent.Name = "RaceSelectionRequested"
	raceEvent.Parent = ReplicatedStorage
	
	enterDungeonEvent.OnServerEvent:Connect(function(player, race, difficulty)
		print("Player", player.Name, "entering dungeon with race:", race, "difficulty:", difficulty)
		local character = player.Character
		if character then
			gameManager:spawnPlayerInDungeon(player, character, difficulty)
		end
	end)
	
	print("Remote events created: EnterDungeon, DungeonPortalEntered, RaceSelectionRequested")
end

setupRemoteEvents()

Players.PlayerAdded:Connect(function(player)
	gameManager:initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	gameManager.playerData[player.UserId] = nil
end)

RunService.Heartbeat:Connect(function(deltaTime)
	gameManager:updateGame(deltaTime)
end)

return gameManager
