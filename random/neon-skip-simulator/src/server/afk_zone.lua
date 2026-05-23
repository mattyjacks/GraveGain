--[[
    Neon Skip Simulator - AFK Zone (SAFETY VERSION)
    Handles auto-clicker area with time limits to prevent abuse
    
    SAFETY FEATURES:
    - AFK rewards cap at 60 minutes to prevent playtime inflation
    - Clear messaging about AFK mechanics
    - No permanent AFK farming
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.game_config)
local SafetyConfig = require(ReplicatedStorage.Shared.safety_config)

-- AFK Zone settings
local AFK_ZONE_POSITION = Vector3.new(50, 5, 0)
local AFK_ZONE_SIZE = Vector3.new(20, 10, 20)
local AFK_REWARD_INTERVAL = 1 -- seconds
local AFK_MOMENTUM_PER_INTERVAL = 1 -- base amount

-- Track players in AFK zone
local afkPlayers = {}
local afkStartTimes = {} -- Track when each player started AFK
local afkTotalRewards = {} -- Track total AFK rewards per session

-- Create AFK zone visual
local function createAFKZone()
    local zone = Instance.new("Part")
    zone.Name = "AFKZone"
    zone.Size = AFK_ZONE_SIZE
    zone.Position = AFK_ZONE_POSITION
    zone.Anchored = true
    zone.CanCollide = false
    zone.Transparency = 0.7
    zone.BrickColor = BrickColor.new("Bright green")
    zone.Material = Enum.Material.ForceField
    zone.Parent = workspace
    
    -- Billboard label
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.Adornee = zone
    billboard.Parent = zone
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⚡ AUTO-SKIP ZONE ⚡\nStand here for passive Momentum!"
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = billboard
    
    -- Neon border effect
    for i = 1, 4 do
        local edge = Instance.new("Part")
        edge.Size = Vector3.new(1, 1, AFK_ZONE_SIZE.Z)
        edge.Anchored = true
        edge.CanCollide = false
        edge.BrickColor = BrickColor.new("Bright green")
        edge.Material = Enum.Material.Neon
        edge.Transparency = 0.3
        edge.Parent = workspace
        
        if i == 1 then
            edge.Position = AFK_ZONE_POSITION + Vector3.new(-AFK_ZONE_SIZE.X/2, 0, 0)
        elseif i == 2 then
            edge.Position = AFK_ZONE_POSITION + Vector3.new(AFK_ZONE_SIZE.X/2, 0, 0)
        elseif i == 3 then
            edge.Size = Vector3.new(AFK_ZONE_SIZE.X, 1, 1)
            edge.Position = AFK_ZONE_POSITION + Vector3.new(0, 0, -AFK_ZONE_SIZE.Z/2)
        else
            edge.Size = Vector3.new(AFK_ZONE_SIZE.X, 1, 1)
            edge.Position = AFK_ZONE_POSITION + Vector3.new(0, 0, AFK_ZONE_SIZE.Z/2)
        end
    end
    
    -- Particle effect
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, AFK_ZONE_SIZE.Y/2, 0)
    attachment.Parent = zone
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 10
    particles.Speed = NumberRange.new(2, 5)
    particles.SpreadAngle = Vector2.new(0, 0)
    particles.Acceleration = Vector3.new(0, 2, 0)
    particles.Parent = attachment
end

-- Check if position is in AFK zone
local function isInAFKZone(position)
    local halfSize = AFK_ZONE_SIZE / 2
    local relative = position - AFK_ZONE_POSITION
    
    return math.abs(relative.X) <= halfSize.X and
           math.abs(relative.Y) <= halfSize.Y and
           math.abs(relative.Z) <= halfSize.Z
end

-- Check all players
local function checkPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if not character then continue end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local inZone = isInAFKZone(hrp.Position)
        local wasInZone = afkPlayers[player.UserId]
        
        if inZone and not wasInZone then
            -- Player entered AFK zone
            afkPlayers[player.UserId] = true
            afkStartTimes[player.UserId] = tick()
            afkTotalRewards[player.UserId] = 0
            notifyPlayer(player, "⚡ AFK Zone Active! (60 min max for balance) ⚡")
        elseif not inZone and wasInZone then
            -- Player left AFK zone
            afkPlayers[player.UserId] = nil
            afkStartTimes[player.UserId] = nil
            afkTotalRewards[player.UserId] = nil
            notifyPlayer(player, "👋 Left AFK Zone")
        end
    end
end

-- Notify player
local function notifyPlayer(player, message)
    local success, _ = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local remoteEvent = ReplicatedStorage:FindFirstChild("ShowNotification")
        if remoteEvent then
            remoteEvent:FireClient(player, message)
        end
    end)
end

-- Give AFK rewards (with safety limits)
local function giveAFKRewards()
    for userId, _ in pairs(afkPlayers) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then 
            afkPlayers[userId] = nil
            afkStartTimes[userId] = nil
            continue 
        end
        
        -- Check AFK time limit
        local afkStartTime = afkStartTimes[userId]
        if afkStartTime then
            local afkDurationMinutes = (tick() - afkStartTime) / 60
            
            -- Stop rewards after max AFK time
            if afkDurationMinutes >= SafetyConfig.AFK.MAX_AFK_TIME_MINUTES then
                -- Only notify once when limit is reached
                if not player:GetAttribute("AFKLimitReached") then
                    player:SetAttribute("AFKLimitReached", true)
                    notifyPlayer(player, "⏸️ " .. SafetyConfig.AFK.REWARD_STOP_MESSAGE)
                end
                continue -- Skip giving rewards
            else
                player:SetAttribute("AFKLimitReached", nil)
            end
        end
        
        local leaderstats = player:FindFirstChild("leaderstats")
        if not leaderstats then continue end
        
        local momentumStat = leaderstats:FindFirstChild("Momentum")
        if not momentumStat then continue end
        
        -- Safety cap check
        if momentumStat.Value >= SafetyConfig.DATA.MAX_MOMENTUM then
            continue
        end
        
        -- Calculate reward (scales with rebirths)
        local reward = AFK_MOMENTUM_PER_INTERVAL
        
        local rebirthStat = leaderstats:FindFirstChild("Rebirths")
        if rebirthStat and rebirthStat.Value > 0 then
            for i = #GameConfig.REBIRTHS, 1, -1 do
                if rebirthStat.Value >= GameConfig.REBIRTHS[i].tier then
                    reward = reward * GameConfig.REBIRTHS[i].multiplier
                    break
                end
            end
        end
        
        -- Apply reward with cap check
        local newValue = momentumStat.Value + math.floor(reward)
        if newValue > SafetyConfig.DATA.MAX_MOMENTUM then
            newValue = SafetyConfig.DATA.MAX_MOMENTUM
        end
        momentumStat.Value = newValue
        
        -- Track total AFK rewards
        if not afkTotalRewards[userId] then
            afkTotalRewards[userId] = 0
        end
        afkTotalRewards[userId] = afkTotalRewards[userId] + math.floor(reward)
    end
end

-- Setup
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(2) -- Wait for character to settle
        afkPlayers[player.UserId] = nil
        afkStartTimes[player.UserId] = nil
        afkTotalRewards[player.UserId] = nil
        player:SetAttribute("AFKLimitReached", nil)
    end)
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
    afkPlayers[player.UserId] = nil
    afkStartTimes[player.UserId] = nil
    afkTotalRewards[player.UserId] = nil
end)

-- Create zone on startup
task.wait(1)
createAFKZone()

-- Main loop
while true do
    task.wait(1)
    checkPlayers()
end

-- Reward loop
while true do
    task.wait(AFK_REWARD_INTERVAL)
    giveAFKRewards()
end
