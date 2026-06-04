-- BattleSharks Ability Controller (D4)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameEnums = require(Shared:WaitForChild("Enums"):WaitForChild("GameEnums"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local AbilityController = {}
local player = Players.LocalPlayer
local abilities = {}
local cooldowns = {}
local abilityUI = {}

local ABILITY_DATA = {
	BasicAttack = { Name = "Bite", Cooldown = 0.8, Damage = 15, Range = 8, Key = Enum.KeyCode.MouseButton1, Icon = "🦈" },
	Boost = { Name = "Boost", Cooldown = 5, Duration = 2, SpeedMultiplier = 2, Key = Enum.KeyCode.LeftShift, Icon = "⚡" },
	Leap = { Name = "Leap", Cooldown = 3, Force = 150, Key = Enum.KeyCode.Space, Icon = "🌊" },
	Fighter_Rage = { Name = "Shark Rage", Cooldown = 15, Duration = 5, DamageMultiplier = 1.5, Key = Enum.KeyCode.Q, Icon = "😤", RequiredClass = "Fighter" },
	Ranger_Dash = { Name = "Swift Dash", Cooldown = 8, Distance = 50, Key = Enum.KeyCode.Q, Icon = "💨", RequiredClass = "Ranger" },
	Healer_Regen = { Name = "Regeneration", Cooldown = 20, Duration = 8, HealPerSecond = 10, Key = Enum.KeyCode.Q, Icon = "💚", RequiredClass = "Healer" }
}

function AbilityController.Initialize()
	UserInputService.InputBegan:Connect(AbilityController.OnInput)
	AbilityController.SetupAbilities()
	RunService.Heartbeat:Connect(AbilityController.UpdateCooldowns)
	GameUtilities.DebugPrint("AbilityController: Initialized")
end

function AbilityController.SetupAbilities()
	local remoteFolder = ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	local getDataFunc = remoteFolder:WaitForChild("GetPlayerData")
	if getDataFunc then
		local success, data = pcall(function() return getDataFunc:InvokeServer() end)
		if success and data then AbilityController.LoadClassAbilities(data.Class or "Fighter") end
	end
end

function AbilityController.LoadClassAbilities(className)
	abilityUI[1] = ABILITY_DATA.BasicAttack
	abilityUI[2] = ABILITY_DATA.Boost
	abilityUI[3] = ABILITY_DATA.Leap
	if className == "Fighter" then abilityUI[4] = ABILITY_DATA.Fighter_Rage
	elseif className == "Ranger" then abilityUI[4] = ABILITY_DATA.Ranger_Dash
	elseif className == "Healer" then abilityUI[4] = ABILITY_DATA.Healer_Regen end
	for i, ability in pairs(abilityUI) do cooldowns[ability.Name] = 0 end
end

function AbilityController.OnInput(input, gp)
	if gp then return end
	for _, ability in pairs(abilityUI) do
		if input.KeyCode == ability.Key or input.UserInputType == ability.Key then
			AbilityController.UseAbility(ability.Name)
			break
		end
	end
end

function AbilityController.UseAbility(name)
	local ability = nil
	for _, ab in pairs(abilityUI) do if ab.Name == name then ability = ab break end end
	if not ability then return false end
	if cooldowns[name] > 0 then return false end
	
	local remoteFolder = ReplicatedStorage:WaitForChild("BattleSharksRemotes")
	local character = player.Character
	if not character then return false end
	
	cooldowns[name] = ability.Cooldown
	
	if name == "Bite" then
		local event = remoteFolder:FindFirstChild("PlayerAttack")
		if event then
			local pos = character.PrimaryPart.Position + character.PrimaryPart.CFrame.LookVector * ability.Range
			event:FireServer(pos, "BasicAttack")
		end
	elseif name == "Boost" then
		local event = remoteFolder:FindFirstChild("PlayerBoost")
		if event then event:FireServer(character.PrimaryPart.CFrame.LookVector) end
	elseif name == "Leap" then
		character.PrimaryPart:ApplyImpulse(Vector3.new(0, ability.Force, 0))
	else
		local event = remoteFolder:FindFirstChild("PlayerAttack")
		if event then event:FireServer(nil, name) end
	end
	return true
end

function AbilityController.UpdateCooldowns(dt)
	for name, cd in pairs(cooldowns) do if cd > 0 then cooldowns[name] = math.max(0, cd - dt) end end
end

function AbilityController.GetCooldown(name) return cooldowns[name] or 0 end
function AbilityController.IsReady(name) return (cooldowns[name] or 0) <= 0 end

return AbilityController
