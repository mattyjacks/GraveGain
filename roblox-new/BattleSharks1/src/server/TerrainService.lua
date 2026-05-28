-- BattleSharks Server Terrain Service
-- Manages terrain generation, loading, and synchronization

local TerrainService = {}

-- Service configuration
TerrainService.CONFIG = {
	ENABLE_TERRAIN_STREAMING = true,
	STREAM_UPDATE_RATE = 10,  -- Updates per second
	CHUNK_GENERATION_RATE = 2,  -- Chunks per frame
	MESH_UPDATE_RATE = 1,  -- Mesh updates per frame
	PLAYER_TRACKING_RANGE = 200,  -- Studs
	SYNC_CHUNKS_TO_CLIENTS = true
}

-- Service state
TerrainService.State = {
	IsInitialized = false,
	Players = {},
	TerrainFolder = nil,
	LastUpdateTime = 0,
	LastChunkGeneration = 0,
	LastMeshUpdate = 0,
	TotalChunksGenerated = 0,
	TotalMeshesUpdated = 0
}

-- Initialize terrain service
function TerrainService.Initialize()
	if TerrainService.State.IsInitialized then
		return false
	end
	
	-- Create terrain folder in workspace
	print("Creating terrain folder in workspace...")
	TerrainService.State.TerrainFolder = Instance.new("Folder")
	TerrainService.State.TerrainFolder.Name = "BattleSharksTerrain"
	TerrainService.State.TerrainFolder.Parent = workspace
	print("Terrain folder created:", TerrainService.State.TerrainFolder:GetFullName())
	
	-- Generate initial terrain immediately
	TerrainService.UpdateWorkspaceTerrain()
	
	-- Start terrain update loop
	TerrainService.StartUpdateLoop()
	
	TerrainService.State.IsInitialized = true
	print("Terrain Service initialized")
	
	return true
end

-- Handle player joining
function TerrainService.OnPlayerAdded(player)
	-- Initialize player data
	TerrainService.State.Players[player.UserId] = {
		Player = player,
		LastPosition = Vector3.new(0, 0, 0),
		LoadedChunks = {},
		LastSyncTime = tick()
	}
	
	print("Terrain Service: Player added", player.Name)
end

-- Handle player leaving
function TerrainService.OnPlayerRemoved(player)
	-- Clean up player data
	TerrainService.State.Players[player.UserId] = nil
	
	print("Terrain Service: Player removed", player.Name)
end

-- Start terrain update loop
function TerrainService.StartUpdateLoop()
	task.spawn(function()
		while true do
			local currentTime = tick()
			
			-- Update performance stats
			TerrainService.State.LastUpdateTime = currentTime
			
			-- Only update terrain if needed (for now, don't regenerate)
			-- TerrainService.UpdateWorkspaceTerrain() -- Disabled to prevent continuous regeneration
			
			task.wait(1 / TerrainService.CONFIG.STREAM_UPDATE_RATE)
		end
	end)
end

-- Create hexagonal reef with sand and fish
function TerrainService.UpdateWorkspaceTerrain()
	-- Check if terrain folder exists
	if not TerrainService.State.TerrainFolder then
		warn("Terrain folder not found!")
		return
	end
	
	-- Clear existing terrain
	TerrainService.State.TerrainFolder:ClearAllChildren()
	
	print("Creating hexagonal reef with sand and fish...")
	
	-- Create underwater environment
	TerrainService.CreateUnderwaterEnvironment()
	
	-- Create hexagonal reef structures
	local reefParts = TerrainService.CreateHexagonalReef()
	
	-- Add fish
	local fishCount = TerrainService.AddFish()
	
	-- Add coral and decorations
	local decorationCount = TerrainService.AddCoralAndDecorations()
	
	print("Created hexagonal reef:", reefParts, "hexagons,", fishCount, "fish,", decorationCount, "decorations")
end

-- Create underwater environment
function TerrainService.CreateUnderwaterEnvironment()
	-- Create water effect (large transparent blue part)
	local water = Instance.new("Part")
	water.Name = "UnderwaterEnvironment"
	water.Size = Vector3.new(200, 100, 200)
	water.Position = Vector3.new(0, 25, 0)
	water.Anchored = true
	water.CanCollide = false
	water.Material = Enum.Material.Glass
	water.Color = Color3.new(0.1, 0.3, 0.8)
	water.Transparency = 0.7
	water.Parent = TerrainService.State.TerrainFolder
	
	-- Add underwater lighting
	local light = Instance.new("PointLight")
	light.Name = "UnderwaterLight"
	light.Brightness = 0.8
	light.Color = Color3.new(0.2, 0.6, 1.0)
	light.Range = 100
	light.Parent = water
end

-- Create hexagonal reef structures
function TerrainService.CreateHexagonalReef()
	local hexSize = 8  -- Size of each hexagon
	local hexHeight = 2  -- Height of hexagonal prisms
	local partsCreated = 0
	
	-- Create hexagonal grid pattern
	for q = -3, 3 do
		for r = -3, 3 do
			-- Convert hex coordinates to world position
			local worldX = hexSize * 1.5 * q
			local worldZ = hexSize * math.sqrt(3) * (r + q/2)
			
			-- Vary the height for natural reef look
			local height = hexHeight + math.random(-1, 2)
			
			-- Create hexagonal prism using multiple wedges
			local hexModel = TerrainService.CreateHexagonalPrism(worldX, height, worldZ, hexSize)
			if hexModel then
				hexModel.Name = "HexReef_" .. q .. "_" .. r
				hexModel.Parent = TerrainService.State.TerrainFolder
				partsCreated += 1
			end
		end
	end
	
	return partsCreated
end

-- Create a single hexagonal prism using wedges
function TerrainService.CreateHexagonalPrism(x, y, z, size)
	local model = Instance.new("Model")
	
	-- Create 6 wedges to form a hexagon
	local wedgeSize = size
	local wedgeHeight = y
	
	-- Materials for reef look
	local materials = {
		Enum.Material.Sand,
		Enum.Material.Slate,
		Enum.Material.Rock,
		Enum.Material.Concrete
	}
	
	local colors = {
		Color3.new(0.9, 0.8, 0.6),  -- Sand
		Color3.new(0.7, 0.6, 0.5),  -- Brown rock
		Color3.new(0.6, 0.5, 0.4),  -- Dark rock
		Color3.new(0.8, 0.7, 0.6)   -- Light sand
	}
	
	-- Create 6 wedges in hexagonal pattern
	for i = 1, 6 do
		local angle = (i - 1) * math.pi / 3
		local wedge = Instance.new("WedgePart")
		
		-- Position wedge to form hexagon
		local offsetX = math.cos(angle) * size * 0.5
		local offsetZ = math.sin(angle) * size * 0.5
		
		wedge.Size = Vector3.new(wedgeSize, wedgeHeight, wedgeSize)
		wedge.Position = Vector3.new(x + offsetX, y/2, z + offsetZ)
		wedge.Orientation = Vector3.new(0, (i - 1) * 60, 0)
		
		-- Random material and color for variety
		local materialIndex = math.random(1, #materials)
		wedge.Material = materials[materialIndex]
		wedge.Color = colors[materialIndex]
		
		wedge.Anchored = true
		wedge.CanCollide = true
		wedge.TopSurface = Enum.SurfaceType.Smooth
		wedge.BottomSurface = Enum.SurfaceType.Smooth
		wedge.Parent = model
	end
	
	-- Add a center cylinder to fill the hexagon
	local center = Instance.new("CylinderMesh")
	local centerPart = Instance.new("Part")
	centerPart.Name = "Center"
	centerPart.Size = Vector3.new(size * 0.8, wedgeHeight, size * 0.8)
	centerPart.Position = Vector3.new(x, y/2, z)
	centerPart.Material = Enum.Material.Sand
	centerPart.Color = Color3.new(0.9, 0.8, 0.6)
	centerPart.Anchored = true
	centerPart.CanCollide = true
	centerPart.TopSurface = Enum.SurfaceType.Smooth
	centerPart.BottomSurface = Enum.SurfaceType.Smooth
	centerPart.Parent = model
	
	return model
end

-- Add fish to the reef
function TerrainService.AddFish()
	local fishCount = 0
	local fishTypes = {
		{Size = Vector3.new(2, 1, 4), Color = Color3.new(1, 0.5, 0), Name = "TropicalFish"},
		{Size = Vector3.new(3, 1.5, 6), Color = Color3.new(0.5, 0.5, 1), Name = "BlueFish"},
		{Size = Vector3.new(1.5, 0.8, 3), Color = Color3.new(1, 1, 0.5), Name = "YellowFish"},
		{Size = Vector3.new(4, 2, 8), Color = Color3.new(0.8, 0.8, 0.8), Name = "SilverFish"}
	}
	
	-- Add fish swimming around the reef
	for i = 1, 15 do
		local fishType = fishTypes[math.random(1, #fishTypes)]
		local fish = Instance.new("Part")
		fish.Name = fishType.Name .. "_" .. i
		fish.Size = fishType.Size
		fish.Position = Vector3.new(
			math.random(-60, 60),
			math.random(10, 40),
			math.random(-60, 60)
		)
		fish.Material = Enum.Material.Neon
		fish.Color = fishType.Color
		fish.Transparency = 0.2
		fish.Anchored = false
		fish.CanCollide = false
		
		-- Add fish movement (simple floating animation)
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
		bodyVelocity.Velocity = Vector3.new(
			math.random(-2, 2),
			math.random(-1, 1),
			math.random(-2, 2)
		)
		bodyVelocity.Parent = fish
		
		fish.Parent = TerrainService.State.TerrainFolder
		fishCount += 1
	end
	
	return fishCount
end

-- Add coral and decorations
function TerrainService.AddCoralAndDecorations()
	local decorationCount = 0
	
	-- Add coral
	for i = 1, 20 do
		local coral = Instance.new("Part")
		coral.Name = "Coral_" .. i
		coral.Size = Vector3.new(
			math.random(1, 3),
			math.random(2, 8),
			math.random(1, 3)
		)
		coral.Position = Vector3.new(
			math.random(-50, 50),
			coral.Size.Y / 2 + 2,
			math.random(-50, 50)
		)
		coral.Material = Enum.Material.Neon
		coral.Color = Color3.new(
			math.random(0.5, 1),
			math.random(0.5, 1),
			math.random(0.5, 1)
		)
		coral.Transparency = 0.3
		coral.Anchored = true
		coral.CanCollide = false
		coral.Parent = TerrainService.State.TerrainFolder
		decorationCount += 1
	end
	
	-- Add seaweed
	for i = 1, 15 do
		local seaweed = Instance.new("Part")
		seaweed.Name = "Seaweed_" .. i
		seaweed.Size = Vector3.new(0.5, math.random(5, 15), 0.5)
		seaweed.Position = Vector3.new(
			math.random(-50, 50),
			seaweed.Size.Y / 2,
			math.random(-50, 50)
		)
		seaweed.Material = Enum.Material.Grass
		seaweed.Color = Color3.new(0.1, 0.6, 0.2)
		seaweed.Anchored = true
		seaweed.CanCollide = false
		seaweed.Parent = TerrainService.State.TerrainFolder
		decorationCount += 1
	end
	
	return decorationCount
end

-- Get terrain service statistics
function TerrainService.GetStats()
	return {
		IsInitialized = TerrainService.State.IsInitialized,
		PlayerCount = #TerrainService.State.Players,
		TotalChunksGenerated = TerrainService.State.TotalChunksGenerated,
		TotalMeshesUpdated = TerrainService.State.TotalMeshesUpdated,
		LastUpdateTime = TerrainService.State.LastUpdateTime
	}
end

-- Cleanup terrain service
function TerrainService.Cleanup()
	-- Clear terrain folder
	if TerrainService.State.TerrainFolder then
		TerrainService.State.TerrainFolder:ClearAllChildren()
		TerrainService.State.TerrainFolder:Destroy()
		TerrainService.State.TerrainFolder = nil
	end
	
	-- Clear player data
	TerrainService.State.Players = {}
	
	TerrainService.State.IsInitialized = false
	print("Terrain Service cleaned up")
end

return TerrainService
