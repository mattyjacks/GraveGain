# ===== IMPROVEMENTS #401-550: ITEMS & LOOT =====
# This file contains 150 item and loot improvements for GraveGain

static func get_improvements() -> Dictionary:
	var imp: Dictionary = {}
	
	# #401-410: Weapon Enhancements
	imp[401] = {"name": "Weapon Damage Scaling", "desc": "Weapons scale 50% better with stats"}
	imp[402] = {"name": "Weapon Rarity Increase", "desc": "Weapons drop at higher rarity"}
	imp[403] = {"name": "Weapon Enchantment", "desc": "Weapons can be enchanted with effects"}
	imp[404] = {"name": "Weapon Evolution", "desc": "Weapons evolve into stronger forms"}
	imp[405] = {"name": "Weapon Fusion", "desc": "Combine weapons for stronger versions"}
	imp[406] = {"name": "Weapon Transmutation", "desc": "Transform weapons into other types"}
	imp[407] = {"name": "Weapon Augmentation", "desc": "Augment weapons with special properties"}
	imp[408] = {"name": "Weapon Mastery Bonus", "desc": "Weapon mastery grants 50% more bonus"}
	imp[409] = {"name": "Weapon Synergy", "desc": "Dual wielding same weapon type grants bonus"}
	imp[410] = {"name": "Weapon Resonance", "desc": "Weapons resonate together for power"}
	
	# #411-420: Armor Enhancements
	imp[411] = {"name": "Armor Defense Scaling", "desc": "Armor scales 50% better with stats"}
	imp[412] = {"name": "Armor Rarity Increase", "desc": "Armor drops at higher rarity"}
	imp[413] = {"name": "Armor Enchantment", "desc": "Armor can be enchanted with effects"}
	imp[414] = {"name": "Armor Evolution", "desc": "Armor evolves into stronger forms"}
	imp[415] = {"name": "Armor Set Bonuses", "desc": "Wearing full set grants powerful bonus"}
	imp[416] = {"name": "Armor Transmutation", "desc": "Transform armor into other types"}
	imp[417] = {"name": "Armor Augmentation", "desc": "Augment armor with special properties"}
	imp[418] = {"name": "Armor Durability", "desc": "Armor lasts 50% longer before breaking"}
	imp[419] = {"name": "Armor Regeneration", "desc": "Armor regenerates durability over time"}
	imp[420] = {"name": "Armor Resonance", "desc": "Full armor set resonates for power"}
	
	# #421-430: Accessory Enhancements
	imp[421] = {"name": "Ring Slots", "desc": "Gain additional ring slots"}
	imp[422] = {"name": "Amulet Slots", "desc": "Gain additional amulet slots"}
	imp[423] = {"name": "Trinket Slots", "desc": "Gain additional trinket slots"}
	imp[424] = {"name": "Accessory Scaling", "desc": "Accessories scale 50% better"}
	imp[425] = {"name": "Accessory Rarity", "desc": "Accessories drop at higher rarity"}
	imp[426] = {"name": "Accessory Stacking", "desc": "Accessory effects stack multiplicatively"}
	imp[427] = {"name": "Accessory Synergy", "desc": "Matching accessories grant bonuses"}
	imp[428] = {"name": "Accessory Evolution", "desc": "Accessories evolve into stronger forms"}
	imp[429] = {"name": "Accessory Fusion", "desc": "Combine accessories for power"}
	imp[430] = {"name": "Accessory Transmutation", "desc": "Transform accessories into others"}
	
	# #431-440: Consumable Enhancements
	imp[431] = {"name": "Potion Effectiveness", "desc": "Potions are 50% more effective"}
	imp[432] = {"name": "Potion Duration", "desc": "Potion effects last 50% longer"}
	imp[433] = {"name": "Potion Stacking", "desc": "Potion effects stack with each other"}
	imp[434] = {"name": "Potion Crafting", "desc": "Craft potions from materials"}
	imp[435] = {"name": "Potion Transmutation", "desc": "Convert potions into other types"}
	imp[436] = {"name": "Food Healing", "desc": "Food heals 50% more"}
	imp[437] = {"name": "Food Buffs", "desc": "Food grants temporary buffs"}
	imp[438] = {"name": "Food Stacking", "desc": "Food effects stack with each other"}
	imp[439] = {"name": "Consumable Efficiency", "desc": "Consumables cost 50% less to use"}
	imp[440] = {"name": "Consumable Crafting", "desc": "Craft consumables from materials"}
	
	# #441-450: Loot Quality & Rarity
	imp[441] = {"name": "Loot Rarity Increase", "desc": "All loot drops at higher rarity"}
	imp[442] = {"name": "Legendary Loot Chance", "desc": "Legendary items drop 50% more often"}
	imp[443] = {"name": "Epic Loot Chance", "desc": "Epic items drop 50% more often"}
	imp[444] = {"name": "Rare Loot Chance", "desc": "Rare items drop 50% more often"}
	imp[445] = {"name": "Loot Quality Scaling", "desc": "Loot quality scales with level"}
	imp[446] = {"name": "Loot Stat Scaling", "desc": "Loot stats scale 50% better"}
	imp[447] = {"name": "Loot Enchantment Chance", "desc": "Loot drops pre-enchanted"}
	imp[448] = {"name": "Loot Perfection", "desc": "Loot drops with perfect stats"}
	imp[449] = {"name": "Loot Duplication", "desc": "Chance to duplicate loot drops"}
	imp[450] = {"name": "Loot Multiplication", "desc": "Loot drops multiply by 1.5x"}
	
	# #451-460: Gold & Currency
	imp[451] = {"name": "Gold Drop Increase", "desc": "Enemies drop 50% more gold"}
	imp[452] = {"name": "Gold Multiplier", "desc": "All gold gains multiplied by 1.5x"}
	imp[453] = {"name": "Gold Interest", "desc": "Gold earns interest over time"}
	imp[454] = {"name": "Gold Conversion", "desc": "Convert gold to other currencies"}
	imp[455] = {"name": "Gold Duplication", "desc": "Chance to duplicate gold drops"}
	imp[456] = {"name": "Currency Conversion", "desc": "Convert between currencies freely"}
	imp[457] = {"name": "Currency Stacking", "desc": "Currencies stack for bonuses"}
	imp[458] = {"name": "Currency Scaling", "desc": "Currency values scale with level"}
	imp[459] = {"name": "Treasure Hunting", "desc": "Find hidden treasure caches"}
	imp[460] = {"name": "Wealth Generation", "desc": "Passive wealth generation over time"}
	
	# #461-470: Crafting & Enchanting
	imp[461] = {"name": "Crafting Recipes", "desc": "Unlock new crafting recipes"}
	imp[462] = {"name": "Crafting Efficiency", "desc": "Crafting costs 50% less materials"}
	imp[463] = {"name": "Crafting Speed", "desc": "Crafting is 50% faster"}
	imp[464] = {"name": "Crafting Quality", "desc": "Crafted items are higher quality"}
	imp[465] = {"name": "Enchanting Recipes", "desc": "Unlock new enchanting recipes"}
	imp[466] = {"name": "Enchanting Efficiency", "desc": "Enchanting costs 50% less materials"}
	imp[467] = {"name": "Enchanting Success Rate", "desc": "Enchanting succeeds 50% more often"}
	imp[468] = {"name": "Enchanting Power", "desc": "Enchantments are 50% more powerful"}
	imp[469] = {"name": "Disenchanting", "desc": "Disenchant items to recover materials"}
	imp[470] = {"name": "Transmutation", "desc": "Transmute items into other types"}
	
	# #471-480: Item Properties & Stats
	imp[471] = {"name": "Stat Scaling", "desc": "Item stats scale 50% better"}
	imp[472] = {"name": "Stat Perfection", "desc": "Items drop with perfect stats"}
	imp[473] = {"name": "Stat Stacking", "desc": "Item stats stack multiplicatively"}
	imp[474] = {"name": "Stat Synergy", "desc": "Matching stats grant bonuses"}
	imp[475] = {"name": "Stat Conversion", "desc": "Convert between different stats"}
	imp[476] = {"name": "Stat Multiplication", "desc": "Item stats multiplied by 1.5x"}
	imp[477] = {"name": "Stat Duplication", "desc": "Chance to duplicate item stats"}
	imp[478] = {"name": "Stat Rerolling", "desc": "Reroll item stats for cost"}
	imp[479] = {"name": "Stat Optimization", "desc": "Automatically optimize item stats"}
	imp[480] = {"name": "Stat Augmentation", "desc": "Augment items with extra stats"}
	
	# #481-490: Item Durability & Maintenance
	imp[481] = {"name": "Durability Increase", "desc": "Items last 50% longer"}
	imp[482] = {"name": "Durability Regeneration", "desc": "Items regenerate durability over time"}
	imp[483] = {"name": "Durability Repair", "desc": "Repair items to restore durability"}
	imp[484] = {"name": "Durability Scaling", "desc": "Durability scales with level"}
	imp[485] = {"name": "Indestructible Items", "desc": "Items never break"}
	imp[486] = {"name": "Self-Repairing Items", "desc": "Items repair themselves automatically"}
	imp[487] = {"name": "Durability Sharing", "desc": "Items share durability with each other"}
	imp[488] = {"name": "Durability Pooling", "desc": "Pool durability across items"}
	imp[489] = {"name": "Durability Conversion", "desc": "Convert durability to damage"}
	imp[490] = {"name": "Durability Immunity", "desc": "Ignore durability penalties"}
	
	# #491-500: Item Identification & Appraisal
	imp[491] = {"name": "Item Identification", "desc": "Identify items to reveal stats"}
	imp[492] = {"name": "Item Appraisal", "desc": "Appraise items to find value"}
	imp[493] = {"name": "Item Grading", "desc": "Grade items by quality"}
	imp[494] = {"name": "Item Certification", "desc": "Certify items for bonuses"}
	imp[495] = {"name": "Item Authentication", "desc": "Authenticate items for value"}
	imp[496] = {"name": "Item Valuation", "desc": "Automatically value items"}
	imp[497] = {"name": "Item Comparison", "desc": "Compare items side-by-side"}
	imp[498] = {"name": "Item Recommendations", "desc": "Get item recommendations"}
	imp[499] = {"name": "Item Tracking", "desc": "Track item locations"}
	imp[500] = {"name": "Item Organization", "desc": "Organize items automatically"}
	
	# #501-510: Unique & Legendary Items
	imp[501] = {"name": "Unique Item Drops", "desc": "Unique items drop more frequently"}
	imp[502] = {"name": "Legendary Item Drops", "desc": "Legendary items drop more frequently"}
	imp[503] = {"name": "Mythic Item Drops", "desc": "Mythic items drop occasionally"}
	imp[504] = {"name": "Artifact Item Drops", "desc": "Artifact items drop occasionally"}
	imp[505] = {"name": "Divine Item Drops", "desc": "Divine items drop occasionally"}
	imp[506] = {"name": "Cursed Item Drops", "desc": "Cursed items drop with powerful effects"}
	imp[507] = {"name": "Blessed Item Drops", "desc": "Blessed items drop with bonuses"}
	imp[508] = {"name": "Soulbound Items", "desc": "Items bind to player for power"}
	imp[509] = {"name": "Sentient Items", "desc": "Items gain sentience and personality"}
	imp[510] = {"name": "Evolving Items", "desc": "Items evolve as you use them"}
	
	# #511-520: Item Sets & Collections
	imp[511] = {"name": "Item Set Bonuses", "desc": "Wearing sets grants bonuses"}
	imp[512] = {"name": "Item Set Synergy", "desc": "Sets synergize for power"}
	imp[513] = {"name": "Item Collection Bonuses", "desc": "Collecting items grants bonuses"}
	imp[514] = {"name": "Item Collection Tracking", "desc": "Track item collections"}
	imp[515] = {"name": "Item Collection Rewards", "desc": "Complete collections for rewards"}
	imp[516] = {"name": "Item Transmutation Sets", "desc": "Transmute full sets for power"}
	imp[517] = {"name": "Item Fusion Sets", "desc": "Fuse sets into mega items"}
	imp[518] = {"name": "Item Evolution Sets", "desc": "Sets evolve into stronger forms"}
	imp[519] = {"name": "Item Resonance Sets", "desc": "Sets resonate together for power"}
	imp[520] = {"name": "Item Harmony Sets", "desc": "Sets achieve harmony for bonuses"}
	
	# #521-530: Item Storage & Management
	imp[521] = {"name": "Inventory Expansion", "desc": "Increase inventory size by 50%"}
	imp[522] = {"name": "Inventory Organization", "desc": "Organize inventory automatically"}
	imp[523] = {"name": "Inventory Sorting", "desc": "Sort inventory by various criteria"}
	imp[524] = {"name": "Inventory Filtering", "desc": "Filter inventory by type"}
	imp[525] = {"name": "Inventory Search", "desc": "Search inventory for items"}
	imp[526] = {"name": "Storage Expansion", "desc": "Expand storage capacity"}
	imp[527] = {"name": "Storage Organization", "desc": "Organize storage automatically"}
	imp[528] = {"name": "Item Stacking", "desc": "Stack items for space efficiency"}
	imp[529] = {"name": "Dimensional Storage", "desc": "Store items in pocket dimension"}
	imp[530] = {"name": "Infinite Storage", "desc": "Access infinite storage space"}
	
	# #531-540: Item Trading & Commerce
	imp[531] = {"name": "Item Trading", "desc": "Trade items with NPCs"}
	imp[532] = {"name": "Item Selling", "desc": "Sell items for better prices"}
	imp[533] = {"name": "Item Buying", "desc": "Buy items from merchants"}
	imp[534] = {"name": "Item Auctions", "desc": "Auction items to highest bidder"}
	imp[535] = {"name": "Item Bartering", "desc": "Barter items for other items"}
	imp[536] = {"name": "Item Gifting", "desc": "Gift items to other players"}
	imp[537] = {"name": "Item Sharing", "desc": "Share items with party members"}
	imp[538] = {"name": "Item Lending", "desc": "Lend items temporarily"}
	imp[539] = {"name": "Item Insurance", "desc": "Insure items against loss"}
	imp[540] = {"name": "Item Valuation", "desc": "Automatically value items fairly"}
	
	# #541-550: Advanced Item Mechanics
	imp[541] = {"name": "Item Mutation", "desc": "Items mutate into new forms"}
	imp[542] = {"name": "Item Evolution", "desc": "Items evolve as you use them"}
	imp[543] = {"name": "Item Corruption", "desc": "Items corrupt for dark power"}
	imp[544] = {"name": "Item Purification", "desc": "Purify corrupted items"}
	imp[545] = {"name": "Item Fusion", "desc": "Fuse items together"}
	imp[546] = {"name": "Item Splitting", "desc": "Split items into components"}
	imp[547] = {"name": "Item Cloning", "desc": "Clone items for duplicates"}
	imp[548] = {"name": "Item Transmutation", "desc": "Transmute items into others"}
	imp[549] = {"name": "Item Resurrection", "desc": "Resurrect destroyed items"}
	imp[550] = {"name": "Item Ascension", "desc": "Ascend items to higher tiers"}
	
	return imp
