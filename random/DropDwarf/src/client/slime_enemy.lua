-- DropDwarf: slime_enemy.lua
-- Client-side slime cube enemies: 4 sizes, patrol AI, death split, slime projectiles,
-- terrain sliming (speed boost + slip physics), pickaxe kill detection.

local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")

local Networking = require(game.ReplicatedStorage.Shared.networking)

local SlimeEnemy = {}
SlimeEnemy.__index = SlimeEnemy

-- ============================================================
-- CONSTANTS
-- ============================================================

local SLIME_GREEN   = Color3.fromRGB(40, 200, 60)
local SLIME_DARK    = Color3.fromRGB(20, 140, 35)
local SLIME_GLOW    = Color3.fromRGB(80, 255, 100)
local SLIME_TRAIL   = Color3.fromRGB(50, 220, 70)

-- Size configs: [scale, HP proxy (visual only), speed]
local SIZE_CONFIG = {
    Large  = { scale = 4.0, speed = 4,  splitInto = "Medium", splits = 2 },
    Medium = { scale = 2.5, speed = 6,  splitInto = "Small",  splits = 0 },
    Small  = { scale = 1.5, speed = 8,  splitInto = nil,      splits = 0 },
    Tiny   = { scale = 0.8, speed = 10, splitInto = nil,      splits = 0 },
}

-- Slime trail data: { partId -> { part, timestamp } }
local slimedParts = {} -- partId (string) -> { part, expireTime }
local SLIME_DURATION = 60 -- seconds
local SLIME_SPEED_MULT = 1.55 -- 55% faster on slimed terrain

-- ============================================================
-- MODULE STATE
-- ============================================================
local allSlimes = {} -- array of slime instance tables
local slimeFolder = nil
local playerRef = nil
local isActive = false
local heartbeatConn = nil

-- ============================================================
-- SLIMED TERRAIN TRACKING
-- ============================================================

-- Returns true if a given part is currently slimed
function SlimeEnemy.IsSlimed(part)
    if not part then return false end
    local id = tostring(part)  -- unique per-instance, no Plugin capability needed
    local record = slimedParts[id]
    if not record then return false end
    if tick() > record.expireTime then
        -- Expired: clean up
        if record.overlay and record.overlay.Parent then
            record.overlay:Destroy()
        end
        slimedParts[id] = nil
        return false
    end
    return true
end

-- Mark a part as slimed for SLIME_DURATION seconds
local function slimePart(part)
    if not part or not part:IsA("BasePart") then return end
    local id = tostring(part)  -- unique per-instance, no Plugin capability needed
    local expiry = tick() + SLIME_DURATION

    -- If already slimed, just refresh
    if slimedParts[id] then
        slimedParts[id].expireTime = expiry
        return
    end

    -- Create a thin green overlay on top of the part
    local overlay = Instance.new("Part")
    overlay.Name = "SlimeOverlay"
    overlay.Size = Vector3.new(part.Size.X, 0.2, part.Size.Z)
    overlay.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 + 0.1, 0)
    overlay.Anchored = true
    overlay.CanCollide = false
    overlay.CastShadow = false
    overlay.Color = SLIME_TRAIL
    overlay.Material = Enum.Material.Neon
    overlay.Transparency = 0.35
    overlay.Parent = workspace

    -- Glow
    local pl = Instance.new("PointLight")
    pl.Brightness = 0.5
    pl.Range = 6
    pl.Color = SLIME_GLOW
    pl.Parent = overlay

    slimedParts[id] = { part = part, overlay = overlay, expireTime = expiry }

    -- Tag the part itself with a SlimeTrail value for server reference
    local tag = part:FindFirstChild("SlimeTrail")
    if not tag then
        tag = Instance.new("BoolValue")
        tag.Name = "SlimeTrail"
        tag.Parent = part
    end
    tag.Value = true

    -- Auto-remove after duration
    task.delay(SLIME_DURATION, function()
        local rec = slimedParts[id]
        if rec then
            if rec.overlay and rec.overlay.Parent then
                rec.overlay:Destroy()
            end
            slimedParts[id] = nil
            local t2 = part:FindFirstChild("SlimeTrail")
            if t2 then t2:Destroy() end
        end
    end)
end

-- Periodically expire old slimed parts (belt-and-suspenders cleanup)
local function cleanupSlimed()
    local now = tick()
    for id, rec in pairs(slimedParts) do
        if now > rec.expireTime then
            if rec.overlay and rec.overlay.Parent then rec.overlay:Destroy() end
            slimedParts[id] = nil
        end
    end
end

-- ============================================================
-- SLIME PROJECTILE
-- ============================================================

local function fireSlimeProjectile(origin, direction, speed)
    local proj = Instance.new("Part")
    proj.Name = "SlimeProjectile"
    proj.Shape = Enum.PartType.Ball
    proj.Size = Vector3.new(0.8, 0.8, 0.8)
    proj.Position = origin
    proj.Color = SLIME_GREEN
    proj.Material = Enum.Material.Neon
    proj.Transparency = 0.3
    proj.CanCollide = false
    proj.CastShadow = false
    proj.Anchored = false
    proj.Parent = workspace

    local pl = Instance.new("PointLight")
    pl.Brightness = 1.0; pl.Range = 6; pl.Color = SLIME_GLOW; pl.Parent = proj

    -- Apply velocity
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = direction.Unit * speed
    bv.MaxForce = Vector3.new(1e4, 1e4, 1e4)
    bv.Parent = proj

    -- Detect when it touches terrain
    local hitConn
    local lifeConn
    local alive = true
    local function onHit(hit)
        if not alive then return end
        if hit and hit:IsA("BasePart") and hit.Name ~= "SlimeProjectile" then
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and hit:IsDescendantOf(p.Character) then
                    isPlayer = true
                    break
                end
            end
            if not isPlayer then
                alive = false
                if hitConn then hitConn:Disconnect() end
                -- Slime the hit terrain
                slimePart(hit)
                -- Splat visual
                local splat = Instance.new("Part")
                splat.Name = "SlimeSplat"
                splat.Shape = Enum.PartType.Cylinder
                splat.Size = Vector3.new(0.3, 1.5, 1.5)
                splat.CFrame = CFrame.new(hit.Position + Vector3.new(0, hit.Size.Y/2 + 0.15, 0))
                    * CFrame.Angles(0, 0, math.pi/2)
                splat.Anchored = true
                splat.CanCollide = false
                splat.Color = SLIME_DARK
                splat.Material = Enum.Material.Neon
                splat.Transparency = 0.2
                splat.CastShadow = false
                splat.Parent = workspace
                proj:Destroy()
                -- Fade splat
                TweenService:Create(splat, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Transparency = 1 }):Play()
                task.delay(2.1, function() if splat.Parent then splat:Destroy() end end)
            end
        end
    end
    hitConn = proj.Touched:Connect(onHit)

    -- Self-destruct after 4s
    task.delay(4, function()
        alive = false
        if hitConn then hitConn:Disconnect() end
        if proj.Parent then proj:Destroy() end
    end)
end

-- Burst N slime projectiles in random directions from a position
local function burstSlime(origin, count)
    count = count or 6
    for i = 1, count do
        local angle  = (i / count) * math.pi * 2 + math.random() * 0.8
        local elevat = math.random() * math.pi * 0.5 -- upward arc
        local dir = Vector3.new(
            math.cos(angle) * math.cos(elevat),
            math.sin(elevat) + 0.3,
            math.sin(angle) * math.cos(elevat))
        local spd = math.random() * 20 + 15
        task.delay(i * 0.04, function()
            fireSlimeProjectile(origin, dir, spd)
        end)
    end
end

-- ============================================================
-- SLIME VISUAL CONSTRUCTION
-- ============================================================

local function buildSlimeModel(size, pos)
    local cfg = SIZE_CONFIG[size]
    local sc  = cfg.scale

    local model = Instance.new("Model")
    model.Name  = "SlimeCube_" .. size

    -- Body cube
    local body = Instance.new("Part")
    body.Name        = "Body"
    body.Size        = Vector3.new(sc, sc, sc)
    body.Position    = pos
    body.Anchored    = true
    body.CanCollide  = true
    body.Color       = SLIME_GREEN
    body.Material    = Enum.Material.Neon
    body.Transparency = 0.15
    body.CastShadow  = true
    body.TopSurface  = Enum.SurfaceType.Smooth
    body.BottomSurface = Enum.SurfaceType.Smooth
    body.Parent = model

    -- Inner darker cube (layered look)
    local inner = Instance.new("Part")
    inner.Name        = "Inner"
    inner.Size        = Vector3.new(sc * 0.65, sc * 0.65, sc * 0.65)
    inner.Position    = pos + Vector3.new(0, sc * 0.05, 0)
    inner.Anchored    = true
    inner.CanCollide  = false
    inner.CastShadow  = false
    inner.Color       = SLIME_DARK
    inner.Material    = Enum.Material.Neon
    inner.Transparency = 0.5
    inner.TopSurface  = Enum.SurfaceType.Smooth
    inner.BottomSurface = Enum.SurfaceType.Smooth
    inner.Parent = model

    -- Glow point light
    local pl = Instance.new("PointLight")
    pl.Brightness = 1.5
    pl.Range      = sc * 4
    pl.Color      = SLIME_GLOW
    pl.Parent     = body

    -- Eyes (two small bright cubes)
    local eyeOffset = sc * 0.22
    for _, side in ipairs({ -1, 1 }) do
        local eye = Instance.new("Part")
        eye.Name         = "Eye"
        eye.Size         = Vector3.new(sc * 0.18, sc * 0.18, sc * 0.08)
        eye.Position     = pos + Vector3.new(side * eyeOffset, sc * 0.12, -sc * 0.48)
        eye.Anchored     = true
        eye.CanCollide   = false
        eye.CastShadow   = false
        eye.Color        = Color3.fromRGB(220, 255, 220)
        eye.Material     = Enum.Material.Neon
        eye.Transparency = 0
        eye.TopSurface   = Enum.SurfaceType.Smooth
        eye.BottomSurface = Enum.SurfaceType.Smooth
        eye.Parent = model

        local eyePl = Instance.new("PointLight")
        eyePl.Brightness = 0.8; eyePl.Range = sc * 2; eyePl.Color = Color3.fromRGB(180, 255, 180)
        eyePl.Parent = eye
    end

    -- Ooze drips (thin neon rods hanging below)
    local dripCount = math.floor(sc * 1.5)
    for d = 1, dripCount do
        local angle = (d / dripCount) * math.pi * 2
        local dr = sc * 0.3
        local drip = Instance.new("Part")
        drip.Name        = "Drip"
        drip.Size        = Vector3.new(sc * 0.1, sc * 0.35 + math.random() * sc * 0.2, sc * 0.1)
        drip.Position    = pos + Vector3.new(math.cos(angle) * dr, -sc * 0.55, math.sin(angle) * dr)
        drip.Anchored    = true
        drip.CanCollide  = false
        drip.CastShadow  = false
        drip.Color       = SLIME_TRAIL
        drip.Material    = Enum.Material.Neon
        drip.Transparency = 0.4
        drip.Parent = model
    end

    model.PrimaryPart = body
    model.Parent = workspace
    return model, body
end

-- ============================================================
-- SLIME INSTANCE
-- ============================================================

local SlimeInstance = {}
SlimeInstance.__index = SlimeInstance

local nextSlimeId = 1

function SlimeInstance.new(size, spawnPos, patrolEndPos)
    local self = setmetatable({}, SlimeInstance)
    self.id         = nextSlimeId
    nextSlimeId     = nextSlimeId + 1
    self.size       = size
    self.cfg        = SIZE_CONFIG[size]
    self.patrolA    = spawnPos
    self.patrolB    = patrolEndPos
    self.targetPos  = patrolEndPos
    self.dead       = false
    self.bobTime    = math.random() * math.pi * 2
    self.trailTimer = 0
    self.squishScale = 1

    local model, body = buildSlimeModel(size, spawnPos)
    self.model = model
    self.body  = body

    return self
end

function SlimeInstance:GetPosition()
    if self.body and self.body.Parent then
        return self.body.Position
    end
    return self.patrolA
end

function SlimeInstance:MoveTo(targetPos, dt)
    if not self.body or not self.body.Parent then return end
    local pos = self.body.Position
    local dir = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
    if dir.Magnitude < 1.5 then
        -- Reached target, flip patrol direction
        if self.targetPos == self.patrolB then
            self.targetPos = self.patrolA
        else
            self.targetPos = self.patrolB
        end
        return
    end
    local speed = self.cfg.speed
    local newPos = pos + dir.Unit * speed * dt

    -- Keep slime on ground (simple raycast)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { self.model }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(
        Vector3.new(newPos.X, pos.Y + 2, newPos.Z),
        Vector3.new(0, -8, 0),
        rayParams)
    local groundY = result and (result.Position.Y + self.cfg.scale / 2) or pos.Y
    self.body.Position = Vector3.new(newPos.X, groundY, newPos.Z)

    -- Keep inner/eye/drip parts in sync by moving entire model
    if self.model.PrimaryPart then
        self.model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(newPos.X, groundY, newPos.Z)))
    end

    -- Leave a slime trail on the ground under the slime
    self.trailTimer = self.trailTimer + dt
    if self.trailTimer > 1.0 then
        self.trailTimer = 0
        if result and result.Instance then
            slimePart(result.Instance)
        end
    end
end

function SlimeInstance:Bob(dt)
    if not self.body or not self.body.Parent then return end
    self.bobTime = self.bobTime + dt * 3
    -- Squish-and-stretch
    local bobY = math.sin(self.bobTime) * (self.cfg.scale * 0.06)
    local sc = self.cfg.scale
    local squishX = 1 + math.sin(self.bobTime * 2) * 0.04
    local squishY = 1 + math.cos(self.bobTime * 2) * 0.06
    self.body.Size = Vector3.new(sc * squishX, sc * squishY, sc * squishX)
end

function SlimeInstance:CheckPickaxeHit(pickaxeRootCF, isSwinging, isHeavy)
    -- Called each frame by the slime system; pickaxeRootCF is the pickaxe root CFrame
    if self.dead then return false end
    if not isSwinging then return false end
    if not self.body or not self.body.Parent then return false end
    local dist = (self.body.Position - pickaxeRootCF.Position).Magnitude
    local hitRange = self.cfg.scale * 1.5 + 4
    return dist < hitRange
end

function SlimeInstance:Die()
    if self.dead then return end
    self.dead = true

    local pos = self:GetPosition()
    local size = self.size
    local cfg  = self.cfg

    -- Slime burst projectiles
    local projectileCount = size == "Large" and 10
        or size == "Medium" and 7
        or size == "Small" and 4
        or 2
    burstSlime(pos, projectileCount)

    -- Death flash + fade
    if self.body and self.body.Parent then
        TweenService:Create(self.body, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
            { Transparency = 1, Size = self.body.Size * 1.4 }):Play()
    end
    task.delay(0.3, function()
        if self.model and self.model.Parent then
            self.model:Destroy()
        end
    end)

    -- Notify: split Large into 2 Medium
    local newSpawns = {}
    if cfg.splitInto and cfg.splits > 0 then
        for i = 1, cfg.splits do
            local angle = (i / cfg.splits) * math.pi * 2
            local offset = Vector3.new(math.cos(angle) * cfg.scale, 0, math.sin(angle) * cfg.scale)
            local newPos = pos + offset
            local newPatrolEnd = pos - offset * 3
            table.insert(newSpawns, { size = cfg.splitInto, pos = newPos, patrolEnd = newPatrolEnd })
        end
    end

    return newSpawns
end

-- ============================================================
-- SYSTEM MANAGER
-- ============================================================

function SlimeEnemy.new()
    local self = setmetatable({}, SlimeEnemy)
    self.slimes = {}
    self.active = false
    self.connection = nil
    self.pickaxeRef = nil -- set externally
    self.player = Players.LocalPlayer
    return self
end

-- Parse the SlimeSpawnData string value from the level folder
local function parseSpawnData(str)
    local spawns = {}
    if not str or str == "" then return spawns end
    for entry in str:gmatch("[^;]+") do
        local size, px, py, pz, ex, ey, ez =
            entry:match("(%a+)|([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)|([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)")
        if size then
            table.insert(spawns, {
                size      = size,
                pos       = Vector3.new(tonumber(px), tonumber(py), tonumber(pz)),
                patrolEnd = Vector3.new(tonumber(ex), tonumber(ey), tonumber(ez)),
            })
        end
    end
    return spawns
end

function SlimeEnemy:Start(levelFolder, pickaxeRef)
    self.active    = true
    self.pickaxeRef = pickaxeRef
    self.slimes    = {}

    -- Read spawn data from level folder
    local spawnDataVal = levelFolder and levelFolder:FindFirstChild("SlimeSpawnData")
    local spawns = spawnDataVal and parseSpawnData(spawnDataVal.Value) or {}

    -- Spawn slimes with slight delay (level just loaded)
    task.delay(1.5, function()
        for _, s in ipairs(spawns) do
            local inst = SlimeInstance.new(s.size, s.pos, s.patrolEnd)
            table.insert(self.slimes, inst)
        end
    end)

    -- Main update loop
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)

    -- Periodic slimed part cleanup
    task.spawn(function()
        while self.active do
            task.wait(5)
            cleanupSlimed()
        end
    end)
end

function SlimeEnemy:Stop()
    self.active = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    -- Destroy all slimes
    for _, s in ipairs(self.slimes) do
        if s.model and s.model.Parent then
            s.model:Destroy()
        end
    end
    self.slimes = {}
    -- Remove all slime overlays
    for _, rec in pairs(slimedParts) do
        if rec.overlay and rec.overlay.Parent then rec.overlay:Destroy() end
    end
    slimedParts = {}
end

function SlimeEnemy:Update(dt)
    if not self.active then return end

    -- Get pickaxe hit state
    local pickaxeSwinging = false
    local pickaxeHeavy    = false
    local pickaxeCF       = CFrame.new()
    if self.pickaxeRef and self.pickaxeRef.root and self.pickaxeRef.root.Parent then
        pickaxeCF = self.pickaxeRef.root.CFrame
        pickaxeSwinging = self.pickaxeRef.isSwinging or false
        pickaxeHeavy    = self.pickaxeRef.isHeavySwing or false
    end

    local toRemove = {}
    local toAdd    = {}

    for i, slime in ipairs(self.slimes) do
        if slime.dead then
            table.insert(toRemove, i)
        else
            -- Move toward patrol target
            slime:MoveTo(slime.targetPos, dt)
            -- Bob animation
            slime:Bob(dt)
            -- Check pickaxe hit
            if slime:CheckPickaxeHit(pickaxeCF, pickaxeSwinging, pickaxeHeavy) then
                local newSpawns = slime:Die()
                table.insert(toRemove, i)
                Networking.FireServer(Networking.Events.SlimeKilled,
                    slime.id, slime.size, slime:GetPosition())
                if newSpawns then
                    for _, ns in ipairs(newSpawns) do
                        table.insert(toAdd, ns)
                    end
                end
            end
        end
    end

    -- Remove dead slimes (reverse order)
    table.sort(toRemove, function(a, b) return a > b end)
    for _, idx in ipairs(toRemove) do
        table.remove(self.slimes, idx)
    end

    -- Add split children
    for _, ns in ipairs(toAdd) do
        local child = SlimeInstance.new(ns.size, ns.pos, ns.patrolEnd)
        table.insert(self.slimes, child)
    end
end

-- Public: check if the ground beneath the player is slimed
function SlimeEnemy.IsGroundSlimed(hrpPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(hrpPos, Vector3.new(0, -5, 0), rayParams)
    if result and result.Instance then
        return SlimeEnemy.IsSlimed(result.Instance)
    end
    return false
end

-- Public: expose slimedParts for movement.lua to read ground type
SlimeEnemy.IsSlimed = SlimeEnemy.IsSlimed

-- Public: SlimeRain modifier - immediately slime every platform in the level folder
function SlimeEnemy:SlimeAllTerrain(levelFolder)
    if not levelFolder then return end
    local slimeDuration = 90  -- seconds
    for _, part in ipairs(levelFolder:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChild("SlimeTrail") then
            local tag = part:FindFirstChild("TerrainType")
            if tag then
                -- Create slime overlay
                local overlay = Instance.new("Part")
                overlay.Name     = "SlimeOverlay"
                overlay.Size     = Vector3.new(part.Size.X + 0.1, 0.15, part.Size.Z + 0.1)
                overlay.CFrame   = CFrame.new(part.Position + Vector3.new(0, part.Size.Y / 2 + 0.08, 0))
                overlay.Material = Enum.Material.Neon
                overlay.Color    = SLIME_TRAIL
                overlay.CanCollide = false
                overlay.Anchored   = true
                overlay.CastShadow = false
                overlay.Parent = part

                local slimeTag = Instance.new("BoolValue")
                slimeTag.Name  = "SlimeTrail"
                slimeTag.Value = true
                slimeTag.Parent = part

                -- Expire after duration
                task.delay(slimeDuration, function()
                    if overlay and overlay.Parent then overlay:Destroy() end
                    if slimeTag and slimeTag.Parent then slimeTag:Destroy() end
                end)
            end
        end
    end
end

return SlimeEnemy
