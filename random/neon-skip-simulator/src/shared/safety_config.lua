--[[
    Neon Skip Simulator - Safety & Accessibility Configuration
    
    SAFETY FEATURES:
    - AFK time limits to prevent playtime inflation
    - Data caps to prevent overflow
    - Rate limiting for remote events
    - Accessibility options for photosensitive players
]]

local SafetyConfig = {}

-- AFK Zone Safety (prevents algorithm manipulation)
SafetyConfig.AFK = {
    -- Maximum time a player can AFK before rewards stop (in minutes)
    -- This prevents players from leaving devices on indefinitely
    MAX_AFK_TIME_MINUTES = 60,
    
    -- Rewards stop after this time
    REWARD_STOP_MESSAGE = "AFK rewards paused. Please take a break!",
    
    -- Kick warning after extended AFK (disabled by default, just stops rewards)
    EXTENDED_AFK_WARNING = "You've been idle for a while. Rewards paused for balance."
}

-- Data Safety (prevents overflow and exploits)
SafetyConfig.DATA = {
    -- Maximum momentum a player can have (prevents integer overflow)
    -- 2^31 - 1 is max safe integer in Lua 5.1
    MAX_MOMENTUM = 2000000000,
    
    -- Maximum rebirths
    MAX_REBIRTHS = 100,
    
    -- Maximum pet multiplier (prevents exploit stacking)
    MAX_PET_MULTIPLIER = 10,
    
    -- Sanity check for momentum gains (prevents hacked clients)
    MAX_MOMENTUM_PER_SKIP = 1000,
    
    -- Auto-ban threshold for suspicious gains (disabled, just logs)
    SUSPICIOUS_GAIN_THRESHOLD = 100000
}

-- Rate Limiting (prevents remote event spam)
SafetyConfig.RATE_LIMITS = {
    -- Minimum time between shop purchases (seconds)
    SHOP_PURCHASE_COOLDOWN = 0.5,
    
    -- Minimum time between skip actions (client-side, additional check)
    SKIP_ACTION_COOLDOWN = 0.1,
    
    -- Remote event spam threshold (events per second)
    MAX_REMOTE_EVENTS_PER_SECOND = 10
}

-- Accessibility (photosensitive player safety)
SafetyConfig.ACCESSIBILITY = {
    -- Allow disabling screen shake (even though it's not implemented, good to have)
    ALLOW_DISABLE_SCREEN_SHAKE = true,
    
    -- Allow reducing particle effects
    ALLOW_REDUCE_PARTICLES = true,
    
    -- Reduced motion option
    REDUCED_MOTION = {
        disableParticles = true,
        disableTrails = false,
        disableAura = false,
        disableShockwave = true
    },
    
    -- Photosensitive warning on first join
    SHOW_PHOTOSENSITIVE_WARNING = true
}

-- Auto-Skip Gamepass Safety
SafetyConfig.AUTO_SKIP = {
    -- Auto-skip is slightly slower than manual (encourages active play)
    SPEED_PENALTY = 0.8,
    
    -- Maximum skips per second with auto-skip
    MAX_SKIPS_PER_SECOND = 5,
    
    -- Warning about AFK gameplay
    AFK_WARNING = "Auto-Skip is for accessibility. Active play earns more!"
}

-- Monetization Safety (clear and honest)
SafetyConfig.MONETIZATION = {
    -- Clear descriptions required
    REQUIRE_CLEAR_DESCRIPTIONS = true,
    
    -- No gambling mechanics
    ALLOW_GAMBLING = false,
    
    -- Gamepass effects must be clear
    -- All gamepasses in this game are permanent (not consumable)
    ALL_GAMEPASSES_PERMANENT = true,
    
    -- Price validation (ensure prices are reasonable)
    MIN_GAMEPASS_PRICE = 5,
    MAX_GAMEPASS_PRICE = 10000
}

-- Content Safety
SafetyConfig.CONTENT = {
    -- Game is appropriate for all ages
    CONTENT_RATING = "All Ages",
    
    -- No user-generated content that could be inappropriate
    ALLOW_USER_CONTENT = false,
    
    -- All text filtered through Roblox (automatic)
    USE_TEXT_FILTER = true,
    
    -- No external links
    ALLOW_EXTERNAL_LINKS = false
}

return SafetyConfig
