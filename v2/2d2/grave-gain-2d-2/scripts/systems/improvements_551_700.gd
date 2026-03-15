# ===== IMPROVEMENTS #551-700: MAP GENERATION & DUNGEONS =====
# This file contains 150 map generation and dungeon improvements for GraveGain

static func get_improvements() -> Dictionary:
	var imp: Dictionary = {}
	
	# #551-560: Room Generation
	imp[551] = {"name": "Room Variety", "desc": "Increased variety in room layouts"}
	imp[552] = {"name": "Room Complexity", "desc": "Rooms have more complex layouts"}
	imp[553] = {"name": "Room Decoration", "desc": "Rooms decorated with more details"}
	imp[554] = {"name": "Room Theming", "desc": "Rooms have distinct themes"}
	imp[555] = {"name": "Room Scaling", "desc": "Rooms scale with difficulty"}
	imp[556] = {"name": "Room Density", "desc": "Rooms have more content"}
	imp[557] = {"name": "Room Connections", "desc": "Rooms connect in interesting ways"}
	imp[558] = {"name": "Room Secrets", "desc": "Rooms contain more secrets"}
	imp[559] = {"name": "Room Hazards", "desc": "Rooms contain environmental hazards"}
	imp[560] = {"name": "Room Treasures", "desc": "Rooms contain treasure caches"}
	
	# #561-570: Corridor Generation
	imp[561] = {"name": "Corridor Variety", "desc": "Corridors have varied designs"}
	imp[562] = {"name": "Corridor Complexity", "desc": "Corridors have complex layouts"}
	imp[563] = {"name": "Corridor Decoration", "desc": "Corridors decorated with details"}
	imp[564] = {"name": "Corridor Ambushes", "desc": "Corridors contain ambush points"}
	imp[565] = {"name": "Corridor Hazards", "desc": "Corridors contain hazards"}
	imp[566] = {"name": "Corridor Secrets", "desc": "Corridors contain secrets"}
	imp[567] = {"name": "Corridor Treasures", "desc": "Corridors contain treasures"}
	imp[568] = {"name": "Corridor Traps", "desc": "Corridors contain traps"}
	imp[569] = {"name": "Corridor Lighting", "desc": "Corridors have dynamic lighting"}
	imp[570] = {"name": "Corridor Atmosphere", "desc": "Corridors have atmospheric effects"}
	
	# #571-580: Dungeon Themes
	imp[571] = {"name": "Crypt Theme", "desc": "Dungeons can be crypts"}
	imp[572] = {"name": "Castle Theme", "desc": "Dungeons can be castles"}
	imp[573] = {"name": "Cave Theme", "desc": "Dungeons can be caves"}
	imp[574] = {"name": "Temple Theme", "desc": "Dungeons can be temples"}
	imp[575] = {"name": "Laboratory Theme", "desc": "Dungeons can be laboratories"}
	imp[576] = {"name": "Prison Theme", "desc": "Dungeons can be prisons"}
	imp[577] = {"name": "Mansion Theme", "desc": "Dungeons can be mansions"}
	imp[578] = {"name": "Sewers Theme", "desc": "Dungeons can be sewers"}
	imp[579] = {"name": "Mines Theme", "desc": "Dungeons can be mines"}
	imp[580] = {"name": "Forest Theme", "desc": "Dungeons can be forests"}
	
	# #581-590: Dungeon Features
	imp[581] = {"name": "Lava Pits", "desc": "Dungeons contain lava pits"}
	imp[582] = {"name": "Water Features", "desc": "Dungeons contain water features"}
	imp[583] = {"name": "Bridges", "desc": "Dungeons contain bridges"}
	imp[584] = {"name": "Platforms", "desc": "Dungeons contain platforms"}
	imp[585] = {"name": "Pillars", "desc": "Dungeons contain pillars"}
	imp[586] = {"name": "Statues", "desc": "Dungeons contain statues"}
	imp[587] = {"name": "Altars", "desc": "Dungeons contain altars"}
	imp[588] = {"name": "Fountains", "desc": "Dungeons contain fountains"}
	imp[589] = {"name": "Doors", "desc": "Dungeons contain locked doors"}
	imp[590] = {"name": "Gates", "desc": "Dungeons contain gates"}
	
	# #591-600: Environmental Hazards
	imp[591] = {"name": "Spike Traps", "desc": "Dungeons contain spike traps"}
	imp[592] = {"name": "Poison Gas", "desc": "Dungeons contain poison gas"}
	imp[593] = {"name": "Fire Traps", "desc": "Dungeons contain fire traps"}
	imp[594] = {"name": "Ice Traps", "desc": "Dungeons contain ice traps"}
	imp[595] = {"name": "Lightning Traps", "desc": "Dungeons contain lightning traps"}
	imp[596] = {"name": "Falling Objects", "desc": "Dungeons have falling objects"}
	imp[597] = {"name": "Crumbling Floors", "desc": "Dungeons have crumbling floors"}
	imp[598] = {"name": "Collapsing Ceilings", "desc": "Dungeons have collapsing ceilings"}
	imp[599] = {"name": "Moving Walls", "desc": "Dungeons have moving walls"}
	imp[600] = {"name": "Rotating Platforms", "desc": "Dungeons have rotating platforms"}
	
	# #601-610: Secret Areas
	imp[601] = {"name": "Hidden Rooms", "desc": "Dungeons contain hidden rooms"}
	imp[602] = {"name": "Secret Passages", "desc": "Dungeons contain secret passages"}
	imp[603] = {"name": "Hidden Treasures", "desc": "Dungeons contain hidden treasures"}
	imp[604] = {"name": "Secret Doors", "desc": "Dungeons contain secret doors"}
	imp[605] = {"name": "Hidden Switches", "desc": "Dungeons contain hidden switches"}
	imp[606] = {"name": "Concealed Chests", "desc": "Dungeons contain concealed chests"}
	imp[607] = {"name": "Hidden Altars", "desc": "Dungeons contain hidden altars"}
	imp[608] = {"name": "Secret Shrines", "desc": "Dungeons contain secret shrines"}
	imp[609] = {"name": "Hidden Vaults", "desc": "Dungeons contain hidden vaults"}
	imp[610] = {"name": "Secret Chambers", "desc": "Dungeons contain secret chambers"}
	
	# #611-620: Boss Arenas
	imp[611] = {"name": "Boss Arena Design", "desc": "Boss arenas have unique designs"}
	imp[612] = {"name": "Boss Arena Hazards", "desc": "Boss arenas contain hazards"}
	imp[613] = {"name": "Boss Arena Mechanics", "desc": "Boss arenas have special mechanics"}
	imp[614] = {"name": "Boss Arena Scaling", "desc": "Boss arenas scale with difficulty"}
	imp[615] = {"name": "Boss Arena Phases", "desc": "Boss arenas change during fight"}
	imp[616] = {"name": "Boss Arena Minions", "desc": "Boss arenas spawn minions"}
	imp[617] = {"name": "Boss Arena Traps", "desc": "Boss arenas contain traps"}
	imp[618] = {"name": "Boss Arena Pillars", "desc": "Boss arenas have destructible pillars"}
	imp[619] = {"name": "Boss Arena Platforms", "desc": "Boss arenas have moving platforms"}
	imp[620] = {"name": "Boss Arena Atmosphere", "desc": "Boss arenas have atmospheric effects"}
	
	# #621-630: Procedural Generation
	imp[621] = {"name": "Seed-Based Generation", "desc": "Dungeons generated from seeds"}
	imp[622] = {"name": "Perlin Noise Generation", "desc": "Use Perlin noise for generation"}
	imp[623] = {"name": "Cellular Automata", "desc": "Use cellular automata for caves"}
	imp[624] = {"name": "Recursive Generation", "desc": "Recursive dungeon generation"}
	imp[625] = {"name": "Constraint-Based Generation", "desc": "Generate with constraints"}
	imp[626] = {"name": "Graph-Based Generation", "desc": "Generate using graphs"}
	imp[627] = {"name": "Template-Based Generation", "desc": "Generate from templates"}
	imp[628] = {"name": "Hybrid Generation", "desc": "Combine multiple generation methods"}
	imp[629] = {"name": "Adaptive Generation", "desc": "Generation adapts to player"}
	imp[630] = {"name": "Dynamic Generation", "desc": "Dungeons generate dynamically"}
	
	# #631-640: Dungeon Difficulty
	imp[631] = {"name": "Difficulty Scaling", "desc": "Dungeons scale with difficulty"}
	imp[632] = {"name": "Enemy Density Scaling", "desc": "Enemy density scales with difficulty"}
	imp[633] = {"name": "Hazard Scaling", "desc": "Hazards scale with difficulty"}
	imp[634] = {"name": "Trap Scaling", "desc": "Traps scale with difficulty"}
	imp[635] = {"name": "Loot Scaling", "desc": "Loot scales with difficulty"}
	imp[636] = {"name": "Boss Scaling", "desc": "Bosses scale with difficulty"}
	imp[637] = {"name": "Complexity Scaling", "desc": "Complexity scales with difficulty"}
	imp[638] = {"name": "Density Scaling", "desc": "Density scales with difficulty"}
	imp[639] = {"name": "Variety Scaling", "desc": "Variety scales with difficulty"}
	imp[640] = {"name": "Challenge Scaling", "desc": "Challenge scales with difficulty"}
	
	# #641-650: Dungeon Progression
	imp[641] = {"name": "Linear Progression", "desc": "Dungeons have linear progression"}
	imp[642] = {"name": "Branching Progression", "desc": "Dungeons have branching paths"}
	imp[643] = {"name": "Non-Linear Progression", "desc": "Dungeons are non-linear"}
	imp[644] = {"name": "Hub-Based Progression", "desc": "Dungeons use hub system"}
	imp[645] = {"name": "Gated Progression", "desc": "Progression gated by keys/abilities"}
	imp[646] = {"name": "Vertical Progression", "desc": "Dungeons have vertical levels"}
	imp[647] = {"name": "Horizontal Progression", "desc": "Dungeons expand horizontally"}
	imp[648] = {"name": "Spiral Progression", "desc": "Dungeons spiral downward"}
	imp[649] = {"name": "Circular Progression", "desc": "Dungeons form circles"}
	imp[650] = {"name": "Maze Progression", "desc": "Dungeons are mazes"}
	
	# #651-660: Dungeon Atmosphere
	imp[651] = {"name": "Lighting System", "desc": "Dynamic lighting in dungeons"}
	imp[652] = {"name": "Fog Effects", "desc": "Fog effects in dungeons"}
	imp[653] = {"name": "Particle Effects", "desc": "Particle effects in dungeons"}
	imp[654] = {"name": "Sound Design", "desc": "Atmospheric sounds in dungeons"}
	imp[655] = {"name": "Music System", "desc": "Dynamic music in dungeons"}
	imp[656] = {"name": "Color Grading", "desc": "Color grading for atmosphere"}
	imp[657] = {"name": "Ambient Effects", "desc": "Ambient effects in dungeons"}
	imp[658] = {"name": "Environmental Storytelling", "desc": "Story told through environment"}
	imp[659] = {"name": "Visual Themes", "desc": "Distinct visual themes"}
	imp[660] = {"name": "Immersion Effects", "desc": "Effects for immersion"}
	
	# #661-670: Dungeon Rewards
	imp[661] = {"name": "Treasure Rooms", "desc": "Dungeons contain treasure rooms"}
	imp[662] = {"name": "Loot Caches", "desc": "Dungeons contain loot caches"}
	imp[663] = {"name": "Artifact Rooms", "desc": "Dungeons contain artifact rooms"}
	imp[664] = {"name": "Vault Rooms", "desc": "Dungeons contain vault rooms"}
	imp[665] = {"name": "Reward Scaling", "desc": "Rewards scale with difficulty"}
	imp[666] = {"name": "Bonus Rewards", "desc": "Bonus rewards for completion"}
	imp[667] = {"name": "Challenge Rewards", "desc": "Rewards for challenges"}
	imp[668] = {"name": "Speed Rewards", "desc": "Rewards for speed completion"}
	imp[669] = {"name": "Perfection Rewards", "desc": "Rewards for perfect runs"}
	imp[670] = {"name": "Discovery Rewards", "desc": "Rewards for discoveries"}
	
	# #671-680: Dungeon Events
	imp[671] = {"name": "Random Events", "desc": "Random events in dungeons"}
	imp[672] = {"name": "Triggered Events", "desc": "Events triggered by actions"}
	imp[673] = {"name": "Timed Events", "desc": "Events triggered by time"}
	imp[674] = {"name": "Cascading Events", "desc": "Events trigger other events"}
	imp[675] = {"name": "Earthquake Events", "desc": "Earthquakes in dungeons"}
	imp[676] = {"name": "Collapse Events", "desc": "Collapses in dungeons"}
	imp[677] = {"name": "Flood Events", "desc": "Floods in dungeons"}
	imp[678] = {"name": "Fire Events", "desc": "Fires in dungeons"}
	imp[679] = {"name": "Invasion Events", "desc": "Enemy invasions in dungeons"}
	imp[680] = {"name": "Corruption Events", "desc": "Corruption spreads in dungeons"}
	
	# #681-690: Dungeon Persistence
	imp[681] = {"name": "Persistent Dungeons", "desc": "Dungeons persist between visits"}
	imp[682] = {"name": "Dynamic Changes", "desc": "Dungeons change over time"}
	imp[683] = {"name": "Player Impact", "desc": "Player actions affect dungeons"}
	imp[684] = {"name": "Destruction Persistence", "desc": "Destroyed objects stay destroyed"}
	imp[685] = {"name": "Enemy Persistence", "desc": "Killed enemies stay dead"}
	imp[686] = {"name": "Loot Persistence", "desc": "Taken loot stays taken"}
	imp[687] = {"name": "State Tracking", "desc": "Track dungeon state"}
	imp[688] = {"name": "Progress Tracking", "desc": "Track player progress in dungeon"}
	imp[689] = {"name": "Completion Tracking", "desc": "Track dungeon completion"}
	imp[690] = {"name": "Statistics Tracking", "desc": "Track dungeon statistics"}
	
	# #691-700: Advanced Dungeon Mechanics
	imp[691] = {"name": "Dungeon Corruption", "desc": "Dungeons become corrupted"}
	imp[692] = {"name": "Dungeon Evolution", "desc": "Dungeons evolve over time"}
	imp[693] = {"name": "Dungeon Mutation", "desc": "Dungeons mutate randomly"}
	imp[694] = {"name": "Dungeon Fusion", "desc": "Dungeons fuse together"}
	imp[695] = {"name": "Dungeon Splitting", "desc": "Dungeons split into sections"}
	imp[696] = {"name": "Dungeon Merging", "desc": "Dungeons merge with others"}
	imp[697] = {"name": "Dungeon Transformation", "desc": "Dungeons transform completely"}
	imp[698] = {"name": "Dungeon Ascension", "desc": "Dungeons ascend to higher tiers"}
	imp[699] = {"name": "Dungeon Recursion", "desc": "Dungeons contain dungeons"}
	imp[700] = {"name": "Dungeon Infinity", "desc": "Infinite dungeon generation"}
	
	return imp
