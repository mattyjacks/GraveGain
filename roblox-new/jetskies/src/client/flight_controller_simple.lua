local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local FlightController = {}
local GameData

-- State
local state = {
    jetSky = nil,
    hull = nil,
    seat = nil,
    
    -- Physics
    velocity = Vector3.zero,
    rotation = CFrame.new(),
    
    -- Controls
    throttle = 0,
    pitch = 0,
    yaw = 0,
    roll = 0,
    
    -- Systems
    boostFuel = 100,
    isBoosting = false,
    boostCooldown = 0,
    
    -- Environment
    isInWater = false,
    
    -- Stats
    stats = nil,
    
    -- Physics bodies
    bodyVelocity = nil,
    bodyAngularVelocity = nil
}

-- Input state
local input = {
    W = false,
    S = false,
    A = false,
    D = false,
    Space = false,
    Ctrl = false,
    Shift = false
}

function FlightController:Init(jetSky, seat, stats)
    GameData = require(game:GetService("ReplicatedStorage").Shared.game_data)
    
    state.jetSky = jetSky
    state.hull = jetSky:FindFirstChild("HullLower") or jetSky:WaitForChild("Hull")
    state.seat = seat
    state.stats = stats
    state.boostFuel = stats.boostCapacity or 100
    
    -- Setup physics
    self:SetupPhysics()
    
    -- Input handling
    UserInputService.InputBegan:Connect(function(key, processed)
        if processed then return end
        self:HandleInput(key.KeyCode, true)
    end)
    
    UserInputService.InputEnded:Connect(function(key)
        self:HandleInput(key.KeyCode, false)
    end)
    
    -- Set initial rotation
    state.rotation = state.hull.CFrame - state.hull.CFrame.Position
    
    print("[FlightController] Simple controller initialized")
end

function FlightController:SetupPhysics()
    -- Remove old physics bodies
    local oldVel = state.hull:FindFirstChild("JetSkyVelocity")
    if oldVel then oldVel:Destroy() end
    local oldGyro = state.hull:FindFirstChild("JetSkyGyro")
    if oldGyro then oldGyro:Destroy() end
    
    -- BodyVelocity for movement
    state.bodyVelocity = Instance.new("BodyVelocity")
    state.bodyVelocity.Name = "JetSkyVelocity"
    state.bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
    state.bodyVelocity.Velocity = Vector3.zero
    state.bodyVelocity.Parent = state.hull
    
    -- BodyAngularVelocity for rotation
    state.bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    state.bodyAngularVelocity.Name = "JetSkyAngularVel"
    state.bodyAngularVelocity.MaxTorque = Vector3.new(30000, 30000, 30000)
    state.bodyAngularVelocity.AngularVelocity = Vector3.zero
    state.bodyAngularVelocity.Parent = state.hull
    
    -- Make sure hull isn't anchored
    state.hull.Anchored = false
end

function FlightController:HandleInput(keyCode, isPressed)
    if keyCode == Enum.KeyCode.W then input.W = isPressed end
    if keyCode == Enum.KeyCode.S then input.S = isPressed end
    if keyCode == Enum.KeyCode.A then input.A = isPressed end
    if keyCode == Enum.KeyCode.D then input.D = isPressed end
    if keyCode == Enum.KeyCode.Space then input.Space = isPressed end
    if keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.RightControl then
        input.Ctrl = isPressed
    end
    if keyCode == Enum.KeyCode.LeftShift then input.Shift = isPressed end
end

function FlightController:Update(dt)
    if not state.hull then return self:GetState() end
    
    local hull = state.hull
    local currentVel = hull.AssemblyLinearVelocity
    local currentPos = hull.Position
    local currentCFrame = hull.CFrame
    
    -- Check water status
    local waterLevel = GameData.WATER_LEVEL
    local wasInWater = state.isInWater
    state.isInWater = currentPos.Y <= waterLevel + 2
    
    if state.isInWater and not wasInWater and currentVel.Magnitude > 5 then
        self:CreateSplash(currentPos)
    end
    
    -- === THROTTLE CONTROL ===
    if input.W then
        state.throttle = math.min(state.throttle + dt * 1.5, 1)
    elseif input.S then
        state.throttle = math.max(state.throttle - dt * 1.5, 0)
    end
    
    -- Boost
    if input.Shift and state.boostFuel > 0 and state.boostCooldown <= 0 then
        state.isBoosting = true
        state.boostFuel = math.max(0, state.boostFuel - dt * 20)
    else
        state.isBoosting = false
        state.boostCooldown = math.max(0, state.boostCooldown - dt)
        if state.boostFuel < 100 then
            state.boostFuel = math.min(100, state.boostFuel + dt * 10)
        end
        if input.Shift and state.boostFuel <= 0 then
            state.boostCooldown = 1
        end
    end
    
    -- === ROTATION CONTROLS ===
    -- Pitch (Space/Ctrl or mouse)
    if input.Space then
        state.pitch = math.min(state.pitch + dt * 2, 1)
    elseif input.Ctrl then
        state.pitch = math.max(state.pitch - dt * 2, -1)
    else
        state.pitch = state.pitch * 0.9  -- Return to center
    end
    
    -- Yaw (A/D - rudder)
    if input.A then
        state.yaw = math.max(state.yaw - dt * 2, -1)
    elseif input.D then
        state.yaw = math.min(state.yaw + dt * 2, 1)
    else
        state.yaw = state.yaw * 0.9
    end
    
    -- Auto-roll to level when no input
    state.roll = state.roll * 0.95
    
    -- === CALCULATE FORCES ===
    local forward = currentCFrame.LookVector
    local up = currentCFrame.UpVector
    local right = currentCFrame.RightVector
    
    -- Base speed
    local baseSpeed = (state.stats.speed or 50)
    local maxSpeed = baseSpeed * (state.isBoosting and 2 or 1)
    
    -- Water speed bonus
    if state.isInWater then
        maxSpeed = maxSpeed * 1.5
    end
    
    -- Thrust force
    local thrust = forward * state.throttle * maxSpeed * 2
    
    -- Add pitch lift component
    local pitchLift = up * state.pitch * maxSpeed * 0.5
    
    -- Apply gravity compensation when not in water
    local gravityComp = Vector3.zero
    if not state.isInWater then
        gravityComp = Vector3.new(0, 30, 0)  -- Counter gravity
    end
    
    -- Buoyancy in water
    local buoyancy = Vector3.zero
    if state.isInWater then
        local depth = math.max(0, waterLevel + 2 - currentPos.Y)
        buoyancy = Vector3.new(0, 80 + depth * 10, 0)
    end
    
    -- Total velocity target
    local targetVel = thrust + pitchLift + gravityComp + buoyancy
    
    -- Smooth velocity transition
    local newVel = currentVel:Lerp(targetVel, 0.1)
    
    -- Apply drag
    if not state.isInWater then
        newVel = newVel * 0.98
    else
        newVel = newVel * 0.95
    end
    
    -- Apply velocity
    if state.bodyVelocity then
        state.bodyVelocity.Velocity = newVel
    end
    
    -- === ROTATION ===
    -- Calculate angular velocity based on controls
    local angularVel = Vector3.new(
        -state.pitch * 2,  -- Pitch (X axis rotation)
        state.yaw * 1.5,    -- Yaw (Y axis rotation)
        -state.roll * 2     -- Roll (Z axis rotation)
    )
    
    -- Add auto-leveling when in water
    if state.isInWater then
        angularVel = angularVel + Vector3.new(-currentCFrame:ToEulerAnglesXYZ().X * 0.5, 0, -currentCFrame:ToEulerAnglesXYZ().Z * 0.5)
    end
    
    -- Apply rotation
    if state.bodyAngularVelocity then
        state.bodyAngularVelocity.AngularVelocity = angularVel
    end
    
    -- Update state
    state.velocity = newVel
    
    -- Visual effects
    self:UpdateVisuals()
    
    return self:GetState()
end

function FlightController:UpdateVisuals()
    -- Update thruster glows
    local leftGlow = state.jetSky:FindFirstChild("LeftOuterGlow") or state.jetSky:FindFirstChild("LeftGlow")
    local rightGlow = state.jetSky:FindFirstChild("RightOuterGlow") or state.jetSky:FindFirstChild("RightGlow")
    
    local color
    if state.isBoosting then
        color = Color3.fromRGB(255, 100, 0)
    elseif state.isInWater then
        color = Color3.fromRGB(0, 200, 255)
    else
        color = Color3.fromRGB(0, 255, 200)
    end
    
    if leftGlow then leftGlow.Color = color end
    if rightGlow then rightGlow.Color = color end
    
    -- Emit particles from nozzles
    if state.throttle > 0.1 then
        for _, side in ipairs({"Left", "Right"}) do
            local nozzle = state.jetSky:FindFirstChild(side .. "Nozzle")
            if nozzle then
                local emitter = nozzle:FindFirstChild("ThrustParticles")
                if not emitter then
                    emitter = Instance.new("ParticleEmitter")
                    emitter.Name = "ThrustParticles"
                    emitter.Color = ColorSequence.new(color)
                    emitter.Size = NumberSequence.new(0.3, 1)
                    emitter.Lifetime = NumberRange.new(0.2, 0.4)
                    emitter.Rate = 50
                    emitter.Speed = NumberRange.new(10, 20)
                    emitter.Acceleration = Vector3.new(0, 0, 10)
                    emitter.Parent = nozzle
                end
                emitter.Rate = state.throttle * (state.isBoosting and 100 or 50)
            end
        end
    end
end

function FlightController:CreateSplash(position)
    local splash = Instance.new("Part")
    splash.Anchored = true
    splash.CanCollide = false
    splash.Transparency = 1
    splash.Size = Vector3.new(1, 1, 1)
    splash.Position = Vector3.new(position.X, GameData.WATER_LEVEL, position.Z)
    splash.Parent = Workspace
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    emitter.Size = NumberSequence.new(0.5, 2)
    emitter.Lifetime = NumberRange.new(0.3, 0.6)
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(5, 15)
    emitter.SpreadAngle = Vector2.new(60, 60)
    emitter.Parent = splash
    emitter:Emit(15)
    
    task.delay(0.8, function()
        splash:Destroy()
    end)
end

function FlightController:GetState()
    return {
        velocity = state.velocity,
        altitude = state.hull and state.hull.Position.Y or 0,
        speed = state.velocity and state.velocity.Magnitude or 0,
        throttle = state.throttle,
        pitch = state.pitch,
        yaw = state.yaw,
        roll = state.roll,
        isBoosting = state.isBoosting,
        isInWater = state.isInWater,
        boostFuel = state.boostFuel,
        boostMax = 100
    }
end

function FlightController:GetVelocity() return state.velocity end
function FlightController:GetAltitude() return state.hull and state.hull.Position.Y or 0 end
function FlightController:GetSpeed() return state.velocity.Magnitude end
function FlightController:IsInWater() return state.isInWater end
function FlightController.IsActive() return state.jetSky ~= nil end

return FlightController
