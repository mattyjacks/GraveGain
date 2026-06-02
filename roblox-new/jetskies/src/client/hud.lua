local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local HUD = {}
local GameData

-- UI References
local ui = {
    screenGui = nil,
    speedometer = nil,
    altitudeMeter = nil,
    ringCounter = nil,
    boostBar = nil,
    ringPopup = nil
}

-- State
local player

function HUD:Init(localPlayer, clientState)
    GameData = require(game:GetService("ReplicatedStorage").Shared.game_data)
    player = localPlayer
    
    -- Create ScreenGui
    ui.screenGui = Instance.new("ScreenGui")
    ui.screenGui.Name = "JetSkyHUD"
    ui.screenGui.ResetOnSpawn = false
    ui.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Create all HUD elements
    self:CreateSpeedometer()
    self:CreateAltitudeMeter()
    self:CreateRingCounter()
    self:CreateBoostBar()
    self:CreateRingPopup()
    
    print("[HUD] Initialized")
end

function HUD:CreateSpeedometer()
    local frame = Instance.new("Frame")
    frame.Name = "Speedometer"
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(1, -220, 0, 20)
    frame.BackgroundColor3 = GameData.UIColors.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = ui.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = "SPEED"
    label.TextColor3 = GameData.UIColors.TEXT
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(1, 0, 0, 30)
    value.Position = UDim2.new(0, 0, 0, 25)
    value.BackgroundTransparency = 1
    value.Text = "0 studs/s"
    value.TextColor3 = GameData.UIColors.PRIMARY
    value.TextScaled = true
    value.Font = Enum.Font.GothamBold
    value.Parent = frame
    
    ui.speedometer = value
end

function HUD:CreateAltitudeMeter()
    local frame = Instance.new("Frame")
    frame.Name = "AltitudeMeter"
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(1, -220, 0, 90)
    frame.BackgroundColor3 = GameData.UIColors.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = ui.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = "ALTITUDE"
    label.TextColor3 = GameData.UIColors.TEXT
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(1, 0, 0, 30)
    value.Position = UDim2.new(0, 0, 0, 25)
    value.BackgroundTransparency = 1
    value.Text = "0 studs"
    value.TextColor3 = GameData.UIColors.SECONDARY
    value.TextScaled = true
    value.Font = Enum.Font.GothamBold
    value.Parent = frame
    
    ui.altitudeMeter = value
end

function HUD:CreateRingCounter()
    local frame = Instance.new("Frame")
    frame.Name = "RingCounter"
    frame.Size = UDim2.new(0, 150, 0, 50)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = GameData.UIColors.BACKGROUND
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = ui.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.Position = UDim2.new(0, 5, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "◯"
    icon.TextColor3 = Color3.fromRGB(255, 215, 0)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame
    
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(1, -50, 1, 0)
    value.Position = UDim2.new(0, 50, 0, 0)
    value.BackgroundTransparency = 1
    value.Text = "0"
    value.TextColor3 = GameData.UIColors.TEXT
    value.TextScaled = true
    value.Font = Enum.Font.GothamBold
    value.Parent = frame
    
    ui.ringCounter = value
end

function HUD:CreateBoostBar()
    local frame = Instance.new("Frame")
    frame.Name = "BoostBar"
    frame.Size = UDim2.new(0, 200, 0, 20)
    frame.Position = UDim2.new(1, -220, 0, 160)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = ui.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = GameData.UIColors.PRIMARY
    fill.BackgroundTransparency = 0.1
    fill.BorderSizePixel = 0
    fill.Parent = frame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 10)
    fillCorner.Parent = fill
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "BOOST"
    label.TextColor3 = GameData.UIColors.TEXT
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    ui.boostBar = fill
end

function HUD:CreateRingPopup()
    local label = Instance.new("TextLabel")
    label.Name = "RingPopup"
    label.Size = UDim2.new(0, 200, 0, 40)
    label.Position = UDim2.new(0.5, -100, 0.3, 0)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Visible = false
    label.Parent = ui.screenGui
    
    ui.ringPopup = label
end

function HUD:UpdateStats(stats)
    if ui.speedometer then
        ui.speedometer.Text = string.format("%.0f studs/s", stats.speed or 0)
    end
    
    if ui.altitudeMeter then
        ui.altitudeMeter.Text = string.format("%.0f studs", stats.altitude or 0)
    end
    
    if ui.ringCounter then
        ui.ringCounter.Text = tostring(stats.rings or 0)
    end
end

function HUD:UpdateBoost(fuel, maxFuel)
    if not ui.boostBar then return end
    
    local percent = fuel / maxFuel
    ui.boostBar.Size = UDim2.new(percent, 0, 1, 0)
    
    -- Color shift based on fuel level
    if percent > 0.5 then
        ui.boostBar.BackgroundColor3 = GameData.UIColors.PRIMARY
    elseif percent > 0.25 then
        ui.boostBar.BackgroundColor3 = GameData.UIColors.WARNING
    else
        ui.boostBar.BackgroundColor3 = GameData.UIColors.DANGER
    end
end

function HUD:ShowRingCollected(value)
    if not ui.ringPopup then return end
    
    local text = value > 1 and string.format("+%d RINGS!", value) or "+1 RING!"
    if value >= 5 then
        text = "★ HIDDEN RING! ★"
    end
    
    ui.ringPopup.Text = text
    ui.ringPopup.Visible = true
    
    -- Pop animation
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local popTween = TweenService:Create(ui.ringPopup, tweenInfo, {
        Size = UDim2.new(0, 220, 0, 44),
        Position = UDim2.new(0.5, -110, 0.3, -10)
    })
    popTween:Play()
    
    -- Fade out after delay
    task.delay(1.5, function()
        local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(ui.ringPopup, fadeInfo, {
            TextTransparency = 1
        })
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            ui.ringPopup.Visible = false
            ui.ringPopup.TextTransparency = 0
            ui.ringPopup.Size = UDim2.new(0, 200, 0, 40)
            ui.ringPopup.Position = UDim2.new(0.5, -100, 0.3, 0)
        end)
    end)
end

return HUD
