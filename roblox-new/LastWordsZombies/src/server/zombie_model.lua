-- Builds zombie model instances (normal and Big Word variants)

local ZombieModel = {}

local function MakePart(zombie, name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = zombie
	return p
end

local function Weld(torso, part, offset)
	part.CFrame = torso.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = torso
	w.Part1 = part
	w.Parent = torso
end

function ZombieModel.Build(isBigWord)
	local bigScale = isBigWord and 1.6 or 1.0
	local sx = (math.random(80, 120) / 100) * bigScale
	local sy = (math.random(85, 115) / 100) * bigScale
	local sz = sx

	local bodyColor  = isBigWord and Color3.new(0.05, 0.35, 0.05) or Color3.new(0.1, 0.4, 0.1)
	local eyeColor   = isBigWord and Color3.new(0.6, 1, 0)        or Color3.new(0, 1, 0.2)
	local clothColor = isBigWord and Color3.new(0.02, 0.2, 0.02)  or Color3.new(0.05, 0.22, 0.05)

	local zombie = Instance.new("Model")
	zombie.Name = isBigWord and "BigWordZombie" or "Zombie"

	local function part(name, w, h, d, color, mat)
		return MakePart(zombie, name, Vector3.new(w*sx, h*sy, d*sz), color, mat)
	end

	local torso    = part("Torso",    2,   2,   1,   bodyColor)
	local head     = part("Head",     1.5, 1.5, 1.5, bodyColor)
	local leftArm  = part("LeftArm",  0.8, 2,   0.8, bodyColor)
	local rightArm = part("RightArm", 0.8, 2,   0.8, bodyColor)
	local leftLeg  = part("LeftLeg",  0.8, 2.5, 0.8, clothColor)
	local rightLeg = part("RightLeg", 0.8, 2.5, 0.8, clothColor)
	local leftEye  = part("LeftEye",  0.3, 0.3, 0.1, eyeColor, Enum.Material.Neon)
	local rightEye = part("RightEye", 0.3, 0.3, 0.1, eyeColor, Enum.Material.Neon)

	zombie.PrimaryPart = torso
	torso.CFrame = CFrame.new(0, 0, 0)

	local tHY = torso.Size.Y / 2
	local hHY = head.Size.Y  / 2
	local aHY = leftArm.Size.Y / 2
	local lHY = leftLeg.Size.Y / 2
	local hHX = head.Size.X / 2

	Weld(torso, head,     CFrame.new(0,  tHY + hHY, 0))
	Weld(torso, leftArm,  CFrame.new(-(torso.Size.X/2 + leftArm.Size.X/2),  tHY - aHY, 0))
	Weld(torso, rightArm, CFrame.new( (torso.Size.X/2 + rightArm.Size.X/2), tHY - aHY, 0))
	Weld(torso, leftLeg,  CFrame.new(-torso.Size.X/4, -(tHY + lHY), 0))
	Weld(torso, rightLeg, CFrame.new( torso.Size.X/4, -(tHY + lHY), 0))
	Weld(torso, leftEye,  CFrame.new(-hHX * 0.4, tHY + hHY * 0.2, -(head.Size.Z/2 + 0.05*sz)))
	Weld(torso, rightEye, CFrame.new( hHX * 0.4, tHY + hHY * 0.2, -(head.Size.Z/2 + 0.05*sz)))

	-- Eye glow
	local eyeLight = Instance.new("PointLight")
	eyeLight.Color      = isBigWord and Color3.new(0.4, 1, 0) or Color3.new(0, 1, 0.2)
	eyeLight.Brightness = isBigWord and 4 or 2
	eyeLight.Range      = isBigWord and 14 or 8
	eyeLight.Parent = torso

	-- Crown for Big Word zombies
	if isBigWord then
		local crown = MakePart(zombie, "Crown",
			Vector3.new(1.6*sx, 0.4*sy, 1.6*sz),
			Color3.new(0.8, 0.6, 0), Enum.Material.Neon)
		Weld(torso, crown, CFrame.new(0, tHY + head.Size.Y + 0.2*sy, 0))
	end

	return zombie
end

-- Attach a word billboard above the zombie head
function ZombieModel.CreateWordDisplay(zombie, word)
	local head = zombie:FindFirstChild("Head") or zombie.PrimaryPart
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WordDisplay"
	billboard.Size = UDim2.new(0, 240, 0, 56)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = head

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.new(0, 1, 0.5)
	frame.Parent = billboard

	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.new(1, -10, 1, -6)
	label.Position = UDim2.new(0, 5, 0, 3)
	label.BackgroundTransparency = 1
	label.Text = word:upper()
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = frame

	return billboard
end

return ZombieModel
