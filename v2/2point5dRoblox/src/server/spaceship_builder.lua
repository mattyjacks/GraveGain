-- spaceship_builder.lua
-- Procedurally generates a flying-saucer spaceship exterior.
-- Disk hull + dome + 4 engine pods + antenna + landing struts + Neon details.
-- Call SpaceshipBuilder.build(parent, origin) → returns the Model.

local SpaceshipBuilder = {}

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored    = true
	p.CanCollide  = props.noCollide == true and false or true
	p.CastShadow  = true
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "noCollide" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function light(p, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color; l.Brightness = brightness; l.Range = range
	l.Parent = p
end

local HULL_COLOR    = Color3.fromRGB(55, 60, 80)
local DETAIL_COLOR  = Color3.fromRGB(30, 35, 55)
local NEON_CYAN     = Color3.fromRGB(0, 220, 255)
local NEON_ORANGE   = Color3.fromRGB(255, 140, 0)
local NEON_PURPLE   = Color3.fromRGB(180, 60, 255)
local GLASS_COLOR   = Color3.fromRGB(120, 200, 255)
local METAL         = Enum.Material.Metal
local NEON          = Enum.Material.Neon
local GLASS         = Enum.Material.Glass
local SmoothPlastic = Enum.Material.SmoothPlastic

function SpaceshipBuilder.build(parent, origin)
	origin = origin or Vector3.new(0, 0, 0)
	local ox, oy, oz = origin.X, origin.Y, origin.Z

	local model = Instance.new("Model")
	model.Name = "Spaceship"
	model.Parent = parent

	-- ── Main disk hull (Modular Ring to allow holes) ─────────────────────────────
	local hullSegments = 12
	local hullRadius = 75
	for i = 1, hullSegments do
		local angle = math.rad((i-1) * (360 / hullSegments))
		local nextAngle = math.rad(i * (360 / hullSegments))
		local midAngle = (angle + nextAngle) / 2
		
		local segment = part(model, {
			Name = "HullSegment_" .. i,
			Size = Vector3.new(50, 12, 40),
			Color = HULL_COLOR, Material = METAL,
			CFrame = CFrame.new(ox + math.cos(midAngle) * 50, oy, oz + math.sin(midAngle) * 50) 
				* CFrame.Angles(0, -midAngle, 0)
		})
	end

	-- Neon Deck Rings (Atmospheric Lighting)
	local ringRadii = {150 * 0.15, 150 * 0.3, 150 * 0.42}
	for i, r in ipairs(ringRadii) do
		local ring = part(model, {
			Name = "NeonRing", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, r * 2, r * 2),
			Color = Color3.fromRGB(40, 100, 255), Material = NEON,
			CFrame = CFrame.new(ox, oy + 6, oz) * CFrame.Angles(0, 0, math.rad(90)),
			noCollide = true,
		})
		if i == 1 or i == 3 then
			light(ring, Color3.fromRGB(80, 140, 255), 0.5, i == 1 and 40 or 60)
		end
	end

	-- Disk rim accent (glowing ring)
	local rim = part(model, {
		Name = "Rim", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.5, 152, 152),
		Color = NEON_CYAN, Material = NEON,
		CFrame = CFrame.new(ox, oy + 0.5, oz) * CFrame.Angles(0, 0, math.rad(90)),
		noCollide = true,
	})
	light(rim, NEON_CYAN, 2, 100)

	-- Under-disk (Modular Ring)
	for i = 1, hullSegments do
		local angle = math.rad((i-1) * (360 / hullSegments))
		local midAngle = angle + math.rad(180 / hullSegments)
		
		part(model, {
			Name = "UnderSegment_" .. i,
			Size = Vector3.new(45, 6, 35),
			Color = DETAIL_COLOR, Material = METAL,
			CFrame = CFrame.new(ox + math.cos(midAngle) * 45, oy - 2.5, oz + math.sin(midAngle) * 45)
				* CFrame.Angles(0, -midAngle, 0)
		})
	end

	-- ── Open Bridge (No roof) ──────────────────────────────────────────
	-- Inner deck base (Modular Ring)
	for i = 1, 8 do
		local angle = math.rad((i-1) * (360 / 8))
		local midAngle = angle + math.rad(180 / 8)
		part(model, {
			Name = "DomeBaseSegment_" .. i,
			Size = Vector3.new(15, 8, 15),
			Color = HULL_COLOR, Material = METAL,
			CFrame = CFrame.new(ox + math.cos(midAngle) * 15, oy + 8, oz + math.sin(midAngle) * 15)
				* CFrame.Angles(0, -midAngle, 0)
		})
	end
	-- Guard rails around the open top
	for i = 1, 16 do
		local rad = math.rad(i * (360/16))
		local r = 22
		local rx = ox + math.cos(rad) * r
		local rz = oz + math.sin(rad) * r
		part(model, {
			Name = "Rail", Shape = Enum.PartType.Block,
			Size = Vector3.new(1, 6, 4),
			Color = DETAIL_COLOR, Material = METAL,
			CFrame = CFrame.new(rx, oy + 12, rz) * CFrame.Angles(0, -rad, 0),
		})
	end

	-- ── Engine pods (×4, Massive) ────────────────────────────────
	local angles = {0, 90, 180, 270}
	for _, ang in ipairs(angles) do
		local rad = math.rad(ang)
		local ex = ox + math.cos(rad) * 65
		local ez = oz + math.sin(rad) * 65

		-- Nacelle body
		local eng = part(model, {
			Name = "Engine", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(15, 18, 18),
			Color = DETAIL_COLOR, Material = METAL,
			CFrame = CFrame.new(ex, oy - 3, ez) * CFrame.Angles(0, 0, math.rad(90)),
		})
		-- Thruster glow
		local thrust = part(model, {
			Name = "Thrust", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4, 14, 14),
			Color = NEON_ORANGE, Material = NEON,
			CFrame = CFrame.new(ex, oy - 10, ez) * CFrame.Angles(0, 0, math.rad(90)),
			noCollide = true,
		})
		light(thrust, NEON_ORANGE, 3, 50)
		-- Pylon
		part(model, {
			Name = "Pylon", Shape = Enum.PartType.Block,
			Size = Vector3.new(4, 15, 35),
			Color = HULL_COLOR, Material = METAL,
			CFrame = CFrame.lookAt(
				Vector3.new((ox + ex) / 2, oy - 1, (oz + ez) / 2),
				Vector3.new(ex, oy - 1, ez)
			),
		})
	end

	-- ── Landing struts (×3) ──────────────────────────────────────────────
	for i = 1, 3 do
		local rad = math.rad(i * 120)
		local sx = ox + math.cos(rad) * 45
		local sz = oz + math.sin(rad) * 45
		-- Strut
		part(model, {
			Name = "Strut", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(25, 3, 3),
			Color = DETAIL_COLOR, Material = METAL,
			CFrame = CFrame.new((sx + ox) / 2, oy - 8, (sz + oz) / 2)
				* CFrame.lookAt(Vector3.new(0,0,0), Vector3.new(sx - ox, -12, sz - oz).Unit)
				* CFrame.Angles(0, 0, math.rad(90)),
		})
		-- Foot pad
		part(model, {
			Name = "Pad", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, 8, 8),
			Color = HULL_COLOR, Material = METAL,
			CFrame = CFrame.new(sx, oy - 20, sz) * CFrame.Angles(0, 0, math.rad(90)),
		})
	end

	-- ── Antenna array ───────────────────────────────────────────
	part(model, {
		Name = "Antenna", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(25, 2, 2),
		Color = DETAIL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox, oy + 28, oz),
	})
	local antTip = part(model, {
		Name = "AntTip", Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 4),
		Color = NEON_PURPLE, Material = NEON,
		CFrame = CFrame.new(ox, oy + 40, oz), noCollide = true,
	})
	light(antTip, NEON_PURPLE, 3, 40)

	-- ── Windows ────────────────────────────────
	for i = 1, 12 do
		local wrad = math.rad(i * 30)
		local wr = 55
		local wx = ox + math.cos(wrad) * wr
		local wz = oz + math.sin(wrad) * wr
		local win = part(model, {
			Name = "Window", Shape = Enum.PartType.Block,
			Size = Vector3.new(0.5, 6, 6),
			Color = GLASS_COLOR, Material = GLASS, Transparency = 0.5,
			CFrame = CFrame.new(wx, oy + 2, wz) * CFrame.Angles(0, wrad, 0),
			noCollide = true,
		})
		light(win, GLASS_COLOR, 0.8, 20)
	end

	-- ── Massive Sensor dish ─────────────────────────────────────────────────────
	part(model, {
		Name = "Dish", Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 12, 12),
		Color = HULL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox + 30, oy + 10, oz),
	})
	part(model, {
		Name = "DishStem", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 2, 2),
		Color = DETAIL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox + 30, oy + 7, oz),
	})

	model.PrimaryPart = disk
	return model
end

return SpaceshipBuilder
