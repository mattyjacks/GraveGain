local CombatSystem = {}
CombatSystem.__index = CombatSystem

local Players = game:GetService("Players")

function CombatSystem.new()
	local self = setmetatable({}, CombatSystem)

	self.character = nil
	self.hrp = nil
	self.humanoid = nil
	self.playerStats = nil
	self.isBlocking = false
	self.attackCooldown = 0
	self.pushCooldown = 0
	self.lastAttackTime = 0

	return self
end

function CombatSystem:setCharacter(character, playerStats)
	self.character = character
	self.hrp = character:FindFirstChild("HumanoidRootPart")
	self.humanoid = character:FindFirstChild("Humanoid")
	self.playerStats = playerStats
end

function CombatSystem:update(dt)
	if self.attackCooldown > 0 then
		self.attackCooldown = self.attackCooldown - dt
	end
	if self.pushCooldown > 0 then
		self.pushCooldown = self.pushCooldown - dt
	end
end

function CombatSystem:performAttack()
	if self.attackCooldown > 0 then return false end
	if not self.character or not self.hrp then return false end

	self.attackCooldown = 0.6
	self.lastAttackTime = tick()

	local damageMultiplier = 1
	if self.playerStats and self.playerStats.rageActive then
		damageMultiplier = self.playerStats:getRageDamageMultiplier()
	end

	local baseDamage = 15 * damageMultiplier
	self:applyDamageToEnemies(baseDamage)

	return true
end

function CombatSystem:performPush(isPowerAttack)
	if self.pushCooldown > 0 then return false end
	if not self.character or not self.hrp then return false end

	local pushForce = isPowerAttack and 50 or 30
	local pushRange = isPowerAttack and 25 or 15
	local pushDamage = isPowerAttack and 25 or 10

	local damageMultiplier = 1
	if self.playerStats and self.playerStats.rageActive then
		damageMultiplier = self.playerStats:getRageDamageMultiplier()
	end

	pushDamage = pushDamage * damageMultiplier
	self.pushCooldown = isPowerAttack and 1.2 or 0.8

	self:applyPushToEnemies(self.hrp.Position, self.hrp.CFrame.LookVector, pushRange, pushForce, pushDamage)

	return true
end

function CombatSystem:applyDamageToEnemies(damage)
	local enemyFolder = workspace:FindFirstChild("Enemies")
	if not enemyFolder then return end

	local rangeSq = 15 * 15

	for _, enemy in ipairs(enemyFolder:GetChildren()) do
		local enemyHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
		if enemyHRP then
			local toEnemy = enemyHRP.Position - self.hrp.Position
			local distSq = toEnemy.X * toEnemy.X + toEnemy.Y * toEnemy.Y + toEnemy.Z * toEnemy.Z

			if distSq < rangeSq then
				local dist = math.sqrt(distSq)
				local dot = (toEnemy.X * self.hrp.CFrame.LookVector.X + toEnemy.Y * self.hrp.CFrame.LookVector.Y + toEnemy.Z * self.hrp.CFrame.LookVector.Z) / dist

				if dot > 0.3 then
					local enemyHumanoid = enemy:FindFirstChild("Humanoid")
					if enemyHumanoid then
						enemyHumanoid:TakeDamage(damage)
						if self.playerStats then
							self.playerStats:addTempHP(damage * 0.25)
						end
					end
				end
			end
		end
	end
end

function CombatSystem:applyPushToEnemies(origin, direction, range, force, damage)
	local enemyFolder = workspace:FindFirstChild("Enemies")
	if not enemyFolder then return end

	local rangeSq = range * range

	for _, enemy in ipairs(enemyFolder:GetChildren()) do
		local enemyHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
		if enemyHRP then
			local toEnemy = enemyHRP.Position - origin
			local distSq = toEnemy.X * toEnemy.X + toEnemy.Y * toEnemy.Y + toEnemy.Z * toEnemy.Z

			if distSq < rangeSq then
				local dist = math.sqrt(distSq)
				local dot = (toEnemy.X * direction.X + toEnemy.Y * direction.Y + toEnemy.Z * direction.Z) / dist

				if dot > 0.5 then
					local pushVec = direction * force + Vector3.new(0, force * 0.3, 0)
					local bv = enemyHRP:FindFirstChild("BodyVelocity")
					if not bv then
						bv = Instance.new("BodyVelocity")
						bv.MaxForce = Vector3.new(10000, 10000, 10000)
						bv.Parent = enemyHRP
					end
					bv.Velocity = pushVec
					game:GetService("Debris"):AddItem(bv, 0.25)

					local enemyHumanoid = enemy:FindFirstChild("Humanoid")
					if enemyHumanoid then
						enemyHumanoid:TakeDamage(damage)
						if self.playerStats then
							self.playerStats:addTempHP(damage * 0.25)
						end
					end
				end
			end
		end
	end
end

function CombatSystem:takeDamage(amount)
	if self.playerStats then
		self.playerStats:takeDamage(amount)
	elseif self.humanoid then
		self.humanoid:TakeDamage(amount)
	end
end

return CombatSystem
