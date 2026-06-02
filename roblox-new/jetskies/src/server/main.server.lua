local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage.Shared
local GameData = require(shared.game_data)
local Collectibles = require(shared.collectibles)
local UpgradeData = require(shared.upgrade_data)
local SaveManager = require(script.Parent.save_manager)
local WorldGenerator = require(script.Parent.world_generator)

-- Player data storage
local playerData = {}
local worldIslands = {}

-- Setup remotes (create immediately so client can find them)
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

for _, eventName in pairs(GameData.RemoteEvents) do
    local event = Instance.new("RemoteEvent")
    event.Name = eventName
    event.Parent = remotes
end

for _, funcName in pairs(GameData.RemoteFunctions) do
    local func = Instance.new("RemoteFunction")
    func.Name = funcName
    func.Parent = remotes
end

-- Get remotes
local CollectRing = remotes:WaitForChild("CollectRing")
local RequestUpgrade = remotes:WaitForChild("RequestUpgrade")
local StatsUpdate = remotes:WaitForChild("StatsUpdate")
local RingCollected = remotes:WaitForChild("RingCollected")
local WorldInit = remotes:WaitForChild("WorldInit")
local UpgradeResponse = remotes:WaitForChild("UpgradeResponse")

-- Get Remote Functions
local GetPlayerData = remotes:WaitForChild("GetPlayerData")
local PurchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

-- Initialize world
local function initWorld()
    worldIslands = WorldGenerator.GenerateWorld(Vector3.new(0, 50, 0))
    print("[Server] World generated with", #worldIslands, "islands and adaptive ocean")
end

-- Player join handling
Players.PlayerAdded:Connect(function(player)
    print("[Server] Player joined:", player.Name)
    
    -- Load or create player data
    local data = SaveManager.Load(player)
    playerData[player.UserId] = {
        rings = data.rings or 0,
        upgrades = data.upgrades or {SPEED = 1, BOOST = 1, HANDLING = 1},
        highestAltitude = data.highestAltitude or 0,
        islandsDiscovered = data.islandsDiscovered or 0
    }
    
    -- Wait for character
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        
        -- Find starter island position
        local spawnPos = Vector3.new(0, 65, 0)
        if worldIslands and #worldIslands > 0 then
            spawnPos = worldIslands[1].position + Vector3.new(0, 15, 0)
        end
        
        -- Create detailed JetSky for player at starter island
        local JetSkyDetailed = require(shared.jetsky_detailed)
        local jetSky, seat = JetSkyDetailed.CreateDetailedJetSky()
        jetSky.Name = "JetSky_" .. player.UserId
        jetSky:SetPrimaryPartCFrame(CFrame.new(spawnPos))
        jetSky.Parent = Workspace
        
        -- Position player and seat them
        task.wait(0.2)
        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")
        
        if humanoid and hrp and seat then
            -- Disable humanoid auto-rotation
            humanoid.AutoRotate = false
            -- Sit in seat
            seat:Sit(humanoid)
            -- Position seat relative to hull
            task.wait(0.1)
        end
        
        -- Wait a moment for client tutorial to show, then send world data
        task.wait(2)
        
        -- Send world data to client
        local islandData = {}
        for _, island in ipairs(worldIslands) do
            table.insert(islandData, {
                type = island.type,
                position = {island.position.X, island.position.Y, island.position.Z},
                size = island.size
            })
        end
        
        WorldInit:FireClient(player, {islands = islandData})
        
        -- Send initial stats
        local pdata = playerData[player.UserId]
        StatsUpdate:FireClient(player, {
            rings = pdata.rings,
            altitude = 100,
            speed = 0
        })
        
        print("[Server] JetSky created for", player.Name)
    end)
end)

-- Player leave handling
Players.PlayerRemoving:Connect(function(player)
    if playerData[player.UserId] then
        SaveManager.Save(player, playerData[player.UserId])
        playerData[player.UserId] = nil
    end
    
    -- Cleanup JetSky
    local jetSky = Workspace:FindFirstChild("JetSky_" .. player.UserId)
    if jetSky then jetSky:Destroy() end
end)

-- Collect ring handler
CollectRing.OnServerEvent:Connect(function(player, trigger)
    if not trigger or not trigger.Parent then return end
    
    local value = trigger:FindFirstChild("Value")
    local ringValue = value and value.Value or 1
    
    local pdata = playerData[player.UserId]
    if not pdata then return end
    
    pdata.rings = pdata.rings + ringValue
    
    -- Notify client
    RingCollected:FireClient(player, ringValue, pdata.rings)
    
    -- Cleanup ring parts
    local ring = trigger:FindFirstChild("Ring")
    local hole = trigger:FindFirstChild("Hole")
    if ring then ring:Destroy() end
    if hole then hole:Destroy() end
    trigger:Destroy()
end)

-- Purchase upgrade handler
PurchaseUpgrade.OnServerInvoke = function(player, upgradeType)
    local pdata = playerData[player.UserId]
    if not pdata then return {success = false, error = "No player data"} end
    
    local currentTier = pdata.upgrades[upgradeType] or 1
    local cost = UpgradeData.GetCost(upgradeType, currentTier)
    
    if not cost then
        return {success = false, error = "Max tier reached"}
    end
    
    if pdata.rings < cost then
        return {success = false, error = "Not enough rings"}
    end
    
    -- Deduct rings and upgrade
    pdata.rings = pdata.rings - cost
    pdata.upgrades[upgradeType] = currentTier + 1
    
    -- Notify client
    local finalStats = UpgradeData.ComputeFinalStats({}, pdata.upgrades)
    UpgradeResponse:FireClient(player, {
        success = true,
        upgradeType = upgradeType,
        newTier = currentTier + 1,
        rings = pdata.rings,
        stats = finalStats
    })
    
    return {success = true, stats = finalStats}
end

-- Get player data handler
GetPlayerData.OnServerInvoke = function(player)
    local pdata = playerData[player.UserId]
    if not pdata then return nil end
    
    return {
        rings = pdata.rings,
        upgrades = pdata.upgrades,
        highestAltitude = pdata.highestAltitude,
        islandsDiscovered = pdata.islandsDiscovered
    }
end

-- Initialize
initWorld()
print("[Server] JetSkies server initialized")
