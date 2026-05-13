-- dungeon_entrance_styles.lua (SERVER)
-- A library of 10 distinct architectural styles for dungeon entrances.
-- Each includes a ProximityPrompt for seamless transition into the dungeon interiors.

local DungeonEntranceStyles = {}

local function createBase(pos, name)
	local model = Instance.new("Model")
	model.Name = name or "DungeonEntrance"
	
	-- Raycast to find ground
	local rayOrigin = Vector3.new(pos.X, 300, pos.Z)
	local rayDir = Vector3.new(0, -500, 0)
	local result = workspace:Raycast(rayOrigin, rayDir)
	local groundY = result and result.Position.Y or 20
	
	local root = Instance.new("Part")
	root.Name = "EntranceRoot"
	root.Size = Vector3.new(15, 1, 15)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(pos.X, groundY + 0.5, pos.Z)
	root.Parent = model
	model.PrimaryPart = root
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Enter Dungeon"
	prompt.ObjectText = name
	prompt.HoldDuration = 2.0
	prompt.Parent = root
	
	-- Universal Label
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 200, 0, 50)
	bg.StudsOffset = Vector3.new(0, 15, 0)
	bg.AlwaysOnTop = false -- Prevents showing through the lobby floor
	bg.MaxDistance = 300
	bg.Parent = root
	local lbl = Instance.new("TextLabel", bg)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(200, 100, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 24
	lbl.Text = "☠ " .. name:upper()
	
	return model, root, prompt
end

-- 1. Ancient Archway
function DungeonEntranceStyles.AncientArchway(pos)
	local model, root, prompt = createBase(pos, "Ancient Vault")
	for i = -1, 1, 2 do
		local pillar = Instance.new("Part")
		pillar.Size = Vector3.new(6, 25, 6)
		pillar.Color = Color3.fromRGB(80, 80, 90)
		pillar.Material = Enum.Material.Slate
		pillar.CFrame = root.CFrame * CFrame.new(i * 10, 12, 0)
		pillar.Anchored = true; pillar.Parent = model
	end
	local lintel = Instance.new("Part")
	lintel.Size = Vector3.new(26, 6, 8)
	lintel.Color = Color3.fromRGB(60, 60, 70)
	lintel.Material = Enum.Material.Slate
	lintel.CFrame = root.CFrame * CFrame.new(0, 26, 0)
	lintel.Anchored = true; lintel.Parent = model

	local portal = Instance.new("Part")
	portal.Size = Vector3.new(14, 20, 1)
	portal.Color = Color3.fromRGB(150, 0, 255); portal.Material = Enum.Material.Neon
	portal.Transparency = 0.5; portal.CanCollide = false
	portal.CFrame = root.CFrame * CFrame.new(0, 10, 0)
	portal.Anchored = true; portal.Parent = model
	
	local light = Instance.new("PointLight", portal)
	light.Color = portal.Color; light.Range = 40; light.Brightness = 3
	
	return model
end

-- 2. Tech Bunker
function DungeonEntranceStyles.TechBunker(pos)
	local model, root, prompt = createBase(pos, "Sector-9 Bunker")
	local door = Instance.new("Part")
	door.Size = Vector3.new(16, 16, 4)
	door.Color = Color3.fromRGB(50, 50, 60)
	door.Material = Enum.Material.Metal
	door.CFrame = root.CFrame * CFrame.new(0, 8, 0)
	door.Anchored = true; door.Parent = model
	local neon = Instance.new("Part")
	neon.Size = Vector3.new(1, 16, 1)
	neon.Color = Color3.fromRGB(0, 255, 255); neon.Material = Enum.Material.Neon
	neon.CFrame = door.CFrame * CFrame.new(7.5, 0, 2.1)
	neon.Anchored = true; neon.Parent = model
	return model
end

-- 3. Overgrown Cave
function DungeonEntranceStyles.OvergrownCave(pos)
	local model, root, prompt = createBase(pos, "Viny Cavern")
	local mouth = Instance.new("Part")
	mouth.Shape = Enum.PartType.Ball
	mouth.Size = Vector3.new(25, 25, 25)
	mouth.Color = Color3.fromRGB(60, 50, 40); mouth.Material = Enum.Material.Rock
	mouth.CFrame = root.CFrame * CFrame.new(0, 0, 5)
	mouth.Anchored = true; mouth.Parent = model
	-- Vines
	for i = 1, 10 do
		local v = Instance.new("Part")
		v.Size = Vector3.new(0.5, 10 + math.random(0, 5), 0.5)
		v.Color = Color3.fromRGB(40, 80, 40); v.Material = Enum.Material.Grass
		v.CFrame = root.CFrame * CFrame.new(math.random(-10, 10), 15, -2)
		v.Anchored = true; v.Parent = model
	end
	return model
end

-- 4. Crystal Fissure
function DungeonEntranceStyles.CrystalFissure(pos)
	local model, root, prompt = createBase(pos, "Prism Depths")
	for i = 1, 8 do
		local c = Instance.new("Part")
		c.Size = Vector3.new(4, 15 + math.random(0, 10), 4)
		c.Color = Color3.fromRGB(150, 100, 255); c.Material = Enum.Material.Neon
		c.Transparency = 0.4
		c.CFrame = root.CFrame * CFrame.new(math.random(-10, 10), 5, math.random(-5, 5)) * CFrame.Angles(math.rad(math.random(-30, 30)), 0, 0)
		c.Anchored = true; c.Parent = model
	end
	return model
end

-- 5. Demon Gate
function DungeonEntranceStyles.DemonGate(pos)
	local model, root, prompt = createBase(pos, "Abyssal Gate")
	local frame = Instance.new("Part")
	frame.Size = Vector3.new(18, 30, 6)
	frame.Color = Color3.fromRGB(30, 10, 10); frame.Material = Enum.Material.Basalt
	frame.CFrame = root.CFrame * CFrame.new(0, 15, 0)
	frame.Anchored = true; frame.Parent = model
	
	local portal = Instance.new("Part")
	portal.Size = Vector3.new(12, 24, 1)
	portal.Color = Color3.fromRGB(255, 30, 0); portal.Material = Enum.Material.Neon
	portal.Transparency = 0.4; portal.CanCollide = false
	portal.CFrame = frame.CFrame * CFrame.new(0, 0, 0.1)
	portal.Anchored = true; portal.Parent = model
	
	local p = Instance.new("ParticleEmitter", portal)
	p.Texture = "rbxassetid://244221446"
	p.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
	p.Size = NumberSequence.new(2, 0)
	p.Lifetime = NumberRange.new(1, 2)
	p.Rate = 50; p.Speed = NumberRange.new(5, 10)
	
	return model
end

-- 6. Wrecked Spaceship
function DungeonEntranceStyles.WreckedSpaceship(pos)
	local model, root, prompt = createBase(pos, "Crash Site Alpha")
	local hull = Instance.new("Part")
	hull.Size = Vector3.new(30, 15, 40)
	hull.Color = Color3.fromRGB(150, 150, 160); hull.Material = Enum.Material.CorrodedMetal
	hull.CFrame = root.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(20), 0, 0)
	hull.Anchored = true; hull.Parent = model
	return model
end

-- 7. Sunken Temple
function DungeonEntranceStyles.SunkenTemple(pos)
	local model, root, prompt = createBase(pos, "Gilded Ruin")
	local pillar = Instance.new("Part")
	pillar.Size = Vector3.new(6, 12, 6)
	pillar.Color = Color3.fromRGB(220, 200, 150); pillar.Material = Enum.Material.Marble
	pillar.CFrame = root.CFrame * CFrame.new(0, 6, 0)
	pillar.Anchored = true; pillar.Parent = model
	return model
end

-- 8. Icy Crevasse
function DungeonEntranceStyles.IcyCrevasse(pos)
	local model, root, prompt = createBase(pos, "Frozen Maw")
	local ice = Instance.new("Part")
	ice.Size = Vector3.new(20, 20, 20)
	ice.Color = Color3.fromRGB(180, 220, 255); ice.Material = Enum.Material.Ice
	ice.CFrame = root.CFrame * CFrame.new(0, 5, 0)
	ice.Anchored = true; ice.Parent = model
	return model
end

-- 9. Magical Vortex
function DungeonEntranceStyles.MagicalVortex(pos)
	local model, root, prompt = createBase(pos, "Nexus Point")
	local core = Instance.new("Part")
	core.Shape = Enum.PartType.Ball; core.Size = Vector3.new(10, 10, 10)
	core.Color = Color3.fromRGB(200, 50, 255); core.Material = Enum.Material.Neon
	core.CFrame = root.CFrame * CFrame.new(0, 10, 0)
	core.Anchored = true; core.CanCollide = false; core.Parent = model
	return model
end

-- 10. Iron Mine
function DungeonEntranceStyles.IronMine(pos)
	local model, root, prompt = createBase(pos, "Rusty Shaft")
	local beam1 = Instance.new("Part")
	beam1.Size = Vector3.new(2, 15, 2); beam1.Color = Color3.fromRGB(80, 60, 40); beam1.Material = Enum.Material.Wood
	beam1.CFrame = root.CFrame * CFrame.new(-7, 7.5, 0); beam1.Anchored = true; beam1.Parent = model
	local beam2 = beam1:Clone(); beam2.CFrame = root.CFrame * CFrame.new(7, 7.5, 0); beam2.Parent = model
	local top = Instance.new("Part")
	top.Size = Vector3.new(16, 2, 2); top.Color = Color3.fromRGB(80, 60, 40); top.Material = Enum.Material.Wood
	top.CFrame = root.CFrame * CFrame.new(0, 15, 0); top.Anchored = true; top.Parent = model
	return model
end

function DungeonEntranceStyles.getRandomStyle(pos)
	local styles = {
		DungeonEntranceStyles.AncientArchway,
		DungeonEntranceStyles.TechBunker,
		DungeonEntranceStyles.OvergrownCave,
		DungeonEntranceStyles.CrystalFissure,
		DungeonEntranceStyles.DemonGate,
		DungeonEntranceStyles.WreckedSpaceship,
		DungeonEntranceStyles.SunkenTemple,
		DungeonEntranceStyles.IcyCrevasse,
		DungeonEntranceStyles.MagicalVortex,
		DungeonEntranceStyles.IronMine,
	}
	local style = styles[math.random(1, #styles)]
	return style(pos)
end

return DungeonEntranceStyles
