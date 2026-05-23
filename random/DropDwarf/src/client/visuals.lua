-- DropDwarf: visuals.lua
-- Advanced graphics, lighting, atmosphere, and post-processing effects.
-- Applies per-biome lighting transitions and hub atmosphere.

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

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
        Ambient             = Color3.fromRGB(90, 25, 8),
        OutdoorAmbient      = Color3.fromRGB(70, 20, 5),
        Brightness          = 1.8,
        FogColor            = Color3.fromRGB(55, 20, 8),
        FogEnd              = 280,
        FogStart            = 60,
        ColorShift_Bottom   = Color3.fromRGB(80, 10, 0),
        ColorShift_Top      = Color3.fromRGB(180, 60, 10),
        -- Atmosphere
        AtmoDensity         = 0.7,
        AtmoOffset          = 0.25,
        AtmoColor           = Color3.fromRGB(200, 80, 20),
        AtmoDecay           = Color3.fromRGB(100, 30, 5),
        AtmoGlare           = 0.6,
        AtmoHaze            = 2.2,
        -- Bloom
        BloomIntensity      = 1.4,
        BloomSize           = 56,
        BloomThreshold      = 0.85,
        -- SunRays
        SunRaysIntensity    = 0.18,
        SunRaysSpread       = 0.4,
        -- ColorCorrection
        CCBrightness        = -0.04,
        CCSaturation        = 0.3,
        CCContrast          = 0.15,
        CCTintColor         = Color3.fromRGB(255, 160, 80),
        -- DepthOfField (subtle)
        DOFFarIntensity     = 0.1,
        DOFNearIntensity    = 0.0,
        DOFFocusDistance    = 40,
        DOFInFocusRadius    = 20,
    },
    Fortress = {
        -- Dark stone dungeon, torch-lit. Moody but playable.
        Ambient             = Color3.fromRGB(32, 26, 18),   -- raised from (12,10,8)
        OutdoorAmbient      = Color3.fromRGB(24, 20, 12),
        Brightness          = 1.2,                          -- raised from 0.5
        FogColor            = Color3.fromRGB(10, 8, 5),
        FogEnd              = 350,                          -- raised from 140
        FogStart            = 50,
        ColorShift_Bottom   = Color3.fromRGB(14, 9, 4),
        ColorShift_Top      = Color3.fromRGB(90, 68, 35),
        AtmoDensity         = 0.45,                         -- was 0.85
        AtmoOffset          = 0.05,
        AtmoColor           = Color3.fromRGB(90, 68, 35),
        AtmoDecay           = Color3.fromRGB(18, 12, 6),
        AtmoGlare           = 0.0,
        AtmoHaze            = 1.0,                          -- was 2.8
        BloomIntensity      = 2.2,   -- torches still bloom dramatically
        BloomSize           = 56,
        BloomThreshold      = 0.72,
        SunRaysIntensity    = 0.0,
        SunRaysSpread       = 0.1,
        CCBrightness        = -0.05,
        CCSaturation        = -0.15, -- desaturated stone look
        CCContrast          = 0.2,
        CCTintColor         = Color3.fromRGB(210, 180, 130), -- warm torch tint
        DOFFarIntensity     = 0.1,
        DOFNearIntensity    = 0.0,
        DOFFocusDistance    = 35,
        DOFInFocusRadius    = 18,
    },
    Cave = {
        Ambient             = Color3.fromRGB(140, 140, 148), -- bright neutral gray, clearly visible
        OutdoorAmbient      = Color3.fromRGB(120, 120, 130),
        Brightness          = 2.2,
        FogColor            = Color3.fromRGB(18, 20, 32),
        FogEnd              = 600,
        FogStart            = 120,
        ColorShift_Bottom   = Color3.fromRGB(4, 6, 14),
        ColorShift_Top      = Color3.fromRGB(8, 14, 36),
        AtmoDensity         = 0.05,  -- near-zero atmosphere
        AtmoOffset          = 0.0,
        AtmoColor           = Color3.fromRGB(60, 90, 160),
        AtmoDecay           = Color3.fromRGB(8, 12, 30),
        AtmoGlare           = 0.0,
        AtmoHaze            = 0.1,
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
        Ambient             = Color3.fromRGB(42, 32, 16),   -- raised from (30,22,10)
        OutdoorAmbient      = Color3.fromRGB(32, 24, 10),
        Brightness          = 1.4,                          -- raised from 0.8
        FogColor            = Color3.fromRGB(16, 12, 6),
        FogEnd              = 380,                          -- raised from 160
        FogStart            = 70,
        ColorShift_Bottom   = Color3.fromRGB(22, 14, 4),
        ColorShift_Top      = Color3.fromRGB(180, 140, 40),
        AtmoDensity         = 0.35,                         -- was 0.8
        AtmoOffset          = 0.2,
        AtmoColor           = Color3.fromRGB(180, 140, 50),
        AtmoDecay           = Color3.fromRGB(35, 25, 8),
        AtmoGlare           = 0.1,
        AtmoHaze            = 0.8,                          -- was 2.8
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

return Visuals
