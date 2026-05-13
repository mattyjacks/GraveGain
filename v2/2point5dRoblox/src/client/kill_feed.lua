-- kill_feed.lua (CLIENT)
-- Floating damage numbers above enemies, XP gain popups, kill notifications.

local KillFeed = {}

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Main GUI container
local gui = Instance.new("ScreenGui")
gui.Name = "KillFeedGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Kill notification feed (top right)
local feedFrame = Instance.new("Frame")
feedFrame.Size = UDim2.new(0, 280, 0, 200)
feedFrame.Position = UDim2.new(1, -290, 0, 80)
feedFrame.BackgroundTransparency = 1
feedFrame.Parent = gui

local feedLayout = Instance.new("UIListLayout")
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Padding = UDim.new(0, 4)
feedLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
feedLayout.FillDirection = Enum.FillDirection.Vertical
feedLayout.Parent = feedFrame

-- ── Floating Damage Numbers ───────────────────────────────────────────────

local camera = workspace.CurrentCamera

function KillFeed.showDamageNumber(worldPos, amount, isCrit)
	local screenPos, onScreen = camera:WorldToScreenPoint(worldPos + Vector3.new(0, 3, 0))
	if not onScreen or screenPos.Z < 0 then return end

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 80, 0, 30)
	lbl.Position = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 15)
	lbl.BackgroundTransparency = 1
	lbl.ZIndex = 15

	if isCrit then
		lbl.Text = "⚡ " .. math.ceil(amount) .. "!"
		lbl.TextColor3 = Color3.fromRGB(255, 220, 0)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 24
	else
		lbl.Text = tostring(math.ceil(amount))
		lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 18
	end

	lbl.Parent = gui

	-- Float upward and fade out
	local targetPos = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 60)
	TweenService:Create(lbl, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos,
		TextTransparency = 1,
	}):Play()

	game:GetService("Debris"):AddItem(lbl, 1)
end

-- ── XP Popup ─────────────────────────────────────────────────────────────

function KillFeed.showXPGain(amount)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 200, 0, 32)
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.Position = UDim2.new(0.5, 0, 0.75, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "+" .. amount .. " XP"
	lbl.TextColor3 = Color3.fromRGB(230, 210, 60)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 20
	lbl.ZIndex = 15
	lbl.Parent = gui

	TweenService:Create(lbl, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.65, 0),
		TextTransparency = 1,
	}):Play()

	game:GetService("Debris"):AddItem(lbl, 1.3)
end

-- ── Level Up Banner ───────────────────────────────────────────────────────

function KillFeed.showLevelUp(level)
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0, 400, 0, 60)
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0.4, 0)
	banner.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	banner.BackgroundTransparency = 0.2
	banner.BorderSizePixel = 0
	banner.ZIndex = 20
	banner.Parent = gui
	Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(230, 200, 50)
	stroke.Thickness = 2
	stroke.Parent = banner

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⭐  LEVEL UP! — LEVEL " .. level
	lbl.TextColor3 = Color3.fromRGB(255, 230, 80)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 26
	lbl.ZIndex = 21
	lbl.Parent = banner

	-- Animate in, hold, animate out
	banner.Position = UDim2.new(0.5, 0, 0.3, 0)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.4, 0)
	}):Play()

	task.delay(2.5, function()
		TweenService:Create(banner, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
		TweenService:Create(lbl, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
		game:GetService("Debris"):AddItem(banner, 0.7)
	end)
end

-- ── Kill Notification ─────────────────────────────────────────────────────

function KillFeed.showKill(enemyName, isBoss)
	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, 0, 0, 32)
	entry.BackgroundColor3 = isBoss and Color3.fromRGB(80, 20, 20) or Color3.fromRGB(20, 20, 35)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0
	entry.ZIndex = 15
	Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -8, 1, 0)
	lbl.Position = UDim2.new(0, 4, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = (isBoss and "👑 BOSS SLAIN: " or "💀 ") .. enemyName
	lbl.TextColor3 = isBoss and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(200, 200, 220)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Right
	lbl.ZIndex = 16
	lbl.Parent = entry

	entry.Parent = feedFrame
	entry.Size = UDim2.new(1, 0, 0, 32)

	-- Fade out after 4 seconds
	task.delay(3.5, function()
		TweenService:Create(entry, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		TweenService:Create(lbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		game:GetService("Debris"):AddItem(entry, 0.6)
	end)
end

return KillFeed
