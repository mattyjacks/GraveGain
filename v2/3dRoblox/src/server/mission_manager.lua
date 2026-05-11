-- Mission Manager - Orchestrates dungeon generation, spawning, and mission flow
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"))
local DungeonGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("dungeon_generator"))
local DungeonRenderer = require(script.Parent:WaitForChild("dungeon_renderer"))
local HordeSpawner = require(script.Parent:WaitForChild("horde_spawner"))
local GameManager = require(script.Parent:WaitForChild("game_manager"))

local MissionManager = {}
MissionManager.__index = MissionManager

function MissionManager.new()
	local self = setmetatable({}, MissionManager)
	
	self.dungeon_generator = nil
	self.dungeon_renderer = nil
	self.horde_spawner = nil
	self.game_manager = GameManager
	
	self.mission_active = false
	self.mission_start_time = 0
	self.mission_duration = 600
	
	self.update_connection = nil
	
	return self
end

function MissionManager:initialize()
	print("[MissionManager] Initializing...")
	
	-- Listen for mission start
	local events = ReplicatedStorage:WaitForChild("Events")
	local start_mission = events:WaitForChild("StartMission")
	
	start_mission.OnServerEvent:Connect(function(player, difficulty)
		self:start_mission(difficulty)
	end)
	
	print("[MissionManager] Initialized")
end

function MissionManager:start_mission(difficulty)
	if self.mission_active then
		print("[MissionManager] Mission already active")
		return
	end
	
	print("[MissionManager] Starting mission with difficulty:", Constants.DIFFICULTY_NAMES[difficulty])
	
	self.mission_active = true
	self.mission_start_time = tick()
	
	-- Generate dungeon
	self:_generate_dungeon()
	
	-- Spawn all players
	self:_spawn_all_players()
	
	-- Start horde spawner
	self:_start_horde_spawner(difficulty)
	
	-- Start update loop
	self:_start_update_loop()
	
	-- Update game state
	self.game_manager:set_game_state(Constants.GAME_STATES.IN_GAME)
	
	print("[MissionManager] Mission started")
end

function MissionManager:_generate_dungeon()
	print("[MissionManager] Generating dungeon...")
	
	self.dungeon_generator = DungeonGenerator.new()
	local dungeon_data = self.dungeon_generator:generate()
	
	print("[MissionManager] Dungeon generated with", #dungeon_data.rooms, "rooms")
	
	-- Render dungeon
	self.dungeon_renderer = DungeonRenderer.new(dungeon_data)
	self.dungeon_renderer:render()
	
	print("[MissionManager] Dungeon rendered")
end

function MissionManager:_spawn_all_players()
	local players = Players:GetPlayers()
	
	for _, player in ipairs(players) do
		if player.Character then
			player.Character:Destroy()
		end
		
		local player_data = self.game_manager:get_player_data(player.UserId)
		if player_data then
			local spawn_pos = self:_get_spawn_position(player_data.team)
			
			-- Trigger character spawn on server
			local CharacterSpawner = require(script.Parent:WaitForChild("character_spawner"))
			CharacterSpawner:spawn_character(player, player_data, spawn_pos)
			
			print("[MissionManager] Spawned player:", player.Name)
		end
	end
end

function MissionManager:_get_spawn_position(team)
	if not self.dungeon_generator then
		return CFrame.new(0, 5, 0)
	end
	
	local spawn_pos = self.dungeon_generator.spawn_position
	
	if team == "team_2" then
		spawn_pos = spawn_pos + Vector3.new(50, 0, 0)
	end
	
	return CFrame.new(spawn_pos)
end

function MissionManager:_start_horde_spawner(difficulty)
	print("[MissionManager] Starting horde spawner...")
	
	local dungeon_data = self.dungeon_generator and {
		rooms = self.dungeon_generator.rooms,
		enemy_spawn_points = self.dungeon_generator.enemy_spawn_points,
		tiles = self.dungeon_generator.tiles,
	} or {}
	
	self.horde_spawner = HordeSpawner.new(dungeon_data, difficulty)
	self.horde_spawner:initialize()
	
	-- Spawn initial wave
	self.horde_spawner:spawn_wave(Players:GetPlayers())
	
	print("[MissionManager] Horde spawner started")
end

function MissionManager:_start_update_loop()
	if self.update_connection then
		self.update_connection:Disconnect()
	end
	
	self.update_connection = RunService.Heartbeat:Connect(function(delta_time)
		self:_update_mission(delta_time)
	end)
end

function MissionManager:_update_mission(delta_time)
	if not self.mission_active then return end
	
	local players = Players:GetPlayers()
	
	-- Update horde spawner
	if self.horde_spawner then
		self.horde_spawner:update(delta_time, players)
	end
	
	-- Check mission end conditions
	self:_check_mission_end(players)
end

function MissionManager:_check_mission_end(players)
	local mission_elapsed = tick() - self.mission_start_time
	
	-- Check if all players are dead
	local all_dead = true
	for _, player in ipairs(players) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if player.Character.Humanoid.Health > 0 then
				all_dead = false
				break
			end
		end
	end
	
	if all_dead then
		self:end_mission(false)
		return
	end
	
	-- Check if mission time is up
	if mission_elapsed >= self.mission_duration then
		self:end_mission(true)
		return
	end
end

function MissionManager:end_mission(success)
	if not self.mission_active then return end
	
	self.mission_active = false
	
	if self.update_connection then
		self.update_connection:Disconnect()
	end
	
	local state = success and Constants.GAME_STATES.MISSION_COMPLETE or Constants.GAME_STATES.MISSION_FAILED
	self.game_manager:set_game_state(state)
	
	print("[MissionManager] Mission ended:", success and "SUCCESS" or "FAILED")
	
	-- Cleanup
	task.wait(5)
	self:_cleanup_mission()
end

function MissionManager:_cleanup_mission()
	if self.dungeon_renderer then
		self.dungeon_renderer:cleanup()
	end
	
	if self.horde_spawner and self.horde_spawner.horde_folder then
		self.horde_spawner.horde_folder:Destroy()
	end
	
	print("[MissionManager] Mission cleaned up")
end

function MissionManager:get_mission_stats()
	if not self.mission_active then
		return nil
	end
	
	return {
		wave_number = self.horde_spawner and self.horde_spawner:get_wave_number() or 0,
		active_enemies = self.horde_spawner and self.horde_spawner:get_active_enemy_count() or 0,
		director_intensity = self.horde_spawner and self.horde_spawner:get_director_intensity() or 0,
		elapsed_time = tick() - self.mission_start_time,
	}
end

return MissionManager
