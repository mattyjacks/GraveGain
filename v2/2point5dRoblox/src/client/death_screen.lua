-- death_screen.lua (CLIENT)
-- Shows a stylized death/respawn screen when the player dies.
-- Also shows a victory screen when a mission is completed.

local DeathScreen = {}

local TweenService   = game:GetService("TweenService")
local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player         = Players.LocalPlayer
local playerGui      = player:WaitForChild("PlayerGui")

-- ── Death Screen ─────────────────────────────────────────────────────────────

function DeathScreen.showDeath(stats)
	local existing = playerGui:FindFirstChild("DeathGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "DeathGui"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 150
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- Dark red vignette overlay
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Parent = gui
	TweenService:Create(bg, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.4}):Play()

	-- Central panel
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 440, 0, 320)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(10, 5, 5)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.ZIndex = 5
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(150, 20, 20)
	stroke.Thickness = 2
	panel.Parent = bg

	-- Animate in
	panel.Position = UDim2.new(0.5, 0, 0.6, 0)
	TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	local function makeLabel(text, y, size, col)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -20, 0, 36)
		l.Position = UDim2.new(0, 10, 0, y)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = col or Color3.fromRGB(220, 220, 230)
		l.Font = Enum.Font.GothamBold
		l.TextSize = size or 16
		l.ZIndex = 6
		l.Parent = panel
		return l
	end

	makeLabel("YOU DIED", 16, 48, Color3.fromRGB(220, 40, 40))
	makeLabel("─────────────────────", 68, 12, Color3.fromRGB(80, 30, 30))

	local kills  = (stats and stats.kills)  or 0
	local xp     = (stats and stats.xp)     or 0
	local damage = (stats and stats.damage) or 0
	local gold   = (stats and stats.gold)   or 0

	makeLabel("⚔  Kills: " .. kills, 90,  16)
	makeLabel("💎 Gold:  " .. gold,  122, 16)
	makeLabel("✨ XP:    " .. xp,    154, 16)
	makeLabel("🗡 Damage Dealt: " .. math.ceil(damage), 186, 14, Color3.fromRGB(180, 160, 160))

	-- Respawn button
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.7, 0, 0, 44)
	btn.Position = UDim2.new(0.15, 0, 0, 258)
	btn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
	btn.BorderSizePixel = 0
	btn.Text = "RESPAWN"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.ZIndex = 6
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.Parent = panel

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 30, 30)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 20, 20)}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		gui:Destroy()
		-- Fire respawn event to server
		local respawnEvent = ReplicatedStorage:FindFirstChild("RespawnPlayer")
		if respawnEvent then
			respawnEvent:FireServer()
		else
			player:LoadCharacter()
		end
	end)
end

-- ── Victory Screen ────────────────────────────────────────────────────────────

function DeathScreen.showVictory(stats, loot)
	local existing = playerGui:FindFirstChild("VictoryGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "VictoryGui"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 150
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- Gold/green vignette
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 40, 10)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Parent = gui
	TweenService:Create(bg, TweenInfo.new(1), {BackgroundTransparency = 0.4}):Play()

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 460, 0, 360)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(8, 14, 6)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.ZIndex = 5
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(180, 160, 30)
	stroke.Thickness = 2
	panel.Parent = bg

	panel.Position = UDim2.new(0.5, 0, 0.4, 0)
	TweenService:Create(panel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	local function makeLabel(text, y, size, col)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -20, 0, 36)
		l.Position = UDim2.new(0, 10, 0, y)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = col or Color3.fromRGB(220, 230, 200)
		l.Font = Enum.Font.GothamBold
		l.TextSize = size or 16
		l.ZIndex = 6
		l.Parent = panel
		return l
	end

	makeLabel("⭐  MISSION COMPLETE!", 14, 36, Color3.fromRGB(255, 220, 60))
	makeLabel("──────────────────────────", 58, 12, Color3.fromRGB(80, 80, 20))

	local kills  = (stats and stats.kills)  or 0
	local xp     = (stats and stats.xp)     or 0
	local damage = (stats and stats.damage) or 0
	local gold   = (stats and stats.gold)   or 0

	makeLabel("⚔  Enemies Slain: " .. kills,  82,  16)
	makeLabel("💎 Gold Collected: " .. gold,   114, 16)
	makeLabel("✨ XP Earned:      " .. xp,     146, 16)
	makeLabel("🗡 Total Damage:  " .. math.ceil(damage), 178, 14, Color3.fromRGB(180, 200, 160))

	-- Loot section
	if loot and #loot > 0 then
		makeLabel("📦 LOOT FOUND:", 210, 14, Color3.fromRGB(200, 170, 80))
		local lootText = ""
		for i, item in ipairs(loot) do
			if i <= 4 then lootText = lootText .. "• " .. item .. "  " end
		end
		local ll = makeLabel(lootText, 236, 13, Color3.fromRGB(200, 200, 160))
		ll.TextWrapped = true
	end

	-- Return to lobby button
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.7, 0, 0, 44)
	btn.Position = UDim2.new(0.15, 0, 0, 300)
	btn.BackgroundColor3 = Color3.fromRGB(40, 100, 20)
	btn.BorderSizePixel = 0
	btn.Text = "RETURN TO LOBBY"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.ZIndex = 6
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.Parent = panel

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 140, 30)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 100, 20)}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		gui:Destroy()
		local respawnEvent = ReplicatedStorage:FindFirstChild("RespawnPlayer")
		if respawnEvent then
			respawnEvent:FireServer()
		else
			player:LoadCharacter()
		end
	end)
end

-- ── Event Wiring ──────────────────────────────────────────────────────────────

function DeathScreen.setup()
	-- Listen for player death
	local humanoidDiedConn
	local function watchCharacter(char)
		if humanoidDiedConn then humanoidDiedConn:Disconnect() end
		local humanoid = char:WaitForChild("Humanoid")
		humanoidDiedConn = humanoid.Died:Connect(function()
			task.wait(1.5) -- Brief pause before showing screen
			DeathScreen.showDeath({
				kills  = 0, -- will be wired up via RemoteEvent later
				xp     = 0,
				damage = 0,
				gold   = 0,
			})
		end)
	end

	watchCharacter(player.Character or player.CharacterAdded:Wait())
	player.CharacterAdded:Connect(watchCharacter)

	-- Listen for MissionComplete event
	local missionComplete = ReplicatedStorage:FindFirstChild("MissionComplete")
	if missionComplete then
		missionComplete.OnClientEvent:Connect(function(stats, loot)
			DeathScreen.showVictory(stats, loot)
		end)
	end
end

return DeathScreen
