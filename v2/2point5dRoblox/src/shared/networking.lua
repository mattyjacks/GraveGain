local Networking = {}

function Networking:createRemoteEvents()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local events = {
		PlayerAction = Instance.new("RemoteEvent"),
		EnemyUpdate = Instance.new("RemoteEvent"),
		LootDrop = Instance.new("RemoteEvent"),
		PlayerDamage = Instance.new("RemoteEvent"),
		EnemyDamage = Instance.new("RemoteEvent"),
		AbilityUsed = Instance.new("RemoteEvent"),
		LevelUp = Instance.new("RemoteEvent"),
		FloorComplete = Instance.new("RemoteEvent"),
		ActComplete = Instance.new("RemoteEvent"),
	}
	
	for name, event in pairs(events) do
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	
	return events
end

function Networking:createRemoteFunctions()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local functions = {
		GetPlayerStats = Instance.new("RemoteFunction"),
		GetDungeonData = Instance.new("RemoteFunction"),
		GetEnemyData = Instance.new("RemoteFunction"),
		GetLootData = Instance.new("RemoteFunction"),
	}
	
	for name, func in pairs(functions) do
		func.Name = name
		func.Parent = ReplicatedStorage
	end
	
	return functions
end

function Networking:sendPlayerAction(action, data)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:FindFirstChild("PlayerAction")
	
	if event then
		event:FireServer(action, data)
	end
end

function Networking:sendAbilityUsed(abilityName, targetPos)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:FindFirstChild("AbilityUsed")
	
	if event then
		event:FireServer(abilityName, targetPos)
	end
end

function Networking:sendEnemyDamage(enemyId, damage, damageType)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:FindFirstChild("EnemyDamage")
	
	if event then
		event:FireServer(enemyId, damage, damageType)
	end
end

function Networking:onPlayerDamage(callback)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:WaitForChild("PlayerDamage")
	
	event.OnClientEvent:Connect(callback)
end

function Networking:onEnemyUpdate(callback)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:WaitForChild("EnemyUpdate")
	
	event.OnClientEvent:Connect(callback)
end

function Networking:onLootDrop(callback)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local event = ReplicatedStorage:WaitForChild("LootDrop")
	
	event.OnClientEvent:Connect(callback)
end

function Networking:getPlayerStats(callback)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local func = ReplicatedStorage:WaitForChild("GetPlayerStats")
	
	local stats = func:InvokeServer()
	if callback then callback(stats) end
	return stats
end

function Networking:getDungeonData(callback)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local func = ReplicatedStorage:WaitForChild("GetDungeonData")
	
	local data = func:InvokeServer()
	if callback then callback(data) end
	return data
end

return Networking
