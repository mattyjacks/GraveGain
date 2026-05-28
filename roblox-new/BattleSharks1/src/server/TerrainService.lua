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

-- Create underwater environment using Roblox Terrain water
function TerrainService.CreateUnderwaterEnvironment()
	-- Fill a 200x50x200 region with Terrain water
	workspace.Terrain:FillBlock(
		CFrame.new(0, 25, 0),
		Vector3.new(200, 50, 200),
		Enum.Material.Water
	)
	
	-- Underwater ambient light source
	local ambientPart = Instance.new("Part")
	ambientPart.Name = "UnderwaterAmbient"
	ambientPart.Size = Vector3.new(1, 1, 1)
	ambientPart.Position = Vector3.new(0, 30, 0)
	ambientPart.Anchored = true
	ambientPart.CanCollide = false
	ambientPart.Transparency = 1
	ambientPart.Parent = TerrainService.State.TerrainFolder
	local ambient = Instance.new("PointLight")
	ambient.Brightness = 1.5
	ambient.Color = Color3.new(0.1, 0.5, 0.9)
	ambient.Range = 200
	ambient.Parent = ambientPart
	
	-- Sunbeams
	TerrainService.CreateSunbeams()
end

-- Create animated sunbeams (tall thin neon cylinders slanted at angles)
function TerrainService.CreateSunbeams()
	local beamPositions = {
		{-30, 15}, {10, -25}, {40, 30}, {-50, -10},
		{20, 50}, {-15, 40}, {55, -20}, {-40, 35}
	}
	for i, pos in ipairs(beamPositions) do
		local beam = Instance.new("Part")
		beam.Name = "Sunbeam_" .. i
		beam.Shape = Enum.PartType.Cylinder
		beam.Size = Vector3.new(55, 3, 3)
		beam.Anchored = true
		beam.CanCollide = false
		beam.CastShadow = false
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.new(0.85, 0.92, 1)
		beam.Transparency = 0.82
		-- Slant downward at slight angle
		beam.CFrame = CFrame.new(pos[1], 28, pos[2])
			* CFrame.Angles(0, 0, math.rad(80 + math.random(-5, 5)))
		beam.Parent = TerrainService.State.TerrainFolder
		
		-- Pulsing animation
		task.spawn(function()
			while beam and beam.Parent do
				local t = tick()
				beam.Transparency = 0.78 + math.sin(t * 1.5 + i) * 0.08
				task.wait(0.15)
			end
		end)
	end
end

-- Create hexagonal reef using Terrain FillCylinder for proper grounded hex pillars
function TerrainService.CreateHexagonalReef()
	local hexSize = 8
	local partsCreated = 0
	
	-- Use Roblox Terrain to fill the seafloor base with sand
	workspace.Terrain:FillBlock(
		CFrame.new(0, 0, 0),
		Vector3.new(220, 2, 220),
		Enum.Material.Sand
	)
	
	-- Hex grid: flat-top layout
	for q = -4, 4 do
		for r = -4, 4 do
			if math.random() > 0.2 then
				local wx = hexSize * 1.5 * q
				local wz = hexSize * math.sqrt(3) * (r + q / 2)
				
				-- Height: taller near center
				local dist = math.sqrt(wx^2 + wz^2)
				local h = math.max(2, math.floor(6 - dist * 0.08) + math.random(0, 3))
				
				-- Single visible cylinder - no wedge gaps
				TerrainService.PlaceHexPillar(wx, h, wz, hexSize)
				partsCreated += 1
				
				-- Coral on top
				if math.random() > 0.55 then
					TerrainService.PlaceCoral(wx, h, wz)
				end
			end
		end
	end
	
	-- A few rock pillars for visual variety
	for i = 1, 5 do
		local px = math.random(-60, 60)
		local pz = math.random(-60, 60)
		local ph = math.random(8, 16)
		workspace.Terrain:FillCylinder(
			CFrame.new(px, ph / 2, pz),
			ph, 4,
			Enum.Material.Basalt
		)
	end
	
	return partsCreated
end

-- Place one hex pillar using Terrain
function TerrainService.PlaceHexPillar(x, h, z, size)
	-- Use terrain cylinder for a clean hex look
	local mat = ({Enum.Material.Sand, Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Sandstone})[math.random(1,4)]
	workspace.Terrain:FillCylinder(
		CFrame.new(x, h / 2, z),
		h, size * 0.6,
		mat
	)
end

-- Place a coral decoration part at a position
function TerrainService.PlaceCoral(x, baseH, z)
	local coralColors = {
		Color3.fromRGB(255, 80, 60),
		Color3.fromRGB(255, 160, 30),
		Color3.fromRGB(255, 100, 200),
		Color3.fromRGB(80, 220, 180),
		Color3.fromRGB(255, 220, 50),
	}
	local numBranches = math.random(1, 3)
	for _ = 1, numBranches do
		local coral = Instance.new("Part")
		coral.Name = "Coral"
		local w = math.random(1, 2) * 0.5
		local ch = math.random(2, 5)
		coral.Size = Vector3.new(w, ch, w)
		coral.CFrame = CFrame.new(
			x + math.random(-3, 3),
			baseH + ch / 2,
			z + math.random(-3, 3)
		)
		coral.Anchored = true
		coral.CanCollide = false
		coral.CastShadow = false
		coral.Material = Enum.Material.Neon
		coral.Color = coralColors[math.random(1, #coralColors)]
		coral.Transparency = 0.1
		coral.Parent = TerrainService.State.TerrainFolder
	end
end


-- Add fish: simple anchored parts that move via CFrame each frame
function TerrainService.AddFish()
	local fishSpecs = {
		{color = Color3.fromRGB(255, 120, 20),  w=2,  h=1.2, l=4,  speed=4,  y=12},
		{color = Color3.fromRGB(40,  100, 255), w=2,  h=1.2, l=4,  speed=5,  y=18},
		{color = Color3.fromRGB(255, 220, 0),   w=1.5,h=0.9, l=3,  speed=3,  y=10},
		{color = Color3.fromRGB(80,  200, 80),  w=2.5,h=1.5, l=5,  speed=6,  y=22},
		{color = Color3.fromRGB(255, 80,  180), w=1.8,h=1.1, l=3.5,speed=4,  y=15},
		{color = Color3.fromRGB(255, 160, 60),  w=1.5,h=0.8, l=3,  speed=3.5,y=8 },
	}
	
	local fishCount = 0
	for _, spec in ipairs(fishSpecs) do
		local count = math.random(3, 6)
		for i = 1, count do
			-- Simple 2-part fish: body ellipse + tail wedge
			local model = Instance.new("Model")
			model.Name = "Fish"
			
			local body = Instance.new("Part")
			body.Name = "FishBody"
			body.Shape = Enum.PartType.Ball
			body.Size = Vector3.new(spec.w, spec.h, spec.l)
			body.Material = Enum.Material.SmoothPlastic
			body.Color = spec.color
			body.Anchored = true
			body.CanCollide = false
			body.CastShadow = false
			body.CFrame = CFrame.new(
				math.random(-70, 70),
				spec.y + math.random(-3, 3),
				math.random(-70, 70)
			)
			body.Parent = model
			
			local tail = Instance.new("WedgePart")
			tail.Name = "FishTail"
			tail.Size = Vector3.new(spec.w * 0.8, spec.h * 0.9, spec.l * 0.35)
			tail.Material = Enum.Material.SmoothPlastic
			tail.Color = spec.color
			tail.Anchored = true
			tail.CanCollide = false
			tail.CastShadow = false
			tail.CFrame = body.CFrame * CFrame.new(0, 0, spec.l * 0.65)
			tail.Parent = model
			
			model.Parent = TerrainService.State.TerrainFolder
			fishCount += 1
			
			-- Swim: move CFrame directly each tick
			local targetCF = body.CFrame
			local changeTimer = 0
			task.spawn(function()
				while model and model.Parent do
					local dt = task.wait(0.05)
					changeTimer += dt or 0.05
					
					-- Pick new target every 3-5 seconds
					if changeTimer > math.random(3, 5) then
						changeTimer = 0
						local tx = math.random(-70, 70)
						local ty = spec.y + math.random(-5, 5)
						local tz = math.random(-70, 70)
						local facing = (Vector3.new(tx, ty, tz) - body.Position)
						if facing.Magnitude > 0.1 then
							targetCF = CFrame.new(tx, math.clamp(ty, 4, 40), tz)
								* CFrame.fromMatrix(Vector3.new(), facing.Unit, Vector3.new(0,1,0))
						end
					end
					
					-- Lerp body towards target
					body.CFrame = body.CFrame:Lerp(targetCF, 0.03)
					-- Keep tail behind body
					tail.CFrame = body.CFrame * CFrame.new(0, 0, spec.l * 0.65)
				end
			end)
		end
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
