-- BattleSharks Terrain Manager
-- Main coordinator for the hexagonal voxel terrain system

local TerrainManager = {}
local HexagonalCoordinates = require(script.Parent.HexagonalCoordinates)
local VoxelData = require(script.Parent.VoxelData)
local VoxelTypes = require(script.Parent.VoxelTypes)
local TerrainGenerator = require(script.Parent.TerrainGenerator)
local VoxelMesh = require(script.Parent.VoxelMesh)

-- Terrain configuration
TerrainManager.CONFIG = {
	CHUNK_LOAD_RADIUS = 3,  -- Number of chunks to load around players
	CHUNK_UNLOAD_RADIUS = 5,  -- Number of chunks to keep loaded
	MAX_LOADED_CHUNKS = 100,  -- Maximum chunks to keep in memory
	AUTO_SAVE_INTERVAL = 300,  -- Auto-save every 5 minutes
	ENABLE_MESH_OPTIMIZATION = true,
	ENABLE_TERRAIN_STREAMING = true
}

-- Terrain state
TerrainManager.State = {
	LoadedChunks = {},
	ChunkMeshes = {},
	PlayerPositions = {},
	TerrainSeed = math.random(1, 1000000),
	IsInitialized = false,
	LastAutoSave = tick(),
	ChunkGenerationQueue = {},
	ChunkMeshUpdateQueue = {}
}

-- Initialize terrain system
function TerrainManager.Initialize(seed)
	if TerrainManager.State.IsInitialized then
		return false
	end
	
	-- Set terrain generation seed
	TerrainGenerator.SetSeed(seed or TerrainManager.State.TerrainSeed)
	
	-- Start auto-save timer
	TerrainManager.StartAutoSaveTimer()
	
	-- Initialize chunk queues
	TerrainManager.State.ChunkGenerationQueue = {}
	TerrainManager.State.ChunkMeshUpdateQueue = {}
	
	TerrainManager.State.IsInitialized = true
	print("Terrain Manager initialized with seed:", TerrainManager.State.TerrainSeed)
	
	return true
end

-- Get or create a chunk
function TerrainManager.GetChunk(chunkQ, chunkR)
	local chunkKey = TerrainManager.GetChunkKey(chunkQ, chunkR)
	
	-- Check if chunk is already loaded
	if TerrainManager.State.LoadedChunks[chunkKey] then
		return TerrainManager.State.LoadedChunks[chunkKey]
	end
	
	-- Create new chunk
	local chunk = VoxelData.Chunk.new(chunkQ, chunkR)
	TerrainManager.State.LoadedChunks[chunkKey] = chunk
	
	-- Add to generation queue
	table.insert(TerrainManager.State.ChunkGenerationQueue, {chunkQ, chunkR})
	
	return chunk
end

-- Generate terrain for a chunk
function TerrainManager.GenerateChunk(chunkQ, chunkR)
	local chunk = TerrainManager.GetChunk(chunkQ, chunkR)
	
	if not chunk.IsGenerated then
		TerrainGenerator.GenerateChunk(chunk, chunkQ, chunkR)
		
		-- Add to mesh update queue
		table.insert(TerrainManager.State.ChunkMeshUpdateQueue, {chunkQ, chunkR})
	end
	
	return chunk
end

-- Update chunk mesh
function TerrainManager.UpdateChunkMesh(chunkQ, chunkR)
	local chunk = TerrainManager.GetChunk(chunkQ, chunkR)
	
	if chunk.NeedsMeshUpdate then
		local meshData = VoxelMesh.UpdateChunkMesh(chunk)
		
		if meshData then
			local chunkKey = TerrainManager.GetChunkKey(chunkQ, chunkR)
			TerrainManager.State.ChunkMeshes[chunkKey] = meshData
		end
	end
	
	return chunk.MeshData
end

-- Process chunk generation queue
function TerrainManager.ProcessChunkQueue(maxChunks)
	maxChunks = maxChunks or 5
	
	local processed = 0
	
	while #TerrainManager.State.ChunkGenerationQueue > 0 and processed < maxChunks do
		local chunkPos = table.remove(TerrainManager.State.ChunkGenerationQueue, 1)
		local chunkQ, chunkR = chunkPos[1], chunkPos[2]
		
		TerrainManager.GenerateChunk(chunkQ, chunkR)
		processed += 1
	end
	
	return processed
end

-- Process mesh update queue
function TerrainManager.ProcessMeshQueue(maxMeshes)
	maxMeshes = maxMeshes or 3
	
	local processed = 0
	
	while #TerrainManager.State.ChunkMeshUpdateQueue > 0 and processed < maxMeshes do
		local chunkPos = table.remove(TerrainManager.State.ChunkMeshUpdateQueue, 1)
		local chunkQ, chunkR = chunkPos[1], chunkPos[2]
		
		TerrainManager.UpdateChunkMesh(chunkQ, chunkR)
		processed += 1
	end
	
	return processed
end

-- Update terrain around player positions
function TerrainManager.UpdateTerrainAroundPlayers(playerPositions)
	TerrainManager.State.PlayerPositions = playerPositions
	
	local chunksToLoad = {}
	local chunksToUnload = {}
	
	-- Find chunks to load
	for _, playerPos in ipairs(playerPositions) do
		local playerChunkQ, playerChunkR = HexagonalCoordinates.WorldToAxial(
			playerPos.X / VoxelMesh.HEX_SIZE,
			playerPos.Z / VoxelMesh.HEX_SIZE
		)
		
		-- Check surrounding chunks
		for dq = -TerrainManager.CONFIG.CHUNK_LOAD_RADIUS, TerrainManager.CONFIG.CHUNK_LOAD_RADIUS do
			for dr = -TerrainManager.CONFIG.CHUNK_LOAD_RADIUS, TerrainManager.CONFIG.CHUNK_LOAD_RADIUS do
				local distance = math.sqrt(dq*dq + dr*dr)
				if distance <= TerrainManager.CONFIG.CHUNK_LOAD_RADIUS then
					local chunkQ = playerChunkQ + dq
					local chunkR = playerChunkR + dr
					local chunkKey = TerrainManager.GetChunkKey(chunkQ, chunkR)
					
					if not TerrainManager.State.LoadedChunks[chunkKey] then
						chunksToLoad[chunkKey] = {chunkQ, chunkR}
					end
				end
			end
		end
	end
	
	-- Find chunks to unload
	for chunkKey, chunk in pairs(TerrainManager.State.LoadedChunks) do
		local shouldUnload = true
		
		for _, playerPos in ipairs(playerPositions) do
			local playerChunkQ, playerChunkR = HexagonalCoordinates.WorldToAxial(
				playerPos.X / VoxelMesh.HEX_SIZE,
				playerPos.Z / VoxelMesh.HEX_SIZE
			)
			
			local distance = HexagonalCoordinates.Distance(
				chunk.ChunkQ, chunk.ChunkR,
				playerChunkQ, playerChunkR
			)
			
			if distance <= TerrainManager.CONFIG.CHUNK_UNLOAD_RADIUS then
				shouldUnload = false
				break
			end
		end
		
		if shouldUnload then
			chunksToUnload[chunkKey] = chunk
		end
	end
	
	-- Load new chunks
	for chunkKey, chunkPos in pairs(chunksToLoad) do
		TerrainManager.GetChunk(chunkPos[1], chunkPos[2])
	end
	
	-- Unload distant chunks
	for chunkKey, chunk in pairs(chunksToUnload) do
		TerrainManager.UnloadChunk(chunk.ChunkQ, chunk.ChunkR)
	end
	
	return #chunksToLoad, #chunksToUnload
end

-- Unload a chunk
function TerrainManager.UnloadChunk(chunkQ, chunkR)
	local chunkKey = TerrainManager.GetChunkKey(chunkQ, chunkR)
	
	-- Save chunk if modified
	local chunk = TerrainManager.State.LoadedChunks[chunkKey]
	if chunk and chunk.IsModified then
		TerrainManager.SaveChunk(chunkQ, chunkR)
	end
	
	-- Remove from loaded chunks
	TerrainManager.State.LoadedChunks[chunkKey] = nil
	TerrainManager.State.ChunkMeshes[chunkKey] = nil
	
	print("Unloaded chunk:", chunkQ, chunkR)
end

-- Get voxel at world position
function TerrainManager.GetVoxel(worldPos)
	local worldQ, worldR = HexagonalCoordinates.WorldToAxial(worldPos, VoxelMesh.HEX_SIZE)
	local worldY = math.floor(worldPos.Y / VoxelMesh.HEIGHT_SCALE)
	
	local chunkQ, chunkR = VoxelData.WorldToChunk(worldQ, worldR)
	local localQ, localR, localY = VoxelData.WorldToLocal(worldQ, worldR, worldY)
	
	local chunk = TerrainManager.GetChunk(chunkQ, chunkR)
	if chunk and chunk.IsGenerated then
		return chunk:GetVoxel(localQ, localR, localY)
	end
	
	return nil
end

-- Set voxel at world position
function TerrainManager.SetVoxel(worldPos, materialType)
	local worldQ, worldR = HexagonalCoordinates.WorldToAxial(worldPos, VoxelMesh.HEX_SIZE)
	local worldY = math.floor(worldPos.Y / VoxelMesh.HEIGHT_SCALE)
	
	local chunkQ, chunkR = VoxelData.WorldToChunk(worldQ, worldR)
	local localQ, localR, localY = VoxelData.WorldToLocal(worldQ, worldR, worldY)
	
	local chunk = TerrainManager.GetChunk(chunkQ, chunkR)
	if chunk and chunk.IsGenerated then
		local success = chunk:SetVoxel(localQ, localR, localY, materialType)
		
		if success then
			-- Add to mesh update queue
			table.insert(TerrainManager.State.ChunkMeshUpdateQueue, {chunkQ, chunkR})
		end
		
		return success
	end
	
	return false
end

-- Get chunk key for storage
function TerrainManager.GetChunkKey(chunkQ, chunkR)
	return chunkQ .. "_" .. chunkR
end

-- Parse chunk key
function TerrainManager.ParseChunkKey(chunkKey)
	local q, r = chunkKey:match("(-?%d+)_(-?%d+)")
	return tonumber(q), tonumber(r)
end

-- Save chunk to storage
function TerrainManager.SaveChunk(chunkQ, chunkR)
	-- Placeholder for chunk saving
	-- In production, this would save to DataStore or file system
	local chunkKey = TerrainManager.GetChunkKey(chunkQ, chunkR)
	print("Saving chunk:", chunkKey)
end

-- Load chunk from storage
function TerrainManager.LoadChunk(chunkQ, chunkR)
	-- Placeholder for chunk loading
	-- In production, this would load from DataStore or file system
	local chunkKey = TerrainManager.GetChunkKey(chunkQ, chunkR)
	print("Loading chunk:", chunkKey)
	return nil
end

-- Start auto-save timer
function TerrainManager.StartAutoSaveTimer()
	task.spawn(function()
		while true do
			task.wait(TerrainManager.CONFIG.AUTO_SAVE_INTERVAL)
			TerrainManager.AutoSaveModifiedChunks()
		end
	end)
end

-- Auto-save all modified chunks
function TerrainManager.AutoSaveModifiedChunks()
	local savedCount = 0
	
	for chunkKey, chunk in pairs(TerrainManager.State.LoadedChunks) do
		if chunk.IsModified then
			local chunkQ, chunkR = TerrainManager.ParseChunkKey(chunkKey)
			TerrainManager.SaveChunk(chunkQ, chunkR)
			chunk:MarkClean()
			savedCount += 1
		end
	end
	
	TerrainManager.State.LastAutoSave = tick()
	
	if savedCount > 0 then
		print("Auto-saved", savedCount, "modified chunks")
	end
end

-- Get terrain statistics
function TerrainManager.GetTerrainStats()
	local loadedChunks = 0
	local generatedChunks = 0
	local modifiedChunks = 0
	local totalMemory = 0
	
	for chunkKey, chunk in pairs(TerrainManager.State.LoadedChunks) do
		loadedChunks += 1
		if chunk.IsGenerated then
			generatedChunks += 1
		end
		if chunk.IsModified then
			modifiedChunks += 1
		end
		totalMemory += chunk:GetMemoryUsage()
	end
	
	return {
		LoadedChunks = loadedChunks,
		GeneratedChunks = generatedChunks,
		ModifiedChunks = modifiedChunks,
		TotalMemory = totalMemory,
		QueueSize = #TerrainManager.State.ChunkGenerationQueue,
		MeshQueueSize = #TerrainManager.State.ChunkMeshUpdateQueue,
		PlayerCount = #TerrainManager.State.PlayerPositions
	}
end

-- Cleanup terrain system
function TerrainManager.Cleanup()
	-- Save all modified chunks
	TerrainManager.AutoSaveModifiedChunks()
	
	-- Clear all loaded chunks
	TerrainManager.State.LoadedChunks = {}
	TerrainManager.State.ChunkMeshes = {}
	TerrainManager.State.PlayerPositions = {}
	TerrainManager.State.ChunkGenerationQueue = {}
	TerrainManager.State.ChunkMeshUpdateQueue = {}
	
	TerrainManager.State.IsInitialized = false
	print("Terrain Manager cleaned up")
end

-- Set terrain configuration
function TerrainManager.SetConfig(config)
	for key, value in pairs(config) do
		if TerrainManager.CONFIG[key] ~= nil then
			TerrainManager.CONFIG[key] = value
		end
	end
end

-- Get terrain configuration
function TerrainManager.GetConfig()
	return TerrainManager.CONFIG
end

-- Get terrain state
function TerrainManager.GetState()
	return TerrainManager.State
end

return TerrainManager
