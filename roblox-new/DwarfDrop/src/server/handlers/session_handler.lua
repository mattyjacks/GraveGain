-- DwarfDrop: handlers/session_handler.lua
-- Session init, level start, dynamic chunk loading, lobby events
-- FIX Bug#8: RequestChunkLoad is bound EXCLUSIVELY here - not in main.server

local Players    = game:GetService("Players")

local Networking        = require(game.ReplicatedStorage.Shared.networking)
local GameData          = require(game.ReplicatedStorage.Shared.game_data)
local BiomeData         = require(game.ReplicatedStorage.Shared.biome_data)
local GameMode          = require(game.ReplicatedStorage.Shared.game_mode)

local Session           = require(script.Parent.Parent.session)
local PlayerData        = require(script.Parent.Parent.player_data)
local PlayerStateManager = require(script.Parent.Parent.player_state_manager)
local ItemHandler       = require(script.Parent.Parent.item_handler)
local LevelGenerator    = require(script.Parent.Parent.level_generator)

local SessionHandler = {}

-- External setter injected from main.server (avoids circular require)
SessionHandler.SetPlayerInLevel = nil
SessionHandler.GetPlayerState   = nil

-- ==================== LEVEL START ====================

local function buildPlayerLevelState(player, seed, modifier)
    return {
        inLevel      = true,
        seed         = seed,
        depth        = 0,
        timer        = 0,
        gold         = 0,
        modifier     = modifier,
        loadedSlots  = { [1] = true, [2] = true },
        weightFallMult = 1.0,
    }
end

local function startLevelForSession(host, seed, modeId)
    local hostUid = host.UserId
    local sess    = Session.GetSession(hostUid)
    if not sess then
        sess = Session.CreateSession(host)
    end

    local modifier = GameData.RunModifiers.Normal
    local data     = PlayerData.Get(host)
    if data and data.pendingModifier then
        modifier = GameData.RunModifiers[data.pendingModifier] or GameData.RunModifiers.Normal
    end

    -- Biome sequence
    local biomeSequence = BiomeData.GenerateSequence(seed)
    Session.SetBiomeSequence(hostUid, biomeSequence)
    Session.SetMode(hostUid, modeId or "Singleplayer")
    Session.SetInLevel(hostUid, true)

    -- Build level geometry
    local sessionId     = tostring(hostUid) .. "_" .. tostring(os.time())
    local levelFolder   = LevelGenerator.BuildLevel(seed, sessionId, biomeSequence, modifier)
    Session.SetLevelFolder(hostUid, levelFolder)

    -- FIX Bug#5: use math.random() - 0.5 for float offset (not math.random(-0.5,0.5))
    local basketFolder = levelFolder:FindFirstChild("DwarvenEntryBasket")

    local members = Session.GetMembers(hostUid)
    for _, player in ipairs(members) do
        -- Teleport to basket
        local char = player.Character
        if char and basketFolder then
            local spawnMarker = basketFolder:FindFirstChild("SpawnPosition")
            local basePos = spawnMarker and spawnMarker.Value
                or Vector3.new(0, GameData.LEVEL_Y_OFFSET - 30, 0)
            local spawnPos = basePos + Vector3.new(
                    (math.random() - 0.5) * 10,
                    0,
                    (math.random() - 0.5) * 10)

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(spawnPos)
            end
        end

        -- Give flashlight lantern in slot 1 at level start
        ItemHandler.GiveItem(player, "Lantern", 1)

        -- Apply stats
        local pData = PlayerData.Get(player)
        if pData then
            PlayerStateManager.PushStats(player, pData.upgrades,
                ItemHandler.GetBackpack(player))
        end

        -- Send modifier to client
        Networking.FireClient(Networking.Events.ModifierSet, player, modifier)
        Networking.FireClient(Networking.Events.GameModeChanged, player, modeId or "Singleplayer")

        -- Register in-level state
        local state = buildPlayerLevelState(player, seed, modifier)
        if SessionHandler.SetPlayerInLevel then
            SessionHandler.SetPlayerInLevel(player, state)
        end

        -- Signal level ready
        Networking.FireClient(Networking.Events.LevelGenerated, player, {
            seed           = seed,
            modeId         = modeId or "Singleplayer",
            biomeSequence  = biomeSequence,
        })

        -- Trigger basket launch animation
        task.delay(0.5, function()
            Networking.FireClient(Networking.Events.TriggerBasketLaunch, player)
        end)
    end
end

-- ==================== CHUNK LOADING ====================
-- FIX Bug#8: single binding point for RequestChunkLoad

local function onRequestChunkLoad(player, slotIndex)
    slotIndex = tonumber(slotIndex)
    if not slotIndex then return end

    local sess = Session.GetSessionForPlayer(player)
    if not sess or not sess.levelFolder then return end

    local hostUid = sess.host.UserId
    local biomeSeq = sess.biomeSequence
    local seed     = sess.levelFolder:FindFirstChild("Seed")
    if not seed or not biomeSeq then return end

    local modifier = GameData.RunModifiers.Normal
    local state    = SessionHandler.GetPlayerState and SessionHandler.GetPlayerState(player)
    if state and state.modifier then
        modifier = state.modifier
    end

    -- Load the requested slot
    local newSlot = LevelGenerator.LoadSlot(
        sess.levelFolder, seed.Value, slotIndex, biomeSeq, modifier)

    if newSlot then
        Networking.FireClient(Networking.Events.ChunkLoaded, player, slotIndex)

        -- Unload slots more than 2 behind
        local unloadIdx = slotIndex - 2
        if unloadIdx >= 1 then
            LevelGenerator.UnloadSlot(sess.levelFolder, unloadIdx)
            Networking.FireClient(Networking.Events.UnloadChunk, player, unloadIdx)
        end
    end
end

-- ==================== INIT ====================

function SessionHandler.Init()
    -- RequestStartLevel: player hits portal
    Networking.OnServer(Networking.Events.RequestStartLevel, function(player, seed, modeId)
        if type(seed) ~= "string" or #seed == 0 then
            seed = "MattyJacks"
        end
        seed = seed:sub(1, 32)
        PlayerData.SetLastSeed(player, seed)

        -- Solo or existing session host
        local sess = Session.GetSessionForPlayer(player)
        local isHost = (sess == nil) or (sess.host == player)

        if isHost then
            startLevelForSession(player, seed, modeId or "Singleplayer")
        else
            -- Non-host cannot start; host triggers start via lobby
        end
    end)

    -- FIX Bug#8: ONLY bind RequestChunkLoad here
    Networking.OnServer(Networking.Events.RequestChunkLoad, onRequestChunkLoad)

    -- Lobby: set game mode
    Networking.OnServer(Networking.Events.SetGameMode, function(player, modeId)
        local sess = Session.GetSession(player.UserId)
        if sess and sess.host == player then
            Session.SetMode(player.UserId, modeId)
            -- Broadcast lobby state to all members
            local members = Session.GetMembers(player.UserId)
            local memberNames = {}
            for _, m in ipairs(members) do
                table.insert(memberNames, { name = m.Name, userId = m.UserId })
            end
            for _, m in ipairs(members) do
                Networking.FireClient(Networking.Events.LobbyUpdate, m, {
                    host    = player.Name,
                    members = memberNames,
                    modeId  = modeId,
                })
            end
        end
    end)

    -- Lobby: join session
    Networking.OnServer(Networking.Events.RequestJoinSession, function(player, hostName)
        local host = nil
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Name == hostName then
                host = p
                break
            end
        end
        if not host then return end
        local added = Session.AddMember(host.UserId, player)
        if added then
            local sess     = Session.GetSession(host.UserId)
            local members  = Session.GetMembers(host.UserId)
            local memberNames = {}
            for _, m in ipairs(members) do
                table.insert(memberNames, { name = m.Name, userId = m.UserId })
            end
            for _, m in ipairs(members) do
                Networking.FireClient(Networking.Events.LobbyUpdate, m, {
                    host    = host.Name,
                    members = memberNames,
                    modeId  = sess.modeId,
                })
            end
        end
    end)

    -- Lobby: leave session
    Networking.OnServer(Networking.Events.LeaveSession, function(player)
        Session.RemoveMember(player)
        Session.CreateSession(player)  -- back to solo
    end)
end

return SessionHandler
