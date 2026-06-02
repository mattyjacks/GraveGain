local JetSkyDetailed = {}
local GameData = require(script.Parent:WaitForChild("game_data"))

-- Color palette
local C = {
    HULL = Color3.fromRGB(0, 120, 200),
    HULL2 = Color3.fromRGB(0, 80, 160),
    CHROME = Color3.fromRGB(180, 190, 200),
    DARK = Color3.fromRGB(60, 60, 70),
    CARBON = Color3.fromRGB(40, 40, 40),
    LEATHER = Color3.fromRGB(120, 60, 40),
    NEON = Color3.fromRGB(0, 255, 255),
    NEON_BOOST = Color3.fromRGB(255, 150, 50),
    GLASS = Color3.fromRGB(200, 220, 255),
    RED = Color3.fromRGB(255, 50, 50),
    YELLOW = Color3.fromRGB(255, 200, 0),
    RUBBER = Color3.fromRGB(30, 30, 30),
    FOAM = Color3.fromRGB(240, 240, 250)
}

local function createPart(name, shape, size, color, mat, parent, cf, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = shape
    p.Size = size
    p.Color = color
    p.Material = mat or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Anchored = false
    p.CanCollide = collide or false
    p.Parent = parent
    p.CFrame = cf
    return p
end

local function createCylinder(name, size, color, mat, parent, cf)
    local p = createPart(name, Enum.PartType.Cylinder, size, color, mat, parent, cf, false)
    return p
end

local function createWedge(name, size, color, mat, parent, cf)
    local p = createPart(name, Enum.PartType.Wedge, size, color, mat, parent, cf, false)
    return p
end

function JetSkyDetailed.CreateDetailedJetSky(primaryColor, accentColor)
    primaryColor = primaryColor or C.HULL
    accentColor = accentColor or C.NEON
    
    local m = Instance.new("Model")
    m.Name = "JetSky_Detailed"
    
    -- MAIN HULL (7 parts)
    local hullLower = createPart("HullLower", Enum.PartType.Block, Vector3.new(3.2, 1.8, 7.5), primaryColor, Enum.Material.SmoothPlastic, m, CFrame.new(0, -0.5, 0), true)
    local hullUpper = createPart("HullUpper", Enum.PartType.Block, Vector3.new(2.8, 1.4, 6), primaryColor, Enum.Material.SmoothPlastic, m, CFrame.new(0, 0.7, 0.5))
    local noseCone = createCylinder("NoseCone", Vector3.new(3, 2.2, 2.2), primaryColor, Enum.Material.SmoothPlastic, m, CFrame.new(0, -0.2, 4) * CFrame.Angles(0,0,math.rad(90)))
    local noseTip = createPart("NoseTip", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5), accentColor, Enum.Material.Neon, m, CFrame.new(0, -0.2, 5.2))
    local hullTail = createPart("HullTail", Enum.PartType.Block, Vector3.new(2.6, 1.6, 2.5), C.HULL2, Enum.Material.SmoothPlastic, m, CFrame.new(0, 0.2, -4))
    local belly = createPart("Belly", Enum.PartType.Block, Vector3.new(2.5, 0.8, 5), C.DARK, Enum.Material.Metal, m, CFrame.new(0, -1.2, 0))
    local spine = createCylinder("Spine", Vector3.new(7, 0.6, 0.6), primaryColor, Enum.Material.SmoothPlastic, m, CFrame.new(0, 1.2, 0) * CFrame.Angles(0,0,math.rad(90)))
    
    -- WINGS (6 parts)
    local leftWing = createWedge("LeftWing", Vector3.new(4.5, 0.3, 3), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(-3.5, 0.5, 0) * CFrame.Angles(0,0,math.rad(-5)))
    local rightWing = createWedge("RightWing", Vector3.new(4.5, 0.3, 3), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(3.5, 0.5, 0) * CFrame.Angles(0,0,math.rad(5)))
    local leftWingTip = createWedge("LeftWingTip", Vector3.new(1.2, 0.2, 1.5), accentColor, Enum.Material.Neon, m, CFrame.new(-6, 0.6, 0.5))
    local rightWingTip = createWedge("RightWingTip", Vector3.new(1.2, 0.2, 1.5), accentColor, Enum.Material.Neon, m, CFrame.new(6, 0.6, 0.5))
    local leftFlap = createPart("LeftFlap", Enum.PartType.Block, Vector3.new(2, 0.1, 1.5), C.DARK, Enum.Material.Metal, m, CFrame.new(-3, 0.2, -1))
    local rightFlap = createPart("RightFlap", Enum.PartType.Block, Vector3.new(2, 0.1, 1.5), C.DARK, Enum.Material.Metal, m, CFrame.new(3, 0.2, -1))
    
    -- TAIL (7 parts)
    local vStab = createWedge("VStab", Vector3.new(0.4, 2.5, 2), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(0, 2, -4.5))
    local stabLight = createPart("StabLight", Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), C.RED, Enum.Material.Neon, m, CFrame.new(0, 3.3, -5))
    local leftHStab = createWedge("LeftHStab", Vector3.new(2, 0.2, 1.2), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(-1.5, 1, -5))
    local rightHStab = createWedge("RightHStab", Vector3.new(2, 0.2, 1.2), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(1.5, 1, -5))
    local leftElevator = createPart("LeftElevator", Enum.PartType.Block, Vector3.new(1, 0.1, 0.8), C.DARK, Enum.Material.Metal, m, CFrame.new(-1.5, 0.8, -5.3))
    local rightElevator = createPart("RightElevator", Enum.PartType.Block, Vector3.new(1, 0.1, 0.8), C.DARK, Enum.Material.Metal, m, CFrame.new(1.5, 0.8, -5.3))
    local rudder = createWedge("Rudder", Vector3.new(0.3, 1.8, 1), C.DARK, Enum.Material.Metal, m, CFrame.new(0, 2.5, -4.8))
    
    -- COCKPIT & SEATING (8 parts)
    local seatBase = createPart("SeatBase", Enum.PartType.Block, Vector3.new(1.8, 0.4, 2), C.DARK, Enum.Material.Metal, m, CFrame.new(0, 1.4, -0.5))
    local seatCushion = createPart("SeatCushion", Enum.PartType.Block, Vector3.new(1.6, 0.3, 1.8), C.LEATHER, Enum.Material.Leather, m, CFrame.new(0, 1.75, -0.5))
    local seatBack = createPart("SeatBack", Enum.PartType.Block, Vector3.new(1.6, 1.2, 0.3), C.LEATHER, Enum.Material.Leather, m, CFrame.new(0, 2.3, -1.3) * CFrame.Angles(math.rad(-15), 0, 0))
    local headrest = createCylinder("Headrest", Vector3.new(1.4, 0.4, 0.4), C.LEATHER, Enum.Material.Leather, m, CFrame.new(0, 3, -1.4) * CFrame.Angles(0,0,math.rad(90)))
    local seat = Instance.new("Seat")
    seat.Name = "Seat"
    seat.Size = Vector3.new(1.5, 0.5, 1.5)
    seat.Color = C.LEATHER
    seat.Material = Enum.Material.Leather
    seat.Anchored = false
    seat.CanCollide = true
    seat.Disabled = false
    seat.Parent = m
    seat.CFrame = CFrame.new(0, 2, -0.5)
    
    -- Dashboard (6 parts)
    local dash = createPart("Dashboard", Enum.PartType.Block, Vector3.new(2.4, 0.6, 0.8), C.DARK, Enum.Material.Metal, m, CFrame.new(0, 2, 2) * CFrame.Angles(math.rad(-20), 0, 0))
    local speedo = createCylinder("Speedometer", Vector3.new(0.15, 0.6, 0.6), C.CHROME, Enum.Material.Metal, m, CFrame.new(-0.6, 2.2, 2) * CFrame.Angles(math.rad(-20), 0, math.rad(90)))
    local altimeter = createCylinder("Altimeter", Vector3.new(0.15, 0.5, 0.5), C.CHROME, Enum.Material.Metal, m, CFrame.new(0.6, 2.2, 2) * CFrame.Angles(math.rad(-20), 0, math.rad(90)))
    local compass = createCylinder("Compass", Vector3.new(0.15, 0.4, 0.4), C.CHROME, Enum.Material.Metal, m, CFrame.new(0, 2.25, 2.1) * CFrame.Angles(math.rad(-20), 0, math.rad(90)))
    local fuelGauge = createCylinder("FuelGauge", Vector3.new(0.12, 0.35, 0.35), C.CHROME, Enum.Material.Metal, m, CFrame.new(-1, 2.15, 1.9) * CFrame.Angles(math.rad(-20), 0, math.rad(90)))
    local boostGauge = createCylinder("BoostGauge", Vector3.new(0.12, 0.35, 0.35), C.CHROME, Enum.Material.Metal, m, CFrame.new(1, 2.15, 1.9) * CFrame.Angles(math.rad(-20), 0, math.rad(90)))
    
    -- WINDSHIELD (2 parts)
    local wFrame = createPart("WindshieldFrame", Enum.PartType.Block, Vector3.new(2.6, 1.2, 0.1), C.DARK, Enum.Material.Metal, m, CFrame.new(0, 2.8, 2.3) * CFrame.Angles(math.rad(-30), 0, 0))
    local windshield = createPart("Windshield", Enum.PartType.Block, Vector3.new(2.4, 1, 0.05), C.GLASS, Enum.Material.Glass, m, CFrame.new(0, 2.8, 2.31) * CFrame.Angles(math.rad(-30), 0, 0))
    windshield.Transparency = 0.7
    
    -- HANDLEBARS (5 parts)
    local handleStem = createCylinder("HandleStem", Vector3.new(1.8, 0.25, 0.25), C.CHROME, Enum.Material.Metal, m, CFrame.new(0, 2.2, 1.5) * CFrame.Angles(0,0,math.rad(90)))
    local leftGrip = createCylinder("LeftGrip", Vector3.new(1, 0.2, 0.2), C.RUBBER, Enum.Material.SmoothPlastic, m, CFrame.new(-0.9, 2.2, 1.5) * CFrame.Angles(0,0,math.rad(90)))
    local rightGrip = createCylinder("RightGrip", Vector3.new(1, 0.2, 0.2), C.RUBBER, Enum.Material.SmoothPlastic, m, CFrame.new(0.9, 2.2, 1.5) * CFrame.Angles(0,0,math.rad(90)))
    local throttle = createPart("Throttle", Enum.PartType.Block, Vector3.new(0.15, 0.4, 0.15), C.RED, Enum.Material.Metal, m, CFrame.new(1, 2.4, 1.3))
    local brake = createPart("Brake", Enum.PartType.Block, Vector3.new(0.15, 0.3, 0.15), C.YELLOW, Enum.Material.Metal, m, CFrame.new(-1, 2.35, 1.3))
    
    -- DUAL JET ENGINES (14 parts)
    local leftEngine = createCylinder("LeftEngine", Vector3.new(3.5, 1.2, 1.2), C.DARK, Enum.Material.Metal, m, CFrame.new(-1.3, 0, -2.5) * CFrame.Angles(0,0,math.rad(90)))
    local rightEngine = createCylinder("RightEngine", Vector3.new(3.5, 1.2, 1.2), C.DARK, Enum.Material.Metal, m, CFrame.new(1.3, 0, -2.5) * CFrame.Angles(0,0,math.rad(90)))
    local leftIntake = createCylinder("LeftIntake", Vector3.new(0.3, 0.9, 0.9), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(-1.3, 0, -0.8) * CFrame.Angles(0,0,math.rad(90)))
    local rightIntake = createCylinder("RightIntake", Vector3.new(0.3, 0.9, 0.9), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(1.3, 0, -0.8) * CFrame.Angles(0,0,math.rad(90)))
    local leftTurbo = createCylinder("LeftTurbo", Vector3.new(0.8, 0.5, 0.5), C.CHROME, Enum.Material.Metal, m, CFrame.new(-1.3, 0.5, -1.5) * CFrame.Angles(0,0,math.rad(90)))
    local rightTurbo = createCylinder("RightTurbo", Vector3.new(0.8, 0.5, 0.5), C.CHROME, Enum.Material.Metal, m, CFrame.new(1.3, 0.5, -1.5) * CFrame.Angles(0,0,math.rad(90)))
    local leftNozzle = createCylinder("LeftNozzle", Vector3.new(1, 0.8, 0.8), C.CHROME, Enum.Material.Metal, m, CFrame.new(-1.3, 0, -4.2) * CFrame.Angles(0,0,math.rad(90)))
    local rightNozzle = createCylinder("RightNozzle", Vector3.new(1, 0.8, 0.8), C.CHROME, Enum.Material.Metal, m, CFrame.new(1.3, 0, -4.2) * CFrame.Angles(0,0,math.rad(90)))
    local leftInnerGlow = createCylinder("LeftInnerGlow", Vector3.new(0.3, 0.5, 0.5), accentColor, Enum.Material.Neon, m, CFrame.new(-1.3, 0, -4.5) * CFrame.Angles(0,0,math.rad(90)))
    local rightInnerGlow = createCylinder("RightInnerGlow", Vector3.new(0.3, 0.5, 0.5), accentColor, Enum.Material.Neon, m, CFrame.new(1.3, 0, -4.5) * CFrame.Angles(0,0,math.rad(90)))
    local leftOuterGlow = createCylinder("LeftOuterGlow", Vector3.new(0.2, 0.6, 0.6), accentColor, Enum.Material.Neon, m, CFrame.new(-1.3, 0, -4.7) * CFrame.Angles(0,0,math.rad(90)))
    local rightOuterGlow = createCylinder("RightOuterGlow", Vector3.new(0.2, 0.6, 0.6), accentColor, Enum.Material.Neon, m, CFrame.new(1.3, 0, -4.7) * CFrame.Angles(0,0,math.rad(90)))
    local leftFin = createWedge("LeftFin", Vector3.new(0.8, 0.8, 0.3), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(-1.3, -0.5, -4.5) * CFrame.Angles(math.rad(-15), 0, 0))
    local rightFin = createWedge("RightFin", Vector3.new(0.8, 0.8, 0.3), C.CARBON, Enum.Material.SmoothPlastic, m, CFrame.new(1.3, -0.5, -4.5) * CFrame.Angles(math.rad(-15), 0, 0))
    
    -- LIGHTING (8 parts)
    local headlightL = createCylinder("HeadlightL", Vector3.new(0.3, 0.4, 0.4), C.GLASS, Enum.Material.Glass, m, CFrame.new(-0.8, 0.3, 3.5) * CFrame.Angles(0,0,math.rad(90)))
    local headlightR = createCylinder("HeadlightR", Vector3.new(0.3, 0.4, 0.4), C.GLASS, Enum.Material.Glass, m, CFrame.new(0.8, 0.3, 3.5) * CFrame.Angles(0,0,math.rad(90)))
    local navLightL = createPart("NavLightL", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), C.RED, Enum.Material.Neon, m, CFrame.new(-6.2, 0.6, 0.5))
    local navLightR = createPart("NavLightR", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(0, 255, 0), Enum.Material.Neon, m, CFrame.new(6.2, 0.6, 0.5))
    local tailLight = createPart("TailLight", Enum.PartType.Ball, Vector3.new(0.25, 0.25, 0.25), C.RED, Enum.Material.Neon, m, CFrame.new(0, 3.3, -5))
    local strobe1 = createPart("Strobe1", Enum.PartType.Ball, Vector3.new(0.15, 0.15, 0.15), C.YELLOW, Enum.Material.Neon, m, CFrame.new(-2, 0.6, -2))
    local strobe2 = createPart("Strobe2", Enum.PartType.Ball, Vector3.new(0.15, 0.15, 0.15), C.YELLOW, Enum.Material.Neon, m, CFrame.new(2, 0.6, -2))
    local bellyLight = createPart("BellyLight", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), C.YELLOW, Enum.Material.Neon, m, CFrame.new(0, -1.5, 0))
    
    -- DETAILS (12 parts)
    local fuelCap = createCylinder("FuelCap", Vector3.new(0.2, 0.4, 0.4), C.YELLOW, Enum.Material.Metal, m, CFrame.new(-1, 0.5, 1) * CFrame.Angles(0,0,math.rad(90)))
    local oilCap = createCylinder("OilCap", Vector3.new(0.15, 0.25, 0.25), C.RED, Enum.Material.Metal, m, CFrame.new(1, 0.5, 1) * CFrame.Angles(0,0,math.rad(90)))
    
    -- Side vents (6 parts)
    for i = 1, 3 do
        createPart("LeftVent"..i, Enum.PartType.Block, Vector3.new(0.3, 0.15, 0.8), C.DARK, Enum.Material.Metal, m, CFrame.new(-1.65, 0.2+(i-1)*0.3, -1+(i-1)*0.5))
        createPart("RightVent"..i, Enum.PartType.Block, Vector3.new(0.3, 0.15, 0.8), C.DARK, Enum.Material.Metal, m, CFrame.new(1.65, 0.2+(i-1)*0.3, -1+(i-1)*0.5))
    end
    
    -- Grab handles (2 parts)
    createCylinder("LeftHandle", Vector3.new(1, 0.1, 0.1), C.CHROME, Enum.Material.Metal, m, CFrame.new(-1, 2, 0) * CFrame.Angles(0,0,math.rad(90)))
    createCylinder("RightHandle", Vector3.new(1, 0.1, 0.1), C.CHROME, Enum.Material.Metal, m, CFrame.new(1, 2, 0) * CFrame.Angles(0,0,math.rad(90)))
    
    -- Tie downs (4 parts)
    createPart("TieDownFL", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), C.CHROME, Enum.Material.Metal, m, CFrame.new(-1.5, 0.5, 2.5))
    createPart("TieDownFR", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), C.CHROME, Enum.Material.Metal, m, CFrame.new(1.5, 0.5, 2.5))
    createPart("TieDownRL", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), C.CHROME, Enum.Material.Metal, m, CFrame.new(-1.5, 0.5, -2.5))
    createPart("TieDownRR", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), C.CHROME, Enum.Material.Metal, m, CFrame.new(1.5, 0.5, -2.5))
    
    -- Antenna
    createCylinder("Antenna", Vector3.new(0.8, 0.05, 0.05), C.CHROME, Enum.Material.Metal, m, CFrame.new(0.5, 3.5, -3) * CFrame.Angles(math.rad(10), 0, math.rad(90)))
    createPart("AntennaTip", Enum.PartType.Ball, Vector3.new(0.1, 0.1, 0.1), C.RED, Enum.Material.Neon, m, CFrame.new(0.5, 3.9, -3.1))
    
    -- Hull stripes/decals (visual details)
    createPart("StripeL", Enum.PartType.Block, Vector3.new(0.1, 0.05, 6), accentColor, Enum.Material.Neon, m, CFrame.new(-1.41, 0.2, 0))
    createPart("StripeR", Enum.PartType.Block, Vector3.new(0.1, 0.05, 6), accentColor, Enum.Material.Neon, m, CFrame.new(1.41, 0.2, 0))
    
    -- Registration number plate
    local regPlate = createPart("RegPlate", Enum.PartType.Block, Vector3.new(0.8, 0.3, 0.05), C.CHROME, Enum.Material.Metal, m, CFrame.new(0, 0.3, -5.26))
    
    -- Set primary part
    m.PrimaryPart = hullLower
    
    -- Create welds to connect all parts
    local function weld(p0, p1)
        local w = Instance.new("WeldConstraint")
        w.Part0 = p0
        w.Part1 = p1
        w.Parent = p0
        return w
    end
    
    -- Weld all parts to hull
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") and part ~= hullLower and part ~= seat then
            weld(hullLower, part)
        end
    end
    
    -- Weld seat separately
    weld(hullLower, seat)
    
    -- Unanchor after welds
    task.defer(function()
        hullLower.Anchored = false
    end)
    
    return m, seat
end

-- Thruster particle effects
function JetSkyDetailed.CreateThrusterEffects(jetSky, isBoosting, isInWater)
    local color = isBoosting and C.NEON_BOOST or (isInWater and Color3.fromRGB(0, 200, 255) or C.NEON)
    
    -- Left exhaust particles
    local leftGlow = jetSky:FindFirstChild("LeftOuterGlow")
    local rightGlow = jetSky:FindFirstChild("RightOuterGlow")
    
    if leftGlow then leftGlow.Color = color end
    if rightGlow then rightGlow.Color = color end
    
    -- Create particle emitters
    for _, side in ipairs({"Left", "Right"}) do
        local nozzle = jetSky:FindFirstChild(side .. "Nozzle")
        if nozzle then
            local emitter = nozzle:FindFirstChild("ExhaustParticles")
            if not emitter then
                emitter = Instance.new("ParticleEmitter")
                emitter.Name = "ExhaustParticles"
                emitter.Color = ColorSequence.new(color, Color3.fromRGB(100, 100, 100))
                emitter.Size = NumberSequence.new(0.5, 2)
                emitter.Lifetime = NumberRange.new(0.3, 0.6)
                emitter.Rate = isBoosting and 100 or 50
                emitter.Speed = NumberRange.new(20, 40)
                emitter.Acceleration = Vector3.new(0, -5, 0)
                emitter.SpreadAngle = Vector2.new(10, 10)
                emitter.Parent = nozzle
            else
                emitter.Rate = isBoosting and 100 or 50
                emitter.Color = ColorSequence.new(color, Color3.fromRGB(100, 100, 100))
            end
        end
    end
end

-- Create detailed ring with 3D geometry
function JetSkyDetailed.CreateDetailedRing(position, value)
    value = value or 1
    local m = Instance.new("Model")
    m.Name = "DetailedRing_" .. value
    
    -- Main ring
    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Shape = Enum.PartType.Torus
    ring.Size = Vector3.new(GameData.RING_SIZE, 1, GameData.RING_SIZE)
    ring.Color = Color3.fromRGB(255, 215, 0)
    ring.Material = Enum.Material.Neon
    ring.Anchored = true
    ring.CanCollide = false
    ring.Position = position
    ring.Transparency = 0.2
    ring.Parent = m
    
    -- Inner energy field
    local inner = Instance.new("Part")
    inner.Name = "InnerField"
    inner.Shape = Enum.PartType.Ball
    inner.Size = Vector3.new(GameData.RING_SIZE * 0.5, GameData.RING_SIZE * 0.5, GameData.RING_SIZE * 0.5)
    inner.Color = Color3.fromRGB(100, 200, 255)
    inner.Material = Enum.Material.ForceField
    inner.Anchored = true
    inner.CanCollide = false
    inner.Position = position
    inner.Transparency = 0.7
    inner.Parent = m
    
    -- Collection trigger
    local trigger = Instance.new("Part")
    trigger.Name = "Trigger"
    trigger.Shape = Enum.PartType.Ball
    trigger.Size = Vector3.new(GameData.RING_SIZE + 5, GameData.RING_SIZE + 5, GameData.RING_SIZE + 5)
    trigger.Transparency = 1
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.Position = position
    trigger.Parent = m
    
    local val = Instance.new("IntValue")
    val.Name = "Value"
    val.Value = value
    val.Parent = trigger
    
    -- Spin animation script
    local spin = Instance.new("Script")
    spin.Name = "RingSpinner"
    spin.Source = [[
        local ring = script.Parent:FindFirstChild("Ring")
        if ring then
            while true do
                ring.CFrame = ring.CFrame * CFrame.Angles(0, 0.05, 0)
                task.wait(0.03)
            end
        end
    ]]
    spin.Parent = m
    
    return m
end

return JetSkyDetailed
