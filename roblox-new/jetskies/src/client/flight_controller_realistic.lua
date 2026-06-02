local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FlightController = {}
local GameData
local FlightPhysics

-- State
local state = {
    jetSky = nil,
    hull = nil,
    seat = nil,
    
    -- Physics state
    velocity = Vector3.zero,
    angularVelocity = Vector3.zero,
    cframe = CFrame.new(),
    altitude = 0,
    speed = 0,
    
    -- Flight controls
    throttle = 0,          -- 0 to 1
    targetThrottle = 0,
    pitch = 0,           -- -1 to 1
    roll = 0,            -- -1 to 1
    yaw = 0,             -- -1 to 1
    
    -- Systems
    boostFuel = 100,
    isBoosting = false,
    boostCooldown = 0,
    
    -- Environment
    isInWater = false,
    submergedDepth = 0,
    
    -- Physics bodies
    bodyVelocity = nil,
    bodyGyro = nil,
    
    -- Stats
    stats = nil
}

-- Input state
local input = {
    W = false,
    S = false,
    A = false,
    D = false,
    Q = false,  -- Roll left
    E = false,  -- Roll right
    Space = false,
    Ctrl = false,
    Shift = false
}

function FlightController:Init(jetSky, seat, stats)
    GameData = require(game:GetService("ReplicatedStorage").Shared.game_data)
    FlightPhysics = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("flight_physics"))
    FlightPhysics.Init()
    
    state.jetSky = jetSky
    state.hull = jetSky:WaitForChild("HullLower")
    state.seat = seat
    state.stats = stats
    state.boostFuel = stats.boostCapacity or 100
    
    -- Setup physics bodies
    self:SetupPhysicsBodies()
    
    -- Initial state
    state.cframe = state.hull.CFrame
    state.velocity = Vector3.zero
    state.angularVelocity = Vector3.zero
    
    -- Input handling
    UserInputService.InputBegan:Connect(function(key, processed)
        if processed then return end
        self:HandleInput(key.KeyCode, true)
    end)
    
    UserInputService.InputEnded:Connect(function(key)
        self:HandleInput(key.KeyCode, false)
    end)
    
    -- Mouse-based pitch/roll control
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Mouse controls pitch and roll when holding right click or in flight
            local mousePos = UserInputService:GetMouseLocation()
            local screenSize = Workspace.CurrentCamera.ViewportSize
            
            -- Normalize mouse position (-1 to 1 from center)
            local mouseX = (mousePos.X - screenSize.X / 2) / (screenSize.X / 2)
            local mouseY = (mousePos.Y - screenSize.Y / 2) / (screenSize.Y / 2)
            
            -- Apply deadzone
            local deadzone = 0.1
            if math.abs(mouseX) < deadzone then mouseX = 0 end
            if math.abs(mouseY) < deadzone then mouseY = 0 end
            
            -- Pitch from mouse Y (inverted: up = nose down in plane terms, but we want up = pitch up)
            state.pitch = -math.clamp(mouseY * 1.5, -1, 1)
            -- Roll from mouse X
            state.roll = math.clamp(mouseX * 1.5, -1, 1)
        end
    end)
    
    print("[FlightController] Initialized with realistic physics")
end

function FlightController:SetupPhysicsBodies()
    -- BodyVelocity for smooth movement
    local bodyVel = state.hull:FindFirstChild("JetSkyVelocity")
    if not bodyVel then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "JetSkyVelocity"
        bodyVel.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVel.Velocity = Vector3.zero
        bodyVel.Parent = state.hull
    end
    state.bodyVelocity = bodyVel
    
    -- BodyGyro for rotation control
    local bodyGyro = state.hull:FindFirstChild("JetSkyGyro")
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "JetSkyGyro"
        bodyGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
        bodyGyro.P = 5000
        bodyGyro.D = 500
        bodyGyro.Parent = state.hull
    end
    state.bodyGyro = bodyGyro
end

function FlightController:HandleInput(keyCode, isPressed)
    if keyCode == Enum.KeyCode.W then input.W = isPressed end
    if keyCode == Enum.KeyCode.S then input.S = isPressed end
    if keyCode == Enum.KeyCode.A then input.A = isPressed end
    if keyCode == Enum.KeyCode.D then input.D = isPressed end
    if keyCode == Enum.KeyCode.Q then input.Q = isPressed end
    if keyCode == Enum.KeyCode.E then input.E = isPressed end
    if keyCode == Enum.KeyCode.Space then input.Space = isPressed end
    if keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.RightControl then
        input.Ctrl = isPressed
    end
    if keyCode == Enum.KeyCode.LeftShift then input.Shift = isPressed end
end

function FlightController:UpdateControls(dt)
    -- Throttle control (W/S) - gradual response like real throttle
    if input.W then
        state.targetThrottle = math.min(state.targetThrottle + dt * 0.5, 1)
    elseif input.S then
        state.targetThrottle = math.max(state.targetThrottle - dt * 0.5, 0)
    end
    
    -- Smooth throttle response
    state.throttle = state.throttle + (state.targetThrottle - state.throttle) * dt * 3
    
    -- Boost
    if input.Shift and state.boostFuel > 0 and state.boostCooldown <= 0 then
        state.isBoosting = true
        state.boostFuel = math.max(0, state.boostFuel - GameData.BOOST_DRAIN_RATE * dt)
    else
        state.isBoosting = false
        state.boostCooldown = math.max(0, state.boostCooldown - dt)
        if state.boostFuel < (state.stats.boostCapacity or 100) then
            state.boostFuel = math.min(state.stats.boostCapacity or 100, state.boostFuel + GameData.BOOST_RECHARGE_RATE * dt)
        end
        if input.Shift and state.boostFuel <= 0 then
            state.boostCooldown = GameData.BOOST_COOLDOWN
        end
    end
    
    -- Yaw (A/D for rudder control - turns nose left/right)
    if input.A then
        state.yaw = math.max(state.yaw - dt * 2, -1)
    elseif input.D then
        state.yaw = math.min(state.yaw + dt * 2, 1)
    else
        state.yaw = state.yaw * 0.9  -- Return to center
    end
    
    -- Manual roll (Q/E) - barrel roll control
    if input.Q then
        state.roll = math.max(state.roll - dt * 3, -1)
    elseif input.E then
        state.roll = math.min(state.roll + dt * 3, 1)
    end
    
    -- Altitude control (Space/Ctrl modifies pitch)
    if input.Space then
        state.pitch = math.min(state.pitch + dt * 2, 1)
    elseif input.Ctrl then
        state.pitch = math.max(state.pitch - dt * 2, -1)
    end
end

function FlightController:CheckWaterStatus()
    local pos = state.hull.Position
    local waterLevel = GameData.WATER_LEVEL
    
    -- Check if in water
    local wasInWater = state.isInWater
    state.isInWater = pos.Y <= waterLevel + 1
    
    -- Calculate submerged depth
    if state.isInWater then
        state.submergedDepth = math.max(0, waterLevel + 2 - pos.Y)
        
        -- Splash effect on entry
        if not wasInWater and state.speed > GameData.SPLASH_THRESHOLD then
            self:CreateSplashEffect(pos)
        end
    else
        state.submergedDepth = 0
    end
end

function FlightController:Update(dt)
    if not state.hull then return end
    
    -- Update controls
    self:UpdateControls(dt)
    
    -- Check water status
    self:CheckWaterStatus()
    
    -- Get current state
    state.cframe = state.hull.CFrame
    state.velocity = state.hull.AssemblyLinearVelocity
    state.altitude = state.hull.Position.Y
    state.speed = state.velocity.Magnitude
    
    -- Build physics controls
    local controls = {
        throttle = state.throttle,
        pitch = state.pitch,
        yaw = state.yaw,
        roll = state.roll,
        isBoosting = state.isBoosting,
        isInWater = state.isInWater
    }
    
    -- Build physics state
    local physicsState = {
        velocity = state.velocity,
        cframe = state.cframe,
        angularVelocity = state.hull.AssemblyAngularVelocity,
        altitude = state.altitude,
        isInWater = state.isInWater,
        submergedDepth = state.submergedDepth
    }
    
    -- Run physics simulation
    local result = FlightPhysics.Update(dt, physicsState, controls)
    
    -- Apply physics results
    if state.bodyVelocity then
        state.bodyVelocity.Velocity = result.velocity
    end
    
    -- Calculate target rotation
    local currentRotation = state.cframe - state.cframe.Position
    local pitchRotation = CFrame.Angles(result.moments.control.Z * dt * 0.5, 0, 0)
    local yawRotation = CFrame.Angles(0, result.moments.control.Y * dt * 0.5, 0)
    local rollRotation = CFrame.Angles(0, 0, result.moments.control.X * dt * 0.5)
    
    local targetRotation = currentRotation * pitchRotation * yawRotation * rollRotation
    
    -- Apply rotation via BodyGyro
    if state.bodyGyro then
        state.bodyGyro.CFrame = CFrame.new(state.hull.Position) * targetRotation
    end
    
    -- Update visual effects
    self:UpdateVisuals()
    
    -- Return current state for HUD
    return {
        speed = state.speed,
        altitude = state.altitude,
        throttle = state.throttle,
        isBoosting = state.isBoosting,
        isInWater = state.isInWater,
        isStalled = result.aerodynamics.isStalled,
        angleOfAttack = result.aerodynamics.angleOfAttack,
        boostFuel = state.boostFuel,
        boostMax = state.stats.boostCapacity or 100
    }
end

function FlightController:UpdateVisuals()
    -- Update thruster glow colors based on state
    local leftGlow = state.jetSky:FindFirstChild("LeftOuterGlow")
    local rightGlow = state.jetSky:FindFirstChild("RightOuterGlow")
    
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
    
    -- Update particle effects
    for _, side in ipairs({"Left", "Right"}) do
        local nozzle = state.jetSky:FindFirstChild(side .. "Nozzle")
        if nozzle then
            local emitter = nozzle:FindFirstChild("ExhaustParticles")
            if not emitter then
                emitter = Instance.new("ParticleEmitter")
                emitter.Name = "ExhaustParticles"
                emitter.Color = ColorSequence.new(color, Color3.fromRGB(100, 100, 100))
                emitter.Size = NumberSequence.new(0.3, 1.5)
                emitter.Lifetime = NumberRange.new(0.2, 0.5)
                emitter.Rate = state.throttle * 80
                emitter.Speed = NumberRange.new(15, 30)
                emitter.Acceleration = Vector3.new(0, -5, 0)
                emitter.SpreadAngle = Vector2.new(8, 8)
                emitter.Parent = nozzle
            else
                emitter.Rate = state.throttle * (state.isBoosting and 150 or 80)
                emitter.Color = ColorSequence.new(color, Color3.fromRGB(100, 100, 100))
            end
        end
    end
end

function FlightController:CreateSplashEffect(position)
    -- Water entry splash
    local splash = Instance.new("Part")
    splash.Anchored = true
    splash.CanCollide = false
    splash.Transparency = 1
    splash.Size = Vector3.new(1, 1, 1)
    splash.Position = Vector3.new(position.X, GameData.WATER_LEVEL, position.Z)
    splash.Parent = Workspace
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    emitter.Size = NumberSequence.new(1, 3)
    emitter.Lifetime = NumberRange.new(0.3, 0.8)
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(10, 25)
    emitter.Acceleration = Vector3.new(0, -20, 0)
    emitter.SpreadAngle = Vector2.new(60, 60)
    emitter.Parent = splash
    emitter:Emit(20)
    
    -- Ripple
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
    
    task.spawn(function()
        for i = 1, 15 do
            ripple.Size = Vector3.new(0.5, 1 + i * 1.5, 1 + i * 1.5)
            ripple.Transparency = 0.5 + i * 0.03
            task.wait(0.05)
        end
        ripple:Destroy()
    end)
    
    task.delay(1, function() splash:Destroy() end)
end

-- Getters
function FlightController:GetVelocity() return state.velocity end
function FlightController:GetAltitude() return state.altitude end
function FlightController:GetSpeed() return state.speed end
function FlightController:GetThrottle() return state.throttle end
function FlightController:IsBoosting() return state.isBoosting end
function FlightController:GetBoostFuel() return state.boostFuel end
function FlightController:GetMaxBoost() return state.stats.boostCapacity or 100 end
function FlightController:IsInWater() return state.isInWater end
function FlightController.IsActive() return state.jetSky ~= nil end

function FlightController:GetState()
    return {
        velocity = state.velocity,
        altitude = state.altitude,
        speed = state.speed,
        throttle = state.throttle,
        pitch = state.pitch,
        roll = state.roll,
        yaw = state.yaw,
        isBoosting = state.isBoosting,
        isInWater = state.isInWater,
        boostFuel = state.boostFuel,
        boostMax = state.stats.boostCapacity or 100
    }
end

return FlightController
