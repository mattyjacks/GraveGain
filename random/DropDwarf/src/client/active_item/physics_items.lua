-- DropDwarf: active_item/physics_items.lua
-- Applies client-side physical forces for active equipment (parachutes, jetpacks, balloons, etc.).

local ItemData = require(game.ReplicatedStorage.Shared.item_data)
local player   = game:GetService("Players").LocalPlayer

local PhysicsItems = {}

function PhysicsItems.UpdateParachute(controller, hrp, char, dt)
    if not controller.parachuteOpen then return end
    
    local def = ItemData.Items.Parachute
    local vel = hrp.AssemblyLinearVelocity
    
    -- Cap downward speed
    if vel.Y < -def.fallSpeedCap then
        hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -def.fallSpeedCap, vel.Z)
    end
    
    -- Check ceiling collision (damage parachute)
    local chuteRP = RaycastParams.new()
    chuteRP.FilterType = Enum.RaycastFilterType.Exclude
    chuteRP.FilterDescendantsInstances = { char }
    local upResult = workspace:Raycast(hrp.Position, Vector3.new(0, 10, 0), chuteRP)
    
    if upResult and upResult.Instance then
        local now = tick()
        if now - controller.lastChuteDmgTime >= 0.5 then
            controller.lastChuteDmgTime = now
            controller.chuteHP = controller.chuteHP - 1
            if controller.hudRef and controller.hudRef.UpdateChuteHP then
                controller.hudRef:UpdateChuteHP(controller.chuteHP)
            end
            if controller.chuteHP <= 0 then
                controller:_closeParachute()
            end
        end
    end
end

function PhysicsItems.UpdateBalloon(controller, hrp, dt)
    if not controller.balloonOn then return end
    
    local def = ItemData.Items.Balloon
    local normalGrav = workspace.Gravity
    local wantedGrav = normalGrav * def.gravityScale
    local gravDiff   = normalGrav - wantedGrav
    
    -- Apply upward force to simulate lighter gravity
    hrp:ApplyImpulse(Vector3.new(0, hrp.AssemblyMass * gravDiff * dt, 0))
end

function PhysicsItems.UpdateJetpack(controller, hrp, dt)
    if not (controller.jetpackOn and controller.water > 0) then return end
    
    local def = ItemData.Items.SteamJetpack
    -- Apply upward lift force
    hrp:ApplyImpulse(Vector3.new(0, hrp.AssemblyMass * def.liftForce * dt, 0))
end

function PhysicsItems.UpdateThrower(controller, hrp, hum, dt)
    if not (controller.throwerOn and controller.water > 0) then return end
    
    local def   = ItemData.Items.SteamThrower
    local cam   = workspace.CurrentCamera
    local lv    = cam.CFrame.LookVector
    local lookFlat = Vector3.new(lv.X, 0, lv.Z)
    
    -- Knockback in opposite direction of camera look flat vector when in mid-air
    if lookFlat.Magnitude > 0.01 then
        local lookH = lookFlat.Unit
        local isOnGround = (hum.FloorMaterial ~= Enum.Material.Air)
        if not isOnGround then
            hrp:ApplyImpulse(-lookH * hrp.AssemblyMass * def.knockbackForce * dt)
        end
    end
end

return PhysicsItems
