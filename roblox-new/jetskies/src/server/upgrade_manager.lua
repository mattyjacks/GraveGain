local UpgradeManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage.Shared.game_data)
local UpgradeData = require(ReplicatedStorage.Shared.upgrade_data)

function UpgradeManager.GetShopData(playerRings, currentUpgrades)
    local shopData = {}
    
    for upgradeType, upgrade in pairs(GameData.Upgrades) do
        local currentTier = currentUpgrades[upgradeType] or 1
        local info = UpgradeData.GetUpgradeInfo(upgradeType, currentTier)
        
        shopData[upgradeType] = {
            name = upgrade.name,
            description = upgrade.description,
            currentTier = currentTier,
            currentValue = info.currentValue,
            nextValue = info.nextValue,
            cost = info.cost,
            canAfford = info.cost and playerRings >= info.cost or false,
            isMaxed = info.isMaxed
        }
    end
    
    return shopData
end

function UpgradeManager.ValidatePurchase(playerRings, currentUpgrades, upgradeType)
    local currentTier = currentUpgrades[upgradeType] or 1
    if currentTier >= 5 then
        return false, "Maximum tier reached"
    end
    
    local cost = UpgradeData.GetCost(upgradeType, currentTier)
    if not cost then
        return false, "Maximum tier reached"
    end
    
    if playerRings < cost then
        return false, "Not enough rings"
    end
    
    return true, nil
end

return UpgradeManager
