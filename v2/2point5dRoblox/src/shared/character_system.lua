local GameData = require(script.Parent:WaitForChild("game_data"))

local CharacterSystem = {}
CharacterSystem.__index = CharacterSystem

function CharacterSystem.new(race, difficulty)
	local self = setmetatable({}, CharacterSystem)
	
	self.race = race
	self.difficulty = difficulty or "Normal"
	self.class = "Adventurer"
	self.level = 1
	self.experience = 0
	self.gold = 0
	
	local raceData = GameData.RACES[race]
	self.baseStats = {
		str = raceData.stats.str,
		dex = raceData.stats.dex,
		int = raceData.stats.int,
		vit = raceData.stats.vit,
		lck = raceData.stats.lck,
	}
	
	self.statPoints = 0
	self.skillPoints = 0
	self.skills = {
		Melee = 0,
		Magic = 0,
		Survival = 0,
	}
	
	self.maxHealth = self:calculateMaxHealth()
	self.currentHealth = self.maxHealth
	self.maxMana = self:calculateMaxMana()
	self.currentMana = self.maxMana
	
	self.inventory = {}
	self.equipment = {}
	for _, slot in ipairs(GameData.EQUIPMENT_SLOTS) do
		self.equipment[slot] = nil
	end
	
	self.abilities = { "Slash", "DodgeRoll" }
	self.abilityTimers = {}
	
	self.statusEffects = {}
	
	return self
end

function CharacterSystem:calculateMaxHealth()
	local config = GameData.PLAYER_CONFIG
	local vit = self.baseStats.vit
	local armorBonus = self.level * config.armorPerLevel
	return config.baseHealth + (vit * config.healthPerVit) + armorBonus
end

function CharacterSystem:calculateMaxMana()
	local config = GameData.PLAYER_CONFIG
	local int = self.baseStats.int
	return config.baseMana + (int * config.manaPerInt)
end

function CharacterSystem:calculateDamage()
	local config = GameData.PLAYER_CONFIG
	local str = self.baseStats.str
	local baseDamage = 5
	local weapon = self.equipment.Weapon
	
	if weapon then
		baseDamage = weapon.damage or 5
	end
	
	return baseDamage + (str * config.damagePerStr)
end

function CharacterSystem:calculateCritChance()
	local config = GameData.PLAYER_CONFIG
	local dex = self.baseStats.dex
	return math.min(0.5, dex * config.critChancePerDex)
end

function CharacterSystem:gainExperience(amount)
	local raceData = GameData.RACES[self.race]
	local actualXP = amount * raceData.xpMultiplier
	self.experience = self.experience + actualXP
	
	local xpNeeded = GameData.GAME_BALANCE.xpPerLevel * self.level
	if self.experience >= xpNeeded then
		self:levelUp()
	end
	
	return actualXP
end

function CharacterSystem:levelUp()
	self.level = self.level + 1
	self.experience = 0
	self.statPoints = self.statPoints + 5
	self.skillPoints = self.skillPoints + 1
	
	self.maxHealth = self:calculateMaxHealth()
	self.currentHealth = self.maxHealth
	self.maxMana = self:calculateMaxMana()
	self.currentMana = self.maxMana
	
	return self.level
end

function CharacterSystem:addStatPoint(stat, amount)
	if self.statPoints >= amount then
		self.baseStats[stat] = self.baseStats[stat] + amount
		self.statPoints = self.statPoints - amount
		
		self.maxHealth = self:calculateMaxHealth()
		self.maxMana = self:calculateMaxMana()
		
		return true
	end
	return false
end

function CharacterSystem:addSkillPoint(branch, amount)
	if self.skillPoints >= amount then
		self.skills[branch] = self.skills[branch] + amount
		self.skillPoints = self.skillPoints - amount
		return true
	end
	return false
end

function CharacterSystem:takeDamage(amount, damageType)
	damageType = damageType or "Physical"
	self.currentHealth = math.max(0, self.currentHealth - amount)
	return self.currentHealth <= 0
end

function CharacterSystem:heal(amount)
	self.currentHealth = math.min(self.maxHealth, self.currentHealth + amount)
end

function CharacterSystem:restoreMana(amount)
	self.currentMana = math.min(self.maxMana, self.currentMana + amount)
end

function CharacterSystem:canUseAbility(abilityName)
	local ability = GameData.ABILITIES[abilityName]
	if not ability then return false end
	
	if self.currentMana < ability.manaCost then return false end
	
	local timer = self.abilityTimers[abilityName] or 0
	if timer > 0 then return false end
	
	return true
end

function CharacterSystem:useAbility(abilityName)
	if not self:canUseAbility(abilityName) then return false end
	
	local ability = GameData.ABILITIES[abilityName]
	self.currentMana = self.currentMana - ability.manaCost
	self.abilityTimers[abilityName] = ability.cooldown
	
	return true
end

function CharacterSystem:updateAbilityCooldowns(deltaTime)
	for abilityName, timer in pairs(self.abilityTimers) do
		if timer > 0 then
			self.abilityTimers[abilityName] = timer - deltaTime
		end
	end
end

function CharacterSystem:addStatusEffect(effectName, duration)
	if not self.statusEffects[effectName] then
		self.statusEffects[effectName] = duration
	end
end

function CharacterSystem:updateStatusEffects(deltaTime)
	for effectName, duration in pairs(self.statusEffects) do
		self.statusEffects[effectName] = duration - deltaTime
		if self.statusEffects[effectName] <= 0 then
			self.statusEffects[effectName] = nil
		end
	end
end

function CharacterSystem:addGold(amount)
	self.gold = self.gold + amount
end

function CharacterSystem:spendGold(amount)
	if self.gold >= amount then
		self.gold = self.gold - amount
		return true
	end
	return false
end

function CharacterSystem:getStats()
	return {
		level = self.level,
		experience = self.experience,
		health = self.currentHealth,
		maxHealth = self.maxHealth,
		mana = self.currentMana,
		maxMana = self.maxMana,
		damage = self:calculateDamage(),
		critChance = self:calculateCritChance(),
		gold = self.gold,
		stats = self.baseStats,
		skills = self.skills,
	}
end

return CharacterSystem
