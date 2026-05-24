-- DropDwarf: hub_ui.lua
-- Hub UI: upgrade shop, seed input, leaderboard display

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local GameData    = require(game.ReplicatedStorage.Shared.game_data)
local UpgradeData = require(game.ReplicatedStorage.Shared.upgrade_data)
local Networking  = require(game.ReplicatedStorage.Shared.networking)
local TimedSeeds  = require(game.ReplicatedStorage.Shared.timed_seeds)
local GameMode    = require(game.ReplicatedStorage.Shared.game_mode)

local HubUI = {}
HubUI.__index = HubUI

local COLOR_BG      = Color3.fromRGB(12, 10, 16)
local COLOR_PANEL   = Color3.fromRGB(22, 18, 28)
local COLOR_GOLD    = Color3.fromRGB(255, 210, 40)
local COLOR_GREEN   = Color3.fromRGB(60, 210, 80)
local COLOR_ORANGE  = Color3.fromRGB(255, 140, 30)
local COLOR_WHITE   = Color3.new(1, 1, 1)
local COLOR_GRAY    = Color3.fromRGB(140, 130, 120)
local COLOR_RED     = Color3.fromRGB(220, 60, 40)
local COLOR_CYAN    = Color3.fromRGB(80, 200, 255)

local function makeFrame(parent, name, pos, size, bg, trans)
    local f = Instance.new("Frame")
    f.Name = name
    f.Position = pos
    f.Size = size
    f.BackgroundColor3 = bg or COLOR_BG
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function makeLabel(parent, name, text, pos, size, font, color, align, bgTrans)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Text = text
    l.Position = pos
    l.Size = size
    l.BackgroundTransparency = bgTrans or 1
    l.TextColor3 = color or COLOR_WHITE
    l.Font = font or Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.Parent = parent
    return l
end

local function makeButton(parent, name, text, pos, size, bgColor, textColor, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.Position = pos
    btn.Size = size
    btn.BackgroundColor3 = bgColor or COLOR_ORANGE
    btn.TextColor3 = textColor or COLOR_WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

local function makeInput(parent, name, placeholder, pos, size)
    local box = Instance.new("TextBox")
    box.Name = name
    box.PlaceholderText = placeholder
    box.Text = ""
    box.Position = pos
    box.Size = size
    box.BackgroundColor3 = Color3.fromRGB(20, 18, 24)
    box.TextColor3 = COLOR_WHITE
    box.PlaceholderColor3 = COLOR_GRAY
    box.Font = Enum.Font.Code
    box.TextScaled = true
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box
    return box
end

local function addCorner(f, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = f
    return c
end

local function addStroke(f, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or COLOR_GRAY
    s.Thickness = thick or 1
    s.Parent = f
    return s
end

function HubUI.new()
    local self = setmetatable({}, HubUI)
    self.player         = Players.LocalPlayer
    self.gui            = nil
    self.playerData     = nil
    self.currentSeed    = "MattyJacks"
    self.shopOpen       = false
    self.shopUpgradeId  = nil
    self.leaderboardOpen = false
    self.seedOpen       = false
    self.modifierOpen   = false
    self.selectedModifier = "Normal"  -- currently chosen modifier id
    self.dropType = "fps"              -- "fps" or "tps"
    self.gameModeId = "Singleplayer"   -- current selected game mode
    self.lobbyOpen  = false
    self.lobbyData  = nil              -- last received lobby state
    return self
end

function HubUI:Build()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DropDwarfHubUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 5
    screenGui.Parent = self.player.PlayerGui
    self.gui = screenGui

    -- ==================== PERSISTENT BAR ====================
    -- Top bar always visible in hub: gold, best time, seed
    local topBar = makeFrame(screenGui, "TopBar",
        UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 44),
        COLOR_BG, 0.3)
    addStroke(topBar, Color3.fromRGB(60, 50, 40), 1)
    self.topBar = topBar

    makeLabel(topBar, "Title", "DROP DWARF",
        UDim2.new(0.5, -80, 0, 2), UDim2.new(0, 160, 1, -4),
        Enum.Font.GothamBold, COLOR_ORANGE)

    self.goldBarLabel = makeLabel(topBar, "Gold",
        "GOLD: 0",
        UDim2.new(0, 10, 0, 2), UDim2.new(0, 160, 1, -4),
        Enum.Font.GothamBold, COLOR_GOLD, Enum.TextXAlignment.Left)

    self.bestTimeBarLabel = makeLabel(topBar, "BestTime",
        "BEST: --:--.-",
        UDim2.new(1, -520, 0, 2), UDim2.new(0, 190, 1, -4),
        Enum.Font.Code, COLOR_CYAN, Enum.TextXAlignment.Right)

    -- MODIFIERS button in top bar
    makeButton(topBar, "ModifierBtn", "MODIFIERS",
        UDim2.new(1, -112, 0, 4), UDim2.new(0, 104, 1, -8),
        Color3.fromRGB(80, 40, 120), COLOR_WHITE, function()
            self:OpenModifier()
        end)

    -- MULTIPLAYER button in top bar
    makeButton(topBar, "MultiplayerBtn", "MULTIPLAYER",
        UDim2.new(1, -226, 0, 4), UDim2.new(0, 106, 1, -8),
        Color3.fromRGB(30, 80, 160), COLOR_WHITE, function()
            self:OpenLobby(self.onStartRun)
        end)

    -- OPTIONS button in top bar
    makeButton(topBar, "OptionsBtn", "OPTIONS",
        UDim2.new(1, -322, 0, 4), UDim2.new(0, 88, 1, -8),
        Color3.fromRGB(100, 80, 70), COLOR_WHITE, function()
            self:OpenOptions()
        end)

    -- ==================== UPGRADE SHOP PANEL ====================
    local shopPanel = makeFrame(screenGui, "ShopPanel",
        UDim2.new(0.5, -200, 0.5, -200), UDim2.new(0, 400, 0, 400),
        COLOR_PANEL, 0.05)
    addCorner(shopPanel, 12)
    addStroke(shopPanel, COLOR_ORANGE, 2)
    shopPanel.Visible = false
    self.shopPanel = shopPanel

    makeLabel(shopPanel, "Title", "UPGRADE SHOP",
        UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 36),
        Enum.Font.GothamBold, COLOR_ORANGE)

    self.shopUpgradeName = makeLabel(shopPanel, "UpgradeName", "",
        UDim2.new(0, 12, 0, 50), UDim2.new(1, -24, 0, 28),
        Enum.Font.GothamBold, COLOR_WHITE)

    self.shopDescription = makeLabel(shopPanel, "Desc", "",
        UDim2.new(0, 12, 0, 80), UDim2.new(1, -24, 0, 44),
        Enum.Font.Gotham, COLOR_GRAY)
    self.shopDescription.TextScaled = false
    self.shopDescription.TextSize = 15
    self.shopDescription.TextWrapped = true

    self.shopCurrentLabel = makeLabel(shopPanel, "Current", "Current: 0",
        UDim2.new(0, 12, 0, 130), UDim2.new(1, -24, 0, 24),
        Enum.Font.Gotham, COLOR_CYAN, Enum.TextXAlignment.Left)

    self.shopNextLabel = makeLabel(shopPanel, "Next", "Next: 0",
        UDim2.new(0, 12, 0, 156), UDim2.new(1, -24, 0, 24),
        Enum.Font.Gotham, COLOR_GREEN, Enum.TextXAlignment.Left)

    self.shopTierLabel = makeLabel(shopPanel, "Tier", "Tier: 0 / 10",
        UDim2.new(0, 12, 0, 182), UDim2.new(1, -24, 0, 24),
        Enum.Font.Gotham, COLOR_WHITE, Enum.TextXAlignment.Left)

    -- Tier progress bar
    local tierTrack = makeFrame(shopPanel, "TierTrack",
        UDim2.new(0, 12, 0, 212), UDim2.new(1, -24, 0, 14),
        Color3.fromRGB(30, 25, 35), 0)
    addCorner(tierTrack, 4)
    self.shopTierBar = makeFrame(tierTrack, "TierFill",
        UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0),
        COLOR_ORANGE, 0)
    addCorner(self.shopTierBar, 4)

    self.shopCostLabel = makeLabel(shopPanel, "Cost", "Cost: 50 Gold",
        UDim2.new(0, 12, 0, 232), UDim2.new(1, -24, 0, 28),
        Enum.Font.GothamBold, COLOR_GOLD)

    self.shopGoldLabel = makeLabel(shopPanel, "YourGold", "You have: 0 Gold",
        UDim2.new(0, 12, 0, 262), UDim2.new(1, -24, 0, 22),
        Enum.Font.Gotham, COLOR_GRAY)

    self.shopBuyBtn = makeButton(shopPanel, "BuyBtn", "UPGRADE",
        UDim2.new(0, 12, 0, 292), UDim2.new(1, -24, 0, 44),
        COLOR_ORANGE, COLOR_WHITE, function()
            self:PurchaseUpgrade()
        end)

    makeButton(shopPanel, "CloseBtn", "CLOSE",
        UDim2.new(0, 12, 0, 344), UDim2.new(1, -24, 0, 36),
        Color3.fromRGB(50, 40, 55), COLOR_GRAY, function()
            self:CloseShop()
        end)

    -- ==================== SEED INPUT PANEL ====================
    local seedPanel = makeFrame(screenGui, "SeedPanel",
        UDim2.new(0.5, -220, 0.5, -220), UDim2.new(0, 440, 0, 440),
        COLOR_PANEL, 0.05)
    addCorner(seedPanel, 12)
    addStroke(seedPanel, COLOR_CYAN, 2)
    seedPanel.Visible = false
    self.seedPanel = seedPanel

    makeLabel(seedPanel, "Title", "LEVEL SEED",
        UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 34),
        Enum.Font.GothamBold, COLOR_CYAN)

    makeLabel(seedPanel, "Hint",
        "Same seed = same level layout. Compare runs with friends!",
        UDim2.new(0, 12, 0, 46), UDim2.new(1, -24, 0, 22),
        Enum.Font.Gotham, COLOR_GRAY)
    local seedHintLabel = seedPanel:FindFirstChild("Hint")
    if seedHintLabel then
        seedHintLabel.TextScaled = false
        seedHintLabel.TextSize = 13
        seedHintLabel.TextWrapped = true
    end

    -- Timed seed buttons
    local timedData = TimedSeeds.GetAll()
    local timedColors = { COLOR_ORANGE, Color3.fromRGB(80, 160, 255), Color3.fromRGB(160, 80, 255) }
    local timedBtnY = 72
    self.timedSeedBtns = {}
    for i, ts in ipairs(timedData) do
        local btn = makeButton(seedPanel, "TimedBtn_" .. i,
            ts.label .. "  [" .. TimedSeeds.FormatCountdown(ts.countdown) .. "]",
            UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -24, 0, 34),
            timedColors[i], COLOR_WHITE, function()
                self.seedInput.Text = ts.seed
                self:ConfirmSeedText(ts.seed)
            end)
        self.timedSeedBtns[i] = { btn = btn, seedData = ts }
        timedBtnY = timedBtnY + 38
    end

    -- Default seed button
    makeButton(seedPanel, "DefaultBtn", "Default Seed (MattyJacks)",
        UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -24, 0, 34),
        Color3.fromRGB(50, 120, 60), COLOR_WHITE, function()
            self.seedInput.Text = "MattyJacks"
            self:ConfirmSeedText("MattyJacks")
        end)
    timedBtnY = timedBtnY + 42

    -- Divider
    makeFrame(seedPanel, "Divider",
        UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -24, 0, 1),
        COLOR_GRAY, 0.5)
    timedBtnY = timedBtnY + 10

    -- Custom seed input
    makeLabel(seedPanel, "CustomLabel", "Custom Seed:",
        UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -24, 0, 20),
        Enum.Font.Gotham, COLOR_GRAY, Enum.TextXAlignment.Left)
    timedBtnY = timedBtnY + 22

    self.seedInput = makeInput(seedPanel, "SeedInput", "Enter any text or number...",
        UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -130, 0, 34))
    self.seedInput.Text = self.currentSeed

    makeButton(seedPanel, "ConfirmBtn", "SET",
        UDim2.new(1, -114, 0, timedBtnY), UDim2.new(0, 50, 0, 34),
        COLOR_CYAN, COLOR_BG, function()
            self:ConfirmSeed()
        end)

    makeButton(seedPanel, "RandomBtn", "RNG",
        UDim2.new(1, -60, 0, timedBtnY), UDim2.new(0, 48, 0, 34),
        COLOR_ORANGE, COLOR_WHITE, function()
            self:RandomSeed()
        end)
    timedBtnY = timedBtnY + 38

    self.seedStatusLabel = makeLabel(seedPanel, "Status", "",
        UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -24, 0, 20),
        Enum.Font.Gotham, COLOR_GREEN)
    timedBtnY = timedBtnY + 24

    makeButton(seedPanel, "CloseBtn", "CLOSE",
        UDim2.new(0, 12, 0, timedBtnY), UDim2.new(1, -24, 0, 36),
        Color3.fromRGB(50, 40, 55), COLOR_GRAY, function()
            self:CloseSeed()
        end)

    -- ==================== LEADERBOARD PANEL ====================
    local lbPanel = makeFrame(screenGui, "LeaderboardPanel",
        UDim2.new(0.5, -250, 0.5, -280), UDim2.new(0, 500, 0, 560),
        COLOR_PANEL, 0.05)
    addCorner(lbPanel, 12)
    addStroke(lbPanel, COLOR_GOLD, 2)
    lbPanel.Visible = false
    self.lbPanel = lbPanel

    makeLabel(lbPanel, "Title", "LEADERBOARD",
        UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 36),
        Enum.Font.GothamBold, COLOR_GOLD)

    -- Tab buttons
    self.lbTabTime = makeButton(lbPanel, "TabTime", "FASTEST TIMES",
        UDim2.new(0, 12, 0, 52), UDim2.new(0.5, -18, 0, 32),
        COLOR_GOLD, COLOR_BG, function()
            self:ShowLeaderboardTab("time")
        end)

    self.lbTabDepth = makeButton(lbPanel, "TabDepth", "BEST DEPTHS",
        UDim2.new(0.5, 6, 0, 52), UDim2.new(0.5, -18, 0, 32),
        Color3.fromRGB(60, 50, 30), COLOR_GOLD, function()
            self:ShowLeaderboardTab("depth")
        end)

    -- Entry list scroll frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "EntryScroll"
    scroll.Position = UDim2.new(0, 12, 0, 92)
    scroll.Size = UDim2.new(1, -24, 1, -140)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = lbPanel
    self.lbScroll = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = scroll

    makeButton(lbPanel, "CloseBtn", "CLOSE",
        UDim2.new(0, 12, 1, -48), UDim2.new(1, -24, 0, 36),
        Color3.fromRGB(50, 40, 55), COLOR_GRAY, function()
            self:CloseLeaderboard()
        end)

    -- ==================== PROMPT ====================
    -- Small floating prompt for portal/kiosk interaction
    self.promptLabel = makeLabel(screenGui, "Prompt", "",
        UDim2.new(0.5, -150, 0.75, 0), UDim2.new(0, 300, 0, 44),
        Enum.Font.GothamBold, COLOR_WHITE)
    local promptBG = screenGui:FindFirstChild("Prompt")
    if promptBG then
        promptBG.BackgroundColor3 = COLOR_BG
        promptBG.BackgroundTransparency = 0.3
        addCorner(promptBG, 8)
        promptBG.Visible = false
        self.promptLabel = promptBG
        self.promptText = makeLabel(promptBG, "Text", "",
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0),
            Enum.Font.GothamBold, COLOR_WHITE)
    end

    -- Current seed display in top bar
    self.seedBarLabel = makeLabel(topBar, "SeedBar",
        "SEED: 12345",
        UDim2.new(0.5, 90, 0, 2), UDim2.new(0, 160, 1, -4),
        Enum.Font.Code, COLOR_CYAN, Enum.TextXAlignment.Left)

    -- ==================== DROP TYPE TOGGLE ====================
    -- Persistent pill toggle anchored to bottom-center, above the prompt
    local dropToggle = makeFrame(screenGui, "DropTypeToggle",
        UDim2.new(0.5, -130, 1, -80), UDim2.new(0, 260, 0, 40),
        Color3.fromRGB(14, 12, 20), 0.15)
    addCorner(dropToggle, 10)
    addStroke(dropToggle, COLOR_GRAY, 1)
    self.dropToggle = dropToggle

    makeLabel(dropToggle, "Label", "CAMERA:",
        UDim2.new(0, 8, 0, 0), UDim2.new(0, 68, 1, 0),
        Enum.Font.Gotham, COLOR_GRAY, Enum.TextXAlignment.Left)

    self.fpsBtn = makeButton(dropToggle, "FPSBtn", "FIRST PERSON",
        UDim2.new(0, 76, 0, 4), UDim2.new(0, 86, 1, -8),
        Color3.fromRGB(255, 100, 30), COLOR_WHITE, function()
            self:SetDropType("fps")
        end)

    self.tpsBtn = makeButton(dropToggle, "TPSBtn", "THIRD PERSON",
        UDim2.new(0, 166, 0, 4), UDim2.new(0, 86, 1, -8),
        Color3.fromRGB(40, 40, 50), COLOR_GRAY, function()
            self:SetDropType("tps")
        end)

    -- ==================== OPTIONS PANEL ====================
    local optionsPanel = makeFrame(screenGui, "OptionsPanel",
        UDim2.new(0.5, -180, 0.5, -120), UDim2.new(0, 360, 0, 240),
        COLOR_PANEL, 0.05)
    addCorner(optionsPanel, 12)
    addStroke(optionsPanel, COLOR_ORANGE, 2)
    optionsPanel.Visible = false
    self.optionsPanel = optionsPanel

    makeLabel(optionsPanel, "Title", "OPTIONS",
        UDim2.new(0, 0, 0, 12), UDim2.new(1, 0, 0, 32),
        Enum.Font.GothamBold, COLOR_ORANGE)

    makeLabel(optionsPanel, "CamLabel", "DEFAULT CAMERA MODE",
        UDim2.new(0, 12, 0, 60), UDim2.new(1, -24, 0, 24),
        Enum.Font.GothamBold, COLOR_WHITE)

    self.optFpsBtn = makeButton(optionsPanel, "OptFPSBtn", "FIRST PERSON",
        UDim2.new(0.08, 0, 0, 96), UDim2.new(0.4, 0, 0, 44),
        Color3.fromRGB(255, 100, 30), COLOR_WHITE, function()
            self:SetDropType("fps")
        end)

    self.optTpsBtn = makeButton(optionsPanel, "OptTPSBtn", "THIRD PERSON",
        UDim2.new(0.52, 0, 0, 96), UDim2.new(0.4, 0, 0, 44),
        Color3.fromRGB(40, 40, 50), COLOR_GRAY, function()
            self:SetDropType("tps")
        end)

    makeButton(optionsPanel, "CloseBtn", "CLOSE",
        UDim2.new(0, 12, 1, -48), UDim2.new(1, -24, 0, 36),
        Color3.fromRGB(50, 40, 55), COLOR_GRAY, function()
            self:CloseOptions()
        end)

    self.lbEntries = {}
    self.lbMode = "time"
end

function HubUI:SetDropType(dt)
    self.dropType = dt
    if self.fpsBtn then
        self.fpsBtn.BackgroundColor3 = dt == "fps"
            and Color3.fromRGB(255, 100, 30)
            or  Color3.fromRGB(40, 40, 50)
        self.fpsBtn.TextColor3 = dt == "fps" and COLOR_WHITE or COLOR_GRAY
    end
    if self.tpsBtn then
        self.tpsBtn.BackgroundColor3 = dt == "tps"
            and Color3.fromRGB(60, 140, 255)
            or  Color3.fromRGB(40, 40, 50)
        self.tpsBtn.TextColor3 = dt == "tps" and COLOR_WHITE or COLOR_GRAY
    end
    if self.optFpsBtn then
        self.optFpsBtn.BackgroundColor3 = dt == "fps"
            and Color3.fromRGB(255, 100, 30)
            or  Color3.fromRGB(40, 40, 50)
        self.optFpsBtn.TextColor3 = dt == "fps" and COLOR_WHITE or COLOR_GRAY
    end
    if self.optTpsBtn then
        self.optTpsBtn.BackgroundColor3 = dt == "tps"
            and Color3.fromRGB(60, 140, 255)
            or  Color3.fromRGB(40, 40, 50)
        self.optTpsBtn.TextColor3 = dt == "tps" and COLOR_WHITE or COLOR_GRAY
    end

    -- Save to server and run camera trigger callback
    Networking.FireServer(Networking.Events.SaveCameraPreference, dt)
    if self.onChangeCamera then
        self.onChangeCamera(dt)
    end
end

function HubUI:OpenOptions()
    self.optionsOpen = true
    if self.optionsPanel then self.optionsPanel.Visible = true end
end

function HubUI:CloseOptions()
    self.optionsOpen = false
    if self.optionsPanel then self.optionsPanel.Visible = false end
end

function HubUI:GetDropType()
    return self.dropType or "fps"
end

-- ==================== SHOP LOGIC ====================

function HubUI:OpenShop(upgradeId)
    self.shopOpen = true
    self.shopUpgradeId = upgradeId
    self:RefreshShop()
    self.shopPanel.Visible = true
end

function HubUI:CloseShop()
    self.shopOpen = false
    self.shopPanel.Visible = false
end

function HubUI:RefreshShop()
    local upgradeId = self.shopUpgradeId
    if not upgradeId then return end
    local upg = UpgradeData.Upgrades[upgradeId]
    if not upg then return end
    local data = self.playerData
    local currentTier = (data and data.upgrades and data.upgrades[upgradeId]) or 0
    local gold = (data and data.gold) or 0
    local currentVal = UpgradeData.GetValue(upgradeId, currentTier)
    local nextVal = UpgradeData.GetValue(upgradeId, currentTier + 1)
    local cost = UpgradeData.GetUpgradeCost(upgradeId, currentTier)
    local maxed = currentTier >= upg.maxTier

    self.shopUpgradeName.Text = upg.displayName
    self.shopDescription.Text = upg.description
    self.shopCurrentLabel.Text = string.format("Current: %s %s", tostring(currentVal), upg.unit)
    self.shopNextLabel.Text = maxed and "MAXED OUT" or
        string.format("Next: %s %s", tostring(nextVal), upg.unit)
    self.shopTierLabel.Text = string.format("Tier: %d / %d", currentTier, upg.maxTier)
    self.shopTierBar.Size = UDim2.new(currentTier / upg.maxTier, 0, 1, 0)
    if maxed then
        self.shopCostLabel.Text = "FULLY UPGRADED"
        self.shopCostLabel.TextColor3 = COLOR_GREEN
        self.shopBuyBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        self.shopBuyBtn.Text = "MAXED"
    else
        self.shopCostLabel.Text = string.format("Cost: %d Gold", cost)
        self.shopCostLabel.TextColor3 = gold >= cost and COLOR_GOLD or COLOR_RED
        self.shopBuyBtn.BackgroundColor3 = gold >= cost and COLOR_ORANGE or Color3.fromRGB(60, 40, 40)
        self.shopBuyBtn.Text = "UPGRADE"
    end
    self.shopGoldLabel.Text = string.format("You have: %d Gold", gold)
end

function HubUI:PurchaseUpgrade()
    if not self.shopUpgradeId then return end
    Networking.FireServer(Networking.Events.PurchaseUpgrade, self.shopUpgradeId)
end

-- ==================== SEED LOGIC ====================

function HubUI:OpenSeed()
    self.seedOpen = true
    self.seedInput.Text = self.currentSeed
    self.seedStatusLabel.Text = ""
    -- Refresh timed seed button countdowns
    if self.timedSeedBtns then
        local timedData = TimedSeeds.GetAll()
        for i, entry in ipairs(self.timedSeedBtns) do
            local ts = timedData[i]
            if ts and entry.btn then
                entry.btn.Text = ts.label .. "  [" .. TimedSeeds.FormatCountdown(ts.countdown) .. "]"
                entry.seedData = ts
                -- Rebind click (update seed value captured in closure)
                entry.btn.MouseButton1Click:Connect(function()
                    self.seedInput.Text = ts.seed
                    self:ConfirmSeedText(ts.seed)
                end)
            end
        end
    end
    self.seedPanel.Visible = true
end

function HubUI:CloseSeed()
    self.seedOpen = false
    self.seedPanel.Visible = false
end

function HubUI:ConfirmSeed()
    local seed = self.seedInput.Text
    if seed == "" then seed = "MattyJacks" end
    self:ConfirmSeedText(seed)
end

function HubUI:ConfirmSeedText(seed)
    if not seed or seed == "" then seed = "MattyJacks" end
    seed = tostring(seed):sub(1, 32)
    self.currentSeed = seed
    if self.seedInput then self.seedInput.Text = seed end
    if self.seedStatusLabel then
        self.seedStatusLabel.Text = "Active: " .. seed
        self.seedStatusLabel.TextColor3 = COLOR_GREEN
    end
    if self.seedBarLabel then
        self.seedBarLabel.Text = "SEED: " .. seed
    end
end

function HubUI:RandomSeed()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local len = math.random(4, 10)
    local s = ""
    for i = 1, len do
        local idx = math.random(1, #chars)
        s = s .. chars:sub(idx, idx)
    end
    self.seedInput.Text = s
    self:ConfirmSeed()
end

-- ==================== LEADERBOARD LOGIC ====================

function HubUI:OpenLeaderboard()
    self.leaderboardOpen = true
    self.lbPanel.Visible = true
    Networking.FireServer(Networking.Events.RequestLeaderboard)
end

function HubUI:CloseLeaderboard()
    self.leaderboardOpen = false
    self.lbPanel.Visible = false
end

function HubUI:ShowLeaderboardTab(mode)
    self.lbMode = mode
    if mode == "time" then
        self.lbTabTime.BackgroundColor3 = COLOR_GOLD
        self.lbTabTime.TextColor3 = COLOR_BG
        self.lbTabDepth.BackgroundColor3 = Color3.fromRGB(60, 50, 30)
        self.lbTabDepth.TextColor3 = COLOR_GOLD
    else
        self.lbTabDepth.BackgroundColor3 = COLOR_GOLD
        self.lbTabDepth.TextColor3 = COLOR_BG
        self.lbTabTime.BackgroundColor3 = Color3.fromRGB(60, 50, 30)
        self.lbTabTime.TextColor3 = COLOR_GOLD
    end
    self:RefreshLeaderboard()
end

function HubUI:PopulateLeaderboard(times, depths)
    self.lbTimes = times
    self.lbDepths = depths
    self:RefreshLeaderboard()
end

function HubUI:RefreshLeaderboard()
    -- Clear existing
    for _, child in ipairs(self.lbScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local entries = self.lbMode == "time" and (self.lbTimes or {}) or (self.lbDepths or {})
    for i, entry in ipairs(entries) do
        local row = makeFrame(self.lbScroll, "Entry_" .. i,
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 36),
            i % 2 == 0 and Color3.fromRGB(25, 20, 30) or Color3.fromRGB(30, 25, 38), 0)
        row.LayoutOrder = i
        addCorner(row, 4)

        -- Rank
        local rankColor = i == 1 and COLOR_GOLD or (i == 2 and COLOR_GRAY or (i == 3 and COLOR_ORANGE or COLOR_WHITE))
        makeLabel(row, "Rank", string.format("#%d", entry.rank),
            UDim2.new(0, 6, 0, 0), UDim2.new(0, 40, 1, 0),
            Enum.Font.GothamBold, rankColor)

        -- Name
        makeLabel(row, "Name", entry.name or "Unknown",
            UDim2.new(0, 50, 0, 0), UDim2.new(0.55, 0, 1, 0),
            Enum.Font.Gotham, COLOR_WHITE, Enum.TextXAlignment.Left)

        -- Score
        local scoreText
        if self.lbMode == "time" and entry.timeSeconds then
            local cs = math.floor((entry.timeSeconds % 1) * 100)
            local s = math.floor(entry.timeSeconds) % 60
            local m = math.floor(entry.timeSeconds / 60)
            scoreText = string.format("%02d:%02d.%02d", m, s, cs)
        elseif entry.depthMeters then
            scoreText = string.format("%.1fm", entry.depthMeters)
        else
            scoreText = "---"
        end
        makeLabel(row, "Score", scoreText,
            UDim2.new(0.55, 0, 0, 0), UDim2.new(0.45, -6, 1, 0),
            Enum.Font.Code, COLOR_CYAN, Enum.TextXAlignment.Right)
    end

    if #entries == 0 then
        makeLabel(self.lbScroll, "Empty", "No records yet. Be the first!",
            UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 36),
            Enum.Font.Gotham, COLOR_GRAY)
    end
end

-- ==================== PROXIMITY DETECTION ====================

function HubUI:ShowPrompt(text)
    if self.promptLabel then
        self.promptLabel.Visible = true
        if self.promptText then self.promptText.Text = text end
    end
end

function HubUI:HidePrompt()
    if self.promptLabel then
        self.promptLabel.Visible = false
    end
end

-- ==================== DATA UPDATE ====================

function HubUI:UpdatePlayerData(data)
    self.playerData = data
    if data then
        if self.goldBarLabel then
            self.goldBarLabel.Text = string.format("GOLD: %d", data.gold or 0)
        end
        if self.bestTimeBarLabel then
            if data.bestTime then
                local t = data.bestTime
                local cs = math.floor((t % 1) * 100)
                local s = math.floor(t) % 60
                local m = math.floor(t / 60)
                self.bestTimeBarLabel.Text = string.format("BEST: %02d:%02d.%02d", m, s, cs)
            else
                self.bestTimeBarLabel.Text = "BEST: --:--.--"
            end
        end
        if data.defaultCamera then
            local dt = data.defaultCamera
            self.dropType = dt
            if self.fpsBtn then
                self.fpsBtn.BackgroundColor3 = dt == "fps" and Color3.fromRGB(255, 100, 30) or Color3.fromRGB(40, 40, 50)
                self.fpsBtn.TextColor3 = dt == "fps" and COLOR_WHITE or COLOR_GRAY
            end
            if self.tpsBtn then
                self.tpsBtn.BackgroundColor3 = dt == "tps" and Color3.fromRGB(60, 140, 255) or Color3.fromRGB(40, 40, 50)
                self.tpsBtn.TextColor3 = dt == "tps" and COLOR_WHITE or COLOR_GRAY
            end
            if self.optFpsBtn then
                self.optFpsBtn.BackgroundColor3 = dt == "fps" and Color3.fromRGB(255, 100, 30) or Color3.fromRGB(40, 40, 50)
                self.optFpsBtn.TextColor3 = dt == "fps" and COLOR_WHITE or COLOR_GRAY
            end
            if self.optTpsBtn then
                self.optTpsBtn.BackgroundColor3 = dt == "tps" and Color3.fromRGB(60, 140, 255) or Color3.fromRGB(40, 40, 50)
                self.optTpsBtn.TextColor3 = dt == "tps" and COLOR_WHITE or COLOR_GRAY
            end
            if self.onChangeCamera then
                self.onChangeCamera(dt)
            end
        end
    end
    if self.shopOpen then
        self:RefreshShop()
    end
end

function HubUI:UpdateGold(gold)
    if self.playerData then self.playerData.gold = gold end
    if self.goldBarLabel then
        self.goldBarLabel.Text = string.format("GOLD: %d", gold)
    end
    if self.shopOpen then self:RefreshShop() end
end

function HubUI:GetCurrentSeed()
    return self.currentSeed
end

function HubUI:GetCurrentModifier()
    return self.selectedModifier
end

-- ==================== MODIFIER PANEL ====================

function HubUI:BuildModifierPanel()
    local panel = makeFrame(self.gui, "ModifierPanel",
        UDim2.new(0.5, -280, 0.5, -260), UDim2.new(0, 560, 0, 520),
        Color3.fromRGB(14, 12, 20), 0.05)
    addCorner(panel, 14)
    addStroke(panel, Color3.fromRGB(80, 60, 120), 2)
    panel.Visible = false
    self.modifierPanel = panel

    makeLabel(panel, "Title", "CHOOSE RUN MODIFIER",
        UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 36),
        Enum.Font.GothamBold, COLOR_GOLD)

    local closeBtn = makeButton(panel, "Close", "X",
        UDim2.new(1, -38, 0, 8), UDim2.new(0, 30, 0, 30),
        COLOR_RED, COLOR_WHITE, function() self:CloseModifier() end)

    -- Modifier buttons
    local yOffset = 52
    local modHeight = 76
    local modGap = 8
    self.modifierButtons = {}

    for _, modId in ipairs(GameData.ModifierList) do
        local mod = GameData.RunModifiers[modId]
        local btnFrame = makeFrame(panel, modId .. "Frame",
            UDim2.new(0, 12, 0, yOffset), UDim2.new(1, -24, 0, modHeight),
            Color3.fromRGB(22, 18, 32), 0)
        addCorner(btnFrame, 10)
        addStroke(btnFrame, mod.color, 1)

        makeLabel(btnFrame, "Name", mod.displayName,
            UDim2.new(0, 10, 0, 4), UDim2.new(0.4, 0, 0.45, 0),
            Enum.Font.GothamBold, mod.color)
        makeLabel(btnFrame, "Desc", mod.description,
            UDim2.new(0, 10, 0.45, 0), UDim2.new(0.85, 0, 0.55, -4),
            Enum.Font.Gotham, COLOR_GRAY, Enum.TextXAlignment.Left)

        local selBtn = makeButton(btnFrame, "Select", "SELECT",
            UDim2.new(1, -88, 0.15, 0), UDim2.new(0, 80, 0.7, 0),
            Color3.fromRGB(30, 26, 42), COLOR_WHITE, function()
                self:SelectModifier(modId)
            end)
        self.modifierButtons[modId] = { frame = btnFrame, btn = selBtn }
        yOffset = yOffset + modHeight + modGap
    end

    self:RefreshModifierButtons()
end

function HubUI:RefreshModifierButtons()
    for modId, entry in pairs(self.modifierButtons or {}) do
        local mod = GameData.RunModifiers[modId]
        local isSelected = modId == self.selectedModifier
        entry.frame.BackgroundColor3 = isSelected
            and Color3.fromRGB(30, 22, 50)
            or Color3.fromRGB(22, 18, 32)
        addStroke(entry.frame, isSelected and mod.color or Color3.fromRGB(50, 45, 65), isSelected and 2 or 1)
        entry.btn.BackgroundColor3 = isSelected and mod.color or Color3.fromRGB(40, 35, 55)
        entry.btn.Text = isSelected and "ACTIVE" or "SELECT"
    end
end

function HubUI:SelectModifier(modId)
    self.selectedModifier = modId
    Networking.FireServer(Networking.Events.SetModifier, modId)
    self:RefreshModifierButtons()
end

function HubUI:OpenModifier()
    if not self.modifierPanel then self:BuildModifierPanel() end
    self.modifierOpen = true
    self.modifierPanel.Visible = true
end

function HubUI:CloseModifier()
    self.modifierOpen = false
    if self.modifierPanel then
        self.modifierPanel.Visible = false
    end
end

-- ==================== GAME MODE + LOBBY ====================

function HubUI:BuildLobbyPanel()
    local panel = makeFrame(self.gui, "LobbyPanel",
        UDim2.new(0.5, -240, 0.5, -220), UDim2.new(0, 480, 0, 440),
        Color3.fromRGB(12, 10, 18), 0.05)
    addCorner(panel, 14)
    addStroke(panel, Color3.fromRGB(60, 140, 255), 2)
    panel.Visible = false
    self.lobbyPanel = panel

    makeLabel(panel, "Title", "GAME MODE & LOBBY",
        UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 36),
        Enum.Font.GothamBold, COLOR_WHITE)

    makeButton(panel, "CloseBtn", "X",
        UDim2.new(1, -38, 0, 8), UDim2.new(0, 30, 0, 30),
        COLOR_RED, COLOR_WHITE, function() self:CloseLobby() end)

    -- 3 mode buttons
    local modeOrder = { "Singleplayer", "Cooperative", "Competitive" }
    local modeColors = {
        Singleplayer = Color3.fromRGB(80, 200, 255),
        Cooperative  = Color3.fromRGB(60, 210, 80),
        Competitive  = Color3.fromRGB(220, 60, 40),
    }
    self.modeBtns = {}
    for i, modeId in ipairs(modeOrder) do
        local mode = GameMode.Modes[modeId]
        local xOff = 10 + (i - 1) * 153
        local mFrame = makeFrame(panel, modeId .. "Frame",
            UDim2.new(0, xOff, 0, 50), UDim2.new(0, 150, 0, 80),
            Color3.fromRGB(22, 18, 32), 0)
        addCorner(mFrame, 10)
        addStroke(mFrame, modeColors[modeId], 1)

        makeLabel(mFrame, "Name", mode.displayName,
            UDim2.new(0, 4, 0, 4), UDim2.new(1, -8, 0.45, 0),
            Enum.Font.GothamBold, modeColors[modeId])
        makeLabel(mFrame, "Desc", mode.description,
            UDim2.new(0, 4, 0.45, 2), UDim2.new(1, -8, 0.55, -4),
            Enum.Font.Gotham, COLOR_GRAY)

        local capturedId = modeId
        local btn = makeButton(mFrame, "Btn", "SELECT",
            UDim2.new(0.05, 0, 1, -32), UDim2.new(0.9, 0, 0, 26),
            Color3.fromRGB(40, 36, 55), COLOR_WHITE, function()
                self:SetGameMode(capturedId)
            end)
        self.modeBtns[modeId] = { frame = mFrame, btn = btn, color = modeColors[modeId] }
    end

    -- Join a lobby by host UserId input
    makeLabel(panel, "JoinLabel", "JOIN LOBBY (enter host's Player ID):",
        UDim2.new(0, 10, 0, 140), UDim2.new(1, -20, 0, 20),
        Enum.Font.Gotham, COLOR_GRAY, Enum.TextXAlignment.Left)
    self.joinInput = makeInput(panel, "JoinInput", "Host Player ID...",
        UDim2.new(0, 10, 0, 162), UDim2.new(0.65, -5, 0, 32))
    makeButton(panel, "JoinBtn", "JOIN",
        UDim2.new(0.65, 5, 0, 162), UDim2.new(0.35, -10, 0, 32),
        Color3.fromRGB(40, 80, 160), COLOR_WHITE, function()
            local hostId = tonumber(self.joinInput and self.joinInput.Text)
            if hostId then
                Networking.FireServer(Networking.Events.RequestJoinSession, hostId)
            end
        end)
    makeButton(panel, "LeaveBtn", "LEAVE LOBBY",
        UDim2.new(0, 10, 0, 200), UDim2.new(0.45, -5, 0, 28),
        Color3.fromRGB(80, 30, 30), COLOR_GRAY, function()
            Networking.FireServer(Networking.Events.LeaveSession)
            self:ClearLobbyMembers()
        end)

    -- Members list
    makeLabel(panel, "MembersLabel", "LOBBY MEMBERS:",
        UDim2.new(0, 10, 0, 238), UDim2.new(1, -20, 0, 20),
        Enum.Font.GothamBold, COLOR_WHITE, Enum.TextXAlignment.Left)
    local membersScroll = Instance.new("ScrollingFrame")
    membersScroll.Name = "MembersScroll"
    membersScroll.Position = UDim2.new(0, 10, 0, 260)
    membersScroll.Size = UDim2.new(1, -20, 0, 120)
    membersScroll.BackgroundTransparency = 1
    membersScroll.ScrollBarThickness = 3
    membersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    membersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    membersScroll.Parent = panel
    local ml = Instance.new("UIListLayout")
    ml.SortOrder = Enum.SortOrder.LayoutOrder
    ml.Padding = UDim.new(0, 3)
    ml.Parent = membersScroll
    self.membersScroll = membersScroll

    -- Player ID display (so others can join you)
    local myId = tostring(Players.LocalPlayer.UserId)
    makeLabel(panel, "MyIdLabel", "YOUR PLAYER ID: " .. myId,
        UDim2.new(0, 10, 1, -44), UDim2.new(1, -20, 0, 18),
        Enum.Font.Code, COLOR_CYAN, Enum.TextXAlignment.Left)

    -- Start button (only meaningful as host)
    self.lobbyStartBtn = makeButton(panel, "StartBtn", "START RUN",
        UDim2.new(0.5, -80, 1, -40), UDim2.new(0, 160, 0, 34),
        COLOR_GREEN, Color3.fromRGB(10, 30, 10), function()
            self:CloseLobby()
            -- enterLevel is wired in main.client.lua via a callback
            if self.onStartRun then self.onStartRun() end
        end)

    self:RefreshModeBtns()
end

function HubUI:RefreshModeBtns()
    for modeId, entry in pairs(self.modeBtns or {}) do
        local isActive = modeId == self.gameModeId
        entry.frame.BackgroundColor3 = isActive
            and Color3.fromRGB(28, 24, 42)
            or  Color3.fromRGB(18, 14, 26)
        local stroke = entry.frame:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Thickness = isActive and 2 or 1 end
        entry.btn.BackgroundColor3 = isActive and entry.color or Color3.fromRGB(40, 36, 55)
        entry.btn.Text = isActive and "ACTIVE" or "SELECT"
    end
end

function HubUI:SetGameMode(modeId)
    self.gameModeId = modeId
    Networking.FireServer(Networking.Events.SetGameMode, modeId)
    self:RefreshModeBtns()
end

function HubUI:GetGameMode()
    return self.gameModeId or "Singleplayer"
end

function HubUI:OpenLobby(onStartRun)
    if not self.lobbyPanel then self:BuildLobbyPanel() end
    self.onStartRun = onStartRun
    self.lobbyOpen = true
    self.lobbyPanel.Visible = true
    self:RefreshModeBtns()
end

function HubUI:CloseLobby()
    self.lobbyOpen = false
    if self.lobbyPanel then self.lobbyPanel.Visible = false end
end

function HubUI:ClearLobbyMembers()
    if not self.membersScroll then return end
    for _, c in ipairs(self.membersScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

-- Called by main.client.lua on LobbyUpdate event
function HubUI:OnLobbyUpdate(data)
    if not data then return end
    self.lobbyData = data
    -- Update mode if server reported it
    if data.modeId then
        self.gameModeId = data.modeId
        self:RefreshModeBtns()
    end
    -- Rebuild members list
    if not self.membersScroll then return end
    self:ClearLobbyMembers()
    if not data.members then return end
    local myId = Players.LocalPlayer.UserId
    local isHost = (data.hostUserId == myId)
    if self.lobbyStartBtn then
        self.lobbyStartBtn.Visible = isHost
    end
    for i, m in ipairs(data.members) do
        local rowBg = (i % 2 == 0)
            and Color3.fromRGB(22, 18, 30)
            or  Color3.fromRGB(28, 24, 36)
        local row = makeFrame(self.membersScroll, "Member_" .. i,
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), rowBg, 0)
        row.LayoutOrder = i
        addCorner(row, 4)
        local isMe = (m.userId == myId)
        local nameText = m.name .. (isMe and " (you)" or "")
            .. (m.userId == data.hostUserId and " [HOST]" or "")
        makeLabel(row, "Name", nameText,
            UDim2.new(0, 6, 0, 0), UDim2.new(1, -12, 1, 0),
            Enum.Font.Gotham, isMe and COLOR_CYAN or COLOR_WHITE,
            Enum.TextXAlignment.Left)
    end
end

function HubUI:SetVisible(visible)
    if self.gui then
        self.gui.Enabled = visible
    end
end

function HubUI:Destroy()
    if self.gui then
        self.gui:Destroy()
        self.gui = nil
    end
end

return HubUI
