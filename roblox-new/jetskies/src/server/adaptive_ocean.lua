local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AdaptiveOcean = {}

-- Ocean configuration
local OCEAN_CONFIG = {
    BASE_HEIGHT = -10,
    GRID_COUNT = 20,          -- NxN grid of wave tiles
    WAVE_TILE_SIZE = 6000,    -- total ocean size
    WAVE_HEIGHT = 4,          -- max wave height
    WAVE_SPEED = 0.8,         -- wave animation speed
    UPDATE_RATE = 0.08,       -- seconds between updates
    COLORS = {
        DEEP = Color3.fromRGB(0, 60, 120),
        SHALLOW = Color3.fromRGB(0, 100, 170),
        FOAM = Color3.fromRGB(180, 230, 255)
    }
}

-- Wave state
local oceanState = {
    waveTiles = {},
    time = 0,
    players = {},
    lastUpdate = 0
}

-- Simplex noise approximation for waves
local function noise(x, z, time)
    -- Combine multiple sine waves for natural look
    local wave1 = math.sin(x * 0.05 + time) * math.cos(z * 0.03 + time * 0.7)
    local wave2 = math.sin(x * 0.1 - time * 0.5) * 0.5
    local wave3 = math.cos(z * 0.08 + time * 0.3) * 0.3
    local detail = math.sin(x * 0.3 + z * 0.2) * 0.1
    
    return (wave1 + wave2 + wave3 + detail) * OCEAN_CONFIG.WAVE_HEIGHT
end

function AdaptiveOcean.Init()
    print("[AdaptiveOcean] Initializing...")
    
    -- Create world folder
    local worldFolder = Workspace:FindFirstChild("World")
    if not worldFolder then
        worldFolder = Instance.new("Folder")
        worldFolder.Name = "World"
        worldFolder.Parent = Workspace
    end
    
    -- Create ocean container
    local oceanFolder = Instance.new("Folder")
    oceanFolder.Name = "Ocean"
    oceanFolder.Parent = worldFolder
    oceanState.oceanFolder = oceanFolder
    
    -- Create base water plane
    AdaptiveOcean.CreateBasePlane(oceanFolder)
    
    -- Create wave grid
    AdaptiveOcean.CreateWaveGrid(oceanFolder)
    
    -- Create distant horizon
    AdaptiveOcean.CreateHorizon(oceanFolder)
    
    -- Start update loop
    RunService.Heartbeat:Connect(function(dt)
        oceanState.time = oceanState.time + dt * OCEAN_CONFIG.WAVE_SPEED
        
        -- Throttled updates
        oceanState.lastUpdate = oceanState.lastUpdate + dt
        if oceanState.lastUpdate >= OCEAN_CONFIG.UPDATE_RATE then
            oceanState.lastUpdate = 0
            AdaptiveOcean.UpdateWaves()
        end
    end)
    
    -- Track players for adaptive detail
    local Players = game:GetService("Players")
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            table.insert(oceanState.players, player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        for i, p in ipairs(oceanState.players) do
            if p == player then
                table.remove(oceanState.players, i)
                break
            end
        end
    end)
    
    print("[AdaptiveOcean] Ocean created with adaptive waves")
end

function AdaptiveOcean.CreateBasePlane(parent)
    -- Large flat water plane as base
    local base = Instance.new("Part")
    base.Name = "OceanBase"
    base.Size = Vector3.new(OCEAN_CONFIG.WAVE_TILE_SIZE, 4, OCEAN_CONFIG.WAVE_TILE_SIZE)
    base.Position = Vector3.new(0, OCEAN_CONFIG.BASE_HEIGHT - 4, 0)
    base.Color = OCEAN_CONFIG.COLORS.DEEP
    base.Material = Enum.Material.Water
    base.Transparency = 0.15
    base.Anchored = true
    base.CanCollide = false
    base.TopSurface = Enum.SurfaceType.Smooth
    base.BottomSurface = Enum.SurfaceType.Smooth
    base.Parent = parent
    
    -- Kill brick script for falling players
    base.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Check if player is in a JetSky
            local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
            if player then
                local jetSky = Workspace:FindFirstChild("JetSky_" .. player.UserId)
                if not jetSky then
                    -- Only kill if not in JetSky
                    humanoid.Health = 0
                end
            end
        end
    end)
end

function AdaptiveOcean.CreateWaveGrid(parent)
    local gridCount = OCEAN_CONFIG.GRID_COUNT
    local tileSize = OCEAN_CONFIG.WAVE_TILE_SIZE / gridCount
    
    for x = -gridCount/2, gridCount/2 - 1 do
        for z = -gridCount/2, gridCount/2 - 1 do
            local tile = Instance.new("Part")
            tile.Name = "Wave_" .. x .. "_" .. z
            tile.Size = Vector3.new(tileSize, 3, tileSize)
            local posX = x * tileSize + tileSize/2
            local posZ = z * tileSize + tileSize/2
            tile.Position = Vector3.new(posX, OCEAN_CONFIG.BASE_HEIGHT, posZ)
            tile.Color = OCEAN_CONFIG.COLORS.SHALLOW
            tile.Material = Enum.Material.Water
            tile.Transparency = 0.35
            tile.Anchored = true
            tile.CanCollide = false
            tile.TopSurface = Enum.SurfaceType.Smooth
            tile.BottomSurface = Enum.SurfaceType.Smooth
            tile.CastShadow = false
            tile.Parent = parent
            
            tile:SetAttribute("BaseX", posX)
            tile:SetAttribute("BaseZ", posZ)
            tile:SetAttribute("GridX", x)
            tile:SetAttribute("GridZ", z)
            
            table.insert(oceanState.waveTiles, tile)
        end
    end
end

function AdaptiveOcean.CreateHorizon(parent)
    -- Distant horizon rim
    local horizon = Instance.new("Part")
    horizon.Name = "Horizon"
    horizon.Size = Vector3.new(OCEAN_CONFIG.WAVE_TILE_SIZE * 1.5, 60, OCEAN_CONFIG.WAVE_TILE_SIZE * 1.5)
    horizon.Orientation = Vector3.new(0, 0, 0)
    horizon.Position = Vector3.new(0, OCEAN_CONFIG.BASE_HEIGHT - 30, 0)
    horizon.Color = Color3.fromRGB(0, 40, 100)
    horizon.Material = Enum.Material.SmoothPlastic
    horizon.Transparency = 0.0
    horizon.Anchored = true
    horizon.CanCollide = false
    horizon.CastShadow = false
    horizon.Parent = parent
    
    -- Foam/spray layer on top of ocean
    local foam = Instance.new("Part")
    foam.Name = "OceanFoam"
    foam.Size = Vector3.new(OCEAN_CONFIG.WAVE_TILE_SIZE, 1, OCEAN_CONFIG.WAVE_TILE_SIZE)
    foam.Position = Vector3.new(0, OCEAN_CONFIG.BASE_HEIGHT + OCEAN_CONFIG.WAVE_HEIGHT + 0.5, 0)
    foam.Color = Color3.fromRGB(220, 245, 255)
    foam.Material = Enum.Material.Neon
    foam.Transparency = 0.92
    foam.Anchored = true
    foam.CanCollide = false
    foam.CastShadow = false
    foam.Parent = parent
end

function AdaptiveOcean.UpdateWaves()
    local time = oceanState.time
    local config = OCEAN_CONFIG
    
    -- Get average player position for adaptive detail
    local avgPlayerPos = Vector3.zero
    local playerCount = #oceanState.players
    
    if playerCount > 0 then
        for _, player in ipairs(oceanState.players) do
            if player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    avgPlayerPos = avgPlayerPos + hrp.Position
                end
            end
        end
        avgPlayerPos = avgPlayerPos / playerCount
    end
    
    -- Update each wave tile
    for _, tile in ipairs(oceanState.waveTiles) do
        local baseX = tile:GetAttribute("BaseX")
        local baseZ = tile:GetAttribute("BaseZ")
        
        -- Calculate wave height at this position
        local waveHeight = noise(baseX, baseZ, time)
        
        -- Adaptive detail based on distance from players
        local distanceFromPlayer = math.huge
        if playerCount > 0 then
            distanceFromPlayer = math.sqrt((baseX - avgPlayerPos.X)^2 + (baseZ - avgPlayerPos.Z)^2)
        end
        
        -- Far tiles get reduced wave movement for performance
        local heightScale = distanceFromPlayer > 800 and 0.3 or (distanceFromPlayer > 400 and 0.7 or 1.0)
        waveHeight = waveHeight * heightScale
        
        -- Update tile Y position only (no tilting - avoids gaps between tiles)
        tile.Position = Vector3.new(baseX, config.BASE_HEIGHT + waveHeight, baseZ)
        
        -- Adjust color based on wave height
        if waveHeight > config.WAVE_HEIGHT * 0.55 then
            tile.Color = config.COLORS.FOAM
            tile.Transparency = 0.25
        elseif waveHeight > 0 then
            tile.Color = config.COLORS.SHALLOW
            tile.Transparency = 0.35
        else
            tile.Color = config.COLORS.DEEP
            tile.Transparency = 0.45
        end
    end
end

-- Get wave height at a specific position
function AdaptiveOcean.GetWaveHeight(x, z)
    return OCEAN_CONFIG.BASE_HEIGHT + noise(x, z, oceanState.time)
end

-- Check if a position is submerged
function AdaptiveOcean.IsSubmerged(position)
    local waveHeight = AdaptiveOcean.GetWaveHeight(position.X, position.Z)
    return position.Y < waveHeight
end

return AdaptiveOcean
