-- Tower Hop - Main Client Script
-- Entry point for client-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD = require(script.Parent.hud)

-- Initialize
local function Initialize()
    -- Wait for player to be ready
    local player = Players.LocalPlayer
    
    -- Initialize HUD
    HUD:Initialize()
    
    print("Tower Hop client initialized!")
end

-- Start initialization
Initialize()
