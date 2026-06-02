local DataStoreService = game:GetService("DataStoreService")
local SaveManager = {}

local DATASTORE_NAME = "JetSkiesData"
local dataStore
local dataCache = {}

local function getDataStore()
    if not dataStore then
        local success, result = pcall(function()
            return DataStoreService:GetDataStore(DATASTORE_NAME)
        end)
        
        if success then
            dataStore = result
        else
            warn("[SaveManager] Failed to get DataStore:", result)
        end
    end
    return dataStore
end

function SaveManager.Load(player)
    local store = getDataStore()
    if not store then
        return {rings = 0, upgrades = {SPEED = 1, BOOST = 1, HANDLING = 1}, highestAltitude = 0, islandsDiscovered = 0}
    end
    
    local key = tostring(player.UserId)
    local success, data = pcall(function()
        return store:GetAsync(key)
    end)
    
    if success and data then
        dataCache[player.UserId] = data
        return data
    else
        -- Return default data
        return {rings = 0, upgrades = {SPEED = 1, BOOST = 1, HANDLING = 1}, highestAltitude = 0, islandsDiscovered = 0}
    end
end

function SaveManager.Save(player, data)
    local store = getDataStore()
    if not store then return false end
    
    local key = tostring(player.UserId)
    local success, err = pcall(function()
        store:SetAsync(key, data)
    end)
    
    if success then
        dataCache[player.UserId] = data
        return true
    else
        warn("[SaveManager] Failed to save data for", player.Name, ":", err)
        return false
    end
end

return SaveManager
