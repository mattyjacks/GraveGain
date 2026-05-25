-- DwarfDrop: player_data.lua
-- Server-side player data with DataStore persistence

local DataStoreService = game:GetService("DataStoreService")
local UpgradeData      = require(game.ReplicatedStorage.Shared.upgrade_data)

local PlayerData = {}

local DATASTORE_KEY = "DwarfDrop_v1"
local SAVE_INTERVAL = 60  -- auto-save every 60 seconds
local MAX_RETRIES   = 3

local store = nil
local cache = {}  -- [userId] = data table

-- FIX Bug#6: guard DataStore availability (e.g. in Studio without API access)
local storeAvailable = false
local ok, err = pcall(function()
    store = DataStoreService:GetDataStore(DATASTORE_KEY)
    storeAvailable = true
end)
if not ok then
    warn("[PlayerData] DataStore unavailable:", err)
end

local function defaultData()
    return {
        gold      = 0,
        upgrades  = UpgradeData.DefaultUpgrades(),
        bestTime  = nil,     -- seconds (nil = no run completed)
        bestDepth = 0,       -- meters
        totalRuns = 0,
        lastSeed  = "MattyJacks",
        defaultCamera = "fps",
    }
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Load with retry
function PlayerData.Load(player)
    local userId = player.UserId
    if cache[userId] then return cache[userId] end

    local data = nil
    if storeAvailable then
        for attempt = 1, MAX_RETRIES do
            local success, result = pcall(function()
                return store:GetAsync(tostring(userId))
            end)
            if success then
                data = result
                break
            else
                warn(string.format("[PlayerData] Load attempt %d failed for %d: %s", attempt, userId, result))
                task.wait(1)
            end
        end
    end

    if data == nil then
        data = defaultData()
    else
        -- Merge missing keys from default
        local def = defaultData()
        for k, v in pairs(def) do
            if data[k] == nil then
                data[k] = v
            end
        end
        -- Merge missing upgrade keys
        for k, v in pairs(def.upgrades) do
            if data.upgrades[k] == nil then
                data.upgrades[k] = v
            end
        end
    end

    cache[userId] = data
    return data
end

-- Save with retry
function PlayerData.Save(player)
    local userId = player.UserId
    local data = cache[userId]
    if not data then return end
    if not storeAvailable then return end

    for attempt = 1, MAX_RETRIES do
        local success, err2 = pcall(function()
            store:SetAsync(tostring(userId), data)
        end)
        if success then
            return
        else
            warn(string.format("[PlayerData] Save attempt %d failed for %d: %s", attempt, userId, err2))
            task.wait(1)
        end
    end
end

function PlayerData.Get(player)
    return cache[player.UserId]
end

function PlayerData.Unload(player)
    PlayerData.Save(player)
    cache[player.UserId] = nil
end

-- Gold operations
function PlayerData.AddGold(player, amount)
    local data = cache[player.UserId]
    if not data then return end
    data.gold = math.max(0, data.gold + amount)
end

function PlayerData.SpendGold(player, amount)
    local data = cache[player.UserId]
    if not data then return false end
    if data.gold < amount then return false end
    data.gold = data.gold - amount
    return true
end

-- Upgrade purchase
function PlayerData.PurchaseUpgrade(player, upgradeId)
    local data = cache[player.UserId]
    if not data then return false, "no_data" end

    local currentTier = data.upgrades[upgradeId] or 0
    local cost = UpgradeData.GetUpgradeCost(upgradeId, currentTier)
    if cost == math.huge then return false, "maxed" end
    if data.gold < cost then return false, "no_gold" end

    data.gold = data.gold - cost
    data.upgrades[upgradeId] = currentTier + 1
    return true, nil
end

-- Record a completed run
function PlayerData.RecordRun(player, timeSeconds, depthMeters)
    local data = cache[player.UserId]
    if not data then return end
    data.totalRuns = (data.totalRuns or 0) + 1
    -- Best time: lower is better (only if completed to bottom)
    if depthMeters >= 1000 then
        if data.bestTime == nil or timeSeconds < data.bestTime then
            data.bestTime = timeSeconds
        end
    end
    if depthMeters > (data.bestDepth or 0) then
        data.bestDepth = depthMeters
    end
end

function PlayerData.SetLastSeed(player, seed)
    local data = cache[player.UserId]
    if not data then return end
    data.lastSeed = seed
end

function PlayerData.SetCameraPreference(player, camType)
    local data = cache[player.UserId]
    if not data then return end
    data.defaultCamera = camType
end

return PlayerData
