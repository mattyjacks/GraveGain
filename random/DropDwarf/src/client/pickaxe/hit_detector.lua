-- DropDwarf: pickaxe/hit_detector.lua
-- Processes camera-forward raycasts for combat, ore extraction, and terrain elasticity responses.

local TweenService = game:GetService("TweenService")
local Networking   = require(game.ReplicatedStorage.Shared.networking)

local HitDetector = {}

-- Constant configuration
local HIT_RANGE        = 8
local SOFT_FALL_BLEED  = 18
local BOUNCE_IMPULSE   = 22
local SLIME_LIGHT_DMG  = 10
local SLIME_HEAVY_BASE = 20
local SLIME_HEAVY_MAX  = 80

function HitDetector.Raycast(camera, char)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local origin    = camera.CFrame.Position
    local direction = camera.CFrame.LookVector * HIT_RANGE
    return workspace:Raycast(origin, direction, rayParams)
end

-- Stamp visual scratch marks on cave walls
local function spawnCarveMark(pos, normal, terrainType)
    local mark = Instance.new("Part")
    mark.Name        = "CarveMark"
    mark.Size        = Vector3.new(0.6, 0.6, 0.15)
    mark.Anchored    = true
    mark.CanCollide  = false
    mark.CastShadow  = false
    
    local col = (terrainType == "Soft") and Color3.fromRGB(60, 40, 20) or Color3.fromRGB(100, 95, 85)
    mark.Color    = col
    mark.Material = Enum.Material.SmoothPlastic
    mark.CFrame   = CFrame.new(pos, pos + normal) * CFrame.Angles(0, 0, math.pi / 2)
    mark.Parent   = workspace

    TweenService:Create(mark, TweenInfo.new(8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
    task.delay(8.1, function()
        if mark.Parent then mark:Destroy() end
    end)
end

-- Apply upward/backward bounce impulse
local function applyBounce(player, impulse)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bv = Instance.new("BodyVelocity")
    bv.Name      = "PickaxeBounce"
    bv.Velocity  = Vector3.new(
        hrp.CFrame.LookVector.X * -impulse * 0.4,
        impulse * 0.7,
        hrp.CFrame.LookVector.Z * -impulse * 0.4
    )
    bv.MaxForce  = Vector3.new(1e4, 1e4, 1e4)
    bv.Parent    = hrp
    task.delay(0.15, function()
        if bv.Parent then bv:Destroy() end
    end)
end

-- Bleed fall velocity when pickaxe grips soft surfaces
local function reduceVerticalVelocity(player, reduction)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vel = hrp.AssemblyLinearVelocity
    local newVelY = math.max(vel.Y, vel.Y + reduction)
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.5, newVelY, vel.Z * 0.5)
end

-- Spawn local rock/dirt chips when mining
local function spawnOreChips(pos, oreColor)
    for i = 1, 6 do
        local chip = Instance.new("Part")
        chip.Name        = "OreChip"
        chip.Size        = Vector3.new(math.random(10, 30)/100, math.random(10, 30)/100, math.random(10, 30)/100)
        chip.Position    = pos + Vector3.new(math.random(-8, 8)/10, math.random(0, 8)/10, math.random(-8, 8)/10)
        chip.Color       = oreColor
        chip.Material    = Enum.Material.SmoothPlastic
        chip.Anchored    = false
        chip.CanCollide  = false
        chip.CastShadow  = false
        chip.Parent      = workspace
        chip.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(4, 14), math.random(-12, 12))

        TweenService:Create(chip, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = 1, Size = Vector3.new(0.02, 0.02, 0.02) }):Play()
        task.delay(0.65, function()
            if chip.Parent then chip:Destroy() end
        end)
    end
end

-- Swing hit to Slime cube
local function damageSlime(slimePart, chargePower, isHeavy)
    if not slimePart then return end
    
    local damage
    if isHeavy then
        damage = math.floor(SLIME_HEAVY_BASE + (SLIME_HEAVY_MAX - SLIME_HEAVY_BASE) * chargePower)
    else
        damage = SLIME_LIGHT_DMG
    end

    Networking.FireServer(Networking.Events.SlimeKilled, slimePart, damage, slimePart.Position)

    -- Slime green visual splat
    local flash = Instance.new("Part")
    flash.Shape         = Enum.PartType.Ball
    flash.Size          = Vector3.new(1.5 + chargePower*2, 1.5 + chargePower*2, 1.5 + chargePower*2)
    flash.CFrame        = CFrame.new(slimePart.Position)
    flash.Anchored      = true
    flash.CanCollide    = false
    flash.CastShadow    = false
    flash.Color         = Color3.fromRGB(60, 255, 80)
    flash.Material      = Enum.Material.Neon
    flash.Transparency  = 0.2
    flash.Parent        = workspace

    TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1) }):Play()
    game:GetService("Debris"):AddItem(flash, 0.45)
end

function HitDetector.Process(controller, hitResult, isHeavy, chargePower)
    if not hitResult then return end
    local instance = hitResult.Instance
    if not instance then return end

    if instance.Name == "GoldCoin" or instance:FindFirstChild("IsCoin") then
        return
    end

    -- Slime
    if instance.Name == "SlimeCube" or instance:FindFirstChild("IsSlime") then
        damageSlime(instance, chargePower or 0, isHeavy)
        return
    end

    -- Wall Ore node
    if instance.Name == "WallOre" and instance:FindFirstChild("IsMineable") then
        spawnOreChips(hitResult.Position, instance.Color)
        Networking.FireServer(Networking.Events.MineWall, instance, chargePower or 0)
        return
    end

    -- Standard Biome Shaft terrain
    local terrainTag = instance:FindFirstChild("TerrainType")
    local terrainType = terrainTag and terrainTag.Value or "Firm"

    spawnCarveMark(hitResult.Position, hitResult.Normal, terrainType)
    Networking.FireServer(Networking.Events.PickaxeTerrainHit, hitResult.Position, terrainType)

    if terrainType == "Soft" then
        reduceVerticalVelocity(controller.player, SOFT_FALL_BLEED)
        for i = 1, 3 do
            spawnCarveMark(hitResult.Position + Vector3.new(0, -i * 0.25, 0), hitResult.Normal, terrainType)
        end
    elseif terrainType == "Firm" then
        if isHeavy then
            reduceVerticalVelocity(controller.player, SOFT_FALL_BLEED * (0.3 + chargePower * 0.7))
        else
            applyBounce(controller.player, BOUNCE_IMPULSE * 0.8)
        end
    elseif terrainType == "Hard" then
        if isHeavy and chargePower >= 0.8 then
            reduceVerticalVelocity(controller.player, SOFT_FALL_BLEED * 0.4)
        else
            applyBounce(controller.player, BOUNCE_IMPULSE * (1.2 + chargePower * 0.4))
        end
    end
end

return HitDetector
