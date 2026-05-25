-- DwarfDrop: game_mode.lua
-- Game mode definitions and rules

local GameMode = {}

GameMode.Modes = {
    Singleplayer = {
        id = "Singleplayer",
        displayName = "Singleplayer",
        maxPlayers = 1,
        pvpEnabled = false,
        coopEnabled = false,
        sharedGold = false,
        sharedLevel = false,
        winCondition = "individual_bottom",
        description = "Race to the bottom alone.",
    },
    Cooperative = {
        id = "Cooperative",
        displayName = "Cooperative",
        maxPlayers = 4,
        pvpEnabled = false,
        coopEnabled = true,
        sharedGold = true,
        sharedLevel = true,
        winCondition = "all_alive_bottom",
        description = "All players share gold and a single level. Help downed teammates.",
        downedEnabled = true,
        rescueRadius = 8,
        rescueTime = 4.0,
        bleedTime = 30.0,
    },
    Competitive = {
        id = "Competitive",
        displayName = "Competitive",
        maxPlayers = 4,
        pvpEnabled = true,
        coopEnabled = false,
        sharedGold = false,
        sharedLevel = true,
        winCondition = "last_survivor_or_fastest",
        description = "Fight each other while racing to the bottom.",
        pvpDamage = 25,
        pvpKnockbackForce = 80,
    },
}

GameMode.ModeList = { "Singleplayer", "Cooperative", "Competitive" }

function GameMode.Get(modeId)
    return GameMode.Modes[modeId] or GameMode.Modes.Singleplayer
end

function GameMode.IsPvP(modeId)
    local m = GameMode.Get(modeId)
    return m.pvpEnabled == true
end

function GameMode.IsCoop(modeId)
    local m = GameMode.Get(modeId)
    return m.coopEnabled == true
end

return GameMode
