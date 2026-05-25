-- DwarfDrop: slime_enemy.lua
-- Client-side slime visual AI: spawns slime models at server anchor points,
-- handles client-side movement, projectile throws, and hit detection.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking = require(game.ReplicatedStorage.Shared.networking)

local SlimeEnemy = {}
SlimeEnemy.__index = SlimeEnemy

local SLIME_MOVE_SPEED = 12
local SLIME_AGGRO_RANGE = 28
local SLIME_THROW_RANGE = 18
local SLIME_THROW_COOLDOWN = 3.5
local SLIME_CONTACT_RANGE = 4
local SLIME_CONTACT_DMG = 8

local slimeParts = {}  -- [part] = {target, timer, velY}

-- ==================== SLIME SYSTEM (module-level) ====================

local SlimeSystem = {}
local slimedParts = {}

function SlimeSystem.Slime(part)
    slimedParts[part] = true
    if part:IsA("BasePart") then
        part.Color = part.Color:Lerp(Color3.fromRGB(40,200,80), 0.6)
    end
end

function SlimeSystem.IsSlimed(part)
    return slimedParts[part] == true
end

function SlimeSystem.Clear(part)
    slimedParts[part] = nil
end

-- ==================== ACTIVE SLIME ENTITY ====================

function SlimeEnemy.new(anchorPart, biome)
    local self = setmetatable({}, SlimeEnemy)
    local size  = biome and (biome.name == "Mine" and 3 or 2) or 2
    self.anchor = anchorPart
    self.size   = size

    local root = Instance.new("Part")
    root.Name   = "SlimePart"
    root.Size   = Vector3.new(size, size * 0.7, size)
    root.Color  = Color3.fromRGB(40, 200, 80)
    root.Material = Enum.Material.SmoothPlastic
    root.CFrame = anchorPart.CFrame
    root.CanCollide = false
    root.CastShadow = false
    root.Parent = workspace

    local glow = Instance.new("PointLight")
    glow.Brightness = 1.5; glow.Range = 10; glow.Color = Color3.fromRGB(40,200,80)
    glow.Parent = root

    self.root          = root
    self.velY          = 0
    self.alive         = true
    self.throwTimer    = math.random() * SLIME_THROW_COOLDOWN
    self.lastHitTime   = 0

    slimeParts[root] = self
    return self
end

function SlimeEnemy:Destroy()
    self.alive = false
    slimeParts[self.root] = nil
    if self.root and self.root.Parent then
        self.root:Destroy()
    end
end

function SlimeEnemy:Update(dt)
    if not self.alive then return end
    local root = self.root
    if not root or not root.Parent then self.alive = false; return end

    local player = Players.LocalPlayer
    local char   = player.Character
    local hrp    = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (root.Position - hrp.Position).Magnitude

    -- Aggro
    if dist < SLIME_AGGRO_RANGE then
        local dir = (hrp.Position - root.Position)
        local flatDir = Vector3.new(dir.X, 0, dir.Z)
        if flatDir.Magnitude > 0.1 then
            flatDir = flatDir.Unit
            local moveV = flatDir * SLIME_MOVE_SPEED * dt
            self.velY = self.velY - (workspace.Gravity * dt)

            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = { root }
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local groundCheck = workspace:Raycast(root.Position, Vector3.new(0,-self.size*0.5-1.5,0), rp)
            if groundCheck then
                self.velY = 0
                if math.random() < 0.02 then
                    self.velY = math.random()*20 + 15
                end
            end

            root.CFrame = root.CFrame + moveV + Vector3.new(0, self.velY * dt, 0)
        end

        -- Contact damage
        if dist < SLIME_CONTACT_RANGE then
            local now = tick()
            if now - self.lastHitTime > 1.5 then
                self.lastHitTime = now
                Networking.FireServer(Networking.Events.SlimeHit, SLIME_CONTACT_DMG)
            end
        end

        -- Projectile throw
        self.throwTimer = self.throwTimer - dt
        if dist < SLIME_THROW_RANGE and self.throwTimer <= 0 then
            self.throwTimer = SLIME_THROW_COOLDOWN + math.random() * 2
            self:ThrowProjectile(hrp.Position)
        end
    end
end

function SlimeEnemy:ThrowProjectile(targetPos)
    local origin = self.root.Position + Vector3.new(0, self.size * 0.5, 0)
    local dir    = (targetPos - origin)
    local dist   = dir.Magnitude
    if dist < 0.5 then return end
    local speed  = math.min(40, dist * 1.8)
    local vel    = dir.Unit * speed + Vector3.new(0, dist * 0.35, 0)

    local blob = Instance.new("Part")
    blob.Size     = Vector3.new(1, 1, 1)
    blob.Shape    = Enum.PartType.Ball
    blob.Color    = Color3.fromRGB(40, 220, 80)
    blob.Material = Enum.Material.SmoothPlastic
    blob.CFrame   = CFrame.new(origin)
    blob.CanCollide = false
    blob.CastShadow = false
    blob.Parent   = workspace

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e4,1e4,1e4)
    bv.Velocity = vel; bv.Parent = blob

    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not blob.Parent or tick() - startTime > 4 then
            blob:Destroy()
            conn:Disconnect(); return
        end
        bv.Velocity = bv.Velocity + Vector3.new(0, -workspace.Gravity * dt, 0)

        local player = Players.LocalPlayer
        local char   = player.Character
        local hrp2   = char and char:FindFirstChild("HumanoidRootPart")
        if hrp2 and (blob.Position - hrp2.Position).Magnitude < 3.5 then
            -- Slime terrain
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = { char, blob }
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(blob.Position, Vector3.new(0,-3,0), rp)
            if hit then SlimeSystem.Slime(hit.Instance) end

            Networking.FireServer(Networking.Events.SlimeHit, SLIME_CONTACT_DMG * 0.7)
            Networking.FireServer(Networking.Events.TerrainSlimed, "", blob.Position)
            blob:Destroy()
            conn:Disconnect()
        end
    end)
end

-- ==================== MANAGER ====================

local activeSlimes = {}
local connection   = nil

function SlimeEnemy.StartManager(modifier)
    SlimeEnemy.StopManager()
    -- Discover all spawn anchors
    local function scanForAnchors(root)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj.Name == "SlimeAnchor" and obj:FindFirstChild("IsSlimeSpawn") then
                local slime = SlimeEnemy.new(obj, nil)
                table.insert(activeSlimes, slime)
            end
        end
    end
    scanForAnchors(workspace)

    connection = RunService.Heartbeat:Connect(function(dt)
        for i = #activeSlimes, 1, -1 do
            local slime = activeSlimes[i]
            slime:Update(dt)
            if not slime.alive then
                table.remove(activeSlimes, i)
            end
        end
    end)
end

function SlimeEnemy.StopManager()
    if connection then connection:Disconnect(); connection = nil end
    for _, s in ipairs(activeSlimes) do
        s:Destroy()
    end
    activeSlimes = {}
end

function SlimeEnemy.GetSlimeSystem()
    return SlimeSystem
end

return SlimeEnemy
