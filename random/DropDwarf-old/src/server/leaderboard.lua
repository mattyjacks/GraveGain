-- DropDwarf: leaderboard.lua
-- Leaderboard management: fastest wins, best depths

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local GameData = require(game.ReplicatedStorage.Shared.game_data)

local Leaderboard = {}

local lbStore = DataStoreService:GetOrderedDataStore("DropDwarfLeaderboard_v1")
local depthStore = DataStoreService:GetOrderedDataStore("DropDwarfDepth_v1")

-- Submit a winning time (lower is better - store as inverted integer ms)
-- We store 999999999 - timeMs so that higher scores = faster times in OrderedDataStore
function Leaderboard.SubmitTime(player, timeSeconds)
    local timeMs = math.floor(timeSeconds * 100) -- centiseconds
    local score = 999999999 - timeMs             -- inverted so fastest = highest
    local key = tostring(player.UserId)
    local success, err = pcall(function()
        lbStore:SetAsync(key, score)
    end)
    if not success then
        warn("[Leaderboard] Failed to submit time:", err)
    end
end

-- Submit a depth record (higher = better, stored directly)
function Leaderboard.SubmitDepth(player, depthMeters)
    local score = math.floor(depthMeters * 10) -- tenths of a meter
    local key = tostring(player.UserId)
    local success, err = pcall(function()
        depthStore:SetAsync(key, score)
    end)
    if not success then
        warn("[Leaderboard] Failed to submit depth:", err)
    end
end

-- Get top N fastest times
function Leaderboard.GetTopTimes(count)
    count = count or GameData.MAX_LEADERBOARD_ENTRIES
    local success, pages = pcall(function()
        return lbStore:GetSortedAsync(false, count)
    end)
    if not success then
        warn("[Leaderboard] Failed to get times:", pages)
        return {}
    end
    local results = {}
    local rank = 1
    local page = pages:GetCurrentPage()
    for _, entry in ipairs(page) do
        local userId = tonumber(entry.key)
        local scoreInverted = entry.value
        local timeMs = 999999999 - scoreInverted
        local timeSeconds = timeMs / 100
        local name = "[Unknown]"
        pcall(function()
            name = Players:GetNameFromUserIdAsync(userId)
        end)
        table.insert(results, {
            rank = rank,
            userId = userId,
            name = name,
            timeSeconds = timeSeconds,
        })
        rank = rank + 1
    end
    return results
end

-- Get top N best depths
function Leaderboard.GetTopDepths(count)
    count = count or GameData.MAX_LEADERBOARD_ENTRIES
    local success, pages = pcall(function()
        return depthStore:GetSortedAsync(false, count)
    end)
    if not success then
        warn("[Leaderboard] Failed to get depths:", pages)
        return {}
    end
    local results = {}
    local rank = 1
    local page = pages:GetCurrentPage()
    for _, entry in ipairs(page) do
        local userId = tonumber(entry.key)
        local depthMeters = entry.value / 10
        local name = "[Unknown]"
        pcall(function()
            name = Players:GetNameFromUserIdAsync(userId)
        end)
        table.insert(results, {
            rank = rank,
            userId = userId,
            name = name,
            depthMeters = depthMeters,
        })
        rank = rank + 1
    end
    return results
end

-- Get absolute rank of a player in the time leaderboard
function Leaderboard.GetPlayerTimeRank(userId, timeSeconds)
    local timeMs = math.floor(timeSeconds * 100)
    local playerScore = 999999999 - timeMs
    local success, pages = pcall(function()
        return lbStore:GetSortedAsync(false, GameData.MAX_LEADERBOARD_ENTRIES)
    end)
    if not success then return nil end
    local rank = 1
    local page = pages:GetCurrentPage()
    for _, entry in ipairs(page) do
        if entry.value >= playerScore then
            rank = rank + 1
        else
            break
        end
    end
    return rank
end

-- Format time as MM:SS.cs
function Leaderboard.FormatTime(timeSeconds)
    local cs = math.floor((timeSeconds % 1) * 100)
    local s = math.floor(timeSeconds) % 60
    local m = math.floor(timeSeconds / 60)
    return string.format("%02d:%02d.%02d", m, s, cs)
end

return Leaderboard
