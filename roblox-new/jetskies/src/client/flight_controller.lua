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
    stats = nil
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
    
    -- Calculate input vectors
    local moveForward = input.W and 1 or (input.S and -1 or 0)
    local turnRight = input.D and 1 or (input.A and -1 or 0)
    local ascend = input.Space and 1 or (input.Ctrl and -1 or 0)
    
    -- Base speed with upgrade multiplier
    local baseSpeed = state.stats.speed or GameData.BASE_SPEED
    local speed = baseSpeed
    
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
        
        self:UpdateThrusterVisuals(false)
        
        -- Trigger cooldown if depleted
        if input.Shift and state.boostFuel <= 0 then
            state.boostCooldown = GameData.BOOST_COOLDOWN
        end
    end
    
    -- Calculate forces
    local forward = currentCFrame.LookVector
    local right = currentCFrame.RightVector
    local up = currentCFrame.UpVector
    
    -- Forward thrust
    local thrust = forward * moveForward * speed
    
    -- Vertical movement
    local vertical = Vector3.new(0, ascend * GameData.ALTITUDE_SPEED, 0)
    
    -- Turn torque
    local handling = state.stats.handling or GameData.TURN_SPEED
    local turnAmount = turnRight * handling * dt * 60
    
    -- Apply tilt for visual feedback
    state.tiltZ = moveForward * GameData.TILT_ANGLE
    state.tiltX = -turnRight * GameData.TILT_ANGLE * 0.5
    
    -- Smooth tilt
    local targetTilt = CFrame.Angles(math.rad(state.tiltZ), 0, math.rad(state.tiltX))
    hull.CFrame = currentCFrame * CFrame.Angles(0, math.rad(-turnAmount), 0) * targetTilt
    
    -- Apply velocity with momentum decay
    local targetVelocity = thrust + vertical
    state.velocity = currentVelocity:Lerp(targetVelocity, 0.1)
    
    -- Altitude ceiling check
    local pos = hull.Position
    if pos.Y > GameData.MAX_ALTITUDE then
        state.velocity = Vector3.new(state.velocity.X, -10, state.velocity.Z)
    end
    
    -- Apply velocity
    hull.AssemblyLinearVelocity = state.velocity
    hull.AssemblyAngularVelocity = Vector3.new(0, turnAmount * 2, 0)
    
    -- Update stats
    state.altitude = pos.Y
    state.speed = state.velocity.Magnitude
end

function FlightController:UpdateThrusterVisuals(isBoosting)
    if not state.thrusterLeft or not state.thrusterRight then return end
    
    local color = isBoosting and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(0, 200, 255)
    
    -- Update glow parts
    local leftGlow = state.thrusterLeft:FindFirstChild("LeftGlow")
    local rightGlow = state.thrusterRight:FindFirstChild("RightGlow")
    
    if leftGlow then leftGlow.Color = color end
    if rightGlow then rightGlow.Color = color end
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
