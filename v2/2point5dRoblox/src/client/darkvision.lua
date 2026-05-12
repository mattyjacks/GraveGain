local Darkvision = {}
Darkvision.__index = Darkvision

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

function Darkvision.new()
	local self = setmetatable({}, Darkvision)

	self.active = false
	self.colorShift = 0
	self.cachedParts = {}
	self.updateCounter = 0
	self.character = nil
	self.hrp = nil

	return self
end

function Darkvision:activate(character)
	self.active = true
	self.character = character
	self.hrp = character:FindFirstChild("HumanoidRootPart")
	self:cacheWorldParts()
	print("Darkvision activated")
end

function Darkvision:deactivate()
	self.active = false
	self.colorShift = 0
	self.cachedParts = {}
	print("Darkvision deactivated")
end

function Darkvision:cacheWorldParts()
	self.cachedParts = {}
	local dungeon = workspace:FindFirstChild("Dungeon")
	if dungeon then
		for _, part in ipairs(dungeon:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(self.cachedParts, part)
			end
		end
	end
end

function Darkvision:update(dt)
	if not self.active or not self.character or not self.hrp then return end

	local brightness = Lighting.Brightness
	local targetColorShift = math.max(0, (0.5 - brightness) / 0.5)
	targetColorShift = math.min(1, targetColorShift)

	self.colorShift = self.colorShift + (targetColorShift - self.colorShift) * dt * 3

	self.updateCounter = self.updateCounter + 1
	if self.updateCounter % 3 == 0 then
		self:applyDarkvisionEffect(self.colorShift)
	end
end

function Darkvision:applyDarkvisionEffect(colorShift)
	if colorShift < 0.05 then return end

	local camPos = workspace.CurrentCamera.CFrame.Position

	for _, part in ipairs(self.cachedParts) do
		if part and part.Parent then
			local dist = (part.Position - camPos).Magnitude
			if dist < 80 then
				local originalColor = part.Color
				local bw = (originalColor.R + originalColor.G + originalColor.B) / 3
				local desaturated = Color3.fromRGB(bw * 255, bw * 255, bw * 255)
				part.Color = originalColor:Lerp(desaturated, colorShift * 0.6)
			end
		end
	end
end

return Darkvision
