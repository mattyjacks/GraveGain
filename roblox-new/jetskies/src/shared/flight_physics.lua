local FlightPhysics = {}
local GameData

-- Realistic flight constants
FlightPhysics.Constants = {
    -- Aerodynamics
    LIFT_COEFFICIENT = 0.8,           -- Wing efficiency
    DRAG_COEFFICIENT = 0.02,          -- Air resistance
    INDUCED_DRAG_FACTOR = 0.05,       -- Drag from lift
    STALL_ANGLE = math.rad(15),       -- Critical angle of attack
    MAX_LIFT_ANGLE = math.rad(20),    -- Maximum effective angle
    
    -- Physics
    AIR_DENSITY = 1.225,              -- kg/m^3 at sea level
    GRAVITY = 196.2,                  -- Roblox gravity ( studs/s^2)
    MASS = 500,                       -- JetSky mass in kg equivalent
    
    -- Thrust
    MAX_THRUST = 15000,               -- Maximum engine thrust
    THRUST_RESPONSE = 0.3,            -- Throttle response time
    IDLE_THRUST = 500,                -- Idle thrust
    
    -- Control surfaces
    ELEVATOR_EFFECTIVENESS = 2.5,     -- Pitch control
    RUDDER_EFFECTIVENESS = 1.8,       -- Yaw control
    AILERON_EFFECTIVENESS = 2.0,      -- Roll control
    
    -- Stability
    PITCH_STABILITY = 0.15,           -- Natural pitch damping
    YAW_STABILITY = 0.1,              -- Natural yaw damping
    ROLL_STABILITY = 0.2,             -- Natural roll damping
    
    -- Ground effect
    GROUND_EFFECT_HEIGHT = 10,        -- Height where ground effect starts
    GROUND_EFFECT_MAX = 0.3,          -- Max lift increase from ground effect
    
    -- Water physics
    WATER_DENSITY = 1000,             -- kg/m^3
    HYDRODYNAMIC_DRAG = 0.5,          -- Drag in water
    BUOYANCY_VOLUME = 2.5,            -- Displacement volume
    PLANING_SPEED = 30,               -- Speed where planing starts
}

function FlightPhysics.Init()
    GameData = require(script.Parent:WaitForChild("game_data"))
end

-- Calculate lift force based on velocity and angle of attack
function FlightPhysics.CalculateLift(velocity, angleOfAttack, altitude)
    local speed = velocity.Magnitude
    if speed < 1 then return Vector3.zero end
    
    local const = FlightPhysics.Constants
    
    -- Stall check
    local effectiveAngle = math.clamp(angleOfAttack, -const.MAX_LIFT_ANGLE, const.MAX_LIFT_ANGLE)
    if math.abs(angleOfAttack) > const.STALL_ANGLE then
        -- Stall condition - loss of lift
        effectiveAngle = effectiveAngle * 0.3
    end
    
    -- Lift coefficient varies with angle of attack
    local liftCoeff = const.LIFT_COEFFICIENT * math.sin(effectiveAngle * 2)
    
    -- Calculate lift magnitude
    local liftMag = 0.5 * const.AIR_DENSITY * speed * speed * liftCoeff
    
    -- Lift direction is perpendicular to velocity, upward relative to aircraft
    local liftDir = Vector3.new(0, 1, 0)  -- Simplified, should be relative to aircraft orientation
    
    -- Ground effect (increased lift near ground/water)
    if altitude < const.GROUND_EFFECT_HEIGHT then
        local groundFactor = 1 + const.GROUND_EFFECT_MAX * (1 - altitude / const.GROUND_EFFECT_HEIGHT)
        liftMag = liftMag * groundFactor
    end
    
    return liftDir * liftMag
end

-- Calculate drag force
function FlightPhysics.CalculateDrag(velocity, angleOfAttack)
    local speed = velocity.Magnitude
    if speed < 0.1 then return Vector3.zero end
    
    local const = FlightPhysics.Constants
    
    -- Parasitic drag
    local paraDrag = 0.5 * const.AIR_DENSITY * speed * speed * const.DRAG_COEFFICIENT
    
    -- Induced drag (drag from generating lift)
    local inducedDrag = const.INDUCED_DRAG_FACTOR * math.sin(angleOfAttack) ^ 2 * speed * speed
    
    -- Total drag
    local totalDrag = paraDrag + inducedDrag
    
    -- Drag opposes velocity
    local dragDir = -velocity.Unit
    
    return dragDir * totalDrag
end

-- Calculate thrust force
function FlightPhysics.CalculateThrust(throttle, speed, isBoosting, isInWater)
    local const = FlightPhysics.Constants
    
    -- Base thrust from throttle (0-1)
    local targetThrust = const.IDLE_THRUST + (const.MAX_THRUST - const.IDLE_THRUST) * throttle
    
    -- Boost multiplier
    if isBoosting then
        targetThrust = targetThrust * GameData.BOOST_MULTIPLIER
    end
    
    -- Water thrust (jet pumps work better in water initially)
    if isInWater then
        if speed < const.PLANING_SPEED then
            -- Better thrust at low speeds in water (jet pump efficiency)
            targetThrust = targetThrust * 1.5
        else
            -- Normal thrust once planing
            targetThrust = targetThrust * 1.2
        end
    end
    
    -- Thrust decreases with speed (momentum drag)
    local speedFactor = math.max(0.3, 1 - (speed / 200))
    
    return targetThrust * speedFactor
end

-- Calculate control moments (torques)
function FlightPhysics.CalculateControlMoments(pitchInput, yawInput, rollInput, speed)
    local const = FlightPhysics.Constants
    local speedFactor = math.clamp(speed / 50, 0.2, 1.5)
    
    -- Control effectiveness increases with speed (aerodynamic surfaces)
    local pitchMoment = pitchInput * const.ELEVATOR_EFFECTIVENESS * speedFactor
    local yawMoment = yawInput * const.RUDDER_EFFECTIVENESS * speedFactor
    local rollMoment = rollInput * const.AILERON_EFFECTIVENESS * speedFactor
    
    return Vector3.new(rollMoment, yawMoment, pitchMoment)
end

-- Calculate stability moments (natural restoring forces)
function FlightPhysics.CalculateStabilityMoments(angularVelocity, cframe)
    local const = FlightPhysics.Constants
    
    -- Damping moments oppose angular velocity
    local pitchDamp = -angularVelocity.Z * const.PITCH_STABILITY * 1000
    local yawDamp = -angularVelocity.Y * const.YAW_STABILITY * 1000
    local rollDamp = -angularVelocity.X * const.ROLL_STABILITY * 1000
    
    -- Leveling moment (wants to fly upright)
    local upVector = cframe.UpVector
    local rightVector = cframe.RightVector
    local targetUp = Vector3.new(0, 1, 0)
    
    local rollLevel = -rightVector:Dot(targetUp) * const.ROLL_STABILITY * 500
    local pitchLevel = (upVector.Y - 1) * const.PITCH_STABILITY * 200
    
    return Vector3.new(
        rollDamp + rollLevel,
        yawDamp,
        pitchDamp + pitchLevel
    )
end

-- Calculate buoyancy when in water
function FlightPhysics.CalculateBuoyancy(submergedDepth)
    if submergedDepth <= 0 then return Vector3.zero end
    
    local const = FlightPhysics.Constants
    
    -- Buoyancy force = weight of displaced water
    local displacedVolume = math.min(submergedDepth / 3, const.BUOYANCY_VOLUME)
    local buoyancyForce = displacedVolume * const.WATER_DENSITY * const.GRAVITY / 10
    
    -- Add damping when in water
    return Vector3.new(0, buoyancyForce, 0)
end

-- Calculate hydrodynamic drag in water
function FlightPhysics.CalculateWaterDrag(velocity, submergedDepth)
    if submergedDepth <= 0 then return Vector3.zero end
    
    local speed = velocity.Magnitude
    if speed < 0.1 then return Vector3.zero end
    
    local const = FlightPhysics.Constants
    
    -- Water drag is much higher than air drag
    local dragMag = 0.5 * const.WATER_DENSITY * speed * speed * const.HYDRODYNAMIC_DRAG
    
    -- Less drag when planing (skimming surface)
    if submergedDepth < 1 and speed > const.PLANING_SPEED then
        dragMag = dragMag * 0.3  -- Significantly reduced drag when planing
    end
    
    return -velocity.Unit * dragMag
end

-- Main physics update function
function FlightPhysics.Update(dt, state, controls)
    local const = FlightPhysics.Constants
    
    -- Current state
    local velocity = state.velocity
    local cframe = state.cframe
    local angularVelocity = state.angularVelocity or Vector3.zero
    local altitude = state.altitude
    local isInWater = state.isInWater or false
    local submergedDepth = state.submergedDepth or 0
    
    -- Decompose velocity into airspeed and direction
    local airspeed = velocity.Magnitude
    local forwardVector = cframe.LookVector
    local upVector = cframe.UpVector
    local rightVector = cframe.RightVector
    
    -- Calculate angle of attack (pitch relative to velocity)
    local velocityDir = velocity.Unit
    local angleOfAttack = math.asin(math.clamp(upVector:Dot(velocityDir), -1, 1))
    
    -- === FORCES ===
    local totalForce = Vector3.zero
    
    -- 1. Thrust
    local thrustMag = FlightPhysics.CalculateThrust(
        controls.throttle, 
        airspeed, 
        controls.isBoosting, 
        isInWater
    )
    local thrust = forwardVector * thrustMag
    totalForce = totalForce + thrust
    
    -- 2. Lift (only in air or when planing)
    if not isInWater or (isInWater and airspeed > const.PLANING_SPEED) then
        local lift = FlightPhysics.CalculateLift(velocity, angleOfAttack, altitude)
        totalForce = totalForce + lift
    end
    
    -- 3. Drag (air or water)
    local drag
    if isInWater and submergedDepth > 0.5 then
        drag = FlightPhysics.CalculateWaterDrag(velocity, submergedDepth)
    else
        drag = FlightPhysics.CalculateDrag(velocity, angleOfAttack)
    end
    totalForce = totalForce + drag
    
    -- 4. Gravity
    local gravity = Vector3.new(0, -const.GRAVITY * const.MASS / 100, 0)
    totalForce = totalForce + gravity
    
    -- 5. Buoyancy (when in water)
    if isInWater then
        local buoyancy = FlightPhysics.CalculateBuoyancy(submergedDepth)
        totalForce = totalForce + buoyancy
    end
    
    -- === MOMENTS (ROTATION) ===
    local totalMoment = Vector3.zero
    
    -- 1. Control inputs
    local controlMoments = FlightPhysics.CalculateControlMoments(
        controls.pitch,
        controls.yaw,
        controls.roll,
        airspeed
    )
    totalMoment = totalMoment + controlMoments
    
    -- 2. Stability
    local stabilityMoments = FlightPhysics.CalculateStabilityMoments(angularVelocity, cframe)
    totalMoment = totalMoment + stabilityMoments
    
    -- === INTEGRATION ===
    -- Acceleration = F / m
    local acceleration = totalForce / (const.MASS / 10)
    
    -- Update velocity (with damping)
    local newVelocity = velocity + acceleration * dt
    newVelocity = newVelocity * 0.995  -- Small damping for numerical stability
    
    -- Update angular velocity
    local angularAccel = totalMoment / (const.MASS * 0.5)  -- Approximate moment of inertia
    local newAngularVelocity = angularVelocity + angularAccel * dt
    newAngularVelocity = newAngularVelocity * 0.95  -- Angular damping
    
    -- Return updated physics state
    return {
        velocity = newVelocity,
        acceleration = acceleration,
        angularVelocity = newAngularVelocity,
        forces = {
            thrust = thrust,
            lift = (isInWater and submergedDepth > 0.5) and Vector3.zero or FlightPhysics.CalculateLift(velocity, angleOfAttack, altitude),
            drag = drag,
            gravity = gravity,
            buoyancy = (isInWater and submergedDepth > 0) and FlightPhysics.CalculateBuoyancy(submergedDepth) or Vector3.zero
        },
        moments = {
            control = controlMoments,
            stability = stabilityMoments
        },
        aerodynamics = {
            airspeed = airspeed,
            angleOfAttack = angleOfAttack,
            isStalled = math.abs(angleOfAttack) > const.STALL_ANGLE
        }
    }
end

-- Utility: Calculate glide ratio (distance traveled vs altitude lost)
function FlightPhysics.CalculateGlideRatio(angleOfAttack)
    local const = FlightPhysics.Constants
    local lift = const.LIFT_COEFFICIENT * math.sin(math.clamp(angleOfAttack, 0.01, const.MAX_LIFT_ANGLE) * 2)
    local drag = const.DRAG_COEFFICIENT + const.INDUCED_DRAG_FACTOR * math.sin(angleOfAttack) ^ 2
    return lift / drag
end

-- Utility: Calculate stall speed
function FlightPhysics.CalculateStallSpeed()
    local const = FlightPhysics.Constants
    -- V_stall = sqrt(2 * W / (rho * S * CL_max))
    local weight = const.MASS * const.GRAVITY / 10
    local wingArea = 10  -- Approximate
    local clMax = const.LIFT_COEFFICIENT * math.sin(const.MAX_LIFT_ANGLE * 2)
    return math.sqrt(2 * weight / (const.AIR_DENSITY * wingArea * clMax))
end

-- Utility: Calculate best glide speed
function FlightPhysics.CalculateBestGlideSpeed()
    -- Typically slightly above stall speed
    return FlightPhysics.CalculateStallSpeed() * 1.3
end

return FlightPhysics
