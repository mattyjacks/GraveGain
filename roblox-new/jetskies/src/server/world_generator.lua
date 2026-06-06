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
    
    -- Initialize adaptive ocean first
    AdaptiveOcean.Init()
    
    -- Create cloud layer at ceiling
    WorldGenerator.CreateCloudLayer()
    
    -- Starter island near water surface (Y=5 puts island base just above Y=-10 ocean)
    local seed = math.random(1, 100000)
    local starterIsland = IslandGenerator.CreateNaturalIsland("STARTER", startPos, seed)
    starterIsland.model.Parent = islandsFolder
    table.insert(islands, starterIsland)
    print("[WorldGenerator] Starter island created at", startPos)
    
    -- Explorer islands spread horizontally, slightly higher
    local explorerPositions = {
        Vector3.new(300, 30, 150),
        Vector3.new(-280, 50, 320),
        Vector3.new(150, 70, -350),
    }
    for i, offset in ipairs(explorerPositions) do
        seed = seed + 1
        local pos = startPos + offset
        local island = IslandGenerator.CreateNaturalIsland("EXPLORER", pos, seed)
        island.model.Parent = islandsFolder
        table.insert(islands, island)
        print("[WorldGenerator] Explorer island", i, "at", pos)
    end
    
    -- Summit islands high up
    local summitPositions = {
        Vector3.new(600, 150, 600),
        Vector3.new(-550, 220, -500),
    }
    for i, offset in ipairs(summitPositions) do
        seed = seed + 1
        local pos = startPos + offset
        local island = IslandGenerator.CreateNaturalIsland("SUMMIT", pos, seed)
        island.model.Parent = islandsFolder
        table.insert(islands, island)
        print("[WorldGenerator] Summit island", i, "at", pos)
    end
    
    print("[WorldGenerator] Total islands:", #islands)
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
