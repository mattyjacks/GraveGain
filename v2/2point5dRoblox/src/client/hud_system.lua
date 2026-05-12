local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HUDSystem = {}
HUDSystem.__index = HUDSystem

function HUDSystem.new(characterSystem)
	local self = setmetatable({}, HUDSystem)
	
	self.characterSystem = characterSystem
	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")
	
	self:createHUD()
	
	return self
end

function HUDSystem:createHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = self.playerGui
	
	self.screenGui = screenGui
	
	self:createHealthBar(screenGui)
	self:createManaBar(screenGui)
	self:createAbilityBar(screenGui)
	self:createMinimap(screenGui)
	self:createXPBar(screenGui)
	self:createBuffDebuffPanel(screenGui)
	
	RunService.RenderStepped:Connect(function()
		self:updateHUD()
	end)
end

function HUDSystem:createHealthBar(parent)
	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthBar"
	healthFrame.Size = UDim2.new(0, 200, 0, 30)
	healthFrame.Position = UDim2.new(0, 10, 1, -50)
	healthFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	healthFrame.BorderSizePixel = 2
	healthFrame.BorderColor3 = Color3.fromRGB(200, 0, 0)
	healthFrame.Parent = parent
	
	local healthFill = Instance.new("Frame")
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthFrame
	
	local healthText = Instance.new("TextLabel")
	healthText.Name = "Text"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.TextScaled = true
	healthText.Font = Enum.Font.GothamBold
	healthText.Parent = healthFrame
	
	self.healthBar = healthFrame
	self.healthFill = healthFill
	self.healthText = healthText
end

function HUDSystem:createManaBar(parent)
	local manaFrame = Instance.new("Frame")
	manaFrame.Name = "ManaBar"
	manaFrame.Size = UDim2.new(0, 200, 0, 30)
	manaFrame.Position = UDim2.new(0, 10, 1, -90)
	manaFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	manaFrame.BorderSizePixel = 2
	manaFrame.BorderColor3 = Color3.fromRGB(0, 100, 200)
	manaFrame.Parent = parent
	
	local manaFill = Instance.new("Frame")
	manaFill.Name = "Fill"
	manaFill.Size = UDim2.new(1, 0, 1, 0)
	manaFill.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	manaFill.BorderSizePixel = 0
	manaFill.Parent = manaFrame
	
	local manaText = Instance.new("TextLabel")
	manaText.Name = "Text"
	manaText.Size = UDim2.new(1, 0, 1, 0)
	manaText.BackgroundTransparency = 1
	manaText.TextColor3 = Color3.fromRGB(255, 255, 255)
	manaText.TextScaled = true
	manaText.Font = Enum.Font.GothamBold
	manaText.Parent = manaFrame
	
	self.manaBar = manaFrame
	self.manaFill = manaFill
	self.manaText = manaText
end

function HUDSystem:createAbilityBar(parent)
	local abilityFrame = Instance.new("Frame")
	abilityFrame.Name = "AbilityBar"
	abilityFrame.Size = UDim2.new(0, 400, 0, 60)
	abilityFrame.Position = UDim2.new(0.5, -200, 1, -70)
	abilityFrame.BackgroundTransparency = 0.5
	abilityFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	abilityFrame.BorderSizePixel = 0
	abilityFrame.Parent = parent
	
	self.abilityBar = abilityFrame
	
	for i = 1, 4 do
		local abilityButton = Instance.new("TextButton")
		abilityButton.Name = "Ability" .. i
		abilityButton.Size = UDim2.new(0, 80, 0, 50)
		abilityButton.Position = UDim2.new(0, (i - 1) * 90 + 10, 0, 5)
		abilityButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		abilityButton.BorderSizePixel = 2
		abilityButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
		abilityButton.Text = i
		abilityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		abilityButton.Font = Enum.Font.GothamBold
		abilityButton.Parent = abilityFrame
	end
end

function HUDSystem:createMinimap(parent)
	local minimapFrame = Instance.new("Frame")
	minimapFrame.Name = "Minimap"
	minimapFrame.Size = UDim2.new(0, 150, 0, 150)
	minimapFrame.Position = UDim2.new(1, -160, 0, 10)
	minimapFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	minimapFrame.BorderSizePixel = 2
	minimapFrame.BorderColor3 = Color3.fromRGB(100, 200, 100)
	minimapFrame.Parent = parent
	
	self.minimap = minimapFrame
end

function HUDSystem:createXPBar(parent)
	local xpFrame = Instance.new("Frame")
	xpFrame.Name = "XPBar"
	xpFrame.Size = UDim2.new(0, 300, 0, 15)
	xpFrame.Position = UDim2.new(0.5, -150, 1, -20)
	xpFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	xpFrame.BorderSizePixel = 1
	xpFrame.BorderColor3 = Color3.fromRGB(200, 200, 0)
	xpFrame.Parent = parent
	
	local xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.Size = UDim2.new(0.5, 0, 1, 0)
	xpFill.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpFrame
	
	self.xpBar = xpFrame
	self.xpFill = xpFill
end

function HUDSystem:createBuffDebuffPanel(parent)
	local buffFrame = Instance.new("Frame")
	buffFrame.Name = "BuffDebuffPanel"
	buffFrame.Size = UDim2.new(0, 200, 0, 40)
	buffFrame.Position = UDim2.new(0, 10, 0, 50)
	buffFrame.BackgroundTransparency = 1
	buffFrame.Parent = parent
	
	self.buffPanel = buffFrame
end

function HUDSystem:updateHUD()
	local stats = self.characterSystem:getStats()
	
	local healthPercent = stats.health / stats.maxHealth
	self.healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
	self.healthText.Text = math.floor(stats.health) .. " / " .. stats.maxHealth
	
	local manaPercent = stats.mana / stats.maxMana
	self.manaFill.Size = UDim2.new(manaPercent, 0, 1, 0)
	self.manaText.Text = math.floor(stats.mana) .. " / " .. stats.maxMana
	
	local xpPercent = stats.experience / (100 * stats.level)
	self.xpFill.Size = UDim2.new(math.min(1, xpPercent), 0, 1, 0)
end

return HUDSystem
