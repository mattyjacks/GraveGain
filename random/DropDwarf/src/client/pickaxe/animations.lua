-- DropDwarf: pickaxe/animations.lua
-- Computes procedural walk bobbing, breathing, charge pullbacks, and third-person swings.

local TweenService = game:GetService("TweenService")

local Animations = {}

-- Constants
local BOB_SPEED            = 8
local BOB_AMOUNT           = 0.045
local IDLE_BREATH_SPEED    = 1.4
local IDLE_BREATH_AMOUNT   = 0.012

local SWING_DURATION       = 0.35
local HEAVY_SWING_DURATION = 0.5

function Animations.GetBobSway(controller, isMoving, isFalling, dt)
    -- Idle breathing
    controller.breathTime = (controller.breathTime or 0) + dt * IDLE_BREATH_SPEED
    local breathY = math.sin(controller.breathTime) * IDLE_BREATH_AMOUNT
    local breathX = math.cos(controller.breathTime * 0.5) * IDLE_BREATH_AMOUNT * 0.4

    -- Walk bobbing
    if isMoving and not isFalling and not controller.isSwinging then
        controller.bobTime = (controller.bobTime or 0) + dt * BOB_SPEED
    else
        controller.bobTime = (controller.bobTime or 0) * 0.88
    end
    local bobX = math.sin(controller.bobTime) * BOB_AMOUNT
    local bobY = math.abs(math.cos(controller.bobTime)) * BOB_AMOUNT * 0.55
    local bobRoll = math.sin(controller.bobTime) * math.rad(1.8)

    return bobX, bobY, bobRoll, breathX, breathY
end

function Animations.GetChargePullback(controller, isCharging, chargePower)
    local chargeOffset = CFrame.new()
    if isCharging then
        local ct2 = chargePower * chargePower -- ease-in square
        chargeOffset = CFrame.new(0.06 * ct2, 0.18 * ct2, 0.32 * ct2)
            * CFrame.Angles(math.rad(38 * ct2), math.rad(-12 * ct2), math.rad(-8 * ct2))
        
        -- Tremble at high charge
        if chargePower >= 0.95 then
            local tr = math.sin(tick() * 40) * 0.012
            chargeOffset = chargeOffset * CFrame.new(tr, tr * 0.5, 0)
        end
    end
    return chargeOffset
end

function Animations.GetSwingOffset(controller, dt)
    local swingOffset = CFrame.new()
    if not controller.isSwinging then
        return swingOffset
    end

    controller.swingTime = controller.swingTime + dt
    local dur = controller.isHeavySwing and HEAVY_SWING_DURATION or SWING_DURATION
    local t = math.min(controller.swingTime / dur, 1)

    if t >= 1 then
        controller.isSwinging   = false
        controller.isHeavySwing = false
        controller.swingTime    = 0
    else
        -- Two-phase swing arc
        local arc = 0
        if t < 0.5 then
            arc = t / 0.5
        else
            arc = 1 - (t - 0.5) / 0.5
        end
        arc = arc * arc * (3 - 2 * arc) -- smooth ease

        if controller.isHeavySwing then
            -- Heavy overhead swing
            swingOffset = CFrame.Angles(
                math.rad(-58 * arc),
                math.rad(-18 * arc),
                math.rad( 12 * arc)
            ) * CFrame.new(0.06 * arc, -0.30 * arc, 0.18 * arc)
        else
            -- Light swift downward swing
            swingOffset = CFrame.Angles(
                math.rad(-32 * arc),
                math.rad(-8  * arc),
                math.rad( 3  * arc)
            ) * CFrame.new(0.02 * arc, -0.16 * arc, 0.12 * arc)
        end
    end

    return swingOffset
end

function Animations.PlayTPSSwing(player, isHeavy)
    local char = player.Character
    if not char then return end
    local rs = char:FindFirstChild("RightShoulder")
        or (char:FindFirstChild("UpperTorso")
            and char.UpperTorso:FindFirstChild("RightShoulder"))
    if not rs then return end

    local swingAngle = isHeavy and math.rad(-110) or math.rad(-70)
    local original   = rs.C0
    local swungCF    = original * CFrame.Angles(swingAngle, 0, 0)

    -- Snap strike forward
    TweenService:Create(rs, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = swungCF }):Play()
    
    -- Smooth recovery back to standard grip
    task.delay(0.18, function()
        if rs.Parent then
            TweenService:Create(rs, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = original }):Play()
        end
    end)
end

return Animations
