-- DwarfDrop: seed_system.lua
-- Deterministic seeded RNG for reproducible procedural generation

local SeedSystem = {}

-- djb2 hash: converts string to a stable integer seed
local function StringToSeed(str)
    local hash = 5381
    for i = 1, #str do
        local c = string.byte(str, i)
        hash = (hash * 33 + c) % (2^31 - 1)
    end
    return math.max(1, hash)
end

SeedSystem.StringToSeed = StringToSeed

-- Create a new RNG object from a seed string (plus optional sub-seed string)
function SeedSystem.NewRNG(seed, subSeed)
    local n
    if type(seed) == "number" then
        n = math.max(1, math.floor(seed))
    else
        n = StringToSeed(tostring(seed))
    end
    if subSeed then
        n = StringToSeed(tostring(n) .. "_" .. tostring(subSeed))
    end

    local rng = Random.new(n)
    local obj = {}

    function obj:NextNumber(min, max)
        if min and max then
            return rng:NextNumber(min, max)
        end
        return rng:NextNumber()
    end

    function obj:NextInteger(min, max)
        return rng:NextInteger(min, max)
    end

    -- Derive a child RNG from this one using a string key (does not consume parent state)
    function obj:Child(key)
        return SeedSystem.NewRNG(tostring(n) .. "_" .. tostring(key))
    end

    return obj
end

-- Fisher-Yates shuffle using a given RNG object (mutates array in place)
function SeedSystem.Shuffle(arr, rng)
    for i = #arr, 2, -1 do
        local j = rng:NextInteger(1, i)
        arr[i], arr[j] = arr[j], arr[i]
    end
    return arr
end

-- Weighted random pick: weights is a parallel array of numbers
-- Returns the index chosen
function SeedSystem.WeightedPick(weights, rng)
    local total = 0
    for _, w in ipairs(weights) do
        total = total + w
    end
    local r = rng:NextNumber(0, total)
    local cumulative = 0
    for i, w in ipairs(weights) do
        cumulative = cumulative + w
        if r <= cumulative then
            return i
        end
    end
    return #weights
end

return SeedSystem
