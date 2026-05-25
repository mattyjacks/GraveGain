-- DwarfDrop: hub_ui.lua
-- Hub area UI: upgrade shop, seed kiosk, leaderboard, modifier picker, lobby

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)
local UpgradeData = require(game.ReplicatedStorage.Shared.upgrade_data)
local TimedSeeds  = require(game.ReplicatedStorage.Shared.timed_seeds)
local GameMode    = require(game.ReplicatedStorage.Shared.game_mode)

local HubUI = {}
HubUI.__index = HubUI

local COLOR_BG      = Color3.fromRGB(10, 8, 16)
local COLOR_ACCENT  = Color3.fromRGB(120, 80, 220)
local COLOR_GOLD    = Color3.fromRGB(255, 210, 40)
local COLOR_WHITE   = Color3.new(1, 1, 1)
local COLOR_DIM     = Color3.fromRGB(160, 155, 180)
local COLOR_GREEN   = Color3.fromRGB(60, 210, 80)
local COLOR_RED     = Color3.fromRGB(210, 60, 60)

local function makeFrame(parent, name, pos, size, bgColor, bgTrans)
    local f = Instance.new("Frame")
    f.Name = name; f.Position = pos; f.Size = size
    f.BackgroundColor3 = bgColor or COLOR_BG
    f.BackgroundTransparency = bgTrans or 0.08
    f.BorderSizePixel = 0; f.Parent = parent; return f
end

local function makeLabel(parent, name, text, pos, size, font, color)
    local l = Instance.new("TextLabel")
    l.Name = name; l.Text = text; l.Position = pos; l.Size = size
    l.BackgroundTransparency = 1; l.TextColor3 = color or COLOR_WHITE
    l.Font = font or Enum.Font.GothamBold; l.TextScaled = true; l.Parent = parent; return l
end

local function makeBtn(parent, name, text, pos, size, bgColor, callback)
    local b = Instance.new("TextButton")
    b.Name = name; b.Text = text; b.Position = pos; b.Size = size
    b.BackgroundColor3 = bgColor or COLOR_ACCENT
    b.BackgroundTransparency = 0.1; b.BorderSizePixel = 0
    b.TextColor3 = COLOR_WHITE; b.Font = Enum.Font.GothamBold
    b.TextScaled = true; b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
    if callback then
        b.MouseButton1Click:Connect(callback)
        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency = 0.1 end)
    end; return b
end

local function addCorner(f, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = f; return c
end

local function addStroke(f, color, thick)
    local s = Instance.new("UIStroke"); s.Color = color or COLOR_ACCENT; s.Thickness = thick or 1; s.Parent = f; return s
end

local function addScrollFrame(parent, name, pos, size)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name; sf.Position = pos; sf.Size = size
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 5; sf.ScrollBarImageColor3 = COLOR_ACCENT
    sf.Parent = parent
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0,6); layout.Parent = sf
    return sf, layout
end

function HubUI.new()
    local self = setmetatable({}, HubUI)
    self.player      = Players.LocalPlayer
    self.gui         = nil
    self.playerData  = nil
    self.activePanel = nil
    self.cameraMode  = "fps"
    return self
end

function HubUI:Build()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DwarfDropHubUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 20
    screenGui.Parent = self.player.PlayerGui
    self.gui = screenGui

    -- Background overlay for panels
    self.overlay = makeFrame(screenGui, "Overlay", UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), Color3.new(0,0,0), 1)
    self.overlay.Visible = false

    -- Gold display
    self.goldDisplay = makeFrame(screenGui, "GoldDisplay", UDim2.new(0.5,-100,0,12), UDim2.new(0,200,0,38), COLOR_BG, 0.2)
    addCorner(self.goldDisplay, 10)
    self.goldLabel = makeLabel(self.goldDisplay, "Gold", "GOLD: 0", UDim2.new(0,8,0,0), UDim2.new(1,-16,1,0), Enum.Font.GothamBold, COLOR_GOLD)
    self.goldLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.bestTimeLabel = makeLabel(self.goldDisplay, "BestTime", "Best: --", UDim2.new(0,8,0.5,0), UDim2.new(1,-16,0.5,-2), Enum.Font.Gotham, COLOR_DIM)
    self.bestTimeLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.bestTimeLabel.TextScaled = false; self.bestTimeLabel.TextSize = 11

    -- Proximity prompt label (center bottom)
    self.promptLabel = makeLabel(screenGui, "PromptLabel", "", UDim2.new(0.2,0,0.88,0), UDim2.new(0.6,0,0.06,0), Enum.Font.GothamBold, COLOR_WHITE)
    self.promptLabel.BackgroundColor3 = Color3.fromRGB(20,16,36)
    self.promptLabel.BackgroundTransparency = 0.3
    self.promptLabel.TextScaled = false; self.promptLabel.TextSize = 14
    addCorner(self.promptLabel, 8); self.promptLabel.Visible = false

    -- Camera toggle (top right)
    local camBtn = makeBtn(screenGui, "CamToggle", "CAM: FPS", UDim2.new(1,-148,0,12), UDim2.new(0,138,0,36), Color3.fromRGB(40,38,60), function()
        self:ToggleCameraMode()
    end)
    addCorner(camBtn, 10); self.camToggleBtn = camBtn

    -- Build sub-panels
    self:BuildUpgradePanel()
    self:BuildSeedPanel()
    self:BuildLeaderboardPanel()
    self:BuildModifierPanel()
    self:BuildLobbyPanel()

    -- Request player data
    local rf = Networking.GetFunction(Networking.Functions.GetPlayerData)
    if rf then
        task.spawn(function()
            local data = rf:InvokeServer()
            if data then self:SetPlayerData(data) end
        end)
    end

    -- Listen for remote updates
    Networking.OnClient(Networking.Events.GoldUpdate, function(amount)
        if self.goldLabel then self.goldLabel.Text = string.format("GOLD: %d", amount) end
    end)

    Networking.OnClient(Networking.Events.LeaderboardUpdate, function(data)
        self:UpdateLeaderboard(data)
    end)

    Networking.OnClient(Networking.Events.LobbyUpdate, function(lobbyData)
        self:UpdateLobby(lobbyData)
    end)

    return self
end

-- ==================== UPGRADE PANEL ====================

function HubUI:BuildUpgradePanel()
    local panel = makeFrame(self.gui, "UpgradePanel",
        UDim2.new(0.5,-340,0.5,-280), UDim2.new(0,680,0,560),
        COLOR_BG, 0.06)
    addCorner(panel, 14); addStroke(panel)
    panel.Visible = false; self.upgradePanel = panel

    makeLabel(panel, "Title", "UPGRADE SHOP", UDim2.new(0,0,0,12), UDim2.new(1,0,0,32), Enum.Font.GothamBold, COLOR_ACCENT)
    makeBtn(panel, "Close", "X", UDim2.new(1,-46,0,10), UDim2.new(0,36,0,28), COLOR_RED, function() self:ClosePanel() end)

    local scroll, _ = addScrollFrame(panel, "Scroll", UDim2.new(0,10,0,56), UDim2.new(1,-20,1,-66))

    local upgradeOrder = { "max_health","heal_rate","move_speed","fall_resist","coin_magnet","double_jump" }
    self.upgradeRows = {}

    for _, id in ipairs(upgradeOrder) do
        local def = UpgradeData.Upgrades[id]
        if not def then continue end

        local row = makeFrame(scroll, "Row_"..id, UDim2.new(0,0,0,0), UDim2.new(1,-6,0,72), Color3.fromRGB(20,18,30), 0.2)
        addCorner(row, 8)
        scroll.CanvasSize = UDim2.new(0,0,0,0)

        makeLabel(row, "Name", def.displayName, UDim2.new(0,8,0,6), UDim2.new(0.35,0,0.4,0), Enum.Font.GothamBold, COLOR_WHITE)
        local descLbl = makeLabel(row, "Desc", def.description, UDim2.new(0,8,0.46,0), UDim2.new(0.6,0,0.38,0), Enum.Font.Gotham, COLOR_DIM)
        descLbl.TextScaled = false; descLbl.TextSize = 11

        local valLbl = makeLabel(row, "Val", "Tier 0", UDim2.new(0.38,0,0,6), UDim2.new(0.24,0,0.4,0), Enum.Font.GothamBold, COLOR_GREEN)
        local costLbl = makeLabel(row, "Cost", "---", UDim2.new(0.38,0,0.46,0), UDim2.new(0.24,0,0.38,0), Enum.Font.Gotham, COLOR_GOLD)
        costLbl.TextScaled = false; costLbl.TextSize = 11

        local buyBtn = makeBtn(row, "Buy", "UPGRADE", UDim2.new(0.65,0,0.12,0), UDim2.new(0.32,0,0.76,0), COLOR_ACCENT, function()
            Networking.FireServer(Networking.Events.PurchaseUpgrade, id)
            task.delay(0.2, function()
                local rf = Networking.GetFunction(Networking.Functions.GetPlayerData)
                if rf then
                    local data = rf:InvokeServer()
                    if data then self:SetPlayerData(data) end
                end
            end)
        end)

        self.upgradeRows[id] = { valLbl = valLbl, costLbl = costLbl, buyBtn = buyBtn }
    end
end

function HubUI:UpdateUpgradeRows(upgrades, gold)
    if not self.upgradeRows then return end
    for id, row in pairs(self.upgradeRows) do
        local def = UpgradeData.Upgrades[id]
        if not def then continue end
        local tier = (upgrades and upgrades[id]) or 0
        local val  = UpgradeData.GetValue(id, tier)
        local cost = UpgradeData.GetUpgradeCost(id, tier)
        row.valLbl.Text  = string.format("Tier %d | %g%s", tier, val, def.unit or "")
        if cost == math.huge then
            row.costLbl.Text = "MAXED"
            row.costLbl.TextColor3 = COLOR_GREEN
            row.buyBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
            row.buyBtn.Active = false
        else
            row.costLbl.Text = string.format("%d G", cost)
            local canAfford = (gold or 0) >= cost
            row.costLbl.TextColor3 = canAfford and COLOR_GOLD or COLOR_RED
            row.buyBtn.BackgroundColor3 = canAfford and COLOR_ACCENT or Color3.fromRGB(60,30,30)
            row.buyBtn.Active = canAfford
        end
    end
end

-- ==================== SEED PANEL ====================

function HubUI:BuildSeedPanel()
    local panel = makeFrame(self.gui, "SeedPanel",
        UDim2.new(0.5,-220,0.5,-220), UDim2.new(0,440,0,440),
        COLOR_BG, 0.06)
    addCorner(panel, 14); addStroke(panel)
    panel.Visible = false; self.seedPanel = panel

    makeLabel(panel, "Title", "SEED SELECTION", UDim2.new(0,0,0,10), UDim2.new(1,0,0,30), Enum.Font.GothamBold, COLOR_ACCENT)
    makeBtn(panel, "Close", "X", UDim2.new(1,-46,0,8), UDim2.new(0,36,0,26), COLOR_RED, function() self:ClosePanel() end)

    -- Custom seed input
    makeLabel(panel, "CustomTitle", "Custom Seed", UDim2.new(0,14,0,48), UDim2.new(0.4,0,0,24), Enum.Font.GothamBold, COLOR_WHITE)
    local box = Instance.new("TextBox")
    box.Name = "SeedBox"; box.Position = UDim2.new(0,14,0,76); box.Size = UDim2.new(1,-28,0,38)
    box.BackgroundColor3 = Color3.fromRGB(20,18,30); box.BackgroundTransparency = 0.1
    box.TextColor3 = COLOR_WHITE; box.Font = Enum.Font.Code; box.PlaceholderText = "Enter seed..."
    box.Text = ""; box.TextScaled = true; box.BorderSizePixel = 0; box.ClearTextOnFocus = false
    box.Parent = panel; addCorner(box, 6); self.seedBox = box

    makeBtn(panel, "ApplyCustom", "USE SEED", UDim2.new(0,14,0,122), UDim2.new(1,-28,0,36), COLOR_ACCENT, function()
        local seed = box.Text
        if seed and #seed > 0 then
            self.pendingSeed = seed
            self:ShowPrompt("Seed set: "..seed)
        end
    end)

    -- Timed seeds
    makeLabel(panel, "TimedTitle", "Timed Seeds", UDim2.new(0,14,0,172), UDim2.new(1,-28,0,24), Enum.Font.GothamBold, COLOR_ACCENT)

    local timedSeeds = TimedSeeds.GetAll()
    for i, ts in ipairs(timedSeeds) do
        local yOff = 200 + (i-1)*62
        local tsFrame = makeFrame(panel, "TimedSeed"..i, UDim2.new(0,14,0,yOff), UDim2.new(1,-28,0,54), Color3.fromRGB(20,18,30), 0.2)
        addCorner(tsFrame, 8)
        makeLabel(tsFrame,"Label", ts.label, UDim2.new(0,8,0,4), UDim2.new(0.55,0,0.45,0), Enum.Font.GothamBold, COLOR_WHITE)
        makeLabel(tsFrame,"Seed", ts.seed, UDim2.new(0,8,0.46,0), UDim2.new(0.7,0,0.45,0), Enum.Font.Code, COLOR_DIM)
        local cd = TimedSeeds.FormatCountdown(ts.countdown)
        makeLabel(tsFrame,"Countdown","Resets: "..cd, UDim2.new(0.56,0,0.4,0), UDim2.new(0.44,-10,0.5,0), Enum.Font.Gotham, COLOR_DIM)
        local useSeed = ts.seed
        makeBtn(tsFrame, "Use", "USE", UDim2.new(1,-64,0.08,0), UDim2.new(0,54,0.84,0), COLOR_ACCENT, function()
            self.pendingSeed = useSeed
            self:ShowPrompt("Timed seed set!")
        end)
    end

    -- Random seed
    makeBtn(panel, "Random", "RANDOM SEED", UDim2.new(0,14,1,-56), UDim2.new(1,-28,0,38), Color3.fromRGB(40,60,100), function()
        local seed = tostring(math.floor(math.random()*99999999 + 1))
        box.Text = seed; self.pendingSeed = seed
        self:ShowPrompt("Seed: "..seed)
    end)
end

-- ==================== LEADERBOARD PANEL ====================

function HubUI:BuildLeaderboardPanel()
    local panel = makeFrame(self.gui, "LeaderboardPanel",
        UDim2.new(0.5,-300,0.5,-280), UDim2.new(0,600,0,560),
        COLOR_BG, 0.06)
    addCorner(panel, 14); addStroke(panel)
    panel.Visible = false; self.leaderboardPanel = panel

    makeLabel(panel, "Title", "LEADERBOARD", UDim2.new(0,0,0,10), UDim2.new(1,0,0,30), Enum.Font.GothamBold, COLOR_ACCENT)
    makeBtn(panel, "Close", "X", UDim2.new(1,-46,0,8), UDim2.new(0,36,0,26), COLOR_RED, function() self:ClosePanel() end)

    -- Tab buttons
    local tabTimes  = makeBtn(panel, "TabTimes",  "FASTEST TIMES",   UDim2.new(0,10,0,44), UDim2.new(0.46,0,0,30), COLOR_ACCENT, function() self.lbTab = "times";  self:RefreshLeaderboard() end)
    local tabDepths = makeBtn(panel, "TabDepths", "GREATEST DEPTHS", UDim2.new(0.52,0,0,44), UDim2.new(0.48,-10,0,30), Color3.fromRGB(40,38,60), function() self.lbTab = "depths"; self:RefreshLeaderboard() end)
    self.lbTabBtns = { times = tabTimes, depths = tabDepths }
    self.lbTab = "times"

    local scroll = addScrollFrame(panel, "Scroll", UDim2.new(0,10,0,82), UDim2.new(1,-20,1,-92))
    self.lbScroll = scroll

    makeBtn(panel, "Refresh", "REFRESH", UDim2.new(0.3,0,1,-52), UDim2.new(0.4,0,0,36), Color3.fromRGB(30,28,50), function()
        Networking.FireServer(Networking.Events.RequestLeaderboard)
    end)
end

function HubUI:UpdateLeaderboard(data)
    self.lbData = data
    self:RefreshLeaderboard()
end

function HubUI:RefreshLeaderboard()
    if not self.lbScroll then return end
    for _, child in ipairs(self.lbScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
    local data = self.lbData
    if not data then return end
    local entries = (self.lbTab == "times") and data.times or data.depths
    if not entries then return end
    for _, entry in ipairs(entries) do
        local row = makeFrame(self.lbScroll, "LBRow", UDim2.new(0,0,0,0), UDim2.new(1,-4,0,40), Color3.fromRGB(18,16,28), 0.2)
        addCorner(row, 6)
        local rankLabel = makeLabel(row,"Rank","#"..entry.rank, UDim2.new(0,8,0,0), UDim2.new(0.12,0,1,0), Enum.Font.GothamBold, COLOR_GOLD)
        local nameLabel = makeLabel(row,"Name",entry.name or "Unknown", UDim2.new(0.14,0,0,0), UDim2.new(0.5,0,1,0), Enum.Font.Gotham, COLOR_WHITE)
        local valLabel  = makeLabel(row,"Val","", UDim2.new(0.66,0,0,0), UDim2.new(0.34,-8,1,0), Enum.Font.Code, COLOR_ACCENT)
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        if self.lbTab == "times" and entry.timeSeconds then
            local t = entry.timeSeconds; local cs = math.floor((t%1)*100); local s = math.floor(t)%60; local m = math.floor(t/60)
            valLabel.Text = string.format("%02d:%02d.%02d", m, s, cs)
        elseif self.lbTab == "depths" and entry.depthMeters then
            valLabel.Text = string.format("%.0fm", entry.depthMeters)
        end
    end
    self.lbScroll.CanvasSize = UDim2.new(0,0,0, #entries * 46)
end

-- ==================== MODIFIER PANEL ====================

function HubUI:BuildModifierPanel()
    local panel = makeFrame(self.gui, "ModifierPanel",
        UDim2.new(0.5,-250,0.5,-200), UDim2.new(0,500,0,400),
        COLOR_BG, 0.06)
    addCorner(panel, 14); addStroke(panel)
    panel.Visible = false; self.modifierPanel = panel

    makeLabel(panel, "Title", "RUN MODIFIER", UDim2.new(0,0,0,10), UDim2.new(1,0,0,30), Enum.Font.GothamBold, COLOR_ACCENT)
    makeBtn(panel, "Close", "X", UDim2.new(1,-46,0,8), UDim2.new(0,36,0,26), COLOR_RED, function() self:ClosePanel() end)

    local scroll, _ = addScrollFrame(panel, "Scroll", UDim2.new(0,10,0,46), UDim2.new(1,-20,1,-56))

    for _, modId in ipairs(GameData.ModifierList) do
        local mod = GameData.RunModifiers[modId]
        local row = makeFrame(scroll,"ModRow_"..modId, UDim2.new(0,0,0,0), UDim2.new(1,-4,0,72), Color3.fromRGB(18,16,28), 0.2)
        addCorner(row, 8)
        local nLbl = makeLabel(row,"Name",mod.displayName, UDim2.new(0,8,0,6), UDim2.new(0.45,0,0.45,0), Enum.Font.GothamBold, mod.color or COLOR_WHITE)
        local dLbl = makeLabel(row,"Desc",mod.description, UDim2.new(0,8,0.48,0), UDim2.new(0.6,0,0.46,0), Enum.Font.Gotham, COLOR_DIM)
        dLbl.TextScaled = false; dLbl.TextSize = 10
        local capModId = modId
        makeBtn(row, "Select", "SELECT", UDim2.new(0.65,0,0.1,0), UDim2.new(0.32,0,0.8,0), Color3.fromRGB(40,38,60), function()
            Networking.FireServer(Networking.Events.SetModifier, capModId)
            self.selectedModifier = capModId
            self:ShowPrompt("Modifier: "..mod.displayName)
            self:ClosePanel()
        end)
    end
    scroll.CanvasSize = UDim2.new(0,0,0, #GameData.ModifierList * 78)
end

-- ==================== LOBBY PANEL ====================

function HubUI:BuildLobbyPanel()
    local panel = makeFrame(self.gui, "LobbyPanel",
        UDim2.new(0.5,-240,0.5,-200), UDim2.new(0,480,0,400),
        COLOR_BG, 0.06)
    addCorner(panel, 14); addStroke(panel)
    panel.Visible = false; self.lobbyPanel = panel

    makeLabel(panel, "Title", "MULTIPLAYER LOBBY", UDim2.new(0,0,0,10), UDim2.new(1,0,0,30), Enum.Font.GothamBold, COLOR_ACCENT)
    makeBtn(panel, "Close", "X", UDim2.new(1,-46,0,8), UDim2.new(0,36,0,26), COLOR_RED, function() self:ClosePanel() end)

    self.lobbyMembersList = makeFrame(panel, "Members", UDim2.new(0,10,0,48), UDim2.new(1,-20,0,140), Color3.fromRGB(14,12,22), 0.2)
    addCorner(self.lobbyMembersList, 8)
    self.lobbyMembersLabel = makeLabel(self.lobbyMembersList, "Members", "(no lobby)", UDim2.new(0,8,0,6), UDim2.new(1,-16,1,-12), Enum.Font.Gotham, COLOR_DIM)
    self.lobbyMembersLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.lobbyMembersLabel.TextScaled = false; self.lobbyMembersLabel.TextSize = 12

    local modeY = 196
    for _, modeId in ipairs(GameMode.ModeList) do
        local mode = GameMode.Modes[modeId]
        local captureId = modeId
        makeBtn(panel, "Mode_"..modeId, modeId.." ("..mode.maxPlayers.."P max)", UDim2.new(0,10,0,modeY), UDim2.new(1,-20,0,38), Color3.fromRGB(30,28,50), function()
            Networking.FireServer(Networking.Events.SetGameMode, captureId)
        end)
        modeY = modeY + 44
    end

    -- Join by player name
    local joinBox = Instance.new("TextBox")
    joinBox.Name = "JoinBox"; joinBox.Position = UDim2.new(0,10,0,modeY+4); joinBox.Size = UDim2.new(0.6,-6,0,36)
    joinBox.BackgroundColor3 = Color3.fromRGB(20,18,30); joinBox.BackgroundTransparency = 0.1
    joinBox.TextColor3 = COLOR_WHITE; joinBox.Font = Enum.Font.GothamBold
    joinBox.PlaceholderText = "Host username..."; joinBox.Text = ""
    joinBox.TextScaled = true; joinBox.BorderSizePixel = 0
    joinBox.Parent = panel; addCorner(joinBox, 6); self.joinBox = joinBox

    makeBtn(panel, "JoinBtn", "JOIN", UDim2.new(0.62,0,0,modeY+4), UDim2.new(0.38,-10,0,36), COLOR_ACCENT, function()
        if self.joinBox and #self.joinBox.Text > 0 then
            Networking.FireServer(Networking.Events.RequestJoinSession, self.joinBox.Text)
        end
    end)

    makeBtn(panel, "LeaveBtn", "LEAVE LOBBY", UDim2.new(0,10,1,-52), UDim2.new(1,-20,0,38), COLOR_RED, function()
        Networking.FireServer(Networking.Events.LeaveSession)
    end)
end

function HubUI:UpdateLobby(lobbyData)
    if not self.lobbyMembersLabel then return end
    if not lobbyData then return end
    local lines = { "Host: "..(lobbyData.host or "?"), "Mode: "..(lobbyData.modeId or "?"), "" }
    for _, m in ipairs(lobbyData.members or {}) do
        table.insert(lines, " - "..m.name)
    end
    self.lobbyMembersLabel.Text = table.concat(lines, "\n")
end

-- ==================== PANEL MANAGEMENT ====================

function HubUI:OpenPanel(name)
    self:ClosePanel()
    local panels = {
        upgrade    = self.upgradePanel,
        seed       = self.seedPanel,
        leaderboard= self.leaderboardPanel,
        modifier   = self.modifierPanel,
        lobby      = self.lobbyPanel,
    }
    local p = panels[name]
    if p then
        self.overlay.Visible = true
        p.Visible = true
        self.activePanel = name
        if name == "upgrade" and self.playerData then
            self:UpdateUpgradeRows(self.playerData.upgrades, self.playerData.gold)
        elseif name == "leaderboard" then
            Networking.FireServer(Networking.Events.RequestLeaderboard)
        end
    end
end

function HubUI:ClosePanel()
    local panels = { self.upgradePanel, self.seedPanel, self.leaderboardPanel, self.modifierPanel, self.lobbyPanel }
    for _, p in ipairs(panels) do
        if p then p.Visible = false end
    end
    if self.overlay then self.overlay.Visible = false end
    self.activePanel = nil
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

function HubUI:SetPlayerData(data)
    self.playerData = data
    if self.goldLabel then self.goldLabel.Text = string.format("GOLD: %d", data.gold or 0) end
    if self.bestTimeLabel then
        if data.bestTime then
            local t = data.bestTime; local cs = math.floor((t%1)*100); local s = math.floor(t)%60; local m = math.floor(t/60)
            self.bestTimeLabel.Text = string.format("Best: %02d:%02d.%02d", m, s, cs)
        else
            self.bestTimeLabel.Text = "Best: --"
        end
    end
    if self.activePanel == "upgrade" then
        self:UpdateUpgradeRows(data.upgrades, data.gold)
    end
end

function HubUI:ShowPrompt(text)
    if not self.promptLabel then return end
    self.promptLabel.Text = text; self.promptLabel.Visible = true; self.promptLabel.TextTransparency = 0
    if self._promptTween then self._promptTween:Cancel() end
    task.delay(2.5, function()
        if self.promptLabel then
            self._promptTween = TweenService:Create(self.promptLabel, TweenInfo.new(0.5), {TextTransparency=1})
            self._promptTween:Play()
            self._promptTween.Completed:Connect(function() if self.promptLabel then self.promptLabel.Visible = false end end)
        end
    end)
end

function HubUI:ToggleCameraMode()
    if self.cameraMode == "fps" then
        self.cameraMode = "tps"
        if self.camToggleBtn then self.camToggleBtn.Text = "CAM: TPS" end
        if self.cameraRef then self.cameraRef:Start("tps") end
    else
        self.cameraMode = "fps"
        if self.camToggleBtn then self.camToggleBtn.Text = "CAM: FPS" end
        if self.cameraRef then self.cameraRef:Start("fps") end
    end
    Networking.FireServer(Networking.Events.SaveCameraPreference, self.cameraMode)
end

function HubUI:SetCameraRef(cam)
    self.cameraRef = cam
end

function HubUI:GetPendingSeed()
    return self.pendingSeed or (self.playerData and self.playerData.lastSeed) or "MattyJacks"
end

function HubUI:Show()
    if self.goldDisplay then self.goldDisplay.Visible = true end
    if self.camToggleBtn then self.camToggleBtn.Visible = true end
end

function HubUI:Hide()
    self:ClosePanel()
    if self.goldDisplay then self.goldDisplay.Visible = false end
    if self.camToggleBtn then self.camToggleBtn.Visible = false end
    if self.promptLabel then self.promptLabel.Visible = false end
end

return HubUI
