local JetSkyModels = {}
local GameData = require(script.Parent:WaitForChild("game_data"))

function JetSkyModels.CreateJetSky(color)
    color = color or Color3.fromRGB(0, 150, 255)
    
    local model = Instance.new("Model")
    model.Name = "JetSky"
    
    -- Main Hull
    local hull = Instance.new("Part")
    hull.Name = "Hull"
    hull.Shape = Enum.PartType.Block
    hull.Size = Vector3.new(4, 1.5, 8)
    hull.Color = color
    hull.Material = Enum.Material.SmoothPlastic
    hull.TopSurface = Enum.SurfaceType.Smooth
    hull.BottomSurface = Enum.SurfaceType.Smooth
    hull.Anchored = false
    hull.CanCollide = true
    hull.Parent = model
    
    -- Seat
    local seat = Instance.new("VehicleSeat")
    seat.Name = "Seat"
    seat.Size = Vector3.new(2, 0.5, 2)
    seat.Color = Color3.fromRGB(50, 50, 50)
    seat.Material = Enum.Material.SmoothPlastic
    seat.TopSurface = Enum.SurfaceType.Smooth
    seat.BottomSurface = Enum.SurfaceType.Smooth
    seat.Anchored = false
    seat.CanCollide = true
    seat.Disabled = false
    seat.Headrest = false
    seat.TorsoOnly = false
    seat.Parent = model
    seat.CFrame = CFrame.new(0, 0.5, 0.5)
    
    -- Handlebars
    local handlebars = Instance.new("Part")
    handlebars.Name = "Handlebars"
    handlebars.Shape = Enum.PartType.Cylinder
    handlebars.Size = Vector3.new(3, 0.3, 0.3)
    handlebars.Color = Color3.fromRGB(80, 80, 80)
    handlebars.Material = Enum.Material.Metal
    handlebars.TopSurface = Enum.SurfaceType.Smooth
    handlebars.BottomSurface = Enum.SurfaceType.Smooth
    handlebars.Anchored = false
    handlebars.CanCollide = false
    handlebars.Parent = model
    handlebars.CFrame = CFrame.new(0, 1.2, -2.5) * CFrame.Angles(0, 0, math.rad(90))
    
    -- Left Thruster
    local leftThruster = Instance.new("Part")
    leftThruster.Name = "LeftThruster"
    leftThruster.Shape = Enum.PartType.Cylinder
    leftThruster.Size = Vector3.new(2, 0.8, 0.8)
    leftThruster.Color = Color3.fromRGB(60, 60, 60)
    leftThruster.Material = Enum.Material.Metal
    leftThruster.TopSurface = Enum.SurfaceType.Smooth
    leftThruster.BottomSurface = Enum.SurfaceType.Smooth
    leftThruster.Anchored = false
    leftThruster.CanCollide = false
    leftThruster.Parent = model
    leftThruster.CFrame = CFrame.new(-1.2, -0.5, 3) * CFrame.Angles(0, 0, math.rad(90))
    
    -- Right Thruster
    local rightThruster = Instance.new("Part")
    rightThruster.Name = "RightThruster"
    rightThruster.Shape = Enum.PartType.Cylinder
    rightThruster.Size = Vector3.new(2, 0.8, 0.8)
    rightThruster.Color = Color3.fromRGB(60, 60, 60)
    rightThruster.Material = Enum.Material.Metal
    rightThruster.TopSurface = Enum.SurfaceType.Smooth
    rightThruster.BottomSurface = Enum.SurfaceType.Smooth
    rightThruster.Anchored = false
    rightThruster.CanCollide = false
    rightThruster.Parent = model
    rightThruster.CFrame = CFrame.new(1.2, -0.5, 3) * CFrame.Angles(0, 0, math.rad(90))
    
    -- Thruster Glow (Left)
    local leftGlow = Instance.new("Part")
    leftGlow.Name = "LeftGlow"
    leftGlow.Shape = Enum.PartType.Block
    leftGlow.Size = Vector3.new(0.6, 0.6, 0.2)
    leftGlow.Color = Color3.fromRGB(0, 200, 255)
    leftGlow.Material = Enum.Material.Neon
    leftGlow.TopSurface = Enum.SurfaceType.Smooth
    leftGlow.BottomSurface = Enum.SurfaceType.Smooth
    leftGlow.Anchored = false
    leftGlow.CanCollide = false
    leftGlow.Parent = model
    leftGlow.CFrame = CFrame.new(-1.2, -0.5, 4) * CFrame.Angles(0, math.rad(90), 0)
    
    -- Thruster Glow (Right)
    local rightGlow = Instance.new("Part")
    rightGlow.Name = "RightGlow"
    rightGlow.Shape = Enum.PartType.Block
    rightGlow.Size = Vector3.new(0.6, 0.6, 0.2)
    rightGlow.Color = Color3.fromRGB(0, 200, 255)
    rightGlow.Material = Enum.Material.Neon
    rightGlow.TopSurface = Enum.SurfaceType.Smooth
    rightGlow.BottomSurface = Enum.SurfaceType.Smooth
    rightGlow.Anchored = false
    rightGlow.CanCollide = false
    rightGlow.Parent = model
    rightGlow.CFrame = CFrame.new(1.2, -0.5, 4) * CFrame.Angles(0, math.rad(90), 0)
    
    -- Primary Part
    model.PrimaryPart = hull
    
    -- Weld constraints
    local function weld(part0, part1)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part0
        weld.Part1 = part1
        weld.Parent = part0
    end
    
    weld(hull, seat)
    weld(hull, handlebars)
    weld(hull, leftThruster)
    weld(hull, rightThruster)
    weld(leftThruster, leftGlow)
    weld(rightThruster, rightGlow)
    
    -- Anchor the hull after welds are created
    task.defer(function()
        hull.Anchored = false
    end)
    
    return model
end

function JetSkyModels.CreateThrusterParticles(parent, settings)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = settings.color
    emitter.Size = settings.size
    emitter.Lifetime = NumberRange.new(settings.lifetime)
    emitter.Rate = settings.rate
    emitter.Speed = NumberRange.new(settings.speed)
    emitter.Acceleration = Vector3.new(0, -5, 0)
    emitter.SpreadAngle = Vector2.new(10, 10)
    emitter.Parent = parent
    
    return emitter
end

function JetSkyModels.CreateRing(position, value)
    value = value or 1
    
    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(1, GameData.RING_SIZE, GameData.RING_SIZE)
    ring.Color = Color3.fromRGB(255, 215, 0)
    ring.Material = Enum.Material.Neon
    ring.TopSurface = Enum.SurfaceType.Smooth
    ring.BottomSurface = Enum.SurfaceType.Smooth
    ring.Anchored = true
    ring.CanCollide = false
    ring.Position = position
    ring.Transparency = 0.3
    
    -- Inner hole visual
    local hole = Instance.new("Part")
    hole.Name = "Hole"
    hole.Shape = Enum.PartType.Cylinder
    hole.Size = Vector3.new(1.1, GameData.RING_SIZE * 0.6, GameData.RING_SIZE * 0.6)
    hole.Color = Color3.fromRGB(100, 150, 255)
    hole.Material = Enum.Material.Neon
    hole.TopSurface = Enum.SurfaceType.Smooth
    hole.BottomSurface = Enum.SurfaceType.Smooth
    hole.Anchored = true
    hole.CanCollide = false
    hole.Position = position
    
    -- Collection trigger
    local trigger = Instance.new("Part")
    trigger.Name = "Trigger"
    trigger.Shape = Enum.PartType.Ball
    trigger.Size = Vector3.new(GameData.RING_SIZE + 5, GameData.RING_SIZE + 5, GameData.RING_SIZE + 5)
    trigger.Transparency = 1
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.Position = position
    
    local valueAttr = Instance.new("IntValue")
    valueAttr.Name = "Value"
    valueAttr.Value = value
    valueAttr.Parent = trigger
    
    return ring, hole, trigger
end

function JetSkyModels.CreateCloudPlatform(position, size)
    local cloud = Instance.new("Part")
    cloud.Name = "Cloud"
    cloud.Shape = Enum.PartType.Ball
    cloud.Size = Vector3.new(size, size * 0.3, size)
    cloud.Color = Color3.fromRGB(240, 248, 255)
    cloud.Material = Enum.Material.SmoothPlastic
    cloud.TopSurface = Enum.SurfaceType.Smooth
    cloud.BottomSurface = Enum.SurfaceType.Smooth
    cloud.Anchored = true
    cloud.CanCollide = true
    cloud.Position = position
    cloud.Transparency = 0.2
    
    return cloud
end

return JetSkyModels
