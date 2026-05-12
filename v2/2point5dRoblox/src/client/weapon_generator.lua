local WeaponGenerator = {}

-- Anchor all BaseParts in a model so they don't fall when the model is unparented.
-- We'll unanchor them again when actually welding to a character.
local function anchorModel(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end

function WeaponGenerator.createStick()
	local stick = Instance.new("Model")
	stick.Name = "WoodenStick"
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(4, 0.3, 0.3)
	handle.Color = Color3.fromRGB(120, 80, 40)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = stick
	
	stick.PrimaryPart = handle
	anchorModel(stick)
	return stick
end

function WeaponGenerator.createShield()
	local shield = Instance.new("Model")
	shield.Name = "WoodenShield"
	
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.4, 3, 3)
	base.Color = Color3.fromRGB(100, 60, 30)
	base.Material = Enum.Material.Wood
	base.CanCollide = false
	base.Massless = true
	base.Parent = shield
	
	local rim = Instance.new("Part")
	rim.Name = "Rim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.45, 3.2, 3.2)
	rim.Color = Color3.fromRGB(150, 150, 150)
	rim.Material = Enum.Material.Metal
	rim.CanCollide = false
	rim.Massless = true
	rim.CFrame = base.CFrame
	rim.Parent = shield
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = rim
	weld.Parent = base
	
	shield.PrimaryPart = base
	anchorModel(shield)
	return shield
end

function WeaponGenerator.createBow()
	local bow = Instance.new("Model")
	bow.Name = "WoodenBow"
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Block
	handle.Size = Vector3.new(0.2, 1.2, 0.4)
	handle.Color = Color3.fromRGB(80, 40, 20)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = bow
	
	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Shape = Enum.PartType.Block
	grip.Size = Vector3.new(0.25, 0.8, 0.45)
	grip.Color = Color3.fromRGB(40, 20, 10)
	grip.Material = Enum.Material.Fabric
	grip.CanCollide = false
	grip.Massless = true
	grip.CFrame = handle.CFrame
	grip.Parent = bow
	local gw = Instance.new("WeldConstraint", handle)
	gw.Part0 = handle
	gw.Part1 = grip
	
	local tl1 = Instance.new("Part")
	tl1.Shape = Enum.PartType.Block
	tl1.Size = Vector3.new(0.2, 1.0, 0.3)
	tl1.Color = Color3.fromRGB(120, 80, 40)
	tl1.Material = Enum.Material.Wood
	tl1.CanCollide = false
	tl1.Massless = true
	tl1.CFrame = handle.CFrame * CFrame.new(0, 1.0, 0.1) * CFrame.Angles(math.rad(15), 0, 0)
	tl1.Parent = bow
	local t1w = Instance.new("WeldConstraint", handle)
	t1w.Part0 = handle
	t1w.Part1 = tl1
	
	local tl2 = Instance.new("Part")
	tl2.Shape = Enum.PartType.Block
	tl2.Size = Vector3.new(0.2, 1.0, 0.2)
	tl2.Color = Color3.fromRGB(120, 80, 40)
	tl2.Material = Enum.Material.Wood
	tl2.CanCollide = false
	tl2.Massless = true
	tl2.CFrame = tl1.CFrame * CFrame.new(0, 0.9, -0.1) * CFrame.Angles(math.rad(25), 0, 0)
	tl2.Parent = bow
	local t2w = Instance.new("WeldConstraint", tl1)
	t2w.Part0 = tl1
	t2w.Part1 = tl2
	
	local bl1 = Instance.new("Part")
	bl1.Shape = Enum.PartType.Block
	bl1.Size = Vector3.new(0.2, 1.0, 0.3)
	bl1.Color = Color3.fromRGB(120, 80, 40)
	bl1.Material = Enum.Material.Wood
	bl1.CanCollide = false
	bl1.Massless = true
	bl1.CFrame = handle.CFrame * CFrame.new(0, -1.0, 0.1) * CFrame.Angles(math.rad(-15), 0, 0)
	bl1.Parent = bow
	local b1w = Instance.new("WeldConstraint", handle)
	b1w.Part0 = handle
	b1w.Part1 = bl1
	
	local bl2 = Instance.new("Part")
	bl2.Shape = Enum.PartType.Block
	bl2.Size = Vector3.new(0.2, 1.0, 0.2)
	bl2.Color = Color3.fromRGB(120, 80, 40)
	bl2.Material = Enum.Material.Wood
	bl2.CanCollide = false
	bl2.Massless = true
	bl2.CFrame = bl1.CFrame * CFrame.new(0, -0.9, -0.1) * CFrame.Angles(math.rad(-25), 0, 0)
	bl2.Parent = bow
	local b2w = Instance.new("WeldConstraint", bl1)
	b2w.Part0 = bl1
	b2w.Part1 = bl2
	
	local stringPart = Instance.new("Part")
	stringPart.Name = "String"
	stringPart.Shape = Enum.PartType.Cylinder
	stringPart.Size = Vector3.new(4.2, 0.05, 0.05)
	stringPart.Color = Color3.fromRGB(200, 200, 200)
	stringPart.Material = Enum.Material.Fabric
	stringPart.CanCollide = false
	stringPart.Massless = true
	stringPart.CFrame = handle.CFrame * CFrame.new(0, 0, -1.0) * CFrame.Angles(0, 0, math.rad(90))
	stringPart.Parent = bow
	local sw = Instance.new("WeldConstraint", handle)
	sw.Part0 = handle
	sw.Part1 = stringPart
	
	bow.PrimaryPart = handle
	anchorModel(bow)
	return bow
end

function WeaponGenerator.createPotion()
	local potion = Instance.new("Model")
	potion.Name = "HealthPotion"

	local bottle = Instance.new("Part")
	bottle.Name = "Bottle"
	bottle.Shape = Enum.PartType.Cylinder
	bottle.Size = Vector3.new(0.6, 0.4, 0.4)
	bottle.Color = Color3.fromRGB(200, 255, 200)
	bottle.Material = Enum.Material.Glass
	bottle.Transparency = 0.5
	bottle.CanCollide = false
	bottle.Massless = true
	bottle.CFrame = CFrame.Angles(0, 0, math.rad(90))
	bottle.Parent = potion

	local liquid = Instance.new("Part")
	liquid.Name = "Liquid"
	liquid.Shape = Enum.PartType.Cylinder
	liquid.Size = Vector3.new(0.4, 0.35, 0.35)
	liquid.Color = Color3.fromRGB(0, 255, 50)
	liquid.Material = Enum.Material.Neon
	liquid.CanCollide = false
	liquid.Massless = true
	liquid.CFrame = bottle.CFrame
	liquid.Parent = potion
	
	local lw = Instance.new("WeldConstraint", bottle)
	lw.Part0 = bottle
	lw.Part1 = liquid

	local neck = Instance.new("Part")
	neck.Name = "Neck"
	neck.Shape = Enum.PartType.Cylinder
	neck.Size = Vector3.new(0.3, 0.15, 0.15)
	neck.Color = Color3.fromRGB(200, 255, 200)
	neck.Material = Enum.Material.Glass
	neck.Transparency = 0.5
	neck.CanCollide = false
	neck.Massless = true
	neck.CFrame = bottle.CFrame * CFrame.new(0.45, 0, 0)
	neck.Parent = potion
	
	local nw = Instance.new("WeldConstraint", bottle)
	nw.Part0 = bottle
	nw.Part1 = neck

	local cork = Instance.new("Part")
	cork.Name = "Cork"
	cork.Shape = Enum.PartType.Cylinder
	cork.Size = Vector3.new(0.1, 0.16, 0.16)
	cork.Color = Color3.fromRGB(130, 90, 50)
	cork.Material = Enum.Material.Wood
	cork.CanCollide = false
	cork.Massless = true
	cork.CFrame = neck.CFrame * CFrame.new(0.15, 0, 0)
	cork.Parent = potion
	
	local cw = Instance.new("WeldConstraint", bottle)
	cw.Part0 = bottle
	cw.Part1 = cork

	potion.PrimaryPart = bottle
	anchorModel(potion)
	return potion
end

function WeaponGenerator.createFragGrenade()
	local grenade = Instance.new("Model")
	grenade.Name = "FragGrenade"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(0.6, 0.6, 0.6)
	body.Color = Color3.fromRGB(40, 50, 40)
	body.Material = Enum.Material.Metal
	body.CanCollide = false
	body.Massless = true
	body.Parent = grenade

	local pin = Instance.new("Part")
	pin.Name = "Pin"
	pin.Shape = Enum.PartType.Cylinder
	pin.Size = Vector3.new(0.2, 0.1, 0.1)
	pin.Color = Color3.fromRGB(150, 150, 150)
	pin.Material = Enum.Material.Metal
	pin.CanCollide = false
	pin.Massless = true
	pin.CFrame = body.CFrame * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.rad(90))
	pin.Parent = grenade
	
	local pw = Instance.new("WeldConstraint", body)
	pw.Part0 = body
	pw.Part1 = pin

	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.05, 0.3, 0.3)
	ring.Color = Color3.fromRGB(150, 150, 150)
	ring.Material = Enum.Material.Metal
	ring.CanCollide = false
	ring.Massless = true
	ring.CFrame = pin.CFrame * CFrame.new(0.1, 0, 0)
	ring.Parent = grenade
	
	local rw = Instance.new("WeldConstraint", body)
	rw.Part0 = body
	rw.Part1 = ring

	grenade.PrimaryPart = body
	anchorModel(grenade)
	return grenade
end

function WeaponGenerator.createFlashbang()
	local flashbang = Instance.new("Model")
	flashbang.Name = "Flashbang"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(0.8, 0.4, 0.4)
	body.Color = Color3.fromRGB(180, 180, 180)
	body.Material = Enum.Material.Metal
	body.CanCollide = false
	body.Massless = true
	body.CFrame = CFrame.Angles(0, 0, math.rad(90))
	body.Parent = flashbang

	local stripe = Instance.new("Part")
	stripe.Name = "Stripe"
	stripe.Shape = Enum.PartType.Cylinder
	stripe.Size = Vector3.new(0.2, 0.41, 0.41)
	stripe.Color = Color3.fromRGB(50, 50, 200)
	stripe.Material = Enum.Material.Metal
	stripe.CanCollide = false
	stripe.Massless = true
	stripe.CFrame = body.CFrame
	stripe.Parent = flashbang
	
	local sw = Instance.new("WeldConstraint", body)
	sw.Part0 = body
	sw.Part1 = stripe

	flashbang.PrimaryPart = body
	anchorModel(flashbang)
	return flashbang
end

function WeaponGenerator.createMolotov()
	local molotov = Instance.new("Model")
	molotov.Name = "Molotov"

	local bottle = Instance.new("Part")
	bottle.Name = "Bottle"
	bottle.Shape = Enum.PartType.Cylinder
	bottle.Size = Vector3.new(0.8, 0.4, 0.4)
	bottle.Color = Color3.fromRGB(50, 150, 50)
	bottle.Material = Enum.Material.Glass
	bottle.Transparency = 0.5
	bottle.CanCollide = false
	bottle.Massless = true
	bottle.CFrame = CFrame.Angles(0, 0, math.rad(90))
	bottle.Parent = molotov

	local rag = Instance.new("Part")
	rag.Name = "Rag"
	rag.Shape = Enum.PartType.Block
	rag.Size = Vector3.new(0.3, 0.15, 0.15)
	rag.Color = Color3.fromRGB(200, 200, 200)
	rag.Material = Enum.Material.Fabric
	rag.CanCollide = false
	rag.Massless = true
	rag.CFrame = bottle.CFrame * CFrame.new(0.5, 0, 0)
	rag.Parent = molotov
	
	local rw = Instance.new("WeldConstraint", bottle)
	rw.Part0 = bottle
	rw.Part1 = rag

	molotov.PrimaryPart = bottle
	anchorModel(molotov)
	return molotov
end

function WeaponGenerator.createArrow()
	local arrow = Instance.new("Model")
	arrow.Name = "WoodenArrow"
	
	local shaft = Instance.new("Part")
	shaft.Name = "Shaft"
	shaft.Shape = Enum.PartType.Cylinder
	shaft.Size = Vector3.new(3, 0.1, 0.1)
	shaft.Color = Color3.fromRGB(150, 100, 50)
	shaft.Material = Enum.Material.Wood
	shaft.CanCollide = false
	shaft.Massless = true
	shaft.Parent = arrow
	
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Shape = Enum.PartType.Block
	tip.Size = Vector3.new(0.4, 0.2, 0.2)
	tip.Color = Color3.fromRGB(100, 100, 100)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.Massless = true
	local tipMesh = Instance.new("SpecialMesh")
	tipMesh.MeshType = Enum.MeshType.FileMesh
	tipMesh.MeshId = "rbxassetid://1033714"
	tipMesh.Parent = tip
	tip.CFrame = shaft.CFrame * CFrame.new(1.5, 0, 0)
	tip.Parent = arrow
	
	local tipWeld = Instance.new("WeldConstraint")
	tipWeld.Part0 = shaft
	tipWeld.Part1 = tip
	tipWeld.Parent = shaft
	
	local fletching = Instance.new("Part")
	fletching.Name = "Fletching"
	fletching.Shape = Enum.PartType.Block
	fletching.Size = Vector3.new(0.5, 0.3, 0.05)
	fletching.Color = Color3.fromRGB(255, 255, 255)
	fletching.Material = Enum.Material.Fabric
	fletching.CanCollide = false
	fletching.Massless = true
	fletching.CFrame = shaft.CFrame * CFrame.new(-1.3, 0, 0)
	fletching.Parent = arrow
	
	local fWeld = Instance.new("WeldConstraint")
	fWeld.Part0 = shaft
	fWeld.Part1 = fletching
	fWeld.Parent = shaft
	
	arrow.PrimaryPart = shaft
	anchorModel(arrow)
	return arrow
end

return WeaponGenerator
