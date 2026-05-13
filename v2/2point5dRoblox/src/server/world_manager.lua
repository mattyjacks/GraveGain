-- world_manager.lua (SERVER)
-- Manages the dynamic open world chunks, biome mapping, and boundary fencing.
-- Loads/unloads chunks based on player positions to keep memory usage low.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))
local TerrainGenerator = require(script.Parent:WaitForChild("terrain_generator"))

local WorldManager = {}
WorldManager.__index = WorldManager

function WorldManager.new()
	local self = setmetatable({}, WorldManager)
	self.chunks = {} -- [x][z] = folder
	self.seed = GameData.WORLD_CONFIG.seed
	self.worldFolder = Instance.new("Folder")
	self.worldFolder.Name = "OpenWorld"
	self.worldFolder.Parent = workspace
	
	self:setupRemoteEvents()
	self:generateBoundaryFence()
	
	-- Pre-generate the center of the world (3x3 chunks) while players are in the lobby
	task.spawn(function()
		for x = -1, 1 do
			for z = -1, 1 do
				self:ensureChunk(x, z)
			end
		end
	end)
	
	return self
end

function WorldManager:setupRemoteEvents()
	local requestChunk = Instance.new("RemoteEvent")
	requestChunk.Name = "RequestChunk"
	requestChunk.Parent = ReplicatedStorage
	
	requestChunk.OnServerEvent:Connect(function(player, cx, cz)
		self:ensureChunk(cx, cz)
	end)
end

-- Biome calculation based on 2D noise
function WorldManager:getBiomeAt(cx, cz)
	local noiseScale = GameData.WORLD_CONFIG.biomeFrequency
	local n = math.noise(cx * noiseScale, cz * noiseScale, self.seed * 5)
	n = (n + 1) / 2 -- 0 to 1
	
	if n < 0.25 then return "Inferno"
	elseif n < 0.5 then return "Wasteland"
	elseif n < 0.75 then return "Forest"
	else return "CrystalPlains" end
end

function WorldManager:ensureChunk(cx, cz)
	-- Check radius
	local radius = GameData.WORLD_CONFIG.worldRadius
	if math.abs(cx) > radius or math.abs(cz) > radius then return end
	
	if not self.chunks[cx] then self.chunks[cx] = {} end
	if self.chunks[cx][cz] then return end -- Already exists
	
	local biomeName = self:getBiomeAt(cx, cz)
	local biomeData = GameData.BIOMES[biomeName]
	
	local chunkSize = GameData.WORLD_CONFIG.chunkSize
	local config = {
		Width = chunkSize / 8, -- TILE_SIZE is 8
		Length = chunkSize / 8,
		OriginX = cx * chunkSize,
		OriginZ = cz * chunkSize,
		Seed = self.seed,
		Biome = biomeName,
		Name = "Chunk_" .. cx .. "_" .. cz
	}
	
	local chunkFolder = TerrainGenerator.generate(self.worldFolder, config)
	self.chunks[cx][cz] = chunkFolder
	
	print("Generated Chunk [" .. cx .. "," .. cz .. "] Biome: " .. biomeName)
end

function WorldManager:generateBoundaryFence()
	local radius = GameData.WORLD_CONFIG.worldRadius
	local size = GameData.WORLD_CONFIG.chunkSize
	local bound = (radius + 0.5) * size
	local h = GameData.WORLD_CONFIG.fenceHeight
	
	local fenceFolder = Instance.new("Folder")
	fenceFolder.Name = "WorldBoundary"
	fenceFolder.Parent = self.worldFolder
	
	local function createWall(startPos, endPos)
		local dist = (endPos - startPos).Magnitude
		local wall = Instance.new("Part")
		wall.Name = "InvisibleWall"
		wall.Size = Vector3.new(2, 500, dist)
		wall.CFrame = CFrame.lookAt(startPos:Lerp(endPos, 0.5) + Vector3.new(0, 250, 0), endPos)
		wall.Transparency = 1
		wall.Anchored = true
		wall.Parent = fenceFolder
		
		-- Wooden fence visual
		local segments = math.floor(dist / 12)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		for i = 0, segments do
			local p = startPos:Lerp(endPos, i / segments)
			
			-- Find ground for each post
			local groundResult = workspace:Raycast(Vector3.new(p.X, 300, p.Z), Vector3.new(0, -400, 0), rayParams)
			local postGroundY = groundResult and groundResult.Position.Y or 20
			
			local post = Instance.new("Part")
			post.Size = Vector3.new(2, 20, 2)
			post.Color = Color3.fromRGB(100, 80, 60)
			post.Material = Enum.Material.Wood
			post.CFrame = CFrame.new(p.X, postGroundY + 8, p.Z)
			post.Anchored = true
			post.Parent = fenceFolder
			
			if i < segments then
				local nextP = startPos:Lerp(endPos, (i+1) / segments)
				local nextGroundResult = workspace:Raycast(Vector3.new(nextP.X, 300, nextP.Z), Vector3.new(0, -400, 0), rayParams)
				local nextGroundY = nextGroundResult and nextGroundResult.Position.Y or 20
				
				local rail = Instance.new("Part")
				rail.Size = Vector3.new(0.6, 1.5, (nextP - p).Magnitude + 1)
				rail.Color = Color3.fromRGB(120, 100, 80)
				rail.Material = Enum.Material.Wood
				rail.CFrame = CFrame.lookAt(
					Vector3.new(p.X, postGroundY + 14, p.Z):Lerp(Vector3.new(nextP.X, nextGroundY + 14, nextP.Z), 0.5),
					Vector3.new(nextP.X, nextGroundY + 14, nextP.Z)
				)
				rail.Anchored = true
				rail.Parent = fenceFolder
			end
		end
	end
	
	-- Square boundary
	createWall(Vector3.new(-bound, 0, -bound), Vector3.new(bound, 0, -bound))
	createWall(Vector3.new(bound, 0, -bound), Vector3.new(bound, 0, bound))
	createWall(Vector3.new(bound, 0, bound), Vector3.new(-bound, 0, bound))
	createWall(Vector3.new(-bound, 0, bound), Vector3.new(-bound, 0, -bound))
end

function WorldManager:update(playerPositions)
	-- unloading logic could be added here for optimization
end

return WorldManager
