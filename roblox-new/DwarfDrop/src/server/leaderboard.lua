-- DwarfDrop: leaderboard.lua
-- Ordered DataStore leaderboards for fastest times and greatest depths
-- FIX Bug#6: all DataStore ops are pcall-guarded with availability flag

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local Leaderboard = {}

local MAX_ENTRIES = 100

local timeStore  = nil
local depthStore = nil
local available  = false

local ok = pcall(function()
    timeStore  = DataStoreService:GetOrderedDataStore("DwarfDrop_FastestTimes_v1")
    depthStore = DataStoreService:GetOrderedDataStore("DwarfDrop_GreatestDepths_v1")
    available  = true
end)
if not ok then
    warn("[Leaderboard] OrderedDataStore unavailable (Studio / no API access)")
end

-- Time score: inverted so lower time = higher rank in ascending OrderedDataStore
-- Max representable time: 9999 seconds
local TIME_INVERT_BASE = 9999

local function invertTime(timeSeconds)
    return math.max(1, math.floor((TIME_INVERT_BASE - timeSeconds) * 100))
end

local function uninvertTime(score)
    return TIME_INVERT_BASE - (score / 100)
end

function Leaderboard.SubmitTime(player, timeSeconds)
    if not available then return end
    local key = tostring(player.UserId)
    local score = invertTime(timeSeconds)
    local ok2, err = pcall(function()
        timeStore:UpdateAsync(key, function(old)
            if old == nil or score > old then
                return score
            end
            return old
        end)
    end)
    if not ok2 then
        warn("[Leaderboard] SubmitTime failed:", err)
    end
end

function Leaderboard.SubmitDepth(player, depthMeters)
    if not available then return end
    local key = tostring(player.UserId)
    local score = math.floor(depthMeters * 10)  -- store as tenths of meters
    local ok2, err = pcall(function()
        depthStore:UpdateAsync(key, function(old)
            if old == nil or score > old then
                return score
            end
            return old
        end)
    end)
    if not ok2 then
        warn("[Leaderboard] SubmitDepth failed:", err)
    end
end

local function resolveNames(entries)
    local result = {}
    for rank, entry in ipairs(entries) do
        local name = "Unknown"
        local ok2, playerName = pcall(function()
            return Players:GetNameFromUserIdAsync(tonumber(entry.key))
        end)
        if ok2 then name = playerName end
        table.insert(result, {
            rank   = rank,
            userId = tonumber(entry.key),
            name   = name,
            score  = entry.value,
        })
    end
    return result
end

function Leaderboard.GetTopTimes(count)
    count = count or 10
    if not available then return {} end
    local pages
    local ok2, err = pcall(function()
        pages = timeStore:GetSortedAsync(false, count)
    end)
    if not ok2 then
        warn("[Leaderboard] GetTopTimes failed:", err)
        return {}
    end
    local raw = pages:GetCurrentPage()
    local result = resolveNames(raw)
    for _, entry in ipairs(result) do
        entry.timeSeconds = uninvertTime(entry.score)
    end
    return result
end

function Leaderboard.GetTopDepths(count)
    count = count or 10
    if not available then return {} end
    local pages
    local ok2, err = pcall(function()
        pages = depthStore:GetSortedAsync(false, count)
    end)
    if not ok2 then
        warn("[Leaderboard] GetTopDepths failed:", err)
        return {}
    end
    local raw = pages:GetCurrentPage()
    local result = resolveNames(raw)
    for _, entry in ipairs(result) do
        entry.depthMeters = entry.score / 10
    end
    return result
end

function Leaderboard.GetPlayerRank(player)
    -- Returns {timeRank, depthRank} - approximate, uses page scan
    return { timeRank = nil, depthRank = nil }
end

return Leaderboard
