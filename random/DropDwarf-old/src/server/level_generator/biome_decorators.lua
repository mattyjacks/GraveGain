-- DropDwarf: level_generator/biome_decorators.lua
-- Visual environmental components: lava cascades, timber columns, glowing crystals, moving platforms.

local BiomeData    = require(game.ReplicatedStorage.Shared.biome_data)
local GameData     = require(game.ReplicatedStorage.Shared.game_data)
local SeedSystem   = require(game.ReplicatedStorage.Shared.seed_system)
local PartBuilders = require(script.Parent.part_builders)

local BiomeDecorators = {}

function BiomeDecorators.SpawnStalactite(parent, pos, biome, rng)
    local w = rng:NextInteger(2, 5)
    local h = rng:NextInteger(4, 14)
    local col = BiomeData.GetRandomColor(biome, rng)
    local body = PartBuilders.MakePart(parent, "Stalactite", pos, Vector3.new(w, h, w), col)
    
    if biome.name == "Cave" or biome.name == "Volcano" then
        local tipPos = Vector3.new(pos.X, pos.Y - h/2 - 0.5, pos.Z)
        PartBuilders.SpawnGlowBlock(parent, tipPos, Vector3.new(w*0.4, 1, w*0.4), biome.accentColor, 0.8, 6)
    end
    return body
end

function BiomeDecorators.SpawnOreVein(parent, pos, biome, rng)
    local vW = rng:NextInteger(2, 6)
    local vH = rng:NextInteger(1, 3)
    local vD = rng:NextInteger(1, 2)
    local ore = PartBuilders.MakePart(parent, "OreVein", pos, Vector3.new(vW, vH, vD), biome.accentColor, Enum.Material.Neon, 0.1)
    ore.CanCollide = false
    
    local pl = Instance.new("PointLight")
    pl.Brightness = 0.8
    pl.Range = 8
    pl.Color = biome.accentColor
    pl.Parent = ore
    return ore
end

function BiomeDecorators.SpawnPillar(parent, basePos, height, color, material)
    local sections = math.ceil(height / 4)
    for i = 1, sections do
        local w = math.max(2, 5 - i)
        local y = basePos.Y + (i - 0.5) * 4
        PartBuilders.MakePart(parent, "Pillar", Vector3.new(basePos.X, y, basePos.Z),
            Vector3.new(w, 4, w), color, material or Enum.Material.SmoothPlastic)
    end
end

function BiomeDecorators.SpawnRubble(parent, basePos, pW, pD, biome, rng, count)
    count = count or rng:NextInteger(2, 6)
    for i = 1, count do
        local rx = basePos.X + rng:NextNumber(-pW/2 + 1, pW/2 - 1)
        local rz = basePos.Z + rng:NextNumber(-pD/2 + 1, pD/2 - 1)
        local rs = rng:NextNumber(0.5, 2.5)
        local col = BiomeData.GetRandomColor(biome, rng)
        local rb = PartBuilders.MakePart(parent, "Rubble", Vector3.new(rx, basePos.Y + rs/2, rz),
            Vector3.new(rs, rs, rs), col, Enum.Material.SmoothPlastic, 0)
        rb.CanCollide = false
    end
end

-- Generates premium flowing lava pool + glowing steam hazards
function BiomeDecorators.SpawnLavaPool(parent, pos, sizeX, sizeZ, biome)
    local pool = PartBuilders.MakePart(parent, "LavaPool", pos, Vector3.new(sizeX, 0.3, sizeZ),
        biome.lavaColor or Color3.fromRGB(255, 80, 0), Enum.Material.Neon, 0.15)
    pool.CanCollide = true
    
    local tag = Instance.new("StringValue")
    tag.Name = "IsHazard"
    tag.Value = tostring(biome.hazardDamage or 20)
    tag.Parent = pool

    local pl = Instance.new("PointLight")
    pl.Brightness = 3
    pl.Range = 18
    pl.Color = Color3.fromRGB(255, 100, 20)
    pl.Parent = pool

    -- Volumetric heat distortion particles
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "HeatDistort"
    emitter.Rate = 12
    emitter.Speed = NumberRange.new(2, 5)
    emitter.SpreadAngle = Vector2.new(45, 45)
    emitter.Lifetime = NumberRange.new(0.8, 1.5)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(1, 3.5),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(0.5, 0.88),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 120, 60))
    emitter.Parent = pool

    return pool
end

-- Premium lava cascade: pouring down shaft walls
function BiomeDecorators.SpawnLavaCascade(parent, pos, height, biome)
    local cascade = PartBuilders.MakePart(parent, "LavaCascade", pos, Vector3.new(1.8, height, 0.25),
        Color3.fromRGB(255, 65, 0), Enum.Material.Neon, 0.1)
    cascade.CanCollide = false

    local tag = Instance.new("StringValue")
    tag.Name = "IsHazard"
    tag.Value = "15"
    tag.Parent = cascade

    local pl = Instance.new("PointLight")
    pl.Brightness = 3
    pl.Range = 22
    pl.Color = Color3.fromRGB(255, 90, 0)
    pl.Parent = cascade

    -- Texture offset script to animate the flow on client
    local texture = Instance.new("Texture")
    texture.Name = "FlowTexture"
    texture.Texture = "rbxassetid://13854128" -- vertical water/lava ripple line
    texture.Face = Enum.NormalId.Front
    texture.StudsPerTileU = 2
    texture.StudsPerTileV = 10
    texture.Parent = cascade

    -- Emitter at the splash base
    local splasher = PartBuilders.MakePart(parent, "LavaSplashNode", pos - Vector3.new(0, height/2, 0), Vector3.new(1.2, 0.2, 1.2), Color3.new(1,0,0), Enum.Material.Neon, 1)
    splasher.CanCollide = false
    
    local pe = Instance.new("ParticleEmitter")
    pe.Name = "LavaSplash"
    pe.Rate = 35
    pe.Speed = NumberRange.new(4, 9)
    pe.SpreadAngle = Vector2.new(60, 60)
    pe.Lifetime = NumberRange.new(0.5, 0.9)
    pe.Size = NumberSequence.new(0.4, 0.1)
    pe.Transparency = NumberSequence.new(0.1, 0.9)
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 180, 0))
    pe.Acceleration = Vector3.new(0, -22, 0)
    pe.Parent = splasher

    return cascade
end

-- Premium Bracket torch
function BiomeDecorators.SpawnWallTorch(parent, pos)
    local mount = PartBuilders.MakePart(parent, "TorchMount", pos, Vector3.new(0.4, 0.4, 0.6), Color3.fromRGB(80,80,85), Enum.Material.Metal)
    mount.CanCollide = false

    local bracket = PartBuilders.MakePart(parent, "TorchBracket", pos + Vector3.new(0, 0.3, 0.3), Vector3.new(0.2, 0.8, 0.2), Color3.fromRGB(90,85,75), Enum.Material.Metal)
    bracket.CanCollide = false

    local flameNode = PartBuilders.MakePart(parent, "FlameNode", pos + Vector3.new(0, 0.8, 0.3), Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(255, 150, 40), Enum.Material.Neon, 0.25)
    flameNode.CanCollide = false

    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Range = 22
    light.Color = Color3.fromRGB(255, 175, 75)
    light.Parent = flameNode

    -- Fire and smoke emitters
    local fire = Instance.new("ParticleEmitter")
    fire.Name = "TorchFire"
    fire.Rate = 25
    fire.Speed = NumberRange.new(2, 4)
    fire.Lifetime = NumberRange.new(0.4, 0.7)
    fire.Size = NumberSequence.new(0.8, 0.2)
    fire.Color = ColorSequence.new(Color3.fromRGB(255, 120, 30))
    fire.Parent = flameNode

    local smoke = Instance.new("ParticleEmitter")
    smoke.Name = "TorchSmoke"
    smoke.Rate = 12
    smoke.Speed = NumberRange.new(3, 6)
    smoke.Lifetime = NumberRange.new(1.0, 1.6)
    smoke.Size = NumberSequence.new(0.5, 1.8)
    smoke.Transparency = NumberSequence.new(0.4, 1.0)
    smoke.Color = ColorSequence.new(Color3.fromRGB(60,60,60))
    smoke.Parent = flameNode
end

-- Premium pulsating crystals
function BiomeDecorators.SpawnCrystalCluster(parent, basePos, biome, rng, count)
    count = count or rng:NextInteger(2, 5)
    local crystalCol = biome.crystalColor or biome.accentColor
    for i = 1, count do
        local angle  = (i / count) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
        local radius = rng:NextNumber(0.4, 1.8)
        local cx = basePos.X + math.cos(angle) * radius
        local cz = basePos.Z + math.sin(angle) * radius
        local ch = rng:NextInteger(2, 5)
        local cw = rng:NextInteger(1, 2)
        local crystal = PartBuilders.MakePart(parent, "Crystal",
            Vector3.new(cx, basePos.Y + ch/2, cz),
            Vector3.new(cw, ch, cw), crystalCol, Enum.Material.Neon, 0.55)
        
        crystal.CFrame = crystal.CFrame * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25))
        crystal.CanCollide = false
        
        local pl = Instance.new("PointLight")
        pl.Brightness = 0.25
        pl.Range = 4
        pl.Color = crystalCol
        pl.Parent = crystal

        -- Script/marker to pulsate organic brightness on client
        local animTag = Instance.new("BoolValue")
        animTag.Name = "PulsatingCrystal"
        animTag.Value = true
        animTag.Parent = crystal
    end
end

function BiomeDecorators.SpawnMovingPlatform(parent, pos, size, color, biome, rng, seed)
    local cfg = { speed = 4, axis = "X", range = 12 }
    if biome.name == "Volcano" then cfg = { speed = 5, axis = "X", range = 14 }
    elseif biome.name == "Fortress" then cfg = { speed = 3, axis = "Z", range = 18 }
    elseif biome.name == "Cave" then cfg = { speed = 6, axis = "X", range = 12 }
    elseif biome.name == "Mine" then cfg = { speed = 4, axis = "Z", range = 16 }
    end

    local p = PartBuilders.SpawnPlatform(parent, pos, size, color, Enum.Material.SmoothPlastic, PartBuilders.TERRAIN_FIRM)
    p.Name = "MovingPlatform"
    
    local mv = Instance.new("StringValue")
    mv.Name = "MovePlatform"
    mv.Value = string.format("%s,%.2f,%.2f,%.3f,%.3f,%.3f",
        cfg.axis, cfg.speed, cfg.range, pos.X, pos.Y, pos.Z)
    mv.Parent = p

    PartBuilders.SpawnGlowBlock(parent, Vector3.new(pos.X, pos.Y + size.Y/2 + 0.15, pos.Z),
        Vector3.new(size.X * 0.8, 0.3, size.Z * 0.8), biome.accentColor, 1.0, 8)
    return p
end

-- ==================== BIOME CUSTOM STRUCTS ====================

function BiomeDecorators.GenerateCaveSpireSpiral(folder, pX, currentY, pZ, platformIndex, seed)
    local structRng = SeedSystem.ChildRNG(seed .. "CaveSTRUCT", platformIndex)
    local spireCount = structRng:NextInteger(3, 6)
    local spireRadius = structRng:NextNumber(3, 7)
    for arm = 1, spireCount do
        local angle = (arm / spireCount) * math.pi * 2
        local ax = pX + math.cos(angle) * spireRadius
        local az = pZ + math.sin(angle) * spireRadius
        local dropH = structRng:NextInteger(5, 16)
        BiomeDecorators.SpawnStalactite(folder, Vector3.new(ax, currentY + dropH, az), {name="Cave", accentColor=Color3.fromRGB(100,255,200)}, structRng)
    end
end

function BiomeDecorators.GenerateMineTimberBridge(folder, pX, currentY, pZ, platformIndex, seed, endY)
    local structRng = SeedSystem.ChildRNG(seed .. "MineSTRUCT", platformIndex)
    local steps  = structRng:NextInteger(4, 8)
    local stepW  = structRng:NextInteger(4, 8)
    local stepD  = 3
    local stepDrop = structRng:NextNumber(2.5, 5)
    local zigDir = structRng:NextNumber() > 0.5 and 1 or -1
    local woodCol = Color3.fromRGB(
        structRng:NextInteger(90, 130),
        structRng:NextInteger(60, 90),
        structRng:NextInteger(30, 55))
    
    for zi = 1, steps do
        local zx = pX + zigDir * (zi % 2 == 0 and 3 or -3)
        local zz = pZ + (zi - 1) * 3.5
        local zy = currentY - zi * stepDrop
        if zy > endY + 4 then
            PartBuilders.SpawnPlatform(folder,
                Vector3.new(zx, zy, zz),
                Vector3.new(stepW, 2, stepD), woodCol, Enum.Material.Wood, PartBuilders.TERRAIN_FIRM)
            if zi > 1 then
                local midY = zy + stepDrop / 2
                local midX = pX + zigDir * (zi % 2 == 0 and -3 or 3)
                PartBuilders.SpawnWall(folder, Vector3.new(midX, midY, zz - 1.5),
                    Vector3.new(1.5, 1.5, 4), woodCol, Enum.Material.Wood)
            end
        end
    end
end

function BiomeDecorators.GenerateFortressStoneArch(folder, pX, currentY, pZ, platformIndex, seed)
    local structRng = SeedSystem.ChildRNG(seed .. "FortressSTRUCT", platformIndex)
    local archW = structRng:NextInteger(8, 16)
    local archH = structRng:NextInteger(6, 12)
    local archCol = Color3.fromRGB(
        structRng:NextInteger(50, 80),
        structRng:NextInteger(45, 75),
        structRng:NextInteger(35, 60))
        
    PartBuilders.SpawnPlatform(folder, Vector3.new(pX - archW/2, currentY - archH/2, pZ), Vector3.new(3, archH, 3), archCol, Enum.Material.SmoothPlastic, PartBuilders.TERRAIN_HARD)
    PartBuilders.SpawnPlatform(folder, Vector3.new(pX + archW/2, currentY - archH/2, pZ), Vector3.new(3, archH, 3), archCol, Enum.Material.SmoothPlastic, PartBuilders.TERRAIN_HARD)
    PartBuilders.SpawnPlatform(folder, Vector3.new(pX, currentY - 1, pZ), Vector3.new(archW + 3, 2, 4), archCol, Enum.Material.SmoothPlastic, PartBuilders.TERRAIN_HARD)
    
    for ci = 1, 4 do
        local cOffset = -archW/2 + ci * (archW / 4)
        PartBuilders.SpawnWall(folder, Vector3.new(pX + cOffset, currentY + 1.5, pZ), Vector3.new(2, 3, 3), archCol, Enum.Material.SmoothPlastic)
    end
end

function BiomeDecorators.GenerateVolcanoCascadeShelves(folder, pX, currentY, pZ, platformIndex, seed, endY, biome)
    local structRng = SeedSystem.ChildRNG(seed .. "VolcanoSTRUCT", platformIndex)
    local shelfCount = structRng:NextInteger(3, 5)
    local shelfW = structRng:NextInteger(8, 14)
    local shelfDrop = structRng:NextNumber(4, 8)
    
    for sh = 1, shelfCount do
        local shX = pX + structRng:NextNumber(-4, 4)
        local shZ = pZ + sh * 4
        local shY = currentY - sh * shelfDrop
        if shY > endY + 4 then
            PartBuilders.SpawnPlatform(folder,
                Vector3.new(shX, shY, shZ),
                Vector3.new(shelfW, 2, 5),
                BiomeData.GetRandomColor(biome, structRng),
                Enum.Material.SmoothPlastic, PartBuilders.TERRAIN_HARD)
            
            if structRng:NextNumber() < 0.6 then
                BiomeDecorators.SpawnLavaCascade(folder, Vector3.new(shX, shY + shelfDrop*0.5, shZ), shelfDrop, biome)
            end
        end
    end
end

return BiomeDecorators
