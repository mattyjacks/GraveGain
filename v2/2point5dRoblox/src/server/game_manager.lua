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
local WorldManager = require(ServerFolder:WaitForChild("world_manager"))
local EntranceStyles = require(ServerFolder:WaitForChild("dungeon_entrance_styles"))
local LobbyGenerator = require(ServerFolder:WaitForChild("lobby_generator"))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local PlayerDataStore = DataStoreService:GetDataStore("GraveGain_PlayerData_v1")

local GameManager = {}
GameManager.playerData = {}
GameManager.dungeons = {}
GameManager.combatSystem = CombatSystem.new()
GameManager.lootSystem = LootSystem.new()
GameManager.enemySpawner = EnemySpawner.new()
GameManager.worldManager = WorldManager.new()
GameManager.__index = GameManager

function GameManager:initializePlayer(player)
	print("Initializing player:", player.Name)
	
	local data = nil
	local success, err = pcall(function()
		-- Only attempt if not in Studio or if we're sure APIs are enabled
		-- But the pcall handles it anyway, we just want to avoid noisy warnings
		data = PlayerDataStore:GetAsync("User_" .. player.UserId)
	end)
	
	if not success and not string.find(err, "Studio access to APIs is not allowed") then 
		warn("Failed to load data for", player.Name, err) 
	end

	local playerData = {
		player = player,
		character = nil,
		characterSystem = nil,
		currentDungeon = nil,
		currentFloor = 1,
		isAlive = true,
		level = data and data.level or 1,
		xp = data and data.xp or 0,
		talentPoints = data and data.talentPoints or 0,
		talents = data and data.talents or {}
	}
	
	self.playerData[player.UserId] = playerData
	
	-- Generate starting world chunk
	self.worldManager:ensureChunk(0, 0)
	
	-- Talent spending event
	local talentEvent = ReplicatedStorage:FindFirstChild("SpendTalentPoint")
	if not talentEvent then
		talentEvent = Instance.new("RemoteEvent")
		talentEvent.Name = "SpendTalentPoint"
		talentEvent.Parent = ReplicatedStorage
	end
	
	talentEvent.OnServerEvent:Connect(function(p, talentName)
		local data = self.playerData[p.UserId]
		if data and data.talentPoints > 0 then
			local talentConfig = GameData.TALENTS[talentName]
			local currentLv = data.talents[talentName] or 0
			if talentConfig and currentLv < talentConfig.max then
				data.talentPoints = data.talentPoints - 1
				data.talents[talentName] = currentLv + 1
				print(p.Name, "spent point on", talentName, "Level:", data.talents[talentName])
			end
		end
	end)

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
	local lobbyHeight = GameData.WORLD_CONFIG.lobbyHeight
	humanoidRootPart.CFrame = CFrame.new(0, lobbyHeight + 15, 0) -- Spawns on spaceship deck
	
	local playerData = self.playerData[player.UserId]
	if playerData then
		playerData.currentDungeon = nil
	end
	
	-- Request race selection from client
	local raceEvent = ReplicatedStorage:FindFirstChild("RaceSelectionRequested")
	if not raceEvent then
		raceEvent = Instance.new("RemoteEvent")
		raceEvent.Name = "RaceSelectionRequested"
		raceEvent.Parent = ReplicatedStorage
	end
	raceEvent:FireClient(player)
	
	-- Sync stats to client
	local statsEvent = ReplicatedStorage:FindFirstChild("SyncPlayerStats")
	if not statsEvent then
		statsEvent = Instance.new("RemoteEvent")
		statsEvent.Name = "SyncPlayerStats"
		statsEvent.Parent = ReplicatedStorage
	end
	statsEvent:FireClient(player, playerData.level, playerData.xp, playerData.talentPoints, playerData.talents)
	
	-- Wait for world generation to stabilize, then unlock drop holes
	task.delay(6, function()
		if self.lobbyGenerator then
			self.lobbyGenerator:unlockHoles()
		end
		local unlockEvent = ReplicatedStorage:FindFirstChild("UnlockLobbyHoles")
		if unlockEvent then
			unlockEvent:FireAllClients()
		end
	end)
	
	-- Generate 3 dungeon entrances in the world (invisible until explored)
	if not self.dungeonsPlaced then
		self.dungeonsPlaced = true
		for i = 1, 3 do
			local cx = math.random(-8, 8)
			local cz = math.random(-8, 8)
			self.worldManager:ensureChunk(cx, cz)
			
			local pos = Vector3.new(cx * 128 + math.random(-40, 40), 25, cz * 128 + math.random(-40, 40))
			local entrance = EntranceStyles.getRandomStyle(pos)
			entrance.Parent = workspace
			
			local root = entrance:FindFirstChild("EntranceRoot")
			if root then
				local prompt = root:FindFirstChildWhichIsA("ProximityPrompt")
				if not prompt then
					prompt = Instance.new("ProximityPrompt")
					prompt.ActionText = "Enter Dungeon"
					prompt.ObjectText = "Ancient Portal"
					prompt.HoldDuration = 1
					prompt.Parent = root
				end
				prompt.Triggered:Connect(function(trigPlayer)
					self:spawnPlayerInDungeon(trigPlayer, trigPlayer.Character, "Normal", "Fetch")
				end)
			end
		end
	end
	
	print("Player spawned in Spaceship Lobby at altitude", SHIP_Y)
end

function GameManager:spawnPlayerInDungeon(player, character, difficulty, missionType)
	local playerData = self.playerData[player.UserId]
	
	local dungeonSeed = tick() + player.UserId
	local dungeon = DungeonGenerator.new(dungeonSeed, "Crypt", playerData.currentFloor)
	
	playerData.currentDungeon = dungeon
	playerData.difficulty = difficulty or "Normal"
	playerData.missionType = missionType
	playerData.missionState = "In Progress"
	
	local enterDungeonEvent = ReplicatedStorage:FindFirstChild("EnterDungeon")
	local hudInstructionEvent = ReplicatedStorage:FindFirstChild("ShowHUDInstruction")
	if hudInstructionEvent then
		hudInstructionEvent:FireClient(player, "Find the Dungeon entrance")
	end
	
	local offset = GameData.DUNGEON_CONFIG.offset
	local spawnX = offset.X + dungeon.rooms[1].centerX * 4
	local spawnZ = offset.Z + dungeon.rooms[1].centerY * 4
	
	DungeonRenderer.new(dungeon, workspace)
	self.enemySpawner:spawnInDungeon(dungeon)
	
	-- Raycast to find the exact surface height
	local rayOrigin = Vector3.new(spawnX, 100, spawnZ)
	local rayDir = Vector3.new(0, -150, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	local dungeonFolder = workspace:FindFirstChild("Dungeon")
	if dungeonFolder then
		rayParams.FilterDescendantsInstances = {dungeonFolder}
	end
	
	local rayResult = workspace:Raycast(rayOrigin, rayDir, rayParams)
	local groundY = rayResult and rayResult.Position.Y or 3
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CFrame = CFrame.new(Vector3.new(spawnX, groundY + 3, spawnZ))
	
	-- Connect exterior portal detector if it exists
	task.spawn(function()
		local exterior = workspace:WaitForChild("Exterior", 5)
		if exterior then
			local detector = exterior:WaitForChild("DungeonEnterDetector", 5)
			if detector then
				local connection
				connection = detector.Touched:Connect(function(hit)
					if hit.Parent == character then
						print("Player entered dungeon via archway portal")
						humanoidRootPart.CFrame = CFrame.new(Vector3.new(spawnX, groundY + 3, spawnZ))
						connection:Disconnect() -- Only teleport once
					end
				end)
			end
		end
	end)
	
	if playerData.missionType == "Boss" then
		self:spawnBoss(dungeon, player)
	elseif playerData.missionType == "Fetch" then
		self:spawnFetchArtifact(dungeon, player)
	end
	
	print("Player spawned in", playerData.difficulty, "dungeon at:", spawnX, spawnY, "Mission:", missionType)
end

function GameManager:spawnSpaceElevator(dungeon, player)
	-- Spawn near start
	local offset = GameData.DUNGEON_CONFIG.offset
	local spawnX = offset.X + dungeon.rooms[1].centerX * 4
	local spawnZ = offset.Z + dungeon.rooms[1].centerY * 4
	
	local beam = Instance.new("Part")
	beam.Name = "SpaceElevator"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(200, 10, 10)
	beam.Orientation = Vector3.new(0, 0, 90)
	beam.Position = Vector3.new(spawnX, 100, spawnZ)
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
	local offset = GameData.DUNGEON_CONFIG.offset
	local lastRoom = dungeon.rooms[#dungeon.rooms]
	local bx, bz = offset.X + lastRoom.centerX * 4, offset.Z + lastRoom.centerY * 4
	
	local boss = Instance.new("Model")
	boss.Name = "GiantSkullBoss"
	boss:SetAttribute("EnemyType", "Boss")
	
	local skull = Instance.new("Part")
	skull.Name = "HumanoidRootPart"
	skull.Shape = Enum.PartType.Ball
	skull.Size = Vector3.new(6, 6, 6)
	skull.Color = Color3.fromRGB(200, 200, 200)
	skull.Material = Enum.Material.Slate
	skull.CFrame = CFrame.new(bx, 5, bz)
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
	local offset = GameData.DUNGEON_CONFIG.offset
	local lastRoom = dungeon.rooms[#dungeon.rooms]
	local bx, bz = offset.X + lastRoom.centerX * 4, offset.Z + lastRoom.centerY * 4
	
	local artifact = Instance.new("Part")
	artifact.Name = "ObjectiveArtifact"
	artifact.Shape = Enum.PartType.Ball
	artifact.Size = Vector3.new(2, 2, 2)
	artifact.Color = Color3.fromRGB(255, 215, 0)
	artifact.Material = Enum.Material.Neon
	artifact.CFrame = CFrame.new(bx, 3, bz)
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
							local e = Instance.new("Model")
							e.Name = "Enemy"
							local body = Instance.new("Part")
							body.Name = "Body"
							body.Size = Vector3.new(3,4,3)
							body.Color = Color3.new(1,0,0)
							body.CFrame = CFrame.new(ex, 10, ey)
							body.Parent = e
							local hum = Instance.new("Humanoid")
							hum.MaxHealth = 50; hum.Health = 50
							hum.Parent = e
							local rp = Instance.new("Part")
							rp.Name = "HumanoidRootPart"
							rp.Size = Vector3.new(3,4,3)
							rp.Transparency = 1
							rp.CanCollide = true
							rp.CFrame = body.CFrame
							rp.Parent = e
							e.PrimaryPart = rp
							e.Parent = workspace:FindFirstChild("Enemies") or workspace
						end
					end
				end)
			end
		end
	end)
end

function GameManager:spawnSpaceElevator(dungeon, player)
	local offset = GameData.DUNGEON_CONFIG.offset
	local lastRoom = dungeon.rooms[#dungeon.rooms]
	local bx, bz = offset.X + lastRoom.centerX * 4, offset.Z + lastRoom.centerY * 4
	
	local elevator = Instance.new("Model")
	elevator.Name = "SpaceElevator"
	
	local base = Instance.new("Part")
	base.Name = "HumanoidRootPart"
	base.Size = Vector3.new(10, 1, 10)
	base.Color = Color3.fromRGB(50, 50, 50)
	base.Material = Enum.Material.Metal
	base.Anchored = true
	base.CFrame = CFrame.new(bx, 3, bz)
	base.Parent = elevator
	elevator.PrimaryPart = base
	
	local beam = Instance.new("Part")
	beam.Size = Vector3.new(8, 200, 8)
	beam.Color = Color3.fromRGB(100, 200, 255)
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.5
	beam.Anchored = true
	beam.CanCollide = false
	beam.CFrame = base.CFrame + Vector3.new(0, 100, 0)
	beam.Parent = elevator
	
	elevator.Parent = workspace
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Extract"
	prompt.HoldDuration = 2
	prompt.Parent = base
	
	prompt.Triggered:Connect(function(trigPlayer)
		if trigPlayer == player then
			elevator:Destroy()
			local pData = self.playerData[player.UserId]
			if pData then
				pData.missionState = "Completed"
				
				-- Compile stats
				local stats = {
					kills = pData.characterSystem.level * 3, -- Placeholder
					xp = pData.characterSystem.experience,
					damage = pData.characterSystem.level * 100,
					gold = pData.characterSystem.level * 50
				}
				local loot = {"Epic Sword", "Health Potion"} -- Placeholder
				
				local missionCompleteEvent = ReplicatedStorage:FindFirstChild("MissionComplete")
				if missionCompleteEvent then
					missionCompleteEvent:FireClient(player, stats, loot)
				end
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

function GameManager:onPlayerRemoving(player)
	local data = self.playerData[player.UserId]
	if data then
		pcall(function()
			PlayerDataStore:SetAsync("User_" .. player.UserId, {
				level = data.level,
				xp = data.xp,
				talentPoints = data.talentPoints,
				talents = data.talents
			})
		end)
	end
	self.playerData[player.UserId] = nil
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
	print("Spaceship Lobby generated!")
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
	
	local missionCompleteEvent = Instance.new("RemoteEvent")
	missionCompleteEvent.Name = "MissionComplete"
	missionCompleteEvent.Parent = ReplicatedStorage
	
	local respawnPlayerEvent = Instance.new("RemoteEvent")
	respawnPlayerEvent.Name = "RespawnPlayer"
	respawnPlayerEvent.Parent = ReplicatedStorage
	
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
	
	respawnPlayerEvent.OnServerEvent:Connect(function(player)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
		player:LoadCharacter()
		local newChar = player.Character or player.CharacterAdded:Wait()
		gameManager:spawnPlayerInLobby(player, newChar)
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

Players.PlayerRemoving:Connect(function(p)
	gameManager:onPlayerRemoving(p)
end)

RunService.Heartbeat:Connect(function(deltaTime)
	gameManager:updateGame(deltaTime)
end)

return gameManager
