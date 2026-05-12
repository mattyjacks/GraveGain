local GameData = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("game_data"))

local EnemyAI = {}
EnemyAI.__index = EnemyAI

function EnemyAI.new(enemyData, position)
	local self = setmetatable({}, EnemyAI)
	
	self.type = enemyData.type
	self.position = position
	self.health = enemyData.health
	self.maxHealth = enemyData.maxHealth
	self.damage = enemyData.damage
	self.xp = enemyData.xp
	self.isBoss = enemyData.isBoss or false
	
	self.state = "Idle"
	self.stateTimer = 0
	self.targetPlayer = nil
	self.detectionRange = 20
	self.attackRange = 2
	self.moveSpeed = 10
	self.attackCooldown = 0
	self.attackCooldownMax = 1.5
	
	self.affixes = self:generateAffixes()
	self:applyAffixes()
	
	return self
end

function EnemyAI:generateAffixes()
	local affixes = {}
	
	if math.random() > 0.7 then
		local affixKeys = {}
		for key, _ in pairs(GameData.ENEMY_AFFIXES) do
			table.insert(affixKeys, key)
		end
		
		local numAffixes = math.random(1, 2)
		for i = 1, numAffixes do
			if #affixKeys > 0 then
				local idx = math.random(#affixKeys)
				table.insert(affixes, affixKeys[idx])
				table.remove(affixKeys, idx)
			end
		end
	end
	
	return affixes
end

function EnemyAI:applyAffixes()
	for _, affix in ipairs(self.affixes) do
		local affixData = GameData.ENEMY_AFFIXES[affix]
		if affixData then
			if affixData.speedMult then
				self.moveSpeed = self.moveSpeed * affixData.speedMult
			end
		end
	end
end

function EnemyAI:update(deltaTime, players)
	self.stateTimer = self.stateTimer - deltaTime
	self.attackCooldown = math.max(0, self.attackCooldown - deltaTime)
	
	self:updateState(players)
	self:performAction(deltaTime, players)
end

function EnemyAI:updateState(players)
	local nearestPlayer = self:findNearestPlayer(players)
	
	if nearestPlayer then
		local distance = (self.position - nearestPlayer.position).Magnitude
		
		if distance < self.attackRange then
			self.state = "Attack"
			self.targetPlayer = nearestPlayer
		elseif distance < self.detectionRange then
			self.state = "Chase"
			self.targetPlayer = nearestPlayer
		else
			self.state = "Patrol"
			self.targetPlayer = nil
		end
	else
		self.state = "Idle"
		self.targetPlayer = nil
	end
end

function EnemyAI:performAction(deltaTime, players)
	if self.state == "Idle" then
		self:performIdle(deltaTime)
	elseif self.state == "Patrol" then
		self:performPatrol(deltaTime)
	elseif self.state == "Chase" then
		self:performChase(deltaTime)
	elseif self.state == "Attack" then
		self:performAttack(deltaTime)
	end
end

function EnemyAI:performIdle(deltaTime)
	if self.stateTimer <= 0 then
		self.stateTimer = math.random(2, 5)
	end
end

function EnemyAI:performPatrol(deltaTime)
	if self.stateTimer <= 0 then
		self.stateTimer = math.random(3, 8)
	end
end

function EnemyAI:performChase(deltaTime)
	if not self.targetPlayer then return end
	
	local direction = (self.targetPlayer.position - self.position)
	if direction.Magnitude > 0 then
		direction = direction.Unit
		self.position = self.position + direction * self.moveSpeed * deltaTime
	end
end

function EnemyAI:performAttack(deltaTime)
	if not self.targetPlayer then return end
	
	if self.attackCooldown <= 0 then
		self:attack(self.targetPlayer)
		self.attackCooldown = self.attackCooldownMax
	end
end

function EnemyAI:attack(target)
	if not target then return end
	
	local damage = self.damage + (math.random() - 0.5) * self.damage * 0.2
	
	return {
		damage = damage,
		type = "Physical",
		source = self,
		target = target,
	}
end

function EnemyAI:findNearestPlayer(players)
	local nearest = nil
	local nearestDistance = math.huge
	
	for _, player in ipairs(players) do
		if player.position then
			local distance = (self.position - player.position).Magnitude
			if distance < nearestDistance then
				nearest = player
				nearestDistance = distance
			end
		end
	end
	
	return nearest
end

function EnemyAI:takeDamage(amount)
	self.health = math.max(0, self.health - amount)
	return self.health <= 0
end

function EnemyAI:getState()
	return {
		type = self.type,
		position = self.position,
		health = self.health,
		maxHealth = self.maxHealth,
		state = self.state,
		affixes = self.affixes,
		isBoss = self.isBoss,
	}
end

return EnemyAI
