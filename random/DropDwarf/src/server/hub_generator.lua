-- DropDwarf: hub_generator.lua
-- Procedurally builds the hub area entirely from code

local GameData = require(game.ReplicatedStorage.Shared.game_data)

local HubGenerator = {}

local HUB_Y = GameData.HUB_FLOOR_Y
local HUB_R = GameData.HUB_RADIUS

-- Utility: make a cube block
local function makeBlock(parent, name, pos, size, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.Position = pos
    p.BrickColor = BrickColor.new(color)
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Make a block with specific Color3
local function makeBlockColor3(parent, name, pos, size, color3, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.Position = pos
    p.Color = color3
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Add a BillboardGui text label on a part
local function addLabel(part, text, fontSize, yOffset)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset = Vector3.new(0, yOffset or 3, 0)
    bb.AlwaysOnTop = false
    bb.Parent = part
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = text
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Parent = bb
end

-- Add a ClickDetector + labeled sign post for upgrade shops
local function makeShopPost(parent, pos, label, upgradeId)
    local post = makeBlock(parent, "ShopPost_" .. upgradeId, pos + Vector3.new(0, 3, 0),
        Vector3.new(1, 6, 1), "Medium stone grey", Enum.Material.SmoothPlastic)
    local sign = makeBlock(parent, "ShopSign_" .. upgradeId, pos + Vector3.new(0, 7, 0),
        Vector3.new(6, 3, 1), "Bright orange", Enum.Material.SmoothPlastic)
    sign.CFrame = CFrame.new(pos + Vector3.new(0, 7, 0))
    addLabel(sign, label, 18, 0)

    -- Platform for player to stand
    local platform = makeBlock(parent, "ShopPlatform_" .. upgradeId, pos + Vector3.new(0, 0, 0),
        Vector3.new(10, 1, 10), "Smooth Stone", Enum.Material.SmoothPlastic)

    -- Invisible detector part
    local detector = makeBlock(parent, "ShopDetector_" .. upgradeId, pos + Vector3.new(0, 2, 0),
        Vector3.new(10, 4, 10), "Cyan", Enum.Material.SmoothPlastic)
    detector.Transparency = 0.95
    detector.CanCollide = false

    -- Tag with upgradeId
    local tag = Instance.new("StringValue")
    tag.Name = "UpgradeId"
    tag.Value = upgradeId
    tag.Parent = detector

    return { post = post, sign = sign, platform = platform, detector = detector }
end

function HubGenerator.Generate(workspace)
    local hubFolder = Instance.new("Folder")
    hubFolder.Name = "Hub"
    hubFolder.Parent = workspace

    -- Floor - large stone circle approximated with square grid blocks
    local BLOCK = 4 -- block size
    for x = -HUB_R, HUB_R, BLOCK do
        for z = -HUB_R, HUB_R, BLOCK do
            local dist = math.sqrt(x*x + z*z)
            if dist <= HUB_R then
                -- Checkerboard two shades
                local isLight = (math.floor(x/BLOCK) + math.floor(z/BLOCK)) % 2 == 0
                local col = isLight and Color3.fromRGB(90, 85, 80) or Color3.fromRGB(65, 60, 55)
                makeBlockColor3(hubFolder, "Floor", Vector3.new(x, HUB_Y - 0.5, z),
                    Vector3.new(BLOCK, 1, BLOCK), col, Enum.Material.SmoothPlastic)
            end
        end
    end

    -- Outer walls (low ring fence)
    local WALL_H = 6
    local WALL_SEGS = 40
    for i = 1, WALL_SEGS do
        local angle = (i / WALL_SEGS) * math.pi * 2
        local wx = math.cos(angle) * HUB_R
        local wz = math.sin(angle) * HUB_R
        local seg = makeBlock(hubFolder, "Wall", Vector3.new(wx, HUB_Y + WALL_H/2, wz),
            Vector3.new(16, WALL_H, 2), "Dark stone grey", Enum.Material.SmoothPlastic)
        seg.CFrame = CFrame.new(wx, HUB_Y + WALL_H/2, wz) * CFrame.Angles(0, angle + math.pi/2, 0)
    end

    -- Central spawn pad
    local spawn = makeBlock(hubFolder, "SpawnPad", Vector3.new(0, HUB_Y + 0.5, 0),
        Vector3.new(12, 1, 12), "Bright green", Enum.Material.Neon)
    spawn.Transparency = 0.4
    addLabel(spawn, "SPAWN", 24, 3)

    -- SpawnLocation
    local spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Position = Vector3.new(0, HUB_Y + 2, 0)
    spawnLoc.Size = Vector3.new(6, 1, 6)
    spawnLoc.Anchored = true
    spawnLoc.Neutral = true
    spawnLoc.BrickColor = BrickColor.new("Bright green")
    spawnLoc.Transparency = 1
    spawnLoc.Parent = workspace

    -- Hub title sign (large arch)
    local archBase = makeBlock(hubFolder, "ArchBase", Vector3.new(0, HUB_Y + 1, -HUB_R + 10),
        Vector3.new(30, 2, 4), "Medium stone grey", Enum.Material.SmoothPlastic)
    local archLeft = makeBlock(hubFolder, "ArchLeft", Vector3.new(-14, HUB_Y + 10, -HUB_R + 10),
        Vector3.new(2, 18, 4), "Medium stone grey", Enum.Material.SmoothPlastic)
    local archRight = makeBlock(hubFolder, "ArchRight", Vector3.new(14, HUB_Y + 10, -HUB_R + 10),
        Vector3.new(2, 18, 4), "Medium stone grey", Enum.Material.SmoothPlastic)
    local archTop = makeBlock(hubFolder, "ArchTop", Vector3.new(0, HUB_Y + 20, -HUB_R + 10),
        Vector3.new(30, 2, 4), "Bright orange", Enum.Material.Neon)
    archTop.Transparency = 0.3
    addLabel(archTop, "DROP DWARF", 28, 0)

    -- Upgrade shop stations (arranged in arc)
    local upgradeIds = { "max_health", "heal_rate", "move_speed", "fall_resist" }
    local upgradeLabels = { "MAX HEALTH\n[Buy]", "REGEN RATE\n[Buy]", "MOVE SPEED\n[Buy]", "FALL RESIST\n[Buy]" }
    local shopRadius = 45
    for i, id in ipairs(upgradeIds) do
        local angle = math.rad(-60 + (i - 1) * 40)
        local sx = math.cos(angle) * shopRadius
        local sz = math.sin(angle) * shopRadius - 10
        makeShopPost(hubFolder, Vector3.new(sx, HUB_Y + 1, sz), upgradeLabels[i], id)
    end

    -- Leaderboard display wall
    local lbWall = makeBlock(hubFolder, "LeaderboardWall", Vector3.new(50, HUB_Y + 8, 0),
        Vector3.new(2, 16, 30), "Sand", Enum.Material.SmoothPlastic)
    addLabel(lbWall, "LEADERBOARD", 20, 10)
    -- Placeholder entries (real data populated by leaderboard.lua at runtime)
    for i = 1, 5 do
        local entryPart = makeBlock(hubFolder, "LBEntry_" .. i, Vector3.new(51, HUB_Y + 13 - i * 2.5, 0),
            Vector3.new(0.2, 1, 28), "Light grey", Enum.Material.SmoothPlastic)
        entryPart.Name = "LBEntry_" .. i
    end
    -- Tag wall as leaderboard UI anchor
    local lbTag = Instance.new("StringValue")
    lbTag.Name = "IsLeaderboard"
    lbTag.Value = "true"
    lbTag.Parent = lbWall

    -- Seed input kiosk
    local kioskBase = makeBlock(hubFolder, "SeedKiosk", Vector3.new(-50, HUB_Y + 2, 0),
        Vector3.new(10, 4, 6), "Reddish brown", Enum.Material.SmoothPlastic)
    local kioskTop = makeBlock(hubFolder, "SeedKioskScreen", Vector3.new(-50, HUB_Y + 6, 0),
        Vector3.new(8, 4, 0.5), "Cyan", Enum.Material.Neon)
    kioskTop.Transparency = 0.3
    addLabel(kioskTop, "SEED INPUT\n[Press E]", 18, 3)
    local kioskTag = Instance.new("StringValue")
    kioskTag.Name = "IsSeedKiosk"
    kioskTag.Value = "true"
    kioskTag.Parent = kioskBase

    -- Portal to level
    local portalBase = makeBlock(hubFolder, "PortalBase", GameData.PORTAL_POSITION + Vector3.new(0, -2, 0),
        Vector3.new(12, 2, 4), "Really black", Enum.Material.SmoothPlastic)
    local portalFrame = makeBlock(hubFolder, "PortalFrame", GameData.PORTAL_POSITION + Vector3.new(0, 5, 0),
        Vector3.new(12, 14, 1), "Dark stone grey", Enum.Material.SmoothPlastic)
    local portalGlow = makeBlock(hubFolder, "PortalGlow", GameData.PORTAL_POSITION + Vector3.new(0, 5, 0),
        Vector3.new(10, 12, 0.5), "Cyan", Enum.Material.Neon)
    portalGlow.Transparency = 0.4
    addLabel(portalGlow, "ENTER THE DROP\n[Step In]", 22, 8)

    -- Tag portal
    local portalTag = Instance.new("StringValue")
    portalTag.Name = "IsPortal"
    portalTag.Value = "true"
    portalTag.Parent = portalGlow

    -- Floating decorative rocks (dwarf theme)
    local rockPositions = {
        Vector3.new(30, HUB_Y + 10, 30),
        Vector3.new(-30, HUB_Y + 15, 25),
        Vector3.new(20, HUB_Y + 12, -30),
        Vector3.new(-25, HUB_Y + 8, -25),
    }
    local rockColors = {
        Color3.fromRGB(80, 60, 50),
        Color3.fromRGB(100, 80, 60),
        Color3.fromRGB(60, 50, 40),
        Color3.fromRGB(90, 70, 55),
    }
    for i, rpos in ipairs(rockPositions) do
        -- Chunky minecraft-style rock cluster
        for j = 1, 4 do
            local offset = Vector3.new(
                math.random(-4, 4), math.random(-2, 2), math.random(-4, 4)
            )
            local size = Vector3.new(
                math.random(3, 7), math.random(3, 7), math.random(3, 7)
            )
            makeBlockColor3(hubFolder, "FloatRock_" .. i .. "_" .. j,
                rpos + offset, size, rockColors[i], Enum.Material.SmoothPlastic)
        end
    end

    -- Ambient lighting via PointLights on neon blocks
    local torchPositions = {
        Vector3.new(35, HUB_Y + 5, 35),
        Vector3.new(-35, HUB_Y + 5, 35),
        Vector3.new(35, HUB_Y + 5, -35),
        Vector3.new(-35, HUB_Y + 5, -35),
    }
    for i, tpos in ipairs(torchPositions) do
        local torch = makeBlock(hubFolder, "Torch_" .. i, tpos, Vector3.new(2, 2, 2),
            "Neon orange", Enum.Material.Neon)
        torch.Transparency = 0.2
        local light = Instance.new("PointLight")
        light.Brightness = 3
        light.Range = 40
        light.Color = Color3.fromRGB(255, 160, 60)
        light.Parent = torch
    end

    -- Return important tagged parts for server to hook
    return {
        folder = hubFolder,
        portal = portalGlow,
        seedKiosk = kioskBase,
        spawnPad = spawn,
    }
end

return HubGenerator
