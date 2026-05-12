local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local SM               = require(script.Parent:WaitForChild("sound_manager"))

local ItemHandler = {}
ItemHandler.__index = ItemHandler

function ItemHandler.new(inputHandler)
	local self = setmetatable({}, ItemHandler)
	self.inputHandler = inputHandler
	return self
end

function ItemHandler:consumeBuffItem()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 50)
		print("Consumed Healing Potion. Health:", humanoid.Health)
	end
end

-- Launch a grenade projectile using proper ballistic physics toward mouse.Hit
function ItemHandler:throwGrenade(cookTime, fuseRemaining, equipData)
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local mouse = player:GetMouse()
	local target = mouse.Hit and mouse.Hit.Position
	if not target then return end

	local grenadeType = (equipData and equipData.type) or "Frag"

	-- Create a simple projectile Part (not the full model – avoids PrimaryPart issues)
	local projectile = Instance.new("Part")
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(0.8, 0.8, 0.8)
	projectile.CanCollide = false -- avoid snagging on geometry while flying
	projectile.Massless = false
	projectile.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 1.5, 0))

	-- Color based on type
	if grenadeType == "Frag" then
		projectile.Color = Color3.fromRGB(40, 50, 40)
		projectile.Material = Enum.Material.Metal
	elseif grenadeType == "Flash" then
		projectile.Color = Color3.fromRGB(200, 200, 200)
		projectile.Material = Enum.Material.SmoothPlastic
	elseif grenadeType == "Molotov" then
		projectile.Color = Color3.fromRGB(50, 150, 50)
		projectile.Material = Enum.Material.Glass
		projectile.Transparency = 0.4
	end

	projectile.Parent = workspace

	-- Calculate ballistic velocity toward target (if not cooking in hand)
	if fuseRemaining > 0 then
		local origin = projectile.Position
		local dir = target - origin
		local flatDir = Vector3.new(dir.X, 0, dir.Z)
		local flatDist = flatDir.Magnitude
		if flatDist < 0.1 then flatDist = 0.1 end
		flatDir = flatDir.Unit

		local tFlight = math.max(0.5, math.min(1.8, flatDist / 30)) -- time to target
		local g = workspace.Gravity
		local vx = flatDir.X * (flatDist / tFlight)
		local vz = flatDir.Z * (flatDist / tFlight)
		local vy = (dir.Y + 0.5 * g * tFlight * tFlight) / tFlight

		projectile.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)
	end

	-- Enable collisions slightly after launch so it doesn't hit the player
	task.delay(0.1, function()
		if projectile.Parent then
			projectile.CanCollide = true
		end
	end)

	-- Explosion callback
	task.delay(fuseRemaining, function()
		if not projectile or not projectile.Parent then return end
		local pos = projectile.Position
		projectile:Destroy()

		if grenadeType == "Frag" then
			SM.Explosion()
			local explosion = Instance.new("Explosion")
			explosion.Position = pos
			explosion.BlastRadius = 15
			explosion.BlastPressure = 500000
			explosion.Parent = workspace

			-- Enemy damage
			local enemyFolder = workspace:FindFirstChild("Enemies")
			if enemyFolder then
				for _, enemy in ipairs(enemyFolder:GetChildren()) do
					local eHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
					if eHRP and (eHRP.Position - pos).Magnitude <= 15 then
						ReplicatedStorage.EnemyDamaged:FireServer(enemy, 50)
					end
				end
			end
			-- Self damage
			if (hrp.Position - pos).Magnitude <= 15 then
				local hum = character:FindFirstChild("Humanoid")
				if hum then hum:TakeDamage(50) end
			end

		elseif grenadeType == "Flash" then
			SM.Flashbang()
			-- Flash the screen if player is looking toward it
			local lookDir = hrp.CFrame.LookVector
			local toFlash = (pos - hrp.Position).Unit
			if (hrp.Position - pos).Magnitude <= 30 and lookDir:Dot(toFlash) > 0 then
				local flashGui = Instance.new("ScreenGui")
				flashGui.Parent = player.PlayerGui
				local f = Instance.new("Frame", flashGui)
				f.Size = UDim2.new(1, 0, 1, 0)
				f.BackgroundColor3 = Color3.new(1, 1, 1)
				f.BorderSizePixel = 0
				TweenService:Create(f, TweenInfo.new(3, Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
				game:GetService("Debris"):AddItem(flashGui, 3.5)
			end
			-- Stun/damage enemies
			local enemyFolder = workspace:FindFirstChild("Enemies")
			if enemyFolder then
				for _, enemy in ipairs(enemyFolder:GetChildren()) do
					local eHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
					if eHRP and (eHRP.Position - pos).Magnitude <= 20 then
						ReplicatedStorage.EnemyDamaged:FireServer(enemy, 5)
					end
				end
			end

		elseif grenadeType == "Molotov" then
			SM.MolotovBreak()
			SM.FireLoop()
			-- Fire pool on the ground
			local firePool = Instance.new("Part")
			firePool.Size = Vector3.new(10, 0.4, 10)
			firePool.Shape = Enum.PartType.Block
			firePool.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
			firePool.Color = Color3.fromRGB(200, 80, 0)
			firePool.Material = Enum.Material.Neon
			firePool.Anchored = true
			firePool.CanCollide = false
			firePool.Transparency = 0.4
			firePool.Parent = workspace
			local fire = Instance.new("Fire", firePool)
			fire.Size = 8
			fire.Color = Color3.fromRGB(255, 80, 0)
			fire.SecondaryColor = Color3.fromRGB(255, 200, 0)

			task.spawn(function()
				for _ = 1, 10 do
					task.wait(0.5)
					if not firePool.Parent then break end
					local enemyFolder = workspace:FindFirstChild("Enemies")
					if enemyFolder then
						for _, enemy in ipairs(enemyFolder:GetChildren()) do
							local eHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Root")
							if eHRP and (eHRP.Position - firePool.Position).Magnitude <= 7 then
								ReplicatedStorage.EnemyDamaged:FireServer(enemy, 10)
							end
						end
					end
					if (hrp.Position - firePool.Position).Magnitude <= 7 then
						local hum = character:FindFirstChild("Humanoid")
						if hum then hum:TakeDamage(10) end
					end
				end
				if firePool.Parent then firePool:Destroy() end
			end)
		end
	end)
end

return ItemHandler
