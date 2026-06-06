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
    
    -- Rings live inside island models under Workspace.Islands
    local islandsFolder = Workspace:FindFirstChild("Islands")
    if islandsFolder then
        for _, trigger in ipairs(islandsFolder:GetDescendants()) do
            if trigger.Name == "Trigger" and trigger:IsA("BasePart") then
                table.insert(state.nearbyRings, trigger)
            end
        end
    end
    
    -- Also check legacy Rings folder if present
    local ringsFolder = Workspace:FindFirstChild("Rings")
    if ringsFolder then
        for _, trigger in ipairs(ringsFolder:GetDescendants()) do
            if trigger.Name == "Trigger" and trigger:IsA("BasePart") then
                table.insert(state.nearbyRings, trigger)
            end
        end
    end
end

-- Rescan counter for periodic ring discovery
local rescanTimer = 0
local RESCAN_RATE = 3.0

function CollectionTracker:Update(dt)
    state.lastCheck = state.lastCheck + dt
    rescanTimer = rescanTimer + dt
    
    -- Periodically rescan for newly added rings
    if rescanTimer >= RESCAN_RATE then
        rescanTimer = 0
        self:ScanForRings()
    end
    
    if state.lastCheck < state.checkRate then return end
    state.lastCheck = 0
    
    if not state.jetSky then return end
    
    -- Use PrimaryPart first, then any hull part
    local hull = state.jetSky.PrimaryPart
        or state.jetSky:FindFirstChild("HullLower")
        or state.jetSky:FindFirstChild("Hull")
        or state.jetSky:FindFirstChildWhichIsA("BasePart")
    if not hull then return end
    
    local jetSkyPos = hull.Position
    local collectRadius = GameData.RING_SIZE + 8
    
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
    
    -- Ring visual parts are siblings in the parent Model (Outer, Inner)
    local ringModel = trigger.Parent
    local outer = ringModel and ringModel:FindFirstChild("Outer")
    local inner = ringModel and ringModel:FindFirstChild("Inner")
    
    -- Play collection animation
    self:AnimateCollection(outer, inner, trigger.Position)
    
    -- Remove from local tracking immediately to prevent double-collect
    for i, r in ipairs(state.nearbyRings) do
        if r == trigger then
            table.remove(state.nearbyRings, i)
            break
        end
    end
    
    -- Tell server (server will destroy the model)
    if CollectRing then
        CollectRing:FireServer(trigger)
    end
end

function CollectionTracker:AnimateCollection(outer, inner, position)
    local collectPos = position or Vector3.zero
    
    if outer then
        collectPos = outer.Position
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local spinTween = TweenService:Create(outer, tweenInfo, {
            Size = outer.Size * 1.8,
            Transparency = 0.9
        })
        spinTween:Play()
    end
    
    if inner then
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local innerTween = TweenService:Create(inner, tweenInfo, {
            Size = inner.Size * 2,
            Transparency = 1.0
        })
        innerTween:Play()
    end
    
    -- Particle effect at collection point
    self:SpawnCollectParticles(collectPos)
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
