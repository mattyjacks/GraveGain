-- Player Data Module - Manages character stats and progression
local Constants = require(script.Parent:WaitForChild("constants"))

local PlayerData = {}
PlayerData.__index = PlayerData

-- Race stat definitions
local RACE_STATS = {
	[Constants.RACES.HUMAN] = {
		name = "Human",
		max_hp = 100,
		hp_regen = 1,
		max_stamina = 100,
		run_speed = 250,
		has_shields = true,
		max_shields = 20,
		shield_regen = 2,
		shield_delay = 5,
		has_mana = false,
		max_mana = 0,
		mana_regen = 0,
		has_rage = false,
		max_rage = 0,
		melee_damage = 12,
		ranged_damage = 10,
	},
	[Constants.RACES.ELF] = {
		name = "Elf",
		max_hp = 75,
		hp_regen = 3,
		max_stamina = 100,
		run_speed = 275,
		has_shields = false,
		max_shields = 0,
		shield_regen = 0,
		shield_delay = 0,
		has_mana = true,
		max_mana = 100,
		mana_regen = 2,
		has_rage = false,
		max_rage = 0,
		melee_damage = 14,
		ranged_damage = 12,
	},
	[Constants.RACES.DWARF] = {
		name = "Dwarf",
		max_hp = 150,
		hp_regen = 2,
		max_stamina = 100,
		run_speed = 200,
		has_shields = false,
		max_shields = 0,
		shield_regen = 0,
		shield_delay = 0,
		has_mana = false,
		max_mana = 0,
		mana_regen = 0,
		has_rage = false,
		max_rage = 0,
		melee_damage = 18,
		ranged_damage = 8,
	},
	[Constants.RACES.ORC] = {
		name = "Orc",
		max_hp = 200,
		hp_regen = 3,
		max_stamina = 100,
		run_speed = 225,
		has_shields = false,
		max_shields = 0,
		shield_regen = 0,
		shield_delay = 0,
		has_mana = false,
		max_mana = 0,
		mana_regen = 0,
		has_rage = true,
		max_rage = 100,
		melee_damage = 20,
		ranged_damage = 6,
	},
}

function PlayerData.new(player_id, username, race, class_type)
	local self = setmetatable({}, PlayerData)
	
	self.player_id = player_id
	self.username = username
	self.race = race
	self.class_type = class_type
	self.team = nil
	
	-- Load race stats
	local race_stats = RACE_STATS[race] or RACE_STATS[Constants.RACES.HUMAN]
	self.max_hp = race_stats.max_hp
	self.hp = self.max_hp
	self.hp_regen = race_stats.hp_regen
	
	self.max_stamina = race_stats.max_stamina
	self.stamina = self.max_stamina
	self.stamina_regen_rate = 15
	
	self.has_shields = race_stats.has_shields
	self.max_shields = race_stats.max_shields
	self.shields = self.max_shields
	self.shield_regen = race_stats.shield_regen
	self.shield_delay = race_stats.shield_delay
	self.shield_delay_timer = 0
	
	self.has_mana = race_stats.has_mana
	self.max_mana = race_stats.max_mana
	self.mana = self.max_mana
	self.mana_regen = race_stats.mana_regen
	
	self.has_rage = race_stats.has_rage
	self.max_rage = race_stats.max_rage
	self.rage = 0
	
	self.run_speed = race_stats.run_speed
	self.melee_damage = race_stats.melee_damage
	self.ranged_damage = race_stats.ranged_damage
	
	-- Combat stats
	self.total_kills = 0
	self.total_deaths = 0
	self.gold_earned = 0
	self.xp_earned = 0
	self.level = 1
	
	-- Status
	self.is_alive = true
	self.is_down = false
	self.is_reviving = false
	self.revive_progress = 0
	self.revive_duration = 5
	
	return self
end

function PlayerData:take_damage(amount)
	if not self.is_alive then return end
	
	local damage = amount
	
	if self.shields > 0 then
		local shield_absorb = math.min(self.shields, damage)
		self.shields = self.shields - shield_absorb
		damage = damage - shield_absorb
		self.shield_delay_timer = self.shield_delay
	end
	
	if damage > 0 then
		self.hp = math.max(0, self.hp - damage)
		if self.hp <= 0 then
			self:die()
		end
	end
end

function PlayerData:heal(amount)
	if not self.is_alive then return end
	self.hp = math.min(self.max_hp, self.hp + amount)
end

function PlayerData:restore_stamina(amount)
	self.stamina = math.min(self.max_stamina, self.stamina + amount)
end

function PlayerData:restore_mana(amount)
	if self.has_mana then
		self.mana = math.min(self.max_mana, self.mana + amount)
	end
end

function PlayerData:add_rage(amount)
	if self.has_rage then
		self.rage = math.min(self.max_rage, self.rage + amount)
	end
end

function PlayerData:consume_rage(amount)
	if self.has_rage and self.rage >= amount then
		self.rage = self.rage - amount
		return true
	end
	return false
end

function PlayerData:down()
	if self.is_alive and not self.is_down then
		self.is_down = true
		self.hp = 0
	end
end

function PlayerData:revive(reviver_id)
	if self.is_down then
		self.is_reviving = true
		self.revive_progress = 0
	end
end

function PlayerData:complete_revive()
	if self.is_reviving then
		self.is_reviving = false
		self.is_down = false
		self.hp = self.max_hp * 0.5
	end
end

function PlayerData:die()
	self.is_alive = false
	self.is_down = false
	self.total_deaths = self.total_deaths + 1
end

function PlayerData:add_kill()
	self.total_kills = self.total_kills + 1
end

function PlayerData:add_gold(amount)
	self.gold_earned = self.gold_earned + amount
end

function PlayerData:add_xp(amount)
	self.xp_earned = self.xp_earned + amount
end

function PlayerData:get_class_name()
	local race_classes = Constants.RACE_CLASS_NAMES[self.race]
	if race_classes then
		return race_classes[self.class_type] or "Unknown"
	end
	return "Unknown"
end

function PlayerData:to_dictionary()
	return {
		player_id = self.player_id,
		username = self.username,
		race = self.race,
		class_type = self.class_type,
		team = self.team,
		hp = self.hp,
		max_hp = self.max_hp,
		stamina = self.stamina,
		max_stamina = self.max_stamina,
		shields = self.shields,
		mana = self.mana,
		rage = self.rage,
		total_kills = self.total_kills,
		total_deaths = self.total_deaths,
		gold_earned = self.gold_earned,
		xp_earned = self.xp_earned,
		level = self.level,
		is_alive = self.is_alive,
		is_down = self.is_down,
	}
end

return PlayerData
