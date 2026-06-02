local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")

-- Load modules
local GameData = require(shared.game_data)
local FlightController = require(script.Parent.flight_controller)
local CameraController = require(script.Parent.camera_controller)
local CollectionTracker = require(script.Parent.collection_tracker)
local HUD = require(script.Parent.hud)
local PauseMenu = require(script.Parent.pause_menu)

-- State
local clientState = {
    initialized = false,
    stats = {
        rings = 0,
        altitude = 0,
        speed = 0
    },
    upgrades = {
        SPEED = 1,
        BOOST = 1,
        HANDLING = 1
    }
}

-- Remote events
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local StatsUpdate = remotes:WaitForChild("StatsUpdate")
local RingCollected = remotes:WaitForChild("RingCollected")
local WorldInit = remotes:WaitForChild("WorldInit")

-- Initialize client systems
local function initialize()
    if clientState.initialized then return end
    
    -- Wait for character
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    -- Find JetSky
    local jetSky = workspace:WaitForChild("JetSky_" .. player.UserId, 5)
    if not jetSky then
        warn("JetSky not found, waiting...")
        return
    end
    
    -- Initialize systems
    local finalStats = require(shared.upgrade_data).ComputeFinalStats({}, clientState.upgrades)
    
    FlightController:Init(jetSky, finalStats)
    CameraController:Init(jetSky)
    CollectionTracker:Init(jetSky, clientState)
    HUD:Init(player, clientState)
    PauseMenu:Init()
    
    -- Connect remote events
    StatsUpdate.OnClientEvent:Connect(function(newStats)
        for k, v in pairs(newStats) do
            clientState.stats[k] = v
        end
        HUD:UpdateStats(clientState.stats)
    end)
    
    RingCollected.OnClientEvent:Connect(function(value, total)
        clientState.stats.rings = total
        HUD:ShowRingCollected(value)
        HUD:UpdateStats(clientState.stats)
    end)
    
    -- Start update loop
    RunService.Heartbeat:Connect(function(dt)
        if not FlightController.IsActive then return end
        
        FlightController:Update(dt)
        CameraController:Update(dt, FlightController:GetVelocity())
        CollectionTracker:Update(dt)
        
        -- Update HUD stats
        clientState.stats.altitude = FlightController:GetAltitude()
        clientState.stats.speed = FlightController:GetSpeed()
        HUD:UpdateStats(clientState.stats)
    end)
    
    clientState.initialized = true
    print("[JetSkies] Client initialized")
end

-- Handle respawn
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    clientState.initialized = false
    initialize()
end)

-- Initial init
if player.Character then
    initialize()
end

-- World init from server
WorldInit.OnClientEvent:Connect(function(worldData)
    print("[JetSkies] World received:", #worldData.islands, "islands")
end)

print("[JetSkies] Client script loaded")
