-- Maze Runner - Main Server Script

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create additional remotes
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local setFog = Instance.new("RemoteEvent")
setFog.Name = "SetFog"
setFog.Parent = remotes

local gameFinished = Instance.new("RemoteEvent")
gameFinished.Name = "GameFinished"
gameFinished.Parent = remotes

-- Initialize game manager
local GameManager = require(ReplicatedStorage.Shared.game_manager)
GameManager:Initialize()

print("Maze Runner server started!")
