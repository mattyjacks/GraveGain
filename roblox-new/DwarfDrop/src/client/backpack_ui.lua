-- DwarfDrop: backpack_ui.lua
-- 4-slot active item HUD row
-- FIX Bug#9: Build() receives screenGui parameter - no dependency on hud.Build() timing

local Players  = game:GetService("Players")

local Networking = require(game.ReplicatedStorage.Shared.networking)
local ItemData   = require(game.ReplicatedStorage.Shared.item_data)

local BackpackUI = {}
BackpackUI.__index = BackpackUI

local SLOT_SIZE    = UDim2.new(0, 62, 0, 62)
local SLOT_PAD     = 6
local SLOT_BOT_Y   = 10
local SLOTS        = 4
local KEY_LABELS   = { "1", "2", "3", "4" }

local COLOR_SLOT_BG    = Color3.fromRGB(18, 16, 26)
local COLOR_SLOT_SEL   = Color3.fromRGB(40, 120, 200)
local COLOR_SLOT_GLOW  = Color3.fromRGB(255, 210, 40)

local function addCorner(f, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = f; return c
end

local function makeLabel(parent, name, text, pos, size, font, color, size2, zIdx)
    local l = Instance.new("TextLabel")
    l.Name = name; l.Text = text; l.Position = pos; l.Size = size
    l.BackgroundTransparency = 1; l.TextColor3 = color or Color3.new(1,1,1)
    l.Font = font or Enum.Font.GothamBold; l.TextScaled = true
    if size2 then l.TextScaled = false; l.TextSize = size2 end
    if zIdx then l.ZIndex = zIdx end
    l.Parent = parent; return l
end

function BackpackUI.new()
    local self = setmetatable({}, BackpackUI)
    self.player       = Players.LocalPlayer
    self.slots        = {}
    self.slotData     = {}
    self.activeSlot   = 1
    self.screenGui    = nil
    return self
end

-- FIX Bug#9: accepts screenGui so caller builds hud first, then passes gui in
function BackpackUI:Build(screenGui)
    self.screenGui = screenGui

    local totalW = SLOTS * (62 + SLOT_PAD) - SLOT_PAD
    local containerX = (0.5 * 1) - totalW / 2

    local container = Instance.new("Frame")
    container.Name  = "BackpackContainer"
    container.Size  = UDim2.new(0, totalW + SLOT_PAD * 2, 0, 80)
    container.Position = UDim2.new(0.5, -(totalW/2 + SLOT_PAD), 1, -(80 + SLOT_BOT_Y))
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = screenGui
    self.container = container

    for i = 1, SLOTS do
        local slotFrame = Instance.new("Frame")
        slotFrame.Name = "Slot" .. i
        slotFrame.Size = SLOT_SIZE
        slotFrame.Position = UDim2.new(0, (i-1)*(62+SLOT_PAD), 0, 0)
        slotFrame.BackgroundColor3 = COLOR_SLOT_BG
        slotFrame.BackgroundTransparency = 0.2
        slotFrame.BorderSizePixel = 0
        slotFrame.Parent = container
        addCorner(slotFrame, 8)

        -- Key label
        makeLabel(slotFrame, "Key", KEY_LABELS[i],
            UDim2.new(0,3,0,3), UDim2.new(0,14,0,14),
            Enum.Font.GothamBold, Color3.fromRGB(160,160,180), 10, 12)

        -- Item name
        local nameLabel = makeLabel(slotFrame, "ItemName", "",
            UDim2.new(0,3,0.44,0), UDim2.new(1,-3,0.36,0),
            Enum.Font.Gotham, Color3.fromRGB(240,230,200), nil, 11)
        nameLabel.TextScaled = false

        -- Count
        local countLabel = makeLabel(slotFrame, "Count", "",
            UDim2.new(0,3,0.8,0), UDim2.new(1,-3,0.22,0),
            Enum.Font.GothamBold, COLOR_SLOT_GLOW, nil, 10)
        countLabel.TextScaled = false

        -- Stroke for selected state
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(1,1,1); stroke.Thickness = 2
        stroke.Transparency = 0.8; stroke.Parent = slotFrame

        self.slots[i] = {
            frame      = slotFrame,
            nameLabel  = nameLabel,
            countLabel = countLabel,
            stroke     = stroke,
        }
    end

    -- Wire number keys
    local UIS = game:GetService("UserInputService")
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local k = input.KeyCode
            local idx = (k == Enum.KeyCode.One) and 1 or
                        (k == Enum.KeyCode.Two) and 2 or
                        (k == Enum.KeyCode.Three) and 3 or
                        (k == Enum.KeyCode.Four) and 4 or nil
            if idx then
                self:SelectSlot(idx)
                Networking.FireServer(Networking.Events.EquipSlot, idx)
            end
        end
    end)

    -- Listen for backpack updates
    Networking.OnClient(Networking.Events.BackpackUpdate, function(backpack)
        self:UpdateSlots(backpack)
    end)

    return self
end

function BackpackUI:SelectSlot(idx)
    self.activeSlot = idx
    for i = 1, SLOTS do
        local s = self.slots[i]
        if s then
            local isActive = (i == idx)
            s.frame.BackgroundColor3 = isActive and COLOR_SLOT_SEL or COLOR_SLOT_BG
            s.stroke.Transparency = isActive and 0.1 or 0.8
        end
    end
end

function BackpackUI:UpdateSlots(backpack)
    if not backpack then return end
    for i = 1, SLOTS do
        local slot = self.slots[i]
        local data = backpack[i]
        if not slot then continue end
        if data and data.itemId then
            local def  = ItemData.Items[data.itemId]
            slot.nameLabel.Text  = def and def.displayName or data.itemId
            slot.countLabel.Text = "x" .. (data.count or 0)
            slot.frame.BackgroundTransparency = 0.1
        else
            slot.nameLabel.Text  = ""
            slot.countLabel.Text = ""
            slot.frame.BackgroundTransparency = 0.6
        end
        self.slotData[i] = data
    end
end

function BackpackUI:GetSlotData(i)
    return self.slotData[i]
end

function BackpackUI:GetActiveSlotData()
    return self.slotData[self.activeSlot]
end

function BackpackUI:GetActiveSlotIndex()
    return self.activeSlot
end

function BackpackUI:Show()
    if self.container then self.container.Visible = true end
end

function BackpackUI:Hide()
    if self.container then self.container.Visible = false end
end

return BackpackUI
