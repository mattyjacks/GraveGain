local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local InventoryUI = {}
InventoryUI.__index = InventoryUI

function InventoryUI.new(inventoryManager, inputHandler)
	local self = setmetatable({}, InventoryUI)
	self.manager = inventoryManager
	self.inputHandler = inputHandler
	self.isVisible = false
	self.cellSize = 50
	self.gui = nil

	self.equips = {
		Primary = nil,
		Secondary = nil,
		Consumable = nil,
		Throwable = nil
	}

	self.draggingItem = nil
	self.dragFrame = nil
	self.dragOffset = Vector2.new()
	self.dragConn = nil
	self.rotateConn = nil
	self.releaseConn = nil

	self:createUI()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.I and not gameProcessed then
			self:toggle()
		end
	end)

	return self
end

function InventoryUI:createUI()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Destroy any old UI
	local old = playerGui:FindFirstChild("InventoryUI")
	if old then old:Destroy() end

	self.gui = Instance.new("ScreenGui")
	self.gui.Name = "InventoryUI"
	self.gui.Enabled = false
	self.gui.ResetOnSpawn = false
	self.gui.Parent = playerGui

	local GRID_W = self.manager.width * self.cellSize
	local GRID_H = self.manager.height * self.cellSize
	local EQUIP_H = 90
	local PAD = 12
	local TITLE_H = 30
	local TOTAL_H = TITLE_H + PAD + GRID_H + PAD + EQUIP_H + PAD

	self.mainFrame = Instance.new("Frame")
	self.mainFrame.Size = UDim2.new(0, GRID_W + PAD * 2, 0, TOTAL_H)
	self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	self.mainFrame.BorderSizePixel = 0
	self.mainFrame.Parent = self.gui
	Instance.new("UICorner", self.mainFrame).CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, TITLE_H)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.Text = "⚔  INVENTORY  (R to rotate)"
	title.TextColor3 = Color3.fromRGB(255, 220, 100)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 17
	title.Parent = self.mainFrame

	self.gridFrame = Instance.new("Frame")
	self.gridFrame.Size = UDim2.new(0, GRID_W, 0, GRID_H)
	self.gridFrame.Position = UDim2.new(0, PAD, 0, TITLE_H + PAD)
	self.gridFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	self.gridFrame.BorderSizePixel = 0
	self.gridFrame.ClipsDescendants = true
	self.gridFrame.Parent = self.mainFrame
	Instance.new("UICorner", self.gridFrame).CornerRadius = UDim.new(0, 4)

	-- Grid lines
	for x = 0, self.manager.width do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0, 1, 1, 0)
		line.Position = UDim2.new(0, x * self.cellSize, 0, 0)
		line.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
		line.BorderSizePixel = 0
		line.Parent = self.gridFrame
	end
	for y = 0, self.manager.height do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 0, y * self.cellSize)
		line.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
		line.BorderSizePixel = 0
		line.Parent = self.gridFrame
	end

	-- Equip panel below the grid
	local equipY = TITLE_H + PAD + GRID_H + PAD
	self.equipFrame = Instance.new("Frame")
	self.equipFrame.Size = UDim2.new(0, GRID_W, 0, EQUIP_H)
	self.equipFrame.Position = UDim2.new(0, PAD, 0, equipY)
	self.equipFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	self.equipFrame.BorderSizePixel = 0
	self.equipFrame.Parent = self.mainFrame
	Instance.new("UICorner", self.equipFrame).CornerRadius = UDim.new(0, 4)

	local equipTitles = {"1: Melee", "2: Ranged", "3: Potion", "4: Grenade"}
	self.equipSlots = {}

	local slotW = (GRID_W - 5 * 6) / 4
	for i = 1, 4 do
		local slot = Instance.new("Frame")
		slot.Size = UDim2.new(0, slotW, 0, 56)
		slot.Position = UDim2.new(0, (i - 1) * (slotW + 6) + 6, 0, 24)
		slot.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		slot.BorderSizePixel = 0
		slot.Parent = self.equipFrame
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 4)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 20)
		label.Position = UDim2.new(0, 0, 0, -22)
		label.Text = equipTitles[i]
		label.TextColor3 = Color3.fromRGB(180, 180, 220)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.Parent = slot

		self.equipSlots[i] = slot
	end

	-- Folders to hold rendered item frames
	self.itemsFolder = Instance.new("Folder", self.gridFrame)
	self.itemsFolder.Name = "Items"

	self.equipItemsFolder = Instance.new("Folder", self.equipFrame)
	self.equipItemsFolder.Name = "EquipItems"
end

function InventoryUI:toggle()
	self.isVisible = not self.isVisible
	self.gui.Enabled = self.isVisible
	-- When opening, always show cursor; when closing, only hide if the game normally hides it
	UserInputService.MouseIconEnabled = self.isVisible
	if self.isVisible then
		self:renderItems()
	end
end

function InventoryUI:renderItems()
	self.itemsFolder:ClearAllChildren()
	self.equipItemsFolder:ClearAllChildren()

	-- Grid items
	for _, item in ipairs(self.manager.items) do
		if not item.x or not item.y then continue end
		local w = item.rotated and item.h or item.w
		local h = item.rotated and item.w or item.h

		local frame = Instance.new("TextButton")
		frame.Text = item.name
		frame.TextScaled = true
		frame.TextColor3 = Color3.fromRGB(255, 255, 255)
		frame.BackgroundColor3 = item.color or Color3.fromRGB(80, 80, 180)
		frame.BackgroundTransparency = 0.15
		frame.Size = UDim2.new(0, w * self.cellSize - 3, 0, h * self.cellSize - 3)
		frame.Position = UDim2.new(0, (item.x - 1) * self.cellSize + 1, 0, (item.y - 1) * self.cellSize + 1)
		frame.ZIndex = 2
		frame.Parent = self.itemsFolder
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 3)

		frame.MouseButton1Down:Connect(function()
			self:startDrag(item, frame, "grid")
		end)
	end

	-- Equip slot items
	local equipNames = {"Primary", "Secondary", "Consumable", "Throwable"}
	for i, name in ipairs(equipNames) do
		local item = self.equips[name]
		if item then
			local slot = self.equipSlots[i]
			local frame = Instance.new("TextButton")
			frame.Text = item.name
			frame.TextScaled = true
			frame.TextColor3 = Color3.fromRGB(255, 255, 255)
			frame.BackgroundColor3 = item.color or Color3.fromRGB(80, 80, 180)
			frame.BackgroundTransparency = 0.15
			frame.Size = UDim2.new(1, -4, 1, -4)
			frame.Position = UDim2.new(0, 2, 0, 2)
			frame.ZIndex = 2
			frame.Parent = slot
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 3)

			frame.MouseButton1Down:Connect(function()
				self:startDrag(item, frame, name)
			end)
		end
	end
end

function InventoryUI:startDrag(item, frame, source)
	if self.draggingItem then return end -- Prevent double-drag

	self.draggingItem = item
	self.dragSource = source

	if source == "grid" then
		self.manager:removeItem(item)
	else
		self.equips[source] = nil
	end

	-- Detach the frame and float it over the GUI
	self.dragFrame = frame
	self.dragFrame.Parent = self.gui
	self.dragFrame.ZIndex = 20

	local mouse = Players.LocalPlayer:GetMouse()
	self.dragOffset = Vector2.new(
		mouse.X - frame.AbsolutePosition.X,
		mouse.Y - frame.AbsolutePosition.Y
	)

	self.dragConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and self.dragFrame then
			self.dragFrame.Position = UDim2.new(0, input.Position.X - self.dragOffset.X, 0, input.Position.Y - self.dragOffset.Y)
		end
	end)

	self.rotateConn = UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Enum.KeyCode.R and self.draggingItem then
			self.draggingItem.rotated = not self.draggingItem.rotated
			local w = self.draggingItem.rotated and self.draggingItem.h or self.draggingItem.w
			local h = self.draggingItem.rotated and self.draggingItem.w or self.draggingItem.h
			self.dragFrame.Size = UDim2.new(0, w * self.cellSize - 3, 0, h * self.cellSize - 3)
		end
	end)

	self.releaseConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:endDrag()
		end
	end)
end

function InventoryUI:endDrag()
	-- Disconnect listeners
	if self.dragConn then self.dragConn:Disconnect() self.dragConn = nil end
	if self.rotateConn then self.rotateConn:Disconnect() self.rotateConn = nil end
	if self.releaseConn then self.releaseConn:Disconnect() self.releaseConn = nil end

	local item = self.draggingItem
	self.draggingItem = nil

	if not item then return end
	if self.dragFrame then self.dragFrame:Destroy() self.dragFrame = nil end

	local mouse = Players.LocalPlayer:GetMouse()

	-- Check equip slots first
	local equipNames = {"Primary", "Secondary", "Consumable", "Throwable"}
	for i, slot in ipairs(self.equipSlots) do
		local absPos = slot.AbsolutePosition
		local absSize = slot.AbsoluteSize
		if mouse.X >= absPos.X and mouse.X <= absPos.X + absSize.X
			and mouse.Y >= absPos.Y and mouse.Y <= absPos.Y + absSize.Y then
			-- Swap if occupied
			local slotName = equipNames[i]
			local oldItem = self.equips[slotName]
			if oldItem then
				self.manager:addItem(oldItem)
			end
			self.equips[slotName] = item
			self:renderItems()
			return
		end
	end

	-- Try to place in grid at mouse position
	local gridAbs = self.gridFrame.AbsolutePosition
	local relX = mouse.X - gridAbs.X
	local relY = mouse.Y - gridAbs.Y
	local gridX = math.floor(relX / self.cellSize) + 1
	local gridY = math.floor(relY / self.cellSize) + 1

	if self.manager:canPlaceItem(item, gridX, gridY, item.rotated) then
		self.manager:placeItem(item, gridX, gridY, item.rotated)
	else
		-- Return to any free slot; if grid full, drop in world
		if not self.manager:addItem(item) then
			print("Inventory full – item dropped:", item.name)
			-- Physical drop with ProximityPrompt
			local char = Players.LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and item.model then
				local drop = item.model:Clone()
				for _, p in ipairs(drop:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = false
						p.CanCollide = true
						p.Massless = false
					end
				end
				if drop.PrimaryPart then
					drop.PrimaryPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
				end
				drop.Parent = workspace
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Pick up"
				prompt.ObjectText = item.name
				prompt.RequiresLineOfSight = false
				prompt.Parent = drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")
				local capturedItem = item
				prompt.Triggered:Connect(function(pl)
					if pl == Players.LocalPlayer then
						if self.manager:addItem(capturedItem) then
							drop:Destroy()
							self:renderItems()
						else
							print("Inventory still full!")
						end
					end
				end)
			end
		end
	end

	self:renderItems()
end

return InventoryUI
