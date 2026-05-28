-- BattleSharks Client Terrain Renderer
-- Renders hexagonal voxel terrain on the client

local TerrainRenderer = {}

-- Renderer configuration
TerrainRenderer.CONFIG = {
	ENABLE_TERRAIN_RENDERING = true,
	RENDER_DISTANCE = 3,  -- Chunks to render
	LOD_LEVELS = 4,  -- Levels of detail
	MESH_UPDATE_RATE = 30,  -- FPS
	ENABLE_FRUSTUM_CULLING = true,
	ENABLE_OCCLUSION = true,
	MAX_RENDERED_CHUNKS = 50
}

-- Renderer state
TerrainRenderer.State = {
	IsInitialized = false,
	RenderedChunks = {},
	ChunkModels = {},
	Camera = nil,
	Player = nil,
	LastPosition = Vector3.new(0, 0, 0),
	LastUpdateTime = 0,
	TotalChunksRendered = 0,
	FrameTime = 0,
	RenderQueue = {}
}

-- Initialize terrain renderer
function TerrainRenderer.Initialize()
	if TerrainRenderer.State.IsInitialized then
		return false
	end
	
	-- Get camera and player references
	TerrainRenderer.State.Camera = workspace.CurrentCamera
	TerrainRenderer.State.Player = game.Players.LocalPlayer
	
	-- Create terrain folder
	local terrainFolder = Instance.new("Folder")
	terrainFolder.Name = "ClientTerrain"
	terrainFolder.Parent = workspace
	
	-- Start render loop
	TerrainRenderer.StartRenderLoop()
	
	TerrainRenderer.State.IsInitialized = true
	print("Terrain Renderer initialized")
	
	return true
end

-- Handle terrain sync from server
function TerrainRenderer.HandleTerrainSync(chunks)
	for _, chunkData in ipairs(chunks) do
		local chunkKey = chunkData.ChunkQ .. "_" .. chunkData.ChunkR
		
		-- Store chunk data
		TerrainRenderer.State.RenderedChunks[chunkKey] = chunkData
		
		-- Add to render queue
		table.insert(TerrainRenderer.State.RenderQueue, chunkKey)
	end
end

-- Handle voxel update
function TerrainRenderer.HandleVoxelUpdate(position, materialType, playerId)
	-- Create visual effect for voxel modification
	local effect = Instance.new("Part")
	effect.Name = "VoxelEffect"
	effect.Position = position
	effect.Size = Vector3.new(2, 2, 2)
	effect.Material = Enum.Material.Neon
	effect.CanCollide = false
	effect.Anchored = true
	
	-- Set color based on material type
	effect.Color = Color3.new(0.3, 0.8, 1.0) -- Cyan for water/ice
	
	-- Add to workspace
	effect.Parent = workspace
	
	-- Animate and remove
	local tween = game:GetService("TweenService"):Create(
		effect,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(4, 4, 4), Transparency = 1}
	)
	
	tween:Play()
	tween.Completed:Connect(function()
		effect:Destroy()
	end)
end

-- Render chunk mesh
function TerrainRenderer.RenderChunk(chunkKey)
	local chunkData = TerrainRenderer.State.RenderedChunks[chunkKey]
	if not chunkData then
		return false
	end
	
	-- Remove existing model
	local existingModel = TerrainRenderer.State.ChunkModels[chunkKey]
	if existingModel then
		existingModel:Destroy()
	end
	
	-- Create new model
	local model = Instance.new("Model")
	model.Name = "Chunk_" .. chunkKey
	
	-- Create terrain parts from chunk data
	local basePart = Instance.new("Part")
	basePart.Name = "TerrainBase"
	basePart.Size = Vector3.new(160, 32, 160)
	basePart.Position = Vector3.new(
		chunkData.ChunkQ * 160,
		0,
		chunkData.ChunkR * 160
	)
	basePart.Anchored = true
	basePart.CanCollide = true
	basePart.Material = Enum.Material.Stone
	basePart.Color = Color3.new(0.6, 0.6, 0.7)
	
	-- Add surface details
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = basePart
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0.5, 0.7, 0.3)
	frame.Parent = surfaceGui
	
	-- Add to model
	basePart.Parent = model
	
	-- Add decorative elements (simplified hexagonal representation)
	for i = 1, 5 do
		local hexPart = Instance.new("Part")
		hexPart.Name = "Hex_" .. i
		hexPart.Size = Vector3.new(8, 2, 8)
		hexPart.Position = Vector3.new(
			basePart.Position.X + (math.random(-60, 60)),
			basePart.Position.Y + math.random(5, 15),
			basePart.Position.Z + (math.random(-60, 60))
		)
		hexPart.Anchored = true
		hexPart.CanCollide = true
		hexPart.Material = Enum.Material.Sand
		hexPart.Color = Color3.new(0.9, 0.8, 0.6)
		hexPart.Parent = model
	end
	
	-- Add to workspace
	model.Parent = workspace.ClientTerrain
	
	-- Store reference
	TerrainRenderer.State.ChunkModels[chunkKey] = model
	TerrainRenderer.State.TotalChunksRendered += 1
	
	return true
end

-- Update rendered chunks based on camera position
function TerrainRenderer.UpdateRenderedChunks()
	local cameraPos = TerrainRenderer.State.Camera.CFrame.Position
	
	-- Check if camera moved significantly
	local movement = (cameraPos - TerrainRenderer.State.LastPosition).Magnitude
	if movement < 10 then  -- Don't update if camera didn't move much
		return
	end
	
	TerrainRenderer.State.LastPosition = cameraPos
	
	-- Process render queue
	local processed = 0
	local maxProcess = 3  -- Limit chunks processed per frame
	
	while #TerrainRenderer.State.RenderQueue > 0 and processed < maxProcess do
		local chunkKey = table.remove(TerrainRenderer.State.RenderQueue, 1)
		TerrainRenderer.RenderChunk(chunkKey)
		processed += 1
	end
end

-- Send position update to server
function TerrainRenderer.SendPositionUpdate()
	if not TerrainRenderer.State.Player or not TerrainRenderer.State.Player.Character then
		return
	end
	
	local character = TerrainRenderer.State.Player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	
	if rootPart then
		-- Position update would be sent to server here
		-- For now, just update local state
	end
end

-- Start render loop
function TerrainRenderer.StartRenderLoop()
	task.spawn(function()
		while true do
			local startTime = tick()
			
			-- Update rendered chunks
			TerrainRenderer.UpdateRenderedChunks()
			
			-- Send position update to server
			TerrainRenderer.SendPositionUpdate()
			
			-- Update performance stats
			local endTime = tick()
			TerrainRenderer.State.FrameTime = endTime - startTime
			TerrainRenderer.State.LastUpdateTime = endTime
			
			-- Wait for next frame
			game:GetService("RunService").Heartbeat:Wait()
		end
	end)
end

-- Get renderer statistics
function TerrainRenderer.GetStats()
	local renderedCount = 0
	local vertexCount = 0
	
	for _, model in pairs(TerrainRenderer.State.ChunkModels) do
		renderedCount += 1
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				vertexCount += 8  -- Approximate vertices per part
			end
		end
	end
	
	return {
		IsInitialized = TerrainRenderer.State.IsInitialized,
		RenderedChunks = renderedCount,
		TotalChunksRendered = TerrainRenderer.State.TotalChunksRendered,
		VertexCount = vertexCount,
		FrameTime = TerrainRenderer.State.FrameTime,
		QueueSize = #TerrainRenderer.State.RenderQueue,
		CameraPosition = TerrainRenderer.State.Camera and TerrainRenderer.State.Camera.CFrame.Position or Vector3.new(0, 0, 0)
	}
end

-- Cleanup terrain renderer
function TerrainRenderer.Cleanup()
	-- Destroy all rendered chunks
	for _, model in pairs(TerrainRenderer.State.ChunkModels) do
		model:Destroy()
	end
	
	-- Clear state
	TerrainRenderer.State.RenderedChunks = {}
	TerrainRenderer.State.ChunkModels = {}
	TerrainRenderer.State.RenderQueue = {}
	
	TerrainRenderer.State.IsInitialized = false
	print("Terrain Renderer cleaned up")
end

return TerrainRenderer
