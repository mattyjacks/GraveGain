local Collectibles = {}
local GameData = require(script.Parent:WaitForChild("game_data"))
local JetSkyModels = require(script.Parent:WaitForChild("jetsky_models"))

function Collectibles.SpawnRingIsland(islandCenter, islandSize, islandType)
    local rings = {}
    local config = GameData.IslandTypes[islandType]
    local ringCount = math.random(config.ringCount.min, config.ringCount.max)
    
    for i = 1, ringCount do
        local angle = (i / ringCount) * math.pi * 2
        local radius = islandSize * 0.4
        local x = islandCenter.X + math.cos(angle) * radius
        local z = islandCenter.Z + math.sin(angle) * radius
        local y = islandCenter.Y + GameData.RING_HEIGHT_OFFSET + math.sin(angle * 3) * 5
        
        local position = Vector3.new(x, y, z)
        local ring, hole, trigger = JetSkyModels.CreateRing(position, GameData.RING_VALUE)
        
        table.insert(rings, {
            ring = ring,
            hole = hole,
            trigger = trigger,
            position = position,
            collected = false
        })
    end
    
    -- Add hidden collectible
    local hiddenAngle = math.random() * math.pi * 2
    local hiddenRadius = islandSize * 0.6
    local hiddenPos = Vector3.new(
        islandCenter.X + math.cos(hiddenAngle) * hiddenRadius,
        islandCenter.Y + 25,
        islandCenter.Z + math.sin(hiddenAngle) * hiddenRadius
    )
    
    local hiddenRing, hiddenHole, hiddenTrigger = JetSkyModels.CreateRing(hiddenPos, GameData.HIDDEN_VALUE)
    hiddenRing.Color = Color3.fromRGB(255, 100, 200)
    hiddenHole.Color = Color3.fromRGB(200, 50, 150)
    
    table.insert(rings, {
        ring = hiddenRing,
        hole = hiddenHole,
        trigger = hiddenTrigger,
        position = hiddenPos,
        collected = false,
        isHidden = true
    })
    
    return rings
end

function Collectibles.CreateIsland(islandType, position)
    local config = GameData.IslandTypes[islandType]
    local size = math.random(config.size.min, config.size.max)
    
    -- Main island base
    local base = Instance.new("Part")
    base.Name = islandType .. "_Base"
    base.Shape = Enum.PartType.Ball
    base.Size = Vector3.new(size, size * 0.4, size)
    base.Color = config.color
    base.Material = Enum.Material.Rock
    base.TopSurface = Enum.SurfaceType.Smooth
    base.BottomSurface = Enum.SurfaceType.Smooth
    base.Anchored = true
    base.CanCollide = true
    base.Position = position
    
    -- Grass top
    local grass = Instance.new("Part")
    grass.Name = "Grass"
    grass.Shape = Enum.PartType.Cylinder
    grass.Size = Vector3.new(size * 0.8, 2, size * 0.8)
    grass.Color = Color3.fromRGB(100, 180, 100)
    grass.Material = Enum.Material.Grass
    grass.TopSurface = Enum.SurfaceType.Smooth
    grass.BottomSurface = Enum.SurfaceType.Smooth
    grass.Anchored = true
    grass.CanCollide = true
    grass.Position = position + Vector3.new(0, size * 0.15, 0)
    grass.Orientation = Vector3.new(0, 0, 90)
    
    -- Spawn rings
    local rings = Collectibles.SpawnRingIsland(position, size, islandType)
    
    return {
        base = base,
        grass = grass,
        rings = rings,
        type = islandType,
        position = position,
        size = size,
        difficulty = config.difficulty
    }
end

function Collectibles.SpawnWorld(startPos)
    local islands = {}
    local currentPos = startPos
    
    -- Starter island
    local starter = Collectibles.CreateIsland("STARTER", currentPos)
    table.insert(islands, starter)
    
    -- Explorer islands (3)
    for i = 1, 3 do
        currentPos = currentPos + Vector3.new(
            math.random(-150, 150),
            math.random(50, 100),
            math.random(-150, 150)
        )
        local explorer = Collectibles.CreateIsland("EXPLORER", currentPos)
        table.insert(islands, explorer)
    end
    
    -- Summit islands (2)
    for i = 1, 2 do
        currentPos = currentPos + Vector3.new(
            math.random(-200, 200),
            math.random(100, 200),
            math.random(-200, 200)
        )
        local summit = Collectibles.CreateIsland("SUMMIT", currentPos)
        table.insert(islands, summit)
    end
    
    return islands
end

return Collectibles
