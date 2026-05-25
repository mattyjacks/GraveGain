-- DropDwarf: level_generator/dwarven_basket.lua
-- Builds a high-fidelity entry basket with rotating gears, copper pipes, steam vents, and opening trapdoors.

local PartBuilders = require(script.Parent.part_builders)

local DwarvenBasket = {}

function DwarvenBasket.Build(levelFolder)
    local steelColor  = Color3.fromRGB(58, 62, 70)
    local steelMat    = Enum.Material.Metal
    local bronzeColor = Color3.fromRGB(100, 82, 48)
    local copperColor = Color3.fromRGB(184, 115, 51)
    local ironDark    = Color3.fromRGB(38, 38, 44)

    local basketFloorY  = -12.5
    local basketFloorH  =  0.8
    local basketW       = 12
    local basketH       =  5.4
    local postW         =  1.0
    local rimH          =  0.7
    local wallZ         = basketW / 2

    local basketModel = Instance.new("Model")
    basketModel.Name = "DwarvenEntryBasket"
    basketModel.Parent = levelFolder

    -- ==================== TRAPDOOR FLOOR SYSTEM ====================
    -- Instead of a flat single plate, we build 2 opening doors!
    local doorW = basketW * 0.5 - 0.05
    local doorD = basketW - 0.1
    local doorH = basketFloorH

    -- Left Trapdoor
    local doorL = PartBuilders.MakePart(basketModel, "BasketTrapdoorL",
        Vector3.new(-basketW*0.25, basketFloorY - doorH/2, 0),
        Vector3.new(doorW, doorH, doorD), steelColor, steelMat)
    doorL.Material = Enum.Material.Glass
    doorL.Transparency = 0.3
    doorL.Color = Color3.fromRGB(140, 185, 205)

    -- Right Trapdoor
    local doorR = PartBuilders.MakePart(basketModel, "BasketTrapdoorR",
        Vector3.new(basketW*0.25, basketFloorY - doorH/2, 0),
        Vector3.new(doorW, doorH, doorD), steelColor, steelMat)
    doorR.Material = Enum.Material.Glass
    doorR.Transparency = 0.3
    doorR.Color = Color3.fromRGB(140, 185, 205)

    -- Corner frame posts
    local postBotY = basketFloorY
    local postTopY = basketFloorY + basketH + rimH + 0.3
    local postH    = postTopY - postBotY
    local postCY   = postBotY + postH / 2
    local postInset = basketW / 2 - postW / 2
    for _, cx in ipairs({-1, 1}) do
        for _, cz in ipairs({-1, 1}) do
            local post = PartBuilders.MakePart(basketModel, "BasketPost",
                Vector3.new(cx * postInset, postCY, cz * postInset),
                Vector3.new(postW, postH, postW), bronzeColor, steelMat)
            post.CanCollide = false
        end
    end

    -- ==================== STEAM PIPES AND INDUSTRIAL DETAILS ====================
    -- Copper steam lines venting mist downwards
    for _, coX in ipairs({-postInset - 0.2, postInset + 0.2}) do
        local pipe = PartBuilders.MakePart(basketModel, "CopperSteamPipe",
            Vector3.new(coX, postCY, 0),
            Vector3.new(0.3, postH * 0.9, 0.3), copperColor, Enum.Material.CorrodedMetal)
        pipe.CanCollide = false

        -- Bottom vent nozzle with particle emitters
        local nozzle = PartBuilders.MakePart(basketModel, "SteamNozzle",
            Vector3.new(coX, postBotY - 0.4, 0),
            Vector3.new(0.5, 0.6, 0.5), bronzeColor, steelMat)
        nozzle.CanCollide = false

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "SteamVent"
        emitter.Enabled = false
        emitter.Texture = "rbxassetid://241589139" -- soft cloud smoke texture
        emitter.Rate = 90
        emitter.Speed = NumberRange.new(12, 24)
        emitter.SpreadAngle = Vector2.new(15, 15)
        emitter.Lifetime = NumberRange.new(1.0, 1.8)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.3, 2.5),
            NumberSequenceKeypoint.new(1, 6.0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.4),
            NumberSequenceKeypoint.new(1, 1.0),
        })
        emitter.Color = ColorSequence.new(Color3.fromRGB(240, 240, 245))
        emitter.Acceleration = Vector3.new(0, -18, 0)
        emitter.Parent = nozzle
    end

    -- ==================== COPPER ROTATING COG GEARS ====================
    -- Left gear
    local gearL = PartBuilders.MakePart(basketModel, "IndustrialGearL",
        Vector3.new(-basketW*0.5 - 0.3, postCY, 0),
        Vector3.new(0.4, 3.2, 3.2), copperColor, Enum.Material.Metal)
    gearL.Shape = Enum.PartType.Cylinder
    gearL.CFrame = gearL.CFrame * CFrame.Angles(0, math.pi/2, 0)
    gearL.CanCollide = false

    -- Right gear
    local gearR = PartBuilders.MakePart(basketModel, "IndustrialGearR",
        Vector3.new(basketW*0.5 + 0.3, postCY, 0),
        Vector3.new(0.4, 3.2, 3.2), copperColor, Enum.Material.Metal)
    gearR.Shape = Enum.PartType.Cylinder
    gearR.CFrame = gearR.CFrame * CFrame.Angles(0, math.pi/2, 0)
    gearR.CanCollide = false

    -- ==================== WALL GRATING ====================
    local railCount  = 5
    local barCount   = 5
    local wallInnerW = basketW - postW * 2
    local wallCX     = 0
    local wallFaceT  = 0.35
    local wallBotY = basketFloorY

    local function buildGratingNS(zSign)
        local faceZ = zSign * (wallZ - wallFaceT / 2)
        for ri = 1, railCount do
            local ry = wallBotY + (ri / (railCount + 1)) * basketH
            local rail = PartBuilders.MakePart(basketModel, "RailNS",
                Vector3.new(wallCX, ry, faceZ),
                Vector3.new(wallInnerW, wallFaceT, wallFaceT), ironDark, steelMat)
            rail.CanCollide = false
        end
        for bi = 1, barCount do
            local bx = -wallInnerW/2 + (bi / (barCount + 1)) * wallInnerW
            local barCY = wallBotY + basketH / 2
            local bar = PartBuilders.MakePart(basketModel, "BarNS",
                Vector3.new(bx, barCY, faceZ),
                Vector3.new(wallFaceT, basketH, wallFaceT), ironDark, steelMat)
            bar.CanCollide = false
        end
        local backplate = PartBuilders.MakePart(basketModel, "BasketWallNS",
            Vector3.new(wallCX, wallBotY + basketH/2, faceZ),
            Vector3.new(wallInnerW, basketH, 0.15), steelColor, steelMat)
        backplate.Transparency = 0.7
        backplate.CanCollide = false
    end

    local function buildGratingWE(xSign)
        local faceX = xSign * (wallZ - wallFaceT / 2)
        for ri = 1, railCount do
            local ry = wallBotY + (ri / (railCount + 1)) * basketH
            local rail = PartBuilders.MakePart(basketModel, "RailWE",
                Vector3.new(faceX, ry, wallCX),
                Vector3.new(wallFaceT, wallFaceT, wallInnerW), ironDark, steelMat)
            rail.CanCollide = false
        end
        for bi = 1, barCount do
            local bz = -wallInnerW/2 + (bi / (barCount + 1)) * wallInnerW
            local barCY = wallBotY + basketH / 2
            local bar = PartBuilders.MakePart(basketModel, "BarWE",
                Vector3.new(faceX, barCY, bz),
                Vector3.new(wallFaceT, basketH, wallFaceT), ironDark, steelMat)
            bar.CanCollide = false
        end
        local backplate = PartBuilders.MakePart(basketModel, "BasketWallWE",
            Vector3.new(faceX, wallBotY + basketH/2, wallCX),
            Vector3.new(0.15, basketH, wallInnerW), steelColor, steelMat)
        backplate.Transparency = 0.7
        backplate.CanCollide = false
    end

    buildGratingNS(-1) -- North
    buildGratingNS( 1) -- South
    buildGratingWE(-1) -- West
    buildGratingWE( 1) -- East

    -- Rim Caps (non-collidable to prevent fling)
    local rimY = basketFloorY + basketH + rimH / 2
    local rimN = PartBuilders.MakePart(basketModel, "BasketRimN", Vector3.new(0, rimY, -wallZ), Vector3.new(basketW, rimH, postW + 0.2), bronzeColor, steelMat)
    rimN.CanCollide = false
    local rimS = PartBuilders.MakePart(basketModel, "BasketRimS", Vector3.new(0, rimY,  wallZ), Vector3.new(basketW, rimH, postW + 0.2), bronzeColor, steelMat)
    rimS.CanCollide = false
    local rimW = PartBuilders.MakePart(basketModel, "BasketRimW", Vector3.new(-wallZ, rimY, 0), Vector3.new(postW + 0.2, rimH, basketW - postW * 2), bronzeColor, steelMat)
    rimW.CanCollide = false
    local rimE = PartBuilders.MakePart(basketModel, "BasketRimE", Vector3.new( wallZ, rimY, 0), Vector3.new(postW + 0.2, rimH, basketW - postW * 2), bronzeColor, steelMat)
    rimE.CanCollide = false

    -- Master hanging chains
    local rimTopY      = rimY + rimH / 2
    local ceilY        = -1
    local mergeY       = ceilY - 4
    local chainOffsets = {
        Vector3.new( 4,  0,  4),
        Vector3.new(-4,  0,  4),
        Vector3.new( 4,  0, -4),
        Vector3.new(-4,  0, -4),
    }
    for _, co in ipairs(chainOffsets) do
        local steps = math.ceil((mergeY - rimTopY) / 2.0)
        for ci = 0, steps do
            local t  = ci / steps
            local cx = co.X * (1 - t)
            local cz = co.Z * (1 - t)
            local cy = rimTopY + (mergeY - rimTopY) * t
            local isH = (ci % 2 == 0)
            local lW = isH and 1.8 or 0.5
            local lD = isH and 0.5 or 1.8
            local lnk = PartBuilders.MakePart(basketModel, "ChainLink", Vector3.new(cx, cy, cz), Vector3.new(lW, 1.2, lD), steelColor, steelMat)
            lnk.CanCollide = false
        end
    end

    local mergeP = PartBuilders.MakePart(basketModel, "ChainMerge", Vector3.new(0, mergeY, 0), Vector3.new(3, 1.5, 3), bronzeColor, steelMat)
    mergeP.CanCollide = false

    local masterSteps = math.ceil((ceilY - mergeY) / 2.0)
    for ci = 0, masterSteps do
        local cy = mergeY + (ceilY - mergeY) * (ci / masterSteps)
        local isH = (ci % 2 == 0)
        local lW = isH and 2.5 or 0.7
        local lD = isH and 0.7 or 2.5
        local ml = PartBuilders.MakePart(basketModel, "ChainMaster", Vector3.new(0, cy, 0), Vector3.new(lW, 1.5, lD), steelColor, steelMat)
        ml.CanCollide = false
    end

    -- Hanging central lantern
    local lanternY = rimTopY - 1.5
    local lanternTop = PartBuilders.MakePart(basketModel, "LanternTop", Vector3.new(0, lanternY, 0), Vector3.new(1.6, 0.4, 1.6), ironDark, steelMat)
    lanternTop.CanCollide = false
    for _, lx in ipairs({-0.55, 0.55}) do
        for _, lz in ipairs({-0.55, 0.55}) do
            local lb = PartBuilders.MakePart(basketModel, "LanternBar", Vector3.new(lx, lanternY - 1.1, lz), Vector3.new(0.18, 2.2, 0.18), ironDark, steelMat)
            lb.CanCollide = false
        end
    end
    local lanternBot = PartBuilders.MakePart(basketModel, "LanternBot", Vector3.new(0, lanternY - 2.3, 0), Vector3.new(1.6, 0.4, 1.6), ironDark, steelMat)
    lanternBot.CanCollide = false

    local lanternGlow = Instance.new("Part")
    lanternGlow.Name        = "BasketLantern"
    lanternGlow.Shape       = Enum.PartType.Ball
    lanternGlow.Size        = Vector3.new(0.85, 0.85, 0.85)
    lanternGlow.Position    = Vector3.new(0, lanternY - 1.1, 0)
    lanternGlow.Anchored    = true
    lanternGlow.CanCollide  = false
    lanternGlow.Color       = Color3.fromRGB(255, 190, 70)
    lanternGlow.Material    = Enum.Material.Neon
    lanternGlow.Transparency = 0.15
    lanternGlow.CastShadow  = false
    lanternGlow.Parent      = basketModel

    local lanternLight      = Instance.new("PointLight")
    lanternLight.Brightness = 4
    lanternLight.Range      = 28
    lanternLight.Color      = Color3.fromRGB(255, 195, 80)
    lanternLight.Parent     = lanternGlow

    local suspendSteps = 3
    for si = 0, suspendSteps do
        local sy = rimTopY - 1.0 - si * 0.5
        local sl = PartBuilders.MakePart(basketModel, "LanternChain", Vector3.new(0, sy, 0), Vector3.new(0.4, 0.5, 0.4), ironDark, steelMat)
        sl.CanCollide = false
    end

    return basketModel, doorL, doorR, gearL, gearR
end

return DwarvenBasket
