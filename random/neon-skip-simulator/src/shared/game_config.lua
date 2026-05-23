--[[
    Neon Skip Simulator - Game Configuration
    Core data for ropes, zones, pets, and upgrades
]]

local GameConfig = {}

-- Rope upgrades (main progression)
GameConfig.ROPES = {
    {
        id = "starter",
        name = "Basic Cord",
        cost = 0,
        speed = 1.0,
        jumpHeight = 10,
        color = Color3.fromRGB(200, 200, 200),
        particles = false
    },
    {
        id = "neon_pink",
        name = "Neon Pink Rope",
        cost = 50,
        speed = 1.2,
        jumpHeight = 12,
        color = Color3.fromRGB(255, 0, 128),
        particles = true,
        particleColor = Color3.fromRGB(255, 0, 128)
    },
    {
        id = "cyber_blue",
        name = "Cyber Blue Rope",
        cost = 200,
        speed = 1.5,
        jumpHeight = 15,
        color = Color3.fromRGB(0, 200, 255),
        particles = true,
        particleColor = Color3.fromRGB(0, 200, 255)
    },
    {
        id = "plasma_green",
        name = "Plasma Green Rope",
        cost = 500,
        speed = 1.8,
        jumpHeight = 18,
        color = Color3.fromRGB(0, 255, 100),
        particles = true,
        particleColor = Color3.fromRGB(0, 255, 100),
        trail = true
    },
    {
        id = "holographic",
        name = "Holographic Rope",
        cost = 1200,
        speed = 2.2,
        jumpHeight = 22,
        color = Color3.fromRGB(200, 0, 255),
        particles = true,
        particleColor = Color3.fromRGB(200, 0, 255),
        trail = true,
        holographic = true
    },
    {
        id = "void_purple",
        name = "Void Purple Rope",
        cost = 3000,
        speed = 2.8,
        jumpHeight = 28,
        color = Color3.fromRGB(150, 0, 255),
        particles = true,
        particleColor = Color3.fromRGB(150, 0, 255),
        trail = true,
        aura = true
    },
    {
        id = "sunfire",
        name = "Sunfire Rope",
        cost = 8000,
        speed = 3.5,
        jumpHeight = 35,
        color = Color3.fromRGB(255, 150, 0),
        particles = true,
        particleColor = Color3.fromRGB(255, 200, 0),
        trail = true,
        aura = true,
        shockwave = true
    },
    {
        id = "quantum",
        name = "Quantum Skipper",
        cost = 20000,
        speed = 5.0,
        jumpHeight = 50,
        color = Color3.fromRGB(255, 255, 255),
        particles = true,
        particleColor = Color3.fromRGB(255, 0, 255),
        trail = true,
        aura = true,
        shockwave = true,
        teleportEffect = true
    },
    {
        id = "cosmic",
        name = "Cosmic Hyperrope",
        cost = 50000,
        speed = 8.0,
        jumpHeight = 75,
        color = Color3.fromRGB(255, 100, 255),
        particles = true,
        particleColor = Color3.fromRGB(255, 0, 200),
        trail = true,
        aura = true,
        shockwave = true,
        teleportEffect = true
        -- Note: screenShake removed for accessibility (photosensitive players)
    },
    {
        id = "godlike",
        name = "Godlike Velocity",
        cost = 150000,
        speed = 15.0,
        jumpHeight = 120,
        color = Color3.fromRGB(255, 255, 100),
        particles = true,
        particleColor = Color3.fromRGB(255, 255, 0),
        trail = true,
        aura = true,
        shockwave = true,
        teleportEffect = true,
        rainbow = true
        -- Note: screenShake removed for accessibility (photosensitive players)
    }
}

-- Zones (gated progression)
GameConfig.ZONES = {
    {
        id = "starter",
        name = "Neon Plaza",
        requiredMomentum = 0,
        color = Color3.fromRGB(100, 100, 100)
    },
    {
        id = "cyber",
        name = "Cyber District",
        requiredMomentum = 500,
        color = Color3.fromRGB(0, 200, 255)
    },
    {
        id = "plasma",
        name = "Plasma Core",
        requiredMomentum = 3000,
        color = Color3.fromRGB(0, 255, 100)
    },
    {
        id = "void",
        name = "Void Sector",
        requiredMomentum = 15000,
        color = Color3.fromRGB(150, 0, 255)
    },
    {
        id = "sunfire",
        name = "Sunfire Heights",
        requiredMomentum = 60000,
        color = Color3.fromRGB(255, 150, 0)
    },
    {
        id = "quantum",
        name = "Quantum Realm",
        requiredMomentum = 200000,
        color = Color3.fromRGB(255, 255, 255)
    }
}

-- Holographic pets
GameConfig.PETS = {
    {
        id = "orb_common",
        name = "Neon Orb",
        cost = 1000,
        multiplier = 1.1,
        color = Color3.fromRGB(0, 255, 255),
        rarity = "Common"
    },
    {
        id = "orb_uncommon",
        name = "Cyber Orb",
        cost = 5000,
        multiplier = 1.25,
        color = Color3.fromRGB(255, 0, 255),
        rarity = "Uncommon"
    },
    {
        id = "orb_rare",
        name = "Plasma Orb",
        cost = 15000,
        multiplier = 1.5,
        color = Color3.fromRGB(0, 255, 100),
        rarity = "Rare"
    },
    {
        id = "orb_epic",
        name = "Void Orb",
        cost = 50000,
        multiplier = 2.0,
        color = Color3.fromRGB(150, 0, 255),
        rarity = "Epic"
    },
    {
        id = "orb_legendary",
        name = "Cosmic Orb",
        cost = 200000,
        multiplier = 3.0,
        color = Color3.fromRGB(255, 200, 0),
        rarity = "Legendary"
    }
}

-- Rebirth tiers
GameConfig.REBIRTHS = {
    {
        tier = 1,
        requiredMomentum = 100000,
        multiplier = 2.0,
        color = Color3.fromRGB(255, 255, 255)
    },
    {
        tier = 2,
        requiredMomentum = 500000,
        multiplier = 3.0,
        color = Color3.fromRGB(255, 200, 0)
    },
    {
        tier = 3,
        requiredMomentum = 2000000,
        multiplier = 5.0,
        color = Color3.fromRGB(255, 0, 200)
    },
    {
        tier = 4,
        requiredMomentum = 10000000,
        multiplier = 8.0,
        color = Color3.fromRGB(0, 255, 255)
    },
    {
        tier = 5,
        requiredMomentum = 50000000,
        multiplier = 15.0,
        color = Color3.fromRGB(255, 0, 0)
    }
}

--[[
    GAMEPASS SETUP INSTRUCTIONS:
    1. Create gamepasses in Roblox Creator Dashboard
    2. Copy the gamepass IDs here
    3. All audio must be uploaded by you or from Roblox's free library
    
    TOS COMPLIANCE:
    - Do NOT use audio IDs you don't have rights to
    - Do NOT allow players to play arbitrary audio (copyright violation)
    - Only use Roblox's Sound Effect asset library or upload your own
]]

-- Gamepass IDs (placeholder - update with actual IDs from Creator Dashboard)
GameConfig.GAMEPASSES = {
    AUTO_SKIP = {
        id = 0, -- REPLACE WITH YOUR GAMEPASS ID
        price = 299,
        name = "Auto-Skip"
    },
    X2_MOMENTUM = {
        id = 0, -- REPLACE WITH YOUR GAMEPASS ID
        price = 399,
        name = "x2 Momentum"
    }
}

--[[
    AUDIO SETUP:
    These are placeholder IDs. You MUST either:
    1. Upload your own audio to Roblox (recommended)
    2. Use Roblox's free Sound Effects library
    3. Leave as nil to disable sounds
    
    IMPORTANT TOS NOTICE:
    - Using copyrighted music without license = violation
    - Using inappropriate sounds = violation  
    - Letting players play arbitrary audio IDs = violation
    - Only use audio you have explicit rights to use
]]
GameConfig.AUDIO = {
    clickSound = nil,      -- Upload your own click sound
    jumpSound = nil,       -- Upload your own jump sound  
    upgradeSound = nil,    -- Upload your own upgrade sound
    rebirthSound = nil,    -- Upload your own rebirth sound
    bgmSynthwave = nil     -- Upload your own background music
}

return GameConfig
