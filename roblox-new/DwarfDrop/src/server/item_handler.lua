-- DwarfDrop: item_handler.lua
-- Server-side active item state: backpacks, water, placed items

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local ItemData    = require(game.ReplicatedStorage.Shared.item_data)

local ItemHandler = {}

-- backpacks[userId] = { {itemId, count}, {itemId, count}, {itemId, count}, {itemId, count} }
local backpacks = {}

-- waterLevels[userId] = number (0-5)
local waterLevels = {}

-- placedItems[userId] = list of world instances placed by this player
local placedItems = {}

local BACKPACK_SLOTS = 4

local function emptyBackpack()
    local bp = {}
    for i = 1, BACKPACK_SLOTS do
        bp[i] = nil
    end
    return bp
end

function ItemHandler.InitPlayer(player)
    local uid = player.UserId
    backpacks[uid]   = emptyBackpack()
    waterLevels[uid] = 0
    placedItems[uid] = {}
end

function ItemHandler.CleanupPlayer(player)
    local uid = player.UserId
    -- Destroy placed items in world
    if placedItems[uid] then
        for _, inst in ipairs(placedItems[uid]) do
            if inst and inst.Parent then
                inst:Destroy()
            end
        end
    end
    backpacks[uid]   = nil
    waterLevels[uid] = nil
    placedItems[uid] = nil
end

function ItemHandler.GetBackpack(player)
    return backpacks[player.UserId] or emptyBackpack()
end

-- Add item to first available slot; returns slot index or nil if full
function ItemHandler.GiveItem(player, itemId, count)
    local uid = player.UserId
    if not backpacks[uid] then return nil end
    count = count or 1

    -- Try to stack with existing slot of same item
    for i = 1, BACKPACK_SLOTS do
        local slot = backpacks[uid][i]
        if slot and slot.itemId == itemId then
            local def = ItemData.Items[itemId]
            local maxCount = def and def.maxCount or 99
            if slot.count < maxCount then
                slot.count = math.min(maxCount, slot.count + count)
                ItemHandler._PushBackpack(player)
                return i
            end
        end
    end

    -- Find empty slot
    for i = 1, BACKPACK_SLOTS do
        if not backpacks[uid][i] then
            backpacks[uid][i] = { itemId = itemId, count = count }
            ItemHandler._PushBackpack(player)
            return i
        end
    end

    return nil  -- full
end

-- Remove one use of equipped item in slot
function ItemHandler.ConsumeItem(player, slotIndex)
    local uid = player.UserId
    if not backpacks[uid] then return false end
    local slot = backpacks[uid][slotIndex]
    if not slot then return false end
    slot.count = slot.count - 1
    if slot.count <= 0 then
        backpacks[uid][slotIndex] = nil
    end
    ItemHandler._PushBackpack(player)
    return true
end

function ItemHandler.ClearBackpack(player)
    local uid = player.UserId
    if backpacks[uid] then
        backpacks[uid] = emptyBackpack()
        ItemHandler._PushBackpack(player)
    end
end

function ItemHandler._PushBackpack(player)
    Networking.FireClient(Networking.Events.BackpackUpdate, player,
        backpacks[player.UserId])
end

-- Water system
function ItemHandler.GetWater(player)
    return waterLevels[player.UserId] or 0
end

function ItemHandler.AddWater(player, amount)
    local uid = player.UserId
    waterLevels[uid] = math.min(5, (waterLevels[uid] or 0) + amount)
    Networking.FireClient(Networking.Events.WaterUpdate, player,
        waterLevels[uid], 5)
end

function ItemHandler.SpendWater(player, amount)
    local uid = player.UserId
    local current = waterLevels[uid] or 0
    if current < amount then return false end
    waterLevels[uid] = current - amount
    Networking.FireClient(Networking.Events.WaterUpdate, player,
        waterLevels[uid], 5)
    return true
end

-- Register a placed world item for cleanup tracking
function ItemHandler.TrackPlaced(player, instance)
    local uid = player.UserId
    if placedItems[uid] then
        table.insert(placedItems[uid], instance)
    end
end

-- ==================== REMOTE HANDLERS ====================

-- Collect item crate
Networking.OnServer(Networking.Events.CollectItem, function(player, crateId)
    -- Find the crate in workspace by tag
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "BaseCrate" then
            local tag = obj:FindFirstChild("CrateId")
            if tag and tag.Value == tostring(crateId) then
                local itemTag  = obj:FindFirstChild("ItemId")
                local countTag = obj:FindFirstChild("ItemCount")
                if itemTag then
                    local itemId = itemTag.Value
                    local count  = countTag and countTag.Value or 1
                    local slot   = ItemHandler.GiveItem(player, itemId, count)
                    if slot then
                        Networking.FireClient(Networking.Events.ItemPickup, player, itemId, count)
                        -- Destroy the crate model
                        local model = obj.Parent
                        if model and model:IsA("Model") then
                            model:Destroy()
                        else
                            obj:Destroy()
                        end
                    end
                end
                return
            end
        end
    end
end)

-- Use active item
Networking.OnServer(Networking.Events.UseActiveItem, function(player, slotIndex, extraData)
    local uid = player.UserId
    if not backpacks[uid] then return end
    slotIndex = tonumber(slotIndex)
    if not slotIndex then return end
    local slot = backpacks[uid][slotIndex]
    if not slot then return end

    local def = ItemData.Items[slot.itemId]
    if not def then return end

    -- Water-consuming items
    if def.waterCostPerUse then
        if not ItemHandler.SpendWater(player, def.waterCostPerUse) then
            return  -- not enough water
        end
    end

    -- One-use items consume on use
    if def.useType == "use" then
        -- Special: WaterCooler refills water
        if slot.itemId == "WaterCooler" then
            ItemHandler.AddWater(player, def.waterAmount or 5)
        end
        ItemHandler.ConsumeItem(player, slotIndex)
    end

    Networking.FireClient(Networking.Events.ItemUsed, player, slotIndex, slot.itemId,
        slot.count or 0, extraData)
end)

-- Equip slot
Networking.OnServer(Networking.Events.EquipSlot, function(player, slotIndex)
    -- Acknowledged; client manages which slot is active
    Networking.FireClient(Networking.Events.EquipSlot, player, slotIndex)
end)

return ItemHandler
