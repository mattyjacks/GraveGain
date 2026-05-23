-- DropDwarf: backpack_ui.lua
-- 4-slot inventory bar rendered at bottom-center of the HUD.
-- Slots are updated via BackpackUpdate network event.
-- Number keys 1-4 equip slots; active slot is highlighted.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Networking       = require(game.ReplicatedStorage.Shared.networking)
local ItemData         = require(game.ReplicatedStorage.Shared.item_data)

local BackpackUI = {}
BackpackUI.__index = BackpackUI

local SLOT_SIZE    = 56   -- px per slot
local SLOT_GAP     = 6
local SLOT_COUNT   = 4
local BAR_W        = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP + 16
local BAR_H        = SLOT_SIZE + 24   -- room for hotkey label below

local COLOR_BG        = Color3.fromRGB(14, 12, 20)
local COLOR_SLOT      = Color3.fromRGB(30, 26, 38)
local COLOR_ACTIVE    = Color3.fromRGB(255, 180, 30)
local COLOR_EMPTY     = Color3.fromRGB(22, 18, 28)
local COLOR_WHITE     = Color3.new(1, 1, 1)
local COLOR_GRAY      = Color3.fromRGB(130, 120, 110)
local COLOR_GOLD      = Color3.fromRGB(255, 210, 40)

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

local function addCorner(f, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = f
    return c
end

local function addStroke(f, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or COLOR_GRAY
    s.Thickness = thick or 1
    s.Parent = f
end

local function makeLabel(parent, name, text, pos, size, font, color, align)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Text = text
    l.Position = pos
    l.Size = size
    l.BackgroundTransparency = 1
    l.TextColor3 = color or COLOR_WHITE
    l.Font = font or Enum.Font.Gotham
    l.TextScaled = false
    l.TextSize = 13
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.Parent = parent
    return l
end

function BackpackUI.new()
    local self = setmetatable({}, BackpackUI)
    self.player    = Players.LocalPlayer
    self.gui       = nil
    self.slots     = {}   -- array of slot frame references
    self.slotData  = {}   -- cached {itemId, count} per slot
    self.activeSlot = 1
    self.visible   = false
    return self
end

function BackpackUI:Build(screenGui)
    -- Bar sits above health bar, centered horizontally, just above the HUD bottom strip
    local bar = makeFrame(screenGui, "BackpackBar",
        UDim2.new(0.5, -BAR_W/2, 1, -(BAR_H + 108)),
        UDim2.new(0, BAR_W, 0, BAR_H),
        COLOR_BG, 0.35)
    addCorner(bar, 10)
    addStroke(bar, Color3.fromRGB(60, 52, 75), 1)
    bar.Visible = false
    self.bar = bar

    for i = 1, SLOT_COUNT do
        local xOff = 8 + (i - 1) * (SLOT_SIZE + SLOT_GAP)

        local slotFrame = makeFrame(bar, "Slot" .. i,
            UDim2.new(0, xOff, 0, 6),
            UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE),
            COLOR_SLOT, 0)
        addCorner(slotFrame, 8)
        addStroke(slotFrame, Color3.fromRGB(60, 52, 75), 1)

        -- Item icon placeholder (colored square based on item rarity/type)
        local icon = makeFrame(slotFrame, "Icon",
            UDim2.new(0.1, 0, 0.1, 0), UDim2.new(0.8, 0, 0.6, 0),
            Color3.fromRGB(40, 36, 50), 1)
        addCorner(icon, 4)

        -- Item name label
        local nameLabel = makeLabel(slotFrame, "ItemName", "",
            UDim2.new(0, 0, 0.62, 0), UDim2.new(1, 0, 0, 14),
            Enum.Font.GothamBold, COLOR_WHITE)
        nameLabel.TextSize = 10
        nameLabel.TextScaled = false
        nameLabel.ClipsDescendants = true

        -- Count label (bottom-right corner)
        local countLabel = makeLabel(slotFrame, "Count", "",
            UDim2.new(0.55, 0, 0.55, 0), UDim2.new(0.45, 0, 0.3, 0),
            Enum.Font.GothamBold, COLOR_GOLD)
        countLabel.TextSize = 12

        -- Hotkey label below slot
        local hotkey = makeLabel(bar, "Key" .. i,
            tostring(i),
            UDim2.new(0, xOff, 0, SLOT_SIZE + 8),
            UDim2.new(0, SLOT_SIZE, 0, 14),
            Enum.Font.Gotham, COLOR_GRAY)
        hotkey.TextSize = 11

        self.slots[i] = {
            frame      = slotFrame,
            icon       = icon,
            nameLabel  = nameLabel,
            countLabel = countLabel,
            stroke     = slotFrame:FindFirstChildOfClass("UIStroke"),
        }
    end

    self.gui = screenGui
end

function BackpackUI:Show()
    if self.bar then self.bar.Visible = true end
    self.visible = true
end

function BackpackUI:Hide()
    if self.bar then self.bar.Visible = false end
    self.visible = false
end

-- Called by BackpackUpdate network event
-- slots: array[1..4] of {itemId, count} or false
-- activeSlot: number 1-4
function BackpackUI:Update(slots, activeSlot)
    self.activeSlot = activeSlot or self.activeSlot

    for i = 1, SLOT_COUNT do
        local slotInfo = slots and slots[i]
        local s = self.slots[i]
        if not s then continue end

        local isActive = (i == self.activeSlot)

        if slotInfo and slotInfo.itemId then
            local def = ItemData.Items[slotInfo.itemId]
            self.slotData[i] = slotInfo

            -- Background color based on active
            s.frame.BackgroundColor3 = isActive
                and Color3.fromRGB(60, 48, 20)
                or  COLOR_SLOT

            -- Icon color from item definition color or accent
            local iconColor = def and def.color
                or Color3.fromRGB(80, 200, 255)
            s.icon.BackgroundColor3  = iconColor
            s.icon.BackgroundTransparency = 0

            -- Name (abbreviated for small slot)
            local name = def and def.name or slotInfo.itemId
            s.nameLabel.Text       = name
            s.nameLabel.TextColor3 = isActive and COLOR_GOLD or COLOR_WHITE

            -- Count (only show if > 1)
            s.countLabel.Text = slotInfo.count > 1
                and tostring(slotInfo.count)
                or  ""
        else
            self.slotData[i] = nil
            s.frame.BackgroundColor3  = COLOR_EMPTY
            s.icon.BackgroundTransparency = 1
            s.nameLabel.Text  = ""
            s.countLabel.Text = ""
        end

        -- Active slot highlight border
        local stroke = s.frame:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color     = isActive and COLOR_ACTIVE or Color3.fromRGB(60, 52, 75)
            stroke.Thickness = isActive and 2 or 1
        end
    end
end

-- Wire number keys 1-4 to equip slots; returns connection for cleanup
function BackpackUI:ConnectInput()
    local keyMap = {
        [Enum.KeyCode.One]   = 1,
        [Enum.KeyCode.Two]   = 2,
        [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four]  = 4,
    }
    self.inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local slot = keyMap[input.KeyCode]
        if slot then
            Networking.FireServer(Networking.Events.EquipSlot, slot)
        end
    end)
end

function BackpackUI:DisconnectInput()
    if self.inputConn then
        self.inputConn:Disconnect()
        self.inputConn = nil
    end
end

return BackpackUI
