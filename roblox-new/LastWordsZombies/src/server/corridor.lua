-- Builds the corridor environment and returns cover positions for zombie spawning

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local Corridor = {}

local function MakePart(parent, name, size, pos, color, material, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.Concrete
	p.Anchored = true
	p.CanCollide = canCollide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Corridor.Build()
	local W = GameData.VISUALS.CORRIDOR_WIDTH
	local H = GameData.VISUALS.CORRIDOR_HEIGHT
	local L = GameData.VISUALS.CORRIDOR_LENGTH
	local hw = W / 2

	local corridor = Instance.new("Model")
	corridor.Name = "Corridor"
	corridor.Parent = workspace

	-- Checkerboard floor tiles
	local tileSize = 10
	for tx = -hw, hw - tileSize, tileSize do
		for tz = -L/2, L/2 - tileSize, tileSize do
			local isDark = ((math.floor(tx/tileSize) + math.floor(tz/tileSize)) % 2 == 0)
			MakePart(corridor, "FloorTile",
				Vector3.new(tileSize, 1, tileSize),
				Vector3.new(tx + tileSize/2, -0.5, tz + tileSize/2),
				isDark and Color3.new(0.18, 0.18, 0.22) or Color3.new(0.28, 0.28, 0.32),
				Enum.Material.SmoothPlastic)
		end
	end

	MakePart(corridor, "LeftWall",  Vector3.new(1, H, L), Vector3.new(-hw - 0.5, H/2, 0), Color3.new(0.2, 0.2, 0.25))
	MakePart(corridor, "RightWall", Vector3.new(1, H, L), Vector3.new( hw + 0.5, H/2, 0), Color3.new(0.2, 0.2, 0.25))
	MakePart(corridor, "Ceiling",   Vector3.new(W + 2, 1, L), Vector3.new(0, H + 0.5, 0), Color3.new(0.15, 0.15, 0.18))
	-- Back wall hides zombie spawn zone
	MakePart(corridor, "BackWall",  Vector3.new(W + 2, H + 2, 1), Vector3.new(0, H/2, -L/2 - 0.5), Color3.new(0.12, 0.12, 0.15))
	-- Front wall with viewport hole
	MakePart(corridor, "FrontWallL", Vector3.new(hw - 5, H + 2, 1), Vector3.new(-hw/2 - 2.5, H/2, L/2 + 0.5), Color3.new(0.08, 0.08, 0.1))
	MakePart(corridor, "FrontWallR", Vector3.new(hw - 5, H + 2, 1), Vector3.new( hw/2 + 2.5, H/2, L/2 + 0.5), Color3.new(0.08, 0.08, 0.1))
	-- Outer void box to block skybox from being visible
	MakePart(corridor, "VoidCeiling", Vector3.new(W + 200, 10, L + 200), Vector3.new(0, H + 6, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, false)

	-- Neon trim strips along walls
	for _, side in ipairs({-hw - 0.3, hw + 0.3}) do
		MakePart(corridor, "WallStrip", Vector3.new(0.3, 0.4, L), Vector3.new(side, 0.7,    0), Color3.new(0.8, 0.05, 0.05), Enum.Material.Neon, false)
		MakePart(corridor, "WallStrip", Vector3.new(0.3, 0.4, L), Vector3.new(side, H - 1,  0), Color3.new(0.6, 0.03, 0.03), Enum.Material.Neon, false)
	end

	-- Ceiling pipes
	local pipeColors = {Color3.new(0.35,0.25,0.18), Color3.new(0.28,0.28,0.32), Color3.new(0.4,0.18,0.1)}
	for i = 1, 6 do
		MakePart(corridor, "Pipe", Vector3.new(0.6, 0.6, L),
			Vector3.new(-hw + (i * W/7), H - 1.5, 0),
			pipeColors[(i % 3) + 1], Enum.Material.Metal, false)
	end

	-- Hanging cables
	for i = 1, 12 do
		MakePart(corridor, "Cable", Vector3.new(W * 0.6, 0.2, 0.2),
			Vector3.new(0, H - 3, -L/2 + (i * L/13)),
			Color3.new(0.1, 0.1, 0.1), Enum.Material.Metal, false)
	end

	-- Accent lights alternating red/teal/blue for atmosphere
	local accentColors = {
		Color3.new(1, 0.08, 0.05),
		Color3.new(0.0, 0.8, 0.6),
		Color3.new(0.1, 0.3, 1.0),
	}
	local fixtureColors = {
		Color3.new(0.25, 0.05, 0.05),
		Color3.new(0.05, 0.22, 0.18),
		Color3.new(0.05, 0.08, 0.25),
	}
	for i = 1, 15 do
		local ci = ((i - 1) % 3) + 1
		local lx = (i % 2 == 0) and -hw * 0.5 or hw * 0.5
		local lp = MakePart(corridor, "LightFixture", Vector3.new(1.5, 0.4, 1.5),
			Vector3.new(lx, H - 0.5, -L/2 + (i * L/16)),
			fixtureColors[ci], Enum.Material.Neon, false)
		local light = Instance.new("PointLight")
		light.Color = accentColors[ci]
		light.Brightness = 2.5
		light.Range = 30
		light.Parent = lp
	end
	-- Floor-level fill lights (cool white) so floor tiles are visible
	for i = 1, 8 do
		local fx = (i % 2 == 0) and -hw * 0.3 or hw * 0.3
		local fp = MakePart(corridor, "FloorLight", Vector3.new(0.5, 0.2, 0.5),
			Vector3.new(fx, 0.5, -L/2 + 10 + (i * L/9)),
			Color3.new(0.9, 0.95, 1), Enum.Material.Neon, false)
		local fl = Instance.new("PointLight")
		fl.Color = Color3.new(0.85, 0.9, 1)
		fl.Brightness = 1.5
		fl.Range = 20
		fl.Parent = fp
	end

	-- Wall damage strips
	for i = 1, 20 do
		local side = (i % 2 == 0) and -hw or hw
		MakePart(corridor, "WallDamage",
			Vector3.new(0.2, 0.5 + math.random() * 2, 1 + math.random() * 4),
			Vector3.new(side, 1 + math.random() * (H * 0.6), -L/2 + math.random() * L),
			Color3.new(0.12, 0.04, 0.04), Enum.Material.SmoothPlastic, false)
	end

	-- Pillars with neon trim
	for iz = 1, 7 do
		local pz = -L/2 + 20 + (iz - 1) * 25
		for _, side in ipairs({-hw * 0.75, hw * 0.75}) do
			MakePart(corridor, "Pillar",     Vector3.new(3, H, 3),     Vector3.new(side, H/2, pz), Color3.new(0.22, 0.22, 0.27))
			MakePart(corridor, "PillarTrim", Vector3.new(3.2, 0.3, 3.2), Vector3.new(side, 0.8, pz), Color3.new(0.7, 0.05, 0.05), Enum.Material.Neon, false)
		end
	end

	-- Crates + barrels (returns cover positions)
	local coverPositions = {}
	local crateData = {
		{-hw*0.5,-80,4,4,5},{hw*0.5,-70,3,6,4},
		{-hw*0.6,-50,5,3,4},{hw*0.55,-40,4,4,5},
		{-hw*0.4,-20,3,3,3},{hw*0.4,-10,6,3,4},
		{hw*0.3,-95,4,5,5},{-hw*0.35,-60,3,4,4},
		{-hw*0.5,-130,5,4,6},{hw*0.5,-120,4,4,5},
	}
	for _, cd in ipairs(crateData) do
		local cx, cz, cw, cd2, ch = cd[1], cd[2], cd[3], cd[4], cd[5]
		MakePart(corridor, "Crate",      Vector3.new(cw, ch, cd2),     Vector3.new(cx, ch/2, cz),    Color3.new(0.35, 0.25, 0.12), Enum.Material.Wood)
		MakePart(corridor, "CrateStripe",Vector3.new(cw+0.1,0.3,cd2+0.1),Vector3.new(cx,ch*0.6,cz),Color3.new(0.9, 0.5, 0), Enum.Material.Neon, false)
		table.insert(coverPositions, Vector3.new(cx, 3, cz - 2))
	end
	for _ = 1, 8 do
		local bx = (math.random() - 0.5) * W * 0.7
		local bz = -L/2 + 15 + math.random() * (L - 30)
		MakePart(corridor, "Barrel", Vector3.new(2, 3, 2), Vector3.new(bx, 1.5, bz), Color3.new(0.3, 0.1, 0.05), Enum.Material.Metal)
		table.insert(coverPositions, Vector3.new(bx, 3, bz - 1))
	end

	return coverPositions
end

return Corridor
