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

function GameManager:spawnPlayerInDungeon(player, character, difficulty, missionType)
	local playerData = self.playerData[player.UserId]
	
	local dungeonSeed = tick() + player.UserId
	local dungeon = DungeonGenerator.new(dungeonSeed, "Crypt", playerData.currentFloor)
	
	playerData.currentDungeon = dungeon
	playerData.difficulty = difficulty or "Normal"
	playerData.missionType = missionType or "Boss"
	playerData.missionState = "InProgress"
	self.dungeons[player.UserId] = dungeon
	
	local spawnX = dungeon.rooms[1].centerX * 4
	local spawnY = dungeon.rooms[1].centerY * 4
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CFrame = CFrame.new(Vector3.new(spawnX, 3, spawnY))
	
	DungeonRenderer.new(dungeon, workspace)
	self.enemySpawner:spawnInDungeon(dungeon)
	
	if playerData.missionType == "Boss" then
		self:spawnBoss(dungeon, player)
	elseif playerData.missionType == "Fetch" then
		self:spawnFetchArtifact(dungeon, player)
	end
	
	print("Player spawned in", playerData.difficulty, "dungeon at:", spawnX, spawnY, "Mission:", missionType)
end

function GameManager:spawnSpaceElevator(dungeon, player)
	-- Spawn near start
	local spawnX = dungeon.rooms[1].centerX * 4
	local spawnY = dungeon.rooms[1].centerY * 4
	
	local beam = Instance.new("Part")
	beam.Name = "SpaceElevator"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(200, 10, 10)
	beam.Orientation = Vector3.new(0, 0, 90)
	beam.Position = Vector3.new(spawnX, 100, spawnY)
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(100, 255, 255)
	beam.Transparency = 0.3
	beam.Anchored = true
	beam.CanCollide = false
	beam.Parent = workspace
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Extract"
	prompt.ObjectText = "Space Elevator"
	prompt.HoldDuration = 2
	prompt.Parent = beam
	
	prompt.Triggered:Connect(function(trigPlayer)
		if trigPlayer == player then
			print(player.Name, "extracted successfully!")
			beam:Destroy()
			self:spawnPlayerInLobby(player, player.Character)
		end
	end)
	
	print("Space Elevator deployed for", player.Name)
end

function GameManager:spawnBoss(dungeon, player)
	local lastRoom = dungeon.rooms[#dungeon.rooms]
	local bx, by = lastRoom.centerX * 4, lastRoom.centerY * 4
	
	local boss = Instance.new("Model")
	boss.Name = "GiantSkullBoss"
	boss:SetAttribute("EnemyType", "Boss")
	
	local skull = Instance.new("Part")
	skull.Name = "HumanoidRootPart"
	skull.Shape = Enum.PartType.Ball
	skull.Size = Vector3.new(6, 6, 6)
	skull.Color = Color3.fromRGB(200, 200, 200)
	skull.Material = Enum.Material.Slate
	skull.CFrame = CFrame.new(bx, 5, by)
	skull.Parent = boss
	boss.PrimaryPart = skull
	
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 500
	hum.Health = 500
	hum.Parent = boss
	
	boss.Parent = workspace:FindFirstChild("Enemies") or workspace
	
	hum.Died:Connect(function()
		local pData = self.playerData[player.UserId]
		if pData and pData.missionType == "Boss" then
			pData.missionState = "Extracting"
			self:spawnSpaceElevator(dungeon, player)
		end
	end)
end

function GameManager:spawnFetchArtifact(dungeon, player)
	local lastRoom = dungeon.rooms[#dungeon.rooms]
	local bx, by = lastRoom.centerX * 4, lastRoom.centerY * 4
	
	local artifact = Instance.new("Part")
	artifact.Name = "ObjectiveArtifact"
	artifact.Shape = Enum.PartType.Ball
	artifact.Size = Vector3.new(2, 2, 2)
	artifact.Color = Color3.fromRGB(255, 215, 0)
	artifact.Material = Enum.Material.Neon
	artifact.CFrame = CFrame.new(bx, 3, by)
	artifact.Anchored = true
	artifact.Parent = workspace
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect Artifact"
	prompt.HoldDuration = 1
	prompt.Parent = artifact
	
	prompt.Triggered:Connect(function(trigPlayer)
		if trigPlayer == player then
			artifact:Destroy()
			local pData = self.playerData[player.UserId]
			if pData and pData.missionType == "Fetch" then
				pData.missionState = "Extracting"
				self:spawnSpaceElevator(dungeon, player)
				
				-- Infinite enemies
				task.spawn(function()
					while pData.missionState == "Extracting" and pData.isAlive do
						task.wait(2)
						if not player.Character then break end
						local hrp = player.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local ex = hrp.Position.X + math.random(-20, 20)
							local ey = hrp.Position.Z + math.random(-20, 20)
							local e = Instance.new("Part")
							e.Name = "Enemy"
							e.Size = Vector3.new(3,4,3)
							e.Color = Color3.new(1,0,0)
							e.Position = Vector3.new(ex, 3, ey)
							local hum = Instance.new("Humanoid")
							hum.MaxHealth = 50; hum.Health = 50
							hum.Parent = e
							local rp = Instance.new("Part")
							rp.Name = "HumanoidRootPart"
							rp.Parent = e
							rp.CFrame = e.CFrame
							e.PrimaryPart = rp
							e.Parent = workspace:FindFirstChild("Enemies") or workspace
						end
					end
				end)
			end
		end
	end)
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
	local raceChangedEvent = Instance.new("RemoteEvent")
	raceChangedEvent.Name = "RaceChanged"
	raceChangedEvent.Parent = ReplicatedStorage
	
	local enemyDamagedEvent = Instance.new("RemoteEvent")
	enemyDamagedEvent.Name = "EnemyDamaged"
	enemyDamagedEvent.Parent = ReplicatedStorage
	
	local restoreAmmoEvent = Instance.new("RemoteEvent")
	restoreAmmoEvent.Name = "RestoreAmmo"
	restoreAmmoEvent.Parent = ReplicatedStorage
	
	local lorePickedUpEvent = Instance.new("RemoteEvent")
	lorePickedUpEvent.Name = "LorePickedUp"
	lorePickedUpEvent.Parent = ReplicatedStorage
	
	local loreXPAwardedEvent = Instance.new("BindableEvent")
	loreXPAwardedEvent.Name = "LoreXPAwarded"
	loreXPAwardedEvent.Parent = ReplicatedStorage
	
	local playerLoreCache = {}

	loreXPAwardedEvent.Event:Connect(function(player, loreId)
		if not playerLoreCache[player.UserId] then
			playerLoreCache[player.UserId] = {}
		end
		
		local xpAmount = 50
		if not playerLoreCache[player.UserId][loreId] then
			xpAmount = xpAmount * 3
			playerLoreCache[player.UserId][loreId] = true
			print("New lore found! Awarding 3x XP:", xpAmount)
		else
			print("Lore already known! Awarding 1x XP:", xpAmount)
		end
		
		local playerData = gameManager.playerData[player.UserId]
		if playerData and playerData.characterSystem then
			playerData.characterSystem:gainExperience(xpAmount)
		end
	end)
	
	enemyDamagedEvent.OnServerEvent:Connect(function(player, enemyModel, damage)
		if enemyModel and enemyModel:FindFirstChild("Humanoid") then
			local hum = enemyModel.Humanoid
			hum:TakeDamage(damage)
			
			-- Damage Flash
			local hl = enemyModel:FindFirstChild("DamageHighlight")
			if not hl then
				hl = Instance.new("Highlight")
				hl.Name = "DamageHighlight"
				hl.FillColor = Color3.fromRGB(255, 0, 0)
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.FillTransparency = 0.3
				hl.Parent = enemyModel
			end
			hl.Enabled = true
			task.delay(0.15, function()
				if hl then hl.Enabled = false end
			end)
			
			-- Physical Knockback
			local hrp = enemyModel:FindFirstChild("HumanoidRootPart") or enemyModel:FindFirstChild("Root")
			if hrp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dir = (hrp.Position - player.Character.HumanoidRootPart.Position).Unit
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(dir.X * 30, 10, dir.Z * 30)
				bv.MaxForce = Vector3.new(100000, 100000, 100000)
				bv.Parent = hrp
				game:GetService("Debris"):AddItem(bv, 0.15)
			end
			
			if hum.Health <= 0 then
				gameManager:handleEnemyKill(player, enemyModel:GetAttribute("EnemyType") or "Skeleton")
			end
		end
	end)
	
	enterDungeonEvent.OnServerEvent:Connect(function(player, race, difficulty, missionType)
		print("Player", player.Name, "entering dungeon with race:", race, "difficulty:", difficulty, "Mission:", missionType)
		local character = player.Character
		if character then
			gameManager:spawnPlayerInDungeon(player, character, difficulty, missionType)
		end
	end)
	
	raceChangedEvent.OnServerEvent:Connect(function(player, raceName)
		local character = player.Character
		if not character then return end
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		local raceData = RaceStats.getRaceStats(raceName)
		if not raceData or not raceData.scale then return end
		
		local scale = raceData.scale
		local success, desc = pcall(function() return humanoid:GetAppliedDescription() end)
		if success and desc then
			desc.DepthScale = scale.Z
			desc.HeightScale = scale.Y
			desc.WidthScale = scale.X
			desc.HeadScale = scale.Y
			humanoid:ApplyDescription(desc)
		else
			-- Fallback for non-description avatars
			local function setScale(name, value)
				local valObj = humanoid:FindFirstChild(name)
				if not valObj then
					valObj = Instance.new("NumberValue")
					valObj.Name = name
					valObj.Parent = humanoid
				end
				if valObj:IsA("NumberValue") then
					valObj.Value = value
				end
			end
			setScale("BodyDepthScale", scale.Z)
			setScale("BodyHeightScale", scale.Y)
			setScale("BodyWidthScale", scale.X)
			setScale("HeadScale", scale.Y)
		end
	end)
	
	print("Remote events created: EnterDungeon, DungeonPortalEntered, RaceSelectionRequested, RaceChanged")
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
