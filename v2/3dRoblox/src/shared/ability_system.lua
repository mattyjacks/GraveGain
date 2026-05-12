local AbilitySystem = {}

-- Class abilities - 4 classes × 4 races = 16 combinations
local ABILITIES = {
	-- DPS Class
	dps = {
		human = {
			name = "DPS Human",
			primary = "Laser Rifle Burst",
			secondary = "Plasma Grenade",
			ability1 = "Jetpack Dash",
			ability2 = "Rapid Fire",
			ultimate = "Orbital Strike"
		},
		elf = {
			name = "DPS Elf",
			primary = "Elven Bow",
			secondary = "Arcane Arrow",
			ability1 = "Hover Strafe",
			ability2 = "Multi-Shot",
			ultimate = "Arrow Storm"
		},
		dwarf = {
			name = "DPS Dwarf",
			primary = "Crossbow",
			secondary = "Explosive Bolt",
			ability1 = "Double Jump Strike",
			ability2 = "Ricochet Shot",
			ultimate = "Barrage"
		},
		orc = {
			name = "DPS Orc",
			primary = "Orc Axe",
			secondary = "Throwing Axe",
			ability1 = "Ground Slam",
			ability2 = "Whirlwind",
			ultimate = "Berserker Rage"
		}
	},
	-- Tank Class
	tank = {
		human = {
			name = "Tank Human",
			primary = "Plasma Cannon",
			secondary = "Shield Generator",
			ability1 = "Jetpack Hover",
			ability2 = "Fortify",
			ultimate = "Defensive Dome"
		},
		elf = {
			name = "Tank Elf",
			primary = "Magical Staff",
			secondary = "Barrier Spell",
			ability1 = "Ethereal Drift",
			ability2 = "Mana Shield",
			ultimate = "Protective Aura"
		},
		dwarf = {
			name = "Tank Dwarf",
			primary = "Warhammer",
			secondary = "Shield Bash",
			ability1 = "Anchored Stance",
			ability2 = "Stonehide",
			ultimate = "Unbreakable"
		},
		orc = {
			name = "Tank Orc",
			primary = "Great Axe",
			secondary = "Bone Shield",
			ability1 = "Slam Defense",
			ability2 = "Thick Skin",
			ultimate = "Unstoppable Force"
		}
	},
	-- Support Class
	support = {
		human = {
			name = "Support Human",
			primary = "Healing Rifle",
			secondary = "Medkit Launcher",
			ability1 = "Jetpack Rescue",
			ability2 = "Heal Burst",
			ultimate = "Mass Heal"
		},
		elf = {
			name = "Support Elf",
			primary = "Healing Staff",
			secondary = "Restoration Spell",
			ability1 = "Hover Heal",
			ability2 = "Blessing",
			ultimate = "Rejuvenation"
		},
		dwarf = {
			name = "Support Dwarf",
			primary = "Alchemist Staff",
			secondary = "Potion Toss",
			ability1 = "Steady Stance",
			ability2 = "Fortify Allies",
			ultimate = "Alchemy Burst"
		},
		orc = {
			name = "Support Orc",
			primary = "Shaman Staff",
			secondary = "Spirit Heal",
			ability1 = "Slam Heal",
			ability2 = "Tribal Blessing",
			ultimate = "Ancestral Power"
		}
	},
	-- Mage Class
	mage = {
		human = {
			name = "Mage Human",
			primary = "Plasma Caster",
			secondary = "Fireball",
			ability1 = "Jetpack Kite",
			ability2 = "Frost Nova",
			ultimate = "Meteor Strike"
		},
		elf = {
			name = "Mage Elf",
			primary = "Arcane Staff",
			secondary = "Arcane Missile",
			ability1 = "Hover Cast",
			ability2 = "Lightning Bolt",
			ultimate = "Arcane Explosion"
		},
		dwarf = {
			name = "Mage Dwarf",
			primary = "Rune Staff",
			secondary = "Earth Spike",
			ability1 = "Double Jump Cast",
			ability2 = "Lava Burst",
			ultimate = "Earthquake"
		},
		orc = {
			name = "Mage Orc",
			primary = "Chaos Staff",
			secondary = "Chaos Bolt",
			ability1 = "Slam Spell",
			ability2 = "Inferno",
			ultimate = "Chaos Realm"
		}
	}
}

-- Random class for 17th gateway
local RANDOM_ABILITIES = {
	name = "Random",
	primary = "Mystery Weapon",
	secondary = "Surprise Attack",
	ability1 = "Random Movement",
	ability2 = "Chaos Ability",
	ultimate = "Unpredictable"
}

function AbilitySystem.get_abilities(class_type, race)
	if not class_type or not race then
		return RANDOM_ABILITIES
	end
	
	local class_abilities = ABILITIES[class_type]
	if not class_abilities then
		return RANDOM_ABILITIES
	end
	
	return class_abilities[race] or RANDOM_ABILITIES
end

function AbilitySystem.get_all_classes()
	local classes = {}
	for class_name, _ in pairs(ABILITIES) do
		table.insert(classes, class_name)
	end
	return classes
end

function AbilitySystem.get_all_races()
	return {"human", "elf", "dwarf", "orc"}
end

return AbilitySystem
