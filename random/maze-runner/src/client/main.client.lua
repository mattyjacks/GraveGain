-- Maze Runner - Main Client Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Menu = require(script.Parent.menu)
local HUD = require(script.Parent.hud)

-- Initialize
local function Initialize()
    -- Setup fog events
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    local setFog = remotes:WaitForChild("SetFog")
    setFog.OnClientEvent:Connect(function(fogDensity)
        Lighting.FogStart = 10
        Lighting.FogEnd = 50 + (1 - fogDensity) * 100
        Lighting.FogColor = Color3.fromRGB(50, 50, 50)
    end)
    
    local gameFinished = remotes:WaitForChild("GameFinished")
    gameFinished.OnClientEvent:Connect(function(won, timeTaken, timeLimit)
        HUD:Hide()
        
        -- Show result
        local resultGui = Instance.new("ScreenGui")
        resultGui.Name = "Result"
        resultGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 400, 0, 200)
        frame.Position = UDim2.new(0.5, -200, 0.5, -100)
        frame.BackgroundColor3 = won and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
        frame.BorderSizePixel = 0
        frame.Parent = resultGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 20)
        corner.Parent = frame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 60)
        title.Position = UDim2.new(0, 0, 0, 20)
        title.BackgroundTransparency = 1
        title.Text = won and "ESCAPED!" or "TIME'S UP!"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextScaled = true
        title.Font = Enum.Font.GothamBlack
        title.Parent = frame
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(1, 0, 0, 40)
        timeLabel.Position = UDim2.new(0, 0, 0, 90)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = string.format("Time: %.1f seconds", timeTaken)
        timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timeLabel.TextScaled = true
        timeLabel.Font = Enum.Font.GothamBold
        timeLabel.Parent = frame
        
        local playAgain = Instance.new("TextButton")
        playAgain.Size = UDim2.new(0, 150, 0, 40)
        playAgain.Position = UDim2.new(0.5, -75, 1, -60)
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
            Menu:Show()
        end)
    end)
    
    local collectPowerup = remotes:WaitForChild("CollectPowerup")
    collectPowerup.OnClientEvent:Connect(function(powerupType)
        HUD:OnCollectPowerup(powerupType)
    end)
    
    -- Initialize UI
    Menu:Initialize()
    HUD:Initialize()
    
    print("Maze Runner client initialized!")
end

Initialize()
