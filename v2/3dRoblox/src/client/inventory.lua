-- Inventory - Manages player items and equipment
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemData = require(ReplicatedStorage.Shared:WaitForChild("item_data"))

local Inventory = {}
Inventory.__index = Inventory

local MAX_INVENTORY_SLOTS = 20

function Inventory.new()
	local self = setmetatable({}, Inventory)
	
	self.items = {}
	self.max_slots = MAX_INVENTORY_SLOTS
	self.gold = 0
	self.inventory_open = false
	
	return self
end

function Inventory:initialize()
	print("[Inventory] Initializing...")
	
	self:setup_input()
	self:create_inventory_ui()
	
	print("[Inventory] Initialized")
end

function Inventory:setup_input()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.I then
			self:toggle_inventory()
		end
	end)
end

function Inventory:create_inventory_ui()
	local player = game:GetService("Players").LocalPlayer
	local player_gui = player:WaitForChild("PlayerGui")
	
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "InventoryUI"
	screen_gui.ResetOnSpawn = false
	screen_gui.Enabled = false
	screen_gui.Parent = player_gui
	
	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.BorderSizePixel = 0
	background.Parent = screen_gui
	
	-- Inventory panel
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0.6, 0, 0.8, 0)
	panel.Position = UDim2.new(0.2, 0, 0.1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	panel.BorderSizePixel = 1
	panel.BorderColor3 = Color3.fromRGB(100, 100, 150)
	panel.Parent = screen_gui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.TextColor3 = Color3.fromRGB(200, 200, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Text = "INVENTORY"
	title.Parent = panel
	
	-- Inventory grid
	local grid_container = Instance.new("Frame")
	grid_container.Name = "GridContainer"
	grid_container.Size = UDim2.new(0.7, 0, 0.8, 0)
	grid_container.Position = UDim2.new(0.05, 0, 0.12, 0)
	grid_container.BackgroundTransparency = 1
	grid_container.Parent = panel
	
	local grid_layout = Instance.new("UIGridLayout")
	grid_layout.CellSize = UDim2.new(0.2, 0, 0.2, 0)
	grid_layout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
	grid_layout.Parent = grid_container
	
	-- Create inventory slots
	for i = 1, MAX_INVENTORY_SLOTS do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		slot.BorderSizePixel = 1
		slot.BorderColor3 = Color3.fromRGB(100, 100, 100)
		slot.Parent = grid_container
		
		local slot_label = Instance.new("TextLabel")
		slot_label.Size = UDim2.new(1, 0, 1, 0)
		slot_label.BackgroundTransparency = 1
		slot_label.TextColor3 = Color3.fromRGB(200, 200, 200)
		slot_label.TextSize = 10
		slot_label.Font = Enum.Font.GothamMonospace
		slot_label.Text = ""
		slot_label.Parent = slot
	end
	
	-- Info panel
	local info_panel = Instance.new("Frame")
	info_panel.Name = "InfoPanel"
	info_panel.Size = UDim2.new(0.25, 0, 0.8, 0)
	info_panel.Position = UDim2.new(0.7, 0, 0.12, 0)
	info_panel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	info_panel.BorderSizePixel = 1
	info_panel.BorderColor3 = Color3.fromRGB(100, 100, 100)
	info_panel.Parent = panel
	
	local info_label = Instance.new("TextLabel")
	info_label.Name = "InfoLabel"
	info_label.Size = UDim2.new(1, 0, 1, 0)
	info_label.BackgroundTransparency = 1
	info_label.TextColor3 = Color3.fromRGB(200, 200, 200)
	info_label.TextSize = 12
	info_label.Font = Enum.Font.GothamMonospace
	info_label.TextXAlignment = Enum.TextXAlignment.Left
	info_label.TextYAlignment = Enum.TextYAlignment.Top
	info_label.Text = "Select an item\nfor details"
	info_label.Parent = info_panel
	
	-- Close button
	local close_button = Instance.new("TextButton")
	close_button.Name = "CloseButton"
	close_button.Size = UDim2.new(0.1, 0, 0.05, 0)
	close_button.Position = UDim2.new(0.85, 0, 0.02, 0)
	close_button.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	close_button.TextColor3 = Color3.fromRGB(255, 255, 255)
	close_button.TextSize = 14
	close_button.Font = Enum.Font.GothamBold
	close_button.Text = "X"
	close_button.Parent = panel
	
	close_button.MouseButton1Click:Connect(function()
		self:toggle_inventory()
	end)
	
	screen_gui:SetAttribute("GridContainer", grid_container)
	screen_gui:SetAttribute("InfoLabel", info_label)
end

function Inventory:toggle_inventory()
	local player = game:GetService("Players").LocalPlayer
	local player_gui = player:WaitForChild("PlayerGui")
	local inventory_ui = player_gui:FindFirstChild("InventoryUI")
	
	if inventory_ui then
		inventory_ui.Enabled = not inventory_ui.Enabled
		self.inventory_open = inventory_ui.Enabled
	end
end

function Inventory:add_item(item_id, quantity)
	quantity = quantity or 1
	
	for _ = 1, quantity do
		if #self.items < self.max_slots then
			table.insert(self.items, item_id)
		end
	end
	
	self:update_inventory_display()
end

function Inventory:remove_item(index)
	if index >= 1 and index <= #self.items then
		table.remove(self.items, index)
		self:update_inventory_display()
	end
end

function Inventory:add_gold(amount)
	self.gold = self.gold + amount
end

function Inventory:use_item(index)
	if index >= 1 and index <= #self.items then
		local item_id = self.items[index]
		local item_data = ItemData:get_item(item_id)
		
		if item_data then
			if item_data.type == ItemData.ITEM_TYPES.HEALTH_POTION then
				-- Heal player
				print("[Inventory] Used", item_data.name)
			elseif item_data.type == ItemData.ITEM_TYPES.FOOD then
				-- Heal player
				print("[Inventory] Consumed", item_data.name)
			end
			
			self:remove_item(index)
		end
	end
end

function Inventory:update_inventory_display()
	local player = game:GetService("Players").LocalPlayer
	local player_gui = player:WaitForChild("PlayerGui")
	local inventory_ui = player_gui:FindFirstChild("InventoryUI")
	
	if not inventory_ui then return end
	
	local grid_container = inventory_ui:GetAttribute("GridContainer")
	if not grid_container then return end
	
	-- Update slots
	for i = 1, MAX_INVENTORY_SLOTS do
		local slot = grid_container:FindFirstChild("Slot_" .. i)
		if slot then
			local slot_label = slot:FindFirstChildOfClass("TextLabel")
			if slot_label then
				if i <= #self.items then
					local item_id = self.items[i]
					local item_data = ItemData:get_item(item_id)
					if item_data then
						slot_label.Text = item_data.name:sub(1, 10)
						slot.BackgroundColor3 = ItemData.RARITY_COLORS[item_data.rarity]
					end
				else
					slot_label.Text = ""
					slot.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
				end
			end
		end
	end
end

function Inventory:get_item_count(item_id)
	local count = 0
	for _, id in ipairs(self.items) do
		if id == item_id then
			count = count + 1
		end
	end
	return count
end

return Inventory
