-- Word Dictionary UI for displaying defeated words at game end
-- Shows an educational dictionary of all words the player typed correctly

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WordDefinitions = require(ReplicatedStorage:WaitForChild("WordDefinitions"))

local WordDictionaryUI = {}

-- UI state
local dictionaryUI = nil
local isVisible = false
local defeatedWords = {}

-- Colors for different word difficulties
local difficultyColors = {
	Easy = Color3.new(0.2, 0.8, 0.2),     -- Green
	Medium = Color3.new(0.2, 0.6, 1.0),   -- Blue  
	Hard = Color3.new(0.8, 0.4, 0.8),     -- Purple
	Extreme = Color3.new(1.0, 0.6, 0.2)   -- Orange
}

-- Create the dictionary UI
function WordDictionaryUI.CreateUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Main dictionary screen
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WordDictionaryUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	
	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 900, 0, 600)
	container.Position = UDim2.new(0.5, -450, 0.5, -300)
	container.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
	container.BorderSizePixel = 3
	container.BorderColor3 = Color3.new(0, 1, 0.5)
	container.Parent = screenGui
	
	-- Title section
	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "TitleFrame"
	titleFrame.Size = UDim2.new(1, -40, 0, 80)
	titleFrame.Position = UDim2.new(0, 20, 0, 20)
	titleFrame.BackgroundTransparency = 1
	titleFrame.Parent = container
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📚 YOUR WORD DICTIONARY"
	titleLabel.TextColor3 = Color3.new(0, 1, 0.5)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = titleFrame
	
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 30)
	subtitleLabel.Position = UDim2.new(0, 0, 0, 40)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "All the words you learned to type!"
	subtitleLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	subtitleLabel.TextScaled = false
	subtitleLabel.Font = Enum.Font.SourceSans
	subtitleLabel.TextSize = 18
	subtitleLabel.Parent = titleFrame
	
	-- Stats section
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(1, -40, 0, 40)
	statsFrame.Position = UDim2.new(0, 20, 0, 100)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = container
	
	local wordsCountLabel = Instance.new("TextLabel")
	wordsCountLabel.Name = "WordsCountLabel"
	wordsCountLabel.Size = UDim2.new(0.5, -10, 1, 0)
	wordsCountLabel.Position = UDim2.new(0, 0, 0, 0)
	wordsCountLabel.BackgroundTransparency = 1
	wordsCountLabel.Text = "Words Learned: 0"
	wordsCountLabel.TextColor3 = Color3.new(1, 1, 0)
	wordsCountLabel.TextScaled = true
	wordsCountLabel.Font = Enum.Font.SourceSansBold
	wordsCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	wordsCountLabel.Parent = statsFrame
	
	local uniqueLettersLabel = Instance.new("TextLabel")
	uniqueLettersLabel.Name = "UniqueLettersLabel"
	uniqueLettersLabel.Size = UDim2.new(0.5, -10, 1, 0)
	uniqueLettersLabel.Position = UDim2.new(0.5, 10, 0, 0)
	uniqueLettersLabel.BackgroundTransparency = 1
	uniqueLettersLabel.Text = "Unique Letters: 0"
	uniqueLettersLabel.TextColor3 = Color3.new(0.5, 0.8, 1.0)
	uniqueLettersLabel.TextScaled = true
	uniqueLettersLabel.Font = Enum.Font.SourceSansBold
	uniqueLettersLabel.TextXAlignment = Enum.TextXAlignment.Right
	uniqueLettersLabel.Parent = statsFrame
	
	-- Words scroll frame
	local wordsScrollFrame = Instance.new("ScrollingFrame")
	wordsScrollFrame.Name = "WordsScrollFrame"
	wordsScrollFrame.Size = UDim2.new(1, -40, 1, -180)
	wordsScrollFrame.Position = UDim2.new(0, 20, 0, 140)
	wordsScrollFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	wordsScrollFrame.BackgroundTransparency = 0.5
	wordsScrollFrame.BorderSizePixel = 1
	wordsScrollFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
	wordsScrollFrame.ScrollBarThickness = 12
	wordsScrollFrame.Parent = container
	
	-- Words layout
	local wordsLayout = Instance.new("UIListLayout")
	wordsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	wordsLayout.Padding = UDim.new(0, 2)
	wordsLayout.Parent = wordsScrollFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 120, 0, 40)
	closeButton.Position = UDim2.new(1, -140, 0, 20)
	closeButton.BackgroundColor3 = Color3.new(1, 0, 0)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "CLOSE"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = container
	
	closeButton.MouseButton1Click:Connect(function()
		WordDictionaryUI.Hide()
	end)
	
	-- Store references
	dictionaryUI = {
		Screen = screenGui,
		Container = container,
		WordsScrollFrame = wordsScrollFrame,
		WordsLayout = wordsLayout,
		WordsCountLabel = wordsCountLabel,
		UniqueLettersLabel = uniqueLettersLabel
	}
end

-- Show the dictionary with defeated words
function WordDictionaryUI.Show(defeatedWordsData)
	if not dictionaryUI then
		WordDictionaryUI.CreateUI()
	end
	
	defeatedWords = defeatedWordsData or {}
	
	-- Clear existing word entries
	for _, child in ipairs(dictionaryUI.WordsScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Update stats
	local wordsCount = #defeatedWords
	dictionaryUI.WordsCountLabel.Text = "Words Learned: " .. wordsCount
	
	-- Calculate unique letters
	local uniqueLetters = {}
	for _, wordData in ipairs(defeatedWords) do
		for letter in wordData.word:gmatch(".") do
			uniqueLetters[letter:upper()] = true
		end
	end
	local uniqueCount = 0
	for _ in pairs(uniqueLetters) do
		uniqueCount = uniqueCount + 1
	end
	dictionaryUI.UniqueLettersLabel.Text = "Unique Letters: " .. uniqueCount
	
	-- Create word entries
	for i, wordData in ipairs(defeatedWords) do
		WordDictionaryUI.CreateWordEntry(wordData, i)
	end
	
	-- Update canvas size
	local entryHeight = 60
	local padding = 2
	local totalHeight = #defeatedWords * (entryHeight + padding)
	dictionaryUI.WordsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
	
	-- Show UI with animation
	dictionaryUI.Screen.Enabled = true
	isVisible = true
	
	-- Animate container appearance
	dictionaryUI.Container.Position = UDim2.new(0.5, -450, 0.5, -600)
	local tween = TweenService:Create(
		dictionaryUI.Container,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -450, 0.5, -300)}
	)
	tween:Play()
end

-- Create a word entry
function WordDictionaryUI.CreateWordEntry(wordData, index)
	local definition = WordDefinitions.GetDefinitionOrDefault(wordData.word)
	local entryHeight = 58

	local entryFrame = Instance.new("Frame")
	entryFrame.Name = "WordEntry_" .. index
	entryFrame.Size = UDim2.new(1, -10, 0, entryHeight)
	entryFrame.BackgroundTransparency = 0.85
	entryFrame.BorderSizePixel = 1
	entryFrame.LayoutOrder = index
	entryFrame.Parent = dictionaryUI.WordsScrollFrame

	-- Determine difficulty and color
	local difficulty = WordDictionaryUI.GetWordDifficulty(wordData.word)
	local color = difficultyColors[difficulty] or Color3.new(0.5, 0.5, 0.5)
	entryFrame.BackgroundColor3 = color
	entryFrame.BorderColor3 = color

	-- Left accent stripe
	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 4, 1, 0)
	stripe.BackgroundColor3 = color
	stripe.BorderSizePixel = 0
	stripe.Parent = entryFrame

	-- Word label (top row)
	local wordLabel = Instance.new("TextLabel")
	wordLabel.Name = "WordLabel"
	wordLabel.Size = UDim2.new(0, 180, 0, 26)
	wordLabel.Position = UDim2.new(0, 14, 0, 4)
	wordLabel.BackgroundTransparency = 1
	wordLabel.Text = wordData.word:upper()
	wordLabel.TextColor3 = Color3.new(1, 1, 1)
	wordLabel.TextScaled = true
	wordLabel.Font = Enum.Font.SourceSansBold
	wordLabel.TextXAlignment = Enum.TextXAlignment.Left
	wordLabel.Parent = entryFrame

	-- Difficulty badge
	local diffLabel = Instance.new("TextLabel")
	diffLabel.Name = "DifficultyLabel"
	diffLabel.Size = UDim2.new(0, 80, 0, 20)
	diffLabel.Position = UDim2.new(0, 200, 0, 6)
	diffLabel.BackgroundColor3 = color
	diffLabel.BackgroundTransparency = 0.5
	diffLabel.BorderSizePixel = 0
	diffLabel.Text = difficulty:upper()
	diffLabel.TextColor3 = Color3.new(1, 1, 1)
	diffLabel.TextScaled = true
	diffLabel.Font = Enum.Font.SourceSansBold
	diffLabel.Parent = entryFrame

	-- Wave label
	local waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "WaveLabel"
	waveLabel.Size = UDim2.new(0, 70, 0, 20)
	waveLabel.Position = UDim2.new(0, 290, 0, 6)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "Wave " .. (wordData.wave or 1)
	waveLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	waveLabel.TextScaled = true
	waveLabel.Font = Enum.Font.SourceSans
	waveLabel.TextXAlignment = Enum.TextXAlignment.Left
	waveLabel.Parent = entryFrame

	-- Definition label (second row)
	local defLabel = Instance.new("TextLabel")
	defLabel.Name = "DefinitionLabel"
	defLabel.Size = UDim2.new(1, -20, 0, 26)
	defLabel.Position = UDim2.new(0, 14, 0, 30)
	defLabel.BackgroundTransparency = 1
	defLabel.Text = definition
	defLabel.TextColor3 = Color3.new(0.75, 0.75, 0.75)
	defLabel.TextScaled = true
	defLabel.Font = Enum.Font.SourceSans
	defLabel.TextXAlignment = Enum.TextXAlignment.Left
	defLabel.TextTruncate = Enum.TextTruncate.AtEnd
	defLabel.Parent = entryFrame

	-- Hover effect
	entryFrame.MouseEnter:Connect(function()
		entryFrame.BackgroundTransparency = 0.5
		defLabel.TextColor3 = Color3.new(1, 1, 1)
	end)
	entryFrame.MouseLeave:Connect(function()
		entryFrame.BackgroundTransparency = 0.85
		defLabel.TextColor3 = Color3.new(0.75, 0.75, 0.75)
	end)
end

-- Get word difficulty based on length
function WordDictionaryUI.GetWordDifficulty(word)
	local length = #word
	if length <= 5 then
		return "Easy"
	elseif length <= 8 then
		return "Medium"
	elseif length <= 12 then
		return "Hard"
	else
		return "Extreme"
	end
end

-- Hide the dictionary UI
function WordDictionaryUI.Hide()
	if not dictionaryUI or not isVisible then return end
	
	-- Animate out
	local tween = TweenService:Create(
		dictionaryUI.Container,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -450, 0.5, -600)}
	)
	tween:Play()
	
	tween.Completed:Connect(function()
		dictionaryUI.Screen.Enabled = false
		isVisible = false
	end)
end

-- Check if dictionary is visible
function WordDictionaryUI.IsVisible()
	return isVisible
end

-- Handle escape key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape and isVisible then
		WordDictionaryUI.Hide()
	end
end)

return WordDictionaryUI
