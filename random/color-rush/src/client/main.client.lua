-- Color Rush - Main Client Script

local Players = game:GetService("Players")

local Menu = require(script.Parent.menu)
local HUD = require(script.Parent.hud)

-- Initialize
local function Initialize()
    Menu:Initialize()
    HUD:Initialize()
    
    print("Color Rush client initialized!")
end

Initialize()
