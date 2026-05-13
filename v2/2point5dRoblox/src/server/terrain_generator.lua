-- terrain_generator.lua  (SERVER)
-- Generates a 16-level stepped terrain with mountains, roads, rivers, and ponds.
-- Uses math.noise for heightmaps and biome distribution.

local TerrainGenerator = {}

local RNG = Random.new()
local TILE_SIZE = 8
local LEVELS = 16
local MAX_HEIGHT = 80  -- total height of 16 levels

-- ── Biome Colors ──────────────────────────────────────────────────────────

local PALETTE = {
	Water   = {Color3.fromRGB(30, 100, 200), Enum.Material.Glass},
	Sand    = {Color3.fromRGB(200, 180, 140), Enum.Material.Sand},
	Road    = {Color3.fromRGB(80, 75, 70), Enum.Material.Cobblestone},
	Grass   = {Color3.fromRGB(60, 120, 60), Enum.Material.Grass},
	Rock    = {Color3.fromRGB(100, 100, 110), Enum.Material.Rock},
	Snow    = {Color3.fromRGB(240, 245, 255), Enum.Material.Snow},
}

-- ── Generator ──────────────────────────────────────────────────────────────

function TerrainGenerator.generate(parent, config)
	local folder = Instance.new("Folder")
	folder.Name = config.Name or "GeneratedTerrain"
	folder.Parent = parent

	local width = config.Width or 40  -- in tiles
	local length = config.Length or 100 -- in tiles
	local ox, oz = config.OriginX or 0, config.OriginZ or 0
	local seed = config.Seed or RNG:NextNumber()

	-- Noise scales
	local heightScale = 0.04
	local detailScale = 0.12

	for x = 1, width do
		for z = 1, length do
			-- 1. Get Base Height (0 to 1)
			local nx = (x + ox/TILE_SIZE) * heightScale
			local nz = (z + oz/TILE_SIZE) * heightScale
			local h = math.noise(nx, nz, seed)
			h = (h + 1) / 2 -- normalize to 0-1

			-- 2. Add Detail
			local dh = math.noise(nx * 3, nz * 3, seed * 1.5) * 0.15
			h = math.clamp(h + dh, 0, 1)

			-- 3. Quantize to 16 levels
			local level = math.floor(h * (LEVELS - 1))
			local yPos = level * (MAX_HEIGHT / LEVELS)

			-- 4. Determine Material/Color based on level and "Road" noise
			local mat, col
			local isRoad = false
			
			-- Simple road noise: a "river" of path through the terrain
			local roadNoise = math.noise((x + ox/TILE_SIZE) * 0.05, (z + oz/TILE_SIZE) * 0.05, seed * 2)
			if math.abs(roadNoise) < 0.06 and level > 1 then
				isRoad = true
			end

			if level <= 1 then
				mat, col = PALETTE.Water[2], PALETTE.Water[1]
			elseif isRoad then
				mat, col = PALETTE.Road[2], PALETTE.Road[1]
			elseif level < 4 then
				mat, col = PALETTE.Sand[2], PALETTE.Sand[1]
			elseif level < 10 then
				mat, col = PALETTE.Grass[2], PALETTE.Grass[1]
			elseif level < 14 then
				mat, col = PALETTE.Rock[2], PALETTE.Rock[1]
			else
				mat, col = PALETTE.Snow[2], PALETTE.Snow[1]
			end

			-- 5. Build the tile — position so TOP face = yPos
			local part = Instance.new("Part")
			part.Anchored = true
			part.Size = Vector3.new(TILE_SIZE, MAX_HEIGHT, TILE_SIZE)
			part.Color = col
			part.Material = mat
			-- Top face should be AT yPos, so center = yPos - half height
			part.CFrame = CFrame.new(
				ox + (x - width/2) * TILE_SIZE,
				yPos - (MAX_HEIGHT / 2),
				oz + (z - length/2) * TILE_SIZE
			)
			part.TopSurface = Enum.SurfaceType.Smooth
			part.Parent = folder

			-- 6. Add Details (Trees, Rocks)
			if level >= 4 and level < 10 and not isRoad then
				if RNG:NextNumber() < 0.03 then
					TerrainGenerator.spawnTree(folder, part.Position + Vector3.new(0, MAX_HEIGHT/2, 0))
				elseif RNG:NextNumber() < 0.02 then
					TerrainGenerator.spawnRock(folder, part.Position + Vector3.new(0, MAX_HEIGHT/2, 0))
				end
			end
		end
	end

	return folder
end

function TerrainGenerator.spawnTree(parent, pos)
	local trunkHeight = 6 + RNG:NextNumber(0, 4)
	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(2, trunkHeight, 2)
	trunk.Color = Color3.fromRGB(80, 60, 40)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CFrame = CFrame.new(pos + Vector3.new(0, trunkHeight/2, 0)) * CFrame.Angles(0, math.rad(RNG:NextNumber(0, 360)), 0)
	trunk.Parent = parent

	local leafSize = 7 + RNG:NextNumber(0, 4)
	local leaves = Instance.new("Part")
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(leafSize, leafSize, leafSize)
	leaves.Color = Color3.fromRGB(40, 90, 40)
	leaves.Material = Enum.Material.Grass
	leaves.Anchored = true
	leaves.CFrame = trunk.CFrame * CFrame.new(0, trunkHeight/2 + leafSize/4, 0)
	leaves.Parent = parent
end

function TerrainGenerator.spawnRock(parent, pos)
	local rock = Instance.new("Part")
	rock.Size = Vector3.new(RNG:NextNumber(2, 6), RNG:NextNumber(2, 4), RNG:NextNumber(2, 6))
	rock.Color = Color3.fromRGB(110, 110, 110); rock.Material = Enum.Material.Rock
	rock.Anchored = true; rock.CFrame = CFrame.new(pos + Vector3.new(0, rock.Size.Y/2, 0))
	rock.Parent = parent
end

return TerrainGenerator
