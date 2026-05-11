-- Stats Tracker - Tracks player statistics and achievements
local StatsTracker = {}
StatsTracker.__index = StatsTracker

StatsTracker.ACHIEVEMENTS = {
	first_kill = {
		name = "First Blood",
		description = "Kill your first enemy",
		icon = "🗡️",
	},
	hundred_kills = {
		name = "Centurion",
		description = "Reach 100 kills",
		icon = "⚔️",
	},
	thousand_kills = {
		name = "Legendary Warrior",
		description = "Reach 1000 kills",
		icon = "👑",
	},
	first_crit = {
		name = "Critical Moment",
		description = "Land your first critical hit",
		icon = "✨",
	},
	ten_crits = {
		name = "Precision Master",
		description = "Land 10 critical hits in one mission",
		icon = "🎯",
	},
	survive_wave_10 = {
		name = "Wave Survivor",
		description = "Survive wave 10",
		icon = "🛡️",
	},
	collect_artifact = {
		name = "Treasure Hunter",
		description = "Collect your first artifact",
		icon = "💎",
	},
	revive_teammate = {
		name = "Lifesaver",
		description = "Revive a teammate",
		icon = "❤️",
	},
	complete_nightmare = {
		name = "Nightmare Conqueror",
		description = "Complete a mission on Nightmare difficulty",
		icon = "👿",
	},
	perfect_mission = {
		name = "Flawless",
		description = "Complete a mission without taking damage",
		icon = "⭐",
	},
}

function StatsTracker.new()
	local self = setmetatable({}, StatsTracker)
	
	self.stats = {
		total_kills = 0,
		total_deaths = 0,
		total_damage_dealt = 0,
		total_damage_taken = 0,
		total_gold_collected = 0,
		total_xp_earned = 0,
		missions_completed = 0,
		missions_failed = 0,
		critical_hits = 0,
		headshots = 0,
		revives_given = 0,
		revives_received = 0,
		artifacts_collected = 0,
		playtime_seconds = 0,
	}
	
	self.achievements_unlocked = {}
	self.current_mission_stats = {}
	
	return self
end

function StatsTracker:initialize()
	print("[StatsTracker] Initialized")
end

function StatsTracker:start_mission()
	self.current_mission_stats = {
		kills = 0,
		deaths = 0,
		damage_dealt = 0,
		damage_taken = 0,
		gold_collected = 0,
		critical_hits = 0,
		mission_start_time = tick(),
	}
end

function StatsTracker:end_mission(success)
	if success then
		self.stats.missions_completed = self.stats.missions_completed + 1
	else
		self.stats.missions_failed = self.stats.missions_failed + 1
	end
	
	self.current_mission_stats = {}
end

function StatsTracker:record_kill(damage_dealt)
	self.stats.total_kills = self.stats.total_kills + 1
	self.stats.total_damage_dealt = self.stats.total_damage_dealt + damage_dealt
	self.current_mission_stats.kills = self.current_mission_stats.kills + 1
	
	self:_check_achievement("first_kill")
	self:_check_achievement("hundred_kills")
	self:_check_achievement("thousand_kills")
end

function StatsTracker:record_death()
	self.stats.total_deaths = self.stats.total_deaths + 1
	self.current_mission_stats.deaths = self.current_mission_stats.deaths + 1
end

function StatsTracker:record_damage_taken(damage)
	self.stats.total_damage_taken = self.stats.total_damage_taken + damage
	self.current_mission_stats.damage_taken = self.current_mission_stats.damage_taken + damage
end

function StatsTracker:record_critical_hit(damage)
	self.stats.critical_hits = self.stats.critical_hits + 1
	self.current_mission_stats.critical_hits = self.current_mission_stats.critical_hits + 1
	
	self:_check_achievement("first_crit")
	self:_check_achievement("ten_crits")
end

function StatsTracker:record_gold_collected(amount)
	self.stats.total_gold_collected = self.stats.total_gold_collected + amount
	self.current_mission_stats.gold_collected = self.current_mission_stats.gold_collected + amount
end

function StatsTracker:record_artifact_collected()
	self.stats.artifacts_collected = self.stats.artifacts_collected + 1
	
	self:_check_achievement("collect_artifact")
end

function StatsTracker:record_revive_given()
	self.stats.revives_given = self.stats.revives_given + 1
	
	self:_check_achievement("revive_teammate")
end

function StatsTracker:record_revive_received()
	self.stats.revives_received = self.stats.revives_received + 1
end

function StatsTracker:_check_achievement(achievement_id)
	if self.achievements_unlocked[achievement_id] then
		return
	end
	
	local achievement = self.ACHIEVEMENTS[achievement_id]
	if not achievement then return end
	
	local unlocked = false
	
	if achievement_id == "first_kill" then
		unlocked = self.stats.total_kills >= 1
	elseif achievement_id == "hundred_kills" then
		unlocked = self.stats.total_kills >= 100
	elseif achievement_id == "thousand_kills" then
		unlocked = self.stats.total_kills >= 1000
	elseif achievement_id == "first_crit" then
		unlocked = self.stats.critical_hits >= 1
	elseif achievement_id == "ten_crits" then
		unlocked = self.current_mission_stats.critical_hits and self.current_mission_stats.critical_hits >= 10
	elseif achievement_id == "collect_artifact" then
		unlocked = self.stats.artifacts_collected >= 1
	elseif achievement_id == "revive_teammate" then
		unlocked = self.stats.revives_given >= 1
	end
	
	if unlocked then
		self.achievements_unlocked[achievement_id] = true
		print("[StatsTracker] Achievement Unlocked:", achievement.name)
	end
end

function StatsTracker:get_stats()
	return self.stats
end

function StatsTracker:get_mission_stats()
	return self.current_mission_stats
end

function StatsTracker:get_achievements()
	return self.achievements_unlocked
end

function StatsTracker:get_kill_death_ratio()
	if self.stats.total_deaths == 0 then
		return self.stats.total_kills
	end
	return self.stats.total_kills / self.stats.total_deaths
end

function StatsTracker:get_average_damage_per_kill()
	if self.stats.total_kills == 0 then
		return 0
	end
	return self.stats.total_damage_dealt / self.stats.total_kills
end

function StatsTracker:get_critical_hit_rate()
	if self.stats.total_kills == 0 then
		return 0
	end
	return (self.stats.critical_hits / self.stats.total_kills) * 100
end

return StatsTracker
