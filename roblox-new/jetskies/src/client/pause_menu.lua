local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PauseMenu = {}
local GameData

local ui = {screenGui = nil, mainFrame = nil, upgradeFrame = nil, isOpen = false}
local player

function PauseMenu:Init()
    GameData = require(ReplicatedStorage.Shared.game_data)
    player = Players.LocalPlayer
    self:CreatePauseMenu()
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Escape then self:TogglePause() end
    end)
end

function PauseMenu:CreatePauseMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PauseMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    ui.screenGui = screenGui
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.Parent = screenGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = GameData.UIColors.BACKGROUND
    frame.Parent = screenGui
    ui.mainFrame = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "JETSKIES"
    title.TextColor3 = GameData.UIColors.PRIMARY
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local resumeBtn = self:CreateButton("Resume", UDim2.new(0.5, -100, 0, 60), frame)
    resumeBtn.MouseButton1Click:Connect(function() self:TogglePause() end)
    
    local quitBtn = self:CreateButton("Quit", UDim2.new(0.5, -100, 0, 120), frame)
    quitBtn.MouseButton1Click:Connect(function()
        player:Kick("Thanks for playing JetSkies!")
    end)
end

function PauseMenu:CreateButton(text, position, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = GameData.UIColors.PRIMARY
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    return btn
end

function PauseMenu:TogglePause()
    ui.isOpen = not ui.isOpen
    ui.screenGui.Enabled = ui.isOpen
    -- Free mouse when paused, re-lock for flight when resumed
    UserInputService.MouseBehavior = ui.isOpen
        and Enum.MouseBehavior.Default
        or  Enum.MouseBehavior.LockCenter
end

return PauseMenu
