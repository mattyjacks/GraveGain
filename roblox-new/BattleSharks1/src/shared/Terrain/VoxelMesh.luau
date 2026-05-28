-- BattleSharks Voxel Mesh Generator
-- Converts voxel data into renderable 3D meshes

local VoxelMesh = {}
local HexagonalCoordinates = require(script.Parent.HexagonalCoordinates)
local VoxelData = require(script.Parent.VoxelData)
local VoxelTypes = require(script.Parent.VoxelTypes)

-- Mesh generation parameters
VoxelMesh.HEX_SIZE = 10  -- Size of each hexagonal face
VoxelMesh.HEIGHT_SCALE = 2  -- Height of each voxel layer

-- Face directions for hexagonal voxels
VoxelMesh.FACE_DIRECTIONS = {
	{0, 1, 0},   -- Top
	{0, -1, 0},  -- Bottom
	{1, 0, 0},   -- East
	{-1, 0, 0},  -- West
	{0.5, 0, 0.866},   -- Northeast
	{-0.5, 0, 0.866},  -- Northwest
	{0.5, 0, -0.866},  -- Southeast
	{-0.5, 0, -0.866}  -- Southwest
}

-- Generate hexagonal prism vertices
local function GenerateHexVertices(center, size, height)
	local vertices = {}
	
	-- Bottom hexagon
	for i = 0, 5 do
		local angle = 2 * math.pi / 6 * i
		local x = center.X + size * math.cos(angle)
		local z = center.Z + size * math.sin(angle)
		table.insert(vertices, Vector3.new(x, center.Y, z))
	end
	
	-- Top hexagon
	for i = 0, 5 do
		local angle = 2 * math.pi / 6 * i
		local x = center.X + size * math.cos(angle)
		local z = center.Z + size * math.sin(angle)
		table.insert(vertices, Vector3.new(x, center.Y + height, z))
	end
	
	return vertices
end

-- Generate hexagonal face triangles
local function GenerateHexFaceTriangles(vertices, faceType)
	local triangles = {}
	
	if faceType == "top" then
		-- Top face (triangles 6-11)
		triangles = {7, 8, 6, 8, 9, 6, 9, 10, 6, 10, 11, 6, 11, 12, 6, 12, 7, 6}
	elseif faceType == "bottom" then
		-- Bottom face (triangles 0-5)
		triangles = {1, 0, 2, 2, 0, 3, 3, 0, 4, 4, 0, 5, 5, 0, 6, 6, 0, 1}
	elseif faceType == "side" then
		-- Side faces (need specific implementation for hex sides)
		-- This is simplified - proper hex side generation is more complex
		triangles = {1, 2, 7, 2, 8, 7}  -- Example side face
	end
	
	return triangles
end

-- Generate UV coordinates for hexagonal faces
local function GenerateHexUVs(faceType)
	local uvs = {}
	
	if faceType == "top" or faceType == "bottom" then
		-- Hexagon UVs
		local hexUvs = {
			Vector2.new(0.5, 0),    -- Top
			Vector2.new(0.933, 0.25), -- Top-right
			Vector2.new(0.933, 0.75), -- Bottom-right
			Vector2.new(0.5, 1),    -- Bottom
			Vector2.new(0.067, 0.75), -- Bottom-left
			Vector2.new(0.067, 0.25)  -- Top-left
		}
		
		-- Add UVs for both top and bottom
		for i = 1, 6 do
			table.insert(uvs, hexUvs[i])
		end
		for i = 1, 6 do
			table.insert(uvs, hexUvs[i])
		end
	else
		-- Side face UVs (simplified)
		for i = 1, 8 do
			table.insert(uvs, Vector2.new((i-1) / 4, 0))
			table.insert(uvs, Vector2.new((i-1) / 4, 1))
		end
	end
	
	return uvs
end

-- Check if a voxel face should be rendered (not obscured by neighbors)
local function ShouldRenderFace(chunk, localQ, localR, localY, direction)
	-- Get neighboring voxel position
	local neighborQ = localQ + direction[1]
	local neighborR = localR + direction[2]
	local neighborY = localY + direction[3]
	
	-- Check if neighbor is within chunk bounds
	if chunk:IsValidLocalPosition(neighborQ, neighborR, neighborY) then
		local neighborVoxel = chunk:GetVoxel(neighborQ, neighborR, neighborY)
		if neighborVoxel and VoxelTypes.IsSolid(neighborVoxel.MaterialType) then
			return false  -- Face is obscured by solid neighbor
		end
	else
		-- Neighbor is outside chunk - check adjacent chunks (simplified)
		-- In production, you'd need to check neighboring chunks
	end
	
	return true  -- Face should be rendered
end

-- Generate mesh data for a single voxel
local function GenerateVoxelMesh(chunk, localQ, localR, localY)
	local voxel = chunk:GetVoxel(localQ, localR, localY)
	if not voxel or not VoxelTypes.IsSolid(voxel.MaterialType) then
		return nil
	end
	
	local meshData = {
		Vertices = {},
		Triangles = {},
		UVs = {},
		Colors = {},
		Materials = {}
	}
	
	-- Get voxel position in world space
	local worldQ = chunk.ChunkQ * VoxelData.CHUNK_SIZE_Q + localQ
	local worldR = chunk.ChunkR * VoxelData.CHUNK_SIZE_R + localR
	local worldY = localY * VoxelMesh.HEIGHT_SCALE
	
	local center = HexagonalCoordinates.AxialToWorld(worldQ, worldR, VoxelMesh.HEX_SIZE)
	center = Vector3.new(center.X, worldY, center.Z)
	
	-- Generate hexagonal prism vertices
	local vertices = GenerateHexVertices(center, VoxelMesh.HEX_SIZE, VoxelMesh.HEIGHT_SCALE)
	local baseVertexCount = #meshData.Vertices
	
	-- Add vertices
	for _, vertex in ipairs(vertices) do
		table.insert(meshData.Vertices, vertex)
	end
	
	-- Check each face and add triangles if visible
	local facesToRender = {}
	
	-- Top face
	if ShouldRenderFace(chunk, localQ, localR, localY, {0, 0, 1}) then
		table.insert(facesToRender, "top")
	end
	
	-- Bottom face
	if ShouldRenderFace(chunk, localQ, localR, localY, {0, 0, -1}) then
		table.insert(facesToRender, "bottom")
	end
	
	-- Side faces (simplified - hex has 6 sides)
	for i = 1, 6 do
		local angle = 2 * math.pi / 6 * (i - 1)
		local direction = {
			math.cos(angle),
			0,
			math.sin(angle)
		}
		
		if ShouldRenderFace(chunk, localQ, localR, localY, direction) then
			table.insert(facesToRender, "side_" .. i)
		end
	end
	
	-- Generate triangles for visible faces
	for _, faceType in ipairs(facesToRender) do
		local faceTriangles = GenerateHexFaceTriangles(vertices, faceType)
		for _, triangle in ipairs(faceTriangles) do
			table.insert(meshData.Triangles, baseVertexCount + triangle - 1)
		end
	end
	
	-- Generate UVs
	local uvs = GenerateHexUVs("mixed")
	for _, uv in ipairs(uvs) do
		table.insert(meshData.UVs, uv)
	end
	
	-- Add colors based on voxel type
	local color = VoxelTypes.GetColor(voxel.MaterialType, 0.1)  -- Add slight variation
	for i = 1, #vertices do
		table.insert(meshData.Colors, color)
	end
	
	-- Add material information
	table.insert(meshData.Materials, voxel.MaterialType)
	
	return meshData
end

-- Generate mesh data for an entire chunk
function VoxelMesh.GenerateChunkMesh(chunk)
	if not chunk or not chunk.IsGenerated then
		return nil
	end
	
	local chunkMeshData = {
		Vertices = {},
		Triangles = {},
		UVs = {},
		Colors = {},
		Materials = {},
		MaterialGroups = {}  -- Group triangles by material for optimization
	}
	
	-- Generate mesh for each voxel in chunk
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				local voxelMesh = GenerateVoxelMesh(chunk, q, r, y)
				if voxelMesh then
					-- Merge voxel mesh into chunk mesh
					local vertexOffset = #chunkMeshData.Vertices
					
					-- Add vertices
					for _, vertex in ipairs(voxelMesh.Vertices) do
						table.insert(chunkMeshData.Vertices, vertex)
					end
					
					-- Add triangles (with offset)
					for _, triangle in ipairs(voxelMesh.Triangles) do
						table.insert(chunkMeshData.Triangles, vertexOffset + triangle)
					end
					
					-- Add UVs
					for _, uv in ipairs(voxelMesh.UVs) do
						table.insert(chunkMeshData.UVs, uv)
					end
					
					-- Add colors
					for _, color in ipairs(voxelMesh.Colors) do
						table.insert(chunkMeshData.Colors, color)
					end
					
					-- Track material groups
					local material = voxelMesh.Materials[1]
					if not chunkMeshData.MaterialGroups[material] then
						chunkMeshData.MaterialGroups[material] = {
							StartIndex = #chunkMeshData.Triangles - #voxelMesh.Triangles + 1,
							TriangleCount = #voxelMesh.Triangles
						}
					else
						chunkMeshData.MaterialGroups[material].TriangleCount += #voxelMesh.Triangles
					end
				end
			end
		end
	end
	
	return chunkMeshData
end

-- Create Roblox mesh from mesh data
function VoxelMesh.CreateRobloxMesh(meshData, parent)
	if not meshData or #meshData.Vertices == 0 then
		return nil
	end
	
	-- Create wedge parts for each material group (simplified approach)
	local meshParts = {}
	
	for material, group in pairs(meshData.MaterialGroups) do
		local part = Instance.new("Part")
		part.Name = "VoxelMesh_" .. material
		part.Anchored = true
		part.CanCollide = true
		part.Size = Vector3.new(1, 1, 1)
		
		-- Set material properties
		local materialProps = VoxelTypes.GetProperties(material)
		part.Material = materialProps.Material
		part.Color = materialProps.Color
		part.Transparency = materialProps.Transparency
		part.Reflectance = materialProps.Reflectance
		
		-- Create mesh
		local mesh = Instance.new("Mesh")
		mesh.MeshType = Enum.MeshType.CustomMesh
		
		-- This is simplified - in production you'd use a proper mesh generation system
		-- For now, we'll create a basic representation
		mesh.Scale = Vector3.new(VoxelMesh.HEX_SIZE, VoxelMesh.HEIGHT_SCALE, VoxelMesh.HEX_SIZE)
		
		-- Parent mesh to part
		mesh.Parent = part
		
		-- Parent part to parent
		part.Parent = parent
		
		table.insert(meshParts, part)
	end
	
	return meshParts
end

-- Optimize mesh by combining adjacent faces of same material
function VoxelMesh.OptimizeMesh(meshData)
	-- This is a placeholder for mesh optimization
	-- In production, you'd implement greedy meshing or similar algorithms
	-- to combine adjacent faces into larger quads
	
	print("Mesh optimization not yet implemented - using basic mesh generation")
	return meshData
end

-- Calculate mesh statistics
function VoxelMesh.GetMeshStats(meshData)
	if not meshData then
		return nil
	end
	
	return {
		VertexCount = #meshData.Vertices,
		TriangleCount = #meshData.Triangles / 3,
		MaterialCount = 0,
		MemoryUsage = #meshData.Vertices * 12 + #meshData.Triangles * 4 + #meshData.UVs * 8
	}
end

-- Update chunk mesh (regenerate if needed)
function VoxelMesh.UpdateChunkMesh(chunk)
	if not chunk.NeedsMeshUpdate then
		return chunk.MeshData
	end
	
	-- Generate new mesh data
	local meshData = VoxelMesh.GenerateChunkMesh(chunk)
	
	-- Optimize mesh
	meshData = VoxelMesh.OptimizeMesh(meshData)
	
	-- Store mesh data
	chunk.MeshData = meshData
	chunk.NeedsMeshUpdate = false
	
	return meshData
end

-- Set mesh generation parameters
function VoxelMesh.SetParameters(params)
	if params.HEX_SIZE then VoxelMesh.HEX_SIZE = params.HEX_SIZE end
	if params.HEIGHT_SCALE then VoxelMesh.HEIGHT_SCALE = params.HEIGHT_SCALE end
end

-- Get mesh generation parameters
function VoxelMesh.GetParameters()
	return {
		HEX_SIZE = VoxelMesh.HEX_SIZE,
		HEIGHT_SCALE = VoxelMesh.HEIGHT_SCALE
	}
end

return VoxelMesh
