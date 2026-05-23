-- DropDwarf: pickaxe_model.lua
-- Procedurally generates a first-person pickaxe viewmodel.
-- Supports light swing (left-click) and heavy charged swing (hold left-click).
-- Terrain type interaction: Soft/Firm/Hard determines carve vs bounce behavior.

local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local Networking = require(game.ReplicatedStorage.Shared.networking)

local PickaxeModel = {}
PickaxeModel.__index = PickaxeModel

local BOB_SPEED      = 8
local BOB_AMOUNT     = 0.045
local SWAY_AMOUNT    = 0.015
local SWING_DURATION = 0.35
local HEAVY_CHARGE_TIME  = 0.6
local HEAVY_SWING_DURATION = 0.5
local HIT_RANGE      = 6
local IDLE_BREATH_SPEED  = 1.4   -- gentle idle breathing oscillation
local IDLE_BREATH_AMOUNT = 0.012

local SOFT_FALL_BLEED = 18
local BOUNCE_IMPULSE  = 22

-- Pickaxe palette
local HANDLE_COLOR   = Color3.fromRGB(92, 60, 28)    -- dark walnut
local HANDLE_LIGHT   = Color3.fromRGB(130, 88, 44)   -- lighter wood grain
local HANDLE_DARK    = Color3.fromRGB(60, 38, 14)    -- shadow groove
local CORD_COLOR     = Color3.fromRGB(58, 42, 22)    -- wrapped leather cord
local FERRULE_COLOR  = Color3.fromRGB(72, 72, 80)    -- dull iron ferrule band
local HEAD_COLOR     = Color3.fromRGB(148, 148, 158) -- cold forged iron
local HEAD_LIGHT     = Color3.fromRGB(185, 185, 196) -- polished face highlight
local HEAD_DARK      = Color3.fromRGB(72, 72, 80)    -- recessed shadow
local RUNE_COLOR     = Color3.fromRGB(60, 200, 180)  -- dwarven teal-glow rune
local TIP_COLOR      = Color3.fromRGB(210, 212, 220) -- sharpened pick tip
local BUTT_COLOR     = Color3.fromRGB(55, 55, 60)    -- pommel cap

-- Hand / arm palette
local SKIN_COLOR     = Color3.fromRGB(200, 155, 110) -- mid-tone skin
local SKIN_DARK      = Color3.fromRGB(170, 120, 82)  -- knuckle shadow
local GLOVE_COLOR    = Color3.fromRGB(38, 30, 22)    -- dark leather glove
local GLOVE_STITCH   = Color3.fromRGB(80, 60, 32)    -- stitch highlight
local CUFF_COLOR     = Color3.fromRGB(55, 42, 28)    -- leather cuff band
local VAMBRACE_COLOR = Color3.fromRGB(80, 76, 70)    -- iron vambrace plate
local VAMBRACE_RIVET = Color3.fromRGB(110, 105, 95)  -- rivet highlight

function PickaxeModel.new(camera)
    local self = setmetatable({}, PickaxeModel)
    self.camera         = camera
    self.model          = nil
    self.parts          = {}
    self.connection     = nil
    self.bobTime        = 0
    self.breathTime     = 0
    self.isSwinging     = false
    self.swingTime      = 0
    self.isHeavySwing   = false
    self.chargeTime     = 0
    self.isCharging     = false
    -- Positioned so the hand/arm sit in the lower-right of the view
    self.baseOffset     = CFrame.new(0.52, -0.72, -1.4)
    self.currentOffset  = self.baseOffset
    self.movementRef    = nil
    self.player         = Players.LocalPlayer
    return self
end

-- Wire in the movement system so pickaxe can read currentTerrainType
function PickaxeModel:SetMovement(movement)
    self.movementRef = movement
end

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

-- Shorthand: weld part1 to root offset by c0 CFrame
local function attach(root, part, c0)
    weld(root, part, c0)
end

function PickaxeModel:Build()
    local model = Instance.new("Model")
    model.Name   = "PickaxeViewModel"
    model.Parent = workspace

    -- Invisible root anchor - all parts weld to this
    local root = makePart(model, "Root",
        Vector3.new(0.05, 0.05, 0.05), Color3.new(0,0,0))
    root.Transparency = 1
    model.PrimaryPart = root

    -- ================================================================
    -- FOREARM + VAMBRACE
    -- The forearm is the lower arm, ending at the wrist.
    -- An iron vambrace (plate) sits on the back of the arm.
    -- ================================================================

    -- Main forearm cylinder (slightly tapered - wider at elbow end)
    local forearm = makePart(model, "Forearm",
        Vector3.new(0.22, 0.22, 0.55), SKIN_COLOR, Enum.Material.SmoothPlastic)
    attach(root, forearm, CFrame.new(0, -0.10, 0.30))

    -- Forearm side muscle swell (slight bulge on outer side)
    local forearmSwell = makePart(model, "ForearmSwell",
        Vector3.new(0.20, 0.18, 0.38), SKIN_COLOR, Enum.Material.SmoothPlastic)
    attach(root, forearmSwell, CFrame.new(0.04, -0.08, 0.22))

    -- Iron vambrace plate (back of forearm)
    local vambrace = makePart(model, "Vambrace",
        Vector3.new(0.18, 0.06, 0.46), VAMBRACE_COLOR, Enum.Material.Metal)
    attach(root, vambrace, CFrame.new(0, -0.06, 0.27))

    -- Vambrace centre ridge (raised spine down the middle)
    local vambraceRidge = makePart(model, "VambraceRidge",
        Vector3.new(0.04, 0.04, 0.42), VAMBRACE_RIVET, Enum.Material.Metal)
    attach(root, vambraceRidge, CFrame.new(0, -0.03, 0.27))

    -- Vambrace rivets (4 corner bolts)
    for _, rx in ipairs({-0.07, 0.07}) do
        for _, rz in ipairs({0.08, 0.44}) do
            local rivet = makePart(model, "VRivet",
                Vector3.new(0.04, 0.04, 0.04), VAMBRACE_RIVET, Enum.Material.Metal)
            attach(root, rivet, CFrame.new(rx, -0.03, rz))
        end
    end

    -- Leather cuff band at wrist
    local cuff = makePart(model, "Cuff",
        Vector3.new(0.26, 0.07, 0.07), CUFF_COLOR, Enum.Material.SmoothPlastic)
    attach(root, cuff, CFrame.new(0, -0.09, 0.04))

    -- Cuff stitch line
    local cuffStitch = makePart(model, "CuffStitch",
        Vector3.new(0.24, 0.014, 0.014), GLOVE_STITCH, Enum.Material.SmoothPlastic)
    attach(root, cuffStitch, CFrame.new(0, -0.06, 0.04))

    -- ================================================================
    -- HAND (GLOVED)
    -- Palm block + 4 fingers + thumb, all in dark leather glove.
    -- ================================================================

    -- Palm (main block)
    local palm = makePart(model, "Palm",
        Vector3.new(0.22, 0.14, 0.20), GLOVE_COLOR, Enum.Material.SmoothPlastic)
    attach(root, palm, CFrame.new(0, -0.10, -0.10))

    -- Palm knuckle ridge (raised row across top)
    local knuckleRidge = makePart(model, "KnuckleRidge",
        Vector3.new(0.22, 0.03, 0.05), SKIN_DARK, Enum.Material.SmoothPlastic)
    attach(root, knuckleRidge, CFrame.new(0, -0.03, -0.14))

    -- 4 fingers (curled down around the handle)
    local fingerOffsets = {
        { x = -0.09, name = "FingerIdx" },
        { x = -0.03, name = "FingerMid" },
        { x =  0.03, name = "FingerRng" },
        { x =  0.09, name = "FingerPnk" },
    }
    for _, fo in ipairs(fingerOffsets) do
        -- Proximal phalanx (back knuckle)
        local fp = makePart(model, fo.name .. "_P",
            Vector3.new(0.052, 0.052, 0.12), GLOVE_COLOR, Enum.Material.SmoothPlastic)
        attach(root, fp,
            CFrame.new(fo.x, -0.16, -0.20) * CFrame.Angles(math.rad(22), 0, 0))
        -- Middle phalanx (curling inward)
        local fm = makePart(model, fo.name .. "_M",
            Vector3.new(0.048, 0.048, 0.10), GLOVE_COLOR, Enum.Material.SmoothPlastic)
        attach(root, fm,
            CFrame.new(fo.x, -0.19, -0.30) * CFrame.Angles(math.rad(55), 0, 0))
        -- Distal phalanx (fingertip)
        local fd = makePart(model, fo.name .. "_D",
            Vector3.new(0.044, 0.044, 0.072), GLOVE_COLOR, Enum.Material.SmoothPlastic)
        attach(root, fd,
            CFrame.new(fo.x, -0.14, -0.38) * CFrame.Angles(math.rad(80), 0, 0))
        -- Knuckle bump (sphere-ish highlight at each knuckle)
        local fk = makePart(model, fo.name .. "_K",
            Vector3.new(0.06, 0.05, 0.05), GLOVE_STITCH, Enum.Material.SmoothPlastic)
        attach(root, fk, CFrame.new(fo.x, -0.05, -0.18))
    end

    -- Thumb (angled outward/downward)
    local thumbBase = makePart(model, "ThumbBase",
        Vector3.new(0.055, 0.055, 0.11), GLOVE_COLOR, Enum.Material.SmoothPlastic)
    attach(root, thumbBase,
        CFrame.new(-0.14, -0.11, -0.09) * CFrame.Angles(math.rad(10), math.rad(-30), math.rad(40)))
    local thumbTip = makePart(model, "ThumbTip",
        Vector3.new(0.048, 0.048, 0.085), GLOVE_COLOR, Enum.Material.SmoothPlastic)
    attach(root, thumbTip,
        CFrame.new(-0.18, -0.16, -0.17) * CFrame.Angles(math.rad(40), math.rad(-20), math.rad(30)))

    -- Glove stitching lines across back of hand
    for i, fo in ipairs(fingerOffsets) do
        if i < 4 then
            local stitch = makePart(model, "Stitch" .. i,
                Vector3.new(0.01, 0.01, 0.14), GLOVE_STITCH, Enum.Material.SmoothPlastic)
            attach(root, stitch,
                CFrame.new(fo.x + 0.03, -0.04, -0.14) * CFrame.Angles(0, 0, math.rad(90)))
        end
    end

    -- ================================================================
    -- WOODEN SHAFT
    -- Octagonal cross-section faked with layered boxes.
    -- Leather cord wrapping in lower grip zone.
    -- Butt cap at the bottom end.
    -- ================================================================

    -- Main shaft core (round-ish - three overlapping boxes = approx octagon)
    local shaftA = makePart(model, "ShaftA",
        Vector3.new(0.115, 0.115, 1.02), HANDLE_COLOR, Enum.Material.Wood)
    attach(root, shaftA, CFrame.new(0, 0, -0.26))

    local shaftB = makePart(model, "ShaftB",
        Vector3.new(0.145, 0.072, 1.02), HANDLE_LIGHT, Enum.Material.Wood)
    attach(root, shaftB, CFrame.new(0, 0, -0.26) * CFrame.Angles(0, 0, math.rad(45)))

    local shaftC = makePart(model, "ShaftC",
        Vector3.new(0.145, 0.072, 1.02), HANDLE_DARK, Enum.Material.Wood)
    attach(root, shaftC, CFrame.new(0, 0, -0.26) * CFrame.Angles(0, 0, math.rad(-45)))

    -- Wood grain stripe (subtle lighter line)
    local grain1 = makePart(model, "Grain1",
        Vector3.new(0.02, 0.016, 0.90), HANDLE_LIGHT, Enum.Material.Wood)
    attach(root, grain1, CFrame.new(0.04, 0.04, -0.24))
    local grain2 = makePart(model, "Grain2",
        Vector3.new(0.02, 0.016, 0.78), HANDLE_DARK, Enum.Material.Wood)
    attach(root, grain2, CFrame.new(-0.03, -0.03, -0.20))

    -- Leather cord wrap (grip zone, lower third of shaft)
    -- Tight diagonal bands simulating real wrapped cord
    for i = 0, 9 do
        local cord = makePart(model, "Cord" .. i,
            Vector3.new(0.138, 0.028, 0.028), CORD_COLOR, Enum.Material.SmoothPlastic)
        attach(root, cord,
            CFrame.new(0, 0, 0.02 + i * 0.038)
            * CFrame.Angles(0, 0, math.rad(12 * (i % 2 == 0 and 1 or -1))))
    end

    -- Butt cap (pommel end - flat iron disc)
    local buttCap = makePart(model, "ButtCap",
        Vector3.new(0.155, 0.155, 0.045), BUTT_COLOR, Enum.Material.Metal)
    attach(root, buttCap, CFrame.new(0, 0, 0.52))
    local buttRim = makePart(model, "ButtRim",
        Vector3.new(0.175, 0.175, 0.018), FERRULE_COLOR, Enum.Material.Metal)
    attach(root, buttRim, CFrame.new(0, 0, 0.50))

    -- ================================================================
    -- FERRULE (metal collar where shaft meets head)
    -- Double-band with a centre groove.
    -- ================================================================

    local ferruleA = makePart(model, "FerruleA",
        Vector3.new(0.155, 0.155, 0.055), FERRULE_COLOR, Enum.Material.Metal)
    attach(root, ferruleA, CFrame.new(0, 0, -0.70))

    local ferruleB = makePart(model, "FerruleB",
        Vector3.new(0.148, 0.148, 0.055), FERRULE_COLOR, Enum.Material.Metal)
    attach(root, ferruleB, CFrame.new(0, 0, -0.76))

    -- Ferrule groove (dark recessed centre ring)
    local ferruleGroove = makePart(model, "FerruleGroove",
        Vector3.new(0.145, 0.145, 0.018), HEAD_DARK, Enum.Material.Metal)
    attach(root, ferruleGroove, CFrame.new(0, 0, -0.73))

    -- ================================================================
    -- PICKAXE HEAD
    -- Thick forged iron bar, beveled faces on poll/adze end,
    -- long tapered pick spike with twist, sharpened tip.
    -- ================================================================

    -- Main head bar (horizontal, perpendicular to shaft)
    -- Wider faces on front/back, narrower on top
    local headBar = makePart(model, "HeadBar",
        Vector3.new(0.68, 0.145, 0.130), HEAD_COLOR, Enum.Material.Metal)
    attach(root, headBar, CFrame.new(0, 0.062, -0.82))

    -- Head bar top bevel (angled top edge)
    local headBevelTop = makeWedge(model, "HeadBevelTop",
        Vector3.new(0.68, 0.055, 0.05), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, headBevelTop,
        CFrame.new(0, 0.138, -0.80) * CFrame.Angles(0, math.pi, 0))

    -- Head bar bottom bevel
    local headBevelBot = makeWedge(model, "HeadBevelBot",
        Vector3.new(0.68, 0.040, 0.04), HEAD_DARK, Enum.Material.Metal)
    attach(root, headBevelBot, CFrame.new(0, -0.012, -0.80))

    -- Centre eye hole (where shaft passes through - decorative recess)
    local eyeRecess = makePart(model, "EyeRecess",
        Vector3.new(0.13, 0.13, 0.145), HEAD_DARK, Enum.Material.Metal)
    attach(root, eyeRecess, CFrame.new(0, 0.062, -0.82))

    -- ---- PICK SPIKE (left / forward end) ----
    -- Long tapered section in three segments:
    -- base (thick), mid (taper), and needle tip

    local pickBase = makePart(model, "PickBase",
        Vector3.new(0.115, 0.115, 0.28), HEAD_COLOR, Enum.Material.Metal)
    attach(root, pickBase,
        CFrame.new(-0.34, 0.055, -0.89) * CFrame.Angles(0, 0, math.rad(-4)))

    -- Subtle twist facets on the pick (two thin strips rotated ~30 deg)
    local twistA = makePart(model, "PickTwistA",
        Vector3.new(0.04, 0.095, 0.26), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, twistA,
        CFrame.new(-0.34, 0.055, -0.89) * CFrame.Angles(0, 0, math.rad(28)))
    local twistB = makePart(model, "PickTwistB",
        Vector3.new(0.04, 0.095, 0.26), HEAD_DARK, Enum.Material.Metal)
    attach(root, twistB,
        CFrame.new(-0.34, 0.055, -0.89) * CFrame.Angles(0, 0, math.rad(-28)))

    local pickMid = makeWedge(model, "PickMid",
        Vector3.new(0.095, 0.095, 0.26), HEAD_COLOR, Enum.Material.Metal)
    attach(root, pickMid,
        CFrame.new(-0.52, 0.048, -0.89) * CFrame.Angles(0, math.pi / 2, math.rad(-4)))

    local pickTip = makeWedge(model, "PickTip",
        Vector3.new(0.052, 0.052, 0.18), TIP_COLOR, Enum.Material.Metal)
    attach(root, pickTip,
        CFrame.new(-0.65, 0.040, -0.89) * CFrame.Angles(0, math.pi / 2, math.rad(-4)))

    -- Pick tip final needle (sharpest point)
    local pickNeedle = makeWedge(model, "PickNeedle",
        Vector3.new(0.022, 0.022, 0.10), TIP_COLOR, Enum.Material.Metal)
    attach(root, pickNeedle,
        CFrame.new(-0.72, 0.036, -0.89) * CFrame.Angles(0, math.pi / 2, 0))

    -- Edge highlight on pick top edge (polished bevel strip)
    local pickEdge = makePart(model, "PickEdge",
        Vector3.new(0.012, 0.010, 0.70), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, pickEdge,
        CFrame.new(-0.36, 0.110, -0.89) * CFrame.Angles(0, 0, math.rad(-3)))

    -- ---- ADZE / POLL (right / backward end) ----
    -- Shorter, wider, flatter - like a hammerhead for driving pitons

    local pollBody = makePart(model, "PollBody",
        Vector3.new(0.115, 0.130, 0.115), HEAD_COLOR, Enum.Material.Metal)
    attach(root, pollBody,
        CFrame.new(0.30, 0.060, -0.82))

    -- Poll front face (polished flat striking surface)
    local pollFace = makePart(model, "PollFace",
        Vector3.new(0.025, 0.115, 0.105), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, pollFace, CFrame.new(0.360, 0.060, -0.82))

    -- Poll bevel top
    local pollBevelTop = makeWedge(model, "PollBevelTop",
        Vector3.new(0.105, 0.040, 0.04), HEAD_LIGHT, Enum.Material.Metal)
    attach(root, pollBevelTop,
        CFrame.new(0.300, 0.128, -0.82) * CFrame.Angles(0, math.pi, 0))

    -- Poll bevel bottom
    local pollBevelBot = makeWedge(model, "PollBevelBot",
        Vector3.new(0.105, 0.030, 0.04), HEAD_DARK, Enum.Material.Metal)
    attach(root, pollBevelBot, CFrame.new(0.300, -0.008, -0.82))

    -- ---- DWARVEN RUNE ETCHING ----
    -- Glowing teal neon strip on the flat of the head bar,
    -- representing ancient dwarven script

    local runeStrip = makePart(model, "RuneStrip",
        Vector3.new(0.44, 0.028, 0.012), RUNE_COLOR, Enum.Material.Neon)
    runeStrip.Transparency = 0.25
    attach(root, runeStrip, CFrame.new(-0.04, 0.062, -0.752))

    -- Individual rune glyphs (small bright rectangles in the strip)
    local runePositions = { -0.22, -0.12, -0.02, 0.08, 0.17 }
    for i, rx in ipairs(runePositions) do
        local rune = makePart(model, "Rune" .. i,
            Vector3.new(0.016, 0.038, 0.009), RUNE_COLOR, Enum.Material.Neon)
        rune.Transparency = 0.0
        attach(root, rune, CFrame.new(rx, 0.062, -0.748))
    end

    -- Ambient glow halo (very transparent, slightly larger strip)
    local runeGlow = makePart(model, "RuneGlow",
        Vector3.new(0.50, 0.060, 0.020), RUNE_COLOR, Enum.Material.Neon)
    runeGlow.Transparency = 0.72
    attach(root, runeGlow, CFrame.new(-0.04, 0.062, -0.750))

    -- Rune etching on neck/ferrule face (small circular mark)
    local ferruleMark = makePart(model, "FerruleMark",
        Vector3.new(0.06, 0.06, 0.018), RUNE_COLOR, Enum.Material.Neon)
    ferruleMark.Transparency = 0.3
    attach(root, ferruleMark, CFrame.new(0, 0.062, -0.740))

    -- ---- WEAR DETAILS ----
    -- Dark streaks and chips on the head to sell it as used
    local wearA = makePart(model, "WearA",
        Vector3.new(0.300, 0.008, 0.009), HEAD_DARK, Enum.Material.Metal)
    attach(root, wearA, CFrame.new(-0.12, 0.142, -0.82))
    local wearB = makePart(model, "WearB",
        Vector3.new(0.200, 0.006, 0.009), HEAD_DARK, Enum.Material.Metal)
    attach(root, wearB, CFrame.new(-0.20, -0.014, -0.82) * CFrame.Angles(0, 0, math.rad(8)))
    -- Small nick on pick edge
    local wearC = makePart(model, "WearC",
        Vector3.new(0.018, 0.018, 0.022), HEAD_DARK, Enum.Material.Metal)
    attach(root, wearC, CFrame.new(-0.50, 0.040, -0.86))

    self.model = model
    self.root  = root
    return self
end

function PickaxeModel:Destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
end

-- ============================================================
-- TERRAIN HIT HELPERS
-- ============================================================

-- Raycast from camera forward to find terrain
local function raycastTerrain(camera, char)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local origin    = camera.CFrame.Position
    local direction = camera.CFrame.LookVector * HIT_RANGE
    return workspace:Raycast(origin, direction, rayParams)
end

-- Stamp a carve mark decal on a part at a world position
local function spawnCarveMark(pos, normal, terrainType)
    local mark = Instance.new("Part")
    mark.Name        = "CarveMark"
    mark.Size        = Vector3.new(0.6, 0.6, 0.15)
    mark.Anchored    = true
    mark.CanCollide  = false
    mark.CastShadow  = false
    local col = terrainType == "Soft"
        and Color3.fromRGB(60, 40, 20)
        or Color3.fromRGB(100, 95, 85)
    mark.Color    = col
    mark.Material = Enum.Material.SmoothPlastic
    -- Orient the mark to face the hit normal
    mark.CFrame   = CFrame.new(pos, pos + normal) * CFrame.Angles(0, 0, math.pi / 2)
    mark.Parent   = workspace
    -- Fade and remove after 8s
    TweenService:Create(mark, TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = 1 }):Play()
    task.delay(8.1, function()
        if mark.Parent then mark:Destroy() end
    end)
end

-- Apply a bounce impulse upward/backward to the HRP
local function applyBounce(player, impulse)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name      = "PickaxeBounce"
    bv.Velocity  = Vector3.new(hrp.CFrame.LookVector.X * -impulse * 0.4,
                               impulse * 0.7,
                               hrp.CFrame.LookVector.Z * -impulse * 0.4)
    bv.MaxForce  = Vector3.new(1e4, 1e4, 1e4)
    bv.Parent    = hrp
    task.delay(0.15, function()
        if bv.Parent then bv:Destroy() end
    end)
end

-- Reduce the player's vertical velocity (soft terrain pickaxe grab)
local function reduceVerticalVelocity(player, reduction)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local vel = hrp.AssemblyLinearVelocity
    local newVelY = math.max(vel.Y, vel.Y + reduction) -- reduction is positive = upward
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.5, newVelY, vel.Z * 0.5)
end

-- ============================================================
-- ORE MINING VFX
-- ============================================================

-- Chip particle burst when pickaxe hits ore (client-side)
local function spawnOreChips(pos, oreColor)
    for i = 1, 6 do
        local chip = Instance.new("Part")
        chip.Name        = "OreChip"
        chip.Size        = Vector3.new(
            math.random(10, 30) / 100,
            math.random(10, 30) / 100,
            math.random(10, 30) / 100)
        chip.Position    = pos + Vector3.new(
            math.random(-8, 8) / 10,
            math.random(0, 8) / 10,
            math.random(-8, 8) / 10)
        chip.Color       = oreColor
        chip.Material    = Enum.Material.SmoothPlastic
        chip.Anchored    = false
        chip.CanCollide  = false
        chip.CastShadow  = false
        chip.TopSurface  = Enum.SurfaceType.Smooth
        chip.BottomSurface = Enum.SurfaceType.Smooth
        chip.Parent      = workspace
        chip.AssemblyLinearVelocity = Vector3.new(
            math.random(-12, 12),
            math.random(4, 14),
            math.random(-12, 12))
        TweenService:Create(chip,
            TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = 1, Size = Vector3.new(0.02, 0.02, 0.02) }):Play()
        task.delay(0.65, function()
            if chip.Parent then chip:Destroy() end
        end)
    end
end

-- Depletion burst: bigger explosion of sparks + floating gold text
local function spawnOreDepletion(pos, oreType, goldEarned)
    -- Sparkle ring
    for i = 1, 14 do
        local angle = (i / 14) * math.pi * 2
        local spark = Instance.new("Part")
        spark.Name       = "OreSpark"
        spark.Size       = Vector3.new(0.18, 0.18, 0.18)
        spark.Position   = pos
        spark.Color      = Color3.fromRGB(255, 210, 50)  -- gold spark
        spark.Material   = Enum.Material.Neon
        spark.Anchored   = false
        spark.CanCollide = false
        spark.CastShadow = false
        spark.TopSurface = Enum.SurfaceType.Smooth
        spark.BottomSurface = Enum.SurfaceType.Smooth
        spark.Parent     = workspace
        spark.AssemblyLinearVelocity = Vector3.new(
            math.cos(angle) * math.random(8, 18),
            math.random(6, 16),
            math.sin(angle) * math.random(8, 18))
        TweenService:Create(spark,
            TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = 1, Size = Vector3.new(0.02, 0.02, 0.02) }):Play()
        task.delay(0.75, function()
            if spark.Parent then spark:Destroy() end
        end)
    end
    -- Floating "+N gold" billboard label
    if goldEarned and goldEarned > 0 then
        local billboard = Instance.new("Part")
        billboard.Size        = Vector3.new(0.1, 0.1, 0.1)
        billboard.Position    = pos + Vector3.new(0, 2, 0)
        billboard.Anchored    = true
        billboard.CanCollide  = false
        billboard.Transparency = 1
        billboard.CastShadow  = false
        billboard.Parent      = workspace
        local bg = Instance.new("BillboardGui")
        bg.Size           = UDim2.new(0, 80, 0, 32)
        bg.StudsOffset    = Vector3.new(0, 1, 0)
        bg.AlwaysOnTop    = false
        bg.Parent         = billboard
        local lbl = Instance.new("TextLabel")
        lbl.Size          = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text          = "+" .. goldEarned .. " GOLD"
        lbl.TextColor3    = Color3.fromRGB(255, 215, 50)
        lbl.TextStrokeColor3 = Color3.fromRGB(80, 50, 0)
        lbl.TextStrokeTransparency = 0.4
        lbl.Font          = Enum.Font.GothamBold
        lbl.TextScaled    = true
        lbl.Parent        = bg
        -- Float upward and fade
        TweenService:Create(billboard,
            TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = pos + Vector3.new(0, 6, 0) }):Play()
        TweenService:Create(lbl,
            TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
        task.delay(1.5, function()
            if billboard.Parent then billboard:Destroy() end
        end)
    end
end

-- Crack overlay flash when ore is hit but not yet depleted
local function spawnOreCrack(pos, hpLeft, hpMax)
    local crackColor = Color3.fromRGB(
        math.floor(255 * (1 - hpLeft / hpMax)),
        math.floor(200 * (hpLeft / hpMax)),
        50)
    local flash = Instance.new("Part")
    flash.Size        = Vector3.new(1.2, 1.2, 0.05)
    flash.CFrame      = CFrame.new(pos)
    flash.Anchored    = true
    flash.CanCollide  = false
    flash.CastShadow  = false
    flash.Color       = crackColor
    flash.Material    = Enum.Material.Neon
    flash.Transparency = 0.3
    flash.Parent      = workspace
    TweenService:Create(flash,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = 1, Size = Vector3.new(2, 2, 0.02) }):Play()
    task.delay(0.4, function()
        if flash.Parent then flash:Destroy() end
    end)
end

-- Process a terrain hit based on terrain type and swing heaviness
local function processTerrain(self, hitResult, isHeavy)
    if not hitResult then return end
    local instance = hitResult.Instance
    if not instance then return end

    -- Skip non-terrain instances
    if instance.Name == "GoldCoin" or instance.Name == "SlimeCube" then return end
    if instance:FindFirstChild("IsCoin") then return end

    -- ---- WALL ORE HIT ----
    if instance.Name == "WallOre" and instance:FindFirstChild("IsMineable") then
        -- Chips VFX immediately (client-side, no server round-trip needed for feel)
        spawnOreChips(hitResult.Position, instance.Color)
        -- Notify server to deduct HP and award gold
        Networking.FireServer(Networking.Events.MineWall, instance)
        return  -- don't apply terrain bounce/carve
    end

    local terrainTag = instance:FindFirstChild("TerrainType")
    local terrainType = terrainTag and terrainTag.Value or "Firm"

    -- Carve mark always appears
    spawnCarveMark(hitResult.Position, hitResult.Normal, terrainType)

    -- Notify server (cosmetic/logging only)
    Networking.FireServer(Networking.Events.PickaxeTerrainHit, hitResult.Position, terrainType)

    if terrainType == "Soft" then
        -- Pickaxe sticks in: reduce fall speed, carve line (handled above)
        reduceVerticalVelocity(self.player, SOFT_FALL_BLEED)
        -- Extra carve scratch below hit point
        for i = 1, 3 do
            local scratchPos = hitResult.Position + Vector3.new(0, -i * 0.25, 0)
            spawnCarveMark(scratchPos, hitResult.Normal, terrainType)
        end

    elseif terrainType == "Firm" then
        if isHeavy then
            -- Heavy swing breaks through Firm
            reduceVerticalVelocity(self.player, SOFT_FALL_BLEED * 0.5)
        else
            -- Light swing bounces off Firm
            applyBounce(self.player, BOUNCE_IMPULSE * 0.8)
        end

    elseif terrainType == "Hard" then
        -- Hard always bounces regardless of swing type
        applyBounce(self.player, BOUNCE_IMPULSE * 1.2)
    end
end

-- Start rendering the viewmodel
function PickaxeModel:Start(isMovingFn, isFallingFn)
    self:Build()
    self.isMovingFn  = isMovingFn  or function() return false end
    self.isFallingFn = isFallingFn or function() return false end

    -- Input: left-click begins charging, release fires swing
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not self.isSwinging then
                self.isCharging = true
                self.chargeTime = 0
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.isCharging then
                self.isCharging   = false
                self.isHeavySwing = self.chargeTime >= HEAVY_CHARGE_TIME
                self:Swing(self.isHeavySwing)
                -- Terrain interaction raycast
                local char = self.player and self.player.Character
                if char then
                    local hit = raycastTerrain(self.camera, char)
                    if hit then
                        processTerrain(self, hit, self.isHeavySwing)
                    end
                end
            end
        end
    end)

    -- WallMined: server confirmed hit/depletion - play appropriate VFX
    Networking.OnClient(Networking.Events.WallMined, function(pos, oreType, goldEarned, hpLeft, hpMax)
        if goldEarned and goldEarned > 0 then
            -- Ore fully depleted: big burst + gold popup
            spawnOreDepletion(pos, oreType, goldEarned)
        else
            -- Still has HP: crack flash showing damage progress
            spawnOreCrack(pos, hpLeft or 1, hpMax or 2)
        end
    end)

    self.connection = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)
end

function PickaxeModel:Update(dt)
    if not self.root or not self.camera then return end

    local isMoving  = self.isMovingFn()
    local isFalling = self.isFallingFn()

    -- Track charge time
    if self.isCharging then
        self.chargeTime = self.chargeTime + dt
    end

    -- Idle breathing (always running)
    self.breathTime = self.breathTime + dt * IDLE_BREATH_SPEED
    local breathY = math.sin(self.breathTime) * IDLE_BREATH_AMOUNT
    local breathX = math.cos(self.breathTime * 0.5) * IDLE_BREATH_AMOUNT * 0.4

    -- Walk bob (suppressed while falling or swinging)
    if isMoving and not isFalling and not self.isSwinging then
        self.bobTime = self.bobTime + dt * BOB_SPEED
    else
        -- Decay bob smoothly back to zero
        self.bobTime = self.bobTime * 0.88
    end
    local bobX = math.sin(self.bobTime) * BOB_AMOUNT
    local bobY = math.abs(math.cos(self.bobTime)) * BOB_AMOUNT * 0.55
    -- Subtle tilt roll on each step (weapon tilts side-to-side)
    local bobRoll = math.sin(self.bobTime) * math.rad(1.8)

    -- Charge pullback (raise & rotate back as energy builds)
    local chargeOffset = CFrame.new()
    if self.isCharging then
        local chargeT = math.min(self.chargeTime / HEAVY_CHARGE_TIME, 1)
        -- Smooth ease-in: chargeT^2
        local ct2 = chargeT * chargeT
        chargeOffset = CFrame.new(0.04 * ct2, 0.10 * ct2, 0.22 * ct2)
            * CFrame.Angles(math.rad(26 * ct2), math.rad(-8 * ct2), math.rad(-6 * ct2))
    end

    -- Swing animation
    local swingOffset = CFrame.new()
    if self.isSwinging then
        self.swingTime = self.swingTime + dt
        local dur = self.isHeavySwing and HEAVY_SWING_DURATION or SWING_DURATION
        local t   = math.min(self.swingTime / dur, 1)
        if t >= 1 then
            self.isSwinging   = false
            self.isHeavySwing = false
            self.swingTime    = 0
        else
            -- Two-phase arc: forward snap (0->0.5) then recovery (0.5->1)
            local arc
            if t < 0.5 then
                arc = t / 0.5  -- 0->1 during strike
            else
                arc = 1 - (t - 0.5) / 0.5  -- 1->0 during recovery
            end
            -- Ease the arc with a smooth curve
            arc = arc * arc * (3 - 2 * arc)

            if self.isHeavySwing then
                -- Heavy: overhead arc with shoulder rotation, slight leftward lean
                swingOffset = CFrame.Angles(
                        math.rad(-58 * arc),
                        math.rad(-18 * arc),
                        math.rad( 12 * arc))
                    * CFrame.new(0.06 * arc, -0.30 * arc, 0.18 * arc)
            else
                -- Light: crisp downward snap, slight inward
                swingOffset = CFrame.Angles(
                        math.rad(-32 * arc),
                        math.rad(-8  * arc),
                        math.rad( 3  * arc))
                    * CFrame.new(0.02 * arc, -0.16 * arc, 0.12 * arc)
            end
        end
    end

    -- Fall sway: weapon drifts up and slightly forward while airborne
    local fallSway = CFrame.new()
    if isFalling then
        fallSway = CFrame.new(0, -0.10, 0.06)
            * CFrame.Angles(math.rad(18), 0, math.rad(-2))
    end

    local camCF    = self.camera.CFrame
    local targetCF = camCF
        * self.baseOffset
        * CFrame.new(bobX + breathX, -bobY + breathY, 0)
        * CFrame.Angles(0, 0, bobRoll)
        * chargeOffset
        * swingOffset
        * fallSway

    -- Slightly faster lerp during swing for snappiness, slower at rest
    local lerpAlpha = self.isSwinging and 0.38 or 0.22
    self.root.CFrame = self.root.CFrame:Lerp(targetCF, lerpAlpha)
end

-- Trigger swing animation (isHeavy: boolean)
function PickaxeModel:Swing(isHeavy)
    if not self.isSwinging then
        self.isSwinging   = true
        self.isHeavySwing = isHeavy or false
        self.swingTime    = 0
    end
end

return PickaxeModel
