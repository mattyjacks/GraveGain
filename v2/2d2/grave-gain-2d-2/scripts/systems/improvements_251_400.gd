# ===== IMPROVEMENTS #251-400: ENEMY AI & BEHAVIORS =====
# This file contains 150 enemy AI and behavior improvements for GraveGain

static func get_improvements() -> Dictionary:
	var imp: Dictionary = {}
	
	# #251-260: Enemy Awareness & Detection
	imp[251] = {"name": "Extended Vision Range", "desc": "Enemies can see 50% further"}
	imp[252] = {"name": "Peripheral Vision", "desc": "Enemies detect movement in peripheral vision"}
	imp[253] = {"name": "Sound Detection", "desc": "Enemies hear loud noises from further away"}
	imp[254] = {"name": "Smell Detection", "desc": "Enemies can smell player from 2x distance"}
	imp[255] = {"name": "Vibration Sensing", "desc": "Enemies sense vibrations through ground"}
	imp[256] = {"name": "Heat Sensing", "desc": "Enemies detect heat signatures"}
	imp[257] = {"name": "Magic Detection", "desc": "Enemies sense magical abilities being used"}
	imp[258] = {"name": "Aura Detection", "desc": "Enemies detect player auras"}
	imp[259] = {"name": "Telepathic Link", "desc": "Enemies share vision with nearby allies"}
	imp[260] = {"name": "Hive Mind", "desc": "All enemies of same type coordinate attacks"}
	
	# #261-270: Enemy Movement & Positioning
	imp[261] = {"name": "Flanking AI", "desc": "Enemies attempt to flank player"}
	imp[262] = {"name": "Kiting AI", "desc": "Ranged enemies maintain distance while attacking"}
	imp[263] = {"name": "Charging AI", "desc": "Melee enemies charge at player"}
	imp[264] = {"name": "Circling AI", "desc": "Enemies circle around player"}
	imp[265] = {"name": "Ambush AI", "desc": "Enemies set up ambushes in corridors"}
	imp[266] = {"name": "Retreat AI", "desc": "Enemies retreat when low on health"}
	imp[267] = {"name": "Grouping AI", "desc": "Enemies group together for strength"}
	imp[268] = {"name": "Spreading AI", "desc": "Enemies spread out to avoid AoE"}
	imp[269] = {"name": "High Ground AI", "desc": "Enemies seek high ground advantage"}
	imp[270] = {"name": "Cover AI", "desc": "Enemies use cover to reduce damage"}
	
	# #271-280: Enemy Combat Tactics
	imp[271] = {"name": "Combo Attacks", "desc": "Enemies perform attack combos"}
	imp[272] = {"name": "Ability Rotation", "desc": "Enemies rotate through abilities strategically"}
	imp[273] = {"name": "Interrupt Tactics", "desc": "Enemies interrupt player abilities"}
	imp[274] = {"name": "Crowd Control Tactics", "desc": "Enemies use crowd control strategically"}
	imp[275] = {"name": "Buff Stacking", "desc": "Enemies stack buffs before attacking"}
	imp[276] = {"name": "Debuff Application", "desc": "Enemies apply debuffs to weaken player"}
	imp[277] = {"name": "Defensive Stance", "desc": "Enemies take defensive stance when low health"}
	imp[278] = {"name": "Aggressive Stance", "desc": "Enemies become aggressive when player is weak"}
	imp[279] = {"name": "Tactical Retreat", "desc": "Enemies retreat to heal when needed"}
	imp[280] = {"name": "Coordinated Attacks", "desc": "Multiple enemies coordinate attacks on player"}
	
	# #281-290: Enemy Abilities & Powers
	imp[281] = {"name": "Ability Spam", "desc": "Enemies use abilities more frequently"}
	imp[282] = {"name": "Ability Chaining", "desc": "Enemies chain abilities together"}
	imp[283] = {"name": "Ability Overload", "desc": "Enemies overload abilities for increased effect"}
	imp[284] = {"name": "Spell Reflection", "desc": "Enemies reflect spells back at player"}
	imp[285] = {"name": "Spell Absorption", "desc": "Enemies absorb spells to heal"}
	imp[286] = {"name": "Spell Immunity", "desc": "Enemies gain temporary spell immunity"}
	imp[287] = {"name": "Ability Cooldown Reduction", "desc": "Enemies have reduced ability cooldowns"}
	imp[288] = {"name": "Ability Damage Increase", "desc": "Enemy abilities deal 50% more damage"}
	imp[289] = {"name": "Ability Range Increase", "desc": "Enemy abilities have 50% larger range"}
	imp[290] = {"name": "Ability AoE Increase", "desc": "Enemy abilities hit 50% larger area"}
	
	# #291-300: Enemy Resilience
	imp[291] = {"name": "Damage Reduction", "desc": "Enemies take 25% less damage"}
	imp[292] = {"name": "Armor Increase", "desc": "Enemies have 50% more armor"}
	imp[293] = {"name": "Resistance Increase", "desc": "Enemies have 50% more resistances"}
	imp[294] = {"name": "Health Regeneration", "desc": "Enemies regenerate 5% health per second"}
	imp[295] = {"name": "Damage Reflection", "desc": "Enemies reflect 10% of damage taken"}
	imp[296] = {"name": "Thorns", "desc": "Enemies deal damage when hit"}
	imp[297] = {"name": "Evasion Increase", "desc": "Enemies have 50% more evasion"}
	imp[298] = {"name": "Block Chance", "desc": "Enemies block 30% of attacks"}
	imp[299] = {"name": "Dodge Chance", "desc": "Enemies dodge 30% of attacks"}
	imp[300] = {"name": "Invulnerability Phases", "desc": "Enemies become invulnerable periodically"}
	
	# #301-310: Enemy Aggression & Behavior
	imp[301] = {"name": "Increased Aggression", "desc": "Enemies are 50% more aggressive"}
	imp[302] = {"name": "Relentless Pursuit", "desc": "Enemies pursue player indefinitely"}
	imp[303] = {"name": "Berserk Mode", "desc": "Enemies enter berserk when low health"}
	imp[304] = {"name": "Desperation Attacks", "desc": "Desperate enemies use powerful attacks"}
	imp[305] = {"name": "Vengeance Mode", "desc": "Enemies become stronger after taking damage"}
	imp[306] = {"name": "Feeding Frenzy", "desc": "Enemies become stronger after kills"}
	imp[307] = {"name": "Pack Mentality", "desc": "Enemies stronger when grouped"}
	imp[308] = {"name": "Territorial Behavior", "desc": "Enemies defend territory aggressively"}
	imp[309] = {"name": "Hunting Behavior", "desc": "Enemies hunt player like prey"}
	imp[310] = {"name": "Predatory Instinct", "desc": "Enemies target weak players first"}
	
	# #311-320: Enemy Adaptation
	imp[311] = {"name": "Damage Type Adaptation", "desc": "Enemies adapt to damage types used"}
	imp[312] = {"name": "Ability Adaptation", "desc": "Enemies adapt to abilities used"}
	imp[313] = {"name": "Playstyle Adaptation", "desc": "Enemies adapt to player playstyle"}
	imp[314] = {"name": "Weakness Learning", "desc": "Enemies learn player weaknesses"}
	imp[315] = {"name": "Strategy Learning", "desc": "Enemies learn from previous encounters"}
	imp[316] = {"name": "Resistance Building", "desc": "Enemies build resistance to repeated damage"}
	imp[317] = {"name": "Counter Strategy", "desc": "Enemies develop counters to player tactics"}
	imp[318] = {"name": "Tactical Evolution", "desc": "Enemies evolve tactics during combat"}
	imp[319] = {"name": "Intelligent Retreat", "desc": "Enemies retreat when outmatched"}
	imp[320] = {"name": "Calculated Risk", "desc": "Enemies take calculated risks"}
	
	# #321-330: Enemy Spawning & Scaling
	imp[321] = {"name": "Increased Spawn Rate", "desc": "Enemies spawn 50% more frequently"}
	imp[322] = {"name": "Spawn Waves", "desc": "Enemies spawn in coordinated waves"}
	imp[323] = {"name": "Elite Spawning", "desc": "Elite enemies spawn more frequently"}
	imp[324] = {"name": "Boss Spawning", "desc": "Boss enemies spawn more frequently"}
	imp[325] = {"name": "Reinforcement Spawning", "desc": "Enemies call for reinforcements"}
	imp[326] = {"name": "Level Scaling", "desc": "Enemies scale with player level"}
	imp[327] = {"name": "Difficulty Scaling", "desc": "Enemies scale with difficulty"}
	imp[328] = {"name": "Stat Scaling", "desc": "Enemy stats scale 50% better"}
	imp[329] = {"name": "Ability Scaling", "desc": "Enemy abilities scale with level"}
	imp[330] = {"name": "Loot Scaling", "desc": "Enemy loot scales with level"}
	
	# #331-340: Enemy Synergies
	imp[331] = {"name": "Type Synergy", "desc": "Same enemy types gain bonuses together"}
	imp[332] = {"name": "Damage Synergy", "desc": "Enemies amplify each other's damage"}
	imp[333] = {"name": "Defense Synergy", "desc": "Enemies amplify each other's defense"}
	imp[334] = {"name": "Ability Synergy", "desc": "Enemies combine abilities for effects"}
	imp[335] = {"name": "Buff Sharing", "desc": "Enemies share buffs with allies"}
	imp[336] = {"name": "Healing Synergy", "desc": "Enemies heal each other"}
	imp[337] = {"name": "Damage Sharing", "desc": "Enemies share damage taken"}
	imp[338] = {"name": "Resurrection Synergy", "desc": "Enemies resurrect fallen allies"}
	imp[339] = {"name": "Empowerment Aura", "desc": "Enemies empower nearby allies"}
	imp[340] = {"name": "Corruption Aura", "desc": "Enemies corrupt nearby allies with power"}
	
	# #341-350: Enemy Special Mechanics
	imp[341] = {"name": "Shield Mechanics", "desc": "Enemies have shields that regenerate"}
	imp[342] = {"name": "Armor Mechanics", "desc": "Enemies have layered armor"}
	imp[343] = {"name": "Phase Mechanics", "desc": "Enemies phase between dimensions"}
	imp[344] = {"name": "Splitting Mechanics", "desc": "Enemies split into smaller versions"}
	imp[345] = {"name": "Merging Mechanics", "desc": "Enemies merge into stronger forms"}
	imp[346] = {"name": "Transformation Mechanics", "desc": "Enemies transform when low health"}
	imp[347] = {"name": "Possession Mechanics", "desc": "Enemies possess other enemies"}
	imp[348] = {"name": "Cloning Mechanics", "desc": "Enemies create clones of themselves"}
	imp[349] = {"name": "Summoning Mechanics", "desc": "Enemies summon minions"}
	imp[350] = {"name": "Corruption Mechanics", "desc": "Enemies corrupt the environment"}
	
	# #351-360: Enemy Weaknesses & Vulnerabilities
	imp[351] = {"name": "Elemental Weakness", "desc": "Enemies have elemental weaknesses"}
	imp[352] = {"name": "Type Weakness", "desc": "Enemies weak to certain damage types"}
	imp[353] = {"name": "Status Weakness", "desc": "Enemies vulnerable to status effects"}
	imp[354] = {"name": "Ability Weakness", "desc": "Enemies weak to certain abilities"}
	imp[355] = {"name": "Playstyle Weakness", "desc": "Enemies weak to certain playstyles"}
	imp[356] = {"name": "Positional Weakness", "desc": "Enemies weak from certain positions"}
	imp[357] = {"name": "Timing Weakness", "desc": "Enemies vulnerable at certain times"}
	imp[358] = {"name": "Resource Weakness", "desc": "Enemies weak when low on resources"}
	imp[359] = {"name": "Isolated Weakness", "desc": "Enemies weak when isolated"}
	imp[360] = {"name": "Outnumbered Weakness", "desc": "Enemies weak when outnumbered"}
	
	# #361-370: Enemy Loot & Rewards
	imp[361] = {"name": "Increased Loot Drop", "desc": "Enemies drop 50% more loot"}
	imp[362] = {"name": "Rare Loot Increase", "desc": "Enemies drop 50% more rare loot"}
	imp[363] = {"name": "Gold Drop Increase", "desc": "Enemies drop 50% more gold"}
	imp[364] = {"name": "XP Drop Increase", "desc": "Enemies give 50% more XP"}
	imp[365] = {"name": "Artifact Drops", "desc": "Enemies drop artifacts"}
	imp[366] = {"name": "Unique Drops", "desc": "Enemies drop unique items"}
	imp[367] = {"name": "Crafting Material Drops", "desc": "Enemies drop crafting materials"}
	imp[368] = {"name": "Currency Drops", "desc": "Enemies drop special currency"}
	imp[369] = {"name": "Consumable Drops", "desc": "Enemies drop consumables"}
	imp[370] = {"name": "Buff Drops", "desc": "Enemies drop temporary buffs"}
	
	# #371-380: Enemy Difficulty Modifiers
	imp[371] = {"name": "Damage Multiplier", "desc": "Enemy damage multiplied by 1.5x"}
	imp[372] = {"name": "Health Multiplier", "desc": "Enemy health multiplied by 1.5x"}
	imp[373] = {"name": "Speed Multiplier", "desc": "Enemy speed multiplied by 1.5x"}
	imp[374] = {"name": "Ability Frequency", "desc": "Enemies use abilities 50% more often"}
	imp[375] = {"name": "Attack Frequency", "desc": "Enemies attack 50% more often"}
	imp[376] = {"name": "Spawn Frequency", "desc": "Enemies spawn 50% more often"}
	imp[377] = {"name": "Reinforcement Frequency", "desc": "Enemies call reinforcements more often"}
	imp[378] = {"name": "Buff Frequency", "desc": "Enemies buff themselves more often"}
	imp[379] = {"name": "Debuff Frequency", "desc": "Enemies debuff player more often"}
	imp[380] = {"name": "Crowd Control Frequency", "desc": "Enemies use crowd control more often"}
	
	# #381-390: Enemy Coordination
	imp[381] = {"name": "Coordinated Attacks", "desc": "Enemies coordinate attacks perfectly"}
	imp[382] = {"name": "Synchronized Abilities", "desc": "Enemies synchronize ability usage"}
	imp[383] = {"name": "Formation Fighting", "desc": "Enemies maintain tactical formations"}
	imp[384] = {"name": "Pincer Movement", "desc": "Enemies execute pincer movements"}
	imp[385] = {"name": "Encirclement", "desc": "Enemies attempt to encircle player"}
	imp[386] = {"name": "Distraction Tactics", "desc": "Enemies distract while others attack"}
	imp[387] = {"name": "Support Tactics", "desc": "Enemies support each other in combat"}
	imp[388] = {"name": "Sacrifice Tactics", "desc": "Enemies sacrifice themselves for advantage"}
	imp[389] = {"name": "Bait Tactics", "desc": "Enemies use bait to lure player"}
	imp[390] = {"name": "Trap Tactics", "desc": "Enemies set traps for player"}
	
	# #391-400: Advanced Enemy Mechanics
	imp[391] = {"name": "Mutation System", "desc": "Enemies mutate and evolve during combat"}
	imp[392] = {"name": "Evolution System", "desc": "Enemies evolve into stronger forms"}
	imp[393] = {"name": "Corruption System", "desc": "Enemies corrupt each other for power"}
	imp[394] = {"name": "Fusion System", "desc": "Enemies fuse into mega enemies"}
	imp[395] = {"name": "Parasitic System", "desc": "Enemies parasitize each other"}
	imp[396] = {"name": "Symbiosis System", "desc": "Enemies form symbiotic bonds"}
	imp[397] = {"name": "Hivemind System", "desc": "Enemies form collective hivemind"}
	imp[398] = {"name": "Consciousness Transfer", "desc": "Enemies transfer consciousness between bodies"}
	imp[399] = {"name": "Dimensional Anchoring", "desc": "Enemies anchor to dimensions for power"}
	imp[400] = {"name": "Reality Warping", "desc": "Enemies warp reality around them"}
	
	return imp
