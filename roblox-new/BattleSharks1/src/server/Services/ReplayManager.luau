-- BattleSharks Replay Manager (E8)
-- Replay recording and spectator system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local ReplayManager = {}

local REPLAY_CONFIG = { MaxDuration = 300, RecordInterval = 0.1 }
local activeRecordings = {}
local replays = {}
local spectators = {}

function ReplayManager.Initialize()
	GameUtilities.DebugPrint("ReplayManager: Initialized")
end

function ReplayManager.StartRecording(player)
	activeRecordings[player.UserId] = {
		Frames = {},
		StartTime = tick(),
		PlayerId = player.UserId,
		Events = {}
	}
	
	-- Recording loop
	task.spawn(function()
		while activeRecordings[player.UserId] do
			ReplayManager.RecordFrame(player)
			task.wait(REPLAY_CONFIG.RecordInterval)
			
			-- Auto stop at max duration
			local elapsed = tick() - activeRecordings[player.UserId].StartTime
			if elapsed > REPLAY_CONFIG.MaxDuration then
				ReplayManager.StopRecording(player)
				break
			end
		end
	end)
end

function ReplayManager.RecordFrame(player)
	local recording = activeRecordings[player.UserId]
	if not recording then return end
	if not player.Character then return end
	
	local primaryPart = player.Character.PrimaryPart
	if not primaryPart then return end
	
	table.insert(recording.Frames, {
		Time = tick() - recording.StartTime,
		Position = primaryPart.Position,
		Rotation = primaryPart.Rotation,
		Velocity = primaryPart.Velocity
	})
end

function ReplayManager.StopRecording(player)
	local recording = activeRecordings[player.UserId]
	if not recording then return nil end
	
	activeRecordings[player.UserId] = nil
	
	-- Save replay
	local replayId = player.UserId .. "_" .. math.floor(recording.StartTime)
	recording.Id = replayId
	replays[replayId] = recording
	
	return replayId
end

function ReplayManager.GetReplay(replayId)
	return replays[replayId]
end

function ReplayManager.StartSpectator(spectator, target)
	spectators[spectator.UserId] = {
		Target = target,
		StartTime = tick()
	}
	
	-- Hide spectator character
	if spectator.Character then
		spectator.Character:Destroy()
	end
	
	-- Switch camera
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local specEvent = remoteFolder:FindFirstChild("StartSpectating")
		if specEvent then
			specEvent:FireClient(spectator, target.UserId)
		end
	end
end

function ReplayManager.StopSpectator(spectator)
	spectators[spectator.UserId] = nil
	
	-- Respawn spectator
	spectator:LoadCharacter()
	
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local specEvent = remoteFolder:FindFirstChild("StopSpectating")
		if specEvent then
			specEvent:FireClient(spectator)
		end
	end
end

function ReplayManager.Cleanup()
	activeRecordings = {}
	replays = {}
	spectators = {}
end

return ReplayManager
