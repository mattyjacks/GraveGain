local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))
local PathfindingService = game:GetService("PathfindingService")

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

local TILE = 4

function EnemySpawner.new()
	local self = setmetatable({}, EnemySpawner)

	self.enemies = {}
	self.maxEnemies = 20
	self.spawnCooldown = 0
	self.spawnRate = 2.5

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
	for i = 1, math.min(8, self.maxEnemies) do
		if math.random() > 0.5 then
			self:spawnSkull()
		else
			self:spawnSkeleton()
		end
	end
end

function EnemySpawner:update(dt)
	self.spawnCooldown = self.spawnCooldown - dt

	if self.spawnCooldown <= 0 and #self.enemies < self.maxEnemies then
		if self.dungeon then
			if math.random() > 0.4 then self:spawnSkull() else self:spawnSkeleton() end
		else
			if math.random() > 0.4 then self:spawnOpenWorldSkull() else self:spawnOpenWorldSkeleton() end
		end
		self.spawnCooldown = self.spawnRate
	end

	for i = #self.enemies, 1, -1 do
		local enemy = self.enemies[i]
		if not enemy.model or not enemy.model.Parent then
			table.remove(self.enemies, i)
		else
			self:updateEnemyAI(enemy, dt, gameManager)
		end
	end
end

function EnemySpawner:getRandomSpawnPosition()
	local offset = GameData.DUNGEON_CONFIG.offset
	if not self.dungeon or not self.dungeon.rooms or #self.dungeon.rooms == 0 then
		return Vector3.new(offset.X, 40, offset.Z)
	end

	local room = self.dungeon.rooms[math.random(1, #self.dungeon.rooms)]
	local x = room.x + math.random(1, math.max(1, room.width - 1))
	local y = room.y + math.random(1, math.max(1, room.height - 1))
	
	local worldX = offset.X + x * TILE
	local worldZ = offset.Z + y * TILE
	
	-- Raycast from high up to find the ground
	local rayOrigin = Vector3.new(worldX, 200, worldZ)
	local rayDir = Vector3.new(0, -250, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Exclude existing enemies to avoid stacking
	rayParams.FilterDescendantsInstances = {self.folder}
	
	local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
	local groundY = result and (result.Position.Y + 2) or 20
	
	return Vector3.new(worldX, groundY, worldZ)
end

function EnemySpawner:spawnOpenWorldSkull()
	local pos = self:getRandomOpenWorldSpawnPosition()
	if not pos then return end
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
		aggroRange = 100,
		path = nil,
		pathIndex = 1,
		pathPoints = {},
		lastPathTime = 0,
		attackCooldown = 0,
	})
end

function EnemySpawner:spawnOpenWorldSkeleton()
	local pos = self:getRandomOpenWorldSpawnPosition()
	if not pos then return end
	local skeleton = self:buildSkeletonModel(pos)
	table.insert(self.enemies, {
		type = "Skeleton",
		model = skeleton,
		root = skeleton.PrimaryPart,
		health = 50,
		maxHealth = 50,
		speed = 10 + math.random() * 3,
		target = nil,
		state = "wander",
		wanderDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit,
		wanderTimer = math.random() * 3,
		aggroRange = 100,
		path = nil,
		pathIndex = 1,
		pathPoints = {},
		lastPathTime = 0,
		attackCooldown = 0,
	})
end

function EnemySpawner:getRandomOpenWorldSpawnPosition()
	local players = game:GetService("Players"):GetPlayers()
	if #players == 0 then return nil end
	
	local targetPlayer = players[math.random(1, #players)]
	local char = targetPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	
	-- Spawn around player but not too close
	local angle = math.rad(math.random(0, 360))
	local dist = 40 + math.random(0, 40)
	local spawnX = hrp.Position.X + math.cos(angle) * dist
	local spawnZ = hrp.Position.Z + math.sin(angle) * dist
	
	local rayOrigin = Vector3.new(spawnX, 200, spawnZ)
	local rayDir = Vector3.new(0, -300, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
	if result then
		return result.Position + Vector3.new(0, 3, 0)
	end
	
	return nil
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
		aggroRange = 80,
		path = nil,
		pathIndex = 1,
		pathPoints = {},
		lastPathTime = 0,
		attackCooldown = 0,
	})
end

function EnemySpawner:spawnSkeleton()
	local pos = self:getRandomSpawnPosition()
	local skeleton = self:buildSkeletonModel(pos)
	table.insert(self.enemies, {
		type = "Skeleton",
		model = skeleton,
		root = skeleton.PrimaryPart,
		health = 50,
		maxHealth = 50,
		speed = 10 + math.random() * 3,
		target = nil,
		state = "wander",
		wanderDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit,
		wanderTimer = math.random() * 3,
		aggroRange = 90,
		path = nil,
		pathIndex = 1,
		pathPoints = {},
		lastPathTime = 0,
		attackCooldown = 0,
	})
end

function EnemySpawner:buildSkullModel(position)
	local model = Instance.new("Model")
	model.Name = "Skull"

	local rng = Random.new()
	local scale = rng:NextNumber(0.8, 1.3)

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
	cranium.Anchored = false
	cranium.CanCollide = true
	cranium.CFrame = CFrame.new(position)
	cranium.Parent = model

	local bgui = Instance.new("BillboardGui")
	bgui.Name = "NameTag"
	bgui.Adornee = cranium
	bgui.Size = UDim2.new(0, 100, 0, 40)
	bgui.StudsOffset = Vector3.new(0, 2, 0)
	bgui.AlwaysOnTop = true
	bgui.Parent = cranium
	
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.Text = "Skull"
	tl.TextColor3 = Color3.new(1, 0.2, 0.2)
	tl.TextStrokeTransparency = 0.5
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Parent = bgui

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 30
	hum.Health = 30
	hum.DisplayName = "Skull"
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.Parent = model

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

	model.PrimaryPart = cranium
	model:ScaleTo(scale)
	model.Parent = self.folder

	return model
end

function EnemySpawner:buildSkeletonModel(position)
	local model = Instance.new("Model")
	model.Name = "Skeleton"

	local boneColor = Color3.fromRGB(230, 225, 210)
	
	local function createPart(name, size, pos, parent)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(pos)
		p.Color = boneColor
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = false
		p.CanCollide = true
		p.Parent = parent
		return p
	end

	local hrp = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), position, model)
	hrp.Transparency = 1
	model.PrimaryPart = hrp

	local torso = createPart("Torso", Vector3.new(0.6, 2.2, 0.6), position, model) -- Spine
	local pelvis = createPart("Pelvis", Vector3.new(1.8, 0.4, 0.8), position + Vector3.new(0, -1, 0), model)
	
	local head = createPart("Head", Vector3.new(1.1, 1.2, 1.1), position + Vector3.new(0, 1.6, 0), model)
	
	local function weld(p0, p1, offset)
		local w = Instance.new("Weld")
		w.Part0 = p0
		w.Part1 = p1
		w.C0 = offset
		w.Parent = p0
	end

	weld(hrp, torso, CFrame.new())
	weld(torso, pelvis, CFrame.new(0, -1, 0))
	weld(torso, head, CFrame.new(0, 1.6, 0))

	-- Ribcage
	for i = 1, 4 do
		local ribY = 0.8 - (i * 0.4)
		local ribSize = 2.0 - (i * 0.2)
		local rib = createPart("Rib"..i, Vector3.new(ribSize, 0.15, 0.7), position + Vector3.new(0, ribY, 0), model)
		weld(torso, rib, CFrame.new(0, ribY, 0))
	end

	-- Arms and Legs
	local ra = createPart("Right Arm", Vector3.new(0.4, 2.2, 0.4), position + Vector3.new(1.2, 0.4, 0), model)
	local la = createPart("Left Arm", Vector3.new(0.4, 2.2, 0.4), position + Vector3.new(-1.2, 0.4, 0), model)
	local rl = createPart("Right Leg", Vector3.new(0.5, 2.4, 0.5), position + Vector3.new(0.5, -2.2, 0), model)
	local ll = createPart("Left Leg", Vector3.new(0.5, 2.4, 0.5), position + Vector3.new(-0.5, -2.2, 0), model)

	weld(torso, ra, CFrame.new(1.2, 0.4, 0))
	weld(torso, la, CFrame.new(-1.2, 0.4, 0))
	weld(pelvis, rl, CFrame.new(0.5, -1.2, 0))
	weld(pelvis, ll, CFrame.new(-0.5, -1.2, 0))

	-- Glowing Eyes
	for i = -1, 1, 2 do
		local eye = Instance.new("Part")
		eye.Name = (i == -1 and "Left" or "Right") .. "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.25, 0.25, 0.25)
		eye.Color = Color3.fromRGB(255, 0, 0)
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.Parent = model
		
		local ew = Instance.new("WeldConstraint")
		ew.Part0 = head; ew.Part1 = eye; ew.Parent = eye
		eye.CFrame = head.CFrame * CFrame.new(i * 0.25, 0.1, -0.45)
		
		local l = Instance.new("PointLight")
		l.Color = Color3.new(1, 0, 0)
		l.Brightness = 2
		l.Range = 4
		l.Parent = eye
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 50
	humanoid.Health = 50
	humanoid.DisplayName = "Skeleton"
	humanoid.HipHeight = 2.4
	humanoid.JumpPower = 50
	humanoid.Parent = model

	model.Parent = self.folder
	return model
end

function EnemySpawner:updateEnemyAI(enemy, dt)
	local root = enemy.root
	if not root or not root.Parent then return end
	local humanoid = enemy.model:FindFirstChild("Humanoid")
	if not humanoid then return end

	local players = game:GetService("Players"):GetPlayers()
	local nearestDist = math.huge
	local nearestPos = nil
	local nearestPlayer = nil

	for _, player in ipairs(players) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestPos = hrp.Position
					nearestPlayer = player
				end
			end
		end
	end

	if nearestPos and nearestDist < enemy.aggroRange then
		enemy.state = "chase"
		enemy.target = nearestPos
	else
		enemy.state = "wander"
		enemy.target = nil
	end

	-- Attack logic
	enemy.attackCooldown = math.max(0, (enemy.attackCooldown or 0) - dt)
	if nearestPlayer and nearestDist < 6 and enemy.attackCooldown <= 0 then
		enemy.attackCooldown = 1.5
		local damage = (enemy.type == "Skeleton" and 15 or 8)
		if gameManager then
			gameManager:handlePlayerDamage(nearestPlayer, damage, "Physical", root.Position)
		end
	end

	-- Pathfinding logic
	if enemy.state == "chase" and enemy.target then
		local now = tick()
		if now - enemy.lastPathTime > 0.5 then
			enemy.lastPathTime = now
			local path = PathfindingService:CreatePath({
				AgentRadius = 3,
				AgentHeight = 5,
				AgentCanJump = true,
			})
			
			local success, errorMessage = pcall(function()
				path:ComputeAsync(root.Position, enemy.target)
			end)

			if success and path.Status == Enum.PathStatus.Success then
				enemy.pathPoints = path:GetWaypoints()
				enemy.pathIndex = 2
			else
				-- Fallback to direct move if pathfinding fails
				enemy.pathPoints = { {Position = enemy.target} }
				enemy.pathIndex = 1
			end
		end

		if #enemy.pathPoints > 0 and enemy.pathIndex <= #enemy.pathPoints then
			local nextPoint = enemy.pathPoints[enemy.pathIndex]
			local moveDir = (nextPoint.Position - root.Position)
			
			if moveDir.Magnitude < 3 then
				enemy.pathIndex = enemy.pathIndex + 1
			else
				-- Jumping logic
				-- Jumping logic: Better detection for 2.5D terrain
				if nextPoint.Action == Enum.PathWaypointAction.Jump or (nextPoint.Position.Y - root.Position.Y) > 1.5 then
					humanoid.Jump = true
				end
				
				-- Procedural Wobble for Skeletons
				if enemy.type == "Skeleton" then
					enemy.wobbleTime = (enemy.wobbleTime or 0) + dt * 10
					local wobble = math.sin(enemy.wobbleTime) * 0.15
					local armWobble = math.cos(enemy.wobbleTime) * 0.3
					
					local ra = enemy.model:FindFirstChild("Right Arm")
					local la = enemy.model:FindFirstChild("Left Arm")
					if ra then ra.LocalTransparencyModifier = 0 end -- ensure visible
					
					-- We'll just let the Humanoid handle the move, but we can tilt the torso
					local torso = enemy.model:FindFirstChild("Torso")
					if torso then
						-- Simple tilt based on movement
						-- (This is hard with welds but we can try)
					end
				end
				
				-- Use moveDir to navigate
				if enemy.type == "Skull" then
					-- Hopping specialized logic
					self:handleSkullMovement(enemy, moveDir.Unit, dt)
				else
					humanoid:MoveTo(nextPoint.Position)
				end
			end
		end
	else
		-- Wander logic
		enemy.wanderTimer = enemy.wanderTimer - dt
		if enemy.wanderTimer <= 0 then
			enemy.wanderDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
			enemy.wanderTimer = 2 + math.random() * 3
		end
		
		if enemy.type == "Skull" then
			self:handleSkullMovement(enemy, enemy.wanderDir, dt)
		else
			humanoid:MoveTo(root.Position + enemy.wanderDir * 5)
		end
	end

	if humanoid.Health <= 0 then
		self:killEnemy(enemy)
	end
end

function EnemySpawner:handleSkullMovement(enemy, moveDir, dt)
	local root = enemy.root
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

		local hopDist = enemy.speed * dt
		local newPos = root.Position + moveDir * hopDist + Vector3.new(0, hopHeight - (root.Position.Y - getGroundY(root.Position)), 0)

		-- Update CFrame for all parts
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
end

function getGroundY(pos)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Exclude characters/enemies for accurate ground detection
	local result = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), rayParams)
	return result and result.Position.Y or pos.Y
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
