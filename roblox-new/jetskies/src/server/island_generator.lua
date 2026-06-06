local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IslandGenerator = {}
local GameData = require(ReplicatedStorage.Shared:WaitForChild("game_data"))

-- Island terrain colors
local TERRAIN_COLORS = {
    GRASS_LIGHT = Color3.fromRGB(120, 180, 100),
    GRASS_DARK = Color3.fromRGB(80, 140, 60),
    DIRT = Color3.fromRGB(140, 120, 80),
    ROCK = Color3.fromRGB(120, 110, 100),
    SAND = Color3.fromRGB(220, 200, 160),
    STONE = Color3.fromRGB(100, 100, 100)
}

-- Simple noise function
local function noise(x, z, seed)
    local n = math.sin(x * 12.9898 + z * 78.233 + seed) * 43758.5453
    return n - math.floor(n)
end

-- Smoother noise
local function smoothNoise(x, z, seed)
    local corners = (noise(x-1, z-1, seed) + noise(x+1, z-1, seed) + noise(x-1, z+1, seed) + noise(x+1, z+1, seed)) / 16
    local sides = (noise(x-1, z, seed) + noise(x+1, z, seed) + noise(x, z-1, seed) + noise(x, z+1, seed)) / 8
    local center = noise(x, z, seed) / 4
    return corners + sides + center
end

function IslandGenerator.CreateNaturalIsland(islandType, position, seed)
    local config = GameData.IslandTypes[islandType]
    local size = math.random(config.size.min, config.size.max)
    seed = seed or math.random(1, 10000)
    
    local island = {
        type = islandType,
        position = position,
        size = size,
        parts = {},
        rings = {}
    }
    
    -- Create island model
    local islandModel = Instance.new("Model")
    islandModel.Name = islandType .. "_Island_" .. seed
    
    -- Generate terrain heightmap
    local heightMap = {}
    local resolution = 4  -- studs per terrain cell
    local cells = math.floor(size / resolution)
    local halfCells = math.floor(cells / 2)
    
    for x = -halfCells, halfCells do
        heightMap[x] = {}
        for z = -halfCells, halfCells do
            -- Distance from center (normalized 0-1)
            local dist = math.sqrt(x*x + z*z) / (cells/2)
            
            -- Base falloff (island shape)
            local height = math.max(0, 1 - dist^1.5)
            
            -- Add noise for natural terrain
            local noiseVal = smoothNoise(x * 0.3, z * 0.3, seed)
            height = height * (0.7 + noiseVal * 0.6)
            
            -- Apply island type modifiers
            if islandType == "STARTER" then
                height = height * 0.5  -- Flatter
            elseif islandType == "SUMMIT" then
                height = height * 1.5  -- Taller
                height = height + noiseVal * 0.3
            end
            
            heightMap[x][z] = math.max(0, height * (size * 0.15))
        end
    end
    
    -- Create terrain parts
    for x = -halfCells, halfCells - 1 do
        for z = -halfCells, halfCells - 1 do
            local h1 = heightMap[x] and heightMap[x][z] or 0
            local h2 = heightMap[x+1] and heightMap[x+1][z] or 0
            local h3 = heightMap[x] and heightMap[x][z+1] or 0
            local h4 = heightMap[x+1] and heightMap[x+1][z+1] or 0
            
            local avgHeight = (h1 + h2 + h3 + h4) / 4
            
            if avgHeight > 0.5 then
                -- Determine material based on height and noise
                local noiseVal = smoothNoise(x * 0.5, z * 0.5, seed + 1)
                local color, material
                
                if avgHeight > size * 0.08 then
                    -- High ground - rock/stone
                    color = noiseVal > 0.5 and TERRAIN_COLORS.ROCK or TERRAIN_COLORS.STONE
                    material = Enum.Material.Rock
                elseif avgHeight > size * 0.03 then
                    -- Mid ground - grass
                    color = noiseVal > 0.3 and TERRAIN_COLORS.GRASS_LIGHT or TERRAIN_COLORS.GRASS_DARK
                    material = Enum.Material.Grass
                else
                    -- Beach - sand
                    color = TERRAIN_COLORS.SAND
                    material = Enum.Material.Sand
                end
                
                -- Create terrain block
                local part = Instance.new("Part")
                part.Shape = Enum.PartType.Block
                part.Size = Vector3.new(resolution, math.max(resolution, avgHeight), resolution)
                part.Position = Vector3.new(
                    position.X + x * resolution,
                    position.Y + avgHeight / 2 - 5,
                    position.Z + z * resolution
                )
                part.Color = color
                part.Material = material
                part.Anchored = true
                part.TopSurface = Enum.SurfaceType.Smooth
                part.BottomSurface = Enum.SurfaceType.Smooth
                part.Parent = islandModel
                
                table.insert(island.parts, part)
            end
        end
    end
    
    -- Add cliffs/rock formations on edges
    for x = -halfCells, halfCells, 2 do
        for z = -halfCells, halfCells, 2 do
            local dist = math.sqrt(x*x + z*z) / (cells/2)
            
            if dist > 0.7 and dist < 0.95 then
                -- Edge rocks
                local noiseVal = smoothNoise(x, z, seed + 2)
                if noiseVal > 0.6 then
                    local rock = Instance.new("Part")
                    rock.Shape = Enum.PartType.Ball
                    local rockSize = 3 + noiseVal * 4
                    rock.Size = Vector3.new(rockSize, rockSize * 0.8, rockSize)
                    rock.Position = Vector3.new(
                        position.X + x * resolution,
                        position.Y + 2,
                        position.Z + z * resolution
                    )
                    rock.Color = TERRAIN_COLORS.ROCK
                    rock.Material = Enum.Material.Rock
                    rock.Anchored = true
                    rock.Parent = islandModel
                end
            end
        end
    end
    
    -- Add vegetation (trees/rocks) on top
    local thirdCells = math.floor(halfCells * 2 / 3)
    for i = 1, math.floor(size / 10) do
        local x = math.random(-thirdCells, thirdCells)
        local z = math.random(-thirdCells, thirdCells)
        local h = heightMap[x] and heightMap[x][z] or 0
        
        if h > size * 0.04 and h < size * 0.1 then
            local noiseVal = smoothNoise(x, z, seed + 3)
            
            if noiseVal > 0.4 then
                -- Tree
                local trunk = Instance.new("Part")
                trunk.Shape = Enum.PartType.Cylinder
                trunk.Size = Vector3.new(4, 1, 1)
                trunk.Orientation = Vector3.new(0, 0, 90)
                trunk.Position = Vector3.new(
                    position.X + x * resolution,
                    position.Y + h - 2,
                    position.Z + z * resolution
                )
                trunk.Color = TERRAIN_COLORS.DIRT
                trunk.Material = Enum.Material.Wood
                trunk.Anchored = true
                trunk.Parent = islandModel
                
                local leaves = Instance.new("Part")
                leaves.Shape = Enum.PartType.Ball
                leaves.Size = Vector3.new(5, 4, 5)
                leaves.Position = trunk.Position + Vector3.new(0, 3, 0)
                leaves.Color = TERRAIN_COLORS.GRASS_DARK
                leaves.Material = Enum.Material.LeafyGrass
                leaves.Anchored = true
                leaves.Parent = islandModel
            end
        end
    end
    
    -- Spawn rings in natural formations
    island.rings = IslandGenerator.SpawnRings(islandModel, position, size, heightMap, resolution, seed)
    
    island.model = islandModel
    return island
end

function IslandGenerator.SpawnRings(parent, islandPos, islandSize, heightMap, resolution, seed)
    local rings = {}
    local ringCount = math.random(5, 12)
    
    for i = 1, ringCount do
        -- Random position around island
        local angle = (i / ringCount) * math.pi * 2 + math.random() * 0.5
        local radius = islandSize * 0.3 + math.random() * islandSize * 0.3
        
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        
        -- Convert world offset to cell coords and clamp
        local halfCells = math.floor(math.floor(islandSize / resolution) / 2)
        local gridX = math.max(-halfCells, math.min(halfCells, math.floor(x / resolution)))
        local gridZ = math.max(-halfCells, math.min(halfCells, math.floor(z / resolution)))
        local height = (heightMap[gridX] and heightMap[gridX][gridZ]) or 5
        
        local ringPos = Vector3.new(
            islandPos.X + x,
            islandPos.Y + height + 8,
            islandPos.Z + z
        )
        
        -- Create ring model
        local ringModel = Instance.new("Model")
        ringModel.Name = "Ring_" .. i
        
        -- Outer ring using SpecialMesh (Torus shape)
        local outer = Instance.new("Part")
        outer.Name = "Outer"
        outer.Size = Vector3.new(GameData.RING_SIZE, GameData.RING_SIZE, 1.5)
        outer.Color = Color3.fromRGB(255, 215, 0)
        outer.Material = Enum.Material.Neon
        outer.Anchored = true
        outer.CanCollide = false
        outer.Position = ringPos
        outer.Transparency = 0.1
        outer.Parent = ringModel
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://3270017"
        mesh.Scale = Vector3.new(GameData.RING_SIZE * 0.18, GameData.RING_SIZE * 0.18, 0.3)
        mesh.Parent = outer
        
        -- Inner glow
        local inner = Instance.new("Part")
        inner.Name = "Inner"
        inner.Shape = Enum.PartType.Ball
        inner.Size = Vector3.new(GameData.RING_SIZE * 0.6, GameData.RING_SIZE * 0.6, GameData.RING_SIZE * 0.6)
        inner.Color = Color3.fromRGB(100, 200, 255)
        inner.Material = Enum.Material.Neon
        inner.Anchored = true
        inner.CanCollide = false
        inner.Position = ringPos
        inner.Transparency = 0.85
        inner.Parent = ringModel
        
        -- Point light for glow
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 215, 0)
        light.Brightness = 3
        light.Range = 20
        light.Parent = outer
        
        -- Trigger part
        local trigger = Instance.new("Part")
        trigger.Name = "Trigger"
        trigger.Shape = Enum.PartType.Ball
        trigger.Size = Vector3.new(GameData.RING_SIZE + 4, GameData.RING_SIZE + 4, GameData.RING_SIZE + 4)
        trigger.Transparency = 1
        trigger.Anchored = true
        trigger.CanCollide = false
        trigger.Position = ringPos
        trigger.Parent = ringModel
        
        local value = Instance.new("IntValue")
        value.Name = "Value"
        value.Value = 1
        value.Parent = trigger
        
        -- Spin animation using server-side task.spawn (no Script.Source)
        local outerRef = outer
        task.spawn(function()
            while outerRef and outerRef.Parent do
                outerRef.CFrame = outerRef.CFrame * CFrame.Angles(0, math.rad(2), 0)
                task.wait(0.05)
            end
        end)
        
        ringModel.Parent = parent
        table.insert(rings, {model = ringModel, trigger = trigger, outer = outer, position = ringPos})
    end
    
    return rings
end

return IslandGenerator
