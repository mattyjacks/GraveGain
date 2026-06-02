local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldGenerator = {}
local GameData = require(ReplicatedStorage.Shared.game_data)
local Collectibles = require(ReplicatedStorage.Shared.collectibles)

function WorldGenerator.GenerateWorld(startPos)
    local islands = {}
    local islandsFolder = Workspace:FindFirstChild("Islands")
    if not islandsFolder then
        islandsFolder = Instance.new("Folder")
        islandsFolder.Name = "Islands"
        islandsFolder.Parent = Workspace
    end
    
    local ringsFolder = Workspace:FindFirstChild("Rings")
    if not ringsFolder then
        ringsFolder = Instance.new("Folder")
        ringsFolder.Name = "Rings"
        ringsFolder.Parent = Workspace
    end
    
    -- Create cloud layer at ceiling
    WorldGenerator.CreateCloudLayer()
    
    -- Starter island at spawn
    local starterIsland = Collectibles.CreateIsland("STARTER", startPos)
    WorldGenerator.PlaceIsland(starterIsland, islandsFolder, ringsFolder)
    table.insert(islands, starterIsland)
    
    -- Explorer islands (3)
    local currentPos = startPos
    for i = 1, 3 do
        currentPos = currentPos + Vector3.new(
            math.random(-150, 150),
            math.random(80, 150),
            math.random(-150, 150)
        )
        local island = Collectibles.CreateIsland("EXPLORER", currentPos)
        WorldGenerator.PlaceIsland(island, islandsFolder, ringsFolder)
        table.insert(islands, island)
    end
    
    -- Summit islands (2)
    for i = 1, 2 do
        currentPos = currentPos + Vector3.new(
            math.random(-200, 200),
            math.random(150, 300),
            math.random(-200, 200)
        )
        local island = Collectibles.CreateIsland("SUMMIT", currentPos)
        WorldGenerator.PlaceIsland(island, islandsFolder, ringsFolder)
        table.insert(islands, island)
    end
    
    return islands
end

function WorldGenerator.PlaceIsland(island, islandsFolder, ringsFolder)
    -- Place island parts
    island.base.Parent = islandsFolder
    island.grass.Parent = islandsFolder
    
    -- Place rings
    for _, ringData in ipairs(island.rings) do
        ringData.ring.Parent = ringsFolder
        ringData.hole.Parent = ringsFolder
        ringData.trigger.Parent = ringsFolder
    end
end

function WorldGenerator.CreateCloudLayer()
    local worldFolder = Workspace:FindFirstChild("World")
    if not worldFolder then
        worldFolder = Instance.new("Folder")
        worldFolder.Name = "World"
        worldFolder.Parent = Workspace
    end
    
    -- Create cloud ceiling
    local ceiling = Instance.new("Part")
    ceiling.Name = "CloudCeiling"
    ceiling.Size = Vector3.new(2000, 50, 2000)
    ceiling.Position = Vector3.new(0, GameData.MAX_ALTITUDE + 25, 0)
    ceiling.Color = Color3.fromRGB(240, 248, 255)
    ceiling.Material = Enum.Material.SmoothPlastic
    ceiling.Transparency = 0.7
    ceiling.Anchored = true
    ceiling.CanCollide = false
    ceiling.Parent = worldFolder
    
    -- Create decorative clouds
    for i = 1, 20 do
        local cloud = Instance.new("Part")
        cloud.Name = "Cloud" .. i
        cloud.Shape = Enum.PartType.Ball
        local size = math.random(50, 150)
        cloud.Size = Vector3.new(size, size * 0.4, size)
        cloud.Position = Vector3.new(
            math.random(-800, 800),
            math.random(100, GameData.CLOUD_LAYER_HEIGHT),
            math.random(-800, 800)
        )
        cloud.Color = Color3.fromRGB(255, 255, 255)
        cloud.Material = Enum.Material.SmoothPlastic
        cloud.Transparency = 0.8
        cloud.Anchored = true
        cloud.CanCollide = false
        cloud.Parent = worldFolder
    end
end

function WorldGenerator.CreateOcean()
    local worldFolder = Workspace:FindFirstChild("World")
    if not worldFolder then
        worldFolder = Instance.new("Folder")
        worldFolder.Name = "World"
        worldFolder.Parent = Workspace
    end
    
    -- Create ocean base (kill brick)
    local ocean = Instance.new("Part")
    ocean.Name = "Ocean"
    ocean.Size = Vector3.new(4000, 10, 4000)
    ocean.Position = Vector3.new(0, -20, 0)
    ocean.Color = Color3.fromRGB(0, 100, 150)
    ocean.Material = Enum.Material.Water
    ocean.Transparency = 0.3
    ocean.Anchored = true
    ocean.CanCollide = false
    ocean.Parent = worldFolder
    
    -- Connect kill function
    ocean.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end)
    
    -- Add visible ocean waves (decorative parts)
    for i = 1, 50 do
        local wave = Instance.new("Part")
        wave.Name = "Wave" .. i
        wave.Shape = Enum.PartType.Ball
        wave.Size = Vector3.new(30, 8, 30)
        wave.Position = Vector3.new(
            math.random(-1800, 1800),
            -10,
            math.random(-1800, 1800)
        )
        wave.Color = Color3.fromRGB(50, 150, 200)
        wave.Material = Enum.Material.Water
        wave.Transparency = 0.5
        wave.Anchored = true
        wave.CanCollide = false
        wave.Parent = worldFolder
    end
end

return WorldGenerator
