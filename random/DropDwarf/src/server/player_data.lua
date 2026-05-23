-- DropDwarf: player_data.lua
-- Server-side player data management (gold, upgrades, best times)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local UpgradeData = require(game.ReplicatedStorage.Shared.upgrade_data)

local PlayerData = {}
PlayerData.__index = PlayerData

local DATA_KEY_PREFIX = "DD_Player_v1_"
local dataStore = nil
local ok, err = pcall(function()
    dataStore = DataStoreService:GetDataStore("DropDwarfPlayerData_v1")
end)
if not ok then
    warn("[PlayerData] DataStore unavailable (Studio without API access):", err)
end

-- In-memory cache keyed by Player
local cache = {}

local function defaultData()
    return {
        gold = 0,
        totalGoldEarned = 0,
        upgrades = UpgradeData.DefaultUpgrades(),
        bestTime = nil,         -- seconds (nil = never completed)
        bestDepth = 0,          -- meters (best depth reached before dying or winning)
        totalRuns = 0,
        wins = 0,
        lastSeed = "12345",
    }
end

-- Load from DataStore (with retry)
local function loadData(player)
    if not dataStore then return defaultData() end
    local key = DATA_KEY_PREFIX .. player.UserId
    local success, data = pcall(function()
        return dataStore:GetAsync(key)
    end)
    if success and data then
        local def = defaultData()
        for k, v in pairs(def) do
            if data[k] == nil then data[k] = v end
        end
        for k, v in pairs(def.upgrades) do
            if data.upgrades[k] == nil then data.upgrades[k] = v end
        end
        return data
    else
        if not success then
            warn("[PlayerData] Failed to load data for", player.Name, data)
        end
        return defaultData()
    end
end

-- Save to DataStore
local function saveData(player)
    if not dataStore then return end
    local data = cache[player]
    if not data then return end
    local key = DATA_KEY_PREFIX .. player.UserId
    local success, err = pcall(function()
        dataStore:SetAsync(key, data)
    end)
    if not success then
        warn("[PlayerData] Failed to save data for", player.Name, err)
    end
end

-- Initialize player on join
function PlayerData.OnPlayerAdded(player)
    local data = loadData(player)
    cache[player] = data
    return data
end

-- Cleanup on leave
function PlayerData.OnPlayerRemoving(player)
    saveData(player)
    cache[player] = nil
end

-- Get cached data
function PlayerData.Get(player)
    return cache[player]
end

-- Add gold
function PlayerData.AddGold(player, amount)
    local data = cache[player]
    if not data then return end
    data.gold = data.gold + amount
    data.totalGoldEarned = data.totalGoldEarned + amount
end

-- Spend gold (returns true if successful)
function PlayerData.SpendGold(player, amount)
    local data = cache[player]
    if not data then return false end
    if data.gold < amount then return false end
    data.gold = data.gold - amount
    return true
end

-- Purchase upgrade (returns true if successful)
function PlayerData.PurchaseUpgrade(player, upgradeId)
    local data = cache[player]
    if not data then return false, "No data" end
    local upg = UpgradeData.Upgrades[upgradeId]
    if not upg then return false, "Invalid upgrade" end
    local currentTier = data.upgrades[upgradeId] or 0
    if currentTier >= upg.maxTier then return false, "Max tier reached" end
    local cost = UpgradeData.GetUpgradeCost(upgradeId, currentTier)
    if data.gold < cost then return false, "Not enough gold" end
    data.gold = data.gold - cost
    data.upgrades[upgradeId] = currentTier + 1
    return true, "Success"
end

-- Record run result
function PlayerData.RecordRun(player, depthMeters, timeSeconds, won)
    local data = cache[player]
    if not data then return end
    data.totalRuns = data.totalRuns + 1
    if depthMeters > data.bestDepth then
        data.bestDepth = depthMeters
    end
    if won then
        data.wins = data.wins + 1
        if data.bestTime == nil or timeSeconds < data.bestTime then
            data.bestTime = timeSeconds
        end
    end
    saveData(player)
end

-- Set last seed
function PlayerData.SetLastSeed(player, seed)
    local data = cache[player]
    if data then data.lastSeed = tostring(seed) end
end

-- Force save (e.g., on milestone)
function PlayerData.Save(player)
    saveData(player)
end

return PlayerData
