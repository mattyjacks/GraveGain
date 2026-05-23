-- Tower Hop - Main Server Script
-- Entry point for server-side logic

print("[SERVER] Tower Hop server script starting...")

local success, err = pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")
    local Players = game:GetService("Players")
    
    print("[SERVER] Services acquired")
    
    -- Don't wait for game.Loaded in Studio - it can hang
    -- Just proceed immediately
    print("[SERVER] Starting initialization...")
    
    -- Seed random number generator
    math.randomseed(tick())
    
    -- Create remote events folder
    local remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
    print("[SERVER] Created Remotes folder")
    
    -- Create FloorUpdate remote event
    local floorUpdate = Instance.new("RemoteEvent")
    floorUpdate.Name = "FloorUpdate"
    floorUpdate.Parent = remotes
    print("[SERVER] Created FloorUpdate remote")
    
    -- Initialize game manager (use relative path for server)
    print("[SERVER] Loading game_manager...")
    local GameManager = require(script.Parent.game_manager)
    print("[SERVER] game_manager loaded:", GameManager ~= nil)
    
    -- Check if GameManager loaded properly
    if GameManager and GameManager.Initialize then
        print("[SERVER] Calling GameManager:Initialize()...")
        GameManager:Initialize()
        print("[SERVER] Tower Hop server started successfully!")
    else
        warn("[SERVER] GameManager failed to load properly")
    end
end)

if not success then
    warn("[SERVER] CRITICAL ERROR: " .. tostring(err))
end
