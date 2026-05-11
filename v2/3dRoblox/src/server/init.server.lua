-- GraveGain 3D - Server Entry Point
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[Server] GraveGain 3D Server Started")
print("[Server] Script location:", script:GetFullName())

-- When init.server.lua is in ServerScriptService.Server, script.Parent is ServerScriptService.Server
-- But we need to find the actual folder containing the modules
local ServerFolder = script.Parent
if ServerFolder.Name ~= "Server" then
	-- If we're directly in ServerScriptService, find the Server folder
	ServerFolder = ServerFolder:FindFirstChild("Server")
	if not ServerFolder then
		error("[Server] Could not find Server folder!")
	end
end

print("[Server] Server folder:", ServerFolder:GetFullName())

-- List children of server folder
print("[Server] Children of server folder:")
for _, child in ipairs(ServerFolder:GetChildren()) do
	print("[Server]   -", child.Name, "(" .. child.ClassName .. ")")
end

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
print("[Server] Constants loaded")

local LobbyManager = require(ServerFolder:WaitForChild("lobby_manager"))
print("[Server] LobbyManager loaded")

local MissionManager = require(ServerFolder:WaitForChild("mission_manager"))
print("[Server] MissionManager loaded")

local LootManager = require(ServerFolder:WaitForChild("loot_manager"))
print("[Server] LootManager loaded")

print("[Server] Version:", Constants.VERSION)

-- Initialize systems
local lobby_manager = LobbyManager.new()
lobby_manager:initialize()

local mission_manager = MissionManager.new()
mission_manager:initialize()

local loot_manager = LootManager.new()
loot_manager:initialize()

-- MissionManager already listens for StartMission events in its initialize()
-- No duplicate handler needed here

print("[Server] All systems initialized and ready for players")
