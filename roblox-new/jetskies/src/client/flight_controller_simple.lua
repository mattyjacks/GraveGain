local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local FlightController = {}
local GameData

-- Mouse sensitivity for flight steering
local MOUSE_PITCH_SENSITIVITY = 0.003
local MOUSE_YAW_SENSITIVITY   = 0.003
local MOUSE_SMOOTHING          = 0.25   -- how fast mouse input decays

-- Accumulated mouse-driven pitch/yaw targets (-1 to 1)
local mousePitch = 0
local mouseYaw   = 0

-- State
local state = {
    jetSky = nil,
    hull = nil,
    seat = nil,
    
    -- Physics
    velocity = Vector3.zero,
    rotation = CFrame.new(),
    
    -- Controls
    throttle = 0.3,   -- start with some throttle so it doesn't stall
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
    bodyGyro = nil
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
    
    -- Lock mouse for flight steering
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    -- Keyboard input
    UserInputService.InputBegan:Connect(function(key, processed)
        if processed then return end
        self:HandleInput(key.KeyCode, true)
    end)
    
    UserInputService.InputEnded:Connect(function(key)
        self:HandleInput(key.KeyCode, false)
    end)
    
    -- Mouse scroll = throttle adjustment
    UserInputService.InputChanged:Connect(function(inp, processed)
        if processed then return end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            state.throttle = math.clamp(state.throttle + inp.Position.Z * 0.05, 0, 1)
        end
    end)
    
    -- Set initial rotation
    state.rotation = state.hull.CFrame - state.hull.CFrame.Position
    
    print("[FlightController] Simple controller initialized")
end

function FlightController:SetupPhysics()
    -- Remove old physics bodies
    for _, name in ipairs({"JetSkyVelocity", "JetSkyGyro", "JetSkyAngularVel"}) do
        local old = state.hull:FindFirstChild(name)
        if old then old:Destroy() end
    end
    
    -- BodyVelocity for movement (large MaxForce Y to fully fight gravity)
    state.bodyVelocity = Instance.new("BodyVelocity")
    state.bodyVelocity.Name = "JetSkyVelocity"
    state.bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    state.bodyVelocity.Velocity = Vector3.zero
    state.bodyVelocity.Parent = state.hull
    
    -- BodyGyro to hold orientation (no drift/tumbling)
    state.bodyGyro = Instance.new("BodyGyro")
    state.bodyGyro.Name = "JetSkyGyro"
    state.bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    state.bodyGyro.P = 3000
    state.bodyGyro.D = 200
    state.bodyGyro.CFrame = state.hull.CFrame
    state.bodyGyro.Parent = state.hull
    
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
    
    -- === MOUSE STEERING ===
    local mouseDelta = UserInputService:GetMouseDelta()
    
    -- Mouse Y -> pitch (invert so mouse up = nose up)
    mousePitch = mousePitch - mouseDelta.Y * MOUSE_PITCH_SENSITIVITY
    -- Mouse X -> yaw
    mouseYaw = mouseYaw - mouseDelta.X * MOUSE_YAW_SENSITIVITY
    
    -- Clamp and smooth decay
    mousePitch = math.clamp(mousePitch, -1, 1)
    mouseYaw   = math.clamp(mouseYaw,   -1, 1)
    
    -- === ROTATION CONTROLS ===
    -- Pitch: mouse Y + keyboard Space/Ctrl
    local keyPitch = (input.Space and 1 or 0) + (input.Ctrl and -1 or 0)
    state.pitch = mousePitch + keyPitch * 0.5
    state.pitch = math.clamp(state.pitch, -1, 1)
    
    -- Decay mouse pitch/yaw toward zero when no mouse movement
    mousePitch = mousePitch * (1 - MOUSE_SMOOTHING)
    mouseYaw   = mouseYaw   * (1 - MOUSE_SMOOTHING)
    
    -- Yaw: mouse X + keyboard A/D
    local keyYaw = (input.D and 1 or 0) + (input.A and -1 or 0)
    state.yaw = mouseYaw + keyYaw * 0.5
    state.yaw = math.clamp(state.yaw, -1, 1)
    
    -- Bank (roll) follows yaw for feel
    local targetRoll = -state.yaw * 0.4
    state.roll = state.roll + (targetRoll - state.roll) * dt * 4
    
    -- === CALCULATE FORCES ===
    local forward = currentCFrame.LookVector
    local up = currentCFrame.UpVector
    local right = currentCFrame.RightVector
    
    -- Base speed
    local baseSpeed = (state.stats and state.stats.speed or 50)
    local speedMult = state.isBoosting and 2 or 1
    if state.isInWater then speedMult = speedMult * 1.5 end
    local maxSpeed = baseSpeed * speedMult
    
    -- Thrust: forward component
    local thrust = forward * state.throttle * maxSpeed
    
    -- Vertical control: pitch moves the nose, creating actual climb/dive
    -- Also add a direct vertical component for responsive feel
    local verticalInput = state.pitch * maxSpeed * 0.6
    
    -- Buoyancy in water
    local buoyancy = Vector3.zero
    if state.isInWater then
        local depth = math.max(0, waterLevel + 2 - currentPos.Y)
        buoyancy = Vector3.new(0, 60 + depth * 8, 0)
    end
    
    -- Target velocity: forward thrust + vertical control (fights gravity via BodyVelocity MaxForce)
    -- BodyVelocity with large MaxForce fully counteracts gravity
    local targetVel = thrust + Vector3.new(0, verticalInput, 0) + buoyancy
    
    -- Smooth velocity transition (faster lerp for responsive control)
    local newVel = currentVel:Lerp(targetVel, math.min(dt * 5, 1))
    
    -- Mild drag
    local drag = state.isInWater and 0.96 or 0.99
    newVel = newVel * drag
    
    -- Apply velocity
    if state.bodyVelocity then
        state.bodyVelocity.Velocity = newVel
    end
    
    -- === ROTATION via BodyGyro ===
    -- Build target CFrame by rotating current orientation by pitch/yaw/roll
    if state.bodyGyro then
        -- Rotate the gyro target CFrame based on pitch/yaw inputs
        local pitchDelta = CFrame.Angles(-state.pitch * dt * 2.5, 0, 0)
        local yawDelta   = CFrame.Angles(0, -state.yaw * dt * 2.5, 0)
        local rollDelta  = CFrame.Angles(0, 0, state.roll * dt * 1.5)
        
        -- Apply rotation deltas to current gyro CFrame
        local gyroRot = state.bodyGyro.CFrame - state.bodyGyro.CFrame.Position
        gyroRot = gyroRot * pitchDelta * yawDelta * rollDelta
        
        -- Auto-level roll when no yaw input
        if math.abs(state.yaw) < 0.05 then
            local rx, ry, rz = gyroRot:ToEulerAnglesXYZ()
            gyroRot = CFrame.Angles(rx, ry, rz * 0.95)
        end
        
        -- When in water, auto-level pitch too
        if state.isInWater then
            local rx, ry, rz = gyroRot:ToEulerAnglesXYZ()
            gyroRot = CFrame.Angles(rx * 0.85, ry, rz * 0.85)
        end
        
        state.bodyGyro.CFrame = CFrame.new(currentPos) * gyroRot
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

-- Unlock mouse when paused/destroyed
function FlightController:Cleanup()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return FlightController
