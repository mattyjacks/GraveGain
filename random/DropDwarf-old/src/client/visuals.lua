-- DropDwarf: visuals.lua
-- Advanced graphics, lighting, atmosphere, and post-processing effects.
-- Applies per-biome lighting transitions and hub atmosphere.

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local BiomeData = require(game.ReplicatedStorage.Shared.biome_data)

local Visuals = {}
Visuals.__index = Visuals

-- Tween info for smooth biome transitions
local BIOME_TWEEN = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FAST_TWEEN  = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Per-biome full lighting config
local BiomeLighting = {
    Volcano = {
        -- Lighting service
        Ambient             = Color3.fromRGB(160, 60, 22),   -- raised substantially
        OutdoorAmbient      = Color3.fromRGB(130, 45, 12),
        Brightness          = 2.8,                           -- raised from 1.8
        FogColor            = Color3.fromRGB(55, 20, 8),
        FogEnd              = 600,                           -- doubled fog reach
        FogStart            = 100,
        ColorShift_Bottom   = Color3.fromRGB(80, 10, 0),
        ColorShift_Top      = Color3.fromRGB(220, 90, 20),
        -- Atmosphere
        AtmoDensity         = 0.40,                          -- was 0.7
        AtmoOffset          = 0.20,
        AtmoColor           = Color3.fromRGB(220, 100, 30),
        AtmoDecay           = Color3.fromRGB(100, 30, 5),
        AtmoGlare           = 0.5,
        AtmoHaze            = 1.2,                           -- was 2.2
        -- Bloom
        BloomIntensity      = 1.4,
        BloomSize           = 56,
        BloomThreshold      = 0.85,
        -- SunRays
        SunRaysIntensity    = 0.18,
        SunRaysSpread       = 0.4,
        -- ColorCorrection
        CCBrightness        = 0.04,                          -- slight positive lift
        CCSaturation        = 0.25,
        CCContrast          = 0.12,
        CCTintColor         = Color3.fromRGB(255, 180, 100),
        -- DepthOfField (subtle)
        DOFFarIntensity     = 0.06,
        DOFNearIntensity    = 0.0,
        DOFFocusDistance    = 60,
        DOFInFocusRadius    = 30,
    },
    Fortress = {
        -- Stone dungeon, torch-lit. Substantially brighter for playability.
        Ambient             = Color3.fromRGB(90, 72, 50),   -- raised from (32,26,18)
        OutdoorAmbient      = Color3.fromRGB(72, 58, 38),
        Brightness          = 2.4,                          -- raised from 1.2
        FogColor            = Color3.fromRGB(10, 8, 5),
        FogEnd              = 550,                          -- raised from 350
        FogStart            = 80,
        ColorShift_Bottom   = Color3.fromRGB(20, 14, 6),
        ColorShift_Top      = Color3.fromRGB(130, 98, 50),
        AtmoDensity         = 0.25,                         -- was 0.45
        AtmoOffset          = 0.05,
        AtmoColor           = Color3.fromRGB(120, 90, 48),
        AtmoDecay           = Color3.fromRGB(25, 18, 8),
        AtmoGlare           = 0.0,
        AtmoHaze            = 0.6,                          -- was 1.0
        BloomIntensity      = 2.0,
        BloomSize           = 52,
        BloomThreshold      = 0.72,
        SunRaysIntensity    = 0.0,
        SunRaysSpread       = 0.1,
        CCBrightness        = 0.06,                         -- was -0.05
        CCSaturation        = -0.05,
        CCContrast          = 0.14,
        CCTintColor         = Color3.fromRGB(230, 195, 145),
        DOFFarIntensity     = 0.06,
        DOFNearIntensity    = 0.0,
        DOFFocusDistance    = 50,
        DOFInFocusRadius    = 28,
    },
    Cave = {
        Ambient             = Color3.fromRGB(175, 175, 190), -- boosted for crystal cave visibility
        OutdoorAmbient      = Color3.fromRGB(155, 155, 168),
        Brightness          = 3.2,                           -- raised from 2.2
        FogColor            = Color3.fromRGB(18, 20, 32),
        FogEnd              = 800,                           -- raised from 600
        FogStart            = 160,
        ColorShift_Bottom   = Color3.fromRGB(6, 8, 20),
        ColorShift_Top      = Color3.fromRGB(16, 22, 55),
        AtmoDensity         = 0.02,  -- near-zero atmosphere
        AtmoOffset          = 0.0,
        AtmoColor           = Color3.fromRGB(80, 115, 200),
        AtmoDecay           = Color3.fromRGB(8, 12, 30),
        AtmoGlare           = 0.0,
        AtmoHaze            = 0.05,
        BloomIntensity      = 0.6,
        BloomSize           = 24,
        BloomThreshold      = 0.92,  -- high threshold so only crystals bloom, not whole scene
        SunRaysIntensity    = 0.0,
        SunRaysSpread       = 0.1,
        CCBrightness        = 0.05,
        CCSaturation        = 0.0,
        CCContrast          = 0.05,
        CCTintColor         = Color3.fromRGB(215, 218, 238),
        DOFFarIntensity     = 0.0,
        DOFNearIntensity    = 0.0,
        DOFFocusDistance    = 50,
        DOFInFocusRadius    = 25,
    },
    Mine = {
        Ambient             = Color3.fromRGB(110, 88, 50),  -- raised from (42,32,16)
        OutdoorAmbient      = Color3.fromRGB(90, 70, 38),
        Brightness          = 2.6,                          -- raised from 1.4
        FogColor            = Color3.fromRGB(16, 12, 6),
        FogEnd              = 600,                          -- raised from 380
        FogStart            = 100,
        ColorShift_Bottom   = Color3.fromRGB(28, 18, 5),
        ColorShift_Top      = Color3.fromRGB(210, 165, 55),
        AtmoDensity         = 0.20,                         -- was 0.35
        AtmoOffset          = 0.15,
        AtmoColor           = Color3.fromRGB(200, 160, 65),
        AtmoDecay           = Color3.fromRGB(40, 28, 8),
        AtmoGlare           = 0.08,
        AtmoHaze            = 0.4,                          -- was 0.8
        BloomIntensity      = 1.4,
        BloomSize           = 50,
        BloomThreshold      = 0.80,
        SunRaysIntensity    = 0.0,
        SunRaysSpread       = 0.2,
        CCBrightness        = 0.0,
        CCSaturation        = 0.15,
        CCContrast          = 0.12,
        CCTintColor         = Color3.fromRGB(225, 190, 100),
        DOFFarIntensity     = 0.06,
        DOFNearIntensity    = 0.0,
        DOFFocusDistance    = 45,
        DOFInFocusRadius    = 22,
    },
}

-- Hub lighting (warm stone, heroic)
local HubLighting = {
    Ambient             = Color3.fromRGB(55, 48, 40),
    OutdoorAmbient      = Color3.fromRGB(60, 55, 45),
    Brightness          = 2.0,
    FogColor            = Color3.fromRGB(20, 16, 12),
    FogEnd              = 600,
    FogStart            = 200,
    ColorShift_Bottom   = Color3.fromRGB(25, 18, 10),
    ColorShift_Top      = Color3.fromRGB(200, 160, 80),
    AtmoDensity         = 0.35,
    AtmoOffset          = 0.06,
    AtmoColor           = Color3.fromRGB(200, 160, 100),
    AtmoDecay           = Color3.fromRGB(80, 60, 30),
    AtmoGlare           = 0.3,
    AtmoHaze            = 0.8,
    BloomIntensity      = 0.8,
    BloomSize           = 32,
    BloomThreshold      = 0.95,
    SunRaysIntensity    = 0.12,
    SunRaysSpread       = 0.5,
    CCBrightness        = 0.02,
    CCSaturation        = 0.05,
    CCContrast          = 0.05,
    CCTintColor         = Color3.fromRGB(255, 240, 210),
    DOFFarIntensity     = 0.04,
    DOFNearIntensity    = 0.0,
    DOFFocusDistance    = 80,
    DOFInFocusRadius    = 40,
}

function Visuals.new()
    local self = setmetatable({}, Visuals)
    self.atmosphere = nil
    self.bloom = nil
    self.sunRays = nil
    self.colorCorrection = nil
    self.depthOfField = nil
    self.currentBiome = nil
    self.animatingLights = {}
    return self
end

function Visuals:Setup()
    -- Remove existing post effects to avoid duplicates
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") or child:IsA("Atmosphere") then
            child:Destroy()
        end
    end

    -- Atmosphere (volumetric fog + sky scattering)
    local atmo = Instance.new("Atmosphere")
    atmo.Density    = 0.35
    atmo.Offset     = 0.06
    atmo.Color      = Color3.fromRGB(200, 160, 100)
    atmo.Decay      = Color3.fromRGB(80, 60, 30)
    atmo.Glare      = 0.3
    atmo.Haze       = 0.8
    atmo.Parent     = Lighting
    self.atmosphere = atmo

    -- Bloom effect (neon glow, lava, crystals pop)
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity  = 0.8
    bloom.Size       = 32
    bloom.Threshold  = 0.95
    bloom.Enabled    = true
    bloom.Parent     = Lighting
    self.bloom = bloom

    -- SunRays (god rays through cave openings)
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.12
    sunRays.Spread    = 0.5
    sunRays.Enabled   = true
    sunRays.Parent    = Lighting
    self.sunRays = sunRays

    -- ColorCorrection (cinematic color grading per biome)
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.02
    cc.Saturation = 0.05
    cc.Contrast   = 0.05
    cc.TintColor  = Color3.fromRGB(255, 240, 210)
    cc.Enabled    = true
    cc.Parent     = Lighting
    self.colorCorrection = cc

    -- DepthOfField (subtle background blur)
    local dof = Instance.new("DepthOfFieldEffect")
    dof.FarIntensity    = 0.04
    dof.NearIntensity   = 0.0
    dof.FocusDistance   = 80
    dof.InFocusRadius   = 40
    dof.Enabled         = true
    dof.Parent          = Lighting
    self.depthOfField = dof

    -- Dynamic Light Flicker update connection
    self.lightUpdateConnection = RunService.RenderStepped:Connect(function()
        local t = tick()
        for i = #self.animatingLights, 1, -1 do
            local record = self.animatingLights[i]
            local light = record.light
            if not light or not light.Parent then
                table.remove(self.animatingLights, i)
            else
                if record.type == "pulse" then
                    -- Breathing crystal pulse
                    local sinVal = math.sin(t * 2.2 + record.seed)
                    light.Brightness = record.baseBrightness * (1.0 + sinVal * 0.28)
                    light.Range = record.baseRange * (1.0 + sinVal * 0.15)
                else
                    -- Dynamic torch flicker (Perlin noise)
                    local nVal = math.noise(t * 8.5, record.seed, 0)
                    light.Brightness = record.baseBrightness * (1.0 + nVal * 0.24)
                    light.Range = record.baseRange * (1.0 + nVal * 0.12)
                end
            end
        end
    end)

    -- Apply hub defaults
    self:ApplyHubLighting()
end

function Visuals:ApplyLightingConfig(cfg, tweenInfo)
    tweenInfo = tweenInfo or BIOME_TWEEN

    -- Lighting service properties
    TweenService:Create(Lighting, tweenInfo, {
        Ambient           = cfg.Ambient,
        OutdoorAmbient    = cfg.OutdoorAmbient,
        Brightness        = cfg.Brightness,
        FogColor          = cfg.FogColor,
        FogEnd            = cfg.FogEnd,
        FogStart          = cfg.FogStart,
        ColorShift_Bottom = cfg.ColorShift_Bottom,
        ColorShift_Top    = cfg.ColorShift_Top,
    }):Play()

    -- Atmosphere
    if self.atmosphere then
        TweenService:Create(self.atmosphere, tweenInfo, {
            Density = cfg.AtmoDensity,
            Offset  = cfg.AtmoOffset,
            Color   = cfg.AtmoColor,
            Decay   = cfg.AtmoDecay,
            Glare   = cfg.AtmoGlare,
            Haze    = cfg.AtmoHaze,
        }):Play()
    end

    -- Bloom
    if self.bloom then
        TweenService:Create(self.bloom, tweenInfo, {
            Intensity = cfg.BloomIntensity,
            Size      = cfg.BloomSize,
            Threshold = cfg.BloomThreshold,
        }):Play()
    end

    -- SunRays
    if self.sunRays then
        TweenService:Create(self.sunRays, tweenInfo, {
            Intensity = cfg.SunRaysIntensity,
            Spread    = cfg.SunRaysSpread,
        }):Play()
    end

    -- ColorCorrection
    if self.colorCorrection then
        TweenService:Create(self.colorCorrection, tweenInfo, {
            Brightness = cfg.CCBrightness,
            Saturation = cfg.CCSaturation,
            Contrast   = cfg.CCContrast,
            TintColor  = cfg.CCTintColor,
        }):Play()
    end

    -- DepthOfField
    if self.depthOfField then
        TweenService:Create(self.depthOfField, tweenInfo, {
            FarIntensity  = cfg.DOFFarIntensity,
            NearIntensity = cfg.DOFNearIntensity,
            FocusDistance = cfg.DOFFocusDistance,
            InFocusRadius = cfg.DOFInFocusRadius,
        }):Play()
    end
end

function Visuals:ApplyHubLighting()
    self.currentBiome = "Hub"
    self:ApplyLightingConfig(HubLighting, FAST_TWEEN)
    if self.windSound then self.windSound:Stop() end
end

function Visuals:OnBiomeChanged(biomeName)
    if self.currentBiome == biomeName then return end
    self.currentBiome = biomeName
    local cfg = BiomeLighting[biomeName]
    if cfg then
        self:ApplyLightingConfig(cfg, BIOME_TWEEN)
    end
end

-- Flash effect for fall damage (brief red screen pulse via ColorCorrection)
function Visuals:FlashFallDamage(severity)
    if not self.colorCorrection then return end
    severity = math.clamp(severity, 0, 1)
    local origTint = self.colorCorrection.TintColor
    self.colorCorrection.TintColor = Color3.fromRGB(255, 30, 30)
    self.colorCorrection.Brightness = -0.15 * severity
    TweenService:Create(self.colorCorrection,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TintColor = origTint, Brightness = self.colorCorrection.Brightness }
    ):Play()
end

-- Pulse bloom briefly (when collecting a coin)
function Visuals:PulseCoinCollect()
    if not self.bloom then return end
    local orig = self.bloom.Intensity
    self.bloom.Intensity = orig + 0.8
    TweenService:Create(self.bloom,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Intensity = orig }
    ):Play()
end

-- ==== HIGH-FIDELITY ENVIRONMENTAL AUDIO ====

function Visuals:InitAudio()
    -- Create ambient wind rush sound attached to workspace.CurrentCamera
    local wind = Instance.new("Sound")
    wind.Name = "WindRush"
    wind.SoundId = "rbxassetid://6042539382"  -- wind whoosh ambient loop
    wind.Volume = 0
    wind.Looped = true
    wind.PlayOnRemove = false
    wind.Parent = workspace.CurrentCamera
    self.windSound = wind
end

function Visuals:StartWindSound()
    if not self.windSound then self:InitAudio() end
    self.windSound.Volume = 0
    self.windSound:Play()
end

function Visuals:UpdateWind(velY)
    if not self.windSound then return end
    -- Only rush sound when falling downwards
    if velY >= 0 then
        self.windSound.Volume = math.max(0, self.windSound.Volume - 0.05)
    else
        local fallSpeed = math.abs(velY)
        -- Start scaling volume above speed threshold 30
        local targetVol = math.clamp((fallSpeed - 30) / 100, 0, 0.9)
        self.windSound.Volume = self.windSound.Volume + (targetVol - self.windSound.Volume) * 0.15
        self.windSound.PlaybackSpeed = 0.85 + (fallSpeed / 150) * 0.3
    end
end

-- Premium spatial 3D audio mapper + Dynamic Light setup
function Visuals:AttachSpatialSounds(levelFolder)
    local function setupSound(part)
        local soundId = nil
        local maxDist = 45
        local volume  = 0.5

        if part.Name == "LavaPool" or part.Name == "LavaCascade" then
            soundId = "rbxassetid://6042585137" -- lava/fire ambience loop
            maxDist = 55
            volume  = 0.7
        elseif part.Name == "FlameNode" then
            soundId = "rbxassetid://9083838232" -- crackling fire
            maxDist = 35
            volume  = 0.65
        elseif part.Name == "Crystal" then
            soundId = "rbxassetid://9113837775" -- resonate hum
            maxDist = 30
            volume  = 0.35
        end

        if soundId then
            local sound = Instance.new("Sound")
            sound.Name = "SpatialAmbient"
            sound.SoundId = soundId
            sound.Volume = volume
            sound.Looped = true
            sound.RollOffMode = Enum.RollOffMode.Linear
            sound.MaxDistance = maxDist
            sound.MinDistance = 6
            sound.Parent = part
            sound:Play()
        end
    end

    local function setupPartLights(part)
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("PointLight") then
                local alreadyRegistered = false
                for _, rec in ipairs(self.animatingLights) do
                    if rec.light == child then
                        alreadyRegistered = true
                        break
                    end
                end
                if not alreadyRegistered then
                    table.insert(self.animatingLights, {
                        light = child,
                        baseBrightness = child.Brightness,
                        baseRange = child.Range,
                        type = (part.Name:find("Crystal") or part.Name:find("Vein") or part.Name:find("Crate")) and "pulse" or "flicker",
                        seed = math.random() * 100
                    })
                end
            end
        end
    end

    -- Process existing parts
    for _, descendant in ipairs(levelFolder:GetDescendants()) do
        if descendant:IsA("BasePart") then
            setupSound(descendant)
            setupPartLights(descendant)
        end
    end

    -- Process dynamic future chunk parts
    self.spatialListener = levelFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            task.wait(0.05) -- allow properties replication
            if descendant.Parent then
                setupSound(descendant)
                setupPartLights(descendant)
            end
        end
    end)
end

function Visuals:CleanupAudio()
    if self.windSound then
        self.windSound:Stop()
    end
    if self.spatialListener then
        self.spatialListener:Disconnect()
        self.spatialListener = nil
    end
    self.animatingLights = {}
end

-- Premium Double-Jump steam cloud particle puff
function Visuals:SpawnAirJumpPuff(pos)
    local p = Instance.new("Part")
    p.Name = "AirJumpPuff"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(3, 1, 3)
    p.Position = pos - Vector3.new(0, 2.5, 0)
    p.Color = Color3.fromRGB(240, 245, 255)
    p.Material = Enum.Material.Neon
    p.Transparency = 0.4
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.Parent = workspace

    local pe = Instance.new("ParticleEmitter")
    pe.Texture = "rbxassetid://252125026"
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),
        NumberSequenceKeypoint.new(1, 4.0)
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1.0)
    })
    pe.Lifetime = NumberRange.new(0.4, 0.6)
    pe.Speed = NumberRange.new(12, 18)
    pe.SpreadAngle = Vector2.new(0, 360)
    pe.Rate = 150
    pe.Parent = p
    pe:Emit(35)

    TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(7, 0.2, 7),
        Transparency = 1
    }):Play()

    task.delay(0.6, function()
        p:Destroy()
    end)
end

-- Premium landing impact dust particle cloud
function Visuals:SpawnDustPuff(pos)
    local p = Instance.new("Part")
    p.Name = "DustPuff"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(2, 0.5, 2)
    p.Position = pos - Vector3.new(0, 2.5, 0)
    p.Color = Color3.fromRGB(150, 140, 130)
    p.Material = Enum.Material.SmoothPlastic
    p.Transparency = 0.5
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.Parent = workspace

    local pe = Instance.new("ParticleEmitter")
    pe.Texture = "rbxassetid://252125026"
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 2.5)
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1.0)
    })
    pe.Lifetime = NumberRange.new(0.3, 0.5)
    pe.Speed = NumberRange.new(6, 12)
    pe.SpreadAngle = Vector2.new(0, 360)
    pe.Rate = 120
    pe.Parent = p
    pe:Emit(20)

    TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(5, 0.1, 5),
        Transparency = 1
    }):Play()

    task.delay(0.5, function()
        p:Destroy()
    end)
end

return Visuals

