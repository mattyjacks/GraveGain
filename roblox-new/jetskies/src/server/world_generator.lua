local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldGenerator = {}
local GameData = require(ReplicatedStorage.Shared.game_data)
local IslandGenerator = require(script.Parent.island_generator)
local AdaptiveOcean = require(script.Parent.adaptive_ocean)

function WorldGenerator.GenerateWorld(startPos)
    local islands = {}
    local islandsFolder = Workspace:FindFirstChild("Islands")
    if not islandsFolder then
        islandsFolder = Instance.new("Folder")
        islandsFolder.Name = "Islands"
        islandsFolder.Parent = Workspace
    end
    
    -- Initialize adaptive ocean
    AdaptiveOcean.Init()
    
    -- Create cloud layer at ceiling
    WorldGenerator.CreateCloudLayer()
    
    -- Starter island at spawn
    local seed = math.random(1, 100000)
    local starterIsland = IslandGenerator.CreateNaturalIsland("STARTER", startPos, seed)
    starterIsland.model.Parent = islandsFolder
    table.insert(islands, starterIsland)
    
    -- Explorer islands (3)
    local currentPos = startPos
    for i = 1, 3 do
        seed = seed + 1
        currentPos = currentPos + Vector3.new(
            math.random(-200, 200),
            math.random(50, 120),
            math.random(-200, 200)
        )
        local island = IslandGenerator.CreateNaturalIsland("EXPLORER", currentPos, seed)
        island.model.Parent = islandsFolder
        table.insert(islands, island)
    end
    
    -- Summit islands (2)
    for i = 1, 2 do
        seed = seed + 1
        currentPos = currentPos + Vector3.new(
            math.random(-300, 300),
            math.random(100, 250),
            math.random(-300, 300)
        )
        local island = IslandGenerator.CreateNaturalIsland("SUMMIT", currentPos, seed)
        island.model.Parent = islandsFolder
        table.insert(islands, island)
    end
    
    return islands
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

-- Ocean is now handled by AdaptiveOcean module

return WorldGenerator
