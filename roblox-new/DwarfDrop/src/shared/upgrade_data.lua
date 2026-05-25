-- DwarfDrop: upgrade_data.lua
-- Upgrade definitions, costs, and stat calculations

local UpgradeData = {}

UpgradeData.Upgrades = {
    max_health = {
        id = "max_health",
        displayName = "Max Health",
        icon = "HP",
        description = "Increase your maximum health. Survive longer falls.",
        baseValue = 100,
        perTier = 25,
        costs = { 50, 100, 175, 275, 400, 550, 725, 925, 1150, 1400 },
        maxTier = 10,
        unit = "HP",
    },
    heal_rate = {
        id = "heal_rate",
        displayName = "Regen Rate",
        icon = "REGEN",
        description = "Passively regenerate health per second while not falling.",
        baseValue = 0,
        perTier = 1,
        costs = { 75, 150, 250, 375, 525, 700, 900, 1125, 1375, 1650 },
        maxTier = 10,
        unit = "HP/s",
    },
    move_speed = {
        id = "move_speed",
        displayName = "Move Speed",
        icon = "SPEED",
        description = "Increase walk and sprint speed. Optimize your routes faster.",
        baseValue = 18,
        perTier = 2,
        costs = { 60, 130, 220, 330, 460, 610, 780, 970, 1180, 1410 },
        maxTier = 10,
        unit = "u/s",
    },
    fall_resist = {
        id = "fall_resist",
        displayName = "Fall Resist",
        icon = "RESIST",
        description = "Reduce fall damage taken. Drop further without penalty.",
        baseValue = 0,
        perTier = 0.05,
        costs = { 100, 200, 325, 475, 650, 850, 1075, 1325, 1600, 1900 },
        maxTier = 10,
        unit = "%",
    },
    coin_magnet = {
        id = "coin_magnet",
        displayName = "Coin Magnet",
        icon = "MAGNET",
        description = "Attract nearby coins automatically. Higher tiers pull from farther away.",
        baseValue = 5,
        perTier = 3,
        costs = { 80, 160, 260, 380, 520, 680, 860, 1060, 1280, 1520 },
        maxTier = 10,
        unit = "st",
    },
    double_jump = {
        id = "double_jump",
        displayName = "Double Jump",
        icon = "JUMP",
        description = "Unlock a mid-air jump. Higher tiers give more air launches per fall.",
        baseValue = 0,
        perTier = 1,
        costs = { 150, 280, 440, 630, 850, 1100, 1380, 1690, 2030, 2400 },
        maxTier = 10,
        unit = "x",
    },
}

function UpgradeData.GetValue(upgradeId, tier)
    local upg = UpgradeData.Upgrades[upgradeId]
    if not upg then return 0 end
    tier = math.clamp(tier, 0, upg.maxTier)
    return upg.baseValue + (upg.perTier * tier)
end

function UpgradeData.GetUpgradeCost(upgradeId, currentTier)
    local upg = UpgradeData.Upgrades[upgradeId]
    if not upg then return math.huge end
    local nextTier = currentTier + 1
    if nextTier > upg.maxTier then return math.huge end
    return upg.costs[nextTier]
end

function UpgradeData.GetTotalCost(upgradeId, tier)
    local upg = UpgradeData.Upgrades[upgradeId]
    if not upg then return 0 end
    local total = 0
    for i = 1, math.min(tier, upg.maxTier) do
        total = total + upg.costs[i]
    end
    return total
end

function UpgradeData.DefaultUpgrades()
    return {
        max_health  = 0,
        heal_rate   = 0,
        move_speed  = 0,
        fall_resist = 0,
        coin_magnet = 0,
        double_jump = 0,
    }
end

-- FIX Bug#1: Single canonical ComputeStats - used by player_state_manager only
function UpgradeData.ComputeStats(upgradeTiers)
    local function val(id)
        return UpgradeData.GetValue(id, upgradeTiers[id] or 0)
    end
    return {
        maxHealth    = val("max_health"),
        healRate     = val("heal_rate"),
        walkSpeed    = val("move_speed"),
        sprintSpeed  = val("move_speed") + 10,
        fallResist   = val("fall_resist"),
        coinMagnet   = val("coin_magnet"),
        airJumps     = math.min(3, math.floor(val("double_jump"))),
    }
end

return UpgradeData
