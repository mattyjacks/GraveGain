-- DropDwarf: seed_system.lua
-- Deterministic seeded RNG for reproducible level generation

local SeedSystem = {}

-- Convert a string seed to a numeric seed using djb2 hash
function SeedSystem.StringToSeed(str)
    if type(str) == "number" then return math.floor(str) end
    local hash = 5381
    for i = 1, #str do
        local c = string.byte(str, i)
        hash = ((hash * 33) + c) % 2147483647
    end
    return hash
end

-- Create a deterministic Random object from a seed + optional sub-seed string
-- Sub-seeds allow different systems to derive independent RNGs from the same root seed
function SeedSystem.NewRNG(seed, subSeed)
    local numeric = SeedSystem.StringToSeed(seed)
    if subSeed then
        local sub = SeedSystem.StringToSeed(subSeed)
        -- XOR mix
        numeric = (numeric * 1664525 + sub) % 2147483647
        if numeric <= 0 then numeric = numeric + 2147483646 end
    end
    return Random.new(numeric)
end

-- Derive a child RNG at a specific index (for per-platform generation)
-- rng: parent Random, index: integer
function SeedSystem.ChildRNG(parentSeed, index)
    local childSeed = SeedSystem.StringToSeed(tostring(parentSeed) .. "_" .. tostring(index))
    return Random.new(childSeed)
end

-- Shuffle an array deterministically
function SeedSystem.Shuffle(arr, rng)
    local result = {}
    for _, v in ipairs(arr) do table.insert(result, v) end
    for i = #result, 2, -1 do
        local j = rng:NextInteger(1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

-- Weighted random pick: weights table {item, weight}
function SeedSystem.WeightedPick(choices, rng)
    local total = 0
    for _, c in ipairs(choices) do
        total = total + c.weight
    end
    local roll = rng:NextNumber() * total
    local acc = 0
    for _, c in ipairs(choices) do
        acc = acc + c.weight
        if roll <= acc then return c.item end
    end
    return choices[#choices].item
end

return SeedSystem
