# ===== IMPROVEMENTS #101-250: COMBAT & BALANCE =====
# This file contains 150 combat and balance improvements for GraveGain

static func get_improvements() -> Dictionary:
	var imp: Dictionary = {}
	
	# #101-110: Melee Combat Enhancements
	imp[101] = {"name": "Blade Ricochet", "desc": "Melee attacks can ricochet off walls, hitting enemies behind obstacles"}
	imp[102] = {"name": "Momentum Stacking", "desc": "Consecutive hits without dodging increase damage by 2% per hit (max 20%)"}
	imp[103] = {"name": "Parry Counter", "desc": "Perfect parry within 0.15s triggers automatic counter-attack"}
	imp[104] = {"name": "Cleave Strike", "desc": "Heavy attacks hit all enemies in a cone in front of player"}
	imp[105] = {"name": "Blade Dance", "desc": "Dodge into enemy triggers spinning slash hitting nearby foes"}
	imp[106] = {"name": "Executioner's Edge", "desc": "Attacks on enemies below 25% HP deal 50% more damage"}
	imp[107] = {"name": "Whirlwind Attack", "desc": "Hold attack button for 1s to spin, hitting all surrounding enemies"}
	imp[108] = {"name": "Armor Shatter", "desc": "Consecutive hits on same enemy reduce their armor by 5% (max 50%)"}
	imp[109] = {"name": "Lifesteal Blade", "desc": "Melee attacks restore 10% of damage dealt as health"}
	imp[110] = {"name": "Resonant Strike", "desc": "Hitting same enemy 3x in a row triggers shockwave"}
	
	# #111-120: Ranged Combat Enhancements
	imp[111] = {"name": "Piercing Shot", "desc": "Arrows pass through multiple enemies, damage reduced by 20% per target"}
	imp[112] = {"name": "Explosive Arrows", "desc": "Arrows explode on impact, hitting nearby enemies"}
	imp[113] = {"name": "Homing Projectiles", "desc": "Projectiles slightly curve toward nearest enemy"}
	imp[114] = {"name": "Rapid Fire", "desc": "Hold ranged attack to fire continuously (reduced damage per shot)"}
	imp[115] = {"name": "Ricochet Shots", "desc": "Arrows bounce off walls up to 3 times"}
	imp[116] = {"name": "Charged Shot", "desc": "Hold ranged attack for 1s to charge, dealing 2x damage"}
	imp[117] = {"name": "Spread Shot", "desc": "Fire 3 arrows in a spread pattern"}
	imp[118] = {"name": "Poison Arrows", "desc": "Arrows apply poison, dealing damage over 5 seconds"}
	imp[119] = {"name": "Frost Arrows", "desc": "Arrows slow enemies by 50% for 3 seconds"}
	imp[120] = {"name": "Snapshot Accuracy", "desc": "First shot after standing still for 1s deals 50% more damage"}
	
	# #121-130: Ability Enhancements
	imp[121] = {"name": "Ability Chaining", "desc": "Using ability within 2s of another ability costs 25% less mana"}
	imp[122] = {"name": "Cooldown Reduction", "desc": "Kill streaks reduce ability cooldowns by 5% per streak level"}
	imp[123] = {"name": "Ability Overcharge", "desc": "Use ability twice in a row to overcharge, dealing 50% more damage"}
	imp[124] = {"name": "Mana Battery", "desc": "Melee kills restore 20% mana"}
	imp[125] = {"name": "Spell Echo", "desc": "Abilities have 20% chance to trigger again for free"}
	imp[126] = {"name": "Ability Cascade", "desc": "Killing enemy with ability reduces cooldown by 50%"}
	imp[127] = {"name": "Mana Shield", "desc": "Spend mana to block damage (1 mana = 1 damage blocked)"}
	imp[128] = {"name": "Ability Amplification", "desc": "Each ability cast increases next ability damage by 10% (max 50%)"}
	imp[129] = {"name": "Spell Reflection", "desc": "Abilities reflect off enemies, hitting enemies behind them"}
	imp[130] = {"name": "Mana Efficiency", "desc": "Abilities cost 10% less mana for each enemy killed recently"}
	
	# #131-140: Defense Enhancements
	imp[131] = {"name": "Damage Reduction Stacking", "desc": "Each block increases damage reduction by 5% (max 40%, resets after 3s)"}
	imp[132] = {"name": "Reflect Damage", "desc": "10% of blocked damage reflects back to attacker"}
	imp[133] = {"name": "Fortified Stance", "desc": "Standing still increases armor by 20%"}
	imp[134] = {"name": "Evasion Mastery", "desc": "Dodge chance increases by 1% for each enemy nearby (max 30%)"}
	imp[135] = {"name": "Counter Attack", "desc": "Perfect dodge triggers automatic counter-attack"}
	imp[136] = {"name": "Damage Threshold", "desc": "Damage below 10% of max HP is reduced by 50%"}
	imp[137] = {"name": "Invincibility Frames", "desc": "Dodge grants 0.5s of invincibility"}
	imp[138] = {"name": "Shield Bash", "desc": "Block and press attack to stun nearby enemies"}
	imp[139] = {"name": "Fortify", "desc": "Activate ability to gain 50% damage reduction for 3s"}
	imp[140] = {"name": "Damage Conversion", "desc": "Convert 20% of damage taken into temporary shield"}
	
	# #141-150: Status Effects & Debuffs
	imp[141] = {"name": "Poison Mastery", "desc": "Poison damage increased by 50%, duration extended to 8s"}
	imp[142] = {"name": "Burn Mastery", "desc": "Burning enemies take 25% more damage from all sources"}
	imp[143] = {"name": "Freeze Mastery", "desc": "Frozen enemies take 50% more damage from melee attacks"}
	imp[144] = {"name": "Stun Mastery", "desc": "Stunned enemies drop 50% more loot"}
	imp[145] = {"name": "Bleed Stacking", "desc": "Bleed effects stack, each stack deals 5% more damage"}
	imp[146] = {"name": "Status Effect Duration", "desc": "All status effects last 25% longer"}
	imp[147] = {"name": "Weakness Amplification", "desc": "Weakened enemies take 30% more damage"}
	imp[148] = {"name": "Vulnerability Stacking", "desc": "Vulnerable enemies take 5% more damage per vulnerability stack"}
	imp[149] = {"name": "Curse Mastery", "desc": "Cursed enemies deal 30% less damage"}
	imp[150] = {"name": "Status Immunity Reduction", "desc": "Enemies have 50% less status effect resistance"}
	
	# #151-160: Critical Strike Enhancements
	imp[151] = {"name": "Critical Cascade", "desc": "Critical hits increase crit chance by 5% for 5s (stacks)"}
	imp[152] = {"name": "Crit Damage Scaling", "desc": "Crit damage increases by 1% for each 1% crit chance"}
	imp[153] = {"name": "Guaranteed Crit", "desc": "Every 5th attack is guaranteed crit"}
	imp[154] = {"name": "Crit Heal", "desc": "Critical hits restore 15% of damage as health"}
	imp[155] = {"name": "Crit Cooldown Reduction", "desc": "Critical hits reduce ability cooldowns by 2s"}
	imp[156] = {"name": "Crit Mana Restore", "desc": "Critical hits restore 10 mana"}
	imp[157] = {"name": "Crit Knockback", "desc": "Critical hits knock enemies back"}
	imp[158] = {"name": "Crit Stun", "desc": "Critical hits have 30% chance to stun"}
	imp[159] = {"name": "Crit Bleed", "desc": "Critical hits apply bleed effect"}
	imp[160] = {"name": "Crit Amplification", "desc": "Each critical hit increases next crit damage by 10%"}
	
	# #161-170: Combo System Enhancements
	imp[161] = {"name": "Combo Multiplier", "desc": "Combo damage multiplier increased from 50% to 75%"}
	imp[162] = {"name": "Combo Duration Extension", "desc": "Combo timer extended from 5s to 7s"}
	imp[163] = {"name": "Combo Finisher", "desc": "Completing 10-hit combo triggers massive finisher attack"}
	imp[164] = {"name": "Combo Healing", "desc": "Each combo hit restores 2% max health"}
	imp[165] = {"name": "Combo Mana", "desc": "Each combo hit restores 5 mana"}
	imp[166] = {"name": "Combo Cooldown", "desc": "Combo hits reduce ability cooldowns by 1s"}
	imp[167] = {"name": "Combo Momentum", "desc": "Combo multiplier increases by 5% per hit instead of 3%"}
	imp[168] = {"name": "Combo Knockback", "desc": "Combo hits knock enemies back slightly"}
	imp[169] = {"name": "Combo Stun", "desc": "10-hit combo stuns all nearby enemies"}
	imp[170] = {"name": "Combo Explosion", "desc": "Combo finisher creates explosion hitting nearby enemies"}
	
	# #171-180: Damage Type Scaling
	imp[171] = {"name": "Physical Damage Scaling", "desc": "Physical damage scales 50% better with strength"}
	imp[172] = {"name": "Magical Damage Scaling", "desc": "Magical damage scales 50% better with intelligence"}
	imp[173] = {"name": "Fire Damage Scaling", "desc": "Fire damage increased by 25%"}
	imp[174] = {"name": "Ice Damage Scaling", "desc": "Ice damage increased by 25%"}
	imp[175] = {"name": "Lightning Damage Scaling", "desc": "Lightning damage increased by 25%"}
	imp[176] = {"name": "Poison Damage Scaling", "desc": "Poison damage increased by 25%"}
	imp[177] = {"name": "Holy Damage Scaling", "desc": "Holy damage increased by 25%, extra effective vs undead"}
	imp[178] = {"name": "Dark Damage Scaling", "desc": "Dark damage increased by 25%, extra effective vs living"}
	imp[179] = {"name": "Elemental Synergy", "desc": "Using 2 different elements increases both by 15%"}
	imp[180] = {"name": "Damage Type Resistance Reduction", "desc": "Enemies have 25% less resistance to damage types"}
	
	# #181-190: Aggression & Risk/Reward
	imp[181] = {"name": "Berserk Mode", "desc": "Low health increases damage by 50% but reduces defense by 25%"}
	imp[182] = {"name": "Glass Cannon", "desc": "Reduce armor by 50% to increase damage by 100%"}
	imp[183] = {"name": "High Risk High Reward", "desc": "Damage taken increases damage dealt by 1% per 1% health lost"}
	imp[184] = {"name": "Aggressive Healing", "desc": "Attacking heals 5% of damage dealt"}
	imp[185] = {"name": "Momentum Damage", "desc": "Moving faster increases damage by up to 50%"}
	imp[186] = {"name": "Stationary Damage", "desc": "Standing still increases damage by up to 50%"}
	imp[187] = {"name": "Close Range Damage", "desc": "Damage increases by 50% when close to enemies"}
	imp[188] = {"name": "Long Range Damage", "desc": "Damage increases by 50% when far from enemies"}
	imp[189] = {"name": "Outnumbered Strength", "desc": "Damage increases by 5% for each nearby enemy (max 50%)"}
	imp[190] = {"name": "Solo Power", "desc": "Damage increases by 50% when no allies nearby"}
	
	# #191-200: Balance & Scaling
	imp[191] = {"name": "Level Scaling", "desc": "Damage scales 5% better per level"}
	imp[192] = {"name": "Gear Scaling", "desc": "Damage scales 10% better with equipped items"}
	imp[193] = {"name": "Stat Scaling", "desc": "All stats scale 25% better with level"}
	imp[194] = {"name": "Enemy Scaling", "desc": "Enemies scale 50% better with difficulty"}
	imp[195] = {"name": "Loot Scaling", "desc": "Loot quality scales 25% better with level"}
	imp[196] = {"name": "XP Scaling", "desc": "XP gains scale 50% better with difficulty"}
	imp[197] = {"name": "Health Scaling", "desc": "Max health increases 10% per level"}
	imp[198] = {"name": "Mana Scaling", "desc": "Max mana increases 10% per level"}
	imp[199] = {"name": "Stamina Scaling", "desc": "Max stamina increases 10% per level"}
	imp[200] = {"name": "Armor Scaling", "desc": "Armor increases 5% per level"}
	
	# #201-210: Crowd Control
	imp[201] = {"name": "Stun Duration", "desc": "Stun effects last 25% longer"}
	imp[202] = {"name": "Knockback Distance", "desc": "Knockback distance increased by 50%"}
	imp[203] = {"name": "Slow Duration", "desc": "Slow effects last 25% longer"}
	imp[204] = {"name": "Root Duration", "desc": "Root effects last 25% longer"}
	imp[205] = {"name": "Crowd Control Immunity", "desc": "Reduce crowd control duration by 25%"}
	imp[206] = {"name": "Crowd Control Resistance", "desc": "Enemies have 50% less crowd control resistance"}
	imp[207] = {"name": "Stun Chain", "desc": "Stunning one enemy stuns nearby enemies for 50% duration"}
	imp[208] = {"name": "Knockback Chain", "desc": "Knocking back one enemy knocks back nearby enemies"}
	imp[209] = {"name": "Crowd Control Amplification", "desc": "Each crowd control effect increases next one by 25%"}
	imp[210] = {"name": "Crowd Control Damage", "desc": "Crowd controlled enemies take 50% more damage"}
	
	# #211-220: Resource Management
	imp[211] = {"name": "Mana Regeneration Increase", "desc": "Mana regen increased by 50%"}
	imp[212] = {"name": "Stamina Regeneration Increase", "desc": "Stamina regen increased by 50%"}
	imp[213] = {"name": "Health Regeneration Increase", "desc": "Health regen increased by 50%"}
	imp[214] = {"name": "Resource Efficiency", "desc": "All abilities cost 20% less resources"}
	imp[215] = {"name": "Resource Restoration", "desc": "Killing enemies restores 25% of all resources"}
	imp[216] = {"name": "Resource Pooling", "desc": "Unused mana converts to stamina and vice versa"}
	imp[217] = {"name": "Mana Battery Upgrade", "desc": "Melee kills restore 50% mana instead of 20%"}
	imp[218] = {"name": "Stamina Battery", "desc": "Ranged kills restore 50% stamina"}
	imp[219] = {"name": "Health Battery", "desc": "Ability kills restore 50% health"}
	imp[220] = {"name": "Resource Overflow", "desc": "Excess resources convert to temporary damage boost"}
	
	# #221-230: Passive Bonuses
	imp[221] = {"name": "Passive Damage", "desc": "Gain 5% passive damage increase"}
	imp[222] = {"name": "Passive Defense", "desc": "Gain 5% passive damage reduction"}
	imp[223] = {"name": "Passive Speed", "desc": "Gain 10% movement speed increase"}
	imp[224] = {"name": "Passive Attack Speed", "desc": "Gain 10% attack speed increase"}
	imp[225] = {"name": "Passive Crit Chance", "desc": "Gain 5% crit chance"}
	imp[226] = {"name": "Passive Dodge Chance", "desc": "Gain 5% dodge chance"}
	imp[227] = {"name": "Passive Armor", "desc": "Gain 10% armor"}
	imp[228] = {"name": "Passive Health", "desc": "Gain 10% max health"}
	imp[229] = {"name": "Passive Mana", "desc": "Gain 10% max mana"}
	imp[230] = {"name": "Passive Stamina", "desc": "Gain 10% max stamina"}
	
	# #231-240: Special Effects
	imp[231] = {"name": "Elemental Aura", "desc": "Gain aura that damages nearby enemies"}
	imp[232] = {"name": "Thorns", "desc": "Enemies take damage when hitting you"}
	imp[233] = {"name": "Life Steal Aura", "desc": "Nearby allies gain 5% lifesteal"}
	imp[234] = {"name": "Damage Aura", "desc": "Nearby allies gain 10% damage increase"}
	imp[235] = {"name": "Defense Aura", "desc": "Nearby allies gain 10% damage reduction"}
	imp[236] = {"name": "Speed Aura", "desc": "Nearby allies gain 10% movement speed"}
	imp[237] = {"name": "Healing Aura", "desc": "Nearby allies heal 2% max health per second"}
	imp[238] = {"name": "Mana Aura", "desc": "Nearby allies restore 5 mana per second"}
	imp[239] = {"name": "Stamina Aura", "desc": "Nearby allies restore 5 stamina per second"}
	imp[240] = {"name": "Blessing Aura", "desc": "Nearby allies gain random buff every 5 seconds"}
	
	# #241-250: Advanced Mechanics
	imp[241] = {"name": "Damage Amplification Chain", "desc": "Each hit increases next hit damage by 5% (max 50%)"}
	imp[242] = {"name": "Vulnerability Stacking", "desc": "Enemies take 2% more damage per hit (max 50%)"}
	imp[243] = {"name": "Armor Penetration", "desc": "Ignore 25% of enemy armor"}
	imp[244] = {"name": "Resistance Penetration", "desc": "Ignore 25% of enemy resistances"}
	imp[245] = {"name": "Evasion Penetration", "desc": "Your attacks ignore 25% of enemy evasion"}
	imp[246] = {"name": "Block Penetration", "desc": "Your attacks ignore 25% of enemy block chance"}
	imp[247] = {"name": "Damage Conversion", "desc": "Convert 10% of damage taken to temporary damage boost"}
	imp[248] = {"name": "Damage Reflection", "desc": "Reflect 10% of damage taken back to attacker"}
	imp[249] = {"name": "Damage Absorption", "desc": "Absorb 10% of damage dealt as shield"}
	imp[250] = {"name": "Damage Redistribution", "desc": "Damage to one enemy damages all nearby enemies by 25%"}
	
	return imp
