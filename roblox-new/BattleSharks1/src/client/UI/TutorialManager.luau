-- BattleSharks Tutorial Manager (E1)
-- Interactive onboarding and tutorial system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local TutorialManager = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tutorialUI = nil
local currentStep = 0
local tutorialActive = false

-- TUTORIAL STEPS
local TUTORIAL_STEPS = {
	{
		Id = "welcome",
		Title = "Welcome to BattleSharks!",
		Text = "You're a shark in a vast ocean. Hunt, evolve, and dominate!",
		Duration = 5,
		Highlight = nil,
		Action = nil
	},
	{
		Id = "movement",
		Title = "Movement",
		Text = "Use W/A/S/D to swim. Hold Left Shift to boost!",
		Duration = 8,
		Highlight = nil,
		Action = "boost"
	},
	{
		Id = "combat",
		Title = "Combat",
		Text = "Click to bite enemies. Get close for maximum damage!",
		Duration = 8,
		Highlight = nil,
		Action = "attack"
	},
	{
		Id = "hunger",
		Title = "Hunger System",
		Text = "Watch your hunger bar! Eat fish or food items to survive.",
		Duration = 6,
		Highlight = "HungerBar",
		Action = nil
	},
	{
		Id = "inventory",
		Title = "Inventory",
		Text = "Press [I] to open your inventory and use items!",
		Duration = 6,
		Highlight = nil,
		Action = "inventory"
	},
	{
		Id = "aquarium",
		Title = "Aquarium Mode",
		Text = "Press [A] to visit your aquarium. Feed and decorate!",
		Duration = 6,
		Highlight = nil,
		Action = "aquarium"
	},
	{
		Id = "complete",
		Title = "You're Ready!",
		Text = "Complete quests, level up, and become the apex predator!",
		Duration = 5,
		Highlight = nil,
		Action = nil
	}
}

-- INITIALIZATION
function TutorialManager.Initialize()
	GameUtilities.DebugPrint("TutorialManager: Initializing")
	
	-- Check if player has completed tutorial
	local completed = TutorialManager.HasCompletedTutorial()
	if not completed then
		TutorialManager.StartTutorial()
	end
	
	GameUtilities.DebugPrint("TutorialManager: Initialized")
end

function TutorialManager.HasCompletedTutorial()
	-- Check local storage or server data
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local getDataFunc = remoteFolder:FindFirstChild("GetPlayerData")
		if getDataFunc then
			local success, data = pcall(function() return getDataFunc:InvokeServer() end)
			if success and data then
				return data.TutorialCompleted or false
			end
		end
	end
	return false
end

function TutorialManager.StartTutorial()
	if tutorialActive then return end
	tutorialActive = true
	currentStep = 1
	
	TutorialManager.CreateTutorialUI()
	TutorialManager.ShowStep(currentStep)
end

function TutorialManager.CreateTutorialUI()
	tutorialUI = Instance.new("ScreenGui")
	tutorialUI.Name = "TutorialUI"
	tutorialUI.ResetOnSpawn = false
	tutorialUI.Parent = playerGui
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "TutorialFrame"
	frame.Size = UDim2.new(0, 500, 0, 200)
	frame.Position = UDim2.new(0.5, -250, 0.8, -100)
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = tutorialUI
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 0.8, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.Text = ""
	title.Parent = frame
	
	-- Text
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.new(1, -40, 0, 80)
	text.Position = UDim2.new(0, 20, 0, 60)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.Gotham
	text.TextSize = 18
	text.TextWrapped = true
	text.Text = ""
	text.Parent = frame
	
	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -40, 0, 8)
	progressBg.Position = UDim2.new(0, 20, 1, -25)
	progressBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = frame
	
	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.Size = UDim2.new(0, 0, 1, 0)
	progress.BackgroundColor3 = Color3.new(0, 0.8, 0.2)
	progress.BorderSizePixel = 0
	progress.Parent = progressBg
	
	-- Skip button
	local skipBtn = Instance.new("TextButton")
	skipBtn.Size = UDim2.new(0, 80, 0, 30)
	skipBtn.Position = UDim2.new(1, -90, 0, 10)
	skipBtn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
	skipBtn.Text = "Skip"
	skipBtn.TextColor3 = Color3.new(1, 1, 1)
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.TextSize = 14
	skipBtn.Parent = frame
	
	skipBtn.MouseButton1Click:Connect(TutorialManager.SkipTutorial)
end

function TutorialManager.ShowStep(stepNum)
	local step = TUTORIAL_STEPS[stepNum]
	if not step then
		TutorialManager.CompleteTutorial()
		return
	end
	
	local frame = tutorialUI:FindFirstChild("TutorialFrame")
	if not frame then return end
	
	frame.Visible = true
	frame:FindFirstChild("Title").Text = step.Title
	frame:FindFirstChild("Text").Text = step.Text
	
	-- Update progress
	local progress = frame:FindFirstChild("ProgressBg"):FindFirstChild("Progress")
	progress.Size = UDim2.new(stepNum / #TUTORIAL_STEPS, 0, 1, 0)
	
	-- Highlight element if specified
	if step.Highlight then
		TutorialManager.HighlightElement(step.Highlight)
	end
	
	-- Wait for action or duration
	if step.Action then
		TutorialManager.WaitForAction(step.Action, step.Duration)
	else
		task.delay(step.Duration, function()
			if tutorialActive then
				TutorialManager.NextStep()
			end
		end)
	end
end

function TutorialManager.WaitForAction(actionName, maxDuration)
	local actionCompleted = false
	
	local connection
	connection = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		
		local actionKeys = {
			boost = Enum.KeyCode.LeftShift,
			attack = Enum.UserInputType.MouseButton1,
			inventory = Enum.KeyCode.I,
			aquarium = Enum.KeyCode.A
		}
		
		if input.KeyCode == actionKeys[actionName] or input.UserInputType == actionKeys[actionName] then
			actionCompleted = true
			connection:Disconnect()
			TutorialManager.NextStep()
		end
	end)
	
	-- Timeout
	task.delay(maxDuration, function()
		if not actionCompleted then
			connection:Disconnect()
			TutorialManager.NextStep()
		end
	end)
end

function TutorialManager.NextStep()
	currentStep += 1
	TutorialManager.ShowStep(currentStep)
end

function TutorialManager.HighlightElement(elementName)
	-- Find and highlight UI element
	local ui = playerGui:FindFirstChild("BattleSharksUI")
	if ui then
		local element = ui:FindFirstChild(elementName, true)
		if element then
			-- Create highlight effect
			local highlight = Instance.new("Frame")
			highlight.Name = "Highlight"
			highlight.Size = UDim2.new(1, 10, 1, 10)
			highlight.Position = UDim2.new(0, -5, 0, -5)
			highlight.BackgroundColor3 = Color3.new(1, 0.8, 0)
			highlight.BackgroundTransparency = 0.5
			highlight.BorderSizePixel = 0
			highlight.ZIndex = element.ZIndex - 1
			highlight.Parent = element
			
			-- Animate
			TweenService:Create(highlight, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
				BackgroundTransparency = 0.8
			}):Play()
			
			-- Auto remove
			task.delay(5, function()
				if highlight then highlight:Destroy() end
			end)
		end
	end
end

function TutorialManager.SkipTutorial()
	tutorialActive = false
	if tutorialUI then
		tutorialUI:Destroy()
		tutorialUI = nil
	end
	TutorialManager.MarkTutorialCompleted()
end

function TutorialManager.CompleteTutorial()
	tutorialActive = false
	
	-- Show completion reward
	local frame = tutorialUI:FindFirstChild("TutorialFrame")
	if frame then
		frame:FindFirstChild("Title").Text = "Tutorial Complete!"
		frame:FindFirstChild("Text").Text = "You earned 100 Gold and a Starter Pack!"
		
		task.delay(3, function()
			if tutorialUI then
				tutorialUI:Destroy()
				tutorialUI = nil
			end
		end)
	end
	
	-- Give rewards
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local claimEvent = remoteFolder:FindFirstChild("ClaimDailyReward")
		if claimEvent then
			-- Use same event to give starter gold
		end
	end
	
	TutorialManager.MarkTutorialCompleted()
end

function TutorialManager.MarkTutorialCompleted()
	local remoteFolder = ReplicatedStorage:FindFirstChild("BattleSharksRemotes")
	if remoteFolder then
		local saveEvent = remoteFolder:FindFirstChild("SaveGameData")
		if saveEvent then
			saveEvent:FireServer({TutorialCompleted = true})
		end
	end
end

function TutorialManager.Cleanup()
	if tutorialUI then
		tutorialUI:Destroy()
	end
	tutorialActive = false
	currentStep = 0
end

return TutorialManager
