local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")

-- Load modules
local GameData = require(shared.game_data)
local FlightController = require(script.Parent.flight_controller_simple)
local CameraController = require(script.Parent.camera_controller)
local CollectionTracker = require(script.Parent.collection_tracker)
local HUD = require(script.Parent.hud)
local PauseMenu = require(script.Parent.pause_menu)
local TutorialUI = require(script.Parent.tutorial_ui)

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

-- Initialize client systems
local function initialize()
    if clientState.initialized then return end
    
    -- Show tutorial immediately while world generates
    local showedTutorial = false
    task.spawn(function()
        showedTutorial = TutorialUI:Init(player)
        if showedTutorial then
            print("[JetSkies] First-time tutorial shown")
        end
    end)
    
    -- Wait for remotes first
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if not remotes then
        warn("Remotes folder not found!")
        return
    end
    
    local StatsUpdate = remotes:WaitForChild("StatsUpdate", 5)
    local RingCollected = remotes:WaitForChild("RingCollected", 5)
    local WorldInit = remotes:WaitForChild("WorldInit", 5)
    
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
    
    -- Find seat in the detailed model
    local seat = jetSky:WaitForChild("Seat", 2)
    
    -- Initialize systems
    local finalStats = require(shared.upgrade_data).ComputeFinalStats({}, clientState.upgrades)
    
    FlightController:Init(jetSky, seat, finalStats)
    CameraController:Init(jetSky)
    CollectionTracker:Init(jetSky, clientState)
    HUD:Init(player, clientState)
    PauseMenu:Init()
    
    -- Connect remote events
    if StatsUpdate then
        StatsUpdate.OnClientEvent:Connect(function(newStats)
            for k, v in pairs(newStats) do
                clientState.stats[k] = v
            end
            HUD:UpdateStats(clientState.stats)
        end)
    end
    
    if RingCollected then
        RingCollected.OnClientEvent:Connect(function(value, total)
            clientState.stats.rings = total
            HUD:ShowRingCollected(value)
            HUD:UpdateStats(clientState.stats)
        end)
    end
    
    -- Start update loop
    RunService.Heartbeat:Connect(function(dt)
        if not FlightController.IsActive() then return end
        
        local flightState = FlightController:Update(dt)
        CameraController:Update(dt, FlightController:GetVelocity())
        CollectionTracker:Update(dt)
        
        -- Update HUD stats from realistic flight controller
        clientState.stats.altitude = flightState.altitude
        clientState.stats.speed = flightState.speed
        clientState.stats.rings = clientState.stats.rings or 0
        HUD:UpdateStats(clientState.stats)
        
        -- Update throttle display
        HUD:UpdateThrottle(flightState.throttle)
        
        -- Update water mode indicator
        HUD:SetWaterMode(flightState.isInWater)
    end)
    
    -- World init from server
    if WorldInit then
        WorldInit.OnClientEvent:Connect(function(worldData)
            print("[JetSkies] World received:", #worldData.islands, "islands")
            
            -- Notify tutorial that world is loaded
            if TutorialUI.WorldLoaded then
                TutorialUI:WorldLoaded()
            end
        end)
    end
    
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

print("[JetSkies] Client script loaded")
