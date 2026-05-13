-- space_environment.lua  (CLIENT)
-- Manages the sky/lighting for Lobby (space), Exterior (dawn), and Dungeon modes.
-- Also creates procedural star field, planet billboard, and nebula tint.

local Lighting    = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local SpaceEnv = {}

-- ── Helpers ────────────────────────────────────────────────────────────────

local starSphere = nil
local planetBillboard = nil

local function clearSpaceAssets()
	if starSphere and starSphere.Parent then starSphere:Destroy() end
	if planetBillboard and planetBillboard.Parent then planetBillboard:Destroy() end
	starSphere = nil; planetBillboard = nil
end

local function tweenLighting(props, t)
	TweenService:Create(Lighting, TweenInfo.new(t or 1.5, Enum.EasingStyle.Sine), props):Play()
end

-- Remove any Sky/Atmosphere instances in Lighting
local function clearSky()
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("BlurEffect")
			or c:IsA("ColorCorrectionEffect") then
			c:Destroy()
		end
	end
end

-- ── Star field ─────────────────────────────────────────────────────────────

local function buildStars(parent)
	-- Large sphere of tiny Neon balls around the origin
	local folder = Instance.new("Folder")
	folder.Name = "_StarField"
	folder.Parent = parent

	local rng = Random.new(42)
	local RADIUS = 1800
	local starColors = {
		Color3.fromRGB(255,255,255),
		Color3.fromRGB(200,220,255),
		Color3.fromRGB(255,230,200),
		Color3.fromRGB(180,180,255),
		Color3.fromRGB(255,200,200),
	}

	for _ = 1, 600 do
		-- Random point on sphere surface
		local theta = rng:NextNumber() * math.pi * 2
		local phi   = math.acos(2 * rng:NextNumber() - 1)
		local x = RADIUS * math.sin(phi) * math.cos(theta)
		local y = RADIUS * math.sin(phi) * math.sin(theta)
		local z = RADIUS * math.cos(phi)

		local sz = rng:NextNumber() * 3 + 1.5
		local star = Instance.new("Part")
		star.Shape = Enum.PartType.Ball
		star.Size  = Vector3.new(sz, sz, sz)
		star.Color = starColors[rng:NextInteger(1, #starColors)]
		star.Material = Enum.Material.Neon
		star.Anchored = true
		star.CanCollide = false
		star.CastShadow = false
		star.CFrame = CFrame.new(x, y, z)
		star.Parent = folder
	end

	return folder
end

-- Planet / moon billboard (large glowing sphere in "sky")
local function buildPlanet(parent)
	local planet = Instance.new("Part")
	planet.Name  = "Planet"
	planet.Shape = Enum.PartType.Ball
	planet.Size  = Vector3.new(200, 200, 200)
	-- Randomly pick a blue-green or reddish planet
	local planets = {
		{Color3.fromRGB(60, 100, 200), Enum.Material.SmoothPlastic},  -- blue ocean world
		{Color3.fromRGB(180, 100, 50), Enum.Material.SmoothPlastic},  -- mars-like
		{Color3.fromRGB(140, 200, 140), Enum.Material.SmoothPlastic}, -- lush moon
	}
	local pick = planets[math.random(1, #planets)]
	planet.Color    = pick[1]
	planet.Material = pick[2]
	planet.Anchored = true
	planet.CanCollide = false
	planet.CastShadow = false
	planet.CFrame   = CFrame.new(600, 400, -1200)
	planet.Parent   = parent

	-- Atmosphere glow ring
	local glow = Instance.new("Part")
	glow.Shape   = Enum.PartType.Ball
	glow.Size    = Vector3.new(220, 220, 220)
	glow.Color   = Color3.fromRGB(100, 180, 255)
	glow.Material = Enum.Material.Neon
	glow.Transparency = 0.7
	glow.Anchored = true
	glow.CanCollide = false
	glow.CastShadow = false
	glow.CFrame  = planet.CFrame
	glow.Parent  = parent

	return planet
end

-- ── Public API ─────────────────────────────────────────────────────────────

function SpaceEnv.applyLobby()
	clearSky()
	clearSpaceAssets()

	-- Almost-black space sky
	tweenLighting({
		Ambient         = Color3.fromRGB(5, 5, 15),
		OutdoorAmbient  = Color3.fromRGB(5, 5, 15),
		Brightness      = 0.05,
		FogEnd          = 3000,
		FogColor        = Color3.fromRGB(2, 2, 10),
	}, 1)
	Lighting.ClockTime = 0

	-- Slight nebula color correction
	local cc = Instance.new("ColorCorrectionEffect")
	cc.TintColor   = Color3.fromRGB(180, 180, 255)
	cc.Brightness  = -0.05
	cc.Contrast    = 0.1
	cc.Saturation  = 0.15
	cc.Parent      = Lighting

	-- Stars + planet
	starSphere     = buildStars(workspace)
	planetBillboard = buildPlanet(workspace)
end

function SpaceEnv.applyExterior()
	clearSky()
	clearSpaceAssets()

	-- Eerie dawn on an alien world
	tweenLighting({
		Ambient        = Color3.fromRGB(100, 80, 120),
		OutdoorAmbient = Color3.fromRGB(110, 90, 130),
		Brightness     = 0.9,
		FogEnd         = 600,
		FogColor       = Color3.fromRGB(80, 60, 100),
	}, 2)
	Lighting.ClockTime = 6.5

	local atmo = Instance.new("Atmosphere")
	atmo.Density   = 0.45
	atmo.Offset    = 0.1
	atmo.Color     = Color3.fromRGB(140, 100, 160)
	atmo.Decay     = Color3.fromRGB(60, 40, 80)
	atmo.Glare     = 0.3
	atmo.Haze      = 1.5
	atmo.Parent    = Lighting
end

function SpaceEnv.applyDungeon()
	clearSky()
	clearSpaceAssets()

	tweenLighting({
		Ambient        = Color3.fromRGB(60, 60, 80),
		OutdoorAmbient = Color3.fromRGB(50, 50, 70),
		Brightness     = 0.4,
		FogEnd         = 200,
		FogColor       = Color3.fromRGB(20, 20, 35),
	}, 1.5)
	Lighting.ClockTime = 0
end

function SpaceEnv.applyFullBright()
	clearSky()
	clearSpaceAssets()

	tweenLighting({
		Ambient        = Color3.fromRGB(255, 255, 255),
		OutdoorAmbient = Color3.fromRGB(255, 255, 255),
		Brightness     = 4,
		FogEnd         = 5000,
		FogColor       = Color3.fromRGB(255, 255, 255),
	}, 0.5)
	Lighting.ClockTime = 12
end

return SpaceEnv
