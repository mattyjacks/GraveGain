-- Server-side Lobby Manager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("player_data"))
local GameManager = require(script.Parent:WaitForChild("game_manager"))

local LobbyManager = {}
LobbyManager.__index = LobbyManager

local lobby_players = {}
local player_selections = {}

function LobbyManager.new()
	local self = setmetatable({}, LobbyManager)
	return self
end

function LobbyManager:initialize()
	print("[LobbyManager] Initializing...")
	
	local game_manager = GameManager.new()
	game_manager:initialize()
	
	-- Create lobby platform so players don't fall into the void
	self:_create_lobby_platform()
	
	Players.PlayerAdded:Connect(function(player)
		self:on_player_joined(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:on_player_left(player)
	end)
	
	print("[LobbyManager] Initialized")
end

function LobbyManager:_create_lobby_platform()
	-- Create a Lobby folder in workspace
	local lobby_folder = Instance.new("Folder")
	lobby_folder.Name = "Lobby"
	lobby_folder.Parent = workspace
	self.lobby_folder = lobby_folder
	
	-- Create baseplate floor
	local baseplate = Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Shape = Enum.PartType.Block
	baseplate.Size = Vector3.new(100, 1, 100)
	baseplate.Position = Vector3.new(0, -0.5, 0)
	baseplate.Anchored = true
	baseplate.CanCollide = true
	baseplate.Material = Enum.Material.Slate
	baseplate.Color = Color3.fromRGB(60, 60, 70)
	baseplate.TopSurface = Enum.SurfaceType.Smooth
	baseplate.BottomSurface = Enum.SurfaceType.Smooth
	baseplate.Parent = lobby_folder
	
	-- Create SpawnLocation so players spawn on the platform
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(80, 120, 200)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby_folder
	
	-- Add some lobby lighting
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 60
	light.Color = Color3.fromRGB(200, 200, 255)
	light.Parent = spawn
	
	print("[LobbyManager] Lobby platform created")
end

function LobbyManager:cleanup_lobby()
	if self.lobby_folder then
		self.lobby_folder:Destroy()
		self.lobby_folder = nil
	end
end

function LobbyManager:on_player_joined(player)
	print("[LobbyManager] Player joined:", player.Name)
	
	lobby_players[player.UserId] = {
		player = player,
		username = player.Name,
		race = Constants.RACES.HUMAN,
		class_type = Constants.CLASSES.DPS,
		ready = false,
	}
	
	-- Create player data folder
	local player_data_folder = Instance.new("Folder")
	player_data_folder.Name = "PlayerData"
	player_data_folder.Parent = player
	
	-- Store player selection
	local race_value = Instance.new("IntValue")
	race_value.Name = "Race"
	race_value.Value = Constants.RACES.HUMAN
	race_value.Parent = player_data_folder
	
	local class_value = Instance.new("IntValue")
	class_value.Name = "Class"
	class_value.Value = Constants.CLASSES.DPS
	class_value.Parent = player_data_folder
	
	local ready_value = Instance.new("BoolValue")
	ready_value.Name = "Ready"
	ready_value.Value = false
	ready_value.Parent = player_data_folder
	
	-- Listen for selection changes
	race_value.Changed:Connect(function(new_value)
		self:on_race_selected(player.UserId, new_value)
	end)
	
	class_value.Changed:Connect(function(new_value)
		self:on_class_selected(player.UserId, new_value)
	end)
	
	ready_value.Changed:Connect(function(new_value)
		self:on_player_ready(player.UserId, new_value)
	end)
	
	self:broadcast_lobby_state()
end

function LobbyManager:on_player_left(player)
	print("[LobbyManager] Player left:", player.Name)
	
	lobby_players[player.UserId] = nil
	player_selections[player.UserId] = nil
	
	self:broadcast_lobby_state()
end

function LobbyManager:on_race_selected(player_id, race)
	if lobby_players[player_id] then
		lobby_players[player_id].race = race
		self:broadcast_lobby_state()
	end
end

function LobbyManager:on_class_selected(player_id, class_type)
	if lobby_players[player_id] then
		lobby_players[player_id].class_type = class_type
		self:broadcast_lobby_state()
	end
end

function LobbyManager:on_player_ready(player_id, ready)
	if lobby_players[player_id] then
		lobby_players[player_id].ready = ready
		self:broadcast_lobby_state()
		
		if self:all_players_ready() then
			self:start_game()
		end
	end
end

function LobbyManager:all_players_ready()
	if next(lobby_players) == nil then return false end
	
	for _, player_info in pairs(lobby_players) do
		if not player_info.ready then
			return false
		end
	end
	return true
end

function LobbyManager:broadcast_lobby_state()
	local lobby_state = {}
	
	for player_id, player_info in pairs(lobby_players) do
		table.insert(lobby_state, {
			player_id = player_id,
			username = player_info.username,
			race = player_info.race,
			class_type = player_info.class_type,
			ready = player_info.ready,
		})
	end
	
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		local player_joined = events:FindFirstChild("PlayerJoined")
		if player_joined then
			player_joined:FireAllClients(lobby_state)
		end
	end
end

function LobbyManager:start_game()
	print("[LobbyManager] Starting game...")
	
	GameManager:reset_teams()
	
	for player_id, player_info in pairs(lobby_players) do
		local team = GameManager:assign_player_to_team(player_id)
		
		local player_data = PlayerData.new(
			player_id,
			player_info.username,
			player_info.race,
			player_info.class_type
		)
		player_data.team = team
		
		player_selections[player_id] = player_data
		
		print("[LobbyManager] Player", player_info.username, "assigned to", team)
	end
	
	-- Clean up lobby platform before dungeon generates
	self:cleanup_lobby()
	
	GameManager:start_mission(Constants.DIFFICULTIES.NORMAL)
end

function LobbyManager:get_player_data(player_id)
	return player_selections[player_id]
end

return LobbyManager
