-- Enemy Data - Defines all enemy types and stats
local Constants = require(script.Parent:WaitForChild("constants"))

local EnemyData = {}

EnemyData.ENEMY_STATS = {
	[Constants.ENEMY_TYPES.GOBLIN_SKELETON] = {
		name = "Goblin Skeleton",
		max_hp = 15,
		damage = 3,
		speed = 120,
		attack_range = 2,
		attack_cooldown = 1.0,
		xp_value = 5,
		gold_drop = 1,
		size = 0.8,
		color = Color3.fromRGB(150, 150, 140),
		category = "standard",
	},
	[Constants.ENEMY_TYPES.ELVEN_SKELETON] = {
		name = "Elven Skeleton",
		max_hp = 25,
		damage = 5,
		speed = 100,
		attack_range = 2.5,
		attack_cooldown = 1.2,
		xp_value = 10,
		gold_drop = 2,
		size = 1.0,
		color = Color3.fromRGB(180, 180, 170),
		category = "standard",
	},
	[Constants.ENEMY_TYPES.GOBLIN_ZED] = {
		name = "Goblin Zed",
		max_hp = 40,
		damage = 8,
		speed = 90,
		attack_range = 2,
		attack_cooldown = 1.5,
		xp_value = 15,
		gold_drop = 3,
		size = 0.9,
		color = Color3.fromRGB(100, 150, 100),
		category = "standard",
	},
	[Constants.ENEMY_TYPES.SMALL_ORC_ZED] = {
		name = "Small Orc Zed",
		max_hp = 60,
		damage = 12,
		speed = 80,
		attack_range = 2.5,
		attack_cooldown = 1.8,
		xp_value = 20,
		gold_drop = 5,
		size = 1.1,
		color = Color3.fromRGB(150, 100, 80),
		category = "standard",
	},
	[Constants.ENEMY_TYPES.FLYING_ELF_SKULL] = {
		name = "Flying Elf Skull",
		max_hp = 10,
		damage = 30,
		speed = 150,
		attack_range = 1.5,
		attack_cooldown = 3.0,
		xp_value = 25,
		gold_drop = 5,
		size = 0.6,
		color = Color3.fromRGB(150, 200, 220),
		category = "special",
		can_fly = true,
	},
	[Constants.ENEMY_TYPES.MEDIUM_ORC_ZED] = {
		name = "Medium Orc Zed",
		max_hp = 150,
		damage = 20,
		speed = 70,
		attack_range = 2.5,
		attack_cooldown = 2.0,
		xp_value = 50,
		gold_drop = 10,
		size = 1.3,
		color = Color3.fromRGB(180, 80, 60),
		category = "elite",
	},
	[Constants.ENEMY_TYPES.DWARVEN_ZED] = {
		name = "Dwarven Zed",
		max_hp = 200,
		damage = 15,
		speed = 60,
		attack_range = 2,
		attack_cooldown = 2.5,
		xp_value = 60,
		gold_drop = 15,
		size = 0.9,
		color = Color3.fromRGB(150, 120, 80),
		category = "elite",
		armored = true,
	},
	[Constants.ENEMY_TYPES.HUMAN_ZED] = {
		name = "Human Zed",
		max_hp = 500,
		damage = 25,
		speed = 80,
		attack_range = 3,
		attack_cooldown = 1.0,
		xp_value = 200,
		gold_drop = 50,
		size = 1.2,
		color = Color3.fromRGB(100, 150, 200),
		category = "boss",
		has_ranged = true,
	},
	[Constants.ENEMY_TYPES.HUGE_ORC_ZED] = {
		name = "Huge Orc Zed",
		max_hp = 800,
		damage = 40,
		speed = 50,
		attack_range = 3,
		attack_cooldown = 3.0,
		xp_value = 300,
		gold_drop = 75,
		size = 1.8,
		color = Color3.fromRGB(200, 60, 40),
		category = "boss",
	},
	[Constants.ENEMY_TYPES.ELVEN_NECROMANCER] = {
		name = "Elven Necromancer",
		max_hp = 400,
		damage = 15,
		speed = 60,
		attack_range = 4,
		attack_cooldown = 2.0,
		xp_value = 250,
		gold_drop = 60,
		size = 1.1,
		color = Color3.fromRGB(120, 60, 180),
		category = "boss",
		can_summon = true,
	},
}

function EnemyData:get_enemy_stats(enemy_type)
	return self.ENEMY_STATS[enemy_type] or self.ENEMY_STATS[Constants.ENEMY_TYPES.GOBLIN_SKELETON]
end

function EnemyData:get_random_enemy_type()
	local types = {}
	for enemy_type, _ in pairs(self.ENEMY_STATS) do
		table.insert(types, enemy_type)
	end
	return types[math.random(1, #types)]
end

function EnemyData:get_enemies_by_category(category)
	local enemies = {}
	for enemy_type, stats in pairs(self.ENEMY_STATS) do
		if stats.category == category then
			table.insert(enemies, enemy_type)
		end
	end
	return enemies
end

return EnemyData
