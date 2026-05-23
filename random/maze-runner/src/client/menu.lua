-- Maze Runner - Client Menu

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Menu = {}

local player = Players.LocalPlayer

function Menu:Initialize()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "MazeRunnerMenu"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 400, 0, 60)
    title.Position = UDim2.new(0.5, -200, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "MAZE RUNNER"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = self.ScreenGui
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0, 400, 0, 30)
    subtitle.Position = UDim2.new(0.5, -200, 0, 110)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Escape the procedurally generated maze!"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = self.ScreenGui
    
    -- Difficulty buttons
    local difficulties = {"Easy", "Medium", "Hard", "Insane"}
    local colors = {
        Color3.fromRGB(76, 175, 80),
        Color3.fromRGB(255, 193, 7),
        Color3.fromRGB(255, 87, 34),
        Color3.fromRGB(244, 67, 54),
    }
    
    for i, diff in ipairs(difficulties) do
        local button = Instance.new("TextButton")
        button.Name = diff .. "Button"
        button.Size = UDim2.new(0, 200, 0, 50)
        button.Position = UDim2.new(0.5, -100, 0.3, (i - 1) * 70)
        button.BackgroundColor3 = colors[i]
        button.Text = diff:upper()
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.Parent = self.ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = button
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 220, 0, 55)}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(0, 200, 0, 50)}):Play()
        end)
        
        -- Click to start
        button.MouseButton1Click:Connect(function()
            self:StartGame(diff)
        end)
    end
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0, 500, 0, 100)
    instructions.Position = UDim2.new(0.5, -250, 0.7, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Find the GOLD portal to escape!\nCollect powerups for boosts.\nBeat the clock!"
    instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.Gotham
    instructions.TextWrapped = true
    instructions.Parent = self.ScreenGui
end

function Menu:StartGame(difficulty)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local startGame = remotes:WaitForChild("StartGame")
    
    -- Hide menu
    self.ScreenGui.Enabled = false
    
    -- Call server to start
    local result = startGame:InvokeServer(difficulty)
    
    if result then
        -- Show HUD
        local HUD = require(script.Parent.hud)
        HUD:Show(result.timeLimit)
    end
end

function Menu:Show()
    self.ScreenGui.Enabled = true
    
    -- Hide HUD
    local HUD = require(script.Parent.hud)
    HUD:Hide()
end

return Menu
