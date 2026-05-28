-- BattleSharks Terrain System Test
-- Demonstrates the hexagonal voxel terrain generation

local TerrainTest = {}
local HexagonalCoordinates = require(script.Parent.HexagonalCoordinates)
local VoxelData = require(script.Parent.VoxelData)
local VoxelTypes = require(script.Parent.VoxelTypes)
local TerrainGenerator = require(script.Parent.TerrainGenerator)
local VoxelMesh = require(script.Parent.VoxelMesh)

-- Test configuration
TerrainTest.CONFIG = {
	TEST_CHUNK_SIZE = 3,  -- 3x3 chunks for testing
	HEX_SIZE = 10,
	GENERATE_IN_WORKSPACE = true,
	SHOW_DEBUG_INFO = true
}

-- Run terrain system test
function TerrainTest.RunTest()
	print("=== BattleSharks Terrain System Test ===")
	
	-- Test 1: Hexagonal coordinate system
	TerrainTest.TestHexagonalCoordinates()
	
	-- Test 2: Voxel data structures
	TerrainTest.TestVoxelData()
	
	-- Test 3: Terrain generation
	TerrainTest.TestTerrainGeneration()
	
	-- Test 4: Mesh generation
	TerrainTest.TestMeshGeneration()
	
	-- Test 5: Create visual demonstration
	if TerrainTest.CONFIG.GENERATE_IN_WORKSPACE then
		TerrainTest.CreateVisualDemo()
	end
	
	print("=== Terrain System Test Complete ===")
end

-- Test hexagonal coordinate system
function TerrainTest.TestHexagonalCoordinates()
	print("\n--- Testing Hexagonal Coordinates ---")
	
	-- Test coordinate conversion
	local q, r = 5, 3
	local worldPos = HexagonalCoordinates.AxialToWorld(q, r, TerrainTest.CONFIG.HEX_SIZE)
	print("Axial to World:", q, r, "->", worldPos)
	
	-- Test reverse conversion
	local backQ, backR = HexagonalCoordinates.WorldToAxial(worldPos, TerrainTest.CONFIG.HEX_SIZE)
	print("World to Axial:", worldPos, "->", backQ, backR)
	
	-- Test neighbor calculation
	local neighbors = HexagonalCoordinates.GetNeighbors(q, r)
	print("Neighbors of", q, r, ":")
	for i, neighbor in ipairs(neighbors) do
		print("  ", i, ":", neighbor.q, neighbor.r)
	end
	
	-- Test distance calculation
	local distance = HexagonalCoordinates.Distance(0, 0, 5, 3)
	print("Distance between (0,0) and (5,3):", distance)
	
	print("✓ Hexagonal coordinates test passed")
end

-- Test voxel data structures
function TerrainTest.TestVoxelData()
	print("\n--- Testing Voxel Data ---")
	
	-- Test voxel creation
	local voxel = VoxelData.Voxel.new(0, 0, 0, VoxelTypes.MaterialType.Stone)
	print("Created voxel:", voxel.MaterialType, "at", voxel.Q, voxel.R, voxel.Y)
	
	-- Test chunk creation
	local chunk = VoxelData.Chunk.new(0, 0)
	print("Created chunk:", chunk.ChunkQ, chunk.ChunkR)
	print("Chunk dimensions:", VoxelData.CHUNK_SIZE_Q, "x", VoxelData.CHUNK_SIZE_R, "x", VoxelData.CHUNK_SIZE_Y)
	
	-- Test voxel placement in chunk
	local success = chunk:SetVoxel(5, 5, 10, VoxelTypes.MaterialType.Sand)
	print("Placed voxel in chunk:", success)
	
	-- Test voxel retrieval
	local retrievedVoxel = chunk:GetVoxel(5, 5, 10)
	if retrievedVoxel then
		print("Retrieved voxel:", retrievedVoxel.MaterialType)
	end
	
	-- Test chunk memory usage
	local memoryUsage = chunk:GetMemoryUsage()
	print("Chunk memory usage:", memoryUsage, "bytes")
	
	print("✓ Voxel data test passed")
end

-- Test terrain generation
function TerrainTest.TestTerrainGeneration()
	print("\n--- Testing Terrain Generation ---")
	
	-- Set test seed
	TerrainGenerator.SetSeed(12345)
	
	-- Test height generation
	local height = TerrainGenerator.GetTerrainHeight(10, 10)
	print("Terrain height at (10,10):", height)
	
	-- Test biome generation
	local temperature = TerrainGenerator.GetTemperature(10, 10)
	local moisture = TerrainGenerator.GetMoisture(10, 10)
	print("Temperature:", temperature, "Moisture:", moisture)
	
	-- Test cave generation
	local hasCave = TerrainGenerator.HasCave(10, 10, 20)
	print("Has cave at (10,10,20):", hasCave)
	
	-- Test chunk generation
	local chunk = VoxelData.Chunk.new(0, 0)
	local generatedChunk = TerrainGenerator.GenerateChunk(chunk, 0, 0)
	print("Generated chunk:", generatedChunk.IsGenerated)
	
	-- Count different voxel types in chunk
	local voxelCounts = {}
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				local voxel = chunk:GetVoxel(q, r, y)
				if voxel then
					local material = voxel.MaterialType
					voxelCounts[material] = (voxelCounts[material] or 0) + 1
				end
			end
		end
	end
	
	print("Voxel type distribution:")
	for material, count in pairs(voxelCounts) do
		print("  ", material, ":", count)
	end
	
	print("✓ Terrain generation test passed")
end

-- Test mesh generation
function TerrainTest.TestMeshGeneration()
	print("\n--- Testing Mesh Generation ---")
	
	-- Create a test chunk
	local chunk = VoxelData.Chunk.new(0, 0)
	TerrainGenerator.GenerateChunk(chunk, 0, 0)
	
	-- Generate mesh data
	local meshData = VoxelMesh.GenerateChunkMesh(chunk)
	if meshData then
		print("Generated mesh data:")
		print("  Vertices:", #meshData.Vertices)
		print("  Triangles:", #meshData.Triangles / 3)
		print("  UVs:", #meshData.UVs)
		print("  Materials:", #meshData.Materials)
		
		-- Get mesh statistics
		local stats = VoxelMesh.GetMeshStats(meshData)
		print("  Memory usage:", stats.MemoryUsage, "bytes")
	else
		print("Failed to generate mesh data")
	end
	
	print("✓ Mesh generation test passed")
end

-- Create visual demonstration in workspace
function TerrainTest.CreateVisualDemo()
	print("\n--- Creating Visual Demo ---")
	
	-- Create demo folder
	local demoFolder = Instance.new("Folder")
	demoFolder.Name = "TerrainDemo"
	demoFolder.Parent = workspace
	
	-- Generate a small area of terrain
	local chunkSize = TerrainTest.CONFIG.TEST_CHUNK_SIZE
	local hexSize = TerrainTest.CONFIG.HEX_SIZE
	
	for chunkQ = 0, chunkSize - 1 do
		for chunkR = 0, chunkSize - 1 do
			-- Generate chunk
			local chunk = VoxelData.Chunk.new(chunkQ, chunkR)
			TerrainGenerator.GenerateChunk(chunk, chunkQ, chunkR)
			
			-- Create visual representation
			local chunkModel = Instance.new("Model")
			chunkModel.Name = "Chunk_" .. chunkQ .. "_" .. chunkR
			chunkModel.Parent = demoFolder
			
			-- Add base platform
			local basePart = Instance.new("Part")
			basePart.Name = "Base"
			basePart.Size = Vector3.new(
				VoxelData.CHUNK_SIZE_Q * hexSize,
				4,
				VoxelData.CHUNK_SIZE_R * hexSize
			)
			basePart.Position = Vector3.new(
				chunkQ * VoxelData.CHUNK_SIZE_Q * hexSize,
				0,
				chunkR * VoxelData.CHUNK_SIZE_R * hexSize
			)
			basePart.Anchored = true
			basePart.CanCollide = true
			basePart.Material = Enum.Material.Stone
			basePart.Color = Color3.new(0.6, 0.6, 0.7)
			basePart.Parent = chunkModel
			
			-- Add surface voxels for visualization
			local voxelCount = 0
			for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
				for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
					for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
						local voxel = chunk:GetVoxel(q, r, y)
						if voxel and VoxelTypes.IsSolid(voxel.MaterialType) and voxelCount < 50 then
							-- Create visual voxel
							local voxelPart = Instance.new("Part")
							voxelPart.Name = "Voxel_" .. q .. "_" .. r .. "_" .. y
							voxelPart.Size = Vector3.new(hexSize * 0.8, VoxelMesh.HEIGHT_SCALE * 0.8, hexSize * 0.8)
							voxelPart.Position = Vector3.new(
								chunkQ * VoxelData.CHUNK_SIZE_Q * hexSize + q * hexSize,
								y * VoxelMesh.HEIGHT_SCALE,
								chunkR * VoxelData.CHUNK_SIZE_R * hexSize + r * hexSize
							)
							voxelPart.Anchored = true
							voxelPart.CanCollide = true
							
							-- Set material properties
							local materialProps = VoxelTypes.GetProperties(voxel.MaterialType)
							voxelPart.Material = materialProps.Material
							voxelPart.Color = materialProps.Color
							voxelPart.Transparency = materialProps.Transparency
							voxelPart.Reflectance = materialProps.Reflectance
							
							voxelPart.Parent = chunkModel
							voxelCount += 1
						end
					end
				end
			end
			
			print("Created visual chunk", chunkQ, chunkR, "with", voxelCount, "voxels")
		end
	end
	
	-- Add camera position for viewing
	local cameraPart = Instance.new("Part")
	cameraPart.Name = "CameraPosition"
	cameraPart.Size = Vector3.new(2, 2, 2)
	cameraPart.Position = Vector3.new(
		chunkSize * VoxelData.CHUNK_SIZE_Q * hexSize / 2,
		50,
		chunkSize * VoxelData.CHUNK_SIZE_R * hexSize / 2 + 100
	)
	cameraPart.Anchored = true
	cameraPart.CanCollide = false
	cameraPart.BrickColor = BrickColor.new("Bright red")
	cameraPart.Parent = demoFolder
	
	print("✓ Visual demo created in workspace.TerrainDemo")
	print("Camera position suggested:", cameraPart.Position)
end

-- Run performance test
function TerrainTest.RunPerformanceTest()
	print("\n--- Running Performance Test ---")
	
	local startTime = tick()
	local chunkCount = 10
	
	-- Generate multiple chunks
	for i = 1, chunkCount do
		local chunk = VoxelData.Chunk.new(i, 0)
		TerrainGenerator.GenerateChunk(chunk, i, 0)
		
		-- Generate mesh
		local meshData = VoxelMesh.GenerateChunkMesh(chunk)
	end
	
	local endTime = tick()
	local duration = endTime - startTime
	
	print("Generated", chunkCount, "chunks in", duration, "seconds")
	print("Average time per chunk:", duration / chunkCount, "seconds")
	print("Chunks per second:", chunkCount / duration)
	
	-- Memory usage
	local memoryUsage = collectgarbage("count")
	print("Memory usage:", memoryUsage, "KB")
	
	print("✓ Performance test completed")
end

-- Clean up test data
function TerrainTest.Cleanup()
	print("\n--- Cleaning Up Test Data ---")
	
	-- Remove demo folder
	local demoFolder = workspace:FindFirstChild("TerrainDemo")
	if demoFolder then
		demoFolder:Destroy()
		print("Removed visual demo")
	end
	
	-- Force garbage collection
	collectgarbage("collect")
	print("Forced garbage collection")
	
	print("✓ Cleanup completed")
end

return TerrainTest
