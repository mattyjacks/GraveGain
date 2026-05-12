-- hud_system.lua  -- Complete, self-contained HUD wired to PlayerStats and InputHandler
-- Shows: HP bar, Shield bar, XP bar, weapon hotkeys (1-4) with active highlight,
--        ammo counter, grenade cook timer, mission objective banner,
--        and a flash when the player takes damage.

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HUD = {}
HUD.__index = HUD

local function makeFrame(parent, props)
	local f = Instance.new("Frame")
	for k, v in pairs(props) do f[k] = v end
	f.Parent = parent
	return f
end
local function makeLabel(parent, props)
	local l = Instance.new("TextLabel")
	for k, v in pairs(props) do l[k] = v end
	l.Parent = parent
	return l
end
local function makeCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = parent
end

function HUD.new(playerStats, inputHandler)
	local self = setmetatable({}, HUD)
	self.stats        = playerStats   -- PlayerStats object
	self.input        = inputHandler  -- InputHandler object
	self.missionText  = ""
	self.cookStart    = 0

	local gui = Instance.new("ScreenGui")
	gui.Name          = "GameHUD"
	gui.ResetOnSpawn  = false
	gui.IgnoreGuiInset = true
	gui.Parent        = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.gui          = gui

	self:buildBars()
	self:buildHotbar()
	self:buildObjectiveBanner()
	self:buildDamageFlash()

	RunService.RenderStepped:Connect(function(dt) self:update(dt) end)
	return self
end

-- ── Build ──────────────────────────────────────────────────────────────────

function HUD:buildBars()
	local pad = 12

	-- HP bar
	local hpBg = makeFrame(self.gui, {
		Size = UDim2.new(0, 220, 0, 22), Position = UDim2.new(0, pad, 1, -pad - 22),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
	})
	makeCorner(hpBg, 4)
	self.hpFill = makeFrame(hpBg, {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(210, 40, 40), BorderSizePixel = 0,
	})
	makeCorner(self.hpFill, 4)
	self.hpLabel = makeLabel(hpBg, {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold,
		TextSize = 13, ZIndex = 2,
	})

	-- Shield bar (shown only when shield > 0)
	local shBg = makeFrame(self.gui, {
		Size = UDim2.new(0, 220, 0, 10), Position = UDim2.new(0, pad, 1, -pad - 22 - 14),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
	})
	makeCorner(shBg, 3)
	self.shFill = makeFrame(shBg, {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(80, 160, 255), BorderSizePixel = 0,
	})
	makeCorner(self.shFill, 3)
	self.shBg = shBg

	-- XP bar (full width bottom strip)
	local xpBg = makeFrame(self.gui, {
		Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0,
	})
	self.xpFill = makeFrame(xpBg, {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(230, 210, 0), BorderSizePixel = 0,
	})
	self.xpLabel = makeLabel(self.gui, {
		Size = UDim2.new(0, 100, 0, 14), Position = UDim2.new(0.5, -50, 1, -18),
		BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(230, 210, 0),
		Font = Enum.Font.Gotham, TextSize = 12,
	})
end

function HUD:buildHotbar()
	local labels = {"⚔ Melee", "🏹 Ranged", "🧪 Potion", "💣 Grenade"}
	local modes  = {"Melee", "Ranged", "Potion", "Grenade"}
	local W, H, GAP = 90, 56, 6
	local totalW = W * 4 + GAP * 3
	local startX = -totalW / 2

	local hotbarBg = makeFrame(self.gui, {
		Size = UDim2.new(0, totalW + 16, 0, H + 24),
		Position = UDim2.new(0.5, startX - 8, 1, -H - 24 - 40),
		BackgroundColor3 = Color3.fromRGB(10, 10, 15),
		BackgroundTransparency = 0.4, BorderSizePixel = 0,
	})
	makeCorner(hotbarBg, 8)

	self.hotbarSlots = {}
	for i, mode in ipairs(modes) do
		local slot = makeFrame(hotbarBg, {
			Size = UDim2.new(0, W, 0, H),
			Position = UDim2.new(0, 8 + (i - 1) * (W + GAP), 0, 8),
			BackgroundColor3 = Color3.fromRGB(40, 40, 55),
			BorderSizePixel = 0,
		})
		makeCorner(slot, 6)
		makeLabel(slot, {
			Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 4),
			BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200, 200, 220),
			Font = Enum.Font.GothamBold, TextSize = 11, Text = tostring(i),
		})
		local nameLabel = makeLabel(slot, {
			Size = UDim2.new(1, -4, 0, 20), Position = UDim2.new(0, 2, 1, -24),
			BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(180, 180, 200),
			Font = Enum.Font.Gotham, TextSize = 11, Text = labels[i], TextScaled = false,
		})
		self.hotbarSlots[mode] = {slot = slot, nameLabel = nameLabel}
	end

	-- Ammo counter (below hotbar)
	self.ammoLabel = makeLabel(self.gui, {
		Size = UDim2.new(0, 120, 0, 20),
		Position = UDim2.new(0.5, -60, 1, -32),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(200, 220, 255),
		Font = Enum.Font.GothamBold, TextSize = 15,
	})

	-- Grenade cook timer (above hotbar)
	self.cookLabel = makeLabel(self.gui, {
		Size = UDim2.new(0, 200, 0, 30),
		Position = UDim2.new(0.5, -100, 1, -H - 24 - 80),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 80, 30),
		Font = Enum.Font.GothamBold, TextSize = 22,
		Text = "", Visible = false,
	})
end

function HUD:buildObjectiveBanner()
	self.objectiveBg = makeFrame(self.gui, {
		Size = UDim2.new(0, 360, 0, 36),
		Position = UDim2.new(0.5, -180, 0, 14),
		BackgroundColor3 = Color3.fromRGB(10, 10, 20),
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false,
	})
	makeCorner(self.objectiveBg, 8)
	self.objectiveLabel = makeLabel(self.objectiveBg, {
		Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0),
		BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 230, 80),
		Font = Enum.Font.GothamBold, TextSize = 15, Text = "",
	})
end

function HUD:buildDamageFlash()
	self.damageFlash = makeFrame(self.gui, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(200, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50,
	})
	self.lastHP = nil
end

-- ── Update ─────────────────────────────────────────────────────────────────

function HUD:update(_dt)
	if not self.stats then return end
	local s = self.stats

	-- HP bar
	local hp    = math.max(0, s.realHP or 0) + (s.tempHP or 0)
	local maxHp = s.maxHP or 100
	local hpPct = math.clamp(hp / maxHp, 0, 1)
	self.hpFill.Size = UDim2.new(hpPct, 0, 1, 0)
	self.hpFill.BackgroundColor3 = hpPct > 0.5 and Color3.fromRGB(210, 40, 40)
		or hpPct > 0.25 and Color3.fromRGB(220, 130, 0) or Color3.fromRGB(255, 40, 40)
	self.hpLabel.Text = math.ceil(hp) .. " / " .. maxHp

	-- Damage flash
	if self.lastHP and hp < self.lastHP then
		self.damageFlash.BackgroundTransparency = 0.4
		TweenService:Create(self.damageFlash, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
	end
	self.lastHP = hp

	-- Shield bar
	if s.maxShield and s.maxShield > 0 then
		self.shBg.Visible = true
		self.shFill.Size = UDim2.new(math.clamp((s.shield or 0) / s.maxShield, 0, 1), 0, 1, 0)
	else
		self.shBg.Visible = false
	end

	-- XP bar
	local xp    = s.xp or 0
	local xpReq = s.xpNeeded or 100
	self.xpFill.Size = UDim2.new(math.clamp(xp / xpReq, 0, 1), 0, 1, 0)
	self.xpLabel.Text = "Level " .. (s.level or 1) .. "  •  " .. xp .. " / " .. xpReq .. " XP"

	-- Hotbar highlight
	if self.input then
		for mode, data in pairs(self.hotbarSlots) do
			local active = (self.input.weaponMode == mode)
			data.slot.BackgroundColor3 = active and Color3.fromRGB(90, 80, 30) or Color3.fromRGB(40, 40, 55)
			data.nameLabel.TextColor3  = active and Color3.fromRGB(255, 220, 60) or Color3.fromRGB(180, 180, 200)
		end

		-- Ammo
		if self.input.weaponMode == "Ranged" then
			self.ammoLabel.Visible = true
			self.ammoLabel.Text = "🏹 " .. (self.input.ammo or 0) .. " / " .. (self.input.maxAmmo or 0)
		else
			self.ammoLabel.Visible = false
		end

		-- Grenade cook timer
		if self.input.isCookingGrenade then
			local elapsed = tick() - (self.input.grenadeCookStart or 0)
			local remain = math.max(0, 4 - elapsed)
			self.cookLabel.Visible = true
			self.cookLabel.Text = string.format("💣 %.1fs", remain)
			self.cookLabel.TextColor3 = remain < 1
				and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 160, 30)
		else
			self.cookLabel.Visible = false
		end
	end

	-- Objective banner
	if self.missionText ~= "" then
		self.objectiveBg.Visible = true
		self.objectiveLabel.Text = "▶  " .. self.missionText
	else
		self.objectiveBg.Visible = false
	end
end

function HUD:setObjective(text)
	self.missionText = text or ""
end

function HUD:setStats(playerStats)
	self.stats = playerStats
	self.lastHP = nil
end

return HUD
