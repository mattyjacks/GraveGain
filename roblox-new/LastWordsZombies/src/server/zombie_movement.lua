-- Zombie movement: slow shamble toward camera with raycast obstacle steering

local RunService = game:GetService("RunService")

local ZombieMovement = {}

local GOAL_Z         = 12    -- trigger game over when zombie passes this Z
local BOB_SPEED      = 4     -- shamble bob frequency
local BOB_AMOUNT     = 0.06
local STEER_DISTANCE = 6     -- how far ahead to probe for obstacles
local STEER_ANGLE    = 45    -- degrees left/right probe
local CORRIDOR_HW    = 22    -- half-width limit so zombies don't escape
local SPAWN_Z         = -150  -- Z at spawn (far)
local BILLBOARD_MIN   = 60    -- pixels wide when far
local BILLBOARD_MAX   = 320   -- pixels wide when close
local BILLBOARD_H_MIN = 18
local BILLBOARD_H_MAX = 90

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

		-- Scale billboard: small when far, large when close. Use t^1.5 curve for dramatic close-up growth.
		local t = math.clamp((newPos.Z - SPAWN_Z) / (GOAL_Z - SPAWN_Z), 0, 1)
		local curve = t ^ 1.5
		local bw = BILLBOARD_MIN + (BILLBOARD_MAX - BILLBOARD_MIN) * curve
		local bh = BILLBOARD_H_MIN + (BILLBOARD_H_MAX - BILLBOARD_H_MIN) * curve
		local head = model:FindFirstChild("Head")
		if head then
			local bb = head:FindFirstChild("WordDisplay")
			if bb then bb.Size = UDim2.new(0, bw, 0, bh) end
		end
	end)

	zombieData.MovementConnection = connection
end

return ZombieMovement
