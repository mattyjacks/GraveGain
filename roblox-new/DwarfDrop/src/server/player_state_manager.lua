-- DwarfDrop: player_state_manager.lua
-- FIX Bug#1: Single source of truth for applying stats to a player character.
-- All code that was previously calling its own applyStats now calls this module.

local Players    = game:GetService("Players")
local Networking = require(game.ReplicatedStorage.Shared.networking)
local UpgradeData = require(game.ReplicatedStorage.Shared.upgrade_data)
local ItemData   = require(game.ReplicatedStorage.Shared.item_data)

local PlayerStateManager = {}

-- Apply computed stats to a live character's Humanoid
-- stats = UpgradeData.ComputeStats(upgradeTiers)
function PlayerStateManager.ApplyStatsToCharacter(player, stats)
    if not stats then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.MaxHealth  = stats.maxHealth  or 100
    hum.Health     = math.min(hum.Health, hum.MaxHealth)
    hum.WalkSpeed  = stats.walkSpeed  or 18
    hum.JumpPower  = 50
end

-- Full stat-push: compute stats, apply to character, fire StatsUpdate to client
-- backpack = optional slot array for weight calculation
function PlayerStateManager.PushStats(player, upgradeTiers, backpack)
    local stats = UpgradeData.ComputeStats(upgradeTiers)

    -- Weight modification
    local weightSpeedMult = 1.0
    local weightFallMult  = 1.0
    if backpack then
        local totalKg = ItemData.ComputeWeight(backpack)
        weightSpeedMult, weightFallMult = ItemData.WeightToMultipliers(totalKg)
        stats.weightSpeedMult = weightSpeedMult
        stats.weightFallMult  = weightFallMult
        stats.weightKg        = totalKg
    end

    PlayerStateManager.ApplyStatsToCharacter(player, stats)

    -- Send to client
    Networking.FireClient(Networking.Events.StatsUpdate, player, stats)

    -- Send weight info
    if backpack then
        Networking.FireClient(Networking.Events.WeightUpdate, player, {
            totalKg   = stats.weightKg or 0,
            speedMult = weightSpeedMult,
            fallMult  = weightFallMult,
        })
    end

    return stats
end

return PlayerStateManager
