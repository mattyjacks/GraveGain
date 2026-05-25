-- DwarfDrop: timed_seeds.lua
-- Hourly, Daily, Weekly seeds based on EST timestamps

local TimedSeeds = {}

local EST_OFFSET = -5  -- EST is UTC-5 (no DST handling; close enough for seeds)

local function getESTTime()
    local utc = os.time()
    return utc + (EST_OFFSET * 3600)
end

local function pad(n)
    return n < 10 and ("0" .. n) or tostring(n)
end

function TimedSeeds.GetHourly()
    local t = getESTTime()
    local date = os.date("!*t", t)
    local seed = string.format("HOURLY_%04d%02d%02d_%02d",
        date.year, date.month, date.day, date.hour)
    local countdown = 3600 - (t % 3600)
    return { label = "Hourly Seed", seed = seed, countdown = countdown }
end

function TimedSeeds.GetDaily()
    local t = getESTTime()
    local date = os.date("!*t", t)
    local seed = string.format("DAILY_%04d%02d%02d",
        date.year, date.month, date.day)
    local secondsInDay = (date.hour * 3600) + (date.min * 60) + date.sec
    local countdown = 86400 - secondsInDay
    return { label = "Daily Seed", seed = seed, countdown = countdown }
end

function TimedSeeds.GetWeekly()
    local t = getESTTime()
    local date = os.date("!*t", t)
    -- Week number based on year + ISO week
    local dayOfYear = math.floor((t - os.time{year=date.year, month=1, day=1, hour=0}) / 86400) + 1
    local week = math.floor(dayOfYear / 7)
    local seed = string.format("WEEKLY_%04d_W%02d", date.year, week)
    local dayOfWeek = date.wday  -- 1=Sunday
    local secondsIntoWeek = ((dayOfWeek - 1) * 86400)
        + (date.hour * 3600) + (date.min * 60) + date.sec
    local countdown = (7 * 86400) - secondsIntoWeek
    return { label = "Weekly Seed", seed = seed, countdown = countdown }
end

function TimedSeeds.GetAll()
    return {
        TimedSeeds.GetHourly(),
        TimedSeeds.GetDaily(),
        TimedSeeds.GetWeekly(),
    }
end

function TimedSeeds.FormatCountdown(seconds)
    local s = math.floor(seconds)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return pad(h) .. "h " .. pad(m) .. "m"
    elseif m > 0 then
        return pad(m) .. "m " .. pad(sec) .. "s"
    else
        return pad(sec) .. "s"
    end
end

return TimedSeeds
