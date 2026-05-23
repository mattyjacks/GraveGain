--[[
    Neon Skip Simulator - Leaderstats Handler (SAFETY VERSION)
    Manages player data with safety caps and validation
    
    SAFETY FEATURES:
    - Data caps to prevent integer overflow
    - Sanity checks on data load
    - Protected DataStore calls
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafetyConfig = require(ReplicatedStorage.Shared.safety_config)

local MomentumData = DataStoreService:GetDataStore("MomentumData_v1")
local RebirthData = DataStoreService:GetDataStore("RebirthData_v1")

-- Gamepass ownership tracking
local playerGamepasses = {}

-- Initialize leaderstats
Players.PlayerAdded:Connect(function(player)
    -- Load data
    local momentum = 0
    local rebirths = 0
    
    local success, result = pcall(function()
        return MomentumData:GetAsync(player.UserId)
    end)
    if success and result then
        momentum = result
    end
    
    success, result = pcall(function()
        return RebirthData:GetAsync(player.UserId)
    end)
    if success and result then
        rebirths = result
    end
    
    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- Safety cap on load
    if momentum > SafetyConfig.DATA.MAX_MOMENTUM then
        momentum = SafetyConfig.DATA.MAX_MOMENTUM
    end
    if rebirths > SafetyConfig.DATA.MAX_REBIRTHS then
        rebirths = SafetyConfig.DATA.MAX_REBIRTHS
    end
    
    local momentumStat = Instance.new("IntValue")
    momentumStat.Name = "Momentum"
    momentumStat.Value = momentum
    momentumStat.Parent = leaderstats
    
    -- Add safety clamping on value change
    momentumStat.Changed:Connect(function(newValue)
        if newValue > SafetyConfig.DATA.MAX_MOMENTUM then
            momentumStat.Value = SafetyConfig.DATA.MAX_MOMENTUM
        elseif newValue < 0 then
            momentumStat.Value = 0
        end
    end)
    
    local rebirthStat = Instance.new("IntValue")
    rebirthStat.Name = "Rebirths"
    rebirthStat.Value = rebirths
    rebirthStat.Parent = leaderstats
    
    -- Add safety clamping on value change
    rebirthStat.Changed:Connect(function(newValue)
        if newValue > SafetyConfig.DATA.MAX_REBIRTHS then
            rebirthStat.Value = SafetyConfig.DATA.MAX_REBIRTHS
        elseif newValue < 0 then
            rebirthStat.Value = 0
        end
    end)
    
    -- Check gamepass ownership
    playerGamepasses[player.UserId] = {}
    
    -- Set up save on leave
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            -- Save data
            pcall(function()
                MomentumData:SetAsync(player.UserId, momentumStat.Value)
                RebirthData:SetAsync(player.UserId, rebirthStat.Value)
            end)
        end
    end)
end)

-- Auto-save every 60 seconds
while true do
    task.wait(60)
    for _, player in ipairs(Players:GetPlayers()) do
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            pcall(function()
                MomentumData:SetAsync(player.UserId, leaderstats.Momentum.Value)
                RebirthData:SetAsync(player.UserId, leaderstats.Rebirths.Value)
            end)
        end
    end
end
