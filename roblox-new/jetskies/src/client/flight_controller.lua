local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FlightController = {}
local GameData

-- State
local state = {
    jetSky = nil,
    hull = nil,
    thrusterLeft = nil,
    thrusterRight = nil,
    velocity = Vector3.zero,
    angularVelocity = Vector3.zero,
    altitude = 0,
    speed = 0,
    boostFuel = 100,
    isBoosting = false,
    boostCooldown = 0,
    tiltX = 0,
    tiltZ = 0,
    stats = nil,
    isInWater = false,
    waterTouchParts = {}
}

-- Input state
local input = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false,
    Ctrl = false,
    Shift = false
}

function FlightController:Init(jetSky, stats)
    GameData = require(game:GetService("ReplicatedStorage").Shared.game_data)
    
    state.jetSky = jetSky
    state.hull = jetSky:WaitForChild("Hull")
    state.thrusterLeft = jetSky:WaitForChild("LeftThruster")
    state.thrusterRight = jetSky:WaitForChild("RightThruster")
    state.stats = stats
    state.boostFuel = stats.boostCapacity
    
    -- Add BodyVelocity for smooth physics control
    local bodyVel = state.hull:FindFirstChild("JetSkyVelocity")
    if not bodyVel then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "JetSkyVelocity"
        bodyVel.MaxForce = Vector3.new(50000, 50000, 50000)
        bodyVel.Velocity = Vector3.zero
        bodyVel.Parent = state.hull
    end
    state.bodyVelocity = bodyVel
    
    -- Add BodyGyro for rotation control
    local bodyGyro = state.hull:FindFirstChild("JetSkyGyro")
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "JetSkyGyro"
        bodyGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
        bodyGyro.P = 10000
        bodyGyro.Parent = state.hull
    end
    state.bodyGyro = bodyGyro
    
    -- Setup water detection for all parts
    self:SetupWaterDetection()
    
    -- Input handling
    UserInputService.InputBegan:Connect(function(key, processed)
        if processed then return end
        self:HandleInput(key.KeyCode, true)
    end)
    
    UserInputService.InputEnded:Connect(function(key)
        self:HandleInput(key.KeyCode, false)
    end)
    
    print("[FlightController] Initialized")
end

function FlightController:SetupWaterDetection()
    -- Connect touch detection to all JetSky parts
    for _, part in ipairs(state.jetSky:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if hit.Name == "Ocean" or hit.Parent and hit.Parent.Name == "World" then
                    state.waterTouchParts[part] = true
                    state.isInWater = true
                end
            end)
            
            part.TouchEnded:Connect(function(hit)
                if hit.Name == "Ocean" or hit.Parent and hit.Parent.Name == "World" then
                    state.waterTouchParts[part] = nil
                    -- Check if any parts still in water
                    state.isInWater = next(state.waterTouchParts) ~= nil
                end
            end)
        end
    end
end

function FlightController:HandleInput(keyCode, isPressed)
    if keyCode == Enum.KeyCode.W then input.W = isPressed end
    if keyCode == Enum.KeyCode.A then input.A = isPressed end
    if keyCode == Enum.KeyCode.S then input.S = isPressed end
    if keyCode == Enum.KeyCode.D then input.D = isPressed end
    if keyCode == Enum.KeyCode.Space then input.Space = isPressed end
    if keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.RightControl then
        input.Ctrl = isPressed
    end
    if keyCode == Enum.KeyCode.LeftShift then input.Shift = isPressed end
end

function FlightController:Update(dt)
    if not state.hull then return end
    
    local hull = state.hull
    local currentCFrame = hull.CFrame
    local currentVelocity = hull.AssemblyLinearVelocity
    
    -- Check water contact using position
    local pos = hull.Position
    local waterLevel = GameData.WATER_LEVEL
    local wasInWater = state.isInWater
    state.isInWater = pos.Y <= waterLevel + 2  -- +2 for part height tolerance
    
    -- Splash effect when entering water
    if state.isInWater and not wasInWater and state.speed > GameData.SPLASH_THRESHOLD then
        self:CreateSplashEffect(pos)
    end
    
    -- Calculate input vectors
    local moveForward = input.W and 1 or (input.S and -1 or 0)
    local turnRight = input.D and 1 or (input.A and -1 or 0)
    local ascend = input.Space and 1 or (input.Ctrl and -1 or 0)
    
    -- Base speed with upgrade multiplier
    local baseSpeed = state.stats.speed or GameData.BASE_SPEED
    local speed = baseSpeed
    
    -- WATER PHYSICS: Faster in water!
    local drag = GameData.AIR_DRAG
    if state.isInWater then
        speed = speed * GameData.WATER_SPEED_MULTIPLIER
        drag = GameData.WATER_DRAG
    end
    
    -- Boost handling
    if input.Shift and state.boostFuel > 0 and state.boostCooldown <= 0 then
        state.isBoosting = true
        speed = speed * GameData.BOOST_MULTIPLIER
        state.boostFuel = math.max(0, state.boostFuel - GameData.BOOST_DRAIN_RATE * dt)
        
        -- Visual boost effect
        self:UpdateThrusterVisuals(true)
    else
        state.isBoosting = false
        state.boostCooldown = math.max(0, state.boostCooldown - dt)
        
        -- Recharge boost
        if state.boostFuel < state.stats.boostCapacity then
            state.boostFuel = math.min(state.stats.boostCapacity, state.boostFuel + GameData.BOOST_RECHARGE_RATE * dt)
        end
        
        self:UpdateThrusterVisuals(false, state.isInWater)
        
        -- Trigger cooldown if depleted
        if input.Shift and state.boostFuel <= 0 then
            state.boostCooldown = GameData.BOOST_COOLDOWN
        end
    end
    
    -- Calculate forces
    local forward = currentCFrame.LookVector
    local right = currentCFrame.RightVector
    local up = currentCFrame.UpVector
    
    -- Forward thrust (stronger in water)
    local thrust = forward * moveForward * speed
    
    -- Vertical movement
    local vertical = Vector3.new(0, ascend * GameData.ALTITUDE_SPEED, 0)
    
    -- BUOYANCY: Float when in water!
    if state.isInWater then
        -- Apply upward buoyancy force
        vertical = vertical + Vector3.new(0, GameData.BUOYANCY_FORCE, 0)
        
        -- Dampen falling velocity when hitting water
        if currentVelocity.Y < 0 then
            currentVelocity = Vector3.new(currentVelocity.X, currentVelocity.Y * 0.5, currentVelocity.Z)
        end
        
        -- Auto-level when in water (no tilting)
        state.tiltZ = 0
        state.tiltX = 0
    else
        -- Apply tilt for visual feedback (only in air)
        state.tiltZ = moveForward * GameData.TILT_ANGLE
        state.tiltX = -turnRight * GameData.TILT_ANGLE * 0.5
    end
    
    -- Turn torque
    local handling = state.stats.handling or GameData.TURN_SPEED
    local turnAmount = turnRight * handling * dt * 60
    
    -- Calculate target rotation (yaw only, tilt is visual)
    local targetRotation = currentCFrame * CFrame.Angles(0, math.rad(-turnAmount), 0)
    
    -- Apply tilt for visual feedback
    local targetTilt = CFrame.Angles(math.rad(state.tiltZ), 0, math.rad(state.tiltX))
    hull.CFrame = targetRotation * targetTilt
    
    -- Use BodyGyro to maintain rotation
    if state.bodyGyro then
        state.bodyGyro.CFrame = targetRotation
    end
    
    -- Calculate target velocity with appropriate drag (water = less drag = faster)
    local targetVelocity = thrust + vertical
    state.velocity = currentVelocity:Lerp(targetVelocity, 0.1) * drag
    
    -- Altitude ceiling check
    if pos.Y > GameData.MAX_ALTITUDE then
        state.velocity = Vector3.new(state.velocity.X, -10, state.velocity.Z)
    end
    
    -- Apply velocity using BodyVelocity
    if state.bodyVelocity then
        state.bodyVelocity.Velocity = state.velocity
    else
        hull.AssemblyLinearVelocity = state.velocity
    end
    
    -- Update stats
    state.altitude = pos.Y
    state.speed = state.velocity.Magnitude
end

function FlightController:UpdateThrusterVisuals(isBoosting, isInWater)
    if not state.thrusterLeft or not state.thrusterRight then return end
    
    local color
    if isBoosting then
        color = Color3.fromRGB(255, 100, 0)  -- Orange for boost
    elseif isInWater then
        color = Color3.fromRGB(0, 255, 200)  -- Cyan for water mode
    else
        color = Color3.fromRGB(0, 200, 255)  -- Blue for normal
    end
    
    -- Update glow parts
    local leftGlow = state.thrusterLeft:FindFirstChild("LeftGlow")
    local rightGlow = state.thrusterRight:FindFirstChild("RightGlow")
    
    if leftGlow then leftGlow.Color = color end
    if rightGlow then rightGlow.Color = color end
end

function FlightController:IsInWater()
    return state.isInWater
end

function FlightController:CreateSplashEffect(position)
    local Workspace = game:GetService("Workspace")
    
    -- Create splash particles
    local splashPart = Instance.new("Part")
    splashPart.Anchored = true
    splashPart.CanCollide = false
    splashPart.Transparency = 1
    splashPart.Size = Vector3.new(1, 1, 1)
    splashPart.Position = Vector3.new(position.X, GameData.WATER_LEVEL, position.Z)
    splashPart.Parent = Workspace
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255), Color3.fromRGB(150, 200, 255))
    emitter.Size = NumberSequence.new(2, 5)
    emitter.Lifetime = NumberRange.new(0.5, 1)
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(20, 40)
    emitter.Acceleration = Vector3.new(0, -30, 0)
    emitter.SpreadAngle = Vector2.new(45, 45)
    emitter.Parent = splashPart
    
    emitter:Emit(30)
    
    -- Create ripple ring
    local ripple = Instance.new("Part")
    ripple.Shape = Enum.PartType.Cylinder
    ripple.Size = Vector3.new(0.5, 1, 1)
    ripple.Orientation = Vector3.new(0, 0, 90)
    ripple.Color = Color3.fromRGB(255, 255, 255)
    ripple.Material = Enum.Material.SmoothPlastic
    ripple.Transparency = 0.5
    ripple.Anchored = true
    ripple.CanCollide = false
    ripple.Position = Vector3.new(position.X, GameData.WATER_LEVEL + 0.1, position.Z)
    ripple.Parent = Workspace
    
    -- Animate ripple expanding
    task.spawn(function()
        for i = 1, 20 do
            ripple.Size = Vector3.new(0.5, 1 + i * 2, 1 + i * 2)
            ripple.Transparency = 0.5 + (i / 20) * 0.5
            task.wait(0.03)
        end
        ripple:Destroy()
    end)
    
    -- Cleanup splash
    task.delay(1.5, function()
        splashPart:Destroy()
    end)
end

function FlightController:GetVelocity()
    return state.velocity
end

function FlightController:GetAltitude()
    return state.altitude
end

function FlightController:GetSpeed()
    return state.speed
end

function FlightController:GetBoostFuel()
    return state.boostFuel
end

function FlightController:GetMaxBoost()
    return state.stats and state.stats.boostCapacity or 100
end

function FlightController:IsBoosting()
    return state.isBoosting
end

function FlightController.IsActive()
    return state.jetSky ~= nil
end

return FlightController
