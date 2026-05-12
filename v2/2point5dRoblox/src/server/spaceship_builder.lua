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

	-- ── Main disk hull (flattened cylinder) ─────────────────────────────
	local disk = part(model, {
		Name = "Disk", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(8, 120, 120),
		Color = HULL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox, oy, oz) * CFrame.Angles(0, 0, math.rad(90)),
	})
	-- Disk rim accent (glowing ring)
	local rim = part(model, {
		Name = "Rim", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, 122, 122),
		Color = NEON_CYAN, Material = NEON,
		CFrame = CFrame.new(ox, oy + 0.5, oz) * CFrame.Angles(0, 0, math.rad(90)),
		noCollide = true,
	})
	light(rim, NEON_CYAN, 1.5, 80)

	-- Under-disk (slightly darker)
	part(model, {
		Name = "Underbody", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 100, 100),
		Color = DETAIL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox, oy - 1.5, oz) * CFrame.Angles(0, 0, math.rad(90)),
	})

	-- ── Dome (upper bridge) ──────────────────────────────────────────────
	local dome = part(model, {
		Name = "Dome", Shape = Enum.PartType.Ball,
		Size = Vector3.new(30, 24, 30),
		Color = GLASS_COLOR, Material = GLASS,
		Transparency = 0.35,
		CFrame = CFrame.new(ox, oy + 14, oz),
	})
	-- Inner dome structure
	part(model, {
		Name = "DomeBase", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 36, 36),
		Color = HULL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox, oy + 6, oz) * CFrame.Angles(0, 0, math.rad(90)),
	})

	-- ── Engine pods (×4, equally spaced) ────────────────────────────────
	local angles = {0, 90, 180, 270}
	for _, ang in ipairs(angles) do
		local rad = math.rad(ang)
		local ex = ox + math.cos(rad) * 50
		local ez = oz + math.sin(rad) * 50

		-- Nacelle body
		local eng = part(model, {
			Name = "Engine", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(12, 14, 14),
			Color = DETAIL_COLOR, Material = METAL,
			CFrame = CFrame.new(ex, oy - 2, ez) * CFrame.Angles(0, 0, math.rad(90)),
		})
		-- Thruster glow
		local thrust = part(model, {
			Name = "Thrust", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 10, 10),
			Color = NEON_ORANGE, Material = NEON,
			CFrame = CFrame.new(ex, oy - 7, ez) * CFrame.Angles(0, 0, math.rad(90)),
			noCollide = true,
		})
		light(thrust, NEON_ORANGE, 2, 40)
		-- Pylon connecting to disk
		local pylon = part(model, {
			Name = "Pylon", Shape = Enum.PartType.Block,
			Size = Vector3.new(2.5, 14, 30),
			Color = HULL_COLOR, Material = METAL,
			CFrame = CFrame.lookAt(
				Vector3.new((ox + ex) / 2, oy - 1, (oz + ez) / 2),
				Vector3.new(ex, oy - 1, ez)
			) * CFrame.new(0, 0, 0),
		})
	end

	-- ── Landing struts (×3) ──────────────────────────────────────────────
	for i = 1, 3 do
		local rad = math.rad(i * 120)
		local sx = ox + math.cos(rad) * 35
		local sz = oz + math.sin(rad) * 35
		-- Strut
		part(model, {
			Name = "Strut", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(16, 2, 2),
			Color = DETAIL_COLOR, Material = METAL,
			CFrame = CFrame.new((sx + ox) / 2, oy - 6, (sz + oz) / 2)
				* CFrame.lookAt(Vector3.new(0,0,0), Vector3.new(sx - ox, -8, sz - oz).Unit)
				* CFrame.Angles(0, 0, math.rad(90)),
		})
		-- Foot pad
		part(model, {
			Name = "Pad", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.5, 6, 6),
			Color = HULL_COLOR, Material = METAL,
			CFrame = CFrame.new(sx, oy - 13.5, sz) * CFrame.Angles(0, 0, math.rad(90)),
		})
	end

	-- ── Antenna / sensor array ───────────────────────────────────────────
	part(model, {
		Name = "Antenna", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(18, 1.5, 1.5),
		Color = DETAIL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox, oy + 28, oz),
	})
	local antTip = part(model, {
		Name = "AntTip", Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		Color = NEON_PURPLE, Material = NEON,
		CFrame = CFrame.new(ox, oy + 37, oz), noCollide = true,
	})
	light(antTip, NEON_PURPLE, 2.5, 35)

	-- ── Decorative hull panels & windows ────────────────────────────────
	for i = 1, 8 do
		local wrad = math.rad(i * 45)
		local wr = 42
		local wx = ox + math.cos(wrad) * wr
		local wz = oz + math.sin(wrad) * wr
		local win = part(model, {
			Name = "Window", Shape = Enum.PartType.Block,
			Size = Vector3.new(0.5, 4, 4),
			Color = GLASS_COLOR, Material = GLASS, Transparency = 0.2,
			CFrame = CFrame.new(wx, oy + 1, wz)
				* CFrame.Angles(0, wrad, 0),
			noCollide = true,
		})
		light(win, GLASS_COLOR, 0.5, 15)
	end

	-- ── Sensor dish ─────────────────────────────────────────────────────
	part(model, {
		Name = "Dish", Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 8, 8),
		Color = HULL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox + 20, oy + 7, oz),
	})
	part(model, {
		Name = "DishStem", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 1.5, 1.5),
		Color = DETAIL_COLOR, Material = METAL,
		CFrame = CFrame.new(ox + 20, oy + 5, oz),
	})

	model.PrimaryPart = disk
	return model
end

return SpaceshipBuilder
