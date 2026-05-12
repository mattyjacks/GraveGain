local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonDecorator = {}
DungeonDecorator.__index = DungeonDecorator
local TILE = 4
local WALL_HEIGHT = 6

function DungeonDecorator.new(dungeonRenderer)
	local self = setmetatable({}, DungeonDecorator)
	self.renderer = dungeonRenderer
	self.dungeon = dungeonRenderer.dungeon
	self.rng = dungeonRenderer.rng
	self.palette = dungeonRenderer.palette
	return self
end

function DungeonDecorator:pick(list)
	return self.renderer:pick(list)
end

function DungeonDecorator:renderDecorations(parent)
	local decoFolder = Instance.new("Folder")
	decoFolder.Name = "Decorations"
	decoFolder.Parent = parent

	for i, room in ipairs(self.dungeon.rooms) do
		if self.rng:NextNumber() < 0.6 then
			local lightType = self.rng:NextInteger(1, 4)
			if lightType == 1 then
				self:addTorch(room.centerX, room.centerY, decoFolder)
			elseif lightType == 2 then
				self:addLantern(room.centerX, room.centerY, decoFolder)
			elseif lightType == 3 then
				self:addBrazier(room.centerX, room.centerY, decoFolder)
			else
				self:addGlowingMushroom(room.centerX, room.centerY, decoFolder)
			end
		end
		if self.rng:NextNumber() < 0.3 then
			self:addCrystal(room, decoFolder)
		end
		if self.rng:NextNumber() < 0.4 then
			self:addWaterPool(room, decoFolder)
		end
	end
end

function DungeonDecorator:addFlowerOrDetail(x, y, parent)
	local flower = Instance.new("Part")
	flower.Shape = Enum.PartType.Ball
	flower.Anchored = true
	flower.CanCollide = false
	flower.Size = Vector3.new(0.6, 0.6, 0.6)
	local colors = {
		Color3.fromRGB(255, 50, 50),
		Color3.fromRGB(255, 255, 50),
		Color3.fromRGB(255, 100, 200),
		Color3.fromRGB(100, 200, 255),
		Color3.fromRGB(255, 150, 0),
	}
	flower.Color = colors[self.rng:NextInteger(1, #colors)]
	flower.Material = Enum.Material.SmoothPlastic
	local ox = (self.rng:NextNumber() - 0.5) * TILE * 0.7
	local oz = (self.rng:NextNumber() - 0.5) * TILE * 0.7
	flower.CFrame = CFrame.new(x * TILE + ox, 0.3, y * TILE + oz)
	flower.Parent = parent
end

function DungeonDecorator:addVine(x, y, parent)
	local vine = Instance.new("Part")
	vine.Shape = Enum.PartType.Block
	vine.Anchored = true
	vine.CanCollide = false
	local h = self.rng:NextNumber() * 3 + 1
	vine.Size = Vector3.new(0.4, h, 0.4)
	vine.Color = Color3.fromRGB(20, 120 + self.rng:NextInteger(0, 40), 20)
	vine.Material = Enum.Material.Grass
	local side = self.rng:NextInteger(1, 4)
	local ox, oz = 0, 0
	if side == 1 then ox = TILE / 2 - 0.2
	elseif side == 2 then ox = -TILE / 2 + 0.2
	elseif side == 3 then oz = TILE / 2 - 0.2
	else oz = -TILE / 2 + 0.2 end
	vine.CFrame = CFrame.new(x * TILE + ox, WALL_HEIGHT - h / 2, y * TILE + oz)
	vine.Parent = parent
end

function DungeonDecorator:addTorch(x, y, parent)
	local pole = Instance.new("Part")
	pole.Shape = Enum.PartType.Cylinder
	pole.Anchored = true
	pole.CanCollide = true
	pole.Size = Vector3.new(3, 0.4, 0.4)
	pole.Color = Color3.fromRGB(101, 67, 33)
	pole.Material = Enum.Material.Wood
	pole.CFrame = CFrame.new(x * TILE, 1.5, y * TILE) * CFrame.Angles(0, 0, math.rad(90))
	pole.Parent = parent

	local flame = Instance.new("Part")
	flame.Shape = Enum.PartType.Ball
	flame.Anchored = true
	flame.CanCollide = false
	flame.Size = Vector3.new(1.2, 1.2, 1.2)
	flame.Color = Color3.fromRGB(255, 150, 0)
	flame.Material = Enum.Material.Neon
	flame.CFrame = CFrame.new(x * TILE, 3.3, y * TILE)
	flame.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 50)
	light.Brightness = 2
	light.Range = 20
	light.Parent = flame
end

function DungeonDecorator:addLantern(x, y, parent)
	local pole = Instance.new("Part")
	pole.Shape = Enum.PartType.Cylinder
	pole.Anchored = true
	pole.CanCollide = true
	pole.Size = Vector3.new(4, 0.3, 0.3)
	pole.Color = Color3.fromRGB(50, 50, 50)
	pole.Material = Enum.Material.Metal
	pole.CFrame = CFrame.new(x * TILE, 2, y * TILE) * CFrame.Angles(0, 0, math.rad(90))
	pole.Parent = parent

	local hook = Instance.new("Part")
	hook.Shape = Enum.PartType.Block
	hook.Anchored = true
	hook.CanCollide = false
	hook.Size = Vector3.new(1.5, 0.2, 0.2)
	hook.Color = Color3.fromRGB(50, 50, 50)
	hook.Material = Enum.Material.Metal
	hook.CFrame = CFrame.new(x * TILE + 0.6, 3.9, y * TILE)
	hook.Parent = parent
	
	local lantern = Instance.new("Part")
	lantern.Shape = Enum.PartType.Block
	lantern.Anchored = true
	lantern.CanCollide = false
	lantern.Size = Vector3.new(0.8, 1.2, 0.8)
	lantern.Color = Color3.fromRGB(200, 200, 100)
	lantern.Material = Enum.Material.Glass
	lantern.Transparency = 0.4
	lantern.CFrame = CFrame.new(x * TILE + 1.2, 3.3, y * TILE)
	lantern.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 150)
	light.Brightness = 1.5
	light.Range = 25
	light.Parent = lantern
end

function DungeonDecorator:addBrazier(x, y, parent)
	local base = Instance.new("Part")
	base.Shape = Enum.PartType.Cylinder
	base.Anchored = true
	base.CanCollide = true
	base.Size = Vector3.new(1, 2, 2)
	base.Color = Color3.fromRGB(60, 60, 60)
	base.Material = Enum.Material.Metal
	base.CFrame = CFrame.new(x * TILE, 0.5, y * TILE) * CFrame.Angles(0, 0, math.rad(90))
	base.Parent = parent
	
	local bowl = Instance.new("Part")
	bowl.Shape = Enum.PartType.Cylinder
	bowl.Anchored = true
	bowl.CanCollide = true
	bowl.Size = Vector3.new(0.5, 2.5, 2.5)
	bowl.Color = Color3.fromRGB(40, 40, 40)
	bowl.Material = Enum.Material.Metal
	bowl.CFrame = CFrame.new(x * TILE, 1.25, y * TILE) * CFrame.Angles(0, 0, math.rad(90))
	bowl.Parent = parent

	local flame = Instance.new("Part")
	flame.Shape = Enum.PartType.Ball
	flame.Anchored = true
	flame.CanCollide = false
	flame.Size = Vector3.new(1.5, 1.5, 1.5)
	flame.Color = Color3.fromRGB(255, 100, 0)
	flame.Material = Enum.Material.Neon
	flame.CFrame = CFrame.new(x * TILE, 1.8, y * TILE)
	flame.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 50)
	light.Brightness = 2.5
	light.Range = 30
	light.Parent = flame
end

function DungeonDecorator:addGlowingMushroom(x, y, parent)
	local stem = Instance.new("Part")
	stem.Shape = Enum.PartType.Cylinder
	stem.Anchored = true
	stem.CanCollide = false
	stem.Size = Vector3.new(1.5, 0.4, 0.4)
	stem.Color = Color3.fromRGB(200, 200, 200)
	stem.Material = Enum.Material.Wood
	stem.CFrame = CFrame.new(x * TILE, 0.75, y * TILE) * CFrame.Angles(0, 0, math.rad(90))
	stem.Parent = parent

	local cap = Instance.new("Part")
	cap.Shape = Enum.PartType.Ball
	cap.Anchored = true
	cap.CanCollide = false
	cap.Size = Vector3.new(2, 1, 2)
	local colors = {
		Color3.fromRGB(50, 255, 150),
		Color3.fromRGB(50, 150, 255),
		Color3.fromRGB(200, 50, 255)
	}
	local c = colors[self.rng:NextInteger(1, #colors)]
	cap.Color = c
	cap.Material = Enum.Material.Neon
	cap.CFrame = CFrame.new(x * TILE, 1.5, y * TILE)
	cap.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = c
	light.Brightness = 1.5
	light.Range = 15
	light.Parent = cap
end

function DungeonDecorator:addCrystal(room, parent)
	local cx = room.x + self.rng:NextInteger(1, math.max(1, room.width - 1))
	local cy = room.y + self.rng:NextInteger(1, math.max(1, room.height - 1))

	local crystal = Instance.new("Part")
	crystal.Shape = Enum.PartType.Block
	crystal.Anchored = true
	crystal.CanCollide = false
	local h = self.rng:NextNumber() * 2 + 1
	crystal.Size = Vector3.new(0.6, h, 0.6)
	local pick = self:pick(self.palette.accent)
	crystal.Color = pick[1]
	crystal.Material = pick[2]
	crystal.CFrame = CFrame.new(cx * TILE, h / 2, cy * TILE) * CFrame.Angles(
		math.rad(self.rng:NextNumber() * 20 - 10),
		math.rad(self.rng:NextNumber() * 360),
		math.rad(self.rng:NextNumber() * 20 - 10)
	)
	crystal.Parent = parent

	local glow = Instance.new("PointLight")
	glow.Color = pick[1]
	glow.Brightness = 0.7
	glow.Range = 6
	glow.Parent = crystal
end

function DungeonDecorator:addWaterPool(room, parent)
	local px = room.x + self.rng:NextInteger(1, math.max(1, room.width - 2))
	local py = room.y + self.rng:NextInteger(1, math.max(1, room.height - 2))
	local w = self.rng:NextInteger(2, math.min(4, room.width - 1))
	local h = self.rng:NextInteger(2, math.min(4, room.height - 1))

	local pool = Instance.new("Part")
	pool.Shape = Enum.PartType.Block
	pool.Anchored = true
	pool.CanCollide = false
	pool.Size = Vector3.new(w * TILE * 0.5, 0.3, h * TILE * 0.5)
	pool.Color = Color3.fromRGB(30, 120, 200)
	pool.Material = Enum.Material.Glass
	pool.Transparency = 0.4
	pool.CFrame = CFrame.new(px * TILE, -0.1, py * TILE)
	pool.Parent = parent
end

function DungeonDecorator:renderLoot(parent)
	local lootFolder = Instance.new("Folder")
	lootFolder.Name = "Loot"
	lootFolder.Parent = parent
	
	if not self.dungeon.loot then return end
	
	for _, item in ipairs(self.dungeon.loot) do
		if item.type == "ammo_crate" then
			local crate = Instance.new("Part")
			crate.Name = "AmmoCrate"
			crate.Shape = Enum.PartType.Block
			crate.Size = Vector3.new(2.5, 2.5, 2.5)
			crate.Color = Color3.fromRGB(50, 200, 50)
			crate.Material = Enum.Material.Wood
			crate.Anchored = true
			crate.CFrame = CFrame.new(item.x * TILE, 1.25, item.y * TILE)
			crate.Parent = lootFolder
			
			local debounce = false
			crate.Touched:Connect(function(hit)
				if debounce then return end
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
				if player then
					debounce = true
					local ev = game:GetService("ReplicatedStorage"):FindFirstChild("RestoreAmmo")
					if ev then ev:FireClient(player) end
					crate:Destroy()
				end
			end)
		elseif item.type == "lore_item" then
			local book = Instance.new("Part")
			book.Name = "LoreBook"
			book.Shape = Enum.PartType.Block
			book.Size = Vector3.new(1.2, 0.4, 1.6)
			book.Color = Color3.fromRGB(150, 100, 50)
			book.Material = Enum.Material.Wood
			book.Anchored = true
			book.CFrame = CFrame.new(item.x * TILE, 0.2, item.y * TILE)
			book.Parent = lootFolder
			
			local pages = Instance.new("Part")
			pages.Shape = Enum.PartType.Block
			pages.Size = Vector3.new(1.0, 0.42, 1.4)
			pages.Color = Color3.fromRGB(240, 230, 200)
			pages.Material = Enum.Material.SmoothPlastic
			pages.Anchored = true
			pages.CFrame = book.CFrame
			pages.Parent = book
			
			local debounce = false
			book.Touched:Connect(function(hit)
				if debounce then return end
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
				if player then
					debounce = true
					local ev = game:GetService("ReplicatedStorage"):FindFirstChild("LorePickedUp")
					if ev then ev:FireClient(player, item.loreId) end
					
					local xpEvent = game:GetService("ReplicatedStorage"):FindFirstChild("LoreXPAwarded")
					if xpEvent then xpEvent:Fire(player, item.loreId) end
					
					book:Destroy()
				end
			end)
		end
	end
end

return DungeonDecorator
