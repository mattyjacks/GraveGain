-- Color Rush - Client Controller
-- Handles player input and scrolling level

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.config)

local Controller = {}

local player = Players.LocalPlayer
local scrollConnection = nil
local currentSection = 1
local levelSpeed = Config.SCROLL_SPEED_BASE

function Controller:Start(gameData)
    self.GameData = gameData
    self.IsPlaying = true
    currentSection = 1
    levelSpeed = Config.SCROLL_SPEED_BASE
    
    -- Setup level scrolling
    local levelFolder = workspace:FindFirstChild("Level_" .. player.UserId)
    if not levelFolder then return end
    
    -- Start scrolling
    if scrollConnection then
        scrollConnection:Disconnect()
    end
    
    scrollConnection = RunService.Heartbeat:Connect(function(dt)
        self:UpdateLevelScroll(levelFolder, dt)
    end)
    
    -- Setup input
    self:SetupInput()
    
    -- Setup collision detection
    self:SetupCollision(levelFolder)
end

function Controller:Stop()
    self.IsPlaying = false
    
    if scrollConnection then
        scrollConnection:Disconnect()
        scrollConnection = nil
    end
end

function Controller:UpdateLevelScroll(levelFolder, dt)
    if not self.IsPlaying then return end
    
    -- Move all parts backward (towards player)
    for _, part in ipairs(levelFolder:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "KillZone" then
            part.Position = part.Position - Vector3.new(0, 0, levelSpeed * dt)
        end
    end
    
    -- Increase speed over time
    levelSpeed = math.min(
        levelSpeed + (Config.SPEED_INCREMENT * dt * 0.1),
        Config.SCROLL_SPEED_MAX
    )
end

function Controller:SetupInput()
    -- Color change keys
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local newColor = nil
        
        if input.KeyCode == Enum.KeyCode.Q then
            newColor = Config.COLORS[1] -- Red
        elseif input.KeyCode == Enum.KeyCode.W then
            newColor = Config.COLORS[2] -- Green
        elseif input.KeyCode == Enum.KeyCode.E then
            newColor = Config.COLORS[3] -- Blue
        elseif input.KeyCode == Enum.KeyCode.R then
            newColor = Config.COLORS[4] -- Yellow
        end
        
        if newColor then
            self:ChangeColor(newColor)
        end
    end)
end

function Controller:ChangeColor(color)
    if not self.IsPlaying then return end
    
    -- Update player color
    if player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Color = color
            end
        end
    end
    
    -- Notify server
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local playerAction = remotes:WaitForChild("PlayerAction")
    playerAction:FireServer("ChangeColor", {color = color})
    
    self.CurrentColor = color
end

function Controller:SetupCollision(levelFolder)
    -- Platform collision detection
    player.CharacterAdded:Connect(function(char)
        local rootPart = char:WaitForChild("HumanoidRootPart")
        
        -- Continuous collision check
        task.spawn(function()
            while char and char.Parent and self.IsPlaying do
                self:CheckPlatformCollision(char, levelFolder)
                task.wait(0.1)
            end
        end)
    end)
    
    -- Powerup collision
    for _, part in ipairs(levelFolder:GetDescendants()) do
        if part:IsA("BasePart") and part:GetAttribute("Type") then
            part.Touched:Connect(function(hit)
                local char = hit.Parent
                if char == player.Character then
                    local powerupType = part:GetAttribute("Type")
                    
                    local remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local playerAction = remotes:WaitForChild("PlayerAction")
                    playerAction:FireServer("CollectPowerup", {type = powerupType})
                    
                    part:Destroy()
                end
            end)
        end
    end
end

function Controller:CheckPlatformCollision(char, levelFolder)
    if not self.IsPlaying then return end
    if not self.CurrentColor then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local playerPos = rootPart.Position
    local onPlatform = false
    local colorMatched = false
    
    for _, part in ipairs(levelFolder:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:match("Platform") then
            -- Check if player is above platform
            local pos = part.Position
            local size = part.Size
            
            local dx = math.abs(playerPos.X - pos.X)
            local dz = math.abs(playerPos.Z - pos.Z)
            local dy = playerPos.Y - pos.Y
            
            if dx < size.X/2 and dz < size.Z/2 and dy > 0 and dy < 10 then
                onPlatform = true
                
                -- Check color match
                if part.Color == self.CurrentColor then
                    colorMatched = true
                end
                
                break
            end
        end
    end
    
    -- Report to server
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local playerAction = remotes:WaitForChild("PlayerAction")
    
    if onPlatform and colorMatched then
        playerAction:FireServer("Score", {points = Config.SCORE_PER_PLATFORM})
    elseif onPlatform and not colorMatched then
        playerAction:FireServer("Miss", {})
    end
end

return Controller
