-- Maze Runner - Client HUD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local HUD = {}

local player = Players.LocalPlayer
local timerConnection = nil

function HUD:Initialize()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "MazeRunnerHUD"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    self.ScreenGui.Enabled = false
    
    -- Timer Frame
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "Timer"
    timerFrame.Size = UDim2.new(0, 150, 0, 60)
    timerFrame.Position = UDim2.new(0.5, -75, 0, 20)
    timerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    timerFrame.BackgroundTransparency = 0.5
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = self.ScreenGui
    
    local timerCorner = Instance.new("UICorner")
    timerCorner.CornerRadius = UDim.new(0, 10)
    timerCorner.Parent = timerFrame
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Time"
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "00:00"
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBlack
    timerLabel.Parent = timerFrame
    
    self.TimerLabel = timerLabel
    
    -- Powerup indicators
    self.PowerupFrame = Instance.new("Frame")
    self.PowerupFrame.Name = "Powerups"
    self.PowerupFrame.Size = UDim2.new(0, 200, 0, 40)
    self.PowerupFrame.Position = UDim2.new(0.5, -100, 0, 90)
    self.PowerupFrame.BackgroundTransparency = 1
    self.PowerupFrame.Parent = self.ScreenGui
    
    self.ActivePowerups = {}
end

function HUD:Show(timeLimit)
    self.ScreenGui.Enabled = true
    self.StartTime = tick()
    self.TimeLimit = timeLimit
    
    -- Start timer
    if timerConnection then
        timerConnection:Disconnect()
    end
    
    timerConnection = RunService.Heartbeat:Connect(function()
        self:UpdateTimer()
    end)
end

function HUD:Hide()
    self.ScreenGui.Enabled = false
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
end

function HUD:UpdateTimer()
    if not self.StartTime then return end
    
    local elapsed = tick() - self.StartTime
    local remaining = math.max(0, self.TimeLimit - elapsed)
    
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    
    self.TimerLabel.Text = string.format("%02d:%02d", minutes, seconds)
    
    -- Warning color
    if remaining < 30 then
        self.TimerLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    elseif remaining < 60 then
        self.TimerLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    else
        self.TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    -- Time's up
    if remaining <= 0 then
        self:Hide()
    end
end

function HUD:OnCollectPowerup(powerupType)
    -- Visual indicator for powerup
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 50, 0, 50)
    indicator.Position = UDim2.new(0, #self.ActivePowerups * 55, 0, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = self.PowerupFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = indicator
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = powerupType == "SpeedBoost" and "⚡" or powerupType == "TimeBonus" and "⏰" or "👁️"
    icon.TextScaled = true
    icon.Parent = indicator
    
    table.insert(self.ActivePowerups, indicator)
    
    -- Animate and remove after duration
    task.delay(10, function()
        if indicator then
            TweenService:Create(indicator, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            task.wait(0.5)
            indicator:Destroy()
        end
    end)
end

return HUD
