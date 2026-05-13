-- terrain_generator.lua  (SERVER)
-- Generates a 16-level stepped terrain with mountains, roads, rivers, and ponds.
-- Uses math.noise for heightmaps and biome distribution.

local TerrainGenerator = {}

local RNG = Random.new()
local TILE_SIZE = 8
local LEVELS = 16
local MAX_HEIGHT = 80  -- total height of 16 levels

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))

-- ── Biome Palettes extracted from GameData ───────────────────────────────

-- ── Generator ──────────────────────────────────────────────────────────────

function TerrainGenerator.generate(parent, config)
	local folder = Instance.new("Folder")
	folder.Name = config.Name or "GeneratedTerrain"
	folder.Parent = parent

	local width = config.Width or 16
	local length = config.Length or 16
	local ox, oz = config.OriginX or 0, config.OriginZ or 0
	local seed = config.Seed or 1337
	local biomeName = config.Biome or "Wasteland"
	local biomeData = GameData.BIOMES[biomeName]

	-- Noise scales
	local heightScale = 0.04
	local detailScale = 0.12
	local heightMod = biomeData.heightMod or 1.0

	for x = 1, width do
		for z = 1, length do
			-- 1. Get Base Height (0 to 1)
			local nx = (ox/TILE_SIZE + x) * heightScale
			local nz = (oz/TILE_SIZE + z) * heightScale
			local h = math.noise(nx, nz, seed)
			h = (h + 1) / 2 -- normalize to 0-1

			-- 2. Add Detail
			local dh = math.noise(nx * 3, nz * 3, seed * 1.5) * 0.15
			h = math.clamp(h + dh, 0, 1)

			-- 3. Quantize to 16 levels and apply biome modifier
			local level = math.floor(h * (LEVELS - 1) * heightMod)
			local yPos = level * (MAX_HEIGHT / LEVELS)

			-- 4. Determine Material/Color based on biome and level
			local mat = biomeData.material
			local col = biomeData.color
			
			-- Add slight color variation
			local colorVar = math.noise(nx * 5, nz * 5, seed * 3) * 0.1
			col = Color3.new(
				math.clamp(col.R + colorVar, 0, 1),
				math.clamp(col.G + colorVar, 0, 1),
				math.clamp(col.B + colorVar, 0, 1)
			)

			-- Biome-specific level behavior
			if biomeName == "Inferno" and level <= 2 then
				mat = Enum.Material.Neon
				col = Color3.fromRGB(255, 60, 0) -- Lava
			end

			-- 5. Build the tile
			local part = Instance.new("Part")
			part.Anchored = true
			part.Size = Vector3.new(TILE_SIZE, MAX_HEIGHT, TILE_SIZE)
			part.Color = col
			part.Material = mat
			part.CFrame = CFrame.new(
				ox + (x - width/2) * TILE_SIZE,
				yPos - (MAX_HEIGHT / 2),
				oz + (z - length/2) * TILE_SIZE
			)
			part.TopSurface = Enum.SurfaceType.Smooth
			part.Parent = folder

			-- 6. Spawn Biome Props
			local propChance = 0.04
			if biomeName == "Forest" then propChance = 0.08 end
			
			if RNG:NextNumber() < propChance and level > 2 then
				local surfacePos = part.Position + Vector3.new(0, MAX_HEIGHT/2, 0)
				if biomeName == "Forest" then
					TerrainGenerator.spawnTree(folder, surfacePos)
				elseif biomeName == "CrystalPlains" then
					TerrainGenerator.spawnCrystal(folder, surfacePos)
				elseif biomeName == "Inferno" then
					TerrainGenerator.spawnObsidian(folder, surfacePos)
				else
					TerrainGenerator.spawnRock(folder, surfacePos)
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

function TerrainGenerator.spawnCrystal(parent, pos)
	local crystal = Instance.new("Part")
	crystal.Size = Vector3.new(2, RNG:NextNumber(4, 8), 2)
	crystal.Color = Color3.fromRGB(150, 100, 255)
	crystal.Material = Enum.Material.Neon
	crystal.Transparency = 0.3
	crystal.Anchored = true
	crystal.CFrame = CFrame.new(pos + Vector3.new(0, crystal.Size.Y/2, 0)) * CFrame.Angles(math.rad(RNG:NextNumber(-20, 20)), math.rad(RNG:NextNumber(0, 360)), math.rad(RNG:NextNumber(-20, 20)))
	crystal.Parent = parent
	
	local light = Instance.new("PointLight", crystal)
	light.Color = crystal.Color; light.Range = 15; light.Brightness = 2
end

function TerrainGenerator.spawnObsidian(parent, pos)
	local rock = Instance.new("Part")
	rock.Size = Vector3.new(RNG:NextNumber(3, 7), RNG:NextNumber(2, 5), RNG:NextNumber(3, 7))
	rock.Color = Color3.fromRGB(20, 20, 25); rock.Material = Enum.Material.Basalt
	rock.Anchored = true; rock.CFrame = CFrame.new(pos + Vector3.new(0, rock.Size.Y/2, 0))
	rock.Parent = parent
	
	if RNG:NextNumber() < 0.3 then
		local deco = Instance.new("Part")
		deco.Size = Vector3.new(rock.Size.X * 0.8, 0.2, rock.Size.Z * 0.8)
		deco.Color = Color3.fromRGB(255, 60, 0); deco.Material = Enum.Material.Neon
		deco.CFrame = rock.CFrame * CFrame.new(0, rock.Size.Y/2, 0)
		deco.Anchored = true; deco.Parent = rock
	end
end

return TerrainGenerator
