-- utility_handler.lua (CLIENT)
-- Handles race-specific utility abilities triggered by the "F" key.
-- Features: Flashlights, Flares, Magical Balls, Glowstones, Darkvision, and Torches.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameData = require(Shared:WaitForChild("game_data"))

local UtilityHandler = {}
UtilityHandler.__index = UtilityHandler

function UtilityHandler.new(playerStats)
	local self = setmetatable({}, UtilityHandler)
	self.stats = playerStats
	self.holdTime = 0
	self.isHolding = false
	self.flashlightActive = false
	self.darkvisionActive = false
	
	self.colorCorrection = Lighting:FindFirstChild("DarkvisionEffect") or Instance.new("ColorCorrectionEffect")
	self.colorCorrection.Name = "DarkvisionEffect"
	self.colorCorrection.Parent = Lighting
	self.colorCorrection.Enabled = false
	
	self:setupInputs()
	return self
end

function UtilityHandler:setupInputs()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.F then
			self.isHolding = true
			self.holdTime = tick()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.F then
			local duration = tick() - self.holdTime
			self.isHolding = false
			
			if duration < 0.4 then
				self:onTap()
			else
				self:onHold()
			end
		end
	end)
end

function UtilityHandler:onTap()
	local race = self.stats.raceName
	local char = Players.LocalPlayer.Character
	if not char then return end
	
	if race == "Human" then
		self:toggleFlashlight(char)
	elseif race == "Elf" then
		self:shootMagicBall(char)
	elseif race == "Dwarf" then
		self:throwGlowstone(char)
	elseif race == "Orc" then
		self:throwTorch(char)
	end
end

function UtilityHandler:onHold()
	local race = self.stats.raceName
	local char = Players.LocalPlayer.Character
	if not char then return end

	if race == "Human" then
		self:throwFlare(char)
	elseif race == "Elf" then
		self:toggleBrighteyes(char)
	elseif race == "Dwarf" then
		self:toggleDarkvision()
	elseif race == "Orc" then
		self:placeTorch(char)
	end
end

-- ── RACE ABILITIES ─────────────────────────────────────────────────────────

function UtilityHandler:toggleFlashlight(char)
	local head = char:FindFirstChild("Head")
	if not head then return end
	
	local existing = head:FindFirstChild("Flashlight")
	if existing then
		existing:Destroy()
		self.flashlightActive = false
	else
		local light = Instance.new("SpotLight")
		light.Name = "Flashlight"
		local config = GameData.RACE_UTILITIES.Human.flashlight
		light.Color = config.color
		light.Range = config.range
		light.Brightness = config.brightness
		light.Angle = 45
		light.Parent = head
		self.flashlightActive = true
	end
end

function UtilityHandler:throwFlare(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local flare = Instance.new("Part")
	flare.Size = Vector3.new(0.5, 2, 0.5)
	local config = GameData.RACE_UTILITIES.Human.flare
	flare.Color = config.color
	flare.Material = Enum.Material.Neon
	flare.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
	flare.Parent = workspace
	
	local light = Instance.new("PointLight", flare)
	light.Color = config.color
	light.Brightness = config.brightness
	light.Range = 40
	
	flare.Velocity = (hrp.CFrame.LookVector + Vector3.new(0, 0.5, 0)) * 50
	Debris:AddItem(flare, config.duration)
end

function UtilityHandler:toggleBrighteyes(char)
	local head = char:FindFirstChild("Head")
	if not head then return end
	
	local existing = head:FindFirstChild("BrighteyesL")
	if existing then
		existing:Destroy()
		head:FindFirstChild("BrighteyesR"):Destroy()
	else
		local config = GameData.RACE_UTILITIES.Elf.brighteyes
		for i = -1, 1, 2 do
			local l = Instance.new("SpotLight")
			l.Name = (i == -1) and "BrighteyesL" or "BrighteyesR"
			l.Color = config.color
			l.Range = config.range
			l.Brightness = config.brightness
			l.Angle = 30
			l.Parent = head
		end
	end
end

function UtilityHandler:shootMagicBall(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1, 1, 1)
	local config = GameData.RACE_UTILITIES.Elf.magicBall
	ball.Color = config.color
	ball.Material = Enum.Material.Neon
	ball.Transparency = 0.5
	ball.CanCollide = false
	ball.Anchored = false
	ball.CFrame = hrp.CFrame * CFrame.new(0, 1, -2)
	ball.Parent = workspace
	
	local light = Instance.new("PointLight", ball)
	light.Color = config.color
	light.Brightness = config.brightness
	light.Range = 25
	
	local vel = (Players.LocalPlayer:GetMouse().Hit.Position - ball.Position).Unit * 100
	ball.Velocity = vel
	
	ball.Touched:Connect(function(hit)
		if hit.Parent ~= char and not hit.Parent:IsA("Accessory") then
			ball.Anchored = true
			ball.Velocity = Vector3.new()
		end
	end)
	
	Debris:AddItem(ball, config.duration)
end

function UtilityHandler:toggleDarkvision()
	self.darkvisionActive = not self.darkvisionActive
	self.colorCorrection.Enabled = self.darkvisionActive
	self.colorCorrection.Saturation = GameData.RACE_UTILITIES.Dwarf.darkvision.saturation
	print("Darkvision:", self.darkvisionActive)
end

function UtilityHandler:throwGlowstone(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local stone = Instance.new("Part")
	stone.Size = Vector3.new(1, 1, 1)
	local config = GameData.RACE_UTILITIES.Dwarf.glowstone
	stone.Color = config.color
	stone.Material = Enum.Material.Neon
	stone.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
	stone.Parent = workspace
	
	local light = Instance.new("PointLight", stone)
	light.Color = config.color
	light.Brightness = config.brightness
	light.Range = 30
	
	stone.Velocity = (hrp.CFrame.LookVector + Vector3.new(0, 0.5, 0)) * 40
	Debris:AddItem(stone, config.duration)
end

function UtilityHandler:throwTorch(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local torch = Instance.new("Part")
	torch.Size = Vector3.new(0.5, 3, 0.5)
	local config = GameData.RACE_UTILITIES.Orc.torch
	torch.Color = Color3.fromRGB(100, 80, 60)
	torch.Material = Enum.Material.Wood
	torch.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
	torch.Parent = workspace
	
	local tip = Instance.new("Part")
	tip.Size = Vector3.new(0.6, 0.6, 0.6)
	tip.Color = config.color; tip.Material = Enum.Material.Neon
	tip.CFrame = torch.CFrame * CFrame.new(0, 1.5, 0)
	tip.Parent = torch
	local w = Instance.new("WeldConstraint"); w.Part0 = torch; w.Part1 = tip; w.Parent = tip
	
	local light = Instance.new("PointLight", tip)
	light.Color = config.color; light.Brightness = config.brightness; light.Range = 35
	
	local fire = Instance.new("Fire", tip)
	fire.Size = 4; fire.Heat = 5
	
	torch.Velocity = (hrp.CFrame.LookVector + Vector3.new(0, 0.6, 0)) * 45
	Debris:AddItem(torch, config.duration)
end

function UtilityHandler:placeTorch(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local torch = Instance.new("Part")
	torch.Size = Vector3.new(0.5, 4, 0.5)
	local config = GameData.RACE_UTILITIES.Orc.torch
	torch.Color = Color3.fromRGB(100, 80, 60); torch.Material = Enum.Material.Wood
	torch.Anchored = true
	torch.CFrame = hrp.CFrame * CFrame.new(0, -1, -3)
	torch.Parent = workspace
	
	local tip = Instance.new("Part")
	tip.Size = Vector3.new(0.6, 0.6, 0.6); tip.Color = config.color; tip.Material = Enum.Material.Neon
	tip.Anchored = true
	tip.CFrame = torch.CFrame * CFrame.new(0, 2, 0)
	tip.Parent = torch
	
	local light = Instance.new("PointLight", tip)
	light.Color = config.color; light.Brightness = config.brightness; light.Range = 40
	
	local fire = Instance.new("Fire", tip)
	fire.Size = 6; fire.Heat = 8
	
	Debris:AddItem(torch, config.duration)
end

return UtilityHandler
