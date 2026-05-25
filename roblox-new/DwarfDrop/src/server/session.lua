-- DwarfDrop: session.lua
-- Multiplayer session management: lobby, coop, pvp

local GameMode = require(game.ReplicatedStorage.Shared.game_mode)

local Session = {}

-- sessions[hostUserId] = {
--   host = player,
--   members = {player, ...},
--   modeId = "Singleplayer" | "Cooperative" | "Competitive",
--   levelFolder = Instance | nil,
--   biomeSequence = array | nil,
--   inLevel = bool,
-- }
local sessions = {}
-- playerToSession[userId] = hostUserId
local playerToSession = {}

-- coop downed state: downeState[userId] = {startTime, bleedTimer, rescuer}
local downedState = {}

-- pvp cooldowns: pvpCooldowns["uid1_uid2"] = lastHitTime
local pvpCooldowns = {}

-- ==================== Session CRUD ====================

function Session.CreateSession(host)
    local uid = host.UserId
    if sessions[uid] then
        Session.DestroySession(uid)
    end
    sessions[uid] = {
        host     = host,
        members  = { host },
        modeId   = "Singleplayer",
        levelFolder = nil,
        biomeSequence = nil,
        inLevel  = false,
    }
    playerToSession[uid] = uid
    return sessions[uid]
end

function Session.GetSession(hostUserId)
    return sessions[hostUserId]
end

function Session.GetSessionForPlayer(player)
    local hostUid = playerToSession[player.UserId]
    if not hostUid then return nil end
    return sessions[hostUid]
end

function Session.GetHostForPlayer(player)
    local hostUid = playerToSession[player.UserId]
    if not hostUid then return nil end
    local sess = sessions[hostUid]
    return sess and sess.host or nil
end

function Session.AddMember(hostUserId, player)
    local sess = sessions[hostUserId]
    if not sess then return false end
    local mode = GameMode.Get(sess.modeId)
    if #sess.members >= (mode.maxPlayers or 1) then return false end
    -- Not already in session
    if playerToSession[player.UserId] then return false end
    table.insert(sess.members, player)
    playerToSession[player.UserId] = hostUserId
    return true
end

function Session.RemoveMember(player)
    local hostUid = playerToSession[player.UserId]
    if not hostUid then return end
    local sess = sessions[hostUid]
    if sess then
        for i, m in ipairs(sess.members) do
            if m == player then
                table.remove(sess.members, i)
                break
            end
        end
        -- If the host left, destroy the session
        if sess.host == player then
            Session.DestroySession(hostUid)
            return
        end
    end
    playerToSession[player.UserId] = nil
    downedState[player.UserId] = nil
end

function Session.DestroySession(hostUserId)
    local sess = sessions[hostUserId]
    if not sess then return end
    for _, m in ipairs(sess.members) do
        playerToSession[m.UserId] = nil
        downedState[m.UserId] = nil
    end
    -- Clean up level folder
    if sess.levelFolder and sess.levelFolder.Parent then
        sess.levelFolder:Destroy()
    end
    sessions[hostUserId] = nil
end

function Session.SetMode(hostUserId, modeId)
    local sess = sessions[hostUserId]
    if not sess then return end
    if GameMode.Modes[modeId] then
        sess.modeId = modeId
    end
end

function Session.SetLevelFolder(hostUserId, folder)
    local sess = sessions[hostUserId]
    if sess then sess.levelFolder = folder end
end

function Session.SetBiomeSequence(hostUserId, seq)
    local sess = sessions[hostUserId]
    if sess then sess.biomeSequence = seq end
end

function Session.SetInLevel(hostUserId, inLevel)
    local sess = sessions[hostUserId]
    if sess then sess.inLevel = inLevel end
end

function Session.GetMembers(hostUserId)
    local sess = sessions[hostUserId]
    return sess and sess.members or {}
end

function Session.IsMember(player, hostUserId)
    return playerToSession[player.UserId] == hostUserId
end

-- ==================== Coop Downed ====================

function Session.SetDowned(player)
    downedState[player.UserId] = {
        startTime  = tick(),
        bleedTimer = GameMode.Modes.Cooperative.bleedTime or 30,
    }
end

function Session.IsDowned(player)
    return downedState[player.UserId] ~= nil
end

function Session.ClearDowned(player)
    downedState[player.UserId] = nil
end

-- Tick bleed timers for all downed players; returns list of players who expired
function Session.TickDowned(dt)
    local expired = {}
    for uid, state in pairs(downedState) do
        state.bleedTimer = state.bleedTimer - dt
        if state.bleedTimer <= 0 then
            table.insert(expired, uid)
        end
    end
    for _, uid in ipairs(expired) do
        downedState[uid] = nil
    end
    return expired
end

-- ==================== PvP Cooldowns ====================

local PVP_COOLDOWN = 0.5  -- seconds between hits between the same pair

local function pvpKey(uid1, uid2)
    -- Consistent key regardless of argument order
    if uid1 < uid2 then
        return tostring(uid1) .. "_" .. tostring(uid2)
    end
    return tostring(uid2) .. "_" .. tostring(uid1)
end

function Session.CheckPvPCooldown(attacker, target)
    local key = pvpKey(attacker.UserId, target.UserId)
    local last = pvpCooldowns[key]
    if last and (tick() - last) < PVP_COOLDOWN then
        return false  -- on cooldown
    end
    pvpCooldowns[key] = tick()
    return true
end

function Session.CleanupPvPCooldowns()
    local now = tick()
    for key, t in pairs(pvpCooldowns) do
        if now - t > 10 then
            pvpCooldowns[key] = nil
        end
    end
end

return Session
