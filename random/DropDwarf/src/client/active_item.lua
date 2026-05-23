-- DropDwarf: active_item.lua
-- Client-side active item controller.
-- Handles UI, input, placement raycasting, and physics effects.

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local ItemData    = require(game.ReplicatedStorage.Shared.item_data)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)

local ActiveItem = {}
ActiveItem.__index = ActiveItem

local USE_KEY   = Enum.KeyCode.Q   -- use/toggle item
local PLACE_KEY = Enum.KeyCode.F   -- place item in world

local player = Players.LocalPlayer

function ActiveItem.new(camera, movement)
    local self = setmetatable({}, ActiveItem)
    self.camera    = camera
    self.movement  = movement   -- Movement module reference (to apply forces)
    self.active    = false

    -- Current item state (mirrors server)
    self.itemId         = nil
    self.itemCount      = 0
    self.water          = 0

    -- Effect state
    self.parachuteOpen  = false
    self.balloonOn      = false
    self.jetpackOn      = false
    self.throwerOn      = false
    self.chuteHP        = 3
    self.onRope         = false
    self.ropeRef        = nil
    self.ropeGrabY      = nil   -- Y position where we grabbed
    self.lastVelY       = 0

    -- Spring tracking
    self.onSpring       = false
    self.springPad      = nil
    self.springVel      = 0

    -- Parachute part (visible above character)
    self.chutePart      = nil

    -- Balloon part
    self.balloonPart    = nil

    -- Throw arc preview
    self.arcDots        = {}   -- array of small Part instances
    self.throwCooldown  = 0    -- tick() of last throw, debounce

    self.connections    = {}
    self.hudRef         = nil  -- set via SetHUD

    -- Throttle/debounce timestamps
    self.lastChuteDmgTime  = 0
    self.lastWaterTouchTime = 0
    self.lastSpringTime    = 0
    self.holdItemId        = nil  -- caches itemId when hold starts
    return self
end

function ActiveItem:SetHUD(hud)
    self.hudRef = hud
end

function ActiveItem:Start()
    self.active = true
    self:_wireInput()
    self:_wireRenderStepped()
    self:_wireNetworking()
end

function ActiveItem:Stop()
    self.active = false
    for _, c in ipairs(self.connections) do c:Disconnect() end
    self.connections = {}
    self:_closeParachute()
    self:_popBalloon()
    self:_clearArcDots()
    self.onRope  = false
    self.ropeRef = nil
    self.itemId  = nil
end

-- ==================== INPUT ====================
function ActiveItem:_wireInput()
    local c = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self.active then return end
        if input.KeyCode == USE_KEY then
            self:_onUseKey()
        elseif input.KeyCode == PLACE_KEY then
            self:_onPlaceKey()
        elseif input.KeyCode == Enum.KeyCode.Space then
            if self.onRope then
                self:_releaseRope()
            end
        end
    end)
    table.insert(self.connections, c)

    local cu = UserInputService.InputEnded:Connect(function(input, processed)
        if processed or not self.active then return end
        if input.KeyCode == USE_KEY then
            -- Use cached holdItemId so stop fires even if item changed
            if self.holdItemId then
                Networking.FireServer(Networking.Events.UseActiveItem, "stop", nil)
                self.holdItemId = nil
            end
        end
    end)
    table.insert(self.connections, cu)
end

function ActiveItem:_onUseKey()
    if not self.itemId then return end
    local def = ItemData.Items[self.itemId]
    if not def then return end

    if def.useType == "instant" or def.useType == "toggle" then
        Networking.FireServer(Networking.Events.UseActiveItem, "use", nil)
    elseif def.useType == "hold" then
        self.holdItemId = self.itemId  -- cache for InputEnded
        Networking.FireServer(Networking.Events.UseActiveItem, "start", nil)
    elseif def.useType == "throw" then
        self:_doThrow()
    end
end

function ActiveItem:_onPlaceKey()
    if not self.itemId then return end
    local def = ItemData.Items[self.itemId]
    if not def or def.useType ~= "place" then return end

    -- Raycast from camera look direction to find placement surface
    local cam     = self.camera.camera or workspace.CurrentCamera
    local origin  = cam.CFrame.Position
    local dir     = cam.CFrame.LookVector * 12
    local rp      = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = { player.Character }
    local result  = workspace:Raycast(origin, dir, rp)
    if not result then return end

    Networking.FireServer(Networking.Events.PlaceItem, {
        position = result.Position,
        normal   = result.Normal,
    })
end

-- ==================== ARC PREVIEW ====================
local ARC_STEPS   = 20   -- number of dots along the arc
local ARC_STEP_DT = 0.06 -- time step per dot (seconds)
local DOT_SIZE    = Vector3.new(0.22, 0.22, 0.22)

function ActiveItem:_clearArcDots()
    for _, dot in ipairs(self.arcDots) do
        if dot and dot.Parent then dot:Destroy() end
    end
    self.arcDots = {}
end

function ActiveItem:_updateArcPreview()
    local def = self.itemId and ItemData.Items[self.itemId]
    if not def or def.useType ~= "throw" then
        self:_clearArcDots()
        return
    end

    local cam   = workspace.CurrentCamera
    local char  = player.Character
    local hrp   = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then self:_clearArcDots(); return end

    -- Throw origin: slightly in front of character at shoulder height
    local origin = cam.CFrame.Position
    local dir    = cam.CFrame.LookVector.Unit
    local vel    = dir * def.throwSpeed
    local grav   = Vector3.new(0, -def.gravity, 0)

    -- Ensure we have exactly ARC_STEPS dots
    while #self.arcDots < ARC_STEPS do
        local dot = Instance.new("Part")
        dot.Name         = "ArcDot"
        dot.Size         = DOT_SIZE
        dot.Shape        = Enum.PartType.Ball
        dot.Anchored     = true
        dot.CanCollide   = false
        dot.CastShadow   = false
        dot.Material     = Enum.Material.Neon
        dot.Color        = def.color
        dot.Transparency = 0.3
        dot.Parent       = workspace
        table.insert(self.arcDots, dot)
    end
    while #self.arcDots > ARC_STEPS do
        local removed = table.remove(self.arcDots)
        if removed and removed.Parent then removed:Destroy() end
    end

    -- Recolor dots to match current item (in case item changed)
    for _, dot in ipairs(self.arcDots) do
        dot.Color = def.color
    end

    -- Simulate arc positions
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = { char }

    local pos = origin
    local v   = vel
    for i, dot in ipairs(self.arcDots) do
        local nextPos = pos + v * ARC_STEP_DT + grav * (0.5 * ARC_STEP_DT * ARC_STEP_DT)
        local nextV   = v + grav * ARC_STEP_DT
        -- Fade opacity toward end of arc
        dot.Transparency = 0.2 + (i / ARC_STEPS) * 0.65
        dot.Position = pos
        -- Stop drawing if arc hits terrain (still show remaining dots at last pos)
        local ray = workspace:Raycast(pos, nextPos - pos, rp)
        if ray then
            -- Snap remaining dots to impact point
            for j = i, ARC_STEPS do
                if self.arcDots[j] then
                    self.arcDots[j].Position = ray.Position
                    self.arcDots[j].Transparency = 0.7
                end
            end
            break
        end
        pos = nextPos
        v   = nextV
    end
end

-- ==================== THROW ====================
function ActiveItem:_doThrow()
    if not self.itemId then return end
    local def = ItemData.Items[self.itemId]
    if not def or def.useType ~= "throw" then return end

    -- Debounce: 0.4s between throws
    local now = tick()
    if now - (self.throwCooldown or 0) < 0.4 then return end
    self.throwCooldown = now

    local cam    = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local dir    = cam.CFrame.LookVector.Unit

    -- Clear arc preview immediately
    self:_clearArcDots()

    Networking.FireServer(Networking.Events.ThrowItem, {
        itemId    = self.itemId,
        origin    = { X = origin.X, Y = origin.Y, Z = origin.Z },
        direction = { X = dir.X,    Y = dir.Y,    Z = dir.Z    },
    })
end

-- ==================== PHYSICS LOOP (Heartbeat) ====================
function ActiveItem:_wireRenderStepped()
    -- Physics effects must run on Heartbeat (before physics step integration)
    -- RenderStepped runs after physics; velocity writes get overwritten.
    local c = RunService.Heartbeat:Connect(function(dt)
        if not self.active then return end
        self:_updatePhysicsEffects(dt)
        self:_checkRopeGrab()
        self:_checkSpring()
        self:_checkWaterSources()
    end)
    table.insert(self.connections, c)

    -- Arc preview runs on RenderStepped (purely visual, every frame)
    local cr = RunService.RenderStepped:Connect(function()
        if not self.active then return end
        self:_updateArcPreview()
    end)
    table.insert(self.connections, cr)
end

function ActiveItem:_updatePhysicsEffects(dt)
    local char = player.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local vel = hrp.AssemblyLinearVelocity
    self.lastVelY = vel.Y

    -- Parachute: cap fall speed
    if self.parachuteOpen then
        local def = ItemData.Items.Parachute
        if vel.Y < -def.fallSpeedCap then
            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -def.fallSpeedCap, vel.Z)
        end
        -- Check ceiling collision (raycast upward, exclude character)
        local chuteRP = RaycastParams.new()
        chuteRP.FilterType = Enum.RaycastFilterType.Exclude
        chuteRP.FilterDescendantsInstances = { char }
        local upResult = workspace:Raycast(hrp.Position, Vector3.new(0, 10, 0), chuteRP)
        if upResult and upResult.Instance then
            local now = tick()
            if now - self.lastChuteDmgTime >= 0.5 then  -- max 2 hits/second
                self.lastChuteDmgTime = now
                self.chuteHP = self.chuteHP - 1
                if self.hudRef and self.hudRef.UpdateChuteHP then
                    self.hudRef:UpdateChuteHP(self.chuteHP)
                end
                if self.chuteHP <= 0 then
                    self:_closeParachute()
                end
            end
        end
    end

    -- Balloon: apply reduced gravity via continuous upward force
    if self.balloonOn then
        local def = ItemData.Items.Balloon
        local normalGrav = workspace.Gravity
        local wantedGrav = normalGrav * def.gravityScale
        local gravDiff   = normalGrav - wantedGrav
        -- Apply upward impulse to counteract excess gravity
        hrp:ApplyImpulse(Vector3.new(0, hrp.AssemblyMass * gravDiff * dt, 0))
    end

    -- Jetpack: apply upward force while key held + water available
    if self.jetpackOn and self.water > 0 then
        local def = ItemData.Items.SteamJetpack
        hrp:ApplyImpulse(Vector3.new(0, hrp.AssemblyMass * def.liftForce * dt, 0))
        -- VFX: could add particle here
    end

    -- Thrower: apply knockback opposite to look direction while key held
    if self.throwerOn and self.water > 0 then
        local def   = ItemData.Items.SteamThrower
        local cam   = workspace.CurrentCamera
        local lv    = cam.CFrame.LookVector
        local lookFlat = Vector3.new(lv.X, 0, lv.Z)
        -- Guard against zero vector (looking straight up/down)
        if lookFlat.Magnitude > 0.01 then
            local lookH = lookFlat.Unit
            local isOnGround = (hum.FloorMaterial ~= Enum.Material.Air)
            if not isOnGround then
                hrp:ApplyImpulse(-lookH * hrp.AssemblyMass * def.knockbackForce * dt)
            end
        end
    end

    -- Rope climb
    if self.onRope and self.ropeRef and self.ropeRef.Parent then
        -- Disable gravity by zeroing Y velocity, allow manual climb
        local climbDir = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then climbDir = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then climbDir = -1 end

        local def      = ItemData.Items.ClimbingRope
        -- When idle (climbDir==0), hold position (0 velocity) - don't slide
        local climbSpd = climbDir == 0 and 0
            or (climbDir > 0 and def.climbUpSpeed or def.climbDownSpeed)
        local newVelY  = climbDir * climbSpd
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X * 0.2,
            newVelY,
            hrp.AssemblyLinearVelocity.Z * 0.2
        )
        -- Keep player attached to rope X/Z
        local ropeCF = self.ropeRef.CFrame
        local rpLocal = ropeCF:PointToObjectSpace(hrp.Position)
        rpLocal = Vector3.new(0, rpLocal.Y, 0)  -- clamp to rope center
        local targetPos = ropeCF:PointToWorldSpace(rpLocal)
        hrp.CFrame = CFrame.new(
            Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z),
            Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z) + hrp.CFrame.LookVector
        )
    end
end

function ActiveItem:_checkRopeGrab()
    if self.onRope then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Use overlap sphere to detect nearby rope parts
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { char }
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, 1.5, overlapParams)
    for _, part in ipairs(parts) do
        if part.Name == "ClimbRope" then
            -- Grab the rope: report approximate fall distance in meters
            -- The server's ApplyFallDamage handler applies fallResist upgrade on top;
            -- do NOT pre-halve here or the rope resistance gets double-counted.
            local fallSpeedStuds = math.abs(self.lastVelY)
            if fallSpeedStuds > 40 then
                -- v^2 = 2*g*h  =>  h = v^2/(2*g); convert studs to meters
                local approxFallMeters = (fallSpeedStuds * fallSpeedStuds)
                    / (2 * workspace.Gravity * GameData.STUDS_PER_METER)
                Networking.FireServer(Networking.Events.ApplyFallDamage, approxFallMeters)
            end
            self.onRope  = true
            self.ropeRef = part
            Networking.FireServer(Networking.Events.GrabRope, part)
            break
        end
    end
end

function ActiveItem:_releaseRope()
    self.onRope  = false
    self.ropeRef = nil
    Networking.FireServer(Networking.Events.ReleaseRope)
end

function ActiveItem:_checkSpring()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    -- Debounce: only trigger spring once per 0.4s to avoid multi-frame launch
    local now = tick()
    if now - self.lastSpringTime < 0.4 then return end

    if hum.FloorMaterial ~= Enum.Material.Air then
        -- Exclude character from floor ray
        local springRP = RaycastParams.new()
        springRP.FilterType = Enum.RaycastFilterType.Exclude
        springRP.FilterDescendantsInstances = { char }
        local floorRay = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), springRP)
        if floorRay and floorRay.Instance and floorRay.Instance.Name == "SpringPad" then
            self.lastSpringTime = now
            local def    = ItemData.Items.SpringThing
            local impact = math.abs(self.lastVelY)
            local launch = def.launchForce
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                launch = def.maxLaunchForce
            end
            -- Extreme impact still damages (report as fall meters to server)
            if impact > def.dangerSpeed then
                -- Use only the excess speed above dangerSpeed; v^2=2gh => h=v^2/(2g)
                local excessSpeed = impact - def.dangerSpeed
                local approxFallMeters = (excessSpeed * excessSpeed)
                    / (2 * workspace.Gravity * GameData.STUDS_PER_METER)
                Networking.FireServer(Networking.Events.ApplyFallDamage, approxFallMeters)
            end
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                launch,
                hrp.AssemblyLinearVelocity.Z
            )
        end
    end
end

function ActiveItem:_checkWaterSources()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if self.water >= ItemData.WATER_MAX then return end

    -- Throttle: fire server at most once per second
    local now = tick()
    if now - self.lastWaterTouchTime < 1.0 then return end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { char }
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, 3, overlapParams)
    for _, part in ipairs(parts) do
        if part:FindFirstChild("IsWaterSource") then
            self.lastWaterTouchTime = now
            Networking.FireServer(Networking.Events.UseActiveItem, "waterTouch", { partRef = part })
            break
        end
    end
end

-- ==================== PARACHUTE VISUALS ====================
function ActiveItem:_openParachute()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if self.chutePart then self.chutePart:Destroy() end
    local chute = Instance.new("Part")
    chute.Name         = "Parachute"
    chute.Size         = Vector3.new(14, 0.5, 14)
    chute.Anchored     = false
    chute.CanCollide   = true
    chute.Color        = ItemData.Items.Parachute.color
    chute.Material     = Enum.Material.Fabric
    chute.Transparency = 0.3
    -- Set CFrame BEFORE welding (weld locks relative offset at creation time)
    chute.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 10, 0))
    chute.Parent       = workspace
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = chute
    weld.Parent = chute
    self.chutePart = chute
end

function ActiveItem:_closeParachute()
    self.parachuteOpen = false
    if self.chutePart then
        self.chutePart:Destroy()
        self.chutePart = nil
    end
    if self.hudRef and self.hudRef.UpdateActiveItem then
        self.hudRef:UpdateActiveItem(self.itemId, self.itemCount, false)
    end
end

-- ==================== BALLOON VISUAL ====================
function ActiveItem:_showBalloon()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if self.balloonPart then self.balloonPart:Destroy() end
    local balloon = Instance.new("Part")
    balloon.Name        = "Balloon"
    balloon.Shape       = Enum.PartType.Ball
    balloon.Size        = Vector3.new(5, 6, 5)
    balloon.Anchored    = false
    balloon.CanCollide  = false
    balloon.Color       = ItemData.Items.Balloon.color
    balloon.Material    = Enum.Material.SmoothPlastic
    balloon.Transparency = 0.2
    -- Set CFrame BEFORE welding
    balloon.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 8, 0))
    balloon.Parent      = workspace
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = balloon
    weld.Parent = balloon
    self.balloonPart = balloon
end

function ActiveItem:_popBalloon()
    self.balloonOn = false
    if self.balloonPart then
        self.balloonPart:Destroy()
        self.balloonPart = nil
    end
end

-- ==================== PROJECTILE LANDED VFX ====================
function ActiveItem:_spawnImpactVFX(pos, itemId, hitPlayerId)
    -- Brief flash sphere at impact position
    local flash = Instance.new("Part")
    flash.Shape        = Enum.PartType.Ball
    flash.Size         = itemId == "BigRock" and Vector3.new(5, 5, 5) or Vector3.new(2.5, 2.5, 2.5)
    flash.Anchored     = true
    flash.CanCollide   = false
    flash.Material     = Enum.Material.Neon
    flash.Color        = hitPlayerId and Color3.fromRGB(255, 80, 40) or Color3.fromRGB(255, 220, 60)
    flash.Transparency = 0.3
    flash.CFrame       = CFrame.new(pos)
    flash.Parent       = workspace
    -- Tween it out
    local TweenService = game:GetService("TweenService")
    local tw = TweenService:Create(flash,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = flash.Size * 2.5, Transparency = 1 })
    tw:Play()
    tw.Completed:Connect(function() flash:Destroy() end)
end

-- ==================== SERVER RESPONSES ====================
function ActiveItem:_wireNetworking()
    local c1 = Networking.OnClient(Networking.Events.ItemPickup, function(data)
        self.itemId    = data.itemId
        self.itemCount = data.count
        self.water     = data.water or 0
        if self.hudRef and self.hudRef.UpdateActiveItem then
            self.hudRef:UpdateActiveItem(self.itemId, self.itemCount, false)
        end
        if self.hudRef and self.hudRef.UpdateWater then
            self.hudRef:UpdateWater(self.water, ItemData.WATER_MAX)
        end
    end)
    table.insert(self.connections, c1)

    local c2 = Networking.OnClient(Networking.Events.ItemUsed, function(data)
        if data.denied then return end

        if data.itemId == "HealingPotion" and data.consumed then
            self.itemId    = nil
            self.itemCount = 0

        elseif data.itemId == "Parachute" then
            self.parachuteOpen = data.open
            self.chuteHP       = data.chuteHP or self.chuteHP
            if self.parachuteOpen then
                self:_openParachute()
            else
                self:_closeParachute()
            end

        elseif data.itemId == "Balloon" then
            self.balloonOn = data.on
            if self.balloonOn then
                self:_showBalloon()
            else
                self:_popBalloon()
            end

        elseif data.itemId == "SteamJetpack" then
            self.jetpackOn = data.on

        elseif data.itemId == "SteamThrower" then
            self.throwerOn = data.on
        end

        if self.hudRef and self.hudRef.UpdateActiveItem then
            local active = self.parachuteOpen or self.balloonOn or self.jetpackOn or self.throwerOn
            self.hudRef:UpdateActiveItem(self.itemId, self.itemCount, active)
        end
    end)
    table.insert(self.connections, c2)

    local c3 = Networking.OnClient(Networking.Events.WaterUpdate, function(amount)
        self.water = amount
        if self.hudRef and self.hudRef.UpdateWater then
            self.hudRef:UpdateWater(self.water, ItemData.WATER_MAX)
        end
    end)
    table.insert(self.connections, c3)

    local c4 = Networking.OnClient(Networking.Events.ItemPlaced, function(data)
        self.itemCount = data.remaining or 0
        if self.itemCount <= 0 then self.itemId = nil end
        if self.hudRef and self.hudRef.UpdateActiveItem then
            self.hudRef:UpdateActiveItem(self.itemId, self.itemCount, false)
        end
    end)
    table.insert(self.connections, c4)

    local c5 = Networking.OnClient(Networking.Events.ProjectileLanded, function(data)
        if not data then return end
        local pos = data.pos and Vector3.new(data.pos[1], data.pos[2], data.pos[3])
        if pos then
            self:_spawnImpactVFX(pos, data.itemId, data.hitPlayerId)
        end
        -- If I was the thrower and I ran out, arc is already cleared; no-op
    end)
    table.insert(self.connections, c5)
end

return ActiveItem
