local UpgradeData = {}
local GameData = require(script.Parent:WaitForChild("game_data"))

function UpgradeData.CalculateStat(upgradeType, tier)
    local upgrade = GameData.Upgrades[upgradeType]
    if not upgrade then return 0 end
    
    return upgrade.baseValue + (upgrade.increment * (tier - 1))
end

function UpgradeData.GetCost(upgradeType, currentTier)
    if currentTier >= 5 then return nil end
    
    local nextTier = currentTier + 1
    local tierData = GameData.UpgradeTiers[nextTier]
    
    return tierData and tierData.cost or nil
end

function UpgradeData.CanAfford(playerRings, upgradeType, currentTier)
    local cost = UpgradeData.GetCost(upgradeType, currentTier)
    if not cost then return false end
    
    return playerRings >= cost
end

function UpgradeData.GetUpgradeInfo(upgradeType, tier)
    local upgrade = GameData.Upgrades[upgradeType]
    if not upgrade then return nil end
    
    local currentValue = UpgradeData.CalculateStat(upgradeType, tier)
    local nextValue = UpgradeData.CalculateStat(upgradeType, tier + 1)
    local cost = UpgradeData.GetCost(upgradeType, tier)
    
    return {
        name = upgrade.name,
        description = upgrade.description,
        currentTier = tier,
        currentValue = currentValue,
        nextValue = nextValue,
        cost = cost,
        maxTier = 5,
        isMaxed = tier >= 5
    }
end

function UpgradeData.GetAllUpgradeInfo(playerData)
    local info = {}
    
    for upgradeType, _ in pairs(GameData.Upgrades) do
        local tier = playerData.upgrades[upgradeType] or 0
        info[upgradeType] = UpgradeData.GetUpgradeInfo(upgradeType, tier)
    end
    
    return info
end

function UpgradeData.ComputeFinalStats(baseStats, upgradeTiers)
    return {
        speed = UpgradeData.CalculateStat("SPEED", upgradeTiers.SPEED or 1),
        boostCapacity = UpgradeData.CalculateStat("BOOST", upgradeTiers.BOOST or 1),
        handling = UpgradeData.CalculateStat("HANDLING", upgradeTiers.HANDLING or 1)
    }
end

return UpgradeData
