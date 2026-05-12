local GameData = require(script.Parent:WaitForChild("game_data"))

local CombatSystem = {}
CombatSystem.__index = CombatSystem

function CombatSystem.new()
	local self = setmetatable({}, CombatSystem)
	self.damageNumbers = {}
	return self
end

function CombatSystem:calculateDamage(attacker, defender, abilityName)
	local ability = GameData.ABILITIES[abilityName] or GameData.ABILITIES.Slash
	local baseDamage = attacker:calculateDamage() * ability.damage
	
	local isCrit = math.random() < attacker:calculateCritChance()
	if isCrit then
		baseDamage = baseDamage * GameData.PLAYER_CONFIG.critDamageMultiplier
	end
	
	local variance = baseDamage * 0.1
	local finalDamage = baseDamage + (math.random() - 0.5) * variance * 2
	
	return math.max(1, math.floor(finalDamage)), isCrit
end

function CombatSystem:calculateAoEDamage(ability, distance)
	local abilityData = GameData.ABILITIES[ability]
	if not abilityData or not abilityData.aoe then
		return 0
	end
	
	local range = abilityData.range
	if distance > range then return 0 end
	
	local falloff = 1 - (distance / range)
	return abilityData.damage * falloff
end

function CombatSystem:applyStatusEffect(target, effectName, attacker)
	local effectData = GameData.STATUS_EFFECTS[effectName]
	if not effectData then return end
	
	target:addStatusEffect(effectName, effectData.duration)
	
	if effectData.damagePerSecond then
		target.statusDamage = (target.statusDamage or 0) + effectData.damagePerSecond
	end
	
	if effectData.slowPercent then
		target.slowPercent = (target.slowPercent or 0) + effectData.slowPercent
	end
end

function CombatSystem:getAbilityByKey(key)
	local abilityMap = {
		[Enum.KeyCode.One] = "Slash",
		[Enum.KeyCode.Two] = "Fireball",
		[Enum.KeyCode.Three] = "IceShards",
		[Enum.KeyCode.Four] = "LightningBolt",
	}
	return abilityMap[key]
end

function CombatSystem:createDamageNumber(position, damage, isCrit)
	return {
		position = position,
		damage = damage,
		isCrit = isCrit,
		lifetime = 2,
		age = 0,
		color = isCrit and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(255, 255, 255),
	}
end

function CombatSystem:updateDamageNumbers(deltaTime)
	for i = #self.damageNumbers, 1, -1 do
		local dmgNum = self.damageNumbers[i]
		dmgNum.age = dmgNum.age + deltaTime
		
		if dmgNum.age >= dmgNum.lifetime then
			table.remove(self.damageNumbers, i)
		end
	end
end

function CombatSystem:isInRange(pos1, pos2, range)
	local dx = pos1.X - pos2.X
	local dy = pos1.Z - pos2.Z
	local distance = math.sqrt(dx * dx + dy * dy)
	return distance <= range
end

function CombatSystem:getTargetsInAoE(centerPos, radius, excludeTarget)
	local targets = {}
	
	return targets
end

function CombatSystem:canAttack(attacker, defender, range)
	if not attacker or not defender then return false end
	if attacker.currentHealth <= 0 or defender.currentHealth <= 0 then return false end
	
	return self:isInRange(attacker.position, defender.position, range)
end

return CombatSystem
