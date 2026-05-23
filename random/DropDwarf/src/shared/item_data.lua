-- DropDwarf: item_data.lua
-- Active item definitions. Each item has a unique id, display info,
-- use behavior type, and relevant parameters.

local ItemData = {}

-- Water system constants
ItemData.WATER_MAX        = 5.0   -- litres
ItemData.WATER_START      = 2.5   -- half tank on pickup
ItemData.WATER_FILL_RATE  = 1.0   -- litres per second from water source

-- Item definitions
ItemData.Items = {

    HealingPotion = {
        id           = "HealingPotion",
        displayName  = "Healing Potion",
        description  = "Restores 100 HP over 10 seconds (+10/s). Stacks with natural regen.",
        icon         = "rbxassetid://0",   -- placeholder
        stackable    = true,
        maxStack     = 3,
        useType      = "instant",          -- consumed on use, effect ticks on server
        useCost      = nil,                -- no water cost
        healPerSec   = 10,
        healDuration = 10,                 -- seconds
        weightKg     = 0.3,               -- per unit
        color        = Color3.fromRGB(255, 80, 120),
    },

    ClimbingRope = {
        id           = "ClimbingRope",
        displayName  = "Climbing Rope",
        description  = "Place on a platform edge. Reach down 50m. Grab to slow fall. Jump to release.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "place",            -- click surface to place in world
        useCost      = nil,
        ropeLength   = 160,               -- 50m * 3.2 studs
        climbUpSpeed = 6,                  -- studs/s
        climbDownSpeed = 14,               -- studs/s
        fallDamageMultiplier = 0.5,        -- half fall damage on rope grab
        weightKg     = 1.2,
        color        = Color3.fromRGB(180, 140, 80),
    },

    SpringThing = {
        id           = "SpringThing",
        displayName  = "Spring Thing",
        description  = "A bouncy spring cushion. Jump in rhythm to build height. Fast falls still hurt.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "place",
        useCost      = nil,
        launchForce  = 90,                 -- base upward velocity studs/s
        maxLaunchForce = 180,              -- when perfectly timed
        dangerSpeed  = 80,                 -- studs/s impact speed that still damages
        weightKg     = 2.0,
        color        = Color3.fromRGB(255, 200, 50),
    },

    Parachute = {
        id           = "Parachute",
        displayName  = "Parachute",
        description  = "Slows your fall. Damaged by terrain above. No fall damage while open.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "toggle",           -- press to open/close
        useCost      = nil,
        fallSpeedCap = 8,                  -- max studs/s while open
        chuteDurability = 3,              -- hits before it tears (terrain collision)
        weightKg     = 1.5,
        color        = Color3.fromRGB(220, 80, 80),
    },

    Balloon = {
        id           = "Balloon",
        displayName  = "Balloon",
        description  = "Reduces your gravity, slowing your fall.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "toggle",
        useCost      = nil,
        gravityScale = 0.45,              -- multiplied against workspace.Gravity
        weightKg     = 0.2,
        color        = Color3.fromRGB(120, 180, 255),
    },

    SteamJetpack = {
        id           = "SteamJetpack",
        displayName  = "Steam Jetpack",
        description  = "Burns Water to push you upward. Comes with half a tank.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "hold",             -- hold key to use continuously
        useCost      = "water",
        waterPerSec  = 0.5,               -- litres/s consumed
        liftForce    = 120,               -- upward force (studs/s^2 additive)
        weightKg     = 8.0,               -- heavy metal tank
        color        = Color3.fromRGB(160, 220, 255),
    },

    SteamThrower = {
        id           = "SteamThrower",
        displayName  = "Steam Thrower",
        description  = "Blasts steam at your aim, knocking you back. Stable on dry ground.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "hold",
        useCost      = "water",
        waterPerSec  = 0.8,
        knockbackForce = 85,              -- studs/s away from aim
        range          = 24,              -- stud range of steam spray
        weightKg     = 6.0,
        color        = Color3.fromRGB(200, 240, 255),
    },

    PitonSpikes = {
        id           = "PitonSpikes",
        displayName  = "Piton Spikes",
        description  = "Hammer into vertical walls. Stand on them or hang with pickaxe.",
        icon         = "rbxassetid://0",
        stackable    = true,
        maxStack     = 5,                 -- 5 pitons per item pickup
        useType      = "place",
        useCost      = nil,
        weightKg     = 0.4,               -- per piton
        color        = Color3.fromRGB(80, 80, 90),
    },

    -- ========== COMPETITIVE ITEMS ==========

    Javelin = {
        id           = "Javelin",
        displayName  = "Javelin",
        description  = "Hurl a long spear. Sticks into any surface on landing - can be stepped on.",
        icon         = "rbxassetid://0",
        stackable    = true,
        maxStack     = 3,
        useType      = "throw",
        useCost      = nil,
        -- Throw physics
        throwSpeed   = 120,               -- studs/s initial velocity
        gravity      = 70,               -- studs/s^2 (less than real gravity for better arc)
        -- Damage
        playerDamage = 40,               -- HP on direct hit
        hitRadius    = 2.5,              -- overlap radius at impact to check nearby players
        -- World part on land
        stickSize    = Vector3.new(0.35, 0.35, 5.5),
        canStandOn   = true,             -- creates a climbable/standable surface
        weightKg     = 1.8,               -- per javelin
        color        = Color3.fromRGB(180, 160, 80),
        tipColor     = Color3.fromRGB(200, 200, 210),
    },

    SmallRock = {
        id           = "SmallRock",
        displayName  = "Small Rock",
        description  = "Toss a rock. Fast, travels far. Arc shows where it lands. Hurts players on impact.",
        icon         = "rbxassetid://0",
        stackable    = true,
        maxStack     = 5,
        useType      = "throw",
        useCost      = nil,
        throwSpeed   = 90,
        gravity      = 80,
        playerDamage = 25,
        hitRadius    = 2.0,
        stickSize    = nil,              -- doesn't stick, bounces and disappears
        canStandOn   = false,
        weightKg     = 0.8,               -- per rock
        color        = Color3.fromRGB(110, 100, 95),
    },

    BigRock = {
        id           = "BigRock",
        displayName  = "Big Rock",
        description  = "A massive rock. Very heavy - slows you down and worsens fall damage. Short arc, devastating hit.",
        icon         = "rbxassetid://0",
        stackable    = false,
        useType      = "throw",
        useCost      = nil,
        throwSpeed   = 55,               -- slower, doesn't travel as far
        gravity      = 100,              -- heavy - drops fast
        playerDamage = 80,               -- lots of damage
        hitRadius    = 3.5,              -- wide impact
        stickSize    = nil,
        canStandOn   = false,
        weightKg     = 18.0,             -- very heavy - significant speed + fall damage penalty
        color        = Color3.fromRGB(85, 78, 72),
    },
}

-- Weight system
-- Total backpack weight (kg) drives two penalties:
--   walkSpeed  *= max(WEIGHT_SPEED_FLOOR,  1 - totalKg * WEIGHT_SPEED_PER_KG)
--   fallDamage *= max(1,                   1 + totalKg * WEIGHT_FALL_PER_KG)
-- These constants are used by both server and client.
ItemData.WEIGHT_SPEED_PER_KG  = 0.018   -- -1.8% walkSpeed per kg
ItemData.WEIGHT_SPEED_FLOOR   = 0.30    -- can't drop below 30% base speed
ItemData.WEIGHT_FALL_PER_KG   = 0.04    -- +4% fall damage per kg

-- Water source tags used by level_generator to mark water refill parts
ItemData.WATER_SOURCE_TAG = "IsWaterSource"

-- Biomes that have water sources
ItemData.WATER_BIOMES = {
    Cave     = true,
    Mine     = true,
    Fortress = true,
    -- Volcano = false (no water)
}

return ItemData
