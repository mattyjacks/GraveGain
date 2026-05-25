-- DwarfDrop: hud.lua
-- In-game HUD: depth, timer, health, gold, biome, death/win screens

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GameData  = require(game.ReplicatedStorage.Shared.game_data)
local ItemData  = require(game.ReplicatedStorage.Shared.item_data)

local HUD = {}
HUD.__index = HUD

local COLOR_BG         = Color3.fromRGB(10, 10, 15)
local COLOR_HEALTH     = Color3.fromRGB(60, 210, 80)
local COLOR_HEALTH_LOW = Color3.fromRGB(220, 60, 40)
local COLOR_GOLD       = Color3.fromRGB(255, 210, 40)
local COLOR_DEPTH      = Color3.fromRGB(80, 200, 255)
local COLOR_TIMER      = Color3.fromRGB(255, 255, 255)
local COLOR_BIOME      = Color3.fromRGB(255, 180, 80)
local COLOR_DAMAGE     = Color3.fromRGB(255, 60, 60)

local function makeFrame(parent, name, pos, size, bgColor, bgTrans)
    local f = Instance.new("Frame")
    f.Name = name; f.Position = pos; f.Size = size
    f.BackgroundColor3 = bgColor or COLOR_BG
    f.BackgroundTransparency = bgTrans or 0.4
    f.BorderSizePixel = 0; f.Parent = parent
    return f
end

local function makeLabel(parent, name, text, pos, size, font, color, bgTrans)
    local l = Instance.new("TextLabel")
    l.Name = name; l.Text = text; l.Position = pos; l.Size = size
    l.BackgroundTransparency = bgTrans or 1
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.Font = font or Enum.Font.GothamBold
    l.TextScaled = true; l.Parent = parent
    return l
end

local function addCorner(f, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = f; return c
end

local function addStroke(f, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1, 1, 1)
    s.Thickness = thick or 1; s.Parent = f; return s
end

function HUD.new()
    local self = setmetatable({}, HUD)
    self.player   = Players.LocalPlayer
    self.gui      = nil
    self.isActive = false
    return self
end

function HUD:Build()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DwarfDropHUD"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10
    screenGui.Parent = self.player.PlayerGui
    self.gui       = screenGui
    self.screenGui = screenGui  -- FIX Bug#9: expose for BackpackUI before Build returns

    local main = Instance.new("Frame")
    main.Name = "Main"; main.Size = UDim2.new(1,0,1,0)
    main.Position = UDim2.new(0,0,0,0)
    main.BackgroundTransparency = 1; main.Parent = screenGui
    self.main = main

    -- Depth + Biome panel
    local depthPanel = makeFrame(main, "DepthPanel", UDim2.new(0,10,0,10), UDim2.new(0,220,0,80), COLOR_BG, 0.5)
    addCorner(depthPanel, 8)
    self.depthLabel = makeLabel(depthPanel, "DepthLabel", "0.0m", UDim2.new(0,0,0,0), UDim2.new(1,0,0.55,0), Enum.Font.GothamBold, COLOR_DEPTH)
    self.depthLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.biomeLabel = makeLabel(depthPanel, "BiomeLabel", "VOLCANO", UDim2.new(0,0,0.55,0), UDim2.new(1,0,0.45,0), Enum.Font.Gotham, COLOR_BIOME)
    self.biomeLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Timer
    local timerPanel = makeFrame(main, "TimerPanel", UDim2.new(0.5,-80,0,10), UDim2.new(0,160,0,50), COLOR_BG, 0.5)
    addCorner(timerPanel, 8)
    self.timerLabel = makeLabel(timerPanel, "Timer", "00:00.00", UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), Enum.Font.Code, COLOR_TIMER)
    self.timerLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Gold: placed to right of depth panel, away from player list
    local goldPanel = makeFrame(main, "GoldPanel", UDim2.new(0,240,0,10), UDim2.new(0,170,0,50), COLOR_BG, 0.5)
    addCorner(goldPanel, 8)
    self.goldLabel = makeLabel(goldPanel, "Gold", "GOLD: 0", UDim2.new(0,10,0,0), UDim2.new(1,-10,1,0), Enum.Font.GothamBold, COLOR_GOLD)
    self.goldLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Health
    local healthPanel = makeFrame(main, "HealthPanel", UDim2.new(0,10,1,-70), UDim2.new(0,260,0,55), COLOR_BG, 0.5)
    addCorner(healthPanel, 8)
    self.healthText = makeLabel(healthPanel, "HealthText", "100 / 100", UDim2.new(0,8,0,2), UDim2.new(1,-16,0.4,0), Enum.Font.GothamBold, COLOR_HEALTH)
    self.healthText.TextXAlignment = Enum.TextXAlignment.Left
    local barTrack = makeFrame(healthPanel, "Track", UDim2.new(0,8,0.5,0), UDim2.new(1,-16,0,16), COLOR_BG, 0.2)
    addCorner(barTrack, 4)
    self.healthBar = makeFrame(barTrack, "Fill", UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), COLOR_HEALTH, 0)
    addCorner(self.healthBar, 4)

    -- Damage flash
    self.damageFlash = makeFrame(main, "DamageFlash", UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), COLOR_DAMAGE, 1)
    self.damageFlash.ZIndex = 20

    -- Death screen
    self.deathScreen = makeFrame(main, "DeathScreen", UDim2.new(0.5,-220,0.5,-180), UDim2.new(0,440,0,360), Color3.fromRGB(12,4,4), 0.1)
    addCorner(self.deathScreen, 14); addStroke(self.deathScreen, COLOR_DAMAGE, 2)
    self.deathScreen.Visible = false; self.deathScreen.ZIndex = 30

    makeLabel(self.deathScreen, "Title", "YOU DIED", UDim2.new(0,0,0,8), UDim2.new(1,0,0,38), Enum.Font.GothamBold, COLOR_DAMAGE).TextSize = 28

    self.deathDepthLabel = makeLabel(self.deathScreen, "Depth", "Depth: 0.0m", UDim2.new(0,0,0,46), UDim2.new(0.5,0,0,22), Enum.Font.Gotham, Color3.new(1,1,1))
    self.deathDepthLabel.TextSize = 14; self.deathDepthLabel.TextScaled = false; self.deathDepthLabel.ZIndex = 31

    self.deathGoldLabel = makeLabel(self.deathScreen, "Gold", "Gold: +0", UDim2.new(0.5,0,0,46), UDim2.new(0.5,0,0,22), Enum.Font.Gotham, COLOR_GOLD)
    self.deathGoldLabel.TextSize = 14; self.deathGoldLabel.TextScaled = false; self.deathGoldLabel.ZIndex = 31

    local function makeDeathBtn(name, label, subLabel, row, col, bgColor, callback)
        local PAD = 10; local btnW = (440 - PAD*3)/2; local btnH = (360 - 88 - PAD*3)/2
        local x = PAD + (col-1)*(btnW+PAD); local y = 82 + PAD + (row-1)*(btnH+PAD)
        local btn = Instance.new("TextButton")
        btn.Name = name; btn.Position = UDim2.new(0,x,0,y); btn.Size = UDim2.new(0,btnW,0,btnH)
        btn.BackgroundColor3 = bgColor; btn.BackgroundTransparency = 0.15
        btn.Text = ""; btn.BorderSizePixel = 0; btn.ZIndex = 31; btn.Parent = self.deathScreen
        local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,10); c2.Parent = btn
        local lbl = Instance.new("TextLabel"); lbl.Text = label
        lbl.Size = UDim2.new(1,-8,0.55,0); lbl.Position = UDim2.new(0,4,0.05,0)
        lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.new(1,1,1)
        lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.ZIndex = 32; lbl.Parent = btn
        local sub = Instance.new("TextLabel"); sub.Text = subLabel
        sub.Size = UDim2.new(1,-8,0.38,0); sub.Position = UDim2.new(0,4,0.58,0)
        sub.BackgroundTransparency = 1; sub.TextColor3 = Color3.fromRGB(200,190,180)
        sub.Font = Enum.Font.Gotham; sub.TextScaled = true; sub.ZIndex = 32; sub.Parent = btn
        btn.MouseButton1Click:Connect(function() if callback then callback() end end)
        btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0 end)
        btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.15 end)
        return btn
    end

    makeDeathBtn("RespawnBasket","Respawn in Basket","Keep timer & items",1,1,Color3.fromRGB(40,120,60),function() if self.deathChoiceCallback then self.deathChoiceCallback("respawnBasket") end end)
    makeDeathBtn("RespawnHub","Respawn in Hub","Keep timer & items",1,2,Color3.fromRGB(40,80,160),function() if self.deathChoiceCallback then self.deathChoiceCallback("respawnHub") end end)
    makeDeathBtn("ResetBasket","Reset in Basket","Timer resets, lose items",2,1,Color3.fromRGB(160,100,20),function() if self.deathChoiceCallback then self.deathChoiceCallback("resetBasket") end end)
    makeDeathBtn("ResetHub","Reset in Hub","Timer resets, lose items",2,2,Color3.fromRGB(100,30,30),function() if self.deathChoiceCallback then self.deathChoiceCallback("resetHub") end end)

    -- Win screen
    self.winScreen = makeFrame(main, "WinScreen", UDim2.new(0.2,0,0.15,0), UDim2.new(0.6,0,0.7,0), Color3.fromRGB(5,20,5), 0.15)
    addCorner(self.winScreen, 14); self.winScreen.Visible = false
    makeLabel(self.winScreen, "Title", "YOU REACHED THE BOTTOM!", UDim2.new(0,0,0,0), UDim2.new(1,0,0.18,0), Enum.Font.GothamBold, COLOR_HEALTH)
    self.winTimeLabel  = makeLabel(self.winScreen, "Time", "Time: 00:00.00", UDim2.new(0,0,0.2,0), UDim2.new(1,0,0.15,0), Enum.Font.Code, COLOR_TIMER)
    self.winRankLabel  = makeLabel(self.winScreen, "Rank", "Rank: #???", UDim2.new(0,0,0.36,0), UDim2.new(1,0,0.14,0), Enum.Font.GothamBold, COLOR_GOLD)
    self.winGoldLabel  = makeLabel(self.winScreen, "Gold", "Gold Earned: +0", UDim2.new(0,0,0.52,0), UDim2.new(1,0,0.13,0), Enum.Font.Gotham, COLOR_GOLD)
    makeLabel(self.winScreen, "Hint", "Returning to hub...", UDim2.new(0,0,0.8,0), UDim2.new(1,0,0.12,0), Enum.Font.Gotham, Color3.fromRGB(160,160,160))

    -- Biome banner
    self.biomeBanner = makeFrame(main, "BiomeBanner", UDim2.new(0.25,0,0.4,0), UDim2.new(0.5,0,0.1,0), Color3.fromRGB(20,10,5), 0.3)
    addCorner(self.biomeBanner, 10); self.biomeBanner.Visible = false
    self.biomeBannerLabel = makeLabel(self.biomeBanner, "Text", "ENTERING VOLCANO", UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), Enum.Font.GothamBold, COLOR_BIOME)

    -- Crosshair
    makeFrame(main,"CrossH",UDim2.new(0.5,-10,0.5,-1),UDim2.new(0,20,0,2),Color3.new(1,1,1),0.3)
    makeFrame(main,"CrossV",UDim2.new(0.5,-1,0.5,-10),UDim2.new(0,2,0,20),Color3.new(1,1,1),0.3)

    -- Progress bar (right edge, vertical)
    local progressTrack = makeFrame(main,"ProgressTrack",UDim2.new(1,-16,0,80),UDim2.new(0,8,1,-190),Color3.fromRGB(30,30,40),0.4)
    addCorner(progressTrack, 4)
    self.progressFill = makeFrame(progressTrack,"Fill",UDim2.new(0,0,1,0),UDim2.new(1,0,0,0),COLOR_DEPTH,0)
    addCorner(self.progressFill, 4)
    self.progressLabel = makeLabel(main,"DepthPct","0%",UDim2.new(1,-42,1,-108),UDim2.new(0,36,0,20),Enum.Font.GothamBold,COLOR_DEPTH)
    self.progressLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.progressLabel.TextScaled = false; self.progressLabel.TextSize = 13

    -- Speed panel
    local speedPanel = makeFrame(main,"SpeedPanel",UDim2.new(1,-118,1,-80),UDim2.new(0,100,0,44),COLOR_BG,0.5)
    addCorner(speedPanel,8)
    makeLabel(speedPanel,"SpeedTitle","SPEED",UDim2.new(0,0,0,2),UDim2.new(1,0,0.42,0),Enum.Font.Gotham,Color3.fromRGB(150,150,180))
    self.speedLabel = makeLabel(speedPanel,"SpeedVal","0",UDim2.new(0,0,0.42,0),UDim2.new(1,0,0.58,-2),Enum.Font.GothamBold,Color3.fromRGB(80,200,255))

    -- Combo
    self.comboPanel = makeFrame(main,"ComboPanel",UDim2.new(0.5,-80,1,-140),UDim2.new(0,160,0,60),COLOR_BG,0.6)
    addCorner(self.comboPanel,10); self.comboPanel.Visible = false
    self.comboLabel = makeLabel(self.comboPanel,"Combo","x1 COMBO",UDim2.new(0,0,0,0),UDim2.new(1,0,0.55,0),Enum.Font.GothamBold,COLOR_GOLD)
    self.comboLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.comboStreakLabel = makeLabel(self.comboPanel,"Streak","1 COINS",UDim2.new(0,0,0.55,0),UDim2.new(1,0,0.45,0),Enum.Font.Gotham,Color3.fromRGB(200,200,200))
    self.comboStreakLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Air jump pips
    self.airJumpFrame = makeFrame(main,"AirJumpPips",UDim2.new(0,10,1,-90),UDim2.new(0,100,0,16),Color3.new(0,0,0),1)
    self.airJumpPips = {}

    -- Modifier badge
    self.modifierBadge = makeFrame(main,"ModifierBadge",UDim2.new(1,-155,0,68),UDim2.new(0,145,0,36),COLOR_BG,0.45)
    addCorner(self.modifierBadge,8); self.modifierBadge.Visible = false
    self.modifierLabel = makeLabel(self.modifierBadge,"ModLabel","",UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.Font.GothamBold,Color3.new(1,1,1))
    self.modifierLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Item slot
    local itemSlot = makeFrame(main,"ItemSlot",UDim2.new(1,-118,1,-135),UDim2.new(0,100,0,50),COLOR_BG,0.5)
    addCorner(itemSlot,8); itemSlot.Visible = false; self.itemSlot = itemSlot
    self.itemNameLabel = makeLabel(itemSlot,"ItemName","",UDim2.new(0,6,0,2),UDim2.new(1,-6,0.45,0),Enum.Font.GothamBold,Color3.fromRGB(255,230,100))
    self.itemNameLabel.TextXAlignment = Enum.TextXAlignment.Left; self.itemNameLabel.TextSize = 11; self.itemNameLabel.TextScaled = false
    self.itemCountLabel = makeLabel(itemSlot,"ItemCount","[Q] Use",UDim2.new(0,6,0.5,0),UDim2.new(1,-6,0.5,0),Enum.Font.Gotham,Color3.fromRGB(200,200,200))
    self.itemCountLabel.TextXAlignment = Enum.TextXAlignment.Left; self.itemCountLabel.TextSize = 10; self.itemCountLabel.TextScaled = false

    -- Water bar
    local waterPanel = makeFrame(main,"WaterPanel",UDim2.new(1,-118,1,-160),UDim2.new(0,100,0,20),COLOR_BG,0.5)
    addCorner(waterPanel,4); waterPanel.Visible = false; self.waterPanel = waterPanel
    makeLabel(waterPanel,"WaterTitle","WATER",UDim2.new(0,4,0,0),UDim2.new(0.4,0,1,0),Enum.Font.Gotham,Color3.fromRGB(120,200,255))
    local waterTrack = makeFrame(waterPanel,"Track",UDim2.new(0.42,0,0.2,0),UDim2.new(0.55,0,0.6,0),COLOR_BG,0.3)
    addCorner(waterTrack,3)
    self.waterFill = makeFrame(waterTrack,"Fill",UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Color3.fromRGB(80,180,255),0)
    addCorner(self.waterFill,3)

    -- Speed lines overlay
    self.speedLines = makeFrame(main,"SpeedLines",UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Color3.new(1,1,1),1)
    self.speedLines.ZIndex = 5
    for i = 1, 12 do
        local angle  = (i/12)*math.pi*2
        local length = math.random(80,200)
        local thick  = math.random(1,3)
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.new(1,1,1); line.BackgroundTransparency = 1
        line.BorderSizePixel = 0; line.Size = UDim2.new(0,thick,0,length)
        line.Position = UDim2.new(0.5,-thick/2,0.5,0)
        line.Rotation = math.deg(angle)+90; line.AnchorPoint = Vector2.new(0.5,0)
        line.ZIndex = 5; line.Parent = self.speedLines
    end
    self.speedLinesList = self.speedLines:GetChildren()
    self.speedLinesActive = false

    main.Visible = false; self.isActive = false; self.lastSpeed = 0

    -- FIX Bug#9: return self so caller can chain or access screenGui immediately
    return self
end

function HUD:Show() if self.main then self.main.Visible = true; self.isActive = true end end
function HUD:Hide() if self.main then self.main.Visible = false; self.isActive = false end end

function HUD:UpdateHealth(current, max)
    if not self.healthBar then return end
    local pct = max > 0 and (current/max) or 0
    self.healthBar.Size = UDim2.new(pct,0,1,0)
    local col = pct > 0.4 and COLOR_HEALTH or COLOR_HEALTH_LOW
    self.healthBar.BackgroundColor3 = col
    if self.healthText then
        self.healthText.Text = math.ceil(current).." / "..math.ceil(max)
        self.healthText.TextColor3 = col
    end
    if pct < 0.5 then self:FlashDamage(1 - pct*2) else self:FlashDamage(0.3) end
end

function HUD:FlashDamage(alpha)
    if not self.damageFlash then return end
    alpha = math.clamp(alpha, 0, 0.5)
    self.damageFlash.BackgroundTransparency = 1 - alpha
    TweenService:Create(self.damageFlash, TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {BackgroundTransparency=1}):Play()
end

function HUD:UpdateDepth(depthMeters)
    if self.depthLabel then self.depthLabel.Text = string.format("%.1fm", depthMeters) end
    local pct = math.clamp(depthMeters/1000, 0, 1)
    if self.progressFill then
        self.progressFill.Size = UDim2.new(1,0,pct,0)
        self.progressFill.Position = UDim2.new(0,0,1-pct,0)
        local r = math.floor(80 + (40-80)*pct); local g = math.floor(200 + (255-200)*pct); local b = math.floor(255 + (100-255)*pct)
        self.progressFill.BackgroundColor3 = Color3.fromRGB(r,g,b)
    end
    if self.progressLabel then self.progressLabel.Text = string.format("%d%%", math.floor(pct*100)) end
end

function HUD:UpdateSpeed(studsPerSec)
    self.lastSpeed = studsPerSec or 0
    if self.speedLabel then self.speedLabel.Text = string.format("%.0f", studsPerSec) end
    self:ShowSpeedLines(studsPerSec > 30)
end

function HUD:ShowSpeedLines(show)
    if not self.speedLines then return end
    if show == self.speedLinesActive then return end
    self.speedLinesActive = show
    local alpha = show and 0.72 or 1
    for _, line in ipairs(self.speedLinesList or {}) do
        if line:IsA("Frame") then
            TweenService:Create(line, TweenInfo.new(0.12), {BackgroundTransparency=alpha}):Play()
        end
    end
end

function HUD:UpdateCombo(streak, mult)
    if not self.comboPanel then return end
    if streak <= 1 then self.comboPanel.Visible = false; return end
    self.comboPanel.Visible = true
    if self.comboLabel then
        local multColors = {[1]=Color3.fromRGB(255,220,60),[2]=Color3.fromRGB(80,220,255),[3]=Color3.fromRGB(255,120,40),[5]=Color3.fromRGB(220,80,255)}
        local col = multColors[mult] or COLOR_GOLD
        self.comboLabel.Text = string.format("x%d COMBO", mult)
        self.comboLabel.TextColor3 = col
        self.comboLabel.Position = UDim2.new(0,0,-0.05,0)
        TweenService:Create(self.comboLabel, TweenInfo.new(0.1,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Position=UDim2.new(0,0,0,0)}):Play()
    end
    if self.comboStreakLabel then self.comboStreakLabel.Text = string.format("%d COINS", streak) end
end

function HUD:UpdateAirJumps(left, max)
    if not self.airJumpFrame then return end
    for _, pip in ipairs(self.airJumpPips) do if pip.Parent then pip:Destroy() end end
    self.airJumpPips = {}
    if max <= 0 then self.airJumpFrame.Visible = false; return end
    self.airJumpFrame.Visible = true
    local pipW = 14; local pipGap = 4
    for i = 1, max do
        local pip = Instance.new("Frame")
        pip.Size = UDim2.new(0,pipW,0,12); pip.Position = UDim2.new(0,(i-1)*(pipW+pipGap),0,0)
        pip.BackgroundColor3 = i<=left and Color3.fromRGB(80,200,255) or Color3.fromRGB(40,40,60)
        pip.BackgroundTransparency = 0.2; pip.BorderSizePixel = 0
        local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,3); c2.Parent = pip
        pip.Parent = self.airJumpFrame; table.insert(self.airJumpPips, pip)
    end
end

function HUD:SetModifier(modifier)
    if not self.modifierBadge then return end
    if not modifier or modifier.id == "Normal" then self.modifierBadge.Visible = false; return end
    self.modifierBadge.Visible = true
    self.modifierBadge.BackgroundColor3 = modifier.color or Color3.new(1,1,1)
    if self.modifierLabel then self.modifierLabel.Text = modifier.displayName or modifier.id end
end

function HUD:UpdateTimer(timeSeconds)
    if self.timerLabel then
        local cs = math.floor((timeSeconds%1)*100); local s = math.floor(timeSeconds)%60; local m = math.floor(timeSeconds/60)
        self.timerLabel.Text = string.format("%02d:%02d.%02d", m, s, cs)
    end
end

function HUD:UpdateActiveItem(itemId, count, active)
    if not self.itemSlot then return end
    if not itemId then self.itemSlot.Visible = false; return end
    local def = ItemData.Items[itemId]
    self.itemSlot.Visible = true
    if self.itemNameLabel then self.itemNameLabel.Text = def and def.displayName or itemId end
    if self.itemCountLabel then
        if def and def.useType == "place" then self.itemCountLabel.Text = "[F] Place  x"..(count or 0)
        elseif def and def.useType == "toggle" then self.itemCountLabel.Text = active and "[Q] ON" or "[Q] OFF"
        elseif def and def.useType == "hold" then self.itemCountLabel.Text = active and "[Q] ACTIVE" or "[Q] Hold"
        else self.itemCountLabel.Text = "[Q] Use" end
    end
end

function HUD:UpdateWater(current, max)
    if not self.waterPanel then return end
    local hasWater = (max or 0) > 0
    self.waterPanel.Visible = hasWater
    if self.waterFill and hasWater then
        self.waterFill.Size = UDim2.new(math.clamp((current or 0)/max,0,1),0,1,0)
    end
end

function HUD:UpdateGold(amount)
    if self.goldLabel then self.goldLabel.Text = string.format("GOLD: %d", amount) end
end

function HUD:ShowBiomeChange(biomeName)
    if self.biomeLabel then self.biomeLabel.Text = string.upper(biomeName) end
    if self.biomeBanner and self.biomeBannerLabel then
        self.biomeBannerLabel.Text = "ENTERING "..string.upper(biomeName)
        self.biomeBanner.Visible = true; self.biomeBanner.BackgroundTransparency = 0.3
        TweenService:Create(self.biomeBanner, TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {BackgroundTransparency=1}):Play()
        task.delay(2.5, function()
            if self.biomeBanner then self.biomeBanner.Visible = false; self.biomeBanner.BackgroundTransparency = 0.3 end
        end)
    end
end

function HUD:ShowDeath(depthReached, goldEarned, callback)
    if not self.deathScreen then return end
    self.deathChoiceCallback = callback
    self.deathScreen.Visible = true
    if self.deathDepthLabel then self.deathDepthLabel.Text = string.format("Depth: %.1fm", depthReached) end
    if self.deathGoldLabel then self.deathGoldLabel.Text = string.format("+%d Gold", goldEarned) end
end

function HUD:HideDeath()
    if self.deathScreen then self.deathScreen.Visible = false; self.deathChoiceCallback = nil end
end

function HUD:ShowWin(timeSeconds, absoluteRank, goldEarned)
    if not self.winScreen then return end
    self.winScreen.Visible = true
    if self.winTimeLabel then
        local cs = math.floor((timeSeconds%1)*100); local s = math.floor(timeSeconds)%60; local m = math.floor(timeSeconds/60)
        self.winTimeLabel.Text = string.format("Time: %02d:%02d.%02d", m, s, cs)
    end
    if self.winRankLabel then self.winRankLabel.Text = string.format("Global Rank: #%d", absoluteRank or 999) end
    if self.winGoldLabel then self.winGoldLabel.Text = string.format("Gold Earned: +%d", goldEarned) end
end

function HUD:HideWin()
    if self.winScreen then self.winScreen.Visible = false end
end

function HUD:ShowToast(message)
    if not self.main then return end
    if not self.toastLabel then
        local t = makeLabel(self.main,"Toast","",UDim2.new(0.2,0,0.1,0),UDim2.new(0.6,0,0,28),Enum.Font.GothamBold,Color3.new(1,1,1))
        t.TextSize = 14; t.ZIndex = 28; t.BackgroundColor3 = Color3.fromRGB(18,14,28)
        t.BackgroundTransparency = 0.3; t.BorderSizePixel = 0; addCorner(t,6); self.toastLabel = t
    end
    self.toastLabel.Text = message; self.toastLabel.Visible = true; self.toastLabel.TextTransparency = 0
    if self.toastTween then self.toastTween:Cancel() end
    task.delay(2, function()
        if self.toastLabel then
            self.toastTween = TweenService:Create(self.toastLabel, TweenInfo.new(0.5), {TextTransparency=1})
            self.toastTween:Play()
            self.toastTween.Completed:Connect(function() if self.toastLabel then self.toastLabel.Visible = false end end)
        end
    end)
end

function HUD:ShowDowned()
    if not self.main then return end
    if self.downedOverlay then self.downedOverlay.Visible = true; return end
    local ov = makeFrame(self.main,"DownedOverlay",UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Color3.fromRGB(60,10,10),0.45)
    ov.ZIndex = 25
    local lbl = makeLabel(ov,"Label","YOU ARE DOWN\nHold on for rescue...",UDim2.new(0.2,0,0.35,0),UDim2.new(0.6,0,0.3,0),Enum.Font.GothamBold,Color3.new(1,0.2,0.2))
    lbl.TextScaled = true; lbl.ZIndex = 26; self.downedOverlay = ov
end

function HUD:HideDowned()
    if self.downedOverlay then self.downedOverlay.Visible = false end
end

function HUD:ShowRescueProgress(progress)
    if not self.main then return end
    if not self.rescueBar then
        local bg = makeFrame(self.main,"RescueBarBG",UDim2.new(0.3,0,0.62,0),UDim2.new(0.4,0,0,20),Color3.fromRGB(20,16,28),0.2)
        bg.ZIndex = 22; addCorner(bg,6)
        local fill = makeFrame(bg,"Fill",UDim2.new(0,0,0,0),UDim2.new(0,0,1,0),Color3.fromRGB(60,210,80),0)
        fill.ZIndex = 23; addCorner(fill,6)
        local lbl2 = makeLabel(bg,"Label","RESCUING...",UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.Font.GothamBold,Color3.new(1,1,1))
        lbl2.TextSize = 11; lbl2.ZIndex = 24; self.rescueBar = bg; self.rescueFill = fill
    end
    if progress == nil then self.rescueBar.Visible = false
    else
        self.rescueBar.Visible = true
        self.rescueFill.Size = UDim2.new(math.clamp(progress,0,1),0,1,0)
    end
end

return HUD
