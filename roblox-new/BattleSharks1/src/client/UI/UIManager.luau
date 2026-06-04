-- BattleSharks UI Manager (D1)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local UIManager = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = nil
local uiPanels = {}

function UIManager.Initialize()
	mainUI = Instance.new("ScreenGui")
	mainUI.Name = "BattleSharksUI"
	mainUI.ResetOnSpawn = false
	mainUI.Parent = playerGui
	
	UIManager.CreateHUD()
	UIManager.CreateInventory()
	UIManager.CreateShop()
	UIManager.CreateClassSelect()
	UIManager.CreateAquarium()
	UIManager.CreateMutation()
	UIManager.CreateDailyRewards()
	
	UIManager.SetupInputs()
	UIManager.Show("HUD")
	
	GameUtilities.DebugPrint("UIManager: Initialized")
end

function UIManager.CreateHUD()
	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.Size = UDim2.new(1, 0, 1, 0)
	hud.BackgroundTransparency = 1
	hud.Parent = mainUI
	uiPanels.HUD = hud
	
	-- Health
	local health = Instance.new("Frame")
	health.Size = UDim2.new(0, 200, 0, 20)
	health.Position = UDim2.new(0, 20, 0.9, -20)
	health.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	health.Parent = hud
	
	local healthFill = Instance.new("Frame")
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	healthFill.Parent = health
	
	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.Text = "Health: 100/100"
	healthText.Parent = health
	
	-- Hunger
	local hunger = Instance.new("Frame")
	hunger.Size = UDim2.new(0, 200, 0, 20)
	hunger.Position = UDim2.new(0, 20, 0.9, -45)
	hunger.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	hunger.Parent = hud
	
	local hungerFill = Instance.new("Frame")
	hungerFill.Name = "Fill"
	hungerFill.Size = UDim2.new(1, 0, 1, 0)
	hungerFill.BackgroundColor3 = Color3.new(0.9, 0.6, 0.2)
	hungerFill.Parent = hunger
	
	local hungerText = Instance.new("TextLabel")
	hungerText.Size = UDim2.new(1, 0, 1, 0)
	hungerText.BackgroundTransparency = 1
	hungerText.TextColor3 = Color3.new(1, 1, 1)
	hungerText.Text = "🍖 100/100"
	hungerText.Parent = hunger
	
	-- XP
	local xp = Instance.new("Frame")
	xp.Size = UDim2.new(0, 200, 0, 15)
	xp.Position = UDim2.new(0, 20, 0.9, -65)
	xp.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	xp.Parent = hud
	
	local xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.Size = UDim2.new(0.5, 0, 1, 0)
	xpFill.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
	xpFill.Parent = xp
	
	-- Level/Gold
	local level = Instance.new("TextLabel")
	level.Size = UDim2.new(0, 100, 0, 30)
	level.Position = UDim2.new(0, 20, 0.9, -95)
	level.BackgroundTransparency = 1
	level.TextColor3 = Color3.new(1, 0.8, 0)
	level.Text = "Level 1"
	level.Parent = hud
	
	local gold = Instance.new("TextLabel")
	gold.Size = UDim2.new(0, 150, 0, 30)
	gold.Position = UDim2.new(1, -170, 0, 20)
	gold.BackgroundTransparency = 1
	gold.TextColor3 = Color3.new(1, 0.8, 0)
	gold.Text = "🪙 0"
	gold.Parent = hud
	
	-- Menu buttons
	local buttons = {{"Inventory", "I"}, {"Shop", "B"}, {"Aquarium", "A"}, {"Class", "C"}, {"Mutations", "M"}}
	for i, btn in pairs(buttons) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 90, 0, 30)
		b.Position = UDim2.new(1, -100, 0.5, -80 + i * 35)
		b.BackgroundColor3 = Color3.new(0.2, 0.4, 0.6)
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = btn[1] .. " [" .. btn[2] .. "]"
		b.Parent = hud
		b.MouseButton1Click:Connect(function() UIManager.Show(btn[1]) end)
	end
end

function UIManager.CreatePanel(name, size, titleText)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
	panel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
	panel.Visible = false
	panel.Parent = mainUI
	uiPanels[name] = panel
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	title.Text = titleText
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 20
	title.Parent = panel
	
	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 30, 0, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Parent = panel
	close.MouseButton1Click:Connect(function() UIManager.Hide(name) end)
	
	return panel
end

function UIManager.CreateInventory()
	local panel = UIManager.CreatePanel("Inventory", UDim2.new(0, 400, 0, 300), "📦 Inventory")
	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(1, -20, 1, -60)
	grid.Position = UDim2.new(0, 10, 0, 50)
	grid.BackgroundTransparency = 1
	grid.Parent = panel
end

function UIManager.CreateShop()
	UIManager.CreatePanel("Shop", UDim2.new(0, 500, 0, 400), "🛒 Shop")
end

function UIManager.CreateClassSelect()
	local panel = UIManager.CreatePanel("Class", UDim2.new(0, 450, 0, 300), "⚔️ Select Class")
	local classes = {{"Fighter", "⚔️", Color3.new(0.8, 0.3, 0.3)}, {"Ranger", "🏹", Color3.new(0.3, 0.8, 0.3)}, {"Healer", "💚", Color3.new(0.3, 0.3, 0.8)}}
	
	for i, cls in pairs(classes) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 130, 0, 200)
		card.Position = UDim2.new(0, 10 + (i-1)*145, 0.5, -100)
		card.BackgroundColor3 = cls[3]
		card.Parent = panel
		
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(1, 0, 0, 60)
		icon.Text = cls[2]
		icon.TextSize = 50
		icon.Parent = card
		
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0, 30)
		name.Position = UDim2.new(0, 0, 0, 75)
		name.Text = cls[1]
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Parent = card
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -20, 0, 30)
		btn.Position = UDim2.new(0, 10, 1, -40)
		btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		btn.Text = "Select"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Parent = card
		btn.MouseButton1Click:Connect(function()
			ReplicatedStorage.BattleSharksRemotes.ChangeClass:FireServer(cls[1])
		end)
	end
end

function UIManager.CreateAquarium()
	local panel = UIManager.CreatePanel("Aquarium", UDim2.new(0, 300, 0, 400), "🐠 Aquarium")
	
	local emotion = Instance.new("TextLabel")
	emotion.Size = UDim2.new(1, 0, 0, 30)
	emotion.Position = UDim2.new(0, 0, 0, 50)
	emotion.Text = "😊 Happy"
	emotion.TextColor3 = Color3.new(1, 1, 1)
	emotion.Parent = panel
	
	local actions = {{"Feed", "🍖"}, {"Clean", "🧽"}, {"Decorate", "🎨"}}
	for i, act in pairs(actions) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 80, 0, 40)
		btn.Position = UDim2.new(0, 10 + (i-1)*95, 0, 90)
		btn.BackgroundColor3 = Color3.new(0.2, 0.3, 0.4)
		btn.Text = act[2] .. " " .. act[1]
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Parent = panel
	end
end

function UIManager.CreateMutation()
	UIManager.CreatePanel("Mutations", UDim2.new(0, 250, 0, 350), "🧬 Mutations")
end

function UIManager.CreateDailyRewards()
	local panel = UIManager.CreatePanel("DailyRewards", UDim2.new(0, 350, 0, 200), "📅 Daily Rewards")
	
	local streak = Instance.new("TextLabel")
	streak.Size = UDim2.new(1, 0, 0, 30)
	streak.Position = UDim2.new(0, 0, 0, 50)
	streak.Text = "🔥 Streak: 0 days"
	streak.TextColor3 = Color3.new(1, 0.5, 0)
	streak.Parent = panel
	
	local claim = Instance.new("TextButton")
	claim.Size = UDim2.new(0, 150, 0, 50)
	claim.Position = UDim2.new(0.5, -75, 0.7, -25)
	claim.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
	claim.Text = "Claim Reward"
	claim.TextColor3 = Color3.new(1, 1, 1)
	claim.Parent = panel
	claim.MouseButton1Click:Connect(function()
		ReplicatedStorage.BattleSharksRemotes.ClaimDailyReward:FireServer()
	end)
end

function UIManager.Show(name)
	for n, panel in pairs(uiPanels) do
		panel.Visible = (n == name)
	end
end

function UIManager.Hide(name)
	local panel = uiPanels[name]
	if panel then panel.Visible = false end
	if name ~= "HUD" then uiPanels.HUD.Visible = true end
end

function UIManager.SetupInputs()
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		local keys = {[Enum.KeyCode.I] = "Inventory", [Enum.KeyCode.B] = "Shop", [Enum.KeyCode.A] = "Aquarium", [Enum.KeyCode.C] = "Class", [Enum.KeyCode.M] = "Mutations", [Enum.KeyCode.Escape] = "HUD"}
		if keys[input.KeyCode] then UIManager.Show(keys[input.KeyCode]) end
	end)
end

function UIManager.UpdateStat(stat, value, max)
	local hud = uiPanels.HUD
	if not hud then return end
	
	local bar = hud:FindFirstChild(stat)
	if bar then
		local fill = bar:FindFirstChild("Fill")
		local text = bar:FindFirstChild("TextLabel")
		if fill and max then fill.Size = UDim2.new(value/max, 0, 1, 0) end
		if text then text.Text = stat .. ": " .. math.floor(value) .. "/" .. max end
	end
	
	local label = hud:FindFirstChild(stat .. "Label")
	if label then label.Text = stat .. " " .. value end
end

return UIManager
