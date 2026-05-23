-- DropDwarf: timed_seeds.lua
-- Hourly, Daily, Weekly seeds based on EST timestamps
-- EST = UTC-5 (standard) / EDT = UTC-4 (daylight saving)
-- We use a fixed offset of -5 hours (UTC-5) for simplicity/consistency across seasons.
-- Weekly reset: Saturday at 11:59 PM EST (start of Sunday = 0:00 Sun = 86400 * day boundary)

local TimedSeeds = {}

-- EST offset in seconds: UTC-5 = -18000 seconds
local EST_OFFSET_SECONDS = -18000

-- Get current UTC timestamp (tick() is seconds since epoch on Roblox server)
-- On client, os.time() returns UTC seconds since Unix epoch
local function getUTCTime()
    return os.time()
end

-- Convert UTC timestamp to EST timestamp
local function toEST(utcTime)
    return utcTime + EST_OFFSET_SECONDS
end

-- Get the hourly seed: resets at the start of each hour in EST
-- Format: "hourly_YYYYMMDDHH" for readability + uniqueness
function TimedSeeds.GetHourlySeed()
    local estTime = toEST(getUTCTime())
    local hourBucket = math.floor(estTime / 3600) -- unique per hour
    -- Format as a readable string
    local t = os.date("*t", estTime)
    local label = string.format("hourly_%04d%02d%02d%02d", t.year, t.month, t.day, t.hour)
    return label, hourBucket
end

-- Get the daily seed: resets at midnight EST
-- Format: "daily_YYYYMMDD"
function TimedSeeds.GetDailySeed()
    local estTime = toEST(getUTCTime())
    local dayBucket = math.floor(estTime / 86400) -- unique per day
    local t = os.date("*t", estTime)
    local label = string.format("daily_%04d%02d%02d", t.year, t.month, t.day)
    return label, dayBucket
end

-- Get the weekly seed: resets Saturday at 11:59 PM EST (i.e., week starts Sunday 00:00 EST)
-- wday: 1=Sunday, 2=Monday ... 7=Saturday in Lua
-- We find the most recent Sunday 00:00 EST
function TimedSeeds.GetWeeklySeed()
    local estTime = toEST(getUTCTime())
    local t = os.date("*t", estTime)
    -- wday: 1=Sun, 7=Sat. Days since last Sunday:
    local daysSinceSunday = (t.wday - 1) -- 0 on Sunday, 6 on Saturday
    -- Seconds since start of this day (midnight EST)
    local secondsToday = (t.hour * 3600) + (t.min * 60) + t.sec
    -- Start of this week (Sunday midnight EST) in EST time
    local weekStartEST = estTime - (daysSinceSunday * 86400) - secondsToday
    local weekBucket = math.floor(weekStartEST / 86400)
    -- Generate a label: "weekly_YYYYMMDD" (the Sunday date)
    local ts = os.date("*t", weekStartEST)
    local label = string.format("weekly_%04d%02d%02d", ts.year, ts.month, ts.day)
    return label, weekBucket
end

-- Get seconds remaining until next hour reset (EST)
function TimedSeeds.SecondsUntilNextHour()
    local estTime = toEST(getUTCTime())
    local secondsIntoHour = estTime % 3600
    return 3600 - secondsIntoHour
end

-- Get seconds remaining until next day reset (midnight EST)
function TimedSeeds.SecondsUntilNextDay()
    local estTime = toEST(getUTCTime())
    local secondsIntoDay = estTime % 86400
    return 86400 - secondsIntoDay
end

-- Get seconds remaining until next week reset (Sunday midnight EST)
function TimedSeeds.SecondsUntilNextWeek()
    local estTime = toEST(getUTCTime())
    local t = os.date("*t", estTime)
    local daysSinceSunday = (t.wday - 1)
    local secondsToday = (t.hour * 3600) + (t.min * 60) + t.sec
    local secondsIntoWeek = (daysSinceSunday * 86400) + secondsToday
    return (7 * 86400) - secondsIntoWeek
end

-- Format seconds as HH:MM:SS
function TimedSeeds.FormatCountdown(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh %02dm %02ds", h, m, s)
    else
        return string.format("%dm %02ds", m, s)
    end
end

-- Get all three timed seeds as a table for UI display
function TimedSeeds.GetAll()
    local hourSeed, _ = TimedSeeds.GetHourlySeed()
    local daySeed,  _ = TimedSeeds.GetDailySeed()
    local weekSeed, _ = TimedSeeds.GetWeeklySeed()
    return {
        { label = "Hourly Seed",  seed = hourSeed,  countdown = TimedSeeds.SecondsUntilNextHour() },
        { label = "Daily Seed",   seed = daySeed,   countdown = TimedSeeds.SecondsUntilNextDay() },
        { label = "Weekly Seed",  seed = weekSeed,  countdown = TimedSeeds.SecondsUntilNextWeek() },
    }
end

return TimedSeeds
