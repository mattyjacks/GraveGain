-- BattleSharks Anti-Cheat Manager (G)
-- Server-side security and exploit prevention

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local AntiCheatManager = {}

-- PRIVATE VARIABLES
local playerHistory = {} -- Movement history for detection
local rateLimitData = {} -- Rate limiting per player
local actionLogs = {} -- Transaction logs
local violations = {} -- Violation counts
local bannedPlayers = {} -- Temporary ban list

-- CONFIGURATION
local ANTICHEAT_CONFIG = {
	MaxSpeed = GameConstants.SHARK_BOOST_SPEED * 1.2, -- Absolute max speed
	TeleportThreshold = 50, -- Distance to trigger teleport detection
	PositionHistorySize = 60, -- 3 seconds at 20Hz
	MaxViolations = 3, -- Before kick
	RateLimitWindow = 1.0, -- Seconds
	MaxActionsPerWindow = 10, -- Max actions in window
	MaxDamagePerHit = 200, -- Max damage sanity check
	MaxInventoryValue = 100000, -- Max total inventory value
	LogRetention = 3600 -- Keep logs for 1 hour
}

-- INITIALIZATION
function AntiCheatManager.Initialize()
	GameUtilities.DebugPrint("AntiCheatManager: Initializing")
	
	Players.PlayerAdded:Connect(AntiCheatManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(AntiCheatManager.OnPlayerRemoving)
	
	-- Cleanup old logs periodically
	task.spawn(function()
		while true do
			task.wait(60)
			AntiCheatManager.CleanupOldLogs()
		end
	end)
	
	GameUtilities.DebugPrint("AntiCheatManager: Initialized")
end

function AntiCheatManager.OnPlayerAdded(player)
	playerHistory[player.UserId] = {
		positions = {},
		timestamps = {},
		index = 0
	}
	rateLimitData[player.UserId] = {}
	actionLogs[player.UserId] = {}
	violations[player.UserId] = 0
end

function AntiCheatManager.OnPlayerRemoving(player)
	playerHistory[player.UserId] = nil
	rateLimitData[player.UserId] = nil
	actionLogs[player.UserId] = nil
	violations[player.UserId] = nil
end

-- POSITION VALIDATION (G1, G2, G3)
function AntiCheatManager.ValidateMovement(player, newPosition, timestamp)
	if not player or not player.Character then return false end
	
	local history = playerHistory[player.UserId]
	if not history then return true end -- First movement
	
	local currentPos = player.Character.PrimaryPart and player.Character.PrimaryPart.Position
	if not currentPos then return true end
	
	-- Record position
	history.index = (history.index % ANTICHEAT_CONFIG.PositionHistorySize) + 1
	history.positions[history.index] = currentPos
	history.timestamps[history.index] = timestamp or tick()
	
	-- Calculate speed
	local lastIndex = history.index - 1
	if lastIndex < 1 then lastIndex = ANTICHEAT_CONFIG.PositionHistorySize end
	
	local lastPos = history.positions[lastIndex]
	local lastTime = history.timestamps[lastIndex]
	
	if lastPos and lastTime then
		local distance = (newPosition - lastPos).Magnitude
		local timeDelta = (timestamp or tick()) - lastTime
		
		if timeDelta > 0 then
			local speed = distance / timeDelta
			
			-- Speed check (G2)
			if speed > ANTICHEAT_CONFIG.MaxSpeed then
				AntiCheatManager.FlagViolation(player, "SPEED_HACK", {
					Speed = speed,
					MaxAllowed = ANTICHEAT_CONFIG.MaxSpeed,
					Distance = distance,
					TimeDelta = timeDelta
				})
				return false
			end
			
			-- Teleport detection (G3)
			if distance > ANTICHEAT_CONFIG.TeleportThreshold and timeDelta < 0.1 then
				AntiCheatManager.FlagViolation(player, "TELEPORT", {
					Distance = distance,
					TimeDelta = timeDelta
				})
				return false
			end
		end
	end
	
	-- World boundary check
	local halfX = GameConstants.OCEAN_SIZE.X / 2
	local halfZ = GameConstants.OCEAN_SIZE.Y / 2
	if math.abs(newPosition.X) > halfX or math.abs(newPosition.Z) > halfZ then
		AntiCheatManager.FlagViolation(player, "BOUNDARY_ESCAPE", {
			Position = newPosition
		})
		return false
	end
	
	return true
end

-- RATE LIMITING (G6)
function AntiCheatManager.CheckRateLimit(player, actionType)
	local playerData = rateLimitData[player.UserId]
	if not playerData then return true end
	
	local now = tick()
	playerData[actionType] = playerData[actionType] or {}
	
	-- Clean old entries
	local validEntries = {}
	for _, timestamp in pairs(playerData[actionType]) do
		if now - timestamp < ANTICHEAT_CONFIG.RateLimitWindow then
			table.insert(validEntries, timestamp)
		end
	end
	playerData[actionType] = validEntries
	
	-- Check limit
	if #validEntries >= ANTICHEAT_CONFIG.MaxActionsPerWindow then
		AntiCheatManager.FlagViolation(player, "RATE_LIMIT", {
			Action = actionType,
			Count = #validEntries,
			Window = ANTICHEAT_CONFIG.RateLimitWindow
		})
		return false
	end
	
	-- Record action
	table.insert(playerData[actionType], now)
	return true
end

-- DAMAGE VALIDATION (G4)
function AntiCheatManager.ValidateDamage(player, damage, target, attackType)
	-- Sanity check damage amount
	if damage > ANTICHEAT_CONFIG.MaxDamagePerHit then
		AntiCheatManager.FlagViolation(player, "IMPOSSIBLE_DAMAGE", {
			Damage = damage,
			MaxAllowed = ANTICHEAT_CONFIG.MaxDamagePerHit,
			AttackType = attackType
		})
		return false
	end
	
	-- Check if player can actually hit target
	if player.Character and target and target:IsA("Model") and target.PrimaryPart then
		local playerPos = player.Character.PrimaryPart and player.Character.PrimaryPart.Position
		local targetPos = target.PrimaryPart.Position
		
		if playerPos then
			local distance = (targetPos - playerPos).Magnitude
			local maxRange = GameConstants.BITE_RANGE * 1.5 -- Allow small buffer
			
			if distance > maxRange then
				AntiCheatManager.FlagViolation(player, "RANGE_HACK", {
					Distance = distance,
					MaxRange = maxRange
				})
				return false
			end
		end
	end
	
	-- Check rate limiting for attacks
	return AntiCheatManager.CheckRateLimit(player, "Attack")
end

-- REMOTEEVENT SECURITY (G7)
function AntiCheatManager.ValidateRemoteArgs(player, eventName, ...)
	local args = {...}
	
	-- Check argument count
	if #args > 10 then
		AntiCheatManager.FlagViolation(player, "ARGUMENT_FLOOD", {
			Event = eventName,
			ArgCount = #args
		})
		return false
	end
	
	-- Validate argument types
	for i, arg in pairs(args) do
		local argType = typeof(arg)
		
		-- Block suspicious types
		if argType == "Instance" and arg:IsA("Player") and arg ~= player then
			AntiCheatManager.FlagViolation(player, "PLAYER_SPOOFING", {
				Event = eventName,
				ArgIndex = i
			})
			return false
		end
		
		-- Check Vector3 for NaN/inf
		if argType == "Vector3" then
			if arg.X ~= arg.X or arg.Y ~= arg.Y or arg.Z ~= arg.Z then -- NaN check
				AntiCheatManager.FlagViolation(player, "NAN_INJECTION", {
					Event = eventName,
					ArgIndex = i
				})
				return false
			end
		end
	end
	
	return true
end

-- INVENTORY LOGGING (G5)
function AntiCheatManager.LogTransaction(player, action, itemId, quantity, value)
	local log = {
		Timestamp = GameUtilities.GetTimestamp(),
		PlayerId = player.UserId,
		PlayerName = player.Name,
		Action = action,
		ItemId = itemId,
		Quantity = quantity,
		Value = value
	}
	
	if not actionLogs[player.UserId] then
		actionLogs[player.UserId] = {}
	end
	
	table.insert(actionLogs[player.UserId], log)
	
	-- Validate transaction
	if action == "Purchase" then
		-- Check if player actually has the gold
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		local data = PlayerDataManager.GetPlayerData(player.UserId)
		if data and value and data.Gold < value then
			AntiCheatManager.FlagViolation(player, "INSUFFICIENT_FUNDS", log)
			return false
		end
	elseif action == "Sell" then
		-- Check if player actually has the item
		local hasItem = false
		local PlayerDataManager = require(script.Parent.PlayerDataManager)
		local data = PlayerDataManager.GetPlayerData(player.UserId)
		if data and data.Inventory then
			for _, item in pairs(data.Inventory) do
				if item.Id == itemId then
					hasItem = true
					break
				end
			end
		end
		if not hasItem then
			AntiCheatManager.FlagViolation(player, "ITEM_NOT_OWNED", log)
			return false
		end
	end
	
	return true
end

-- VIOLATION HANDLING
function AntiCheatManager.FlagViolation(player, violationType, details)
	violations[player.UserId] = (violations[player.UserId] or 0) + 1
	
	GameUtilities.LogWarning(string.format("AntiCheat: %s violated %s (Count: %d)",
		player.Name, violationType, violations[player.UserId]))
	
	-- Log violation
	local violation = {
		Timestamp = GameUtilities.GetTimestamp(),
		Type = violationType,
		Details = details
	}
	
	-- Take action based on violation count
	if violations[player.UserId] >= ANTICHEAT_CONFIG.MaxViolations then
		AntiCheatManager.PunishPlayer(player, "Too many violations")
	else
		-- Notify client
		local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
		if remoteFolder then
			local warnEvent = remoteFolder:FindFirstChild("Warning")
			if warnEvent then
				warnEvent:FireClient(player, "Suspicious activity detected")
			end
		end
	end
end

function AntiCheatManager.PunishPlayer(player, reason)
	GameUtilities.LogWarning("AntiCheat: Punishing " .. player.Name .. " - " .. reason)
	
	-- Reset character
	if player.Character then
		player.Character:BreakJoints()
	end
	
	-- Kick if too many violations
	if violations[player.UserId] >= ANTICHEAT_CONFIG.MaxViolations * 2 then
		player:Kick("Exploiting detected. Fair play keeps the game fun for everyone!")
		bannedPlayers[player.UserId] = GameUtilities.GetTimestamp() + 3600 -- 1 hour temp ban
	end
end

-- LOG RETRIEVAL
function AntiCheatManager.GetPlayerLogs(player)
	return actionLogs[player.UserId] or {}
end

function AntiCheatManager.CleanupOldLogs()
	local cutoff = GameUtilities.GetTimestamp() - ANTICHEAT_CONFIG.LogRetention
	
	for userId, logs in pairs(actionLogs) do
		local filtered = {}
		for _, log in pairs(logs) do
			if log.Timestamp > cutoff then
				table.insert(filtered, log)
			end
		end
		actionLogs[userId] = filtered
	end
end

-- PUBLIC API
function AntiCheatManager.IsPlayerBanned(userId)
	if bannedPlayers[userId] then
		if GameUtilities.GetTimestamp() < bannedPlayers[userId] then
			return true
		else
			bannedPlayers[userId] = nil
			return false
		end
	end
	return false
end

function AntiCheatManager.GetViolationCount(player)
	return violations[player.UserId] or 0
end

function AntiCheatManager.ResetViolations(player)
	violations[player.UserId] = 0
end

function AntiCheatManager.Cleanup()
	playerHistory = {}
	rateLimitData = {}
	actionLogs = {}
	violations = {}
	bannedPlayers = {}
end

return AntiCheatManager
