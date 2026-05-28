-- BattleSharks Voxel Data Structure
-- Represents individual voxels in the hexagonal terrain system

local VoxelData = {}
local VoxelTypes = require(script.Parent.VoxelTypes)

-- Voxel structure
VoxelData.Voxel = {}
VoxelData.Voxel.__index = VoxelData.Voxel

-- Create a new voxel
function VoxelData.Voxel.new(q, r, y, materialType)
	local self = setmetatable({}, VoxelData.Voxel)
	
	-- Position coordinates (axial + height)
	self.Q = q or 0  -- Axial Q coordinate
	self.R = r or 0  -- Axial R coordinate
	self.Y = y or 0  -- Height/vertical coordinate
	
	-- Material properties
	self.MaterialType = materialType or VoxelTypes.MaterialType.Air
	self.Properties = VoxelTypes.GetProperties(materialType)
	
	-- State flags
	self.IsModified = false
	self.IsVisible = true
	self.IsLoaded = false
	
	-- Additional data
	self.Health = self.Properties.Strength or 0
	self.Temperature = 20.0  -- Celsius
	self.LightLevel = 0.0
	self.Moisture = 0.0
	
	-- Timestamps for optimization
	self.LastModified = tick()
	self.LastAccessed = tick()
	
	return self
end

-- Voxel chunk structure (16x16x64 voxels per chunk)
VoxelData.Chunk = {}
VoxelData.Chunk.__index = VoxelData.Chunk

-- Chunk dimensions
VoxelData.CHUNK_SIZE_Q = 16
VoxelData.CHUNK_SIZE_R = 16
VoxelData.CHUNK_SIZE_Y = 64

-- Create a new chunk
function VoxelData.Chunk.new(chunkQ, chunkR)
	local self = setmetatable({}, VoxelData.Chunk)
	
	-- Chunk position (in chunk coordinates)
	self.ChunkQ = chunkQ or 0
	self.ChunkR = chunkR or 0
	
	-- Voxel data storage (3D array)
	self.Voxels = {}
	
	-- Chunk state
	self.IsGenerated = false
	self.IsModified = false
	self.IsLoaded = false
	self.IsDirty = false
	
	-- Optimization flags
	self.HasTransparentVoxels = false
	self.HasLiquidVoxels = false
	self.HasSolidVoxels = false
	
	-- Mesh data
	self.MeshData = nil
	self.NeedsMeshUpdate = true
	
	-- Performance tracking
	self.LastAccessed = tick()
	self.AccessCount = 0
	
	-- Initialize voxel array
	self:InitializeVoxels()
	
	return self
end

-- Initialize voxel array for the chunk
function VoxelData.Chunk:InitializeVoxels()
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		self.Voxels[q] = {}
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			self.Voxels[q][r] = {}
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				self.Voxels[q][r][y] = VoxelData.Voxel.new(q, r, y, VoxelTypes.MaterialType.Air)
			end
		end
	end
end

-- Get voxel at local coordinates within chunk
function VoxelData.Chunk:GetVoxel(localQ, localR, localY)
	if not self:IsValidLocalPosition(localQ, localR, localY) then
		return nil
	end
	
	local voxel = self.Voxels[localQ][localR][localY]
	if voxel then
		voxel.LastAccessed = tick()
		self.AccessCount = self.AccessCount + 1
	end
	
	return voxel
end

-- Set voxel at local coordinates within chunk
function VoxelData.Chunk:SetVoxel(localQ, localR, localY, materialType)
	if not self:IsValidLocalPosition(localQ, localR, localY) then
		return false
	end
	
	local voxel = self.Voxels[localQ][localR][localY]
	local oldMaterial = voxel.MaterialType
	
	-- Update voxel properties
	voxel.MaterialType = materialType
	voxel.Properties = VoxelTypes.GetProperties(materialType)
	voxel.Health = voxel.Properties.Strength or 0
	voxel.IsModified = true
	voxel.LastModified = tick()
	
	-- Update chunk state
	self.IsModified = true
	self.IsDirty = true
	self.NeedsMeshUpdate = true
	
	-- Update optimization flags
	self:UpdateOptimizationFlags(materialType, oldMaterial)
	
	return true
end

-- Check if local coordinates are valid within chunk
function VoxelData.Chunk:IsValidLocalPosition(localQ, localR, localY)
	return localQ >= 0 and localQ < VoxelData.CHUNK_SIZE_Q and
		   localR >= 0 and localR < VoxelData.CHUNK_SIZE_R and
		   localY >= 0 and localY < VoxelData.CHUNK_SIZE_Y
end

-- Convert world coordinates to chunk coordinates
function VoxelData.WorldToChunk(worldQ, worldR)
	local chunkQ = math.floor(worldQ / VoxelData.CHUNK_SIZE_Q)
	local chunkR = math.floor(worldR / VoxelData.CHUNK_SIZE_R)
	return chunkQ, chunkR
end

-- Convert world coordinates to local chunk coordinates
function VoxelData.WorldToLocal(worldQ, worldR, worldY)
	local localQ = worldQ % VoxelData.CHUNK_SIZE_Q
	local localR = worldR % VoxelData.CHUNK_SIZE_R
	local localY = worldY % VoxelData.CHUNK_SIZE_Y
	return localQ, localR, localY
end

-- Convert local chunk coordinates to world coordinates
function VoxelData.LocalToWorld(chunkQ, chunkR, localQ, localR, localY)
	local worldQ = chunkQ * VoxelData.CHUNK_SIZE_Q + localQ
	local worldR = chunkR * VoxelData.CHUNK_SIZE_R + localR
	local worldY = localY
	return worldQ, worldR, worldY
end

-- Update optimization flags when voxel changes
function VoxelData.Chunk:UpdateOptimizationFlags(newMaterial, oldMaterial)
	local newProps = VoxelTypes.GetProperties(newMaterial)
	local oldProps = VoxelTypes.GetProperties(oldMaterial)
	
	-- Update solid flag
	if newProps.IsSolid and not oldProps.IsSolid then
		self.HasSolidVoxels = true
	elseif not newProps.IsSolid and oldProps.IsSolid then
		-- Need to check if any other voxels are solid
		self:RecalculateSolidFlag()
	end
	
	-- Update liquid flag
	if newProps.IsLiquid and not oldProps.IsLiquid then
		self.HasLiquidVoxels = true
	elseif not newProps.IsLiquid and oldProps.IsLiquid then
		-- Need to check if any other voxels are liquid
		self:RecalculateLiquidFlag()
	end
	
	-- Update transparent flag
	if newProps.IsTransparent and not oldProps.IsTransparent then
		self.HasTransparentVoxels = true
	elseif not newProps.IsTransparent and oldProps.IsTransparent then
		-- Need to check if any other voxels are transparent
		self:RecalculateTransparentFlag()
	end
end

-- Recalculate solid flag (expensive operation)
function VoxelData.Chunk:RecalculateSolidFlag()
	self.HasSolidVoxels = false
	
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				local voxel = self.Voxels[q][r][y]
				if voxel.Properties.IsSolid then
					self.HasSolidVoxels = true
					return
				end
			end
		end
	end
end

-- Recalculate liquid flag (expensive operation)
function VoxelData.Chunk:RecalculateLiquidFlag()
	self.HasLiquidVoxels = false
	
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				local voxel = self.Voxels[q][r][y]
				if voxel.Properties.IsLiquid then
					self.HasLiquidVoxels = true
					return
				end
			end
		end
	end
end

-- Recalculate transparent flag (expensive operation)
function VoxelData.Chunk:RecalculateTransparentFlag()
	self.HasTransparentVoxels = false
	
	for q = 0, VoxelData.CHUNK_SIZE_Q - 1 do
		for r = 0, VoxelData.CHUNK_SIZE_R - 1 do
			for y = 0, VoxelData.CHUNK_SIZE_Y - 1 do
				local voxel = self.Voxels[q][r][y]
				if voxel.Properties.IsTransparent then
					self.HasTransparentVoxels = true
					return
				end
			end
		end
	end
end

-- Get chunk memory usage (approximate)
function VoxelData.Chunk:GetMemoryUsage()
	local voxelCount = VoxelData.CHUNK_SIZE_Q * VoxelData.CHUNK_SIZE_R * VoxelData.CHUNK_SIZE_Y
	local voxelSize = 64  -- Approximate bytes per voxel
	local meshDataSize = self.MeshData and #self.MeshData * 4 or 0
	
	return voxelCount * voxelSize + meshDataSize
end

-- Mark chunk as clean (no longer needs saving)
function VoxelData.Chunk:MarkClean()
	self.IsModified = false
	self.IsDirty = false
end

-- Mark chunk as dirty (needs saving and mesh update)
function VoxelData.Chunk:MarkDirty()
	self.IsModified = true
	self.IsDirty = true
	self.NeedsMeshUpdate = true
end

return VoxelData
