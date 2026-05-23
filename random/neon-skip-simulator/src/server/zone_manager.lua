--[[
    Neon Skip Simulator - Zone Manager
    Handles zone unlocks and collision gates
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.game_config)

-- Zone gates in workspace
local zoneGates = {}

-- Initialize zone gates
local function setupZoneGates()
    local zonesFolder = workspace:FindFirstChild("Zones")
    if not zonesFolder then return end
    
    for i, zone in ipairs(GameConfig.ZONES) do
        if i == 1 then continue end -- First zone has no gate
        
        local gate = zonesFolder:FindFirstChild("Gate_" .. zone.id)
        if gate then
            zoneGates[zone.id] = {
                part = gate,
                requiredMomentum = zone.requiredMomentum,
                label = gate:FindFirstChild("BillboardGui")
            }
            
            -- Initial collision enabled
            gate.CanCollide = true
            
            -- Update label
            if gate:FindFirstChild("BillboardGui") then
                local textLabel = gate.BillboardGui:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.Text = zone.name .. "\n" .. tostring(zone.requiredMomentum) .. " Momentum"
                end
            end
        end
    end
end

-- Check and update gates for player
local function updateGatesForPlayer(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local momentum = leaderstats.Momentum.Value
    
    for zoneId, gateData in pairs(zoneGates) do
        if momentum >= gateData.requiredMomentum then
            -- Player has unlocked this gate - disable collision for them
            -- Use collision groups or simply open for all once anyone unlocks
            gateData.part.CanCollide = false
            gateData.part.Transparency = 0.9
            
            -- Update visual
            if gateData.label then
                local textLabel = gateData.label:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.Text = "UNLOCKED"
                    textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                end
            end
        end
    end
end

-- Listen for momentum changes
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for leaderstats
        updateGatesForPlayer(player)
    end)
    
    -- Watch for momentum changes
    local leaderstats = player:WaitForChild("leaderstats")
    local momentumStat = leaderstats:WaitForChild("Momentum")
    
    momentumStat.Changed:Connect(function()
        updateGatesForPlayer(player)
    end)
end)

-- Initial setup
task.wait(2)
setupZoneGates()

-- Periodically update all gates
while true do
    task.wait(5)
    for _, player in ipairs(Players:GetPlayers()) do
        updateGatesForPlayer(player)
    end
end
