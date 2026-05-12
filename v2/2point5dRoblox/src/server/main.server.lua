local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))
local Networking = require(Shared:WaitForChild("networking"))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("GraveGain 2.5D Server Started")

local ServerFolder = script.Parent
local gameManager = require(ServerFolder:WaitForChild("game_manager"))

local remoteEvents = Networking:createRemoteEvents()
local remoteFunctions = Networking:createRemoteFunctions()

remoteFunctions.GetPlayerStats.OnServerInvoke = function(player)
	local playerData = gameManager.playerData[player.UserId]
	if playerData and playerData.characterSystem then
		return playerData.characterSystem:getStats()
	end
	return nil
end

remoteFunctions.GetDungeonData.OnServerInvoke = function(player)
	local playerData = gameManager.playerData[player.UserId]
	if playerData and playerData.currentDungeon then
		return {
			floor = playerData.currentFloor,
			enemies = playerData.currentDungeon.enemies,
			loot = playerData.currentDungeon.loot,
		}
	end
	return nil
end

remoteEvents.AbilityUsed.OnServerEvent:Connect(function(player, abilityName, targetPos)
	local playerData = gameManager.playerData[player.UserId]
	if playerData and playerData.characterSystem then
		if playerData.characterSystem:useAbility(abilityName) then
			print("Player used ability:", player.Name, abilityName)
		end
	end
end)

remoteEvents.EnemyDamage.OnServerEvent:Connect(function(player, enemyId, damage, damageType)
	local playerData = gameManager.playerData[player.UserId]
	if playerData and playerData.currentDungeon then
		for _, enemy in ipairs(playerData.currentDungeon.enemies) do
			if enemy.id == enemyId then
				local isDead = enemy:takeDamage(damage)
				if isDead then
					local loot = gameManager:handleEnemyKill(player, enemy.type)
					remoteEvents.LootDrop:FireClient(player, loot, enemy.position)
				end
				break
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	print("Player joined:", player.Name)
	gameManager:initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	print("Player left:", player.Name)
	gameManager.playerData[player.UserId] = nil
	gameManager.dungeons[player.UserId] = nil
end)

RunService.Heartbeat:Connect(function(deltaTime)
	gameManager:updateGame(deltaTime)
end)

print("Server systems initialized")

local raceNames = {}
for race, _ in pairs(GameData.RACES) do
	table.insert(raceNames, race)
end
print("Available Races:", table.concat(raceNames, ", "))

local diffNames = {}
for diff, _ in pairs(GameData.DIFFICULTIES) do
	table.insert(diffNames, diff)
end
print("Available Difficulties:", table.concat(diffNames, ", "))
