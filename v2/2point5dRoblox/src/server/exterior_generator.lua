-- exterior_generator.lua  (SERVER - NEW)
-- Generates the alien wasteland between the spaceship (Z=0) and dungeon (Z=2000).
-- Zone occupies Z=500 to Z=1900. Dungeon entrance archway at Z=1800.

local ExteriorGenerator = {}
ExteriorGenerator.__index = ExteriorGenerator

local RNG = Random.new(99887)

local function r(lo, hi) return lo + RNG:NextNumber() * (hi - lo) end
local function ri(lo, hi) return RNG:NextInteger(lo, hi) end

local GROUND_Y   = -1    -- ground level
local ZONE_START = 500
local ZONE_END   = 1950
local ZONE_WIDTH = 300   -- half-width each side of X=0

-- ── Helpers ────────────────────────────────────────────────────────────────

local function makePart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

-- ── Ground plane ───────────────────────────────────────────────────────────

local function buildGround(parent)
	local len = ZONE_END - ZONE_START
	makePart(parent, {
		Name = "ExteriorGround",
		Size = Vector3.new(ZONE_WIDTH * 2, 2, len),
		Color = Color3.fromRGB(55, 48, 38),
		Material = Enum.Material.Ground,
		CFrame = CFrame.new(0, GROUND_Y - 1, (ZONE_START + ZONE_END) / 2),
	})
	-- Path (slightly lighter strip down the middle)
	makePart(parent, {
		Name = "Path",
		Size = Vector3.new(16, 2.1, len),
		Color = Color3.fromRGB(80, 70, 55),
		Material = Enum.Material.Cobblestone,
		CFrame = CFrame.new(0, GROUND_Y - 0.9, (ZONE_START + ZONE_END) / 2),
	})
end

-- ── Rocks ──────────────────────────────────────────────────────────────────

local function spawnRocks(parent)
	for _ = 1, 80 do
		local x = r(-ZONE_WIDTH + 15, ZONE_WIDTH - 15)
		if math.abs(x) < 12 then x = x + 20 * (x < 0 and -1 or 1) end -- avoid path
		local z = r(ZONE_START + 20, ZONE_END - 100)
		local sz = r(2, 10)
		makePart(parent, {
			Name = "Rock",
			Shape = Enum.PartType.Block,
			Size = Vector3.new(sz, r(1, sz * 0.8), sz * r(0.6, 1.2)),
			Color = Color3.fromRGB(ri(50,80), ri(50,80), ri(55,85)),
			Material = (ri(1,2) == 1) and Enum.Material.Rock or Enum.Material.Slate,
			CFrame = CFrame.new(x, GROUND_Y + sz * 0.3, z)
				* CFrame.Angles(r(-0.2,0.2), r(0, math.pi*2), r(-0.2,0.2)),
		})
	end
end

-- ── Dead trees ─────────────────────────────────────────────────────────────

local function spawnTrees(parent)
	for _ = 1, 40 do
		local x = r(-ZONE_WIDTH + 10, ZONE_WIDTH - 10)
		if math.abs(x) < 14 then x = x + 18 * (x < 0 and -1 or 1) end
		local z = r(ZONE_START + 20, ZONE_END - 200)
		local h = r(8, 18)
		-- Trunk
		makePart(parent, {
			Name = "Trunk",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(h, r(0.6,1.4), r(0.6,1.4)),
			Color = Color3.fromRGB(ri(50,70), ri(35,50), ri(20,35)),
			Material = Enum.Material.Wood,
			CFrame = CFrame.new(x, GROUND_Y + h/2, z) * CFrame.Angles(0,0,math.rad(90)),
		})
		-- Gnarled branch stubs
		for _ = 1, ri(2, 4) do
			local blen = r(2, 5)
			local ba = r(0.3, 1.1)
			makePart(parent, {
				Name = "Branch",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(blen, 0.4, 0.4),
				Color = Color3.fromRGB(55, 40, 25),
				Material = Enum.Material.Wood,
				CFrame = CFrame.new(x + r(-3,3), GROUND_Y + h * r(0.5,0.9), z + r(-3,3))
					* CFrame.Angles(ba, r(0, math.pi*2), r(-0.3,0.3)),
			})
		end
	end
end

-- ── Lore stones (glowing runestones) ──────────────────────────────────────

local function spawnLoreStones(parent)
	local colors = {
		Color3.fromRGB(0,200,255),
		Color3.fromRGB(255,80,200),
		Color3.fromRGB(80,255,120),
		Color3.fromRGB(255,200,0),
	}
	for i = 1, 12 do
		local x = r(-80, 80)
		local z = r(ZONE_START + 100, ZONE_END - 300)
		local col = colors[((i-1) % #colors) + 1]
		local stone = makePart(parent, {
			Name = "LoreStone",
			Shape = Enum.PartType.Block,
			Size = Vector3.new(r(1.5,3), r(3,6), r(0.6,1.2)),
			Color = Color3.fromRGB(60,60,75),
			Material = Enum.Material.Slate,
			CFrame = CFrame.new(x, GROUND_Y + 3, z) * CFrame.Angles(0, r(0,math.pi), r(-0.1,0.1)),
		})
		-- Glowing rune face
		local rune = makePart(parent, {
			Name = "Rune",
			Size = Vector3.new(0.2, stone.Size.Y * 0.6, stone.Size.Z * 2),
			Color = col, Material = Enum.Material.Neon,
			CanCollide = false,
			CFrame = stone.CFrame * CFrame.new(stone.Size.X/2 + 0.1, 0, 0),
		})
		local l = Instance.new("PointLight", rune)
		l.Color = col; l.Brightness = 1.5; l.Range = 20
	end
end

-- ── Dungeon entrance archway ───────────────────────────────────────────────

local function buildDungeonEntrance(parent)
	local ez = 1850  -- archway Z position

	-- Ground ramp into dungeon
	makePart(parent, {
		Name = "EntranceRamp",
		Size = Vector3.new(20, 2, 60),
		Color = Color3.fromRGB(50, 45, 35),
		Material = Enum.Material.Cobblestone,
		CFrame = CFrame.new(0, GROUND_Y - 0.5, ez + 30),
	})

	-- Left pillar
	makePart(parent, {Name="Pillar_L", Size=Vector3.new(3,20,3),
		Color=Color3.fromRGB(55,55,65), Material=Enum.Material.Slate,
		CFrame=CFrame.new(-9, GROUND_Y + 10, ez)})
	-- Right pillar
	makePart(parent, {Name="Pillar_R", Size=Vector3.new(3,20,3),
		Color=Color3.fromRGB(55,55,65), Material=Enum.Material.Slate,
		CFrame=CFrame.new( 9, GROUND_Y + 10, ez)})
	-- Lintel
	makePart(parent, {Name="Lintel", Size=Vector3.new(24,4,3),
		Color=Color3.fromRGB(45,45,55), Material=Enum.Material.Slate,
		CFrame=CFrame.new( 0, GROUND_Y + 21, ez)})

	-- Glowing rune above arch
	local rune = makePart(parent, {Name="ArchRune", Size=Vector3.new(0.3,6,6),
		Color=Color3.fromRGB(150,0,255), Material=Enum.Material.Neon,
		CanCollide=false,
		CFrame=CFrame.new(0, GROUND_Y + 25, ez)})
	local l = Instance.new("PointLight", rune)
	l.Color=Color3.fromRGB(150,0,255); l.Brightness=3; l.Range=35

	-- Sign billboard
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0,140,0,30); bg.StudsOffset = Vector3.new(0,14,0)
	bg.Parent = rune
	local lbl = Instance.new("TextLabel", bg)
	lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
	lbl.TextColor3 = Color3.fromRGB(200,150,255)
	lbl.Font = Enum.Font.GothamBold; lbl.TextScaled=true
	lbl.Text = "☠  DUNGEON ENTRANCE"
end

-- ── Torches lining the path ────────────────────────────────────────────────

local function buildPathTorches(parent)
	local spacing = 60
	local z = ZONE_START + 80
	while z < ZONE_END - 100 do
		for _, side in ipairs({-14, 14}) do
			local base = makePart(parent, {
				Name="TorchPost", Shape=Enum.PartType.Cylinder,
				Size=Vector3.new(5,0.7,0.7),
				Color=Color3.fromRGB(90,60,30), Material=Enum.Material.Wood,
				CFrame=CFrame.new(side, GROUND_Y+2.5, z)*CFrame.Angles(0,0,math.rad(90)),
			})
			local flame = makePart(parent, {
				Name="Flame", Shape=Enum.PartType.Ball,
				Size=Vector3.new(1.2,1.2,1.2),
				Color=Color3.fromRGB(255,140,0), Material=Enum.Material.Neon,
				CanCollide=false,
				CFrame=CFrame.new(side, GROUND_Y+5.5, z),
			})
			local fl = Instance.new("PointLight", flame)
			fl.Color=Color3.fromRGB(255,160,60); fl.Brightness=1.5; fl.Range=25
		end
		z = z + spacing
	end
end

-- ── Public ─────────────────────────────────────────────────────────────────

function ExteriorGenerator.generate(parent)
	local existing = (parent or workspace):FindFirstChild("Exterior")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name   = "Exterior"
	folder.Parent = parent or workspace

	buildGround(folder)
	spawnRocks(folder)
	spawnTrees(folder)
	spawnLoreStones(folder)
	buildPathTorches(folder)
	buildDungeonEntrance(folder)

	return folder
end

return ExteriorGenerator
