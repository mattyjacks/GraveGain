-- Color Rush - Client HUD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.config)

local HUD = {}

local player = Players.LocalPlayer

function HUD:Initialize()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ColorRushHUD"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    self.ScreenGui.Enabled = false
    
    -- Score display
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "Score"
    scoreFrame.Size = UDim2.new(0, 200, 0, 60)
    scoreFrame.Position = UDim2.new(0, 20, 0, 20)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scoreFrame.BackgroundTransparency = 0.5
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = self.ScreenGui
    
    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 10)
    scoreCorner.Parent = scoreFrame
    
    local scoreTitle = Instance.new("TextLabel")
    scoreTitle.Size = UDim2.new(1, 0, 0.4, 0)
    scoreTitle.BackgroundTransparency = 1
    scoreTitle.Text = "SCORE"
    scoreTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    scoreTitle.TextScaled = true
    scoreTitle.Font = Enum.Font.GothamBold
    scoreTitle.Parent = scoreFrame
    
    self.ScoreLabel = Instance.new("TextLabel")
    self.ScoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
    self.ScoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
    self.ScoreLabel.BackgroundTransparency = 1
    self.ScoreLabel.Text = "0"
    self.ScoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    self.ScoreLabel.TextScaled = true
    self.ScoreLabel.Font = Enum.Font.GothamBlack
    self.ScoreLabel.Parent = scoreFrame
    
    -- Lives display
    local livesFrame = Instance.new("Frame")
    livesFrame.Name = "Lives"
    livesFrame.Size = UDim2.new(0, 150, 0, 50)
    livesFrame.Position = UDim2.new(1, -170, 0, 20)
    livesFrame.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    livesFrame.BackgroundTransparency = 0.5
    livesFrame.BorderSizePixel = 0
    livesFrame.Parent = self.ScreenGui
    
    local livesCorner = Instance.new("UICorner")
    livesCorner.CornerRadius = UDim.new(0, 10)
    livesCorner.Parent = livesFrame
    
    self.LivesLabel = Instance.new("TextLabel")
    self.LivesLabel.Size = UDim2.new(1, 0, 1, 0)
    self.LivesLabel.BackgroundTransparency = 1
    self.LivesLabel.Text = "3"
    self.LivesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.LivesLabel.TextScaled = true
    self.LivesLabel.Font = Enum.Font.GothamBlack
    self.LivesLabel.Parent = livesFrame
    
    -- Color indicator (center bottom)
    self.ColorIndicator = Instance.new("Frame")
    self.ColorIndicator.Name = "ColorIndicator"
    self.ColorIndicator.Size = UDim2.new(0, 100, 0, 100)
    self.ColorIndicator.Position = UDim2.new(0.5, -50, 1, -130)
    self.ColorIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.ColorIndicator.BorderSizePixel = 0
    self.ColorIndicator.Parent = self.ScreenGui
    
    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, 50)
    colorCorner.Parent = self.ColorIndicator
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(1, 0, 0.3, 0)
    colorLabel.Position = UDim2.new(0, 0, -0.35, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "YOUR COLOR"
    colorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorLabel.TextScaled = true
    colorLabel.Font = Enum.Font.GothamBold
    colorLabel.Parent = self.ColorIndicator
    
    -- Combo display
    self.ComboLabel = Instance.new("TextLabel")
    self.ComboLabel.Size = UDim2.new(0, 200, 0, 50)
    self.ComboLabel.Position = UDim2.new(0.5, -100, 0.3, 0)
    self.ComboLabel.BackgroundTransparency = 1
    self.ComboLabel.Text = ""
    self.ComboLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    self.ComboLabel.TextScaled = true
    self.ComboLabel.Font = Enum.Font.GothamBlack
    self.ComboLabel.Parent = self.ScreenGui
end

function HUD:Show(score, lives, color)
    self.ScreenGui.Enabled = true
    self.ScoreLabel.Text = tostring(score)
    self.LivesLabel.Text = tostring(lives)
    self.ColorIndicator.BackgroundColor3 = color
    
    -- Listen for server events
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameEvent = remotes:WaitForChild("GameEvent")
    
    gameEvent.OnClientEvent:Connect(function(eventType, data)
        if eventType == "Score" then
            self:UpdateScore(data.score, data.combo)
        elseif eventType == "Respawn" then
            self.LivesLabel.Text = tostring(data.lives)
        elseif eventType == "GameOver" then
            self:ShowGameOver(data)
        elseif eventType == "Powerup" then
            self:ShowPowerup(data.type)
        end
    end)
end

function HUD:Hide()
    self.ScreenGui.Enabled = false
end

function HUD:UpdateScore(score, combo)
    self.ScoreLabel.Text = tostring(score)
    
    -- Show combo
    if combo > 1 then
        self.ComboLabel.Text = combo .. "x COMBO!"
        
        TweenService:Create(self.ComboLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), 
            {Size = UDim2.new(0, 220, 0, 55)}):Play()
        
        task.delay(1, function()
            TweenService:Create(self.ComboLabel, TweenInfo.new(0.3), 
                {TextTransparency = 1}):Play()
            task.wait(0.3)
            self.ComboLabel.Text = ""
            self.ComboLabel.TextTransparency = 0
            self.ComboLabel.Size = UDim2.new(0, 200, 0, 50)
        end)
    end
    
    -- Pulse animation on score
    TweenService:Create(self.ScoreLabel, TweenInfo.new(0.1), {TextSize = 35}):Play()
    task.delay(0.1, function()
        TweenService:Create(self.ScoreLabel, TweenInfo.new(0.1), {TextSize = 28}):Play()
    end)
end

function HUD:ShowPowerup(powerupType)
    local text = powerupType == "Rainbow" and "RAINBOW MODE!" 
        or powerupType == "SlowMo" and "SLOW MOTION!"
        or "EXTRA LIFE!"
    
    local popup = Instance.new("TextLabel")
    popup.Size = UDim2.new(0, 300, 0, 60)
    popup.Position = UDim2.new(0.5, -150, 0.4, 0)
    popup.BackgroundTransparency = 1
    popup.Text = text
    popup.TextColor3 = Color3.fromRGB(255, 215, 0)
    popup.TextScaled = true
    popup.Font = Enum.Font.GothamBlack
    popup.Parent = self.ScreenGui
    
    TweenService:Create(popup, TweenInfo.new(0.5, Enum.EasingStyle.Back), 
        {Position = UDim2.new(0.5, -150, 0.35, 0)}):Play()
    
    task.delay(2, function()
        TweenService:Create(popup, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task.wait(0.3)
        popup:Destroy()
    end)
end

function HUD:ShowGameOver(data)
    self:Hide()
    
    local resultGui = Instance.new("ScreenGui")
    resultGui.Name = "GameOver"
    resultGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = data.won and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
    frame.BorderSizePixel = 0
    frame.Parent = resultGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = data.won and "VICTORY!" or "GAME OVER"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = frame
    
    local scoreText = Instance.new("TextLabel")
    scoreText.Size = UDim2.new(1, 0, 0, 40)
    scoreText.Position = UDim2.new(0, 0, 0, 90)
    scoreText.BackgroundTransparency = 1
    scoreText.Text = "Score: " .. data.score
    scoreText.TextColor3 = Color3.fromRGB(255, 255, 255)
    scoreText.TextScaled = true
    scoreText.Font = Enum.Font.GothamBold
    scoreText.Parent = frame
    
    local comboText = Instance.new("TextLabel")
    comboText.Size = UDim2.new(1, 0, 0, 30)
    comboText.Position = UDim2.new(0, 0, 0, 140)
    comboText.BackgroundTransparency = 1
    comboText.Text = "Max Combo: " .. data.maxCombo
    comboText.TextColor3 = Color3.fromRGB(255, 255, 255)
    comboText.TextScaled = true
    comboText.Font = Enum.Font.Gotham
    comboText.Parent = frame
    
    local timeText = Instance.new("TextLabel")
    timeText.Size = UDim2.new(1, 0, 0, 30)
    timeText.Position = UDim2.new(0, 0, 0, 180)
    timeText.BackgroundTransparency = 1
    timeText.Text = string.format("Time: %.1f seconds", data.time)
    timeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeText.TextScaled = true
    timeText.Font = Enum.Font.Gotham
    timeText.Parent = frame
    
    local playAgain = Instance.new("TextButton")
    playAgain.Size = UDim2.new(0, 150, 0, 40)
    playAgain.Position = UDim2.new(0.5, -75, 1, -70)
    playAgain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    playAgain.Text = "PLAY AGAIN"
    playAgain.TextColor3 = Color3.fromRGB(0, 0, 0)
    playAgain.TextScaled = true
    playAgain.Font = Enum.Font.GothamBold
    playAgain.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = playAgain
    
    playAgain.MouseButton1Click:Connect(function()
        resultGui:Destroy()
        local Menu = require(script.Parent.menu)
        Menu:Show()
    end)
end

return HUD
