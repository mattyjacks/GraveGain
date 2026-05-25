-- Zombie movement: slow shamble toward camera with raycast obstacle steering

local RunService = game:GetService("RunService")

local ZombieMovement = {}

local GOAL_Z         = 12    -- trigger game over when zombie passes this Z
local BOB_SPEED      = 4     -- shamble bob frequency
local BOB_AMOUNT     = 0.06
local STEER_DISTANCE = 6     -- how far ahead to probe for obstacles
local STEER_ANGLE    = 45    -- degrees left/right probe
local CORRIDOR_HW    = 22    -- half-width limit so zombies don't escape

-- Cast a ray from origin in direction*dist; returns true if something hit
local function Probe(origin, dir, dist)
	return workspace:Raycast(origin, dir * dist, RaycastParams.new()) ~= nil
end

-- Probe left or right side (angleDeg from +Z axis)
local function ProbeSide(origin, angleDeg, dist)
	local rad = math.rad(angleDeg)
	local dir = Vector3.new(math.sin(rad), 0, math.cos(rad))
	return Probe(origin, dir, dist)
end

function ZombieMovement.Start(zombieData, onReachedCamera)
	local connection
	local steerBias = 0 -- negative = drift left, positive = drift right

	connection = RunService.Heartbeat:Connect(function(dt)
		if not zombieData.IsAlive then
			connection:Disconnect()
			return
		end
		local model = zombieData.Model
		if not model or not model.Parent or not model.PrimaryPart then
			connection:Disconnect()
			return
		end

		local pos = model.PrimaryPart.Position

		if pos.Z >= GOAL_Z then
			connection:Disconnect()
			onReachedCamera()
			return
		end

		-- Probe ahead and to the sides
		local probeOrigin  = Vector3.new(pos.X, 3, pos.Z)
		local blockedFront = Probe(probeOrigin, Vector3.new(0,0,1), STEER_DISTANCE)
		local blockedRight = ProbeSide(probeOrigin,  STEER_ANGLE, STEER_DISTANCE * 0.7)
		local blockedLeft  = ProbeSide(probeOrigin, -STEER_ANGLE, STEER_DISTANCE * 0.7)

		if blockedFront then
			if not blockedRight and steerBias >= 0 then
				steerBias = 1
			elseif not blockedLeft then
				steerBias = -1
			else
				steerBias = (math.random() < 0.5) and 1 or -1
			end
		else
			steerBias = steerBias * 0.88 -- decay back to straight
		end

		local xDrift = steerBias * zombieData.Speed * 0.6 * dt
		local zStep  = zombieData.Speed * dt
		local bob    = math.sin(tick() * BOB_SPEED) * BOB_AMOUNT

		local newX   = math.clamp(pos.X + xDrift, -CORRIDOR_HW, CORRIDOR_HW)
		local newPos = Vector3.new(newX, 3 + bob, pos.Z + zStep)

		model:SetPrimaryPartCFrame(CFrame.new(newPos, newPos + Vector3.new(0, 0, 1)))
	end)

	zombieData.MovementConnection = connection
end

return ZombieMovement
