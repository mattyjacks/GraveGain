-- Tower Hop - Client HUD
-- Shows current floor, best floor, and leaderboard

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HUD = {}

-- Player reference
local player = Players.LocalPlayer

-- UI Elements
HUD.ScreenGui = nil
HUD.CurrentFloorLabel = nil
HUD.BestFloorLabel = nil
HUD.LeaderboardFrame = nil

-- Initialize HUD
function HUD:Initialize()
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "TowerHopHUD"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Current Floor Display (Top Center)
    local currentFrame = Instance.new("Frame")
    currentFrame.Name = "CurrentFloor"
    currentFrame.Size = UDim2.new(0, 200, 0, 60)
    currentFrame.Position = UDim2.new(0.5, -100, 0, 20)
    currentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    currentFrame.BackgroundTransparency = 0.5
    currentFrame.BorderSizePixel = 0
    currentFrame.Parent = self.ScreenGui
    
    local currentCorner = Instance.new("UICorner")
    currentCorner.CornerRadius = UDim.new(0, 10)
    currentCorner.Parent = currentFrame
    
    local currentTitle = Instance.new("TextLabel")
    currentTitle.Name = "Title"
    currentTitle.Size = UDim2.new(1, 0, 0, 20)
    currentTitle.Position = UDim2.new(0, 0, 0, 5)
    currentTitle.BackgroundTransparency = 1
    currentTitle.Text = "CURRENT FLOOR"
    currentTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentTitle.TextScaled = true
    currentTitle.Font = Enum.Font.GothamBold
    currentTitle.Parent = currentFrame
    
    self.CurrentFloorLabel = Instance.new("TextLabel")
    self.CurrentFloorLabel.Name = "Value"
    self.CurrentFloorLabel.Size = UDim2.new(1, 0, 0, 30)
    self.CurrentFloorLabel.Position = UDim2.new(0, 0, 0, 25)
    self.CurrentFloorLabel.BackgroundTransparency = 1
    self.CurrentFloorLabel.Text = "1"
    self.CurrentFloorLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
    self.CurrentFloorLabel.TextScaled = true
    self.CurrentFloorLabel.Font = Enum.Font.GothamBlack
    self.CurrentFloorLabel.Parent = currentFrame
    
    -- Best Floor Display (Top Right)
    local bestFrame = Instance.new("Frame")
    bestFrame.Name = "BestFloor"
    bestFrame.Size = UDim2.new(0, 150, 0, 50)
    bestFrame.Position = UDim2.new(1, -170, 0, 20)
    bestFrame.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    bestFrame.BackgroundTransparency = 0.3
    bestFrame.BorderSizePixel = 0
    bestFrame.Parent = self.ScreenGui
    
    local bestCorner = Instance.new("UICorner")
    bestCorner.CornerRadius = UDim.new(0, 10)
    bestCorner.Parent = bestFrame
    
    local bestTitle = Instance.new("TextLabel")
    bestTitle.Name = "Title"
    bestTitle.Size = UDim2.new(1, 0, 0, 18)
    bestTitle.Position = UDim2.new(0, 0, 0, 3)
    bestTitle.BackgroundTransparency = 1
    bestTitle.Text = "BEST FLOOR"
    bestTitle.TextColor3 = Color3.fromRGB(0, 0, 0)
    bestTitle.TextScaled = true
    bestTitle.Font = Enum.Font.GothamBold
    bestTitle.Parent = bestFrame
    
    self.BestFloorLabel = Instance.new("TextLabel")
    self.BestFloorLabel.Name = "Value"
    self.BestFloorLabel.Size = UDim2.new(1, 0, 0, 24)
    self.BestFloorLabel.Position = UDim2.new(0, 0, 0, 22)
    self.BestFloorLabel.BackgroundTransparency = 1
    self.BestFloorLabel.Text = "1"
    self.BestFloorLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    self.BestFloorLabel.TextScaled = true
    self.BestFloorLabel.Font = Enum.Font.GothamBlack
    self.BestFloorLabel.Parent = bestFrame
    
    -- Floor Complete Animation
    self.FloorCompleteFrame = Instance.new("Frame")
    self.FloorCompleteFrame.Name = "FloorComplete"
    self.FloorCompleteFrame.Size = UDim2.new(0, 300, 0, 100)
    self.FloorCompleteFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    self.FloorCompleteFrame.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    self.FloorCompleteFrame.BorderSizePixel = 0
    self.FloorCompleteFrame.Visible = false
    self.FloorCompleteFrame.Parent = self.ScreenGui
    
    local completeCorner = Instance.new("UICorner")
    completeCorner.CornerRadius = UDim.new(0, 15)
    completeCorner.Parent = self.FloorCompleteFrame
    
    local completeLabel = Instance.new("TextLabel")
    completeLabel.Name = "Text"
    completeLabel.Size = UDim2.new(1, 0, 1, 0)
    completeLabel.BackgroundTransparency = 1
    completeLabel.Text = "FLOOR COMPLETE!"
    completeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    completeLabel.TextScaled = true
    completeLabel.Font = Enum.Font.GothamBlack
    completeLabel.Parent = self.FloorCompleteFrame
    
    -- Listen for server updates (with timeout)
    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        if not remotes then
            warn("HUD: Timed out waiting for Remotes folder")
            return
        end
        
        local floorUpdate = remotes:WaitForChild("FloorUpdate", 5)
        if not floorUpdate then
            warn("HUD: FloorUpdate remote not found")
            return
        end
        
        floorUpdate.OnClientEvent:Connect(function(currentFloor, bestFloor)
            self:UpdateFloors(currentFloor, bestFloor)
        end)
    end)
end

-- Update floor displays
function HUD:UpdateFloors(current, best)
    local oldCurrent = tonumber(self.CurrentFloorLabel.Text) or 1
    
    self.CurrentFloorLabel.Text = tostring(current)
    self.BestFloorLabel.Text = tostring(best)
    
    -- Color based on progress
    if current >= 100 then
        self.CurrentFloorLabel.TextColor3 = Color3.fromRGB(244, 67, 54) -- Red (hard)
    elseif current >= 50 then
        self.CurrentFloorLabel.TextColor3 = Color3.fromRGB(156, 39, 176) -- Purple
    elseif current >= 25 then
        self.CurrentFloorLabel.TextColor3 = Color3.fromRGB(255, 152, 0) -- Orange
    else
        self.CurrentFloorLabel.TextColor3 = Color3.fromRGB(76, 175, 80) -- Green
    end
    
    -- Show complete animation if floor changed
    if current > oldCurrent then
        self:ShowFloorComplete()
    end
end

-- Floor complete animation
function HUD:ShowFloorComplete()
    self.FloorCompleteFrame.Visible = true
    self.FloorCompleteFrame.Size = UDim2.new(0, 300, 0, 100)
    self.FloorCompleteFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    
    -- Pop in
    local tweenIn = TweenService:Create(
        self.FloorCompleteFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 350, 0, 120), Position = UDim2.new(0.5, -175, 0.5, -60)}
    )
    tweenIn:Play()
    
    -- Fade out after delay
    task.delay(1, function()
        local tweenOut = TweenService:Create(
            self.FloorCompleteFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        )
        tweenOut:Play()
        
        tweenOut.Completed:Connect(function()
            self.FloorCompleteFrame.Visible = false
            self.FloorCompleteFrame.BackgroundTransparency = 0
        end)
    end)
end

return HUD
