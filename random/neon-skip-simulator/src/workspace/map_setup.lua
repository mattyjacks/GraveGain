--[[
    Neon Skip Simulator - Map Setup
    Creates the synthwave/retro aesthetic environment
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.game_config)

-- Baseplate
local function createBaseplate()
    local baseplate = Instance.new("Part")
    baseplate.Name = "Baseplate"
    baseplate.Size = Vector3.new(512, 1, 512)
    baseplate.Position = Vector3.new(0, 0, 0)
    baseplate.Anchored = true
    baseplate.BrickColor = BrickColor.new("Really black")
    baseplate.Material = Enum.Material.SmoothPlastic
    baseplate.TopSurface = Enum.SurfaceType.Smooth
    baseplate.BottomSurface = Enum.SurfaceType.Smooth
    baseplate.Parent = workspace
    
    -- Grid pattern
    for x = -250, 250, 50 do
        local line = Instance.new("Part")
        line.Size = Vector3.new(1, 0.2, 512)
        line.Position = Vector3.new(x, 0.6, 0)
        line.Anchored = true
        line.BrickColor = BrickColor.new("Bright blue")
        line.Material = Enum.Material.Neon
        line.Transparency = 0.7
        line.Parent = workspace
    end
    
    for z = -250, 250, 50 do
        local line = Instance.new("Part")
        line.Size = Vector3.new(512, 0.2, 1)
        line.Position = Vector3.new(0, 0.6, z)
        line.Anchored = true
        line.BrickColor = BrickColor.new("Bright blue")
        line.Material = Enum.Material.Neon
        line.Transparency = 0.7
        line.Parent = workspace
    end
end

-- Spawn area
local function createSpawnArea()
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Position = Vector3.new(0, 2, 0)
    spawnLocation.Anchored = true
    spawnLocation.BrickColor = BrickColor.new("Bright green")
    spawnLocation.Material = Enum.Material.Neon
    spawnLocation.Transparency = 0.5
    spawnLocation.Parent = workspace
    
    -- Spawn platform
    local platform = Instance.new("Part")
    platform.Name = "SpawnPlatform"
    platform.Size = Vector3.new(30, 1, 30)
    platform.Position = Vector3.new(0, 0.5, 0)
    platform.Anchored = true
    platform.BrickColor = BrickColor.new("Really black")
    platform.Material = Enum.Material.SmoothPlastic
    platform.Parent = workspace
    
    -- Neon ring around spawn
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local radius = 15
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        
        local pillar = Instance.new("Part")
        pillar.Size = Vector3.new(2, 8, 2)
        pillar.Position = Vector3.new(x, 4, z)
        pillar.Anchored = true
        pillar.BrickColor = BrickColor.new("Cyan")
        pillar.Material = Enum.Material.Neon
        pillar.Parent = workspace
    end
end

-- Create zones
local function createZones()
    local zonesFolder = Instance.new("Folder")
    zonesFolder.Name = "Zones"
    zonesFolder.Parent = workspace
    
    for i, zone in ipairs(GameConfig.ZONES) do
        if i == 1 then continue end -- Skip first zone (spawn)
        
        -- Calculate position - zones radiate outward
        local angle = ((i - 2) / (#GameConfig.ZONES - 2)) * math.pi
        local distance = 80 + (i * 20)
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance
        
        -- Zone platform
        local platform = Instance.new("Part")
        platform.Name = "Zone_" .. zone.id
        platform.Size = Vector3.new(40, 1, 40)
        platform.Position = Vector3.new(x, 0.5, z)
        platform.Anchored = true
        platform.BrickColor = BrickColor.new(zone.color)
        platform.Material = Enum.Material.SmoothPlastic
        platform.Parent = zonesFolder
        
        -- Zone glow border
        for j = 1, 4 do
            local edgeAngle = ((j - 1) / 4) * math.pi * 2
            local edgeRadius = 20
            local ex = x + math.cos(edgeAngle) * edgeRadius
            local ez = z + math.sin(edgeAngle) * edgeRadius
            
            local pillar = Instance.new("Part")
            pillar.Size = Vector3.new(2, 10, 2)
            pillar.Position = Vector3.new(ex, 5, ez)
            pillar.Anchored = true
            pillar.BrickColor = BrickColor.new(zone.color)
            pillar.Material = Enum.Material.Neon
            pillar.Parent = zonesFolder
        end
        
        -- Gate (invisible wall until unlocked)
        local gate = Instance.new("Part")
        gate.Name = "Gate_" .. zone.id
        gate.Size = Vector3.new(2, 15, 40)
        
        -- Position gate between spawn and zone
        gate.Position = Vector3.new(x * 0.5, 7.5, z * 0.5)
        gate.Anchored = true
        gate.BrickColor = BrickColor.new("Really red")
        gate.Material = Enum.Material.ForceField
        gate.Transparency = 0.3
        gate.CanCollide = true
        gate.Parent = zonesFolder
        
        -- Billboard for gate
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 150, 0, 100)
        billboard.StudsOffset = Vector3.new(0, 8, 0)
        billboard.Adornee = gate
        billboard.Parent = gate
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = zone.name .. "\n" .. tostring(zone.requiredMomentum) .. " Momentum"
        label.TextColor3 = zone.color
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
    end
end

-- Decorative neon elements
local function createDecorations()
    -- Random neon pillars
    for i = 1, 20 do
        local x = math.random(-200, 200)
        local z = math.random(-200, 200)
        local height = math.random(10, 30)
        
        local pillar = Instance.new("Part")
        pillar.Size = Vector3.new(3, height, 3)
        pillar.Position = Vector3.new(x, height / 2, z)
        pillar.Anchored = true
        
        local colors = {
            Color3.fromRGB(255, 0, 128),
            Color3.fromRGB(0, 200, 255),
            Color3.fromRGB(0, 255, 100),
            Color3.fromRGB(255, 0, 255)
        }
        pillar.BrickColor = BrickColor.new(colors[math.random(1, #colors)])
        pillar.Material = Enum.Material.Neon
        pillar.Parent = workspace
    end
    
    -- Floating neon rings
    for i = 1, 10 do
        local x = math.random(-150, 150)
        local z = math.random(-150, 150)
        local y = math.random(15, 40)
        
        local ring = Instance.new("Part")
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(1, 10, 10)
        ring.Orientation = Vector3.new(0, 0, 90)
        ring.Position = Vector3.new(x, y, z)
        ring.Anchored = true
        ring.BrickColor = BrickColor.new("Cyan")
        ring.Material = Enum.Material.Neon
        ring.Transparency = 0.3
        ring.Parent = workspace
    end
end

-- Lighting setup
local function setupLighting()
    Lighting.Brightness = 0.5
    Lighting.Ambient = Color3.fromRGB(50, 50, 80)
    Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
    Lighting.ClockTime = 0
    
    -- Sky (using Roblox default - safe)
    -- To use custom skybox, upload your own sky textures through Creator Dashboard
    -- Do NOT use random asset IDs - they may be copyrighted or inappropriate
    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
    sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
    sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
    sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
    sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
    sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
    sky.StarCount = 3000
    sky.Parent = Lighting
    
    -- Bloom effect
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.5
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting
    
    -- Color correction for synthwave feel
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.TintColor = Color3.fromRGB(255, 200, 255)
    colorCorrection.Saturation = 0.2
    colorCorrection.Contrast = 0.1
    colorCorrection.Parent = Lighting
end

-- Build the map
local function buildMap()
    createBaseplate()
    createSpawnArea()
    createZones()
    createDecorations()
    setupLighting()
    
    print("🌆 Neon Skip Simulator map created!")
end

buildMap()
