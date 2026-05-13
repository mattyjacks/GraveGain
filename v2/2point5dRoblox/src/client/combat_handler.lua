local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatHandler = {}
CombatHandler.__index = CombatHandler

function CombatHandler.new(inputHandler)
	local self = setmetatable({}, CombatHandler)
	self.inputHandler = inputHandler
	self.effectPool = {}
	self.camera = workspace.CurrentCamera
	self.enemyVelocities = {} -- [enemy] = {pos = Vector3, vel = Vector3}
	return self
end

function CombatHandler:getMouseTarget()
	local mouse = Players.LocalPlayer:GetMouse()
	local ray = self.camera:ViewportPointToRay(mouse.X, mouse.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
	
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
	if result then
		return result.Position
	else
		return ray.Origin + ray.Direction * 100
	end
end

function CombatHandler:performMeleeAttack()
	if self.inputHandler.pushAttackCooldown > 0 then return end
	self.inputHandler.pushAttackCooldown = 0.5
	
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local targetPos = self:getMouseTarget()
	local origin = hrp.Position
	local direction = (targetPos - origin).Unit
	local range = 10
	local damage = 25
	
	self:applyPushToEnemies(origin, direction, range, 20, damage)
	self:createPushEffect(origin, direction, range, false)
end

function CombatHandler:update(dt)
	local enemyFolder = workspace:FindFirstChild("Enemies")
	if not enemyFolder then return end
	
	for _, enemy in ipairs(enemyFolder:GetChildren()) do
		local hrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
		if hrp then
			local data = self.enemyVelocities[enemy]
			if not data then
				self.enemyVelocities[enemy] = {pos = hrp.Position, vel = Vector3.new()}
			else
				local newVel = (hrp.Position - data.pos) / dt
				-- Smooth velocity slightly
				data.vel = data.vel:Lerp(newVel, 0.2)
				data.pos = hrp.Position
			end
		end
	end
	
	-- Clean up old entries
	for enemy, _ in pairs(self.enemyVelocities) do
		if not enemy.Parent then
			self.enemyVelocities[enemy] = nil
		end
	end
end

function CombatHandler:performRangedAttack(chargeTime)
	self.inputHandler.ammo = self.inputHandler.ammo - 1
	
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local targetPos = self:getMouseTarget()
	local origin = hrp.Position + Vector3.new(0, 1.5, 0) -- shoulder height
	
	-- Predictive Auto-Aim logic
	local mouse = player:GetMouse()
	local bestEnemy = nil
	local minScreenDist = 60 -- Max distance in pixels to trigger snap
	
	local enemyFolder = workspace:FindFirstChild("Enemies")
	if enemyFolder then
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
			if ehrp then
				local screenPos, onScreen = self.camera:WorldToViewportPoint(ehrp.Position)
				if onScreen then
					local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < minScreenDist then
						minScreenDist = dist
						bestEnemy = enemy
					end
				end
			end
		end
	end
	
	local chargeMultiplier = 1 + (chargeTime / 3)
	local arrowSpeed = 120 * chargeMultiplier
	
	if bestEnemy then
		local ehrp = bestEnemy:FindFirstChild("HumanoidRootPart") or bestEnemy:FindFirstChild("Root")
		local eData = self.enemyVelocities[bestEnemy]
		if ehrp and eData then
			local ep = ehrp.Position
			local ev = eData.vel
			
			-- Solve for time t: |ep + ev*t - origin| = arrowSpeed * t
			local dist = (ep - origin).Magnitude
			local timeToHit = dist / arrowSpeed -- simplified first-order prediction
			
			-- Adjust for relative motion
			targetPos = ep + ev * timeToHit
			print("Auto-aim snapped to", bestEnemy.Name, "with lead:", (targetPos - ep).Magnitude)
		end
	end

	local direction = (targetPos - origin).Unit
	
	local damage = 15 * chargeMultiplier
	
	local arrow = Instance.new("Part")
	arrow.Name = "ArrowProjectile"
	arrow.Size = Vector3.new(0.2, 0.2, 2)
	arrow.Color = Color3.fromRGB(150, 100, 50)
	arrow.Material = Enum.Material.Wood
	arrow.CanCollide = false
	arrow.CFrame = CFrame.lookAt(origin, targetPos)
	
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = direction * arrowSpeed
	bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
	bv.Parent = arrow
	
	arrow.Parent = workspace
	game:GetService("Debris"):AddItem(arrow, 3)
	
	arrow.Touched:Connect(function(hit)
		if hit.Parent and hit.Parent.Name ~= character.Name then
			local enemyHumanoid = hit.Parent:FindFirstChild("Humanoid")
			if enemyHumanoid then
				ReplicatedStorage.EnemyDamaged:FireServer(hit.Parent, damage)
			end
			
			-- STICK ARROW LOGIC
			arrow.Anchored = true
			if bv then bv:Destroy() end
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hit
			weld.Part1 = arrow
			weld.Parent = arrow
			
			-- Move slightly into the surface
			arrow.CFrame = arrow.CFrame * CFrame.new(0, 0, 0.5)
			
			game:GetService("Debris"):AddItem(arrow, 10) -- Sticky arrows last 10s
		end
	end)
end

function CombatHandler:applyPushToEnemies(origin, direction, range, force, damage)
	local enemyFolder = workspace:FindFirstChild("Enemies")
	if not enemyFolder then return end

	local rangeSq = range * range

	for _, enemy in ipairs(enemyFolder:GetChildren()) do
		local enemyHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
		if enemyHRP then
			local toEnemy = enemyHRP.Position - origin
			local distSq = toEnemy.X * toEnemy.X + toEnemy.Y * toEnemy.Y + toEnemy.Z * toEnemy.Z

			if distSq < rangeSq then
				local dist = math.sqrt(distSq)
				local dot = (toEnemy.X * direction.X + toEnemy.Y * direction.Y + toEnemy.Z * direction.Z) / dist

				if dot > 0.5 then
					local pushVec = direction * force + Vector3.new(0, force * 0.3, 0)
					local bv = enemyHRP:FindFirstChild("BodyVelocity")
					if not bv then
						bv = Instance.new("BodyVelocity")
						bv.MaxForce = Vector3.new(10000, 10000, 10000)
						bv.Parent = enemyHRP
					end
					bv.Velocity = pushVec
					game:GetService("Debris"):AddItem(bv, 0.25)

					local enemyHumanoid = enemy:FindFirstChild("Humanoid")
					if enemyHumanoid then
						ReplicatedStorage.EnemyDamaged:FireServer(enemy, damage)
					end
				end
			end
		end
	end
end

function CombatHandler:createPushEffect(origin, direction, range, isCharged)
	local effect
	if #self.effectPool > 0 then
		effect = table.remove(self.effectPool)
		effect.Parent = workspace
	else
		effect = Instance.new("Part")
		effect.Shape = Enum.PartType.Block
		effect.Anchored = true
		effect.CanCollide = false
	end

	if isCharged then
		effect.Size = Vector3.new(4, 3, range)
		effect.Color = Color3.fromRGB(255, 100, 0)
		effect.Material = Enum.Material.Neon
		effect.Transparency = 0.3
	else
		effect.Size = Vector3.new(3, 2, range * 0.6)
		effect.Color = Color3.fromRGB(100, 200, 255)
		effect.Material = Enum.Material.Neon
		effect.Transparency = 0.5
	end

	effect.CFrame = CFrame.lookAt(origin + direction * range * 0.3, origin + direction * range)

	local debris = game:GetService("Debris")
	debris:AddItem(effect, 0.15)
end

return CombatHandler
