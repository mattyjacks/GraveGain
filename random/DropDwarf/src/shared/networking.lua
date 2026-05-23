-- DropDwarf: networking.lua
-- RemoteEvent and RemoteFunction definitions

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networking = {}

-- All remote event names
Networking.Events = {
    -- Server -> Client
    LevelGenerated       = "LevelGenerated",       -- level geometry ready, client can start
    DepthUpdate          = "DepthUpdate",           -- broadcast current depth to player
    BiomeChanged         = "BiomeChanged",          -- player entered new biome
    PlayerDied           = "PlayerDied",            -- player hit 0 HP
    PlayerWon            = "PlayerWon",             -- player reached 1000m alive
    LeaderboardUpdate    = "LeaderboardUpdate",     -- leaderboard data update
    GoldUpdate           = "GoldUpdate",            -- player gold changed
    HealthUpdate         = "HealthUpdate",          -- player health changed (server authority)
    TimerSync            = "TimerSync",             -- server timer sync

    -- Client -> Server
    RequestStartLevel    = "RequestStartLevel",     -- player hits portal, sends seed
    CollectCoin          = "CollectCoin",           -- client picked up a coin
    ApplyFallDamage      = "ApplyFallDamage",       -- client reports fall info
    PurchaseUpgrade      = "PurchaseUpgrade",       -- client buys upgrade
    RequestLeaderboard   = "RequestLeaderboard",    -- client wants leaderboard data
    PlayerReachedBottom  = "PlayerReachedBottom",   -- client confirmed 1000m reached

    -- Slime + terrain interactions (client authoritative, cosmetic)
    SlimeKilled          = "SlimeKilled",           -- client killed a slime (id, size, pos)
    TerrainSlimed        = "TerrainSlimed",         -- slime projectile hit terrain (partId, pos)
    PickaxeTerrainHit    = "PickaxeTerrainHit",     -- pickaxe hit terrain (pos, terrainType)

    -- Wall ore mining
    MineWall             = "MineWall",              -- C->S: pickaxe hit a mineable ore node (partRef)
    WallMined            = "WallMined",             -- S->C: ore node depleted, gives gold + pos

    -- Active items + water system
    UseActiveItem        = "UseActiveItem",         -- C->S: player used active item
    ItemUsed             = "ItemUsed",              -- S->C: confirm item use + remaining
    ItemPickup           = "ItemPickup",            -- S->C: player picked up an item
    WaterUpdate          = "WaterUpdate",           -- S->C: water level changed (0-5)
    PlaceItem            = "PlaceItem",             -- C->S: place rope/piton/spring in world
    ItemPlaced           = "ItemPlaced",            -- S->C: item placed at position
    GrabRope             = "GrabRope",              -- C->S: player grabbed a rope
    ReleaseRope          = "ReleaseRope",           -- C->S: player released a rope
    BackpackUpdate       = "BackpackUpdate",        -- S->C: full backpack slot array
    EquipSlot            = "EquipSlot",             -- C->S: player equips slot index
    DeathChoice          = "DeathChoice",           -- C->S: player chose respawn/reset option after death
    RespawnInBasket      = "RespawnInBasket",       -- S->C: confirmed respawn/reset inside basket
    RespawnInHub         = "RespawnInHub",          -- S->C: confirmed respawn/reset to hub

    -- Combo + modifier + stats
    ComboUpdate          = "ComboUpdate",           -- S->C: current streak count + multiplier
    ModifierSet          = "ModifierSet",           -- S->C: active run modifier data
    AirJumpUsed          = "AirJumpUsed",           -- C->S: player used air jump
    StatsUpdate          = "StatsUpdate",           -- S->C: send full computed stats to client
    CollectCoinCombo     = "CollectCoinCombo",      -- C->S: coin collected with combo data
    SetModifier          = "SetModifier",           -- C->S: hub UI requests a modifier

    -- Multiplayer: session lobby
    SetGameMode          = "SetGameMode",           -- C->S: host sets mode (Singleplayer/Cooperative/Competitive)
    RequestJoinSession   = "RequestJoinSession",    -- C->S: player requests to join host's lobby
    LeaveSession         = "LeaveSession",          -- C->S: player leaves lobby before run
    LobbyUpdate          = "LobbyUpdate",           -- S->C: current lobby state (players, mode, host)
    GameModeChanged      = "GameModeChanged",       -- S->C: mode finalized when level starts

    -- Multiplayer: cooperative
    PlayerDowned         = "PlayerDowned",          -- S->C: broadcast teammate went down {userId, pos}
    PlayerRescued        = "PlayerRescued",         -- S->C: broadcast teammate rescued {userId}
    RequestRescue        = "RequestRescue",         -- C->S: player holding E near downed teammate {targetId}
    RescueProgress       = "RescueProgress",        -- S->C: rescue progress 0-1 for HUD
    GiveItemRequest      = "GiveItemRequest",       -- C->S: give active slot item to nearest teammate
    ItemGiven            = "ItemGiven",             -- S->C: item transferred {fromId, toId, itemId, count}
    TeamHealthUpdate     = "TeamHealthUpdate",      -- S->C: all teammate health values for HUD

    -- Multiplayer: competitive
    AttackPlayer         = "AttackPlayer",          -- C->S: pickaxe swing hit a player {targetId, pos}
    PlayerHit            = "PlayerHit",             -- S->C: you were hit {damage, knockbackDir}
    PlayerEliminated     = "PlayerEliminated",      -- S->C: a player was eliminated {userId}

    -- Throw items (Javelin, SmallRock, BigRock)
    ThrowItem            = "ThrowItem",             -- C->S: player throws held item {itemId, origin, direction}
    ProjectileLanded     = "ProjectileLanded",      -- S->C: projectile hit world/player {itemId, pos, hitPlayerId}

    -- Weight system
    WeightUpdate         = "WeightUpdate",          -- S->C: {totalKg, speedMult, fallMult}
}

-- Remote functions (client->server with return value)
Networking.Functions = {
    GetPlayerData        = "GetPlayerData",         -- returns upgrades, gold, best times
    ValidateSeed         = "ValidateSeed",          -- check if seed is valid string
}

local remoteFolder = nil

-- Server: create all remotes
function Networking.CreateRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "DropDwarfRemotes"
    folder.Parent = ReplicatedStorage

    for _, name in pairs(Networking.Events) do
        local re = Instance.new("RemoteEvent")
        re.Name = name
        re.Parent = folder
    end

    for _, name in pairs(Networking.Functions) do
        local rf = Instance.new("RemoteFunction")
        rf.Name = name
        rf.Parent = folder
    end

    remoteFolder = folder
    return folder
end

-- Client/Server: get a remote event by name
function Networking.GetEvent(name)
    local folder = ReplicatedStorage:WaitForChild("DropDwarfRemotes", 10)
    if not folder then
        warn("[Networking] Remote folder not found!")
        return nil
    end
    return folder:WaitForChild(name, 5)
end

-- Client/Server: get a remote function by name
function Networking.GetFunction(name)
    local folder = ReplicatedStorage:WaitForChild("DropDwarfRemotes", 10)
    if not folder then
        warn("[Networking] Remote folder not found!")
        return nil
    end
    return folder:WaitForChild(name, 5)
end

-- Helper: fire server (client only)
function Networking.FireServer(eventName, ...)
    local re = Networking.GetEvent(eventName)
    if re then re:FireServer(...) end
end

-- Helper: fire client (server only)
function Networking.FireClient(eventName, player, ...)
    local re = Networking.GetEvent(eventName)
    if re then re:FireClient(player, ...) end
end

-- Helper: fire all clients (server only)
function Networking.FireAllClients(eventName, ...)
    local re = Networking.GetEvent(eventName)
    if re then re:FireAllClients(...) end
end

-- Helper: connect on client
function Networking.OnClient(eventName, callback)
    local re = Networking.GetEvent(eventName)
    if re then
        return re.OnClientEvent:Connect(callback)
    end
end

-- Helper: connect on server
function Networking.OnServer(eventName, callback)
    local re = Networking.GetEvent(eventName)
    if re then
        return re.OnServerEvent:Connect(callback)
    end
end

return Networking
