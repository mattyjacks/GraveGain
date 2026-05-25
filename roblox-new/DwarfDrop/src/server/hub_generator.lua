-- DwarfDrop: hub_generator.lua
-- Procedurally builds the hub area from code

local GameData = require(game.ReplicatedStorage.Shared.game_data)

local HubGenerator = {}

local HUB_Y      = GameData.HUB_Y      -- 600
local HUB_RADIUS = GameData.HUB_RADIUS -- 80

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

local function addBillboard(part, text, yOffset)
    local bb = Instance.new("BillboardGui")
    bb.Size          = UDim2.new(0, 180, 0, 50)
    bb.StudsOffset   = Vector3.new(0, yOffset or 3, 0)
    bb.AlwaysOnTop   = false
    bb.Parent        = part
    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = text
    lbl.TextColor3          = Color3.new(1, 1, 1)
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextScaled          = true
    lbl.Parent              = bb
end

function HubGenerator.Build()
    local hubFolder = Instance.new("Folder")
    hubFolder.Name   = "HubGeometry"
    hubFolder.Parent = workspace

    -- ===== FLOOR =====
    local floor = makePart(hubFolder, "HubFloor",
        Vector3.new(0, HUB_Y - 2, 0),
        Vector3.new(HUB_RADIUS * 2, 4, HUB_RADIUS * 2),
        Color3.fromRGB(40, 36, 48))

    -- Floor tiles (decorative)
    local tileSize = 20
    local tileCount = math.floor(HUB_RADIUS / tileSize)
    for tx = -tileCount, tileCount do
        for tz = -tileCount, tileCount do
            local tile = makePart(hubFolder, "FloorTile",
                Vector3.new(tx * tileSize, HUB_Y + 0.1, tz * tileSize),
                Vector3.new(tileSize - 0.5, 0.2, tileSize - 0.5),
                (math.abs(tx + tz) % 2 == 0)
                    and Color3.fromRGB(50, 46, 60)
                    or  Color3.fromRGB(44, 40, 54))
        end
    end

    -- ===== OUTER WALLS =====
    local wallH = 30
    local wallThick = 4
    local walls = {
        { Vector3.new(0, HUB_Y + wallH / 2, -HUB_RADIUS), Vector3.new(HUB_RADIUS * 2, wallH, wallThick) },
        { Vector3.new(0, HUB_Y + wallH / 2,  HUB_RADIUS), Vector3.new(HUB_RADIUS * 2, wallH, wallThick) },
        { Vector3.new(-HUB_RADIUS, HUB_Y + wallH / 2, 0), Vector3.new(wallThick, wallH, HUB_RADIUS * 2) },
        { Vector3.new( HUB_RADIUS, HUB_Y + wallH / 2, 0), Vector3.new(wallThick, wallH, HUB_RADIUS * 2) },
    }
    for i, w in ipairs(walls) do
        makePart(hubFolder, "HubWall" .. i, w[1], w[2], Color3.fromRGB(35, 32, 44))
    end

    -- ===== PORTAL =====
    local portalPos = Vector3.new(0, HUB_Y + 5, -58)
    local portal = makePart(hubFolder, "LevelPortal",
        portalPos, Vector3.new(10, 14, 2),
        Color3.fromRGB(80, 40, 180))
    portal.Material = Enum.Material.Neon
    portal.Transparency = 0.3
    -- Tag for client proximity detection
    local tag = Instance.new("BoolValue")
    tag.Name   = "IsPortal"
    tag.Value  = true
    tag.Parent = portal
    addBillboard(portal, "[ E ] ENTER THE DROP", 9)

    -- Portal frame
    local portalFrame = makePart(hubFolder, "PortalFrame",
        portalPos, Vector3.new(12, 16, 1),
        Color3.fromRGB(60, 30, 140))
    portalFrame.ZIndex = 0

    -- ===== SEED KIOSK =====
    local kioskPos = Vector3.new(24, HUB_Y + 4, -50)
    local kiosk = makePart(hubFolder, "SeedKiosk",
        kioskPos, Vector3.new(6, 8, 6),
        Color3.fromRGB(50, 80, 100))
    local kioskTag = Instance.new("BoolValue")
    kioskTag.Name   = "IsSeedKiosk"
    kioskTag.Value  = true
    kioskTag.Parent = kiosk
    addBillboard(kiosk, "[ E ] SEED KIOSK", 6)

    -- ===== UPGRADE SHOP STATIONS =====
    local shopDefs = {
        { id = "max_health",  label = "MAX HEALTH",  color = Color3.fromRGB(60, 200, 80),  pos = Vector3.new(-50, HUB_Y + 4, 0) },
        { id = "heal_rate",   label = "REGEN RATE",  color = Color3.fromRGB(80, 255, 120), pos = Vector3.new(-50, HUB_Y + 4, 20) },
        { id = "move_speed",  label = "MOVE SPEED",  color = Color3.fromRGB(80, 200, 255), pos = Vector3.new(-50, HUB_Y + 4, 40) },
        { id = "fall_resist", label = "FALL RESIST", color = Color3.fromRGB(255, 180, 40), pos = Vector3.new(-50, HUB_Y + 4, 60) },
        { id = "coin_magnet", label = "COIN MAGNET", color = Color3.fromRGB(255, 220, 40), pos = Vector3.new(-50, HUB_Y + 4, -20) },
        { id = "double_jump", label = "DOUBLE JUMP", color = Color3.fromRGB(160, 80, 255), pos = Vector3.new(-50, HUB_Y + 4, -40) },
    }

    for _, def in ipairs(shopDefs) do
        local post = makePart(hubFolder, "ShopPost_" .. def.id,
            def.pos, Vector3.new(5, 8, 5), def.color)
        post.Material = Enum.Material.SmoothPlastic
        local idTag = Instance.new("StringValue")
        idTag.Name   = "UpgradeId"
        idTag.Value  = def.id
        idTag.Parent = post
        local shopTag = Instance.new("BoolValue")
        shopTag.Name   = "IsUpgradeShop"
        shopTag.Value  = true
        shopTag.Parent = post
        addBillboard(post, "[ E ] " .. def.label, 6)

        -- Glow light
        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Range = 18
        light.Color = def.color
        light.Parent = post
    end

    -- ===== LEADERBOARD DISPLAY WALL =====
    local lbWall = makePart(hubFolder, "LeaderboardWall",
        Vector3.new(50, HUB_Y + 10, 0),
        Vector3.new(2, 24, 40),
        Color3.fromRGB(30, 28, 40))
    local lbTag = Instance.new("BoolValue")
    lbTag.Name   = "IsLeaderboardWall"
    lbTag.Value  = true
    lbTag.Parent = lbWall
    addBillboard(lbWall, "[ E ] LEADERBOARD", 14)

    -- ===== AMBIENT LIGHTING ==

    local hubLight = Instance.new("PointLight")
    hubLight.Brightness = 1.5
    hubLight.Range      = HUB_RADIUS * 1.5
    hubLight.Color      = Color3.fromRGB(180, 160, 220)
    hubLight.Parent     = floor

    -- FIX Bug#4: use local variable 'spawnLabel', do not return global
    local spawnLabel = makePart(hubFolder, "HubSpawnPad",
        Vector3.new(0, HUB_Y + 1, 30),
        Vector3.new(12, 1, 12),
        Color3.fromRGB(60, 55, 80))
    spawnLabel.Transparency = 0.5

    return {
        folder     = hubFolder,
        portal     = portal,
        kiosk      = kiosk,
        spawnPad   = spawnLabel,  -- FIX Bug#4: named 'spawnLabel' locally, returned as 'spawnPad'
    }
end

return HubGenerator
