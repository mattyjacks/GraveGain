local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CollectionTracker = {}
local GameData

-- State
local state = {
    jetSky = nil,
    clientState = nil,
    collectedRings = {},
    nearbyRings = {},
    checkRate = 0.1,
    lastCheck = 0
}

-- Remotes
local CollectRing = nil

function CollectionTracker:Init(jetSky, clientState)
    GameData = require(ReplicatedStorage.Shared.game_data)
    
    state.jetSky = jetSky
    state.clientState = clientState
    
    -- Get remote event
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        CollectRing = remotes:WaitForChild("CollectRing", 5)
    end
    
    -- Find all ring triggers
    self:ScanForRings()
    
    print("[CollectionTracker] Initialized")
end

function CollectionTracker:ScanForRings()
    state.nearbyRings = {}
    
    local ringsFolder = Workspace:FindFirstChild("Rings")
    if not ringsFolder then return end
    
    for _, trigger in ipairs(ringsFolder:GetDescendants()) do
        if trigger.Name == "Trigger" and trigger:IsA("BasePart") then
            table.insert(state.nearbyRings, trigger)
        end
    end
end

function CollectionTracker:Update(dt)
    state.lastCheck = state.lastCheck + dt
    if state.lastCheck < state.checkRate then return end
    state.lastCheck = 0
    
    if not state.jetSky then return end
    
    -- Try detailed model hull first, fallback to simple
    local hull = state.jetSky:FindFirstChild("HullLower") or state.jetSky:FindFirstChild("Hull")
    if not hull then return end
    
    local jetSkyPos = hull.Position
    local collectRadius = GameData.RING_SIZE + 10
    
    -- Check each ring
    for i = #state.nearbyRings, 1, -1 do
        local trigger = state.nearbyRings[i]
        if not trigger or not trigger.Parent then
            table.remove(state.nearbyRings, i)
            continue
        end
        
        local distance = (trigger.Position - jetSkyPos).Magnitude
        if distance <= collectRadius then
            self:CollectRing(trigger)
        end
    end
end

function CollectionTracker:CollectRing(trigger)
    local value = trigger:FindFirstChild("Value")
    local ringValue = value and value.Value or 1
    local isHidden = trigger:FindFirstChild("IsHidden") ~= nil
    
    -- Get ring visual parts
    local ring = trigger:FindFirstChild("Ring")
    local hole = trigger:FindFirstChild("Hole")
    
    -- Play collection animation
    self:AnimateCollection(ring, hole)
    
    -- Tell server
    if CollectRing then
        CollectRing:FireServer(trigger)
    end
    
    -- Remove from local tracking
    for i, r in ipairs(state.nearbyRings) do
        if r == trigger then
            table.remove(state.nearbyRings, i)
            break
        end
    end
end

function CollectionTracker:AnimateCollection(ring, hole)
    if ring then
        -- Spin and scale up effect
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        local spinTween = TweenService:Create(ring, tweenInfo, {
            Orientation = ring.Orientation + Vector3.new(0, 360, 0),
            Size = ring.Size * 1.5,
            Transparency = 0.8
        })
        
        spinTween:Play()
        
        -- Destroy after animation
        task.delay(0.3, function()
            if ring then ring:Destroy() end
            if hole then hole:Destroy() end
        end)
    end
    
    -- Particle effect at collection point
    self:SpawnCollectParticles(ring and ring.Position or Vector3.zero)
end

function CollectionTracker:SpawnCollectParticles(position)
    local particlePart = Instance.new("Part")
    particlePart.Anchored = true
    particlePart.CanCollide = false
    particlePart.Transparency = 1
    particlePart.Size = Vector3.new(1, 1, 1)
    particlePart.Position = position
    particlePart.Parent = Workspace
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = GameData.ParticleSettings.RING_COLLECT.color
    emitter.Size = GameData.ParticleSettings.RING_COLLECT.size
    emitter.Lifetime = NumberRange.new(GameData.ParticleSettings.RING_COLLECT.lifetime)
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(GameData.ParticleSettings.RING_COLLECT.speed)
    emitter.Acceleration = Vector3.new(0, 10, 0)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Parent = particlePart
    
    -- Emit burst of particles
    emitter:Emit(20)
    
    task.delay(1, function()
        particlePart:Destroy()
    end)
end

return CollectionTracker
