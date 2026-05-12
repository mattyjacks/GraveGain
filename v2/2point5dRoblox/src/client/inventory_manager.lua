local InventoryManager = {}
InventoryManager.__index = InventoryManager

function InventoryManager.new()
	local self = setmetatable({}, InventoryManager)
	self.width = 10
	self.height = 5
	self.grid = {} -- 2D array: grid[x][y] = item or nil
	self.items = {} -- list of items
	
	for x = 1, self.width do
		self.grid[x] = {}
		for y = 1, self.height do
			self.grid[x][y] = nil
		end
	end
	
	return self
end

function InventoryManager:canPlaceItem(item, startX, startY, rotated)
	local w = rotated and item.h or item.w
	local h = rotated and item.w or item.h
	
	if startX < 1 or startY < 1 or startX + w - 1 > self.width or startY + h - 1 > self.height then
		return false
	end
	
	for x = startX, startX + w - 1 do
		for y = startY, startY + h - 1 do
			if self.grid[x][y] ~= nil and self.grid[x][y] ~= item then
				return false
			end
		end
	end
	return true
end

function InventoryManager:placeItem(item, startX, startY, rotated)
	if not self:canPlaceItem(item, startX, startY, rotated) then return false end
	
	-- Remove from old position if it exists
	if item.x and item.y then
		local oldW = item.rotated and item.h or item.w
		local oldH = item.rotated and item.w or item.h
		for x = item.x, item.x + oldW - 1 do
			for y = item.y, item.y + oldH - 1 do
				self.grid[x][y] = nil
			end
		end
	end
	
	item.x = startX
	item.y = startY
	item.rotated = rotated
	
	local w = rotated and item.h or item.w
	local h = rotated and item.w or item.h
	for x = startX, startX + w - 1 do
		for y = startY, startY + h - 1 do
			self.grid[x][y] = item
		end
	end
	
	if not table.find(self.items, item) then
		table.insert(self.items, item)
	end
	
	return true
end

function InventoryManager:removeItem(item)
	if not item.x or not item.y then return end
	local w = item.rotated and item.h or item.w
	local h = item.rotated and item.w or item.h
	for x = item.x, item.x + w - 1 do
		for y = item.y, item.y + h - 1 do
			self.grid[x][y] = nil
		end
	end
	item.x = nil
	item.y = nil
	local idx = table.find(self.items, item)
	if idx then table.remove(self.items, idx) end
end

function InventoryManager:findFreeSpace(item)
	for y = 1, self.height do
		for x = 1, self.width do
			if self:canPlaceItem(item, x, y, false) then
				return x, y, false
			end
			if item.w ~= item.h and self:canPlaceItem(item, x, y, true) then
				return x, y, true
			end
		end
	end
	return nil
end

function InventoryManager:addItem(item)
	local x, y, rot = self:findFreeSpace(item)
	if x then
		return self:placeItem(item, x, y, rot)
	end
	return false
end

return InventoryManager
