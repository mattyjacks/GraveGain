local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AdaptiveOcean = {}

-- Ocean configuration
local OCEAN_CONFIG = {
    BASE_HEIGHT = -10,
    GRID_SIZE = 50,           -- studs per wave tile
    WAVE_TILE_SIZE = 4000,    -- total ocean size
    WAVE_HEIGHT = 3,          -- max wave height
    WAVE_SPEED = 1.5,         -- wave animation speed
    WAVE_FREQUENCY = 0.1,     -- wave density
    UPDATE_RATE = 0.1,        -- seconds between updates
    COLORS = {
        DEEP = Color3.fromRGB(0, 80, 140),
        SHALLOW = Color3.fromRGB(0, 120, 180),
        FOAM = Color3.fromRGB(200, 240, 255)
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
    base.Size = Vector3.new(OCEAN_CONFIG.WAVE_TILE_SIZE, 1, OCEAN_CONFIG.WAVE_TILE_SIZE)
    base.Position = Vector3.new(0, OCEAN_CONFIG.BASE_HEIGHT - 2, 0)
    base.Color = OCEAN_CONFIG.COLORS.DEEP
    base.Material = Enum.Material.Water
    base.Transparency = 0.3
    base.Anchored = true
    base.CanCollide = false
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
    -- Create grid of wave tiles
    local gridCount = 8  -- 8x8 grid around center
    local tileSize = OCEAN_CONFIG.WAVE_TILE_SIZE / gridCount
    
    for x = -gridCount/2, gridCount/2 - 1 do
        for z = -gridCount/2, gridCount/2 - 1 do
            local tile = Instance.new("Part")
            tile.Name = "Wave_" .. x .. "_" .. z
            tile.Size = Vector3.new(tileSize, 2, tileSize)
            tile.Position = Vector3.new(
                x * tileSize + tileSize/2,
                OCEAN_CONFIG.BASE_HEIGHT,
                z * tileSize + tileSize/2
            )
            tile.Color = OCEAN_CONFIG.COLORS.SHALLOW
            tile.Material = Enum.Material.SmoothPlastic
            tile.Transparency = 0.4
            tile.Anchored = true
            tile.CanCollide = false
            tile.Parent = parent
            
            -- Store original position
            tile:SetAttribute("BaseX", tile.Position.X)
            tile:SetAttribute("BaseZ", tile.Position.Z)
            tile:SetAttribute("GridX", x)
            tile:SetAttribute("GridZ", z)
            
            table.insert(oceanState.waveTiles, tile)
        end
    end
end

function AdaptiveOcean.CreateHorizon(parent)
    -- Create distant horizon fog effect
    local horizon = Instance.new("Part")
    horizon.Name = "Horizon"
    horizon.Shape = Enum.PartType.Cylinder
    horizon.Size = Vector3.new(OCEAN_CONFIG.WAVE_TILE_SIZE * 1.5, 100, OCEAN_CONFIG.WAVE_TILE_SIZE * 1.5)
    horizon.Orientation = Vector3.new(0, 0, 90)
    horizon.Position = Vector3.new(0, OCEAN_CONFIG.BASE_HEIGHT + 30, 0)
    horizon.Color = Color3.fromRGB(150, 200, 255)
    horizon.Material = Enum.Material.Glass
    horizon.Transparency = 0.9
    horizon.Anchored = true
    horizon.CanCollide = false
    horizon.Parent = parent
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
        local gridX = tile:GetAttribute("GridX")
        local gridZ = tile:GetAttribute("GridZ")
        
        -- Calculate wave height at this position
        local waveHeight = noise(baseX, baseZ, time)
        
        -- Adaptive detail based on distance from players
        local distanceFromPlayer = math.sqrt((baseX - avgPlayerPos.X)^2 + (baseZ - avgPlayerPos.Z)^2)
        
        -- Far tiles move less for performance
        if distanceFromPlayer > 500 then
            waveHeight = waveHeight * 0.5
        end
        
        -- Update tile position
        tile.Position = Vector3.new(baseX, config.BASE_HEIGHT + waveHeight, baseZ)
        
        -- Adjust color based on height (foam on peaks)
        if waveHeight > config.WAVE_HEIGHT * 0.6 then
            tile.Color = config.COLORS.FOAM
            tile.Transparency = 0.2
        elseif waveHeight > 0 then
            tile.Color = config.COLORS.SHALLOW
            tile.Transparency = 0.4
        else
            tile.Color = config.COLORS.DEEP
            tile.Transparency = 0.5
        end
        
        -- Tilt tile to match wave slope
        local slopeX = noise(baseX + 5, baseZ, time) - waveHeight
        local slopeZ = noise(baseX, baseZ + 5, time) - waveHeight
        tile.Orientation = Vector3.new(slopeZ * 5, 0, -slopeX * 5)
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
