-- DropDwarf: game_mode.lua
-- Game mode definitions and per-mode rule constants.

local GameMode = {}

GameMode.Modes = {
    Singleplayer = {
        id              = "Singleplayer",
        displayName     = "Singleplayer",
        description     = "Classic solo run. Just you and the drop.",
        maxPlayers      = 1,
        pvpEnabled      = false,
        coopEnabled     = false,
        sharedLevel     = false,
        sharedGold      = false,
        color           = Color3.fromRGB(80, 200, 255),
    },
    Cooperative = {
        id              = "Cooperative",
        displayName     = "Cooperative",
        description     = "Team up. Rescue downed teammates. Share items. All reach bottom to win.",
        maxPlayers      = 4,
        pvpEnabled      = false,
        coopEnabled     = true,
        sharedLevel     = true,
        sharedGold      = true,    -- gold pickups count for the whole team
        color           = Color3.fromRGB(60, 210, 80),
        -- Coop-specific rules
        downedBleedSecs = 30,      -- seconds before a downed player dies
        rescueRange     = 8,       -- studs to stand near downed player to rescue
        rescueTime      = 3,       -- seconds of holding E to complete rescue
        giveItemRange   = 6,       -- studs to give item to teammate (G key)
        healPotionTeam  = true,    -- HealingPotion heals all coop teammates
        winCondition    = "all",   -- all players must reach the bottom
    },
    Competitive = {
        id              = "Competitive",
        displayName     = "Competitive",
        description     = "Race to the bottom. Attack rivals with your pickaxe. First wins.",
        maxPlayers      = 4,
        pvpEnabled      = true,
        coopEnabled     = false,
        sharedLevel     = true,
        sharedGold      = false,   -- each player keeps own gold
        color           = Color3.fromRGB(220, 60, 40),
        -- PvP-specific rules
        pickaxeDamage   = 15,      -- HP per pickaxe swing on player
        knockbackForce  = 60,      -- studs/s radial from attacker
        pickaxeRange    = 6,       -- stud range of pickaxe swing for player hits
        pickaxeCooldown = 0.5,     -- seconds between player hits (per victim)
        winCondition    = "first", -- first player to reach the bottom wins
    },
}

-- Returns the mode table by id, or Singleplayer as fallback
function GameMode.Get(modeId)
    return GameMode.Modes[modeId] or GameMode.Modes.Singleplayer
end

return GameMode
