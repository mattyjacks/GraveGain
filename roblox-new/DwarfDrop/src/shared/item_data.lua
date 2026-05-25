-- DwarfDrop: item_data.lua
-- Active item definitions + weight system constants

local ItemData = {}

-- Weight system: affects speed and fall damage multipliers
ItemData.WeightConstants = {
    SPEED_PER_KG  = 0.04,  -- speed reduction per kg of carried weight
    FALL_PER_KG   = 0.06,  -- fall damage multiplier increase per kg
    MAX_SPEED_PENALTY  = 0.65,  -- minimum speed multiplier floor (35% max reduction)
    MAX_FALL_PENALTY   = 3.0,   -- maximum fall damage multiplier
}

-- Item weights in kg
ItemData.ItemWeights = {
    Parachute    = 0.4,
    Rope         = 1.2,
    Spring       = 2.5,
    JetpackFuel  = 3.0,
    Balloon      = 0.3,
    Lantern      = 0.8,
    WaterCooler  = 4.0,
    SteamVent    = 2.0,
    Javelin      = 2.0,
    SmallRock    = 1.0,
    BigRock      = 5.0,
}

ItemData.Items = {
    -- ==================== UTILITY ====================
    Parachute = {
        id = "Parachute",
        displayName = "Parachute",
        category = "utility",
        useType = "toggle",  -- Q to deploy/collapse
        maxCount = 3,
        weight = ItemData.ItemWeights.Parachute,
        description = "Deploy to slow your descent dramatically.",
        glowColor = Color3.fromRGB(220, 220, 255),
        spawnWeight = 15,
    },
    Rope = {
        id = "Rope",
        displayName = "Rope",
        category = "utility",
        useType = "place",  -- F to attach rope anchor
        maxCount = 4,
        weight = ItemData.ItemWeights.Rope,
        description = "Attach to walls. Slide down or swing across gaps.",
        glowColor = Color3.fromRGB(180, 140, 80),
        spawnWeight = 12,
    },
    Spring = {
        id = "Spring",
        displayName = "Spring Pad",
        category = "utility",
        useType = "place",
        maxCount = 2,
        weight = ItemData.ItemWeights.Spring,
        description = "Place a spring that launches you upward on contact.",
        glowColor = Color3.fromRGB(80, 255, 80),
        spawnWeight = 8,
    },
    JetpackFuel = {
        id = "JetpackFuel",
        displayName = "Jetpack Fuel",
        category = "utility",
        useType = "hold",  -- Q hold to thrust
        maxCount = 2,
        weight = ItemData.ItemWeights.JetpackFuel,
        description = "Hold Q to fire a burst of thrust upward.",
        glowColor = Color3.fromRGB(255, 160, 40),
        spawnWeight = 6,
        fuelSeconds = 3.5,
    },
    Balloon = {
        id = "Balloon",
        displayName = "Balloon",
        category = "utility",
        useType = "toggle",
        maxCount = 5,
        weight = ItemData.ItemWeights.Balloon,
        description = "Attaches to you and slows descent. Pops on hazard contact.",
        glowColor = Color3.fromRGB(255, 100, 200),
        spawnWeight = 14,
    },
    Lantern = {
        id = "Lantern",
        displayName = "Lantern",
        category = "utility",
        useType = "toggle",
        maxCount = 3,
        weight = ItemData.ItemWeights.Lantern,
        description = "Emits a warm glow. Essential in Cave and Mine biomes.",
        glowColor = Color3.fromRGB(255, 230, 150),
        spawnWeight = 18,
    },
    WaterCooler = {
        id = "WaterCooler",
        displayName = "Water Cooler",
        category = "utility",
        useType = "use",
        maxCount = 1,
        weight = ItemData.ItemWeights.WaterCooler,
        description = "Refills your steam-powered item water tank.",
        glowColor = Color3.fromRGB(80, 200, 255),
        spawnWeight = 10,
        waterAmount = 5,
    },
    SteamVent = {
        id = "SteamVent",
        displayName = "Steam Vent",
        category = "utility",
        useType = "use",  -- Q to blast upward
        maxCount = 2,
        weight = ItemData.ItemWeights.SteamVent,
        description = "Fire a steam burst upward. Requires water.",
        glowColor = Color3.fromRGB(200, 240, 255),
        spawnWeight = 9,
        waterCostPerUse = 1,
    },
    -- ==================== COMPETITIVE ====================
    Javelin = {
        id = "Javelin",
        displayName = "Javelin",
        category = "competitive",
        useType = "throw",  -- Q to throw
        maxCount = 3,
        weight = ItemData.ItemWeights.Javelin,
        description = "Throw at opponents to deal heavy damage.",
        glowColor = Color3.fromRGB(255, 80, 80),
        spawnWeight = 5,
        damage = 40,
    },
    SmallRock = {
        id = "SmallRock",
        displayName = "Small Rock",
        category = "competitive",
        useType = "throw",
        maxCount = 6,
        weight = ItemData.ItemWeights.SmallRock,
        description = "Throw rocks to stagger opponents.",
        glowColor = Color3.fromRGB(180, 160, 130),
        spawnWeight = 8,
        damage = 15,
    },
    BigRock = {
        id = "BigRock",
        displayName = "Big Rock",
        category = "competitive",
        useType = "throw",
        maxCount = 2,
        weight = ItemData.ItemWeights.BigRock,
        description = "Heavy but devastating. Massive knockback.",
        glowColor = Color3.fromRGB(120, 110, 90),
        spawnWeight = 3,
        damage = 70,
    },
}

-- Ordered spawn pool for level generation
ItemData.UtilityItems = {
    "Parachute", "Rope", "Spring", "JetpackFuel",
    "Balloon", "Lantern", "WaterCooler", "SteamVent",
}

ItemData.CompetitiveItems = {
    "Javelin", "SmallRock", "BigRock",
}

-- Compute total weight for a backpack slot array {itemId, count}
function ItemData.ComputeWeight(backpack)
    local total = 0
    for _, slot in ipairs(backpack) do
        if slot and slot.itemId then
            local def = ItemData.Items[slot.itemId]
            if def then
                total = total + (def.weight or 0) * (slot.count or 1)
            end
        end
    end
    return total
end

-- Compute speed and fall multipliers from total weight
function ItemData.WeightToMultipliers(totalKg)
    local wc = ItemData.WeightConstants
    local speedMult = math.max(wc.MAX_SPEED_PENALTY, 1 - totalKg * wc.SPEED_PER_KG)
    local fallMult  = math.min(wc.MAX_FALL_PENALTY, 1 + totalKg * wc.FALL_PER_KG)
    return speedMult, fallMult
end

return ItemData
