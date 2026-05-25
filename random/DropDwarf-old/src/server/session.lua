-- DropDwarf: session.lua
-- Manages multiplayer sessions: lobby grouping, mode, shared level state.
-- A session is created by the first player who picks a non-Singleplayer mode.
-- Other players join via RequestJoinSession, referencing the host's UserId.
-- On run start, all session members enter the same level instance together.

local Players    = game:GetService("Players")
local Networking = require(game.ReplicatedStorage.Shared.networking)
local GameMode   = require(game.ReplicatedStorage.Shared.game_mode)

local Session = {}

-- Active sessions keyed by hostUserId (string)
-- Each session: { hostUserId, modeId, members[], levelFolder, active, rescueStates, pvpCooldowns }
local sessions = {}
-- Reverse map: player -> sessionId (hostUserId string)
local playerSession = {}

-- ===================== INTERNAL HELPERS =====================

local function broadcastLobbyUpdate(sessionId)
    local s = sessions[sessionId]
    if not s then return end
    local memberData = {}
    for _, p in ipairs(s.members) do
        table.insert(memberData, { userId = p.UserId, name = p.Name })
    end
    for _, p in ipairs(s.members) do
        Networking.FireClient(Networking.Events.LobbyUpdate, p, {
            hostUserId = s.hostUserId,
            modeId     = s.modeId,
            members    = memberData,
        })
    end
end

local function getSessionForPlayer(player)
    local sid = playerSession[player]
    return sid and sessions[sid] or nil
end

-- ===================== PUBLIC API =====================

-- Called when a player sets their mode (creates or updates their lobby)
function Session.SetMode(hostPlayer, modeId)
    local mode = GameMode.Get(modeId)
    local sid = tostring(hostPlayer.UserId)

    -- If already in someone else's session, leave it first
    if playerSession[hostPlayer] and playerSession[hostPlayer] ~= sid then
        Session.LeaveSession(hostPlayer)
    end

    if not sessions[sid] then
        sessions[sid] = {
            hostUserId   = hostPlayer.UserId,
            modeId       = modeId,
            members      = { hostPlayer },
            levelFolder  = nil,
            active       = false,
            rescueStates = {},  -- [userId] = { downed=bool, bleedTimer=num, rescuerId=userId|nil, rescueProgress=num }
            pvpCooldowns = {},  -- [attackerId][victimId] = lastHitTime
        }
    else
        sessions[sid].modeId = modeId
    end
    playerSession[hostPlayer] = sid
    broadcastLobbyUpdate(sid)
end

-- Another player joins host's lobby
function Session.JoinSession(joiningPlayer, hostUserId)
    local sid = tostring(hostUserId)
    local s = sessions[sid]
    if not s then
        Networking.FireClient(Networking.Events.LobbyUpdate, joiningPlayer, { error = "Lobby not found" })
        return false
    end
    if s.active then
        Networking.FireClient(Networking.Events.LobbyUpdate, joiningPlayer, { error = "Run already started" })
        return false
    end
    local mode = GameMode.Get(s.modeId)
    if #s.members >= mode.maxPlayers then
        Networking.FireClient(Networking.Events.LobbyUpdate, joiningPlayer, { error = "Lobby full" })
        return false
    end
    -- Leave any current session
    if playerSession[joiningPlayer] then
        Session.LeaveSession(joiningPlayer)
    end
    table.insert(s.members, joiningPlayer)
    playerSession[joiningPlayer] = sid
    broadcastLobbyUpdate(sid)
    return true
end

-- Player leaves their current lobby
function Session.LeaveSession(player)
    local sid = playerSession[player]
    if not sid then return end
    local s = sessions[sid]
    if not s then
        playerSession[player] = nil
        return
    end
    -- Remove from members
    for i = #s.members, 1, -1 do
        if s.members[i] == player then
            table.remove(s.members, i)
            break
        end
    end
    playerSession[player] = nil
    -- If host left, dissolve session or transfer host
    if player.UserId == s.hostUserId then
        if #s.members > 0 then
            -- Transfer host to first remaining member
            local newHost = s.members[1]
            local newSid = tostring(newHost.UserId)
            sessions[newSid] = s
            s.hostUserId = newHost.UserId
            sessions[sid] = nil
            for _, p in ipairs(s.members) do
                playerSession[p] = newSid
            end
            broadcastLobbyUpdate(newSid)
        else
            sessions[sid] = nil
        end
    else
        broadcastLobbyUpdate(sid)
    end
end

-- Called by main.server when a level starts; marks session active and sets levelFolder
function Session.MarkActive(player, levelFolder)
    local sid = playerSession[player]
    if not sid then return end
    local s = sessions[sid]
    if not s then return end
    s.levelFolder = levelFolder
    s.active = true
end

-- Returns the session a player is in, or nil
function Session.GetSession(player)
    return getSessionForPlayer(player)
end

-- Returns sessionId for player
function Session.GetSessionId(player)
    return playerSession[player]
end

-- Returns all members in the same session as player, excluding themselves
function Session.GetTeammates(player)
    local s = getSessionForPlayer(player)
    if not s then return {} end
    local result = {}
    for _, p in ipairs(s.members) do
        if p ~= player and p.Parent then
            table.insert(result, p)
        end
    end
    return result
end

-- Returns all members including self
function Session.GetAllMembers(player)
    local s = getSessionForPlayer(player)
    if not s then return { player } end
    return s.members
end

-- Returns modeId for the player's session
function Session.GetMode(player)
    local s = getSessionForPlayer(player)
    return s and s.modeId or "Singleplayer"
end

-- ===================== COOPERATIVE: DOWNED STATE =====================

-- Mark a player as downed in coop
function Session.SetDowned(player, isDowned)
    local s = getSessionForPlayer(player)
    if not s then return end
    if not s.rescueStates[player.UserId] then
        s.rescueStates[player.UserId] = {}
    end
    local rs = s.rescueStates[player.UserId]
    rs.downed         = isDowned
    rs.bleedTimer     = isDowned and GameMode.Get(s.modeId).downedBleedSecs or nil
    rs.rescuerId      = nil
    rs.rescueProgress = 0
end

function Session.IsDowned(player)
    local s = getSessionForPlayer(player)
    if not s then return false end
    local rs = s.rescueStates[player.UserId]
    return rs and rs.downed == true
end

-- Returns { downed=bool, bleedTimer, rescuerId, rescueProgress } or nil
function Session.GetDownedState(player)
    local s = getSessionForPlayer(player)
    if not s then return nil end
    return s.rescueStates[player.UserId]
end

-- Tick bleed-out timers; returns list of players who expired
function Session.TickBleedTimers(dt)
    local expired = {}
    for sid, s in pairs(sessions) do
        if s.active then
            for userId, rs in pairs(s.rescueStates) do
                if rs.downed and rs.bleedTimer then
                    rs.bleedTimer = rs.bleedTimer - dt
                    if rs.bleedTimer <= 0 then
                        rs.downed = false
                        rs.bleedTimer = nil
                        -- Find the actual player object
                        for _, p in ipairs(s.members) do
                            if p.UserId == userId then
                                table.insert(expired, p)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return expired
end

-- Begin or update rescue progress for rescuer -> downed target
function Session.UpdateRescue(rescuer, targetPlayer, dt)
    local s = getSessionForPlayer(rescuer)
    if not s then return false end
    local rs = s.rescueStates[targetPlayer.UserId]
    if not rs or not rs.downed then return false end
    local mode = GameMode.Get(s.modeId)
    rs.rescuerId = rescuer.UserId
    rs.rescueProgress = (rs.rescueProgress or 0) + dt / mode.rescueTime
    return rs.rescueProgress >= 1.0
end

-- Clear rescue progress for target (rescuer moved away)
function Session.CancelRescue(targetUserId)
    for sid, s in pairs(sessions) do
        local rs = s.rescueStates[targetUserId]
        if rs then
            rs.rescuerId = nil
            rs.rescueProgress = 0
        end
    end
end

-- ===================== COMPETITIVE: PVP COOLDOWN =====================

function Session.CanHitPlayer(attacker, victim)
    local s = getSessionForPlayer(attacker)
    if not s then return false end
    local mode = GameMode.Get(s.modeId)
    if not mode.pvpEnabled then return false end
    s.pvpCooldowns[attacker.UserId] = s.pvpCooldowns[attacker.UserId] or {}
    local lastHit = s.pvpCooldowns[attacker.UserId][victim.UserId] or 0
    return (tick() - lastHit) >= mode.pickaxeCooldown
end

function Session.RecordHit(attacker, victim)
    local s = getSessionForPlayer(attacker)
    if not s then return end
    s.pvpCooldowns[attacker.UserId] = s.pvpCooldowns[attacker.UserId] or {}
    s.pvpCooldowns[attacker.UserId][victim.UserId] = tick()
end

-- ===================== CLEANUP =====================

function Session.CleanupPlayer(player)
    Session.LeaveSession(player)
end

return Session
