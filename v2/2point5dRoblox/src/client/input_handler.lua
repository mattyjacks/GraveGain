local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new(combatSystem)
	local self = setmetatable({}, InputHandler)

	self.isBlocking = false
	self.isAttacking = false
	self.attackHoldTime = 0
	self.pushCooldown = 0
	self.pushAttackCooldown = 0
	self.isEnabled = false
	self.pushAttackCooldown = 0
	self.blockShield = nil
	self.character = nil
	self.hrp = nil
	self.effectPool = {}
	self.shieldCreated = false
	self.combatSystem = combatSystem

	self:setupInputs()

	return self
end

function InputHandler:setupInputs()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self.isEnabled then return end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:startBlock()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.isBlocking then
				self:startPushAttack()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if not self.isEnabled then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:stopBlock()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.isAttacking then
				self:releasePushAttack()
			end
		end
	end)
end

function InputHandler:update(dt)
	if self.pushCooldown > 0 then
		self.pushCooldown = self.pushCooldown - dt
	end
	if self.pushAttackCooldown > 0 then
		self.pushAttackCooldown = self.pushAttackCooldown - dt
	end

	if self.isAttacking then
		self.attackHoldTime = self.attackHoldTime + dt
	end

	self:updateShieldVisual()
end

function InputHandler:startBlock()
	if self.isBlocking or self.shieldCreated then return end
	self.isBlocking = true
	self.shieldCreated = true

	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if not self.blockShield then
		local shield = Instance.new("Part")
		shield.Name = "BlockShield"
		shield.Shape = Enum.PartType.Block
		shield.Size = Vector3.new(3, 4, 0.4)
		shield.Color = Color3.fromRGB(80, 150, 255)
		shield.Material = Enum.Material.ForceField
		shield.Transparency = 0.4
		shield.CanCollide = false
		shield.Anchored = false
		shield.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = shield
		weld.Parent = shield

		shield.CFrame = hrp.CFrame * CFrame.new(0, 0, -2.5)
		shield.Parent = character
		self.blockShield = shield
	end
end

function InputHandler:stopBlock()
	self.isBlocking = false
	self.shieldCreated = false

	if self.blockShield then
		self.blockShield:Destroy()
		self.blockShield = nil
	end
end

function InputHandler:startPushAttack()
	if self.pushCooldown > 0 then return end
	self.isAttacking = true
	self.attackHoldTime = 0
end

function InputHandler:releasePushAttack()
	if not self.isAttacking then return end
	self.isAttacking = false

	if self.combatSystem then
		local isPowerAttack = self.attackHoldTime >= 0.3
		self.combatSystem:performPush(isPowerAttack)
	end

	self.attackHoldTime = 0
end

function InputHandler:createPushEffect(origin, direction, range, isCharged)
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

function InputHandler:applyPushToEnemies(origin, direction, range, force, damage)
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
						enemyHumanoid:TakeDamage(damage)
					end
				end
			end
		end
	end
end

function InputHandler:updateShieldVisual()
	if not self.blockShield then return end
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	self.blockShield.CFrame = hrp.CFrame * CFrame.new(0, 0, -2.5)
end

return InputHandler
