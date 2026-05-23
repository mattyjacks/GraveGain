-- Tower Hop - Procedural Tower Generator
-- Generates infinite tower with increasing difficulty

local Config
local success = pcall(function()
    Config = require(script.Parent.config)
end)

if not success then
    warn("TowerGenerator: Failed to load config!")
    Config = {
        TOWER_RADIUS = 20,
        FLOOR_HEIGHT = 4,
        PLATFORM_SIZE_MIN = 6,
        PLATFORM_SIZE_MAX = 16,
        GAP_MIN = 2,
        GAP_MAX = 6,
        CHECKPOINT_INTERVAL = 10,
        PLATFORM_COLORS = {
            Color3.fromRGB(76, 175, 80),
            Color3.fromRGB(33, 150, 243),
            Color3.fromRGB(255, 152, 0),
            Color3.fromRGB(156, 39, 176),
        },
        DIFFICULTY_SETTINGS = {
            [1] = { gapMultiplier = 1.0, speedMultiplier = 1.0, movingPlatforms = false },
            [25] = { gapMultiplier = 1.2, speedMultiplier = 1.1, movingPlatforms = true },
        },
    }
end

local TowerGenerator = {}

-- Storage for generated floors
TowerGenerator.GeneratedFloors = {}
TowerGenerator.FloorParents = {}

-- Utility: Get difficulty for floor
function TowerGenerator:GetDifficulty(floorNum)
    local difficulty = Config.DIFFICULTY_SETTINGS[1]
    for threshold, settings in pairs(Config.DIFFICULTY_SETTINGS) do
        if floorNum >= threshold then
            difficulty = settings
        end
    end
    return difficulty
end

-- Utility: Random position within tower radius
function TowerGenerator:GetRandomPosition(y, radius)
    local angle = math.random() * math.pi * 2
    local r = math.random() * radius
    return Vector3.new(
        math.cos(angle) * r,
        y,
        math.sin(angle) * r
    )
end

-- Generate a single floor
function TowerGenerator:GenerateFloor(floorNum, parent)
    if self.GeneratedFloors[floorNum] then
        return self.GeneratedFloors[floorNum]
    end

    local difficulty = self:GetDifficulty(floorNum)
    local color = Config.PLATFORM_COLORS[((floorNum - 1) % #Config.PLATFORM_COLORS) + 1]
    
    local floorData = {
        floorNum = floorNum,
        platforms = {},
        spawnPoint = nil,
        finishPoint = nil,
    }
    
    local baseY = (floorNum - 1) * Config.FLOOR_HEIGHT
    
    -- Create spawn platform (always at center-ish)
    local spawnPos = Vector3.new(0, baseY + 2, 0)
    if floorNum > 1 then
        -- Connect to previous floor's finish
        local prevFloor = self.GeneratedFloors[floorNum - 1]
        if prevFloor then
            spawnPos = prevFloor.finishPoint + Vector3.new(0, Config.FLOOR_HEIGHT, 0)
        end
    end
    
    local spawnPlatform = self:CreatePlatform(spawnPos, 8, color, parent)
    floorData.spawnPoint = spawnPos
    table.insert(floorData.platforms, spawnPlatform)
    
    -- Generate path of platforms
    local currentPos = spawnPos
    local platformsInFloor = math.random(3, 6)
    
    for i = 1, platformsInFloor do
        -- Calculate next position with gap
        local gap = Config.GAP_MIN + (Config.GAP_MAX - Config.GAP_MIN) * difficulty.gapMultiplier
        gap = math.random(gap * 10, gap * 15) / 10
        
        local angle = math.random() * math.pi * 2
        local nextPos = currentPos + Vector3.new(
            math.cos(angle) * gap,
            0,
            math.sin(angle) * gap
        )
        
        -- Keep within tower radius
        local distFromCenter = math.sqrt(nextPos.X^2 + nextPos.Z^2)
        if distFromCenter > Config.TOWER_RADIUS then
            nextPos = nextPos * (Config.TOWER_RADIUS / distFromCenter)
            nextPos = Vector3.new(nextPos.X, currentPos.Y, nextPos.Z)
        end
        
        -- Size varies by difficulty
        local size = math.random(Config.PLATFORM_SIZE_MIN, Config.PLATFORM_SIZE_MAX)
        if difficulty.movingPlatforms and math.random() < 0.3 then
            -- Create moving platform
            local movingPlat = self:CreateMovingPlatform(nextPos, size, color, parent, currentPos)
            table.insert(floorData.platforms, movingPlat)
        else
            local platform = self:CreatePlatform(nextPos, size, color, parent)
            table.insert(floorData.platforms, platform)
        end
        
        currentPos = nextPos
    end
    
    -- Create finish platform (checkpoint)
    local finishPos = currentPos + Vector3.new(0, 0, 0)
    local finishSize = 10
    local finishPlatform = self:CreateFinishPlatform(finishPos, finishSize, floorNum, parent)
    floorData.finishPoint = finishPos
    table.insert(floorData.platforms, finishPlatform)
    
    -- Add floor number sign
    self:CreateFloorSign(floorNum, finishPos + Vector3.new(0, 3, 0), parent)
    
    self.GeneratedFloors[floorNum] = floorData
    return floorData
end

-- Create a basic platform
function TowerGenerator:CreatePlatform(position, size, color, parent)
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Shape = Enum.PartType.Block
    platform.Size = Vector3.new(size, 1, size)
    platform.Position = position
    platform.Anchored = true
    platform.CanCollide = true
    platform.Color = color
    platform.Material = Enum.Material.SmoothPlastic
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Parent = parent
    return platform
end

-- Create a moving platform
function TowerGenerator:CreateMovingPlatform(position, size, color, parent, startPos)
    local platform = self:CreatePlatform(position, size, color, parent)
    platform.Name = "MovingPlatform"
    
    -- Add movement script via attributes
    platform:SetAttribute("IsMoving", true)
    platform:SetAttribute("MoveSpeed", 2 + math.random() * 2)
    platform:SetAttribute("StartPos", startPos)
    platform:SetAttribute("EndPos", position)
    
    return platform
end

-- Create finish checkpoint platform
function TowerGenerator:CreateFinishPlatform(position, size, floorNum, parent)
    local platform = Instance.new("Part")
    platform.Name = "Checkpoint_" .. floorNum
    platform.Shape = Enum.PartType.Block
    platform.Size = Vector3.new(size, 1, size)
    platform.Position = position
    platform.Anchored = true
    platform.CanCollide = true
    platform.Color = Color3.fromRGB(255, 215, 0) -- Gold
    platform.Material = Enum.Material.Neon
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Checkpoint glow
    local light = Instance.new("PointLight")
    light.Brightness = 1
    light.Range = 10
    light.Color = Color3.fromRGB(255, 215, 0)
    light.Parent = platform
    
    -- Checkpoint touched event (handled by server)
    platform:SetAttribute("FloorNum", floorNum)
    platform:SetAttribute("IsCheckpoint", true)
    
    platform.Parent = parent
    return platform
end

-- Create floor number sign
function TowerGenerator:CreateFloorSign(floorNum, position, parent)
    local sign = Instance.new("Part")
    sign.Name = "FloorSign_" .. floorNum
    sign.Size = Vector3.new(4, 2, 0.5)
    sign.Position = position
    sign.Anchored = true
    sign.CanCollide = false
    sign.Transparency = 1
    sign.Parent = parent
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = sign
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "FLOOR " .. floorNum
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    return sign
end

-- Clear tower (for reset)
function TowerGenerator:ClearTower()
    self.GeneratedFloors = {}
    for _, parent in pairs(self.FloorParents) do
        if parent then
            parent:Destroy()
        end
    end
    self.FloorParents = {}
end

-- Get spawn location for a floor
function TowerGenerator:GetSpawnLocation(floorNum)
    local floor = self.GeneratedFloors[floorNum]
    if floor then
        return floor.spawnPoint + Vector3.new(0, 5, 0)
    end
    return Vector3.new(0, 10, 0)
end

return TowerGenerator
