local PlayerStats = {}
PlayerStats.__index = PlayerStats

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaceStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("race_stats"))

function PlayerStats.new(character, raceName)
	local self = setmetatable({}, PlayerStats)

	self.character = character
	self.humanoid = character:FindFirstChild("Humanoid")
	self.raceName = raceName
	self.raceStats = RaceStats.getRaceStats(raceName)

	self.realHP = self.raceStats.hp
	self.tempHP = 0
	self.maxHP  = self.raceStats.hp
	self.regenRate = self.raceStats.regenRate
	self.lastDamageTime = 0

	-- XP / Levelling
	self.xp       = 0
	self.level    = 1
	self.xpNeeded = 100
	self.talentPoints = 0
	self.talents = {}

	if self.raceStats.hasShield then
		self.shield = self.raceStats.shieldMax
		self.maxShield = self.raceStats.shieldMax
		self.shieldRegenRate = self.raceStats.shieldRegenRate
		self.shieldRegenDelay = self.raceStats.shieldRegenDelay
	end

	if self.raceStats.hasRage then
		self.rage = 0
		self.maxRage = 100
		self.rageActive = false
		self.rageDuration = 0
		self.rageDamageMultiplier = 1.5
		self.rageSpeedMultiplier = 1.3
	end

	if self.raceStats.hasMana then
		self.mana = 100
		self.maxMana = 100
		self.manaRegenRate = 5
	end

	if self.humanoid then
		self.humanoid.MaxHealth = self.maxHP
		self.humanoid.Health = self.realHP
	end

	return self
end

function PlayerStats:update(dt)
	self.lastDamageTime = self.lastDamageTime - dt

	self:updateHP(dt)
	self:updateShield(dt)
	self:updateRage(dt)
	self:updateMana(dt)
end

function PlayerStats:updateHP(dt)
	if self.realHP < self.maxHP then
		self.realHP = math.min(self.maxHP, self.realHP + self.regenRate * dt)
		if self.humanoid then
			self.humanoid.Health = self.realHP + self.tempHP
		end
	end
end

function PlayerStats:updateShield(dt)
	if not self.raceStats.hasShield then return end

	if self.lastDamageTime < 0 and self.shield < self.maxShield then
		self.shield = math.min(self.maxShield, self.shield + self.shieldRegenRate * dt)
	end
end

function PlayerStats:updateRage(dt)
	if not self.raceStats.hasRage then return end

	if self.rageActive then
		self.rageDuration = self.rageDuration - dt
		if self.rageDuration <= 0 then
			self:deactivateRage()
		end
	end
end

function PlayerStats:updateMana(dt)
	if not self.raceStats.hasMana then return end

	if self.mana < self.maxMana then
		self.mana = math.min(self.maxMana, self.mana + self.manaRegenRate * dt)
	end
end

function PlayerStats:takeDamage(amount)
	self.lastDamageTime = self.shieldRegenDelay or 0

	if self.raceStats.hasShield and self.shield > 0 then
		local shieldDamage = math.min(self.shield, amount)
		self.shield = self.shield - shieldDamage
		amount = amount - shieldDamage
	end

	if amount > 0 then
		self.realHP = math.max(0, self.realHP - amount)
		if self.humanoid then
			self.humanoid.Health = self.realHP + self.tempHP
		end
	end

	if self.raceStats.hasRage then
		self.rage = math.min(self.maxRage, self.rage + amount * 0.5)
		if self.rage >= self.maxRage then
			self:activateRage()
		end
	end
end

function PlayerStats:addTempHP(amount)
	self.tempHP = self.tempHP + amount
	if self.humanoid then
		self.humanoid.Health = self.realHP + self.tempHP
	end
end

function PlayerStats:activateRage()
	if self.rageActive then return end
	self.rageActive = true
	self.rageDuration = 5
	self.rage = 0
	print(self.raceName .. " RAGES!")
end

function PlayerStats:gainXP(amount)
	self.xp = (self.xp or 0) + amount
	local KillFeed = require(script.Parent:WaitForChild("kill_feed"))
	KillFeed.showXPGain(amount)

	while self.xp >= self.xpNeeded do
		self.xp = self.xp - self.xpNeeded
		self.level = self.level + 1
		self.talentPoints = self.talentPoints + 1
		self.xpNeeded = math.floor(self.xpNeeded * 1.5)
		self.maxHP = self.maxHP + 10
		self.realHP = math.min(self.realHP + 20, self.maxHP)
		if self.humanoid then
			self.humanoid.MaxHealth = self.maxHP
			self.humanoid.Health = self.realHP
		end
		print("Level up! Now level", self.level)
		
		local SM = require(script.Parent:WaitForChild("sound_manager"))
		KillFeed.showLevelUp(self.level)
		SM.LevelUp()
	end
end

function PlayerStats:deactivateRage()
	self.rageActive = false
	self.rage = 0
end

function PlayerStats:getRageDamageMultiplier()
	if self.rageActive then
		return self.rageDamageMultiplier
	end
	return 1
end

function PlayerStats:getRageSpeedMultiplier()
	if self.rageActive then
		return self.rageSpeedMultiplier
	end
	return 1
end

function PlayerStats:getStats()
	return {
		race = self.raceName,
		realHP = self.realHP,
		maxHP = self.maxHP,
		tempHP = self.tempHP,
		totalHP = self.realHP + self.tempHP,
		shield = self.shield or 0,
		maxShield = self.maxShield or 0,
		rage = self.rage or 0,
		maxRage = self.maxRage or 0,
		rageActive = self.rageActive or false,
		mana = self.mana or 0,
		maxMana = self.maxMana or 0,
		level = self.level,
		exp = self.xp
	}
end

return PlayerStats
