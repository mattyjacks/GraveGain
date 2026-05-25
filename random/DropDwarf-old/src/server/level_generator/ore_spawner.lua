-- DropDwarf: level_generator/ore_spawner.lua
-- Configurations and spawning of minable wall ore nodes.

local PartBuilders = require(script.Parent.part_builders)

local OreSpawner = {}

local BIOME_ORE = {
    Volcano  = { { name="SulfurVein",  color=Color3.fromRGB(200,180,30),  gold={8,18},  hp=2, glow=Color3.fromRGB(255,220,50) },
                 { name="ObsidianShard", color=Color3.fromRGB(40,20,60),  gold={15,30}, hp=4, glow=Color3.fromRGB(160,80,255) } },
    Fortress = { { name="GoldVein",    color=Color3.fromRGB(220,180,40),  gold={12,25}, hp=3, glow=Color3.fromRGB(255,210,60) },
                 { name="SilverSeam",  color=Color3.fromRGB(190,190,200), gold={8,16},  hp=2, glow=Color3.fromRGB(220,230,255) } },
    Cave     = { { name="GoldVein",    color=Color3.fromRGB(215,175,35),  gold={10,22}, hp=3, glow=Color3.fromRGB(255,205,50) },
                 { name="GemCluster",  color=Color3.fromRGB(80,200,160),  gold={18,35}, hp=5, glow=Color3.fromRGB(100,255,200) } },
    Mine     = { { name="GoldVein",    color=Color3.fromRGB(225,185,40),  gold={14,28}, hp=3, glow=Color3.fromRGB(255,215,60) },
                 { name="CoalSeam",    color=Color3.fromRGB(25,25,30),    gold={4,10},  hp=1, glow=Color3.fromRGB(100,120,180) } },
}

function OreSpawner.SpawnWallOre(parent, side, yPos, halfW, biome, rng)
    local oreList = BIOME_ORE[biome.name]
    if not oreList or #oreList == 0 then return end

    local ore     = oreList[rng:NextInteger(1, #oreList)]
    local goldVal = rng:NextInteger(ore.gold[1], ore.gold[2])
    local depth   = rng:NextNumber(0.8, 2.0)
    local wSize   = rng:NextNumber(2.5, 5.5)
    local hSize   = rng:NextNumber(1.5, 3.5)

    local pos
    local wallX      = halfW - depth / 2
    local slideRange = 60 / 2 - 4
    
    if side == 1 then
        pos = Vector3.new(-wallX, yPos, rng:NextNumber(-slideRange, slideRange))
    elseif side == 2 then
        pos = Vector3.new(wallX, yPos, rng:NextNumber(-slideRange, slideRange))
    elseif side == 3 then
        pos = Vector3.new(rng:NextNumber(-slideRange, slideRange), yPos, -wallX)
    else
        pos = Vector3.new(rng:NextNumber(-slideRange, slideRange), yPos, wallX)
    end

    local sizeX   = (side == 1 or side == 2) and depth or wSize
    local sizeZ   = (side == 3 or side == 4) and depth or wSize
    local oreBody = PartBuilders.MakePart(parent, "WallOre", pos,
        Vector3.new(sizeX, hSize, sizeZ), ore.color, Enum.Material.SmoothPlastic, 0)
    oreBody.CanCollide = false

    local streakDepth = depth + 0.05
    local streakSizeX = (side == 1 or side == 2) and streakDepth or wSize * 0.6
    local streakSizeZ = (side == 3 or side == 4) and streakDepth or wSize * 0.6
    local streak = PartBuilders.MakePart(parent, "OreStreak", pos,
        Vector3.new(streakSizeX, hSize * 0.5, streakSizeZ),
        ore.glow, Enum.Material.Neon, 0.45)
    streak.CanCollide = false

    local pl = Instance.new("PointLight")
    pl.Brightness = 0.4
    pl.Range      = 5
    pl.Color      = ore.glow
    pl.Parent     = oreBody

    local mineTag = Instance.new("StringValue")
    mineTag.Name  = "IsMineable"
    mineTag.Value = ore.name
    mineTag.Parent = oreBody

    local goldTag = Instance.new("IntValue")
    goldTag.Name  = "GoldValue"
    goldTag.Value = goldVal
    goldTag.Parent = oreBody

    local hpTag   = Instance.new("IntValue")
    hpTag.Name    = "OreHp"
    hpTag.Value   = ore.hp
    hpTag.Parent  = oreBody

    local maxHpTag = Instance.new("IntValue")
    maxHpTag.Name  = "OreMaxHp"
    maxHpTag.Value = ore.hp
    maxHpTag.Parent = oreBody

    local streakRef = Instance.new("ObjectValue")
    streakRef.Name  = "OreStreak"
    streakRef.Value = streak
    streakRef.Parent = oreBody

    return oreBody
end

return OreSpawner
