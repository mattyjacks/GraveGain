-- DropDwarf: level_generator/part_builders.lua
-- Core platform, coin, hazard, wall, and material helper parts builders.

local GameData = require(game.ReplicatedStorage.Shared.game_data)

local PartBuilders = {}

-- Terrain type constants
PartBuilders.TERRAIN_SOFT = "Soft"
PartBuilders.TERRAIN_FIRM = "Firm"
PartBuilders.TERRAIN_HARD = "Hard"

local BIOME_TERRAIN = {
    Volcano  = { soft = 0.15, firm = 0.55 },
    Fortress = { soft = 0.25, firm = 0.65 },
    Cave     = { soft = 0.40, firm = 0.75 },
    Mine     = { soft = 0.50, firm = 0.80 },
}

local BIOME_MATERIAL = {
    Volcano  = Enum.Material.Slate,
    Fortress = Enum.Material.SmoothPlastic,
    Cave     = Enum.Material.Granite,
    Mine     = Enum.Material.Sandstone,
}

function PartBuilders.GetTerrainType(biome, rng)
    local t = BIOME_TERRAIN[biome.name] or { soft = 0.33, firm = 0.66 }
    local r = rng:NextNumber()
    if r < t.soft then return PartBuilders.TERRAIN_SOFT
    elseif r < t.firm then return PartBuilders.TERRAIN_FIRM
    else return PartBuilders.TERRAIN_HARD end
end

function PartBuilders.GetBiomeMat(biome, override)
    return override or BIOME_MATERIAL[biome.name] or Enum.Material.SmoothPlastic
end

function PartBuilders.MakePart(parent, name, pos, size, color, material, transparency)
    local p = Instance.new("Part")
    p.Name          = name
    p.Size          = size
    p.Position      = pos
    p.Anchored      = true
    p.Color         = color
    p.Material      = material or Enum.Material.SmoothPlastic
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Transparency  = transparency or 0
    p.CastShadow    = true
    p.Parent        = parent
    return p
end

function PartBuilders.SpawnCoin(parent, pos)
    local coin = Instance.new("Part")
    coin.Name = "GoldCoin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Size = Vector3.new(0.5, GameData.COIN_SIZE, GameData.COIN_SIZE)
    coin.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi/2)
    coin.Anchored = true
    coin.CanCollide = false
    coin.Color = Color3.fromRGB(255, 200, 0)
    coin.Material = Enum.Material.Neon
    coin.Transparency = 0.1
    
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 8
    light.Color = Color3.fromRGB(255, 220, 80)
    light.Parent = coin

    local tag = Instance.new("StringValue")
    tag.Name = "IsCoin"
    tag.Value = "true"
    tag.Parent = coin
    coin.Parent = parent
    return coin
end

function PartBuilders.SpawnHazard(parent, pos, size, biome)
    local h = Instance.new("Part")
    h.Name = "Hazard"
    h.Size = size
    h.Position = pos
    h.Anchored = true
    h.CanCollide = true
    h.Color = biome.accentColor
    h.Material = Enum.Material.Neon
    h.Transparency = 0.3
    h.TopSurface = Enum.SurfaceType.Smooth
    h.BottomSurface = Enum.SurfaceType.Smooth
    
    local tag = Instance.new("StringValue")
    tag.Name = "IsHazard"
    tag.Value = tostring(biome.hazardDamage)
    tag.Parent = h

    local light = Instance.new("PointLight")
    light.Brightness = 1.5
    light.Range = 6
    light.Color = biome.accentColor
    light.Parent = h
    h.Parent = parent
    return h
end

-- Generates beveled/layered platform designs with love
function PartBuilders.SpawnPlatform(parent, pos, size, color, material, terrainType, biome)
    local mat = material
    if not mat and biome then
        mat = PartBuilders.GetBiomeMat(biome)
        if terrainType == PartBuilders.TERRAIN_SOFT then mat = Enum.Material.Mud
        elseif terrainType == PartBuilders.TERRAIN_HARD then mat = Enum.Material.Granite end
    end
    
    -- Organic Layered Platform construction
    local platGroup = Instance.new("Model")
    platGroup.Name = "BeveledPlatform"
    platGroup.Parent = parent

    -- Top structural surface plate (material specific)
    local main = PartBuilders.MakePart(platGroup, "Platform", pos, size, color, mat or Enum.Material.SmoothPlastic)
    
    local tt = Instance.new("StringValue")
    tt.Name = "TerrainType"
    tt.Value = terrainType or PartBuilders.TERRAIN_FIRM
    tt.Parent = main

    -- Round bevel columns at corners to avoid harsh geometric profiles
    local ext = size * 0.5
    local bevelCol = Color3.fromRGB(
        math.clamp(color.R * 255 - 20, 0, 255),
        math.clamp(color.G * 255 - 20, 0, 255),
        math.clamp(color.B * 255 - 20, 0, 255)
    )
    
    local offsets = {
        Vector3.new(-ext.X, 0, -ext.Z),
        Vector3.new(ext.X, 0, -ext.Z),
        Vector3.new(-ext.X, 0, ext.Z),
        Vector3.new(ext.X, 0, ext.Z),
    }
    
    for _, offset in ipairs(offsets) do
        local cyl = Instance.new("Part")
        cyl.Name = "BevelCorner"
        cyl.Shape = Enum.PartType.Cylinder
        cyl.Size = Vector3.new(size.Y * 0.95, 0.45, 0.45)
        cyl.CFrame = CFrame.new(pos + offset) * CFrame.Angles(math.pi/2, 0, 0)
        cyl.Color = bevelCol
        cyl.Material = Enum.Material.Slate
        cyl.Anchored = true
        cyl.CanCollide = true
        cyl.Parent = platGroup
    end

    return main
end

function PartBuilders.SpawnWall(parent, pos, size, color, material, biome)
    local mat = material or (biome and PartBuilders.GetBiomeMat(biome)) or Enum.Material.SmoothPlastic
    return PartBuilders.MakePart(parent, "Wall", pos, size, color, mat)
end

function PartBuilders.SpawnCeiling(parent, pos, size, color, material, biome)
    local mat = material or (biome and PartBuilders.GetBiomeMat(biome)) or Enum.Material.SmoothPlastic
    return PartBuilders.MakePart(parent, "Ceiling", pos, size, color, mat)
end

function PartBuilders.SpawnGlowBlock(parent, pos, size, color, brightness, range)
    local g = PartBuilders.MakePart(parent, "GlowBlock", pos, size, color, Enum.Material.Neon, 0.25)
    g.CanCollide = false
    g.CastShadow = false
    
    local pl = Instance.new("PointLight")
    pl.Brightness = brightness or 1.5
    pl.Range      = range or 12
    pl.Color      = color
    pl.Parent     = g
    return g
end

function PartBuilders.SpawnFinish(parent, worldY)
    local p = Instance.new("Part")
    p.Name = "FinishPlatform"
    p.Size = Vector3.new(GameData.LEVEL_WIDTH, 2, GameData.LEVEL_WIDTH)
    p.Position = Vector3.new(0, worldY - 1, 0)
    p.Anchored = true
    p.Color = Color3.fromRGB(255, 220, 60)
    p.Material = Enum.Material.Neon
    p.Transparency = 0.2
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent

    local light = Instance.new("PointLight")
    light.Brightness = 5
    light.Range = 60
    light.Color = Color3.fromRGB(255, 240, 100)
    light.Parent = p

    local tag = Instance.new("StringValue")
    tag.Name = "IsFinish"
    tag.Value = "true"
    tag.Parent = p

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 400, 0, 100)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.Parent = p
    
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "BOTTOM - 1000m"
    tl.TextColor3 = Color3.new(1, 1, 0.5)
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Parent = bb

    return p
end

function PartBuilders.SpawnBiomeMarker(parent, worldY, biomeName, color)
    local marker = Instance.new("Part")
    marker.Name = "BiomeMarker_" .. biomeName
    marker.Size = Vector3.new(GameData.LEVEL_WIDTH + 20, 0.5, GameData.LEVEL_WIDTH + 20)
    marker.Position = Vector3.new(0, worldY, 0)
    marker.Anchored = true
    marker.CanCollide = false
    marker.Color = color
    marker.Material = Enum.Material.Neon
    marker.Transparency = 1.0 -- Remove glowing transition visual blockage
    marker.Parent = parent

    local tag = Instance.new("StringValue")
    tag.Name = "BiomeName"
    tag.Value = biomeName
    tag.Parent = marker
    return marker
end

local ItemData = require(game.ReplicatedStorage.Shared.item_data)

function PartBuilders.SpawnItemCrate(parent, pos, itemId, rng)
    local item = ItemData.Items[itemId]
    if not item then return end

    local themeColor = item.color or Color3.fromRGB(255, 255, 255)
    local displayName = item.displayName or itemId

    -- Beautiful metallic crate group
    local crateGroup = Instance.new("Model")
    crateGroup.Name = "ItemCrate_" .. itemId
    crateGroup.Parent = parent

    -- Outer dark metal casing
    local size = Vector3.new(3, 3, 3)
    local base = PartBuilders.MakePart(crateGroup, "BaseCrate", pos, size, Color3.fromRGB(30, 30, 32), Enum.Material.Metal)
    base.CanCollide = true
    base.Parent = crateGroup

    -- Neon highlight band around the crate
    local band = PartBuilders.MakePart(crateGroup, "NeonBand", pos + Vector3.new(0, 0, 0), Vector3.new(3.05, 0.4, 3.05), themeColor, Enum.Material.Neon)
    band.CanCollide = false
    band.Parent = crateGroup

    -- Glowing PointLight to illuminate the cave floor
    local light = Instance.new("PointLight")
    light.Brightness = 2.5
    light.Range = 15
    light.Color = themeColor
    light.Parent = base

    -- Billboard prompt for stepped interaction
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 350, 0, 100)
    bb.StudsOffset = Vector3.new(0, 4.5, 0)
    bb.Parent = base

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = string.format("%s\n[Step to Collect]", displayName:upper())
    tl.TextColor3 = themeColor
    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Parent = bb

    -- Server tags for authoritative collection
    local crateTag = Instance.new("BoolValue")
    crateTag.Name = "IsItemCrate"
    crateTag.Value = true
    crateTag.Parent = base

    local idTag = Instance.new("StringValue")
    idTag.Name = "CrateId"
    idTag.Value = string.format("crate_%d_%d", math.floor(pos.Y), rng and rng:NextInteger(1, 100000) or math.random(1, 100000))
    idTag.Parent = base

    local itemTag = Instance.new("StringValue")
    itemTag.Name = "ItemId"
    itemTag.Value = itemId
    itemTag.Parent = base

    return base
end

return PartBuilders
