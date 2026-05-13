local RunService = game:GetService("RunService")

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

local TILE = 4

function EnemySpawner.new()
	local self = setmetatable({}, EnemySpawner)

	self.enemies = {}
	self.maxEnemies = 12
	self.spawnCooldown = 0
	self.spawnRate = 3

	local folder = workspace:FindFirstChild("Enemies")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Enemies"
		folder.Parent = workspace
	end
	self.folder = folder

	return self
end

function EnemySpawner:spawnInDungeon(dungeon)
	self.dungeon = dungeon
	for i = 1, math.min(6, self.maxEnemies) do
		self:spawnSkull()
	end
end

function EnemySpawner:update(dt)
	if not self.dungeon then return end
	
	self.spawnCooldown = self.spawnCooldown - dt

	if self.spawnCooldown <= 0 and #self.enemies < self.maxEnemies then
		self:spawnSkull()
		self.spawnCooldown = self.spawnRate
	end

	for i = #self.enemies, 1, -1 do
		local enemy = self.enemies[i]
		if not enemy.model or not enemy.model.Parent then
			table.remove(self.enemies, i)
		else
			self:updateSkullAI(enemy, dt)
		end
	end
end

function EnemySpawner:getRandomSpawnPosition()
	if not self.dungeon or not self.dungeon.rooms or #self.dungeon.rooms == 0 then
		return Vector3.new(0, 2, 0)
	end

	local room = self.dungeon.rooms[math.random(1, #self.dungeon.rooms)]
	local x = room.x + math.random(1, math.max(1, room.width - 1))
	local y = room.y + math.random(1, math.max(1, room.height - 1))
	return Vector3.new(x * TILE, 2, y * TILE)
end

function EnemySpawner:spawnSkull()
	local pos = self:getRandomSpawnPosition()
	local skull = self:buildSkullModel(pos)
	table.insert(self.enemies, {
		model = skull,
		root = skull:FindFirstChild("Root"),
		health = 30,
		maxHealth = 30,
		speed = 8 + math.random() * 4,
		hopTimer = 0,
		hopInterval = 0.6 + math.random() * 0.4,
		isHopping = false,
		hopPhase = 0,
		target = nil,
		state = "wander",
		wanderDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit,
		wanderTimer = math.random() * 3,
		aggroRange = 25,
	})
end

function EnemySpawner:buildSkullModel(position)
	local model = Instance.new("Model")
	model.Name = "Skull"

	local rng = Random.new()

	local skullColor = Color3.fromRGB(
		220 + rng:NextInteger(0, 35),
		210 + rng:NextInteger(0, 30),
		180 + rng:NextInteger(0, 30)
	)

	local cranium = Instance.new("Part")
	cranium.Name = "Root"
	cranium.Shape = Enum.PartType.Ball
	cranium.Size = Vector3.new(2.4, 2.2, 2.2)
	cranium.Color = skullColor
	cranium.Material = Enum.Material.SmoothPlastic
	cranium.Anchored = true
	cranium.CanCollide = true
	cranium.CFrame = CFrame.new(position)
	cranium.Parent = model

	local jaw = Instance.new("Part")
	jaw.Shape = Enum.PartType.Block
	jaw.Size = Vector3.new(1.6, 0.6, 1.4)
	jaw.Color = skullColor
	jaw.Material = Enum.Material.SmoothPlastic
	jaw.Anchored = false
	jaw.CanCollide = false
	jaw.TopSurface = Enum.SurfaceType.Smooth
	jaw.BottomSurface = Enum.SurfaceType.Smooth
	jaw.CFrame = CFrame.new(position + Vector3.new(0, -0.9, 0.2))
	jaw.Parent = model
	local jawWeld = Instance.new("WeldConstraint")
	jawWeld.Part0 = cranium
	jawWeld.Part1 = jaw
	jawWeld.Parent = jaw

	local leftEye = Instance.new("Part")
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.6, 0.6, 0.4)
	leftEye.Color = Color3.fromRGB(255, 0, 0)
	leftEye.Material = Enum.Material.Neon
	leftEye.Anchored = false
	leftEye.CanCollide = false
	leftEye.TopSurface = Enum.SurfaceType.Smooth
	leftEye.BottomSurface = Enum.SurfaceType.Smooth
	leftEye.CFrame = CFrame.new(position + Vector3.new(-0.45, 0.1, -1.0))
	leftEye.Parent = model
	local leftEyeWeld = Instance.new("WeldConstraint")
	leftEyeWeld.Part0 = cranium
	leftEyeWeld.Part1 = leftEye
	leftEyeWeld.Parent = leftEye

	local rightEye = Instance.new("Part")
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.6, 0.6, 0.4)
	rightEye.Color = Color3.fromRGB(255, 0, 0)
	rightEye.Material = Enum.Material.Neon
	rightEye.Anchored = false
	rightEye.CanCollide = false
	rightEye.CFrame = CFrame.new(position + Vector3.new(0.45, 0.1, -1.0))
	rightEye.Parent = model
	
	local rightEyeWeld = Instance.new("WeldConstraint")
	rightEyeWeld.Part0 = cranium
	rightEyeWeld.Part1 = rightEye
	rightEyeWeld.Parent = rightEye

	-- ── Skeleton Weapons ──
	local weaponTypes = {"Sword", "Axe", "Mace", "Hammer"}
	local weaponType = weaponTypes[math.random(#weaponTypes)]
	local weapon = Instance.new("Model")
	weapon.Name = weaponType .. "Weapon"
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 2.5, 0.4)
	handle.Color = Color3.fromRGB(100, 70, 40)
	handle.Material = Enum.Material.Wood
	handle.Parent = weapon
	
	local blade = Instance.new("Part")
	blade.Color = Color3.fromRGB(150, 150, 160)
	blade.Material = Enum.Material.Metal
	blade.Parent = weapon
	
	if weaponType == "Sword" then
		blade.Size = Vector3.new(0.2, 4, 0.6)
		blade.CFrame = handle.CFrame * CFrame.new(0, 3, 0)
	elseif weaponType == "Axe" then
		blade.Size = Vector3.new(1.5, 1.2, 0.3)
		blade.CFrame = handle.CFrame * CFrame.new(0.6, 1.2, 0)
	elseif weaponType == "Mace" then
		blade.Shape = Enum.PartType.Ball
		blade.Size = Vector3.new(1.2, 1.2, 1.2)
		blade.CFrame = handle.CFrame * CFrame.new(0, 1.2, 0)
	elseif weaponType == "Hammer" then
		blade.Size = Vector3.new(1.8, 1.0, 1.2)
		blade.CFrame = handle.CFrame * CFrame.new(0, 1.2, 0)
	end
	
	local bw = Instance.new("WeldConstraint")
	bw.Part0 = handle; bw.Part1 = blade; bw.Parent = handle
	
	weapon.PrimaryPart = handle
	weapon.Parent = model
	
	local ww = Instance.new("WeldConstraint")
	ww.Part0 = cranium
	ww.Part1 = handle
	ww.Parent = handle
	handle.CFrame = cranium.CFrame * CFrame.new(1.8, -0.5, -0.5) * CFrame.Angles(math.rad(-90), 0, 0)
	
	for _, p in ipairs(weapon:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false; p.Anchored = false end
	end

	local leftGlow = Instance.new("PointLight")
	leftGlow.Color = Color3.fromRGB(255, 50, 0)
	leftGlow.Brightness = 1
	leftGlow.Range = 4
	leftGlow.Parent = leftEye

	local nose = Instance.new("Part")
	nose.Shape = Enum.PartType.Block
	nose.Size = Vector3.new(0.3, 0.4, 0.2)
	nose.Color = Color3.fromRGB(40, 40, 40)
	nose.Material = Enum.Material.SmoothPlastic
	nose.Anchored = false
	nose.CanCollide = false
	nose.TopSurface = Enum.SurfaceType.Smooth
	nose.BottomSurface = Enum.SurfaceType.Smooth
	nose.CFrame = CFrame.new(position + Vector3.new(0, -0.2, -1.05))
	nose.Parent = model
	local noseWeld = Instance.new("WeldConstraint")
	noseWeld.Part0 = cranium
	noseWeld.Part1 = nose
	noseWeld.Parent = nose

	for i = 1, 6 do
		local tooth = Instance.new("Part")
		tooth.Shape = Enum.PartType.Block
		tooth.Size = Vector3.new(0.15, 0.25, 0.15)
		tooth.Color = Color3.fromRGB(240, 240, 220)
		tooth.Material = Enum.Material.SmoothPlastic
		tooth.Anchored = false
		tooth.CanCollide = false
		tooth.TopSurface = Enum.SurfaceType.Smooth
		tooth.BottomSurface = Enum.SurfaceType.Smooth
		local tx = (i - 3.5) * 0.22
		tooth.CFrame = CFrame.new(position + Vector3.new(tx, -0.7, -0.85))
		tooth.Parent = model
		local toothWeld = Instance.new("WeldConstraint")
		toothWeld.Part0 = cranium
		toothWeld.Part1 = tooth
		toothWeld.Parent = tooth
	end

	if rng:NextNumber() < 0.4 then
		local crack = Instance.new("Part")
		crack.Shape = Enum.PartType.Block
		crack.Size = Vector3.new(0.1, 0.8, 0.1)
		crack.Color = Color3.fromRGB(60, 50, 40)
		crack.Material = Enum.Material.SmoothPlastic
		crack.Anchored = false
		crack.CanCollide = false
		crack.CFrame = CFrame.new(position + Vector3.new(0.5, 0.5, -0.6)) * CFrame.Angles(0, 0, math.rad(20))
		crack.Parent = model
		local crackWeld = Instance.new("WeldConstraint")
		crackWeld.Part0 = cranium
		crackWeld.Part1 = crack
		crackWeld.Parent = crack
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 30
	humanoid.Health = 30
	humanoid.Parent = model

	model.PrimaryPart = cranium
	model.Parent = self.folder

	return model
end

function EnemySpawner:updateSkullAI(enemy, dt)
	local root = enemy.root
	if not root then return end

	local players = game:GetService("Players"):GetPlayers()
	local nearestDist = math.huge
	local nearestPos = nil

	for _, player in ipairs(players) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestPos = hrp.Position
				end
			end
		end
	end

	if nearestPos and nearestDist < enemy.aggroRange then
		enemy.state = "chase"
		enemy.target = nearestPos
	else
		enemy.state = "wander"
	end

	enemy.hopTimer = enemy.hopTimer + dt
	if enemy.hopTimer >= enemy.hopInterval then
		enemy.hopTimer = 0
		enemy.isHopping = true
		enemy.hopPhase = 0
	end

	if enemy.isHopping then
		enemy.hopPhase = enemy.hopPhase + dt * 8

		local hopHeight = math.sin(enemy.hopPhase) * 1.5
		if hopHeight < 0 then
			hopHeight = 0
			enemy.isHopping = false
		end

		local moveDir
		if enemy.state == "chase" and enemy.target then
			moveDir = (enemy.target - root.Position)
			moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
			if moveDir.Magnitude > 0.1 then
				moveDir = moveDir.Unit
			else
				moveDir = Vector3.new(0, 0, 0)
			end
		else
			enemy.wanderTimer = enemy.wanderTimer - dt
			if enemy.wanderTimer <= 0 then
				enemy.wanderDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
				enemy.wanderTimer = 2 + math.random() * 3
			end
			moveDir = enemy.wanderDir
		end

		local hopDist = enemy.speed * dt
		local newPos = root.Position + moveDir * hopDist + Vector3.new(0, hopHeight - root.Position.Y + 2, 0)

		local lookTarget = root.Position + moveDir * 5
		local newCFrame = CFrame.lookAt(newPos, Vector3.new(lookTarget.X, newPos.Y, lookTarget.Z))

		for _, part in ipairs(enemy.model:GetDescendants()) do
			if part:IsA("BasePart") then
				local offset = root.CFrame:ToObjectSpace(part.CFrame)
				part.CFrame = newCFrame * offset
			end
		end

		root.CFrame = newCFrame
	end

	local hum = enemy.model:FindFirstChild("Humanoid")
	if hum and hum.Health <= 0 then
		self:killEnemy(enemy)
	end
end

function EnemySpawner:killEnemy(enemy)
	if enemy.model then
		for _, part in ipairs(enemy.model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(
					math.random() * 20 - 10,
					math.random() * 15 + 5,
					math.random() * 20 - 10
				)
				bv.MaxForce = Vector3.new(10000, 10000, 10000)
				bv.Parent = part
				game:GetService("Debris"):AddItem(bv, 0.3)
			end
		end
		game:GetService("Debris"):AddItem(enemy.model, 2)
	end
end

return EnemySpawner
