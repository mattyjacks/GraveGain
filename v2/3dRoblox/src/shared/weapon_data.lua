-- Weapon Data - Defines all weapon types and stats
local WeaponData = {}

WeaponData.WEAPON_TYPES = {
	MELEE = 1,
	RANGED = 2,
}

WeaponData.MELEE_WEAPONS = {
	SWORD = {
		name = "Sword",
		damage = 25,
		attack_speed = 1.0,
		range = 3,
		knockback = 10,
		crit_chance = 0.1,
		crit_multiplier = 2.0,
	},
	AXE = {
		name = "Axe",
		damage = 35,
		attack_speed = 0.8,
		range = 3.5,
		knockback = 15,
		crit_chance = 0.15,
		crit_multiplier = 2.5,
	},
	HAMMER = {
		name = "Hammer",
		damage = 40,
		attack_speed = 0.6,
		range = 3,
		knockback = 20,
		crit_chance = 0.05,
		crit_multiplier = 1.5,
	},
	DAGGER = {
		name = "Dagger",
		damage = 15,
		attack_speed = 1.5,
		range = 2,
		knockback = 5,
		crit_chance = 0.25,
		crit_multiplier = 2.0,
	},
}

WeaponData.RANGED_WEAPONS = {
	CROSSBOW = {
		name = "Crossbow",
		damage = 30,
		fire_rate = 1.2,
		ammo_per_shot = 1,
		range = 100,
		accuracy = 0.95,
		crit_chance = 0.1,
		crit_multiplier = 2.0,
		reload_time = 1.5,
	},
	MUSKET = {
		name = "Musket",
		damage = 50,
		fire_rate = 2.0,
		ammo_per_shot = 1,
		range = 150,
		accuracy = 0.85,
		crit_chance = 0.15,
		crit_multiplier = 2.5,
		reload_time = 3.0,
	},
	PISTOL = {
		name = "Pistol",
		damage = 20,
		fire_rate = 0.5,
		ammo_per_shot = 1,
		range = 80,
		accuracy = 0.9,
		crit_chance = 0.1,
		crit_multiplier = 1.8,
		reload_time = 1.0,
	},
	BOW = {
		name = "Bow",
		damage = 25,
		fire_rate = 0.8,
		ammo_per_shot = 1,
		range = 120,
		accuracy = 0.98,
		crit_chance = 0.2,
		crit_multiplier = 2.0,
		reload_time = 0.5,
	},
}

function WeaponData:get_melee_weapon(weapon_type)
	return self.MELEE_WEAPONS[weapon_type]
end

function WeaponData:get_ranged_weapon(weapon_type)
	return self.RANGED_WEAPONS[weapon_type]
end

function WeaponData:get_all_melee_weapons()
	local weapons = {}
	for name, data in pairs(self.MELEE_WEAPONS) do
		table.insert(weapons, { name = name, data = data })
	end
	return weapons
end

function WeaponData:get_all_ranged_weapons()
	local weapons = {}
	for name, data in pairs(self.RANGED_WEAPONS) do
		table.insert(weapons, { name = name, data = data })
	end
	return weapons
end

return WeaponData
