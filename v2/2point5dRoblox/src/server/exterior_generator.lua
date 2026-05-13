local TerrainGenerator = require(script.Parent:WaitForChild("terrain_generator"))

local ExteriorGenerator = {}

function ExteriorGenerator.generate(parent)
	local existing = (parent or workspace):FindFirstChild("Exterior")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name   = "Exterior"
	folder.Parent = parent or workspace

	-- Generate the massive natural terrain
	-- Significantly increased scale to hide edges during drop pod flight
	TerrainGenerator.generate(folder, {
		Name = "NaturalWasteland",
		Width = 100,
		Length = 400,
		OriginX = 0,
		OriginZ = 1200,
		Seed = 99887,
	})

	-- Still add the Dungeon Entrance Archway at the end of the terrain
	ExteriorGenerator.buildDungeonEntrance(folder)

	return folder
end

function ExteriorGenerator.buildDungeonEntrance(parent)
	local ez = 1850
	local GROUND_Y = 15 -- Adjust based on terrain level at that point

	-- Left pillar
	local p1 = Instance.new("Part")
	p1.Size=Vector3.new(4,25,4); p1.Color=Color3.fromRGB(55,55,65); p1.Material=Enum.Material.Slate
	p1.Anchored=true; p1.CFrame=CFrame.new(-12, GROUND_Y + 12.5, ez); p1.Parent=parent
	-- Right pillar
	local p2 = Instance.new("Part")
	p2.Size=Vector3.new(4,25,4); p2.Color=Color3.fromRGB(55,55,65); p2.Material=Enum.Material.Slate
	p2.Anchored=true; p2.CFrame=CFrame.new( 12, GROUND_Y + 12.5, ez); p2.Parent=parent

	local lintel = Instance.new("Part")
	lintel.Size=Vector3.new(30,5,4); lintel.Color=Color3.fromRGB(45,45,55); lintel.Material=Enum.Material.Slate
	lintel.Anchored=true; lintel.CFrame=CFrame.new( 0, GROUND_Y + 27, ez); lintel.Parent=parent

	-- Glowing rune
	local rune = Instance.new("Part")
	rune.Name = "ArchRune"
	rune.Size=Vector3.new(6,6,0.5); rune.Color=Color3.fromRGB(150,0,255); rune.Material=Enum.Material.Neon
	rune.Anchored=true; rune.CanCollide=false; rune.CFrame=CFrame.new(0, GROUND_Y + 32, ez); rune.Parent=parent
	
	local l = Instance.new("PointLight", rune)
	l.Color=Color3.fromRGB(150,0,255); l.Brightness=3; l.Range=35

	-- Actual teleport detector
	local detector = Instance.new("Part")
	detector.Name = "DungeonEnterDetector"
	detector.Size = Vector3.new(20, 25, 4)
	detector.Transparency = 1
	detector.Anchored = true
	detector.CanCollide = false
	detector.CFrame = CFrame.new(0, GROUND_Y + 12.5, ez)
	detector.Parent = parent

	-- Label
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0,160,0,40); bg.StudsOffset = Vector3.new(0,16,0)
	bg.Parent = rune
	local lbl = Instance.new("TextLabel", bg)
	lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
	lbl.TextColor3 = Color3.fromRGB(200,150,255)
	lbl.Font = Enum.Font.GothamBold; lbl.TextScaled=true
	lbl.Text = "☠  DUNGEON ENTRANCE"
	
	-- Note: The GameManager will connect to this detector's Touched event
end

return ExteriorGenerator

