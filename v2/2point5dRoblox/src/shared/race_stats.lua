local RaceStats = {}

RaceStats.RACES = {
	Human = {
		name = "Human",
		hp = 100,
		regenRate = 1,
		shieldMax = 50,
		shieldRegenRate = 2,
		shieldRegenDelay = 5,
		hasShield = true,
		hasRage = false,
		hasMana = false,
		scale = Vector3.new(1, 1, 1),
		color = Color3.fromRGB(200, 180, 150),
		description = "Balanced stats with shield regeneration"
	},
	Orc = {
		name = "Orc",
		hp = 200,
		regenRate = 3,
		shieldMax = 0,
		shieldRegenRate = 0,
		shieldRegenDelay = 0,
		hasShield = false,
		hasRage = true,
		hasMana = false,
		scale = Vector3.new(1.2, 1.3, 1.2),
		color = Color3.fromRGB(100, 180, 100),
		description = "High HP, Rage mechanic for burst damage"
	},
	Dwarf = {
		name = "Dwarf",
		hp = 150,
		regenRate = 2,
		shieldMax = 0,
		shieldRegenRate = 0,
		shieldRegenDelay = 0,
		hasShield = false,
		hasRage = false,
		hasMana = false,
		scale = Vector3.new(0.9, 0.7, 0.9),
		color = Color3.fromRGB(180, 140, 80),
		description = "Sturdy with Darkvision ability"
	},
	Elf = {
		name = "Elf",
		hp = 75,
		regenRate = 3,
		shieldMax = 0,
		shieldRegenRate = 0,
		shieldRegenDelay = 0,
		hasShield = false,
		hasRage = false,
		hasMana = true,
		scale = Vector3.new(0.85, 0.95, 0.85),
		color = Color3.fromRGB(100, 200, 100),
		description = "Fast regen with Mana-based abilities"
	}
}

function RaceStats.getRaceStats(raceName)
	return RaceStats.RACES[raceName]
end

function RaceStats.getAllRaces()
	local races = {}
	for name, stats in pairs(RaceStats.RACES) do
		table.insert(races, stats)
	end
	return races
end

return RaceStats
