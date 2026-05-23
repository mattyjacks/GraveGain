-- Color Rush - Client Menu

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Menu = {}

local player = Players.LocalPlayer

function Menu:Initialize()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ColorRushMenu"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 500, 0, 80)
    title.Position = UDim2.new(0.5, -250, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "COLOR RUSH"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = self.ScreenGui
    
    -- Rainbow effect for title
    task.spawn(function()
        local hue = 0
        while title and title.Parent do
            title.TextColor3 = Color3.fromHSV(hue, 1, 1)
            hue = (hue + 0.01) % 1
            task.wait(0.05)
        end
    end)
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0, 400, 0, 30)
    subtitle.Position = UDim2.new(0.5, -200, 0, 110)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Match your color to survive!"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = self.ScreenGui
    
    -- Game mode buttons
    local modes = {
        {name = "Classic", desc = "3 lives, speed increases", color = Color3.fromRGB(76, 175, 80)},
        {name = "Endless", desc = "1 life, infinite run", color = Color3.fromRGB(33, 150, 243)},
        {name = "SpeedRun", desc = "Race to the finish!", color = Color3.fromRGB(255, 193, 7)},
    }
    
    for i, mode in ipairs(modes) do
        local button = Instance.new("TextButton")
        button.Name = mode.name .. "Button"
        button.Size = UDim2.new(0, 250, 0, 70)
        button.Position = UDim2.new(0.5, -125, 0.3, (i - 1) * 100)
        button.BackgroundColor3 = mode.color
        button.Text = ""
        button.Parent = self.ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 15)
        corner.Parent = button
        
        local modeName = Instance.new("TextLabel")
        modeName.Size = UDim2.new(1, 0, 0.5, 0)
        modeName.Position = UDim2.new(0, 0, 0, 5)
        modeName.BackgroundTransparency = 1
        modeName.Text = mode.name:upper()
        modeName.TextColor3 = Color3.fromRGB(255, 255, 255)
        modeName.TextScaled = true
        modeName.Font = Enum.Font.GothamBold
        modeName.Parent = button
        
        local modeDesc = Instance.new("TextLabel")
        modeDesc.Size = UDim2.new(1, 0, 0.4, 0)
        modeDesc.Position = UDim2.new(0, 0, 0.55, 0)
        modeDesc.BackgroundTransparency = 1
        modeDesc.Text = mode.desc
        modeDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
        modeDesc.TextScaled = true
        modeDesc.Font = Enum.Font.Gotham
        modeDesc.Parent = button
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 270, 0, 75)}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, 70)}):Play()
        end)
        
        -- Click to start
        button.MouseButton1Click:Connect(function()
            self:StartGame(mode.name)
        end)
    end
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0, 600, 0, 80)
    instructions.Position = UDim2.new(0.5, -300, 0.75, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Q = Red | W = Green | E = Blue | R = Yellow\nMatch your color to the platforms or FALL!"
    instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.GothamBold
    instructions.TextWrapped = true
    instructions.Parent = self.ScreenGui
end

function Menu:StartGame(gameMode)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local startGame = remotes:WaitForChild("StartGame")
    
    self.ScreenGui.Enabled = false
    
    local result = startGame:InvokeServer(gameMode)
    
    if result then
        local HUD = require(script.Parent.hud)
        local Controller = require(script.Parent.controller)
        
        HUD:Show(result.score, result.lives, result.currentColor)
        Controller:Start(result)
    end
end

function Menu:Show()
    self.ScreenGui.Enabled = true
    
    local HUD = require(script.Parent.hud)
    local Controller = require(script.Parent.controller)
    
    HUD:Hide()
    Controller:Stop()
end

return Menu
