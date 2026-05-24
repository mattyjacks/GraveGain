-- DropDwarf: pickaxe/viewmodel.lua
-- Procedurally builds high-fidelity arm, sleeve, and pickaxe geometry on client.

local ViewModel = {}

-- Palette definitions
local SKIN_COLOR     = Color3.fromRGB(200, 155, 110)
local SKIN_DARK      = Color3.fromRGB(170, 120, 82)
local GLOVE_COLOR    = Color3.fromRGB(38, 30, 22)
local GLOVE_STITCH   = Color3.fromRGB(80, 60, 32)
local CUFF_COLOR     = Color3.fromRGB(55, 42, 28)
local VAMBRACE_COLOR = Color3.fromRGB(80, 76, 70)
local VAMBRACE_RIVET = Color3.fromRGB(110, 105, 95)
local HANDLE_COLOR   = Color3.fromRGB(92, 60, 28)
local HANDLE_LIGHT   = Color3.fromRGB(130, 88, 44)
local HANDLE_DARK    = Color3.fromRGB(60, 38, 14)
local CORD_COLOR     = Color3.fromRGB(58, 42, 22)
local FERRULE_COLOR  = Color3.fromRGB(72, 72, 80)
local HEAD_COLOR     = Color3.fromRGB(148, 148, 158)
local HEAD_LIGHT     = Color3.fromRGB(185, 185, 196)
local HEAD_DARK      = Color3.fromRGB(72, 72, 80)
local RUNE_COLOR     = Color3.fromRGB(60, 200, 180)
local TIP_COLOR      = Color3.fromRGB(210, 212, 220)
local BUTT_COLOR     = Color3.fromRGB(55, 55, 60)

local function makePart(parent, name, size, color, material, cframe)
    local p = Instance.new("Part")
    p.Name          = name
    p.Size          = size
    p.CFrame        = cframe or CFrame.new()
    p.Color         = color
    p.Material      = material or Enum.Material.SmoothPlastic
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Anchored      = false
    p.CanCollide    = false
    p.CastShadow    = false
    p.Parent        = parent
    return p
end

local function makeWedge(parent, name, size, color, material, cframe)
    local p = Instance.new("WedgePart")
    p.Name          = name
    p.Size          = size
    p.CFrame        = cframe or CFrame.new()
    p.Color         = color
    p.Material      = material or Enum.Material.SmoothPlastic
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Anchored      = false
    p.CanCollide    = false
    p.CastShadow    = false
    p.Parent        = parent
    return p
end

local function weld(part0, part1, c0)
    local w = Instance.new("WeldConstraint")
    w.Part0  = part0
    w.Part1  = part1
    w.Parent = part0
    if c0 then
        part1.CFrame = part0.CFrame * c0
    end
    return w
end

local function attach(root, part, c0)
    weld(root, part, c0)
end

function ViewModel.Build()
    local model = Instance.new("Model")
    model.Name   = "PickaxeViewModel"
    model.Parent = workspace

    local root = makePart(model, "Root", Vector3.new(0.05, 0.05, 0.05), Color3.new(0,0,0))
    root.Transparency = 1
    model.PrimaryPart = root

    -- Forearm + Vambrace
    local forearm = makePart(model, "Forearm", Vector3.new(0.22, 0.22, 0.55), SKIN_COLOR)
    attach(root, forearm, CFrame.new(0, -0.10, 0.30))

    local forearmSwell = makePart(model, "ForearmSwell", Vector3.new(0.20, 0.18, 0.38), SKIN_COLOR)
    attach(root, forearmSwell, CFrame.new(0.04, -0.08, 0.22))

    local vambrace = makePart(model, "Vambrace", Vector3.new(0.18, 0.06, 0.46), VAMBRACE_COLOR, Enum.Material.Metal)
    attach(root, vambrace, CFrame.new(0, -0.06, 0.27))

    local vambraceRidge = makePart(model, "VambraceRidge", Vector3.new(0.04, 0.04, 0.42), VAMBRACE_RIVET, Enum.Material.Metal)
    attach(root, vambraceRidge, CFrame.new(0, -0.03, 0.27))

    for _, rx in ipairs({-0.07, 0.07}) do
        for _, rz in ipairs({0.08, 0.44}) do
            local rivet = makePart(model, "VRivet", Vector3.new(0.04, 0.04, 0.04), VAMBRACE_RIVET, Enum.Material.Metal)
            attach(root, rivet, CFrame.new(rx, -0.03, rz))
        end
    end

    local cuff = makePart(model, "Cuff", Vector3.new(0.26, 0.07, 0.07), CUFF_COLOR)
    attach(root, cuff, CFrame.new(0, -0.09, 0.04))

    local cuffStitch = makePart(model, "CuffStitch", Vector3.new(0.24, 0.014, 0.014), GLOVE_STITCH)
    attach(root, cuffStitch, CFrame.new(0, -0.06, 0.04))

    -- Gloved Hand
    local palm = makePart(model, "Palm", Vector3.new(0.22, 0.14, 0.20), GLOVE_COLOR)
    attach(root, palm, CFrame.new(0, -0.10, -0.10))

    local knuckleRidge = makePart(model, "KnuckleRidge", Vector3.new(0.22, 0.03, 0.05), SKIN_DARK)
    attach(root, knuckleRidge, CFrame.new(0, -0.03, -0.14))

    local fingerOffsets = {
        { x = -0.09, name = "FingerIdx" },
        { x = -0.03, name = "FingerMid" },
        { x =  0.03, name = "FingerRng" },
        { x =  0.09, name = "FingerPnk" },
    }
    for _, fo in ipairs(fingerOffsets) do
        local fp = makePart(model, fo.name .. "_P", Vector3.new(0.052, 0.052, 0.12), GLOVE_COLOR)
        attach(root, fp, CFrame.new(fo.x, -0.16, -0.20) * CFrame.Angles(math.rad(22), 0, 0))
        
        local fm = makePart(model, fo.name .. "_M", Vector3.new(0.048, 0.048, 0.10), GLOVE_COLOR)
        attach(root, fm, CFrame.new(fo.x, -0.19, -0.30) * CFrame.Angles(math.rad(55), 0, 0))
        
        local fd = makePart(model, fo.name .. "_D", Vector3.new(0.044, 0.044, 0.072), GLOVE_COLOR)
        attach(root, fd, CFrame.new(fo.x, -0.14, -0.38) * CFrame.Angles(math.rad(80), 0, 0))
        
        local fk = makePart(model, fo.name .. "_K", Vector3.new(0.06, 0.05, 0.05), GLOVE_STITCH)
        attach(root, fk, CFrame.new(fo.x, -0.05, -0.18))
    end

    local thumbBase = makePart(model, "ThumbBase", Vector3.new(0.055, 0.055, 0.11), GLOVE_COLOR)
    attach(root, thumbBase, CFrame.new(-0.14, -0.11, -0.09) * CFrame.Angles(math.rad(10), math.rad(-30), math.rad(40)))
    
    local thumbTip = makePart(model, "ThumbTip", Vector3.new(0.048, 0.048, 0.085), GLOVE_COLOR)
    attach(root, thumbTip, CFrame.new(-0.18, -0.16, -0.17) * CFrame.Angles(math.rad(40), math.rad(-20), math.rad(30)))

    for i, fo in ipairs(fingerOffsets) do
        if i < 4 then
            local stitch = makePart(model, "Stitch" .. i, Vector3.new(0.01, 0.01, 0.14), GLOVE_STITCH)
            attach(root, stitch, CFrame.new(fo.x + 0.03, -0.04, -0.14) * CFrame.Angles(0, 0, math.rad(90)))
        end
    end

    -- Wooden Shaft
    local shaftA = makePart(model, "ShaftA", Vector3.new(0.115, 0.115, 1.02), HANDLE_COLOR, Enum.Material.Wood)
    attach(root, shaftA, CFrame.new(0, 0, -0.26))

    local shaftB = makePart(model, "ShaftB", Vector3.new(0.145, 0.072, 1.02), HANDLE_LIGHT, Enum.Material.Wood)
    attach(root, shaftB, CFrame.new(0, 0, -0.26) * CFrame.Angles(0, 0, math.rad(45)))

    local shaftC = makePart(model, "ShaftC", Vector3.new(0.145, 0.072, 1.02), HANDLE_DARK, Enum.Material.Wood)
    attach(root, shaftC, CFrame.new(0, 0, -0.26) * CFrame.Angles(0, 0, math.rad(-45)))

    local grain1 = makePart(model, "Grain1", Vector3.new(0.02, 0.016, 0.90), HANDLE_LIGHT, Enum.Material.Wood)
    attach(root, grain1, CFrame.new(0.04, 0.04, -0.24))
    
    local grain2 = makePart(model, "Grain2", Vector3.new(0.02, 0.016, 0.78), HANDLE_DARK, Enum.Material.Wood)
    attach(root, grain2, CFrame.new(-0.03, -0.03, -0.20))

    for i = 0, 9 do
        local cord = makePart(model, "Cord" .. i, Vector3.new(0.138, 0.028, 0.028), CORD_COLOR)
        attach(root, cord, CFrame.new(0, 0, 0.02 + i * 0.038) * CFrame.Angles(0, 0, math.rad(12 * (i % 2 == 0 and 1 or -1))))
    end

    local buttCap = makePart(model, "ButtCap", Vector3.new(0.155, 0.155, 0.045), BUTT_COLOR, Enum.Material.Metal)
    attach(root, buttCap, CFrame.new(0, 0, 0.52))
    
    local buttRim = makePart(model, "ButtRim", Vector3.new(0.175, 0.175, 0.018), FERRULE_COLOR, Enum.Material.Metal)
    attach(root, buttRim, CFrame.new(0, 0, 0.50))

    -- Ferrule Collar
    local ferruleA = makePart(model, "FerruleA", Vector3.new(0.155, 0.155, 0.055), FERRULE_COLOR, Enum.Material.Metal)
    attach(root, ferruleA, CFrame.new(0, 0, -0.70))

    local ferruleB = makePart(model, "FerruleB", Vector3.new(0.148, 0.148, 0.055), FERRULE_COLOR, Enum.Material.Metal)
    attach(root, ferruleB, CFrame.new(0, 0, -0.76))

    local ferruleGroove = makePart(model, "FerruleGroove", Vector3.new(0.145, 0.145, 0.018), HEAD_DARK, Enum.Material.Metal)
    attach(root, ferruleGroove, CFrame.new(0, 0, -0.73))

    -- Pickaxe Head
    local headBar = makePart(model, "HeadBar", Vector3.new(0.68, 0.145, 0.130), HEAD_COLOR, Enum.Material.Metal)
    attach(root, headBar, CFrame.new(0, 0.062, -0.82))

    local headBevelTop = makeWedge(model, "HeadBevelTop", Vector3.new(0.68, 0.055, 0.05), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, headBevelTop, CFrame.new(0, 0.138, -0.80) * CFrame.Angles(0, math.pi, 0))

    local headBevelBot = makeWedge(model, "HeadBevelBot", Vector3.new(0.68, 0.040, 0.04), HEAD_DARK, Enum.Material.Metal)
    attach(root, headBevelBot, CFrame.new(0, -0.012, -0.80))

    local eyeRecess = makePart(model, "EyeRecess", Vector3.new(0.13, 0.13, 0.145), HEAD_DARK, Enum.Material.Metal)
    attach(root, eyeRecess, CFrame.new(0, 0.062, -0.82))

    -- Pick Spike
    local pickBase = makePart(model, "PickBase", Vector3.new(0.115, 0.115, 0.28), HEAD_COLOR, Enum.Material.Metal)
    attach(root, pickBase, CFrame.new(-0.34, 0.055, -0.89) * CFrame.Angles(0, 0, math.rad(-4)))

    local twistA = makePart(model, "PickTwistA", Vector3.new(0.04, 0.095, 0.26), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, twistA, CFrame.new(-0.34, 0.055, -0.89) * CFrame.Angles(0, 0, math.rad(28)))
    
    local twistB = makePart(model, "PickTwistB", Vector3.new(0.04, 0.095, 0.26), HEAD_DARK, Enum.Material.Metal)
    attach(root, twistB, CFrame.new(-0.34, 0.055, -0.89) * CFrame.Angles(0, 0, math.rad(-28)))

    local pickMid = makeWedge(model, "PickMid", Vector3.new(0.095, 0.095, 0.26), HEAD_COLOR, Enum.Material.Metal)
    attach(root, pickMid, CFrame.new(-0.52, 0.048, -0.89) * CFrame.Angles(0, math.pi / 2, math.rad(-4)))

    local pickTip = makeWedge(model, "PickTip", Vector3.new(0.052, 0.052, 0.18), TIP_COLOR, Enum.Material.Metal)
    attach(root, pickTip, CFrame.new(-0.65, 0.040, -0.89) * CFrame.Angles(0, math.pi / 2, math.rad(-4)))

    local pickNeedle = makeWedge(model, "PickNeedle", Vector3.new(0.022, 0.022, 0.10), TIP_COLOR, Enum.Material.Metal)
    attach(root, pickNeedle, CFrame.new(-0.72, 0.036, -0.89) * CFrame.Angles(0, math.pi / 2, 0))

    local pickEdge = makePart(model, "PickEdge", Vector3.new(0.012, 0.010, 0.70), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, pickEdge, CFrame.new(-0.36, 0.110, -0.89) * CFrame.Angles(0, 0, math.rad(-3)))

    -- Adze / Poll End
    local pollBody = makePart(model, "PollBody", Vector3.new(0.115, 0.130, 0.115), HEAD_COLOR, Enum.Material.Metal)
    attach(root, pollBody, CFrame.new(0.30, 0.060, -0.82))

    local pollFace = makePart(model, "PollFace", Vector3.new(0.025, 0.115, 0.105), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, pollFace, CFrame.new(0.360, 0.060, -0.82))

    local pollBevelTop = makeWedge(model, "PollBevelTop", Vector3.new(0.105, 0.040, 0.04), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, pollBevelTop, CFrame.new(0.300, 0.128, -0.82) * CFrame.Angles(0, math.pi, 0))

    local pollBevelBot = makeWedge(model, "PollBevelBot", Vector3.new(0.105, 0.030, 0.04), HEAD_DARK, Enum.Material.Metal)
    attach(root, pollBevelBot, CFrame.new(0.300, -0.008, -0.82))

    -- Dwarven Rune Etching
    local runeStrip = makePart(model, "RuneStrip", Vector3.new(0.44, 0.028, 0.012), RUNE_COLOR, Enum.Material.Neon)
    runeStrip.Transparency = 0.25
    attach(root, runeStrip, CFrame.new(-0.04, 0.062, -0.752))

    local runePositions = { -0.22, -0.12, -0.02, 0.08, 0.17 }
    for i, rx in ipairs(runePositions) do
        local rune = makePart(model, "Rune" .. i, Vector3.new(0.016, 0.038, 0.009), RUNE_COLOR, Enum.Material.Neon)
        rune.Transparency = 0.0
        attach(root, rune, CFrame.new(rx, 0.062, -0.748))
    end

    local runeGlow = makePart(model, "RuneGlow", Vector3.new(0.50, 0.060, 0.020), RUNE_COLOR, Enum.Material.Neon)
    runeGlow.Transparency = 0.72
    attach(root, runeGlow, CFrame.new(-0.04, 0.062, -0.750))

    local ferruleMark = makePart(model, "FerruleMark", Vector3.new(0.06, 0.06, 0.018), RUNE_COLOR, Enum.Material.Neon)
    ferruleMark.Transparency = 0.3
    attach(root, ferruleMark, CFrame.new(0, 0.062, -0.740))

    -- Wear details
    local wearA = makePart(model, "WearA", Vector3.new(0.300, 0.008, 0.009), HEAD_DARK, Enum.Material.Metal)
    attach(root, wearA, CFrame.new(-0.12, 0.142, -0.82))
    
    local wearB = makePart(model, "WearB", Vector3.new(0.200, 0.006, 0.009), HEAD_DARK, Enum.Material.Metal)
    attach(root, wearB, CFrame.new(-0.20, -0.014, -0.82) * CFrame.Angles(0, 0, math.rad(8)))
    
    local wearC = makePart(model, "WearC", Vector3.new(0.018, 0.018, 0.022), HEAD_DARK, Enum.Material.Metal)
    attach(root, wearC, CFrame.new(-0.50, 0.040, -0.86))

    return model, root
end

return ViewModel
