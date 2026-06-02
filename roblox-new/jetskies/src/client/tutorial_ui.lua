local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TutorialUI = {}

-- UI References
local ui = {
    screenGui = nil,
    mainFrame = nil,
    controlsFrame = nil,
    tipsFrame = nil,
    continueButton = nil,
    isShowing = false
}

-- Player
local player

-- Tutorial data
local CONTROLS = {
    {
        key = "W / S",
        action = "Throttle",
        desc = "Increase / Decrease Speed"
    },
    {
        key = "A / D",
        action = "Turn",
        desc = "Yaw Left / Right"
    },
    {
        key = "SPACE",
        action = "Pitch Up",
        desc = "Climb Higher"
    },
    {
        key = "CTRL",
        action = "Pitch Down",
        desc = "Dive Lower"
    },
    {
        key = "SHIFT",
        action = "Boost",
        desc = "Temporary Speed Boost"
    },
    {
        key = "ESC",
        action = "Pause",
        desc = "Open Pause Menu"
    }
}

local TIPS = {
    "🌊 Fly LOW over water for SPEED BOOST",
    "⭕ Collect GOLDEN RINGS for upgrades",
    "🏝️ Explore islands to find HIDDEN rings",
    "⚡ Use BOOST wisely - it has limited fuel",
    "🎮 Higher THROTTLE = more control response",
    "🌅 Higher islands have BETTER rewards"
}

function TutorialUI:Init(localPlayer)
    player = localPlayer
    
    -- Check if tutorial was already shown
    local shown = self:WasTutorialShown()
    if shown then
        print("[TutorialUI] Tutorial already shown, skipping")
        return false
    end
    
    self:CreateUI()
    self:ShowTutorial()
    
    return true
end

function TutorialUI:WasTutorialShown()
    -- Try to read from local storage
    local success, result = pcall(function()
        -- In Roblox, we can't easily persist data without DataStore
        -- For now, just check memory or use a simple flag
        return _G.TutorialShown
    end)
    
    if success and result then
        return true
    end
    
    return false
end

function TutorialUI:MarkTutorialShown()
    _G.TutorialShown = true
end

function TutorialUI:CreateUI()
    -- ScreenGui
    ui.screenGui = Instance.new("ScreenGui")
    ui.screenGui.Name = "TutorialScreen"
    ui.screenGui.ResetOnSpawn = false
    ui.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Background blur effect
    local blur = Instance.new("Frame")
    blur.Name = "BlurBackground"
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.fromRGB(0, 10, 30)
    blur.BackgroundTransparency = 0.3
    blur.BorderSizePixel = 0
    blur.Parent = ui.screenGui
    
    -- Main container
    ui.mainFrame = Instance.new("Frame")
    ui.mainFrame.Name = "MainFrame"
    ui.mainFrame.Size = UDim2.new(0, 700, 0, 500)
    ui.mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    ui.mainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    ui.mainFrame.BorderSizePixel = 0
    ui.mainFrame.Visible = false
    ui.mainFrame.Parent = ui.screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = ui.mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "🛩️ JETSKIES"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = ui.mainFrame
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 80)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Welcome to the Sky!"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Parent = ui.mainFrame
    
    -- Controls section
    local controlsTitle = Instance.new("TextLabel")
    controlsTitle.Name = "ControlsTitle"
    controlsTitle.Size = UDim2.new(0, 300, 0, 30)
    controlsTitle.Position = UDim2.new(0, 30, 0, 130)
    controlsTitle.BackgroundTransparency = 1
    controlsTitle.Text = "🎮 CONTROLS"
    controlsTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
    controlsTitle.TextScaled = true
    controlsTitle.Font = Enum.Font.GothamBold
    controlsTitle.Parent = ui.mainFrame
    
    -- Controls list
    local controlsList = Instance.new("Frame")
    controlsList.Name = "ControlsList"
    controlsList.Size = UDim2.new(0, 300, 0, 280)
    controlsList.Position = UDim2.new(0, 30, 0, 170)
    controlsList.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    controlsList.BorderSizePixel = 0
    controlsList.Parent = ui.mainFrame
    
    local controlsCorner = Instance.new("UICorner")
    controlsCorner.CornerRadius = UDim.new(0, 12)
    controlsCorner.Parent = controlsList
    
    -- Create control entries
    for i, control in ipairs(CONTROLS) do
        local entry = Instance.new("Frame")
        entry.Name = "Control_" .. i
        entry.Size = UDim2.new(1, -20, 0, 40)
        entry.Position = UDim2.new(0, 10, 0, 10 + (i-1) * 45)
        entry.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
        entry.BorderSizePixel = 0
        entry.Parent = controlsList
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 8)
        entryCorner.Parent = entry
        
        -- Key badge
        local keyBadge = Instance.new("Frame")
        keyBadge.Name = "KeyBadge"
        keyBadge.Size = UDim2.new(0, 60, 0, 28)
        keyBadge.Position = UDim2.new(0, 6, 0.5, -14)
        keyBadge.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        keyBadge.BorderSizePixel = 0
        keyBadge.Parent = entry
        
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 6)
        keyCorner.Parent = keyBadge
        
        local keyText = Instance.new("TextLabel")
        keyText.Name = "KeyText"
        keyText.Size = UDim2.new(1, 0, 1, 0)
        keyText.BackgroundTransparency = 1
        keyText.Text = control.key
        keyText.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyText.TextScaled = true
        keyText.Font = Enum.Font.GothamBold
        keyText.Parent = keyBadge
        
        -- Action text
        local actionText = Instance.new("TextLabel")
        actionText.Name = "Action"
        actionText.Size = UDim2.new(0, 100, 0, 18)
        actionText.Position = UDim2.new(0, 75, 0, 4)
        actionText.BackgroundTransparency = 1
        actionText.Text = control.action
        actionText.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionText.TextScaled = true
        actionText.Font = Enum.Font.GothamBold
        actionText.TextXAlignment = Enum.TextXAlignment.Left
        actionText.Parent = entry
        
        -- Desc text
        local descText = Instance.new("TextLabel")
        descText.Name = "Desc"
        descText.Size = UDim2.new(0, 180, 0, 14)
        descText.Position = UDim2.new(0, 75, 0, 22)
        descText.BackgroundTransparency = 1
        descText.Text = control.desc
        descText.TextColor3 = Color3.fromRGB(180, 180, 180)
        descText.TextScaled = true
        descText.Font = Enum.Font.Gotham
        descText.TextXAlignment = Enum.TextXAlignment.Left
        descText.Parent = entry
    end
    
    -- Tips section
    local tipsTitle = Instance.new("TextLabel")
    tipsTitle.Name = "TipsTitle"
    tipsTitle.Size = UDim2.new(0, 320, 0, 30)
    tipsTitle.Position = UDim2.new(1, -350, 0, 130)
    tipsTitle.BackgroundTransparency = 1
    tipsTitle.Text = "💡 PRO TIPS"
    tipsTitle.TextColor3 = Color3.fromRGB(50, 255, 150)
    tipsTitle.TextScaled = true
    tipsTitle.Font = Enum.Font.GothamBold
    tipsTitle.Parent = ui.mainFrame
    
    -- Tips list
    local tipsList = Instance.new("Frame")
    tipsList.Name = "TipsList"
    tipsList.Size = UDim2.new(0, 320, 0, 220)
    tipsList.Position = UDim2.new(1, -350, 0, 170)
    tipsList.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    tipsList.BorderSizePixel = 0
    tipsList.Parent = ui.mainFrame
    
    local tipsCorner = Instance.new("UICorner")
    tipsCorner.CornerRadius = UDim.new(0, 12)
    tipsCorner.Parent = tipsList
    
    -- Create tips
    for i, tip in ipairs(TIPS) do
        local tipLabel = Instance.new("TextLabel")
        tipLabel.Name = "Tip_" .. i
        tipLabel.Size = UDim2.new(1, -20, 0, 30)
        tipLabel.Position = UDim2.new(0, 10, 0, 10 + (i-1) * 35)
        tipLabel.BackgroundTransparency = 1
        tipLabel.Text = tip
        tipLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        tipLabel.TextScaled = true
        tipLabel.Font = Enum.Font.Gotham
        tipLabel.TextXAlignment = Enum.TextXAlignment.Left
        tipLabel.TextWrapped = true
        tipLabel.Parent = tipsList
    end
    
    -- Continue button
    ui.continueButton = Instance.new("TextButton")
    ui.continueButton.Name = "ContinueButton"
    ui.continueButton.Size = UDim2.new(0, 200, 0, 50)
    ui.continueButton.Position = UDim2.new(0.5, -100, 1, -70)
    ui.continueButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    ui.continueButton.BorderSizePixel = 0
    ui.continueButton.Text = "START FLYING!"
    ui.continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.continueButton.TextScaled = true
    ui.continueButton.Font = Enum.Font.GothamBlack
    ui.continueButton.Parent = ui.mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = ui.continueButton
    
    -- Loading text (shown initially)
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(1, 0, 0, 30)
    loadingText.Position = UDim2.new(0, 0, 1, -110)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "🌍 Generating World..."
    loadingText.TextColor3 = Color3.fromRGB(255, 200, 50)
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.GothamBold
    loadingText.Parent = ui.mainFrame
    ui.loadingText = loadingText
    
    -- Button click handler
    ui.continueButton.MouseButton1Click:Connect(function()
        self:HideTutorial()
    end)
    
    -- Also hide on Enter key
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.Return and ui.isShowing then
            self:HideTutorial()
        end
    end)
end

function TutorialUI:ShowTutorial()
    if not ui.mainFrame then return end
    
    ui.isShowing = true
    ui.mainFrame.Visible = true
    
    -- Animate in
    ui.mainFrame.Size = UDim2.new(0, 600, 0, 400)
    ui.mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = TweenService:Create(ui.mainFrame, tweenInfo, {
        Size = UDim2.new(0, 700, 0, 500),
        Position = UDim2.new(0.5, -350, 0.5, -250)
    })
    tween:Play()
    
    -- Disable continue button initially
    ui.continueButton.Visible = false
    ui.loadingText.Visible = true
    
    print("[TutorialUI] Tutorial shown")
end

function TutorialUI:WorldLoaded()
    if not ui.loadingText or not ui.continueButton then return end
    
    -- Update loading text
    ui.loadingText.Text = "✅ World Ready!"
    ui.loadingText.TextColor3 = Color3.fromRGB(50, 255, 100)
    
    -- Show continue button after short delay
    task.delay(0.5, function()
        ui.loadingText.Visible = false
        ui.continueButton.Visible = true
        
        -- Animate button
        ui.continueButton.Size = UDim2.new(0, 180, 0, 45)
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(ui.continueButton, tweenInfo, {
            Size = UDim2.new(0, 200, 0, 50)
        })
        tween:Play()
    end)
end

function TutorialUI:HideTutorial()
    if not ui.mainFrame then return end
    
    -- Animate out
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local tween = TweenService:Create(ui.mainFrame, tweenInfo, {
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 1.5, -200)
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        ui.mainFrame.Visible = false
        ui.isShowing = false
        self:MarkTutorialShown()
        
        -- Clean up
        if ui.screenGui then
            ui.screenGui:Destroy()
        end
    end)
    
    print("[TutorialUI] Tutorial hidden")
end

function TutorialUI:IsShowing()
    return ui.isShowing
end

return TutorialUI
