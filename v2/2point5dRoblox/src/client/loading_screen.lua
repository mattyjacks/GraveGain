-- loading_screen.lua (CLIENT)
-- Premium loading screen with code-drawn spinner and rotating tips.
-- Fully recreatable — safe to call show() multiple times.

local LoadingScreen = {}

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

-- Rotating tips shown while loading
local TIPS = {
	"💀  Enemies drop better loot at higher difficulties",
	"🏹  Elves regenerate mana while standing still",
	"🛡  Blocking reduces incoming damage by 60%",
	"⚔  Power attacks deal 2.5x damage but cost stamina",
	"🧪  Potions heal over time, not instantly",
	"🔦  Press F to toggle your race ability in the dungeon",
	"🗺  Watch the minimap — enemies are marked in red",
	"💣  Cook grenades for 2-3s for maximum damage",
	"🌿  Dwarves have the best Darkvision in dark areas",
	"🪓  Orcs enter Rage mode after taking 40% HP damage",
}

local screenGui   = nil
local frame       = nil
local titleLabel  = nil
local subtitleLabel = nil
local statusLabel = nil
local tipLabel    = nil
local spinnerFrame = nil
local progressBar  = nil
local progressFill = nil
local spinnerConn  = nil
local tipConn      = nil

local function destroyUI()
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
		frame = nil; titleLabel = nil; statusLabel = nil
		tipLabel = nil; spinnerFrame = nil; progressBar = nil; progressFill = nil
		subtitleLabel = nil
	end
	if spinnerConn then spinnerConn:Disconnect(); spinnerConn = nil end
	if tipConn     then task.cancel(tipConn);     tipConn = nil end
end

local function createUI()
	destroyUI() -- Always fresh

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 200 -- above everything
	screenGui.Parent = playerGui

	-- Dark backdrop
	frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
	frame.BorderSizePixel = 0
	frame.ZIndex = 1
	frame.Parent = screenGui

	-- Gradient overlay (subtle diagonal)
	local uigradient = Instance.new("UIGradient")
	uigradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 15, 35)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 8, 12)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 8, 25)),
	})
	uigradient.Rotation = 135
	uigradient.Parent = frame

	-- Central glow blob (pure Frame, no asset needed)
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(0, 500, 0, 300)
	glow.Position = UDim2.new(0.5, -250, 0.5, -150)
	glow.BackgroundColor3 = Color3.fromRGB(30, 60, 180)
	glow.BackgroundTransparency = 0.85
	glow.BorderSizePixel = 0
	glow.ZIndex = 2
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
	glow.Parent = frame

	-- Title: GRAVEGAIN
	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 90)
	titleLabel.Position = UDim2.new(0, 0, 0.35, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "GRAVEGAIN"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 72
	titleLabel.ZIndex = 5
	titleLabel.Parent = frame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(100, 140, 255)
	titleStroke.Thickness = 2
	titleStroke.Parent = titleLabel

	-- Subtitle
	subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(1, 0, 0, 24)
	subtitleLabel.Position = UDim2.new(0, 0, 0.35, 90)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "TOP-DOWN DUNGEON ADVENTURE"
	subtitleLabel.TextColor3 = Color3.fromRGB(100, 120, 180)
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextSize = 14
	subtitleLabel.ZIndex = 5
	subtitleLabel.Parent = frame

	-- CanvasGroup for the spinner to allow GroupTransparency fading
	spinnerFrame = Instance.new("CanvasGroup")
	spinnerFrame.Size = UDim2.new(0, 54, 0, 54)
	spinnerFrame.Position = UDim2.new(0.5, -27, 0.72, 0)
	spinnerFrame.BackgroundTransparency = 1
	spinnerFrame.ZIndex = 5
	spinnerFrame.Parent = frame

	-- Arc segments (8 dots around a circle)
	local numDots = 8
	for i = 1, numDots do
		local dot = Instance.new("Frame")
		local angle = (i / numDots) * math.pi * 2
		local r = 22
		dot.Size = UDim2.new(0, 7, 0, 7)
		dot.Position = UDim2.new(0.5, math.cos(angle) * r - 3.5, 0.5, math.sin(angle) * r - 3.5)
		dot.BackgroundColor3 = Color3.fromHSV(0.6, 0.8, i / numDots)
		dot.BackgroundTransparency = 1 - (i / numDots) * 0.8
		dot.BorderSizePixel = 0
		dot.ZIndex = 5
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		dot.Name = "Dot" .. i
		dot.Parent = spinnerFrame
	end

	-- Animate spinner rotation
	spinnerConn = RunService.RenderStepped:Connect(function(dt)
		if spinnerFrame and spinnerFrame.Parent then
			spinnerFrame.Rotation = spinnerFrame.Rotation + dt * 180
		end
	end)

	-- Status text
	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.6, 0, 0, 24)
	statusLabel.Position = UDim2.new(0.2, 0, 0.72, 64)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "INITIALIZING SYSTEMS..."
	statusLabel.TextColor3 = Color3.fromRGB(140, 150, 190)
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextSize = 14
	statusLabel.ZIndex = 5
	statusLabel.Parent = frame

	-- Progress bar
	progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0.5, 0, 0, 3)
	progressBar.Position = UDim2.new(0.25, 0, 0.72, 100)
	progressBar.BackgroundColor3 = Color3.fromRGB(30, 35, 60)
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 5
	progressBar.Parent = frame
	Instance.new("UICorner", progressBar).CornerRadius = UDim.new(1, 0)

	progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 6
	progressFill.Parent = progressBar
	Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

	local pfGrad = Instance.new("UIGradient")
	pfGrad.Color = ColorSequence.new(Color3.fromRGB(80, 120, 255), Color3.fromRGB(180, 100, 255))
	pfGrad.Parent = progressFill

	-- Tip label
	tipLabel = Instance.new("TextLabel")
	tipLabel.Size = UDim2.new(0.7, 0, 0, 30)
	tipLabel.Position = UDim2.new(0.15, 0, 0.88, 0)
	tipLabel.BackgroundTransparency = 1
	tipLabel.Text = TIPS[1]
	tipLabel.TextColor3 = Color3.fromRGB(100, 110, 140)
	tipLabel.Font = Enum.Font.GothamMedium
	tipLabel.TextSize = 14
	tipLabel.TextWrapped = true
	tipLabel.ZIndex = 5
	tipLabel.Parent = frame

	-- Tip rotation
	local tipIndex = 1
	tipConn = task.spawn(function()
		while screenGui and screenGui.Parent do
			task.wait(3)
			if tipLabel and tipLabel.Parent then
				tipIndex = tipIndex % #TIPS + 1
				TweenService:Create(tipLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
				task.wait(0.4)
				tipLabel.Text = TIPS[tipIndex]
				TweenService:Create(tipLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
			end
		end
	end)

	-- Animate progress bar (fake progress for effect)
	task.spawn(function()
		local prog = 0
		while screenGui and screenGui.Parent and prog < 0.95 do
			task.wait(0.05)
			prog = prog + math.random(1, 4) / 100
			prog = math.min(prog, 0.95)
			if progressFill and progressFill.Parent then
				TweenService:Create(progressFill, TweenInfo.new(0.15), {Size = UDim2.new(prog, 0, 1, 0)}):Play()
			end
		end
	end)
end

function LoadingScreen.show(message)
	createUI()
	if statusLabel then
		statusLabel.Text = string.upper(message or "LOADING...")
	end
	screenGui.Enabled = true
end

function LoadingScreen.hide(duration)
	if not screenGui then return end
	duration = duration or 1

	-- Complete progress bar
	if progressFill then
		TweenService:Create(progressFill, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0)}):Play()
	end

	task.wait(0.3)

	local info = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	if frame then TweenService:Create(frame, info, {BackgroundTransparency = 1}):Play() end
	if titleLabel then TweenService:Create(titleLabel, info, {TextTransparency = 1}):Play() end
	if subtitleLabel then TweenService:Create(subtitleLabel, info, {TextTransparency = 1}):Play() end
	if statusLabel then TweenService:Create(statusLabel, info, {TextTransparency = 1}):Play() end
	if tipLabel then TweenService:Create(tipLabel, info, {TextTransparency = 1}):Play() end
	if spinnerFrame then TweenService:Create(spinnerFrame, info, {GroupTransparency = 1}):Play() end

	task.delay(duration + 0.3, function()
		destroyUI()
	end)
end

function LoadingScreen.updateStatus(message)
	if statusLabel then
		statusLabel.Text = string.upper(message or "")
	end
end

return LoadingScreen
