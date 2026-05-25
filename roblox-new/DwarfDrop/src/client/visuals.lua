-- DwarfDrop: visuals.lua
-- Client-side visual effects: dust puffs, coin collect pulse, air-jump puff, biome lighting

local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")

local BiomeData = require(game.ReplicatedStorage.Shared.biome_data)
local GameData  = require(game.ReplicatedStorage.Shared.game_data)

local Visuals = {}
Visuals.__index = Visuals

function Visuals.new()
    local self = setmetatable({}, Visuals)
    self.lastBiomeName   = nil
    self.biomeTween      = nil
    return self
end

local function spawnParticleModel(pos, color, count, lifeTime)
    for i = 1, count do
        local p = Instance.new("Part")
        p.Size             = Vector3.new(0.2, 0.2, 0.2)
        p.CFrame           = CFrame.new(pos + Vector3.new(
            (math.random()-0.5)*2.4,
            math.random()*1.0,
            (math.random()-0.5)*2.4))
        p.Color            = color
        p.Material         = Enum.Material.SmoothPlastic
        p.Anchored         = false
        p.CanCollide       = false
        p.CastShadow       = false
        p.Parent           = workspace

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e4,1e4,1e4)
        bv.Velocity = Vector3.new(
            (math.random()-0.5)*20,
            math.random()*18 + 8,
            (math.random()-0.5)*20)
        bv.Parent = p

        game:GetService("Debris"):AddItem(p, lifeTime or 1.0)
    end
end

function Visuals:SpawnDustPuff(pos)
    spawnParticleModel(pos, Color3.fromRGB(180,170,155), 8, 0.9)
end

function Visuals:SpawnAirJumpPuff(pos)
    spawnParticleModel(pos, Color3.fromRGB(80,200,255), 5, 0.6)
end

function Visuals:PulseCoinCollect()
    -- Handled by HUD combo UI; no world particle needed
end

function Visuals:UpdateBiomeLighting(biome, transitionTime)
    if not biome then return end
    if self.lastBiomeName == biome.name then return end
    self.lastBiomeName = biome.name

    transitionTime = transitionTime or 3.5
    local tInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    local target = {
        Ambient      = biome.ambientColor      or Color3.fromRGB(40, 38, 50),
        OutdoorAmbient = biome.ambientColor    or Color3.fromRGB(30, 28, 40),
        FogColor     = biome.fogColor          or Color3.fromRGB(20, 16, 24),
        FogEnd       = biome.fogEnd            or 500,
        ColorShift_Bottom = biome.sunlightColor or Color3.fromRGB(80,70,120),
    }

    if self.biomeTween then self.biomeTween:Cancel() end
    self.biomeTween = TweenService:Create(Lighting, tInfo, target)
    self.biomeTween:Play()
end

function Visuals:ShowBasketLaunchEffect(basketFolder)
    if not basketFolder then return end
    local floor = basketFolder:FindFirstChild("BasketFloor")
    if not floor then return end

    -- Steam puff particles around base
    spawnParticleModel(floor.Position + Vector3.new(0,2,0),
        Color3.fromRGB(230,230,230), 20, 2.0)

    -- Shake camera handled by main.client via CameraShakeSignal
end

return Visuals
