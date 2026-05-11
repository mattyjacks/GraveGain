-- Server-side Game Manager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("player_data"))

local GameManager = {}
GameManager.__index = GameManager

local game_state = Constants.GAME_STATES.LOBBY
local players_in_game = {}
local team_assignments = {
	team_1 = {},
	team_2 = {},
}
local current_difficulty = Constants.DIFFICULTIES.NORMAL
local mission_start_time = 0
local mission_elapsed_time = 0

function GameManager.new()
	local self = setmetatable({}, GameManager)
	return self
end

function GameManager:initialize()
	print("[GameManager] Initializing...")
	
	-- Create RemoteEvents for client-server communication
	local events_folder = Instance.new("Folder")
	events_folder.Name = "Events"
	events_folder.Parent = ReplicatedStorage
	
	local player_joined = Instance.new("RemoteEvent")
	player_joined.Name = "PlayerJoined"
	player_joined.Parent = events_folder
	
	local start_mission = Instance.new("RemoteEvent")
	start_mission.Name = "StartMission"
	start_mission.Parent = events_folder
	
	local player_died = Instance.new("RemoteEvent")
	player_died.Name = "PlayerDied"
	player_died.Parent = events_folder
	
	local player_downed = Instance.new("RemoteEvent")
	player_downed.Name = "PlayerDowned"
	player_downed.Parent = events_folder
	
	local player_revived = Instance.new("RemoteEvent")
	player_revived.Name = "PlayerRevived"
	player_revived.Parent = events_folder
	
	local game_state_changed = Instance.new("RemoteEvent")
	game_state_changed.Name = "GameStateChanged"
	game_state_changed.Parent = events_folder
	
	print("[GameManager] RemoteEvents created")
end

function GameManager:assign_player_to_team(player_id)
	local team_1_count = #team_assignments.team_1
	local team_2_count = #team_assignments.team_2
	
	if team_1_count <= team_2_count and team_1_count < Constants.MAX_PLAYERS_PER_TEAM then
		table.insert(team_assignments.team_1, player_id)
		return "team_1"
	elseif team_2_count < Constants.MAX_PLAYERS_PER_TEAM then
		table.insert(team_assignments.team_2, player_id)
		return "team_2"
	end
	
	return nil
end

function GameManager:can_start_mission()
	local total_players = #team_assignments.team_1 + #team_assignments.team_2
	return total_players >= 1
end

function GameManager:start_mission(difficulty)
	if not self:can_start_mission() then
		return false
	end
	
	game_state = Constants.GAME_STATES.LOADING
	current_difficulty = difficulty or Constants.DIFFICULTIES.NORMAL
	mission_start_time = tick()
	mission_elapsed_time = 0
	
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		local state_changed = events:FindFirstChild("GameStateChanged")
		if state_changed then
			state_changed:FireAllClients(game_state, current_difficulty)
		end
	end
	
	print("[GameManager] Mission started on difficulty:", Constants.DIFFICULTY_NAMES[current_difficulty])
	return true
end

function GameManager:set_game_state(new_state)
	if new_state == game_state then return end
	
	game_state = new_state
	
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		local state_changed = events:FindFirstChild("GameStateChanged")
		if state_changed then
			state_changed:FireAllClients(game_state)
		end
	end
	
	print("[GameManager] Game state changed to:", game_state)
end

function GameManager:get_game_state()
	return game_state
end

function GameManager:get_mission_elapsed_time()
	if mission_start_time > 0 then
		mission_elapsed_time = tick() - mission_start_time
	end
	return mission_elapsed_time
end

function GameManager:get_team_players(team)
	return team_assignments[team] or {}
end

function GameManager:get_all_players()
	local all_players = {}
	for _, player_id in ipairs(team_assignments.team_1) do
		table.insert(all_players, player_id)
	end
	for _, player_id in ipairs(team_assignments.team_2) do
		table.insert(all_players, player_id)
	end
	return all_players
end

function GameManager:reset_teams()
	team_assignments.team_1 = {}
	team_assignments.team_2 = {}
end

function GameManager:get_difficulty_multiplier()
	return Constants.DIFFICULTY_MULTIPLIERS[current_difficulty] or 1.0
end

return GameManager
