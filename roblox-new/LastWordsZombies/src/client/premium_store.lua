-- Premium store system for visual upgrades
-- Handles monetization of blood effects, fonts, and music tracks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local AudioManager = require(script.Parent.AudioManager)

local PremiumStore = {}

-- Player data (would normally be saved to DataStore)
local PlayerData = {
	coins = 0,
	unlockedItems = {
		blood_effects = {"default"},
		font_styles = {"default"},
		music_tracks = {"default"}
	},
	equippedItems = {
		blood_effect = "default",
		font_style = "default",
		music_track = "default"
	}
}

-- UI state
local StoreUI = nil
local IsStoreOpen = false

-- Initialize premium store
function PremiumStore.Initialize()
	print("Premium Store Initialized")
	
	-- Load player data (placeholder)
	LoadPlayerData()
	
	-- Create store UI
	CreateStoreUI()
end

-- Load player data (would use DataStore in production)
function LoadPlayerData()
	-- Placeholder - in production, load from DataStore
	PlayerData.coins = 500 -- Start with some coins for testing
end

-- Save player data (would use DataStore in production)
function SavePlayerData()
	-- Placeholder - in production, save to DataStore
end

-- Create store UI
function CreateStoreUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Main store screen
	local storeScreen = Instance.new("ScreenGui")
	storeScreen.Name = "PremiumStore"
	storeScreen.ResetOnSpawn = false
	storeScreen.Enabled = false
	storeScreen.Parent = playerGui
	
	-- Background
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.BackgroundTransparency = 0.9
	background.Parent = storeScreen
	
	-- Store container
	local storeContainer = Instance.new("Frame")
	storeContainer.Name = "StoreContainer"
	storeContainer.Size = UDim2.new(0, 800, 0, 600)
	storeContainer.Position = UDim2.new(0.5, -400, 0.5, -300)
	storeContainer.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
	storeContainer.BorderSizePixel = 2
	storeContainer.BorderColor3 = Color3.new(0, 1, 0.5)
	storeContainer.Parent = storeScreen
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 60)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "PREMIUM STORE"
	title.TextColor3 = Color3.new(0, 1, 0.5)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = storeContainer
	
	-- Coins display
	local coinsDisplay = Instance.new("Frame")
	coinsDisplay.Name = "CoinsDisplay"
	coinsDisplay.Size = UDim2.new(0, 200, 0, 40)
	coinsDisplay.Position = UDim2.new(1, -220, 0, 20)
	coinsDisplay.BackgroundColor3 = Color3.new(0, 0, 0)
	coinsDisplay.BackgroundTransparency = 0.5
	coinsDisplay.BorderSizePixel = 1
	coinsDisplay.BorderColor3 = Color3.new(1, 0.8, 0)
	coinsDisplay.Parent = storeContainer
	
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Size = UDim2.new(1, -10, 1, 0)
	coinsLabel.Position = UDim2.new(0, 5, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "COINS: " .. PlayerData.coins
	coinsLabel.TextColor3 = Color3.new(1, 0.8, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.SourceSansBold
	coinsLabel.Parent = coinsDisplay
	
	-- Category buttons
	local categoryFrame = Instance.new("Frame")
	categoryFrame.Name = "CategoryFrame"
	categoryFrame.Size = UDim2.new(0, 200, 0, 500)
	categoryFrame.Position = UDim2.new(0, 20, 0, 80)
	categoryFrame.BackgroundTransparency = 1
	categoryFrame.Parent = storeContainer
	
	-- Items frame
	local itemsFrame = Instance.new("ScrollingFrame")
	itemsFrame.Name = "ItemsFrame"
	itemsFrame.Size = UDim2.new(0, 540, 0, 480)
	itemsFrame.Position = UDim2.new(0, 240, 0, 80)
	itemsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	itemsFrame.BackgroundTransparency = 0.5
	itemsFrame.BorderSizePixel = 1
	itemsFrame.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
	itemsFrame.ScrollBarThickness = 10
	itemsFrame.Parent = storeContainer
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.new(1, 0, 0)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = storeContainer
	
	closeButton.MouseButton1Click:Connect(function()
		ToggleStore()
	end)
	
	-- Create category tabs
	CreateCategoryTabs(categoryFrame, itemsFrame)
	
	StoreUI = {
		Screen = storeScreen,
		Container = storeContainer,
		CoinsLabel = coinsLabel,
		ItemsFrame = itemsFrame
	}
end

-- Create category tabs
function CreateCategoryTabs(parent, itemsFrame)
	local categories = {
		{name = "Blood Effects", id = "blood_effects"},
		{name = "Font Styles", id = "font_styles"},
		{name = "Music Tracks", id = "music_tracks"}
	}
	
	local buttonHeight = 50
	local spacing = 10
	
	for i, category in ipairs(categories) do
		local button = Instance.new("TextButton")
		button.Name = category.id .. "Button"
		button.Size = UDim2.new(1, -10, 0, buttonHeight)
		button.Position = UDim2.new(0, 5, 0, (i - 1) * (buttonHeight + spacing))
		button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
		button.BorderSizePixel = 1
		button.BorderColor3 = Color3.new(0, 1, 0.5)
		button.Text = category.name
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.SourceSans
		button.Parent = parent
		
		button.MouseButton1Click:Connect(function()
			ShowCategory(category.id, itemsFrame)
			HighlightCategoryButton(category.id, parent)
		end)
	end
	
	-- Show first category by default
	ShowCategory("blood_effects", itemsFrame)
	HighlightCategoryButton("blood_effects", parent)
end

-- Show items for a category
function ShowCategory(categoryId, itemsFrame)
	local items = GameData.PREMIUM[categoryId:upper()]
	if not items then return end
	
	-- Clear existing items
	for _, child in ipairs(itemsFrame:GetChildren()) do
		child:Destroy()
	end
	
	-- Layout items in a grid
	local itemWidth = 160
	local itemHeight = 120
	local spacing = 20
	local columns = 3
	
	for i, item in ipairs(items) do
		local row = math.floor((i - 1) / columns)
		local col = (i - 1) % columns
		
		local itemFrame = CreateItemFrame(item, categoryId)
		itemFrame.Position = UDim2.new(0, col * (itemWidth + spacing) + spacing, 0, row * (itemHeight + spacing) + spacing)
		itemFrame.Parent = itemsFrame
	end
	
	-- Update canvas size
	local rows = math.ceil(#items / columns)
	itemsFrame.CanvasSize = UDim2.new(0, 0, 0, rows * (itemHeight + spacing) + spacing)
end

-- Create item frame
function CreateItemFrame(item, categoryId)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 160, 0, 120)
	frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
	frame.BorderSizePixel = 2
	frame.Name = item.id .. "Frame"
	
	-- Check if owned/equipped
	local isOwned = table.find(PlayerData.unlockedItems[categoryId], item.id)
	local isEquipped = PlayerData.equippedItems[categoryId] == item.id
	
	if isEquipped then
		frame.BorderColor3 = Color3.new(0, 1, 0)
	elseif isOwned then
		frame.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
	else
		frame.BorderColor3 = Color3.new(1, 0.5, 0)
	end
	
	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = frame
	
	-- Price/Status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -10, 0, 25)
	statusLabel.Position = UDim2.new(0, 5, 0, 35)
	statusLabel.BackgroundTransparency = 1
	
	if isEquipped then
		statusLabel.Text = "EQUIPPED"
		statusLabel.TextColor3 = Color3.new(0, 1, 0)
	elseif isOwned then
		statusLabel.Text = "OWNED"
		statusLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
	else
		statusLabel.Text = "COINS: " .. item.price
		statusLabel.TextColor3 = Color3.new(1, 0.8, 0)
	end
	
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.Parent = frame
	
	-- Action button
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(1, -10, 0, 30)
	actionButton.Position = UDim2.new(0, 5, 1, -35)
	actionButton.BackgroundColor3 = Color3.new(0, 0.5, 0.8)
	actionButton.BorderSizePixel = 0
	actionButton.TextScaled = true
	actionButton.Font = Enum.Font.SourceSansBold
	actionButton.Parent = frame
	
	if isEquipped then
		actionButton.Text = "EQUIPPED"
		actionButton.BackgroundColor3 = Color3.new(0, 0.8, 0)
		actionButton.Active = false
	elseif isOwned then
		actionButton.Text = "EQUIP"
		actionButton.BackgroundColor3 = Color3.new(0, 0.5, 0.8)
	else
		actionButton.Text = "BUY"
		actionButton.BackgroundColor3 = Color3.new(1, 0.5, 0)
		if PlayerData.coins < item.price then
			actionButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
			actionButton.Active = false
		end
	end
	
	actionButton.MouseButton1Click:Connect(function()
		HandleItemAction(item, categoryId, actionButton, statusLabel, frame)
	end)
	
	-- Preview for blood effects
	if categoryId == "blood_effects" then
		local preview = Instance.new("Frame")
		preview.Size = UDim2.new(0, 20, 0, 20)
		preview.Position = UDim2.new(1, -25, 0, 5)
		preview.BackgroundColor3 = item.color
		preview.BorderSizePixel = 1
		preview.BorderColor3 = Color3.new(1, 1, 1)
		preview.Parent = frame
	end
	
	return frame
end

-- Handle item actions (buy/equip)
function HandleItemAction(item, categoryId, button, statusLabel, frame)
	local isOwned = table.find(PlayerData.unlockedItems[categoryId], item.id)
	local isEquipped = PlayerData.equippedItems[categoryId] == item.id
	
	if isEquipped then
		-- Already equipped
		return
	elseif isOwned then
		-- Equip item
		EquipItem(item, categoryId, button, statusLabel, frame)
	else
		-- Buy item
		BuyItem(item, categoryId, button, statusLabel, frame)
	end
end

-- Buy item
function BuyItem(item, categoryId, button, statusLabel, frame)
	if PlayerData.coins < item.price then
		-- Not enough coins
		button.BackgroundColor3 = Color3.new(1, 0, 0)
		task.wait(0.5)
		button.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
		return
	end
	
	-- Deduct coins
	PlayerData.coins = PlayerData.coins - item.price
	
	-- Add to owned items
	table.insert(PlayerData.unlockedItems[categoryId], item.id)
	
	-- Equip the item
	PlayerData.equippedItems[categoryId] = item.id
	
	-- Apply the effect
	ApplyItemEffect(item, categoryId)
	
	-- Update UI
	UpdateCoinsDisplay()
	button.Text = "EQUIPPED"
	button.BackgroundColor3 = Color3.new(0, 0.8, 0)
	button.Active = false
	statusLabel.Text = "EQUIPPED"
	statusLabel.TextColor3 = Color3.new(0, 1, 0)
	frame.BorderColor3 = Color3.new(0, 1, 0)
	
	-- Save data
	SavePlayerData()
end

-- Equip item
function EquipItem(item, categoryId, button, statusLabel, frame)
	-- Equip the item
	PlayerData.equippedItems[categoryId] = item.id
	
	-- Apply the effect
	ApplyItemEffect(item, categoryId)
	
	-- Update UI
	button.Text = "EQUIPPED"
	button.BackgroundColor3 = Color3.new(0, 0.8, 0)
	button.Active = false
	statusLabel.Text = "EQUIPPED"
	statusLabel.TextColor3 = Color3.new(0, 1, 0)
	frame.BorderColor3 = Color3.new(0, 1, 0)
	
	-- Save data
	SavePlayerData()
end

-- Apply item effect
function ApplyItemEffect(item, categoryId)
	if categoryId == "blood_effects" then
		-- Update blood color
		GameData.VISUALS.BLOOD_COLOR = item.color
	elseif categoryId == "font_styles" then
		-- Update font style (would need to update typing handler)
		print("Font style changed to:", item.name)
	elseif categoryId == "music_tracks" then
		-- Change music track
		AudioManager.ChangeMusicTrack(item.id)
	end
end

-- Highlight category button
function HighlightCategoryButton(categoryId, parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("TextButton") then
			if child.Name:match(categoryId) then
				child.BackgroundColor3 = Color3.new(0.3, 0.3, 0.5)
			else
				child.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
			end
		end
	end
end

-- Update coins display
function UpdateCoinsDisplay()
	if StoreUI and StoreUI.CoinsLabel then
		StoreUI.CoinsLabel.Text = "COINS: " .. PlayerData.coins
	end
end

-- Toggle store visibility
function ToggleStore()
	if not StoreUI then return end
	
	IsStoreOpen = not IsStoreOpen
	StoreUI.Screen.Enabled = IsStoreOpen
	
	-- Update coins display when opening
	if IsStoreOpen then
		UpdateCoinsDisplay()
	end
	
	-- Pause game when store is open
	local typingHandler = require(script.Parent.TypingHandler)
	typingHandler.SetEnabled(not IsStoreOpen)
end

-- Add coins (called when player earns them)
function AddCoins(amount)
	PlayerData.coins = PlayerData.coins + amount
	UpdateCoinsDisplay()
	SavePlayerData()
end

-- Get current equipped items
function GetEquippedItems()
	return PlayerData.equippedItems
end

return PremiumStore
