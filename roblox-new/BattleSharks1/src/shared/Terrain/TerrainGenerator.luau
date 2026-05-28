-- BattleSharks Terrain Generator
-- Minecraft-inspired procedural terrain generation using Perlin noise

local TerrainGenerator = {}
local HexagonalCoordinates = require(script.Parent.HexagonalCoordinates)
local VoxelData = require(script.Parent.VoxelData)
local VoxelTypes = require(script.Parent.VoxelTypes)

-- Terrain generation parameters
TerrainGenerator.SEED = math.random(1, 1000000)
TerrainGenerator.SCALE = 0.02  -- Noise scale
TerrainGenerator.HEIGHT_SCALE = 32.0  -- Maximum terrain height
TerrainGenerator.WATER_LEVEL = 16  -- Water level height
TerrainGenerator.BEACH_LEVEL = 18  -- Beach starts here
TerrainGenerator.MOUNTAIN_LEVEL = 40  -- Mountains start here

-- Biome parameters
TerrainGenerator.BIOME_SCALE = 0.005  -- Biome noise scale
TerrainGenerator.TEMPERATURE_SCALE = 0.01  -- Temperature variation
TerrainGenerator.MOISTURE_SCALE = 0.01  -- Moisture variation

-- Cave generation parameters
TerrainGenerator.CAVE_SCALE = 0.05  -- Cave noise scale
TerrainGenerator.CAVE_THRESHOLD = 0.7  -- Cave density threshold
TerrainGenerator.CAVE_CHANCE = 0.3  -- Chance of caves at any given position

-- Ore generation parameters
TerrainGenerator.ORE_VEINS = {
	{
		Type = VoxelTypes.MaterialType.Crystal,
		MinHeight = 5,
		MaxHeight = 25,
		Chance = 0.02,
		VeinSize = 3,
		Scale = 0.1
	},
	{
		Type = VoxelTypes.MaterialType.Volcanic,
		MinHeight = 30,
		MaxHeight = 50,
		Chance = 0.01,
		VeinSize = 5,
		Scale = 0.08
	}
}

-- Simple Perlin noise implementation
local function PerlinNoise(x, y, z, seed)
	-- Simplified noise function for demonstration
	-- In production, use a proper Perlin noise library
	local n = math.sin(x * 12.9898 + y * 78.233 + z * 37.719 + seed * 43.758) * 43758.5453
	return (n - math.floor(n)) * 2 - 1
end

-- Improved Perlin noise with octaves
local function FractalNoise(x, y, z, octaves, persistence, scale, seed)
	local total = 0
	local amplitude = 1
	local frequency = scale
	local maxValue = 0
	
	for i = 1, octaves do
		total += PerlinNoise(x * frequency, y * frequency, z * frequency, seed + i) * amplitude
		maxValue += amplitude
		amplitude *= persistence
		frequency *= 2
	end
	
	return total / maxValue
end

-- Get biome type based on temperature and moisture
local function GetBiomeType(temperature, moisture)
	if temperature < 0.2 then
		if moisture < 0.3 then
			return "Ice"  -- Cold and dry
		else
			return "Arctic"  -- Cold and wet
		end
	elseif temperature < 0.6 then
		if moisture < 0.4 then
			return "Desert"  -- Warm and dry
		elseif moisture < 0.7 then
			return "Plains"  -- Moderate
		else
			return "Swamp"  -- Warm and wet
		end
	else
		if moisture < 0.5 then
			return "Savanna"  -- Hot and dry
		else
			return "Jungle"  -- Hot and wet
		end
	end
end

-- Get voxel material based on biome and height
local function GetVoxelMaterial(biome, height, depth)
	if height < TerrainGenerator.WATER_LEVEL then
		return VoxelTypes.MaterialType.Water
	elseif height < TerrainGenerator.BEACH_LEVEL then
		if depth < 2 then
			return VoxelTypes.MaterialType.Sand
		else
			return VoxelTypes.MaterialType.Gravel
		end
	elseif height < TerrainGenerator.MOUNTAIN_LEVEL then
		if depth < 1 then
			return VoxelTypes.MaterialType.Sand
		elseif depth < 3 then
			return VoxelTypes.MaterialType.Gravel
		else
			return VoxelTypes.MaterialType.Stone
		end
	else
		return VoxelTypes.MaterialType.Stone
	end
end

-- Generate terrain height for a given position
function TerrainGenerator.GetTerrainHeight(worldQ, worldR)
	-- Base terrain height using fractal noise
	local baseHeight = FractalNoise(
		worldQ * TerrainGenerator.SCALE,
		worldR * TerrainGenerator.SCALE,
		0,
		4,  -- octaves
		0.5,  -- persistence
		1.0,  -- scale
		TerrainGenerator.SEED
	)
	
	-- Add mountain ridges
	local mountainNoise = FractalNoise(
		worldQ * TerrainGenerator.SCALE * 0.5,
		worldR * TerrainGenerator.SCALE * 0.5,
		100,
		2,
		0.8,
		1.0,
		TerrainGenerator.SEED + 100
	)
	
	-- Combine noises
	local height = baseHeight + mountainNoise * 0.3
	
	-- Normalize and scale
	height = (height + 1) * 0.5  -- Normalize to 0-1
	height = height * TerrainGenerator.HEIGHT_SCALE
	
	return math.floor(height + 0.5)
end

-- Get temperature for a given position
function TerrainGenerator.GetTemperature(worldQ, worldR)
	local temp = FractalNoise(
		worldQ * TerrainGenerator.TEMPERATURE_SCALE,
		worldR * TerrainGenerator.TEMPERATURE_SCALE,
		200,
		2,
		0.5,
		1.0,
		TerrainGenerator.SEED + 200
	)
	
	return (temp + 1) * 0.5  -- Normalize to 0-1
end

-- Get moisture for a given position
function TerrainGenerator.GetMoisture(worldQ, worldR)
	local moisture = FractalNoise(
		worldQ * TerrainGenerator.MOISTURE_SCALE,
		worldR * TerrainGenerator.MOISTURE_SCALE,
		300,
		2,
		0.5,
		1.0,
		TerrainGenerator.SEED + 300
	)
	
	return (moisture + 1) * 0.5  -- Normalize to 0-1
end

-- Check if a position should have a cave
function TerrainGenerator.HasCave(worldQ, worldR, worldY)
	if math.random() > TerrainGenerator.CAVE_CHANCE then
		return false
	end
	
	local caveNoise = FractalNoise(
		worldQ * TerrainGenerator.CAVE_SCALE,
		worldR * TerrainGenerator.CAVE_SCALE,
		worldY * TerrainGenerator.CAVE_SCALE,
		3,
		0.6,
		1.0,
		TerrainGenerator.SEED + 400
	)
	
	return math.abs(caveNoise) > TerrainGenerator.CAVE_THRESHOLD
end

-- Generate ore veins
function TerrainGenerator.GenerateOres(chunk)
	for _, oreConfig in ipairs(TerrainGenerator.ORE_VEINS) do
		-- Generate multiple veins per chunk
		local veinCount = math.random(1, 3)
		
		for i = 1, veinCount do
			-- Random vein center
			local centerX = math.random(0, VoxelData.CHUNK_SIZE_Q - 1)
			local centerY = math.random(oreConfig.MinHeight, math.min(oreConfig.MaxHeight, VoxelData.CHUNK_SIZE_Y - 1))
			local centerZ = math.random(0, VoxelData.CHUNK_SIZE_R - 1)
			
			-- Generate vein
			local veinSize = math.random(1, oreConfig.VeinSize)
			
			for dq = -veinSize, veinSize do
				for dy = -veinSize, veinSize do
					for dr = -veinSize, veinSize do
						local distance = math.sqrt(dq*dq + dy*dy + dr*dr)
						if distance <= veinSize then
							local q = centerX + dq
							local y = centerY + dy
							local r = centerZ + dr
							
							if chunk:IsValidLocalPosition(q, y, r) then
								local oreNoise = FractalNoise(
									q * oreConfig.Scale,
									y * oreConfig.Scale,
									r * oreConfig.Scale,
									2,
									0.5,
									1.0,
									TerrainGenerator.SEED + 500
								)
								
								if oreNoise > 0.3 then
									chunk:SetVoxel(q, y, r, oreConfig.Type)
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Generate vegetation and decorations
function TerrainGenerator.GenerateVegetation(chunk, worldChunkQ, worldChunkR)
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			-- Convert to world coordinates
			local worldQ = worldChunkQ * VoxelData.CHUNK_SIZE_Q + q
			local worldR = worldChunkR * VoxelData.CHUNK_SIZE_R + r
			
			-- Get surface height
			local surfaceHeight = TerrainGenerator.GetTerrainHeight(worldQ, worldR)
			
			-- Check if surface is suitable for vegetation
			if surfaceHeight > TerrainGenerator.WATER_LEVEL and surfaceHeight < TerrainGenerator.MOUNTAIN_LEVEL then
				-- Generate vegetation based on biome
				local temperature = TerrainGenerator.GetTemperature(worldQ, worldR)
				local moisture = TerrainGenerator.GetMoisture(worldQ, worldR)
				local biome = GetBiomeType(temperature, moisture)
				
				-- Place vegetation
				if biome == "Swamp" or biome == "Jungle" then
					if math.random() < 0.1 then  -- 10% chance
						local y = surfaceHeight + 1
						if chunk:IsValidLocalPosition(q, y, r) then
							chunk:SetVoxel(q, y, r, VoxelTypes.MaterialType.Seaweed)
						end
					end
				elseif biome == "Arctic" and temperature < 0.3 then
					if math.random() < 0.05 then  -- 5% chance
						local y = surfaceHeight + 1
						if chunk:IsValidLocalPosition(q, y, r) then
							chunk:SetVoxel(q, y, r, VoxelTypes.MaterialType.Ice)
						end
					end
				end
			end
		end
	end
end

-- Main chunk generation function
function TerrainGenerator.GenerateChunk(chunk, worldChunkQ, worldChunkR)
	if chunk.IsGenerated then
		return chunk
	end
	
	-- Generate terrain for each voxel in the chunk
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			-- Convert to world coordinates
			local worldQ = worldChunkQ * VoxelData.CHUNK_SIZE_Q + q
			local worldR = worldChunkR * VoxelData.CHUNK_SIZE_R + r
			
			-- Get terrain height and biome
			local surfaceHeight = TerrainGenerator.GetTerrainHeight(worldQ, worldR)
			local temperature = TerrainGenerator.GetTemperature(worldQ, worldR)
			local moisture = TerrainGenerator.GetMoisture(worldQ, worldR)
			local biome = GetBiomeType(temperature, moisture)
			
			-- Fill voxels from bottom to surface
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				local worldY = y
				
				-- Check for caves
				if TerrainGenerator.HasCave(worldQ, worldR, worldY) then
					chunk:SetVoxel(q, y, r, VoxelTypes.MaterialType.Air)
				elseif worldY <= surfaceHeight then
					-- Calculate depth from surface
					local depth = surfaceHeight - worldY
					local material = GetVoxelMaterial(biome, surfaceHeight, depth)
					
					-- Apply biome-specific modifications
					if biome == "Ice" and worldY <= TerrainGenerator.WATER_LEVEL then
						material = VoxelTypes.MaterialType.Ice
					elseif biome == "Swamp" and depth < 5 then
						material = VoxelTypes.MaterialType.Mud
					end
					
					chunk:SetVoxel(q, y, r, material)
				else
					-- Above surface - air or water
					if worldY <= TerrainGenerator.WATER_LEVEL then
						chunk:SetVoxel(q, y, r, VoxelTypes.MaterialType.Water)
					else
						chunk:SetVoxel(q, y, r, VoxelTypes.MaterialType.Air)
					end
				end
			end
		end
	end
	
	-- Generate ores
	TerrainGenerator.GenerateOres(chunk)
	
	-- Generate vegetation and decorations
	TerrainGenerator.GenerateVegetation(chunk, worldChunkQ, worldChunkR)
	
	-- Mark chunk as generated
	chunk.IsGenerated = true
	chunk:MarkDirty()
	
	return chunk
end

-- Set terrain generation seed
function TerrainGenerator.SetSeed(seed)
	TerrainGenerator.SEED = seed
end

-- Get terrain generation parameters
function TerrainGenerator.GetParameters()
	return {
		Seed = TerrainGenerator.SEED,
		Scale = TerrainGenerator.SCALE,
		HeightScale = TerrainGenerator.HEIGHT_SCALE,
		WaterLevel = TerrainGenerator.WATER_LEVEL,
		BeachLevel = TerrainGenerator.BEACH_LEVEL,
		MountainLevel = TerrainGenerator.MOUNTAIN_LEVEL
	}
end

-- Set terrain generation parameters
function TerrainGenerator.SetParameters(params)
	if params.Seed then TerrainGenerator.SEED = params.Seed end
	if params.Scale then TerrainGenerator.SCALE = params.Scale end
	if params.HeightScale then TerrainGenerator.HEIGHT_SCALE = params.HeightScale end
	if params.WaterLevel then TerrainGenerator.WATER_LEVEL = params.WaterLevel end
	if params.BeachLevel then TerrainGenerator.BEACH_LEVEL = params.BeachLevel end
	if params.MountainLevel then TerrainGenerator.MOUNTAIN_LEVEL = params.MountainLevel end
end

return TerrainGenerator
