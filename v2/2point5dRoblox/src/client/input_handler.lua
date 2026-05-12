local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatHandler = require(script.Parent:WaitForChild("combat_handler"))
local ItemHandler = require(script.Parent:WaitForChild("item_handler"))

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new(combatSystem)
	local self = setmetatable({}, InputHandler)

	self.isBlocking = false
	self.isAttacking = false
	self.attackHoldTime = 0
	self.pushCooldown = 0
	self.isEnabled = false
	self.weaponMode = "Melee"
	self.animationController = nil
	self.ammo = 20
	self.maxAmmo = 30
	self.bowChargeStart = 0
	self.isDrawingBow = false
	self.blockShield = nil
	self.character = nil
	self.rightHand = nil
	self.isCookingGrenade = false
	self.grenadeCookStart = 0
	self.combatSystem = combatSystem
	self.inventoryUI = nil

	self.combatHandler = CombatHandler.new(self)
	self.itemHandler = ItemHandler.new(self)

	self:setupInputs()

	local restoreAmmoEvent = ReplicatedStorage:WaitForChild("RestoreAmmo")
	restoreAmmoEvent.OnClientEvent:Connect(function()
		local amount = math.floor(self.maxAmmo * (0.25 + math.random() * 0.75))
		self.ammo = math.min(self.maxAmmo, self.ammo + amount)
		print("Restored Ammo! Current:", self.ammo, "/", self.maxAmmo)
	end)

	return self
end

-- Equip a weapon mode: hide all, show the active one, re-weld it to the hand
function InputHandler:setWeaponMode(mode)
	if not self.isEnabled then return end
	self.weaponMode = mode
	if self.animationController then self.animationController:setBowDraw(false) end

	if not self.inventoryUI or not self.character or not self.rightHand then return end

	local slotMap = {Melee = "Primary", Ranged = "Secondary", Potion = "Consumable", Grenade = "Throwable"}

	-- Unparent all equipped models
	for _, slotName in pairs(slotMap) do
		local item = self.inventoryUI.equips[slotName]
		if item and item.model then
			item.model.Parent = nil
		end
	end

	-- Parent and weld the active one
	local activeSlot = slotMap[mode]
	if activeSlot then
		local item = self.inventoryUI.equips[activeSlot]
		if item and item.model then
			item.model.Parent = self.character
			local primaryPart = item.model.PrimaryPart
			if primaryPart then
				-- Unanchor all parts so WeldConstraints work
				for _, p in ipairs(item.model:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = false
						p.CanCollide = false
						p.Massless = true
					end
				end
				primaryPart.CFrame = self.rightHand.CFrame * (item.offset or CFrame.new())
				-- Remove old welds to right hand from this model
				for _, w in ipairs(primaryPart:GetChildren()) do
					if w:IsA("WeldConstraint") then w:Destroy() end
				end
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = self.rightHand
				weld.Part1 = primaryPart
				weld.Parent = primaryPart
			end
		end
	end

	print("Equipped", mode)
end

function InputHandler:setupInputs()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self.isEnabled then return end

		if input.KeyCode == Enum.KeyCode.One then
			self:setWeaponMode("Melee")
		elseif input.KeyCode == Enum.KeyCode.Two then
			self:setWeaponMode("Ranged")
		elseif input.KeyCode == Enum.KeyCode.Three then
			self:setWeaponMode("Potion")
		elseif input.KeyCode == Enum.KeyCode.Four then
			self:setWeaponMode("Grenade")
		end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if self.weaponMode == "Melee" and not self.isBlocking then
				self.isBlocking = true
				if self.animationController then self.animationController:setBlocking(true) end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.weaponMode == "Melee" then
				self.isAttacking = true
				self.attackHoldTime = 0
				if self.animationController then self.animationController:playSwing() end
				self.combatHandler:performMeleeAttack()
			elseif self.weaponMode == "Ranged" then
				if self.ammo > 0 then
					self.isDrawingBow = true
					self.bowChargeStart = tick()
					if self.animationController then self.animationController:setBowDraw(true) end
				else
					print("Out of ammo!")
				end
			elseif self.weaponMode == "Potion" then
				self.itemHandler:consumeBuffItem()
				self:setWeaponMode("Melee")
			elseif self.weaponMode == "Grenade" then
				self.isCookingGrenade = true
				self.grenadeCookStart = tick()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if not self.isEnabled then return end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.isBlocking = false
			if self.animationController then self.animationController:setBlocking(false) end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.weaponMode == "Melee" then
				self.isAttacking = false
				self.attackHoldTime = 0
			elseif self.weaponMode == "Ranged" and self.isDrawingBow then
				self.isDrawingBow = false
				local chargeTime = math.min(5, tick() - self.bowChargeStart)
				if self.animationController then
					self.animationController:setBowDraw(false)
					self.animationController:playBowFire()
				end
				self.combatHandler:performRangedAttack(chargeTime)
			elseif self.weaponMode == "Grenade" and self.isCookingGrenade then
				self.isCookingGrenade = false
				local cookTime = tick() - self.grenadeCookStart
				if cookTime < 4 then
					local equipData = self.inventoryUI and self.inventoryUI.equips["Throwable"]
					self.itemHandler:throwGrenade(cookTime, 4 - cookTime, equipData)
				end
				-- Switch back to melee after throwing
				self:setWeaponMode("Melee")
			end
		end
	end)
end

function InputHandler:update(dt)
	if self.pushCooldown > 0 then
		self.pushCooldown = self.pushCooldown - dt
	end

	if self.isAttacking then
		self.attackHoldTime = self.attackHoldTime + dt
	end

	if self.isCookingGrenade then
		local cookTime = tick() - self.grenadeCookStart
		if cookTime >= 4 then
			self.isCookingGrenade = false
			print("Grenade exploded in hand!")
			local equipData = self.inventoryUI and self.inventoryUI.equips["Throwable"]
			self.itemHandler:throwGrenade(0, 0, equipData)
			self:setWeaponMode("Melee")
		end
	end

	if not self.blockShield then return end
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	self.blockShield.CFrame = hrp.CFrame * CFrame.new(0, 0, -2.5)
end

return InputHandler
