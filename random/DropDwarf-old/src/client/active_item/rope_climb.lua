-- DropDwarf: active_item/rope_climb.lua
-- Manages climbing rope detection, grabs, climbing velocity, and client-server sync.

local UserInputService = game:GetService("UserInputService")
local Networking  = require(game.ReplicatedStorage.Shared.networking)
local ItemData    = require(game.ReplicatedStorage.Shared.item_data)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)
local player      = game:GetService("Players").LocalPlayer

local RopeClimb = {}

function RopeClimb.CheckGrab(controller, hrp, lastVelY)
    if controller.onRope then return end

    local char = player.Character
    if not char then return end

    -- Use overlap sphere to detect nearby rope parts
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { char }
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, 1.5, overlapParams)
    
    for _, part in ipairs(parts) do
        if part.Name == "ClimbRope" then
            -- Grab the rope: report approximate fall damage/speed in meters
            local fallSpeedStuds = math.abs(lastVelY)
            if fallSpeedStuds > 40 then
                -- v^2 = 2*g*h => h = v^2/(2*g); convert studs to meters
                local approxFallMeters = (fallSpeedStuds * fallSpeedStuds)
                    / (2 * workspace.Gravity * GameData.STUDS_PER_METER)
                Networking.FireServer(Networking.Events.ApplyFallDamage, approxFallMeters)
            end
            
            controller.onRope  = true
            controller.ropeRef = part
            Networking.FireServer(Networking.Events.GrabRope, part)
            break
        end
    end
end

function RopeClimb.Update(controller, hrp)
    if not (controller.onRope and controller.ropeRef and controller.ropeRef.Parent) then
        return
    end

    -- Disable gravity by zeroing Y velocity, allow manual climb
    local climbDir = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
        climbDir = 1
    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then 
        climbDir = -1 
    end

    local def = ItemData.Items.ClimbingRope
    -- When idle (climbDir==0), hold position (0 velocity) - don't slide
    local climbSpd = (climbDir == 0) and 0 
        or (climbDir > 0 and def.climbUpSpeed or def.climbDownSpeed)
    
    local newVelY  = climbDir * climbSpd
    hrp.AssemblyLinearVelocity = Vector3.new(
        hrp.AssemblyLinearVelocity.X * 0.2,
        newVelY,
        hrp.AssemblyLinearVelocity.Z * 0.2
    )

    -- Keep player attached to rope X/Z
    local ropeCF = controller.ropeRef.CFrame
    local rpLocal = ropeCF:PointToObjectSpace(hrp.Position)
    rpLocal = Vector3.new(0, rpLocal.Y, 0)  -- clamp to rope center
    local targetPos = ropeCF:PointToWorldSpace(rpLocal)
    hrp.CFrame = CFrame.new(
        Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z),
        Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z) + hrp.CFrame.LookVector
    )
end

function RopeClimb.Release(controller)
    controller.onRope  = false
    controller.ropeRef = nil
    Networking.FireServer(Networking.Events.ReleaseRope)
end

return RopeClimb
