-- DropDwarf: level_generator/init.lua
-- Main procedural level generator entry point.
-- Manages session-isolated folders and dynamic seeded chunk loading.

local GameData       = require(game.ReplicatedStorage.Shared.game_data)
local BiomeData      = require(game.ReplicatedStorage.Shared.biome_data)
local SeedSystem     = require(game.ReplicatedStorage.Shared.seed_system)
local PartBuilders   = require(script.part_builders)
local DwarvenBasket  = require(script.dwarven_basket)
local BiomeDecorators = require(script.biome_decorators)
local OreSpawner     = require(script.ore_spawner)

local LevelGenerator = {}

-- Expose part builder references for external consumption
LevelGenerator.PartBuilders = PartBuilders

-- Create or clean up a session folder
function LevelGenerator.CreateSessionFolder(sessionId)
    local levelsFolder = workspace:FindFirstChild("Levels")
    if not levelsFolder then
        levelsFolder = Instance.new("Folder")
        levelsFolder.Name = "Levels"
        levelsFolder.Parent = workspace
    end

    local name = "Session_" .. tostring(sessionId)
    local existing = levelsFolder:FindFirstChild(name)
    if existing then existing:Destroy() end

    local sessionFolder = Instance.new("Folder")
    sessionFolder.Name = name
    sessionFolder.Parent = levelsFolder

    -- Create slots subdirectory
    local slotsFolder = Instance.new("Folder")
    slotsFolder.Name = "Slots"
    slotsFolder.Parent = sessionFolder

    return sessionFolder
end

-- Generate a single slot (100m chunk) deterministically
function LevelGenerator.GenerateSlot(sessionFolder, slotIndex, seed)
    print("[DropDwarf LevelGen] Generating slot", slotIndex)
    local slotsFolder = sessionFolder:WaitForChild("Slots")
    local slotName = "Slot_" .. slotIndex
    
    local existing = slotsFolder:FindFirstChild(slotName)
    if existing then existing:Destroy() end

    local slotModel = Instance.new("Model")
    slotModel.Name = slotName
    slotModel.Parent = slotsFolder

    local seedStr = tostring(seed)
    local biomeSequence = BiomeData.GenerateSequence(seedStr)
    local biome = biomeSequence[slotIndex]
    if not biome then return nil, {} end

    local slotStartMeters = (slotIndex - 1) * GameData.SLOT_DEPTH_METERS
    local slotEndMeters   = slotIndex * GameData.SLOT_DEPTH_METERS
    
    local startY = GameData.DepthToWorldY(slotStartMeters)
    local endY   = GameData.DepthToWorldY(slotEndMeters)
    local totalStuds = startY - endY
    local halfW  = GameData.LEVEL_WIDTH / 2 + 4
    local wallThick = 10
    local wallCenterY = startY - totalStuds / 2
    local rng = SeedSystem.NewRNG(seedStr, biome.name .. "_slot" .. slotIndex)

    -- Biome marker boundary
    PartBuilders.SpawnBiomeMarker(slotModel, startY, biome.name, biome.accentColor)

    -- ==== MULTI-LAYER WALLS ====
    local biomeMat = PartBuilders.GetBiomeMat(biome)
    local wallColors = biome.wallColors or {
        BiomeData.GetRandomColor(biome, rng),
        BiomeData.GetRandomColor(biome, rng),
        BiomeData.GetRandomColor(biome, rng),
        BiomeData.GetRandomColor(biome, rng),
    }

    local wallDirs = {
        { pos = Vector3.new(-halfW - wallThick/2, wallCenterY, 0),
          size = Vector3.new(wallThick, totalStuds, GameData.LEVEL_WIDTH + wallThick*2) },
        { pos = Vector3.new(halfW  + wallThick/2, wallCenterY, 0),
          size = Vector3.new(wallThick, totalStuds, GameData.LEVEL_WIDTH + wallThick*2) },
        { pos = Vector3.new(0, wallCenterY, -halfW - wallThick/2),
          size = Vector3.new(GameData.LEVEL_WIDTH + wallThick*2, totalStuds, wallThick) },
        { pos = Vector3.new(0, wallCenterY,  halfW + wallThick/2),
          size = Vector3.new(GameData.LEVEL_WIDTH + wallThick*2, totalStuds, wallThick) },
    }

    for i, wd in ipairs(wallDirs) do
        PartBuilders.SpawnWall(slotModel, wd.pos, wd.size, wallColors[((i-1)%#wallColors)+1], biomeMat)
    end

    -- Wall details & structures
    local slabInterval = 20
    local slabY = startY - slabInterval / 2
    while slabY > endY do
        for side = 1, 4 do
            if rng:NextNumber() < 0.55 then
                local sW = rng:NextInteger(3, 10)
                local sH = rng:NextInteger(2, 8)
                local sD = rng:NextInteger(2, 5)
                local sColor = BiomeData.GetRandomColor(biome, rng)
                local sY = slabY + rng:NextNumber(-4, 4)
                
                if side == 1 then
                    local sPos = Vector3.new(-halfW + sD/2, sY, rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW))
                    PartBuilders.SpawnWall(slotModel, sPos, Vector3.new(sD, sH, sW), sColor, biomeMat)
                elseif side == 2 then
                    local sPos = Vector3.new(halfW - sD/2, sY, rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW))
                    PartBuilders.SpawnWall(slotModel, sPos, Vector3.new(sD, sH, sW), sColor, biomeMat)
                elseif side == 3 then
                    local sPos = Vector3.new(rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW), sY, -halfW + sD/2)
                    PartBuilders.SpawnWall(slotModel, sPos, Vector3.new(sW, sH, sD), sColor, biomeMat)
                else
                    local sPos = Vector3.new(rng:NextNumber(-GameData.LEVEL_WIDTH/2+sW, GameData.LEVEL_WIDTH/2-sW), sY, halfW - sD/2)
                    PartBuilders.SpawnWall(slotModel, sPos, Vector3.new(sW, sH, sD), sColor, biomeMat)
                end
            end
        end
        
        -- High production touches: place wall bracket torches
        if biome.name == "Fortress" and rng:NextNumber() < 0.25 then
            local torchSide = rng:NextInteger(1, 4)
            local torchY = slabY + rng:NextNumber(-4, 4)
            local torchX = torchSide == 1 and (-halfW + 0.5) or (torchSide == 2 and (halfW - 0.5) or rng:NextNumber(-halfW+2, halfW-2))
            local torchZ = torchSide == 3 and (-halfW + 0.5) or (torchSide == 4 and (halfW - 0.5) or rng:NextNumber(-halfW+2, halfW-2))
            BiomeDecorators.SpawnWallTorch(slotModel, Vector3.new(torchX, torchY, torchZ))
        end

        slabY = slabY - slabInterval
    end

    -- Biome details
    if biome.name == "Volcano" then
        -- Flowing lava cascades
        for si = 1, 4 do
            local casY = startY - rng:NextNumber(10, totalStuds - 10)
            local casSide = rng:NextInteger(1, 4)
            local cX = casSide == 1 and (-halfW + 0.5) or (casSide == 2 and (halfW - 0.5) or rng:NextNumber(-halfW+2, halfW-2))
            local cZ = casSide == 3 and (-halfW + 0.5) or (casSide == 4 and (halfW - 0.5) or rng:NextNumber(-halfW+2, halfW-2))
            BiomeDecorators.SpawnLavaCascade(slotModel, Vector3.new(cX, casY, cZ), rng:NextNumber(15, 30), biome)
        end
    elseif biome.name == "Mine" then
        -- Randomized timber support beams — each section gets a unique set
        local beamSections = 10 + rng:NextInteger(0, 4)  -- 10-14 sections per slot
        for si = 1, beamSections do
            local beamY = startY - (totalStuds / beamSections * si) + rng:NextNumber(-8, 8)
            local beamCount = rng:NextInteger(1, 3) -- 1 to 3 beams per section
            local woodR = rng:NextInteger(80, 140)
            local woodG = rng:NextInteger(52, 95)
            local woodB = rng:NextInteger(22, 58)
            local woodCol = Color3.fromRGB(woodR, woodG, woodB)

            for bi = 1, beamCount do
                -- Random yaw angle (0-180 degrees) so beams cross at various angles
                local angle = rng:NextNumber(0, math.pi)
                local cosA  = math.cos(angle)
                local sinA  = math.sin(angle)

                -- Random thickness (2-6 studs) and vertical height (2-5 studs)
                local beamW = rng:NextInteger(2, 6)
                local beamH = rng:NextInteger(2, 5)
                local beamLen = GameData.LEVEL_WIDTH + wallThick + rng:NextNumber(-4, 8)

                -- Random X/Z offset so beams aren't always centered
                local offX = rng:NextNumber(-halfW * 0.4, halfW * 0.4)
                local offZ = rng:NextNumber(-halfW * 0.4, halfW * 0.4)
                local beamY2 = beamY + (bi - 1) * rng:NextNumber(0.5, 3)

                -- Slightly different shade per beam
                local shadeMix = rng:NextNumber(-15, 15)
                local bCol = Color3.fromRGB(
                    math.clamp(woodR + shadeMix, 40, 180),
                    math.clamp(woodG + shadeMix * 0.7, 30, 130),
                    math.clamp(woodB + shadeMix * 0.5, 10, 80)
                )

                local beamPart = PartBuilders.MakePart(slotModel, "MineBeam",
                    Vector3.new(offX, beamY2, offZ),
                    Vector3.new(beamLen, beamH, beamW),
                    bCol, Enum.Material.Wood)
                beamPart.CFrame = CFrame.new(offX, beamY2, offZ) * CFrame.Angles(0, angle, 0)
                beamPart.CanCollide = true

                -- Vertical support posts at beam ends (50% chance per end)
                if rng:NextNumber() < 0.5 then
                    local postH = rng:NextInteger(8, 20)
                    PartBuilders.SpawnWall(slotModel,
                        Vector3.new(-halfW + 2 + rng:NextNumber(0, 6), beamY2 - postH/2, offZ + rng:NextNumber(-3, 3)),
                        Vector3.new(3 + rng:NextInteger(0, 2), postH, 3 + rng:NextInteger(0, 2)), woodCol, Enum.Material.Wood)
                end
                if rng:NextNumber() < 0.5 then
                    local postH = rng:NextInteger(8, 20)
                    PartBuilders.SpawnWall(slotModel,
                        Vector3.new(halfW - 2 - rng:NextNumber(0, 6), beamY2 - postH/2, offZ + rng:NextNumber(-3, 3)),
                        Vector3.new(3 + rng:NextInteger(0, 2), postH, 3 + rng:NextInteger(0, 2)), woodCol, Enum.Material.Wood)
                end
            end

            -- Hanging lantern or glowblock (60% chance per section)
            if rng:NextNumber() < 0.60 then
                local lX = rng:NextNumber(-halfW * 0.5, halfW * 0.5)
                local lZ = rng:NextNumber(-halfW * 0.5, halfW * 0.5)
                local lanternY = beamY - rng:NextNumber(2, 6)
                PartBuilders.SpawnGlowBlock(slotModel,
                    Vector3.new(lX, lanternY, lZ),
                    Vector3.new(rng:NextNumber(1, 2.5), rng:NextNumber(1.5, 3), rng:NextNumber(1, 2.5)),
                    Color3.fromRGB(220 + rng:NextInteger(0, 35), 165 + rng:NextInteger(0, 20), 40 + rng:NextInteger(0, 30)),
                    2.8 + rng:NextNumber(0, 1.2),
                    20 + rng:NextInteger(0, 12))
            end
        end
    end

    -- Wall minable ores
    local oreCount = rng:NextInteger(6, 10)
    for oi = 1, oreCount do
        local oreY = startY - (totalStuds / oreCount * oi) + rng:NextNumber(-8, 8)
        if oreY < startY and oreY > endY + 5 then
            local side = rng:NextInteger(1, 4)
            OreSpawner.SpawnWallOre(slotModel, side, oreY, halfW, biome, rng)
        end
    end

    -- ==== PLATFORM LAYOUT GENERATOR ====
    local ENTRY_CLEARANCE = (slotIndex == 1) and 80 or 0
    local currentY = startY - 4 - ENTRY_CLEARANCE
    local platformIndex = 0
    local slimeSpawns = {}

    while currentY > endY do
        platformIndex = platformIndex + 1
        local platRng = SeedSystem.ChildRNG(seedStr .. biome.name .. "_slot" .. slotIndex, platformIndex)

        local pW = platRng:NextInteger(biome.platform.minX, biome.platform.maxX)
        local pD = platRng:NextInteger(biome.platform.minZ, biome.platform.maxZ)
        local pH = platRng:NextInteger(2, 4)

        local maxDrift = math.max(0, (GameData.LEVEL_WIDTH / 2) - (math.max(pW, pD) / 2) - 2)
        local pX = platRng:NextNumber(-maxDrift, maxDrift)
        local pZ = platRng:NextNumber(-maxDrift, maxDrift)
        local pColor = BiomeData.GetRandomColor(biome, platRng)
        local terrainType = PartBuilders.GetTerrainType(biome, platRng)
        
        local isMoving = platRng:NextNumber() < 0.18

        if isMoving then
            BiomeDecorators.SpawnMovingPlatform(slotModel, Vector3.new(pX, currentY - pH/2, pZ), Vector3.new(pW, pH, pD), pColor, biome, platRng, seedStr)
        else
            PartBuilders.SpawnPlatform(slotModel, Vector3.new(pX, currentY - pH/2, pZ), Vector3.new(pW, pH, pD), pColor, nil, terrainType, biome)
            
            -- Active Item Crate spawning (14% chance on stationary platforms)
            if platRng:NextNumber() < 0.14 then
                local itemPool = {
                    -- Consumables (weighted 3x: most common)
                    "HealingPotion", "HealingPotion", "HealingPotion",
                    -- Traversal (weighted 2x)
                    "ClimbingRope", "ClimbingRope",
                    "Parachute",    "Parachute",
                    "Balloon",
                    -- Gadgets
                    "SpringThing",
                    "SteamJetpack",
                    "PitonSpikes",
                    -- Weapons / throwables
                    "SteamThrower",
                    "Javelin",
                    "SmallRock",  "SmallRock",
                    "BigRock",
                }
                local itemId = itemPool[platRng:NextInteger(1, #itemPool)]
                PartBuilders.SpawnItemCrate(slotModel, Vector3.new(pX, currentY + 1.5, pZ), itemId, platRng)
            end

            -- Gold coin cluster: 30% chance of 2–4 grouped coins on the platform surface
            if platRng:NextNumber() < 0.30 then
                local clusterCount = platRng:NextInteger(2, 4)
                for ci = 1, clusterCount do
                    local cx = pX + platRng:NextNumber(-pW/2 + 1, pW/2 - 1)
                    local cz = pZ + platRng:NextNumber(-pD/2 + 1, pD/2 - 1)
                    PartBuilders.SpawnCoin(slotModel, Vector3.new(cx, currentY + 1.5, cz))
                end
            end
        end

        local platTopY = currentY

        -- Stalactites underside
        if platRng:NextNumber() < 0.45 then
            local stCount = platRng:NextInteger(1, 4)
            for st = 1, stCount do
                local stX = pX + platRng:NextNumber(-pW/2 + 1, pW/2 - 1)
                local stZ = pZ + platRng:NextNumber(-pD/2 + 1, pD/2 - 1)
                BiomeDecorators.SpawnStalactite(slotModel, Vector3.new(stX, currentY - pH - platRng:NextInteger(3, 10), stZ), biome, platRng)
            end
        end

        -- Underside support layers
        if platRng:NextNumber() < 0.5 then
            local layers = platRng:NextInteger(1, 3)
            for li = 1, layers do
                local lOff = li * 2
                local lCol = BiomeData.GetRandomColor(biome, platRng)
                PartBuilders.SpawnWall(slotModel, Vector3.new(pX, currentY - pH - lOff, pZ),
                    Vector3.new(math.max(2, pW - li*2), 2, math.max(2, pD - li*2)), lCol)
            end
        end

        -- Surface rubble decoration
        BiomeDecorators.SpawnRubble(slotModel, Vector3.new(pX, platTopY, pZ), pW, pD, biome, platRng)

        -- Biome custom surface accents
        if biome.name == "Volcano" and platRng:NextNumber() < 0.35 then
            local lpW = platRng:NextInteger(3, math.max(4, pW - 4))
            local lpD = platRng:NextInteger(3, math.max(4, pD - 4))
            BiomeDecorators.SpawnLavaPool(slotModel, Vector3.new(pX, platTopY + 0.2, pZ), lpW, lpD, biome)
        elseif biome.name == "Cave" and platRng:NextNumber() < 0.40 then
            BiomeDecorators.SpawnCrystalCluster(slotModel, Vector3.new(pX + platRng:NextNumber(-pW/3, pW/3), platTopY, pZ + platRng:NextNumber(-pD/3, pD/3)), biome, platRng, platRng:NextInteger(3, 8))
        elseif biome.name == "Fortress" and platRng:NextNumber() < 0.3 then
            local pilH = platRng:NextInteger(6, 16)
            BiomeDecorators.SpawnPillar(slotModel, Vector3.new(pX + platRng:NextNumber(-pW/3, pW/3), platTopY, pZ + platRng:NextNumber(-pD/3, pD/3)), pilH, BiomeData.GetRandomColor(biome, platRng))
        elseif biome.name == "Mine" and platRng:NextNumber() < 0.45 then
            for ov = 1, platRng:NextInteger(1, 3) do
                BiomeDecorators.SpawnOreVein(slotModel, Vector3.new(pX + platRng:NextNumber(-pW/2+1, pW/2-1), platTopY + 0.5, pZ + platRng:NextNumber(-pD/2+1, pD/2-1)), biome, platRng)
            end
        end

        -- Coins
        if platRng:NextNumber() < biome.coinChance then
            local coinX = pX + platRng:NextNumber(-pW/2 + 1, pW/2 - 1)
            local coinZ = pZ + platRng:NextNumber(-pD/2 + 1, pD/2 - 1)
            PartBuilders.SpawnCoin(slotModel, Vector3.new(coinX, platTopY + 2, coinZ))
        end

        -- Secondary platform step
        if platRng:NextNumber() < 0.50 then
            local s2W  = platRng:NextInteger(5, 14)
            local s2D  = platRng:NextInteger(5, 14)
            local s2H  = platRng:NextInteger(2, 4)
            local s2X  = platRng:NextNumber(-maxDrift, maxDrift)
            local s2Z  = platRng:NextNumber(-maxDrift, maxDrift)
            local s2Color = BiomeData.GetRandomColor(biome, platRng)
            local s2Drop  = platRng:NextNumber(biome.dropMin * 0.4, biome.dropMax * 0.6)
            local s2Y  = currentY - s2Drop
            if s2Y > endY then
                local s2Terrain = PartBuilders.GetTerrainType(biome, platRng)
                PartBuilders.SpawnPlatform(slotModel, Vector3.new(s2X, s2Y - s2H/2, s2Z), Vector3.new(s2W, s2H, s2D), s2Color, nil, s2Terrain, biome)
            end
        end

        -- Algorithmic layout details
        if biome.name == "Cave" and platRng:NextNumber() < 0.30 then
            BiomeDecorators.GenerateCaveSpireSpiral(slotModel, pX, currentY, pZ, platformIndex, seedStr)
        elseif biome.name == "Mine" and platRng:NextNumber() < 0.35 then
            BiomeDecorators.GenerateMineTimberBridge(slotModel, pX, currentY, pZ, platformIndex, seedStr, endY)
        elseif biome.name == "Fortress" and platRng:NextNumber() < 0.28 then
            BiomeDecorators.GenerateFortressStoneArch(slotModel, pX, currentY, pZ, platformIndex, seedStr)
        elseif biome.name == "Volcano" and platRng:NextNumber() < 0.30 then
            BiomeDecorators.GenerateVolcanoCascadeShelves(slotModel, pX, currentY, pZ, platformIndex, seedStr, endY, biome)
        end

        -- Slimes
        if platRng:NextNumber() < 0.22 and not isMoving then
            local slimeSizes = { "Large", "Medium", "Small", "Tiny" }
            local slimeSize = slimeSizes[platRng:NextInteger(1, 4)]
            local patrolRange = platRng:NextNumber(6, 16)
            local patrolAngle = platRng:NextNumber(0, math.pi * 2)
            local patrolEnd = Vector3.new(
                pX + math.cos(patrolAngle) * patrolRange,
                platTopY + 2,
                pZ + math.sin(patrolAngle) * patrolRange
            )
            table.insert(slimeSpawns, {
                pos       = Vector3.new(pX, platTopY + 2, pZ),
                patrolEnd = patrolEnd,
                size      = slimeSize,
                platform  = Vector3.new(pX, platTopY, pZ),
            })
        end

        local drop = platRng:NextNumber(biome.dropMin, biome.dropMax)
        currentY = currentY - drop
    end

    -- Ambient lights spaced at 40 studs Y
    local lightSpacing = 40
    local lY = startY - lightSpacing
    while lY > endY do
        local lPart = PartBuilders.MakePart(slotModel, "ShaftLight",
            Vector3.new(rng:NextNumber(-halfW+8, halfW-8), lY, rng:NextNumber(-halfW+8, halfW-8)),
            Vector3.new(0.5, 0.5, 0.5), biome.accentColor, Enum.Material.Neon, 1)
        lPart.CanCollide = false
        lPart.CastShadow = false
        local lpl = Instance.new("PointLight")
        lpl.Brightness = rng:NextNumber(2.0, 3.5)
        lpl.Range = rng:NextNumber(25, 40)
        lpl.Color = biome.accentColor
        lpl.Parent = lPart
        lY = lY - lightSpacing
    end

    return slotModel, slimeSpawns
end

-- Destroy a slot
function LevelGenerator.UnloadSlot(sessionFolder, slotIndex)
    local slotsFolder = sessionFolder:FindFirstChild("Slots")
    if not slotsFolder then return end
    local slotModel = slotsFolder:FindFirstChild("Slot_" .. slotIndex)
    if slotModel then slotModel:Destroy() end
end

-- Isolated Session Generation Bootstrap
function LevelGenerator.Generate(sessionFolder, seed)
    local seedStr = tostring(seed)
    local biomeSequence = BiomeData.GenerateSequence(seedStr)

    -- Save biome order in this session folder
    local seqStore = Instance.new("StringValue")
    seqStore.Name = "BiomeSequence"
    local names = {}
    for i, b in ipairs(biomeSequence) do names[i] = b.name end
    seqStore.Value = table.concat(names, ",")
    seqStore.Parent = sessionFolder

    -- Surface ceiling cap
    local W        = GameData.LEVEL_WIDTH
    local capColor = Color3.fromRGB(55, 52, 46)
    local cap = PartBuilders.MakePart(sessionFolder, "SurfaceCap",
        Vector3.new(0, 5, 0),
        Vector3.new(W + 20, 10, W + 20), capColor)
    cap.CanCollide = false

    -- Build Industrial Dwarven Entry Basket
    local basket, doorL, doorR, gearL, gearR = DwarvenBasket.Build(sessionFolder)

    -- Generate Slot 1 & Slot 2 immediately
    local allSlimes = {}
    local slot1, slimes1 = LevelGenerator.GenerateSlot(sessionFolder, 1, seed)
    local slot2, slimes2 = LevelGenerator.GenerateSlot(sessionFolder, 2, seed)

    for _, s in ipairs(slimes1) do table.insert(allSlimes, s) end
    for _, s in ipairs(slimes2) do table.insert(allSlimes, s) end

    -- Serialize slimes
    local slimeData = Instance.new("StringValue")
    slimeData.Name = "SlimeSpawnData"
    local parts = {}
    for _, s in ipairs(allSlimes) do
        table.insert(parts, string.format("%s|%.2f,%.2f,%.2f|%.2f,%.2f,%.2f",
            s.size, s.pos.X, s.pos.Y, s.pos.Z, s.patrolEnd.X, s.patrolEnd.Y, s.patrolEnd.Z))
    end
    slimeData.Value = table.concat(parts, ";")
    slimeData.Parent = sessionFolder

    -- Bottom termination platform (1000m)
    local finishY = GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS)
    PartBuilders.SpawnFinish(sessionFolder, finishY)

    return sessionFolder, biomeSequence, allSlimes
end

return LevelGenerator
