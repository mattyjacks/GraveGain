-- DwarfDrop: hub_generator.lua
-- Procedurally builds the hub area from code

local GameData = require(game.ReplicatedStorage.Shared.game_data)

local HubGenerator = {}

local HUB_Y      = GameData.HUB_Y      -- 600
local HUB_RADIUS = GameData.HUB_RADIUS -- 80
local CEIL_Y     = HUB_Y + 32          -- cave ceiling height

-- ==================== HELPERS ====================

local function makePart(parent, name, pos, size, color, anchored)
    local p = Instance.new("Part")
    p.Name           = name
    p.Position       = pos
    p.Size           = size
    p.Color          = color or Color3.fromRGB(80, 75, 90)
    p.Anchored       = anchored ~= false
    p.TopSurface     = Enum.SurfaceType.Smooth
    p.BottomSurface  = Enum.SurfaceType.Smooth
    p.Parent         = parent
    return p
end

local function makeWedge(parent, name, cf, size, color)
    local p = Instance.new("WedgePart")
    p.Name = name; p.Size = size
    p.Color = color or Color3.fromRGB(30, 28, 38)
    p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CFrame = cf; p.Parent = parent
    return p
end

local function addLight(parent, brightness, range, color)
    local l = Instance.new("PointLight")
    l.Brightness = brightness; l.Range = range
    l.Color = color or Color3.fromRGB(255, 180, 80)
    l.Parent = parent; return l
end

local function addBillboard(part, text, yOffset, width)
    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, width or 200, 0, 52)
    bb.StudsOffset = Vector3.new(0, yOffset or 3, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 14
    bb.Parent      = part
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(8,6,14)
    bg.BackgroundTransparency = 0.35; bg.BorderSizePixel = 0; bg.Parent = bb
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,6); corner.Parent = bg
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(120,80,220)
    stroke.Thickness = 2; stroke.Parent = bg
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-8,1,0); lbl.Position = UDim2.new(0,4,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true; lbl.Parent = bg
    return bb
end

-- Spawn a torch: pole + flame + light
local function makeTorch(parent, pos, color)
    color = color or Color3.fromRGB(255, 160, 40)
    -- Pole
    local pole = makePart(parent, "TorchPole", pos, Vector3.new(0.4, 4, 0.4), Color3.fromRGB(80, 55, 30))
    pole.Material = Enum.Material.Wood
    -- Flame cap
    local flame = makePart(parent, "TorchFlame",
        pos + Vector3.new(0, 2.4, 0), Vector3.new(1.0, 1.2, 1.0), color)
    flame.Material = Enum.Material.Neon
    flame.Shape    = Enum.PartType.Ball
    flame.CastShadow = false
    addLight(flame, 3.5, 22, color)
    return pole
end

-- Carved stone column: base slab + shaft + capital
local function makeColumn(parent, pos, height)
    height = height or 20
    local col = Color3.fromRGB(42, 38, 52)
    local basePos = Vector3.new(pos.X, HUB_Y + 1, pos.Z)
    makePart(parent, "ColBase",  basePos,                          Vector3.new(5,2,5), Color3.fromRGB(30,28,40))
    makePart(parent, "ColShaft", basePos + Vector3.new(0,height/2+1,0), Vector3.new(3, height, 3), col)
    makePart(parent, "ColCap",   basePos + Vector3.new(0,height+2,0),   Vector3.new(5,2,5), Color3.fromRGB(30,28,40))
end

-- Crystal cluster: several thin neon wedges grouped at a point
local function makeCrystalCluster(parent, pos, color)
    color = color or Color3.fromRGB(80, 40, 200)
    local heights = { 5, 7, 4, 6, 3 }
    local angles  = { 0, 72, 144, 216, 288 }
    local spreads = { 0, 1.4, 1.1, 1.6, 0.9 }
    for i, h in ipairs(heights) do
        local a  = math.rad(angles[i])
        local sp = spreads[i]
        local cf = CFrame.new(pos + Vector3.new(math.cos(a)*sp, h*0.3, math.sin(a)*sp))
                  * CFrame.Angles(math.cos(a)*0.4, 0, math.sin(a)*0.4)
        local c = makeWedge(parent, "Crystal"..i, cf, Vector3.new(0.8, h, 0.8), color)
        c.Material = Enum.Material.Neon
        c.Transparency = 0.2
    end
    local glow = Instance.new("PointLight")
    glow.Brightness = 1.5; glow.Range = 14; glow.Color = color
    -- attach to a small anchor part
    local anchor = makePart(parent, "CrystalAnchor", pos, Vector3.new(0.1,0.1,0.1), color)
    anchor.Transparency = 1; anchor.CanCollide = false; glow.Parent = anchor
end

-- Stalactite hanging from ceiling
local function makeStalactite(parent, x, z, length)
    local baseY = CEIL_Y - 1
    local cf = CFrame.new(x, baseY - length*0.5, z)
             * CFrame.Angles(math.pi, 0, 0)
    makeWedge(parent, "Stalactite",
        cf, Vector3.new(1.6, length, 1.6),
        Color3.fromRGB(28, 25, 36))
end

-- ==================== BUILD ====================

function HubGenerator.Build()
    local hubFolder = Instance.new("Folder")
    hubFolder.Name   = "HubGeometry"
    hubFolder.Parent = workspace

    -- ===== FLOOR =====
    local floor = makePart(hubFolder, "HubFloor",
        Vector3.new(0, HUB_Y - 2, 0),
        Vector3.new(HUB_RADIUS * 2, 4, HUB_RADIUS * 2),
        Color3.fromRGB(32, 29, 40))
    floor.Material = Enum.Material.SmoothPlastic

    -- Checkerboard tiles
    local tileSize  = 16
    local tileCount = math.floor(HUB_RADIUS / tileSize)
    for tx = -tileCount, tileCount do
        for tz = -tileCount, tileCount do
            local even = (math.abs(tx + tz) % 2 == 0)
            local tile = makePart(hubFolder, "FloorTile",
                Vector3.new(tx * tileSize, HUB_Y + 0.12, tz * tileSize),
                Vector3.new(tileSize - 0.4, 0.22, tileSize - 0.4),
                even and Color3.fromRGB(48, 44, 60)
                      or  Color3.fromRGB(38, 35, 50))
            tile.Material = Enum.Material.SmoothPlastic
        end
    end

    -- Runic circle inlay around spawn
    local runeR = 16
    local runeSegs = 24
    for i = 1, runeSegs do
        local a  = (i / runeSegs) * math.pi * 2
        local rx = math.cos(a) * runeR
        local rz = math.sin(a) * runeR
        local rune = makePart(hubFolder, "RuneInlay",
            Vector3.new(rx, HUB_Y + 0.18, rz),
            Vector3.new(1.8, 0.15, 1.8),
            i % 3 == 0 and Color3.fromRGB(120, 80, 220)
                        or  Color3.fromRGB(80, 50, 160))
        rune.Material = Enum.Material.Neon
        rune.CastShadow = false
    end
    -- Runic center gem
    local centerGem = makePart(hubFolder, "RuneCenter",
        Vector3.new(0, HUB_Y + 0.3, 0),
        Vector3.new(4, 0.3, 4),
        Color3.fromRGB(100, 60, 200))
    centerGem.Material = Enum.Material.Neon
    centerGem.Shape    = Enum.PartType.Cylinder
    centerGem.CastShadow = false
    addLight(centerGem, 2, 30, Color3.fromRGB(120, 80, 220))

    -- ===== CAVE CEILING =====
    local ceiling = makePart(hubFolder, "CaveCeiling",
        Vector3.new(0, CEIL_Y + 2, 0),
        Vector3.new(HUB_RADIUS * 2 + 20, 4, HUB_RADIUS * 2 + 20),
        Color3.fromRGB(22, 20, 28))
    ceiling.Material = Enum.Material.SmoothPlastic

    -- Stalactites scattered across ceiling
    math.randomseed(42)
    local stalaPositions = {
        {-55, -55}, {-30, -60}, {10, -58}, {40, -52}, {60, -35},
        {65, 0},    {55, 30},   {30, 60},  {-10, 65}, {-45, 55},
        {-65, 20},  {-60, -20}, {-20, -30},{20, -20}, {-40, 20},
        {40, 20},   {0, 40},    {0, -40},  {-25, 10}, {25, 10},
    }
    for _, sp in ipairs(stalaPositions) do
        local length = math.random(4, 14)
        makeStalactite(hubFolder, sp[1], sp[2], length)
    end

    -- ===== OUTER WALLS =====
    local wallH    = CEIL_Y - HUB_Y
    local wallThick = 5
    local wallColor = Color3.fromRGB(28, 25, 36)
    local wallDefs = {
        { Vector3.new(0,  HUB_Y + wallH/2, -HUB_RADIUS), Vector3.new(HUB_RADIUS*2+10, wallH, wallThick) },
        { Vector3.new(0,  HUB_Y + wallH/2,  HUB_RADIUS), Vector3.new(HUB_RADIUS*2+10, wallH, wallThick) },
        { Vector3.new(-HUB_RADIUS, HUB_Y + wallH/2, 0),  Vector3.new(wallThick, wallH, HUB_RADIUS*2+10) },
        { Vector3.new( HUB_RADIUS, HUB_Y + wallH/2, 0),  Vector3.new(wallThick, wallH, HUB_RADIUS*2+10) },
    }
    for i, w in ipairs(wallDefs) do
        local wall = makePart(hubFolder, "HubWall"..i, w[1], w[2], wallColor)
        wall.Material = Enum.Material.SmoothPlastic
    end

    -- ===== COLUMNS + TORCHES (ring around room) =====
    local colPositions = {
        {-58,  -45}, { 58, -45},
        {-58,    0}, { 58,   0},
        {-58,   45}, { 58,  45},
        {-30, -72},  { 30, -72},
        {-30,  72},  { 30,  72},
    }
    local torchColors = {
        Color3.fromRGB(255, 140, 30),
        Color3.fromRGB(80, 200, 255),
        Color3.fromRGB(200, 80, 255),
    }
    for i, cp in ipairs(colPositions) do
        local basePos = Vector3.new(cp[1], HUB_Y, cp[2])
        makeColumn(hubFolder, basePos, CEIL_Y - HUB_Y - 4)
        -- Torch on each column at mid-height
        local torchColor = torchColors[((i-1) % #torchColors) + 1]
        local torchY     = HUB_Y + (CEIL_Y - HUB_Y) * 0.45
        makeTorch(hubFolder,
            Vector3.new(cp[1], torchY, cp[2]),
            torchColor)
    end

    -- Wall torches along each wall
    local wallTorchDefs = {
        { x=-72, z=-40, c=torchColors[1] }, { x=-72, z=40,  c=torchColors[2] },
        { x= 72, z=-40, c=torchColors[3] }, { x= 72, z=40,  c=torchColors[1] },
        { x=-40, z=-72, c=torchColors[2] }, { x=40,  z=-72, c=torchColors[3] },
        { x=-40, z= 72, c=torchColors[1] }, { x=40,  z= 72, c=torchColors[2] },
    }
    for _, td in ipairs(wallTorchDefs) do
        makeTorch(hubFolder,
            Vector3.new(td.x, HUB_Y + 10, td.z), td.c)
    end

    -- ===== CRYSTAL CLUSTERS (decorative corners) =====
    local crystalDefs = {
        { pos = Vector3.new(-65, HUB_Y, -65), color = Color3.fromRGB(60, 30, 180) },
        { pos = Vector3.new( 65, HUB_Y, -65), color = Color3.fromRGB(30, 120, 200) },
        { pos = Vector3.new(-65, HUB_Y,  65), color = Color3.fromRGB(180, 40, 200) },
        { pos = Vector3.new( 65, HUB_Y,  65), color = Color3.fromRGB(40, 180, 160) },
        { pos = Vector3.new(  0, HUB_Y, -70), color = Color3.fromRGB(120, 60, 220) },
        { pos = Vector3.new(-70, HUB_Y,   0), color = Color3.fromRGB(60, 160, 255) },
        { pos = Vector3.new( 70, HUB_Y,   0), color = Color3.fromRGB(220, 100, 60) },
    }
    for _, cd in ipairs(crystalDefs) do
        makeCrystalCluster(hubFolder, cd.pos, cd.color)
    end

    -- ===== PORTAL + ARCH =====
    local portalPos = Vector3.new(0, HUB_Y + 8, -68)

    -- Arch pillars
    local archColor = Color3.fromRGB(50, 40, 70)
    local archGlow  = Color3.fromRGB(100, 60, 220)
    local archLeft  = makePart(hubFolder, "ArchLeft",
        portalPos + Vector3.new(-8, 0, 0), Vector3.new(3, 20, 3), archColor)
    archLeft.Material = Enum.Material.SmoothPlastic
    local archRight = makePart(hubFolder, "ArchRight",
        portalPos + Vector3.new( 8, 0, 0), Vector3.new(3, 20, 3), archColor)
    archRight.Material = Enum.Material.SmoothPlastic
    -- Arch lintel
    local archLintel = makePart(hubFolder, "ArchLintel",
        portalPos + Vector3.new(0, 11, 0), Vector3.new(20, 3, 3), archColor)
    archLintel.Material = Enum.Material.SmoothPlastic
    -- Arch glow trim
    local archGlowL = makePart(hubFolder, "ArchGlowL",
        portalPos + Vector3.new(-8, 0, 0), Vector3.new(0.5, 20, 0.5),
        archGlow)
    archGlowL.Material = Enum.Material.Neon; archGlowL.CastShadow = false
    local archGlowR = makePart(hubFolder, "ArchGlowR",
        portalPos + Vector3.new( 8, 0, 0), Vector3.new(0.5, 20, 0.5),
        archGlow)
    archGlowR.Material = Enum.Material.Neon; archGlowR.CastShadow = false
    local archGlowTop = makePart(hubFolder, "ArchGlowTop",
        portalPos + Vector3.new(0, 11, 0), Vector3.new(20, 0.5, 0.5),
        archGlow)
    archGlowTop.Material = Enum.Material.Neon; archGlowTop.CastShadow = false
    addLight(archLintel, 4, 35, archGlow)

    -- Portal fill
    local portal = makePart(hubFolder, "LevelPortal",
        portalPos, Vector3.new(13, 20, 1),
        Color3.fromRGB(70, 30, 180))
    portal.Material     = Enum.Material.Neon
    portal.Transparency = 0.45
    portal.CastShadow   = false
    local portalTag     = Instance.new("BoolValue")
    portalTag.Name  = "IsPortal"; portalTag.Value = true; portalTag.Parent = portal
    addBillboard(portal, "[ E ]  ENTER THE DROP", 13, 240)
    addLight(portal, 5, 40, Color3.fromRGB(80, 40, 200))

    -- Path stones leading to portal
    for i = 0, 6 do
        local pz = -20 - i * 7
        local pathStone = makePart(hubFolder, "PathStone",
            Vector3.new(0, HUB_Y + 0.25, pz),
            Vector3.new(10, 0.45, 5.5),
            i % 2 == 0 and Color3.fromRGB(55, 50, 70)
                        or  Color3.fromRGB(45, 42, 58))
        pathStone.Material = Enum.Material.SmoothPlastic
        -- Glowing edge strips
        local edgeL = makePart(hubFolder, "PathEdge",
            Vector3.new(-5.5, HUB_Y + 0.3, pz),
            Vector3.new(0.4, 0.3, 5.5),
            archGlow)
        edgeL.Material = Enum.Material.Neon; edgeL.CastShadow = false
        local edgeR = makePart(hubFolder, "PathEdge",
            Vector3.new(5.5, HUB_Y + 0.3, pz),
            Vector3.new(0.4, 0.3, 5.5),
            archGlow)
        edgeR.Material = Enum.Material.Neon; edgeR.CastShadow = false
    end

    -- ===== SEED KIOSK =====
    local kioskPos = Vector3.new(28, HUB_Y + 4, -52)
    local kioskBase = makePart(hubFolder, "KioskBase",
        kioskPos + Vector3.new(0, -2.5, 0), Vector3.new(9, 1, 9),
        Color3.fromRGB(30, 28, 42))
    kioskBase.Material = Enum.Material.SmoothPlastic
    local kiosk = makePart(hubFolder, "SeedKiosk",
        kioskPos, Vector3.new(6, 8, 6),
        Color3.fromRGB(40, 70, 100))
    kiosk.Material = Enum.Material.SmoothPlastic
    local kioskGlow = makePart(hubFolder, "KioskGlow",
        kioskPos + Vector3.new(0, 4.3, 0), Vector3.new(6.2, 0.4, 6.2),
        Color3.fromRGB(40, 180, 255))
    kioskGlow.Material = Enum.Material.Neon; kioskGlow.CastShadow = false
    addLight(kiosk, 3, 20, Color3.fromRGB(40, 180, 255))
    local kioskTag = Instance.new("BoolValue")
    kioskTag.Name = "IsSeedKiosk"; kioskTag.Value = true; kioskTag.Parent = kiosk
    addBillboard(kiosk, "[ E ]  SEED KIOSK", 7, 200)

    -- ===== UPGRADE SHOP STATIONS =====
    local shopDefs = {
        { id="max_health",  label="MAX HEALTH",  color=Color3.fromRGB(60,200,80),  pos=Vector3.new(-52,HUB_Y+4, 0)  },
        { id="heal_rate",   label="REGEN RATE",  color=Color3.fromRGB(80,255,120), pos=Vector3.new(-52,HUB_Y+4, 22) },
        { id="move_speed",  label="MOVE SPEED",  color=Color3.fromRGB(80,200,255), pos=Vector3.new(-52,HUB_Y+4, 44) },
        { id="fall_resist", label="FALL RESIST", color=Color3.fromRGB(255,180,40), pos=Vector3.new(-52,HUB_Y+4, 66) },
        { id="coin_magnet", label="COIN MAGNET", color=Color3.fromRGB(255,220,40), pos=Vector3.new(-52,HUB_Y+4,-22) },
        { id="double_jump", label="DOUBLE JUMP", color=Color3.fromRGB(160,80,255), pos=Vector3.new(-52,HUB_Y+4,-44) },
    }
    for _, def in ipairs(shopDefs) do
        -- Pedestal
        local ped = makePart(hubFolder, "ShopPed_"..def.id,
            def.pos + Vector3.new(0,-3,0), Vector3.new(7, 1, 7),
            Color3.fromRGB(28, 26, 38))
        ped.Material = Enum.Material.SmoothPlastic
        -- Main post
        local post = makePart(hubFolder, "ShopPost_"..def.id,
            def.pos, Vector3.new(5, 6, 5), def.color)
        post.Material = Enum.Material.SmoothPlastic
        -- Neon top cap
        local cap = makePart(hubFolder, "ShopCap_"..def.id,
            def.pos + Vector3.new(0, 3.2, 0), Vector3.new(5.2, 0.4, 5.2), def.color)
        cap.Material = Enum.Material.Neon; cap.CastShadow = false
        local idTag   = Instance.new("StringValue")
        idTag.Name    = "UpgradeId"; idTag.Value = def.id; idTag.Parent = post
        local shopTag = Instance.new("BoolValue")
        shopTag.Name  = "IsUpgradeShop"; shopTag.Value = true; shopTag.Parent = post
        addBillboard(post, "[ E ]  "..def.label, 5.5, 210)
        addLight(cap, 3, 20, def.color)
    end

    -- Shop sign overhead
    local shopSign = makePart(hubFolder, "ShopSign",
        Vector3.new(-52, HUB_Y + 20, 22),
        Vector3.new(3, 10, 45),
        Color3.fromRGB(30, 26, 40))
    shopSign.Material = Enum.Material.SmoothPlastic
    local shopSignGlow = makePart(hubFolder, "ShopSignGlow",
        Vector3.new(-52.1, HUB_Y + 20, 22),
        Vector3.new(0.4, 9, 44),
        Color3.fromRGB(80, 255, 120))
    shopSignGlow.Material = Enum.Material.Neon; shopSignGlow.CastShadow = false
    addLight(shopSign, 1.5, 30, Color3.fromRGB(80, 255, 120))

    -- ===== LEADERBOARD WALL =====
    local lbWall = makePart(hubFolder, "LeaderboardWall",
        Vector3.new(62, HUB_Y + 10, 0),
        Vector3.new(3, 24, 50),
        Color3.fromRGB(24, 22, 32))
    lbWall.Material = Enum.Material.SmoothPlastic
    -- Neon border strips
    for _, zOff in ipairs({-25, 25}) do
        local strip = makePart(hubFolder, "LBStrip",
            Vector3.new(62, HUB_Y + 10, zOff),
            Vector3.new(0.5, 24, 0.5),
            Color3.fromRGB(255, 210, 40))
        strip.Material = Enum.Material.Neon; strip.CastShadow = false
    end
    addLight(lbWall, 2, 28, Color3.fromRGB(255, 210, 40))
    local lbTag = Instance.new("BoolValue")
    lbTag.Name = "IsLeaderboardWall"; lbTag.Value = true; lbTag.Parent = lbWall
    addBillboard(lbWall, "[ E ]  LEADERBOARD", 14, 230)

    -- ===== AMBIENT FILL LIGHTS =====
    -- Central soft fill
    local centralFill = makePart(hubFolder, "FillLight1",
        Vector3.new(0, HUB_Y + 14, 0),
        Vector3.new(0.1, 0.1, 0.1), Color3.new(0, 0, 0))
    centralFill.Transparency = 1; centralFill.CanCollide = false; centralFill.CastShadow = false
    addLight(centralFill, 1.2, HUB_RADIUS * 1.8, Color3.fromRGB(140, 110, 200))

    local fillPositions = {
        {-40, HUB_Y+12,  40}, {40, HUB_Y+12, -40},
        {-40, HUB_Y+12, -40}, {40, HUB_Y+12,  40},
        {  0, HUB_Y+12,  60}, { 0, HUB_Y+12, -60},
    }
    local fillColors = {
        Color3.fromRGB(80, 60, 160), Color3.fromRGB(60, 100, 180),
        Color3.fromRGB(100, 60, 140), Color3.fromRGB(60, 80, 160),
        Color3.fromRGB(120, 80, 180), Color3.fromRGB(80, 60, 200),
    }
    for i, fp in ipairs(fillPositions) do
        local anchor = makePart(hubFolder, "FillAnchor"..i,
            Vector3.new(fp[1], fp[2], fp[3]),
            Vector3.new(0.1,0.1,0.1), Color3.new(0,0,0))
        anchor.Transparency = 1; anchor.CanCollide = false; anchor.CastShadow = false
        addLight(anchor, 1.8, 55, fillColors[i])
    end

    -- ===== SPAWN PAD =====
    local spawnLabel = makePart(hubFolder, "HubSpawnPad",
        Vector3.new(0, HUB_Y + 0.3, 30),
        Vector3.new(14, 0.5, 14),
        Color3.fromRGB(80, 60, 140))
    spawnLabel.Material = Enum.Material.Neon
    spawnLabel.Transparency = 0.6
    spawnLabel.CastShadow   = false
    addLight(spawnLabel, 1.5, 20, Color3.fromRGB(120, 90, 200))

    return {
        folder   = hubFolder,
        portal   = portal,
        kiosk    = kiosk,
        spawnPad = spawnLabel,
    }
end

return HubGenerator
