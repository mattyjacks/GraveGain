-- Client-side Lore UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared:WaitForChild("constants"))
local LoreEntries1 = require(ReplicatedStorage.Shared:WaitForChild("lore_entries_1"))
local LoreEntries2 = require(ReplicatedStorage.Shared:WaitForChild("lore_entries_2"))
local LoreDatabase = require(ReplicatedStorage.Shared:WaitForChild("lore_database"))

local LoreUI = {}
LoreUI.__index = LoreUI

local player = Players.LocalPlayer
local all_lore_entries = {}
local lore_open = false

function LoreUI:initialize()
	print("[LoreUI] Initializing...")
	
	-- Load all lore entries
	for id, entry in pairs(LoreEntries1.get_entries()) do
		all_lore_entries[id] = entry
	end
	for id, entry in pairs(LoreEntries2.get_entries()) do
		all_lore_entries[id] = entry
	end
	
	print("[LoreUI] Loaded " .. table.getn(all_lore_entries) .. " lore entries")
	print("[LoreUI] Initialized")
end

function LoreUI:create_lore_menu(parent)
	local lore_menu = Instance.new("Frame")
	lore_menu.Name = "LoreMenu"
	lore_menu.Size = UDim2.new(0.9, 0, 0.85, 0)
	lore_menu.Position = UDim2.new(0.05, 0, 0.08, 0)
	lore_menu.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	lore_menu.BorderColor3 = Color3.fromRGB(100, 100, 120)
	lore_menu.BorderSizePixel = 2
	lore_menu.Parent = parent
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.08, 0)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Text = "📚 Learn the Lore"
	title.Parent = lore_menu
	
	-- Close button
	local close_button = Instance.new("TextButton")
	close_button.Name = "CloseButton"
	close_button.Size = UDim2.new(0.05, 0, 0.08, 0)
	close_button.Position = UDim2.new(0.94, 0, 0, 0)
	close_button.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	close_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	close_button.TextSize = 20
	close_button.Font = Enum.Font.GothamBold
	close_button.Text = "X"
	close_button.Parent = lore_menu
	
	close_button.MouseButton1Click:Connect(function()
		self:toggle_lore_menu()
	end)
	
	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0.92, 0)
	content.Position = UDim2.new(0, 0, 0.08, 0)
	content.BackgroundTransparency = 1
	content.Parent = lore_menu
	
	-- Left panel - Categories
	local left_panel = Instance.new("Frame")
	left_panel.Name = "LeftPanel"
	left_panel.Size = UDim2.new(0.25, 0, 1, 0)
	left_panel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	left_panel.Parent = content
	
	-- Category title
	local cat_title = Instance.new("TextLabel")
	cat_title.Name = "CategoryTitle"
	cat_title.Size = UDim2.new(1, 0, 0.08, 0)
	cat_title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	cat_title.TextColor3 = Color3.fromRGB(200, 200, 255)
	cat_title.TextSize = 18
	cat_title.Font = Enum.Font.GothamBold
	cat_title.Text = "Categories"
	cat_title.Parent = left_panel
	
	-- Category list
	local category_list = Instance.new("ScrollingFrame")
	category_list.Name = "CategoryList"
	category_list.Size = UDim2.new(1, 0, 0.92, 0)
	category_list.Position = UDim2.new(0, 0, 0.08, 0)
	category_list.BackgroundTransparency = 1
	category_list.ScrollBarThickness = 8
	category_list.Parent = left_panel
	
	local cat_layout = Instance.new("UIListLayout")
	cat_layout.Padding = UDim.new(0, 5)
	cat_layout.Parent = category_list
	
	-- Middle panel - Entries
	local middle_panel = Instance.new("Frame")
	middle_panel.Name = "MiddlePanel"
	middle_panel.Size = UDim2.new(0.35, 0, 1, 0)
	middle_panel.Position = UDim2.new(0.25, 0, 0, 0)
	middle_panel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	middle_panel.Parent = content
	
	-- Entry title
	local entry_title = Instance.new("TextLabel")
	entry_title.Name = "EntryTitle"
	entry_title.Size = UDim2.new(1, 0, 0.08, 0)
	entry_title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	entry_title.TextColor3 = Color3.fromRGB(200, 200, 255)
	entry_title.TextSize = 18
	entry_title.Font = Enum.Font.GothamBold
	entry_title.Text = "Entries"
	entry_title.Parent = middle_panel
	
	-- Entry list
	local entry_list = Instance.new("ScrollingFrame")
	entry_list.Name = "EntryList"
	entry_list.Size = UDim2.new(1, 0, 0.92, 0)
	entry_list.Position = UDim2.new(0, 0, 0.08, 0)
	entry_list.BackgroundTransparency = 1
	entry_list.ScrollBarThickness = 8
	entry_list.Parent = middle_panel
	
	local entry_layout = Instance.new("UIListLayout")
	entry_layout.Padding = UDim.new(0, 5)
	entry_layout.Parent = entry_list
	
	-- Right panel - Details
	local right_panel = Instance.new("Frame")
	right_panel.Name = "RightPanel"
	right_panel.Size = UDim2.new(0.4, 0, 1, 0)
	right_panel.Position = UDim2.new(0.6, 0, 0, 0)
	right_panel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	right_panel.Parent = content
	
	-- Detail title
	local detail_title = Instance.new("TextLabel")
	detail_title.Name = "DetailTitle"
	detail_title.Size = UDim2.new(1, 0, 0.08, 0)
	detail_title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	detail_title.TextColor3 = Color3.fromRGB(200, 200, 255)
	detail_title.TextSize = 18
	detail_title.Font = Enum.Font.GothamBold
	detail_title.Text = "Details"
	detail_title.Parent = right_panel
	
	-- Detail content
	local detail_content = Instance.new("ScrollingFrame")
	detail_content.Name = "DetailContent"
	detail_content.Size = UDim2.new(1, 0, 0.92, 0)
	detail_content.Position = UDim2.new(0, 0, 0.08, 0)
	detail_content.BackgroundTransparency = 1
	detail_content.ScrollBarThickness = 8
	detail_content.Parent = right_panel
	
	-- Populate categories
	local categories = LoreDatabase.get_all_categories()
	for _, category in ipairs(categories) do
		local cat_button = Instance.new("TextButton")
		cat_button.Name = category
		cat_button.Size = UDim2.new(1, -10, 0, 40)
		cat_button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		cat_button.TextColor3 = Color3.fromRGB(200, 200, 200)
		cat_button.TextSize = 14
		cat_button.Font = Enum.Font.Gotham
		cat_button.Text = LoreDatabase.get_category_emoji(category) .. " " .. category:gsub("_", " ")
		cat_button.TextXAlignment = Enum.TextXAlignment.Left
		cat_button.Parent = category_list
		
		cat_button.MouseButton1Click:Connect(function()
			self:show_entries_for_category(category, entry_list, detail_content)
		end)
	end
	
	lore_menu:SetAttribute("EntryList", entry_list)
	lore_menu:SetAttribute("DetailContent", detail_content)
	
	return lore_menu
end

function LoreUI:show_entries_for_category(category, entry_list, detail_content)
	-- Clear entry list
	for _, child in ipairs(entry_list:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Clear detail content
	for _, child in ipairs(detail_content:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextBox") then
			child:Destroy()
		end
	end
	
	-- Find all entries in this category
	local category_entries = {}
	for id, entry in pairs(all_lore_entries) do
		if entry.category == category then
			table.insert(category_entries, entry)
		end
	end
	
	-- Sort by title
	table.sort(category_entries, function(a, b)
		return a.title < b.title
	end)
	
	-- Create entry buttons
	for _, entry in ipairs(category_entries) do
		local entry_button = Instance.new("TextButton")
		entry_button.Name = entry.id
		entry_button.Size = UDim2.new(1, -10, 0, 50)
		entry_button.BackgroundColor3 = LoreDatabase.get_rarity_color(entry.rarity)
		entry_button.TextColor3 = Color3.fromRGB(0, 0, 0)
		entry_button.TextSize = 12
		entry_button.Font = Enum.Font.Gotham
		entry_button.Text = LoreDatabase.get_type_emoji(entry.type) .. " " .. entry.title
		entry_button.TextXAlignment = Enum.TextXAlignment.Left
		entry_button.Parent = entry_list
		
		entry_button.MouseButton1Click:Connect(function()
			self:show_entry_details(entry, detail_content)
		end)
	end
end

function LoreUI:show_entry_details(entry, detail_content)
	-- Clear detail content
	for _, child in ipairs(detail_content:GetChildren()) do
		child:Destroy()
	end
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundTransparency = 1
	title.TextColor3 = LoreDatabase.get_rarity_color(entry.rarity)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Text = LoreDatabase.get_type_emoji(entry.type) .. " " .. entry.title
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.Parent = detail_content
	
	-- Metadata
	local metadata = Instance.new("TextLabel")
	metadata.Name = "Metadata"
	metadata.Size = UDim2.new(1, 0, 0, 50)
	metadata.Position = UDim2.new(0, 0, 0, 60)
	metadata.BackgroundTransparency = 1
	metadata.TextColor3 = Color3.fromRGB(150, 150, 150)
	metadata.TextSize = 12
	metadata.Font = Enum.Font.Gotham
	metadata.Text = "Type: " .. entry.type .. " | Rarity: " .. entry.rarity .. " | Category: " .. entry.category
	metadata.TextWrapped = true
	metadata.TextXAlignment = Enum.TextXAlignment.Left
	metadata.TextYAlignment = Enum.TextYAlignment.Top
	metadata.Parent = detail_content
	
	-- Content
	local content = Instance.new("TextLabel")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -110)
	content.Position = UDim2.new(0, 0, 0, 110)
	content.BackgroundTransparency = 1
	content.TextColor3 = Color3.fromRGB(200, 200, 200)
	content.TextSize = 13
	content.Font = Enum.Font.Gotham
	content.Text = entry.content
	content.TextWrapped = true
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.Parent = detail_content
end

function LoreUI:toggle_lore_menu()
	lore_open = not lore_open
	local player_gui = player:WaitForChild("PlayerGui")
	local lobby_ui = player_gui:FindFirstChild("LobbyUI")
	if not lobby_ui then return end
	
	local lore_menu = lobby_ui:FindFirstChild("LoreMenu")
	if lore_open then
		if not lore_menu then
			self:create_lore_menu(lobby_ui)
		else
			lore_menu.Visible = true
		end
	else
		if lore_menu then
			lore_menu.Visible = false
		end
	end
end

return LoreUI
