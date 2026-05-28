-- BattleSharks Game Data
-- Central data repository for all game content

local GameConstants = require(script.Parent.Parent.Constants.GameConstants)
local GameEnums = require(script.Parent.Parent.Enums.GameEnums)

local GameData = {}

-- SHARK CLASS DATA
GameData.SharkClasses = {
	[GameEnums.SharkClass.FIGHTER] = {
		DisplayName = "Fighter",
		Description = "Melee focused shark with strong bite damage and tanky stats",
		Color = Color3.new(0.8, 0.2, 0.2),
		StartingHealth = 150,
		StartingSpeed = 22,
		StartingDamage = 20,
		Abilities = {
			BasicAttack = {
				Name = "Vicious Bite",
				Damage = 20,
				Range = 8,
				Cooldown = 0.8,
				Description = "Powerful bite attack"
			},
			Ability1 = {
				Name = "Blood Frenzy",
				Cooldown = 15,
				Duration = 8,
				Description = "Increase damage and speed for 8 seconds"
			},
			Ability2 = {
				Name = "Iron Hide",
				Cooldown = 20,
				Duration = 6,
				Description = "Reduce incoming damage by 50% for 6 seconds"
			},
			Ultimate = {
				Name = "Sharknado",
				Cooldown = 60,
				Damage = 50,
				Radius = 20,
				Description = "Create a vortex of teeth dealing massive AoE damage"
			}
		}
	},
	
	[GameEnums.SharkClass.RANGER] = {
		DisplayName = "Ranger",
		Description = "Ranged shark with harpoon launcher and precision attacks",
		Color = Color3.new(0.2, 0.6, 0.8),
		StartingHealth = 100,
		StartingSpeed = 30,
		StartingDamage = 15,
		Abilities = {
			BasicAttack = {
				Name = "Harpoon Shot",
				Damage = 15,
				Range = 40,
				Cooldown = 1.0,
				Description = "Fire harpoon at target"
			},
			Ability1 = {
				Name = "Rapid Fire",
				Cooldown = 12,
				Duration = 5,
				Description = "Fire 3 harpoons in quick succession"
			},
			Ability2 = {
				Name = "Evasion Boost",
				Cooldown = 18,
				Duration = 4,
				Description = "Increase movement speed by 100% for 4 seconds"
			},
			Ultimate = {
				Name = "Torpedo Barrage",
				Cooldown = 45,
				Projectiles = 8,
				Damage = 25,
				Description = "Launch 8 torpedoes in all directions"
			}
		}
	},
	
	[GameEnums.SharkClass.HEALER] = {
		DisplayName = "Healer",
		Description = "Magical shark with healing spells and support abilities",
		Color = Color3.new(0.2, 0.8, 0.6),
		StartingHealth = 80,
		StartingSpeed = 25,
		StartingDamage = 12,
		Abilities = {
			BasicAttack = {
				Name = "Magic Bite",
				Damage = 12,
				Range = 10,
				Cooldown = 0.9,
				Description = "Enchanted bite with magical damage"
			},
			Ability1 = {
				Name = "Healing Wave",
				Cooldown = 10,
				HealAmount = 30,
				Radius = 15,
				Description = "Heal yourself and nearby allies"
			},
			Ability2 = {
				Name = "Magic Shield",
				Cooldown = 16,
				Duration = 8,
				Description = "Create a shield absorbing 50 damage"
			},
			Ultimate = {
				Name = "Ocean's Blessing",
				Cooldown = 50,
				HealAmount = 60,
				Duration = 15,
				Description = "Massive heal and damage boost for 15 seconds"
			}
		}
	}
}

-- ENEMY DATA
GameData.Enemies = {
	[GameEnums.EnemyType.FISH] = {
		DisplayName = "Fish",
		Health = 10,
		Speed = 15,
		Damage = 2,
		XP = 5,
		Gold = 2,
		Size = Vector3.new(2, 1, 4),
		Model = "FishModel",
		Behavior = "Flee"
	},
	
	[GameEnums.EnemyType.BIRD] = {
		DisplayName = "Seagull",
		Health = 8,
		Speed = 20,
		Damage = 1,
		XP = 8,
		Gold = 3,
		Size = Vector3.new(1, 1, 2),
		Model = "BirdModel",
		Behavior = "Circle"
	},
	
	[GameEnums.EnemyType.CRAB] = {
		DisplayName = "Crab",
		Health = 25,
		Speed = 8,
		Damage = 5,
		XP = 12,
		Gold = 5,
		Size = Vector3.new(3, 2, 3),
		Model = "CrabModel",
		Behavior = "Patrol"
	},
	
	[GameEnums.EnemyType.DIVER] = {
		DisplayName = "Diver",
		Health = 40,
		Speed = 12,
		Damage = 8,
		XP = 20,
		Gold = 10,
		Size = Vector3.new(4, 6, 2),
		Model = "DiverModel",
		Behavior = "Attack"
	},
	
	[GameEnums.EnemyType.SPEARFISHERMAN] = {
		DisplayName = "Spearfisherman",
		Health = 35,
		Speed = 10,
		Damage = 15,
		XP = 25,
		Gold = 12,
		Size = Vector3.new(4, 6, 2),
		Model = "SpearfishermanModel",
		Behavior = "Ranged"
	},
	
	[GameEnums.EnemyType.JELLYFISH] = {
		DisplayName = "Jellyfish",
		Health = 15,
		Speed = 5,
		Damage = 10,
		XP = 15,
		Gold = 6,
		Size = Vector3.new(3, 3, 3),
		Model = "JellyfishModel",
		Behavior = "Float"
	},
	
	[GameEnums.EnemyType.SQUID] = {
		DisplayName = "Squid",
		Health = 30,
		Speed = 18,
		Damage = 12,
		XP = 22,
		Gold = 8,
		Size = Vector3.new(4, 2, 6),
		Model = "SquidModel",
		Behavior = "InkAttack"
	},
	
	[GameEnums.EnemyType.WHALE] = {
		DisplayName = "Whale",
		Health = 200,
		Speed = 25,
		Damage = 20,
		XP = 100,
		Gold = 50,
		Size = Vector3.new(20, 8, 30),
		Model = "WhaleModel",
		Behavior = "Peaceful"
	},
	
	[GameEnums.EnemyType.SHARK] = {
		DisplayName = "Rival Shark",
		Health = 80,
		Speed = 28,
		Damage = 18,
		XP = 40,
		Gold = 20,
		Size = Vector3.new(8, 4, 12),
		Model = "EnemySharkModel",
		Behavior = "Aggressive"
	}
}

-- ITEM DATA
GameData.Items = {
	-- POTIONS
	HealthPotion = {
		DisplayName = "Health Potion",
		Type = GameEnums.ItemType.POTION,
		Rarity = GameEnums.Rarity.COMMON,
		Effect = "Heal",
		Value = 50,
		Cost = 25,
		Description = "Restore 50 health instantly"
	},
	
	SpeedPotion = {
		DisplayName = "Speed Potion",
		Type = GameEnums.ItemType.POTION,
		Rarity = GameEnums.Rarity.UNCOMMON,
		Effect = "SpeedBoost",
		Duration = 30,
		Value = 1.5,
		Cost = 50,
		Description = "Increase speed by 50% for 30 seconds"
	},
	
	RadiationResistance = {
		DisplayName = "Rad-X",
		Type = GameEnums.ItemType.POTION,
		Rarity = GameEnums.Rarity.RARE,
		Effect = "RadiationResist",
		Duration = 60,
		Cost = 100,
		Description = "Resist radiation effects for 60 seconds"
	},
	
	-- FOOD
	FishFood = {
		DisplayName = "Fish Food",
		Type = GameEnums.ItemType.FOOD,
		Rarity = GameEnums.Rarity.COMMON,
		HungerRestore = 20,
		HealthRestore = 5,
		Cost = 10,
		Description = "Basic fish food, restores hunger"
	},
	
	PremiumFish = {
		DisplayName = "Premium Fish",
		Type = GameEnums.ItemType.FOOD,
		Rarity = GameEnums.Rarity.UNCOMMON,
		HungerRestore = 40,
		HealthRestore = 15,
		Cost = 25,
		Description = "Delicious premium fish"
	},
	
	-- MUTATION STABILIZERS
	MutationStabilizer = {
		DisplayName = "Mutation Stabilizer",
		Type = GameEnums.ItemType.MUTATION_STABILIZER,
		Rarity = GameEnums.Rarity.RARE,
		Effect = "StabilizeMutations",
		Duration = 300,
		Cost = 75,
		Description = "Prevent random mutations for 5 minutes"
	}
}

-- MUTATION DATA
GameData.Mutations = {
	[GameEnums.MutationType.EYES_EXTRA] = {
		DisplayName = "Extra Eyes",
		Description = "Grow additional eyes for better perception",
		VisualEffect = "AddEyeModels",
		StatEffect = { Perception = 1.2 },
		Rarity = GameEnums.Rarity.COMMON
	},
	
	[GameEnums.MutationType.TEETH_LARGE] = {
		DisplayName = "Large Teeth",
		Description = "Massive teeth increase bite damage",
		VisualEffect = "ScaleTeeth",
		StatEffect = { Damage = 1.3 },
		Rarity = GameEnums.Rarity.UNCOMMON
	},
	
	[GameEnums.MutationType.FINS_DEFORMED] = {
		DisplayName = "Deformed Fins",
		Description = "Irregular fins affect movement",
		VisualEffect = "DeformFins",
		StatEffect = { Speed = 0.9, TurnSpeed = 1.1 },
		Rarity = GameEnums.Rarity.COMMON
	},
	
	[GameEnums.MutationType.GLOW_EFFECT] = {
		DisplayName = "Bioluminescent",
		Description = "Natural glow illuminates dark waters",
		VisualEffect = "AddGlow",
		StatEffect = { Visibility = 1.5 },
		Rarity = GameEnums.Rarity.RARE
	},
	
	[GameEnums.MutationType.SIZE_INCREASED] = {
		DisplayName = "Gigantism",
		Description = "Increased size makes you more intimidating",
		VisualEffect = "ScaleModel",
		StatEffect = { Size = 1.2, Health = 1.1, Speed = 0.95 },
		Rarity = GameEnums.Rarity.EPIC
	},
	
	[GameEnums.MutationType.COLOR_SHIFT] = {
		DisplayName = "Color Shift",
		Description = "Unnatural coloration",
		VisualEffect = "ChangeColor",
		StatEffect = {},
		Rarity = GameEnums.Rarity.COMMON
	},
	
	[GameEnums.MutationType.PATTERN_CHANGE] = {
		DisplayName = "Pattern Change",
		Description = "Unique skin patterns",
		VisualEffect = "ChangePattern",
		StatEffect = {},
		Rarity = GameEnums.Rarity.UNCOMMON
	}
}

-- AQUARIUM DECORATIONS
GameData.AquariumDecorations = {
	SkeletonWhiskey = {
		DisplayName = "Skeleton with Whiskey",
		Category = GameEnums.DecorationCategory.PROPS,
		Cost = 100,
		Rarity = GameEnums.Rarity.RARE,
		Description = "A skeleton enjoying eternal rest",
		Model = "SkeletonWhiskeyModel"
	},
	
	SunkenShip = {
		DisplayName = "Sunken Ship",
		Category = GameEnums.DecorationCategory.STRUCTURES,
		Cost = 500,
		Rarity = GameEnums.Rarity.EPIC,
		Description = "Ancient shipwreck",
		Model = "SunkenShipModel"
	},
	
	Starfish = {
		DisplayName = "Starfish Colony",
		Category = GameEnums.DecorationCategory.PLANTS,
		Cost = 50,
		Rarity = GameEnums.Rarity.COMMON,
		Description = "Colorful starfish collection",
		Model = "StarfishModel"
	},
	
	CoralReef = {
		DisplayName = "Coral Reef",
		Category = GameEnums.DecorationCategory.PLANTS,
		Cost = 150,
		Rarity = GameEnums.Rarity.UNCOMMON,
		Description = "Vibrant coral formation",
		Model = "CoralModel"
	},
	
	Crystals = {
		DisplayName = "Magic Crystals",
		Category = GameEnums.DecorationCategory.LIGHTING,
		Cost = 300,
		Rarity = GameEnums.Rarity.RARE,
		Description = "Glowing crystals illuminate the aquarium",
		Model = "CrystalModel"
	},
	
	SubmarineWreck = {
		DisplayName = "Submarine Wreck",
		Category = GameEnums.DecorationCategory.STRUCTURES,
		Cost = 750,
		Rarity = GameEnums.Rarity.LEGENDARY,
		Description = "Mysterious submarine remains",
		Model = "SubmarineModel"
	}
}

-- RARITY COLORS
GameData.RarityColors = {
	[GameEnums.Rarity.COMMON] = Color3.new(0.8, 0.8, 0.8),
	[GameEnums.Rarity.UNCOMMON] = Color3.new(0.2, 0.8, 0.2),
	[GameEnums.Rarity.RARE] = Color3.new(0.2, 0.4, 0.8),
	[GameEnums.Rarity.EPIC] = Color3.new(0.6, 0.2, 0.8),
	[GameEnums.Rarity.LEGENDARY] = Color3.new(0.8, 0.6, 0.2)
}

return GameData
