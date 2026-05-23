--[[
    Neon Skip Simulator - Gamepass Handler (SAFETY VERSION)
    Manages Auto-Skip and x2 Momentum with rate limiting
    
    SAFETY FEATURES:
    - Rate limiting on remote events
    - Input validation
    - Clear monetization (no gambling)
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.game_config)
local SafetyConfig = require(ReplicatedStorage.Shared.safety_config)

-- Cache of owned gamepasses
local ownedGamepasses = {}

-- Rate limiting tracking
local lastRemoteCall = {} -- Track last remote call time per player

-- Check if player owns a gamepass
local function ownsGamepass(player, gamepassId)
    local success, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
    end)
    
    if success then
        return result
    end
    
    return false
end

-- Update ownership cache
local function refreshGamepasses(player)
    if not ownedGamepasses[player.UserId] then
        ownedGamepasses[player.UserId] = {}
    end
    
    for passType, passData in pairs(GameConfig.GAMEPASSES) do
        ownedGamepasses[player.UserId][passType] = ownsGamepass(player, passData.id)
    end
    
    -- Notify client
    local remoteEvent = ReplicatedStorage:FindFirstChild("GamepassUpdate")
    if remoteEvent then
        remoteEvent:FireClient(player, ownedGamepasses[player.UserId])
    end
end

-- Get ownership status
function getPlayerGamepasses(player)
    return ownedGamepasses[player.UserId] or {}
end

-- Process purchase
local function processPurchase(player, productId)
    -- Check which gamepass was purchased
    for passType, passData in pairs(GameConfig.GAMEPASSES) do
        if passData.id == productId then
            -- Grant benefits
            if passType == "AUTO_SKIP" then
                -- Enable auto-skip for player
                local remoteEvent = ReplicatedStorage:FindFirstChild("EnableAutoSkip")
                if remoteEvent then
                    remoteEvent:FireClient(player)
                end
                
            elseif passType == "X2_MOMENTUM" then
                -- x2 momentum is checked in skip_controller
                -- Just notify it's active
                local remoteEvent = ReplicatedStorage:FindFirstChild("ShowNotification")
                if remoteEvent then
                    remoteEvent:FireClient(player, "✨ x2 Momentum is now ACTIVE! ✨")
                end
            end
            
            -- Refresh cache
            refreshGamepasses(player)
            
            return true
        end
    end
    
    return false
end

-- Setup remote events
local function setupRemotes()
    local remote = ReplicatedStorage:FindFirstChild("RequestGamepassCheck")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "RequestGamepassCheck"
        remote.Parent = ReplicatedStorage
    end
    
    remote.OnServerEvent:Connect(function(player)
        -- Rate limiting check
        local now = tick()
        local lastCall = lastRemoteCall[player.UserId] or 0
        if now - lastCall < 1 then -- Max 1 call per second
            return
        end
        lastRemoteCall[player.UserId] = now
        
        refreshGamepasses(player)
    end)
    
    -- Create gamepass update remote
    local updateRemote = ReplicatedStorage:FindFirstChild("GamepassUpdate")
    if not updateRemote then
        updateRemote = Instance.new("RemoteEvent")
        updateRemote.Name = "GamepassUpdate"
        updateRemote.Parent = ReplicatedStorage
    end
    
    -- Enable auto-skip remote
    local autoSkipRemote = ReplicatedStorage:FindFirstChild("EnableAutoSkip")
    if not autoSkipRemote then
        autoSkipRemote = Instance.new("RemoteEvent")
        autoSkipRemote.Name = "EnableAutoSkip"
        autoSkipRemote.Parent = ReplicatedStorage
    end
    
    -- Show notification remote
    local notifyRemote = ReplicatedStorage:FindFirstChild("ShowNotification")
    if not notifyRemote then
        notifyRemote = Instance.new("RemoteEvent")
        notifyRemote.Name = "ShowNotification"
        notifyRemote.Parent = ReplicatedStorage
    end
end

-- Handle prompt purchase finished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
    if wasPurchased then
        processPurchase(player, gamepassId)
    end
end)

-- Player added
Players.PlayerAdded:Connect(function(player)
    -- Wait for setup
    task.wait(3)
    
    -- Check gamepasses
    refreshGamepasses(player)
    
    -- Auto-enable auto-skip if owned
    local passes = ownedGamepasses[player.UserId]
    if passes and passes.AUTO_SKIP then
        local remoteEvent = ReplicatedStorage:FindFirstChild("EnableAutoSkip")
        if remoteEvent then
            remoteEvent:FireClient(player)
        end
    end
    
    -- Notify about x2 if owned
    if passes and passes.X2_MOMENTUM then
        local notifyRemote = ReplicatedStorage:FindFirstChild("ShowNotification")
        if notifyRemote then
            notifyRemote:FireClient(player, "✨ x2 Momentum gamepass active!")
        end
    end
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
    ownedGamepasses[player.UserId] = nil
end)

-- Initialize
task.wait(1)
setupRemotes()

-- Periodic refresh (every 60 seconds)
while true do
    task.wait(60)
    for _, player in ipairs(Players:GetPlayers()) do
        refreshGamepasses(player)
    end
end
