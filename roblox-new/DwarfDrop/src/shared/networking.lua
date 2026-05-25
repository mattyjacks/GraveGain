-- DwarfDrop: networking.lua
-- RemoteEvent and RemoteFunction definitions

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networking = {}

Networking.Events = {
    -- Server -> Client
    LevelGenerated       = "LevelGenerated",
    DepthUpdate          = "DepthUpdate",
    BiomeChanged         = "BiomeChanged",
    PlayerDied           = "PlayerDied",
    PlayerWon            = "PlayerWon",
    LeaderboardUpdate    = "LeaderboardUpdate",
    GoldUpdate           = "GoldUpdate",
    HealthUpdate         = "HealthUpdate",
    TimerSync            = "TimerSync",

    -- Client -> Server
    RequestStartLevel    = "RequestStartLevel",
    -- FIX Bug#10: single event name for coin collect (server also handles combo payload)
    CollectCoin          = "CollectCoin",
    ApplyFallDamage      = "ApplyFallDamage",
    PurchaseUpgrade      = "PurchaseUpgrade",
    RequestLeaderboard   = "RequestLeaderboard",
    PlayerReachedBottom  = "PlayerReachedBottom",

    -- Slime + terrain (cosmetic)
    SlimeKilled          = "SlimeKilled",
    TerrainSlimed        = "TerrainSlimed",
    PickaxeTerrainHit    = "PickaxeTerrainHit",
    SlimeHit             = "SlimeHit",

    -- Wall ore mining
    MineWall             = "MineWall",
    WallMined            = "WallMined",

    -- Active items + water
    UseActiveItem        = "UseActiveItem",
    ItemUsed             = "ItemUsed",
    ItemPickup           = "ItemPickup",
    WaterUpdate          = "WaterUpdate",
    PlaceItem            = "PlaceItem",
    ItemPlaced           = "ItemPlaced",
    GrabRope             = "GrabRope",
    ReleaseRope          = "ReleaseRope",
    BackpackUpdate       = "BackpackUpdate",
    EquipSlot            = "EquipSlot",
    CollectItem          = "CollectItem",

    -- Death/respawn
    DeathChoice          = "DeathChoice",
    RespawnInBasket      = "RespawnInBasket",
    RespawnInHub         = "RespawnInHub",

    -- Combo + stats + modifier
    ComboUpdate          = "ComboUpdate",
    ModifierSet          = "ModifierSet",
    AirJumpUsed          = "AirJumpUsed",
    StatsUpdate          = "StatsUpdate",
    SetModifier          = "SetModifier",

    -- Multiplayer: session lobby
    SetGameMode          = "SetGameMode",
    RequestJoinSession   = "RequestJoinSession",
    LeaveSession         = "LeaveSession",
    LobbyUpdate          = "LobbyUpdate",
    GameModeChanged      = "GameModeChanged",

    -- Multiplayer: cooperative
    PlayerDowned         = "PlayerDowned",
    PlayerRescued        = "PlayerRescued",
    RequestRescue        = "RequestRescue",
    RescueProgress       = "RescueProgress",
    GiveItemRequest      = "GiveItemRequest",
    ItemGiven            = "ItemGiven",
    TeamHealthUpdate     = "TeamHealthUpdate",

    -- Multiplayer: competitive
    AttackPlayer         = "AttackPlayer",
    PlayerHit            = "PlayerHit",
    PlayerEliminated     = "PlayerEliminated",

    -- Throw items
    ThrowItem            = "ThrowItem",
    ProjectileLanded     = "ProjectileLanded",

    -- Weight system
    WeightUpdate         = "WeightUpdate",

    -- Dynamic chunks
    -- FIX Bug#8: RequestChunkLoad bound exclusively in session_handler.Init
    RequestChunkLoad     = "RequestChunkLoad",
    ChunkLoaded          = "ChunkLoaded",
    UnloadChunk          = "UnloadChunk",

    -- Misc
    TriggerBasketLaunch  = "TriggerBasketLaunch",
    SpawnMiningNugget    = "SpawnMiningNugget",
    CameraShakeSignal    = "CameraShakeSignal",
    SaveCameraPreference = "SaveCameraPreference",
}

Networking.Functions = {
    GetPlayerData = "GetPlayerData",
    ValidateSeed  = "ValidateSeed",
}

local _remoteFolder = nil

local function getFolder()
    if _remoteFolder then return _remoteFolder end
    _remoteFolder = ReplicatedStorage:WaitForChild("DwarfDropRemotes", 10)
    if not _remoteFolder then
        warn("[Networking] Remote folder not found!")
    end
    return _remoteFolder
end

-- Server: create all remotes
function Networking.CreateRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "DwarfDropRemotes"
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

    _remoteFolder = folder
    return folder
end

function Networking.GetEvent(name)
    local folder = getFolder()
    if not folder then return nil end
    return folder:WaitForChild(name, 5)
end

function Networking.GetFunction(name)
    local folder = getFolder()
    if not folder then return nil end
    return folder:WaitForChild(name, 5)
end

function Networking.FireServer(eventName, ...)
    local re = Networking.GetEvent(eventName)
    if re then re:FireServer(...) end
end

function Networking.FireClient(eventName, player, ...)
    local re = Networking.GetEvent(eventName)
    if re then re:FireClient(player, ...) end
end

function Networking.FireAllClients(eventName, ...)
    local re = Networking.GetEvent(eventName)
    if re then re:FireAllClients(...) end
end

function Networking.OnClient(eventName, callback)
    local re = Networking.GetEvent(eventName)
    if re then
        return re.OnClientEvent:Connect(callback)
    end
end

function Networking.OnServer(eventName, callback)
    local re = Networking.GetEvent(eventName)
    if re then
        return re.OnServerEvent:Connect(callback)
    end
end

return Networking
