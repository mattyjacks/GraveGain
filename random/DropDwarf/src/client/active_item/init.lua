-- DropDwarf: active_item/init.lua
-- Client-side active item controller bootstrapper.
-- Coordinates UI inputs, event bindings, and delegates physics to sub-modules.

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking  = require(game.ReplicatedStorage.Shared.networking)
local ItemData    = require(game.ReplicatedStorage.Shared.item_data)
local GameData    = require(game.ReplicatedStorage.Shared.game_data)

-- Sub-modules
local RopeClimb    = require(script.rope_climb)
local ThrowPreview = require(script.throw_preview)
local PhysicsItems = require(script.physics_items)

local ActiveItem = {}
ActiveItem.__index = ActiveItem

local USE_KEY   = Enum.KeyCode.Q   -- use/toggle item
local PLACE_KEY = Enum.KeyCode.F   -- place item in world

local player = Players.LocalPlayer

function ActiveItem.new(camera, movement)
    local self = setmetatable({}, ActiveItem)
    self.camera    = camera
    self.movement  = movement
    self.active    = false

    -- Current item state
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
    self.ropeGrabY      = nil
    self.lastVelY       = 0

    -- Spring tracking
    self.onSpring       = false
    self.springPad      = nil
    self.springVel      = 0

    -- Visual assets
    self.chutePart      = nil
    self.balloonPart    = nil
    self.arcDots        = {}
    self.throwCooldown  = 0

    self.connections    = {}
    self.hudRef         = nil

    -- Debounces
    self.lastChuteDmgTime   = 0
    self.lastWaterTouchTime = 0
    self.lastSpringTime     = 0
    self.holdItemId         = nil
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
    ThrowPreview.Clear(self)
    self.onRope  = false
    self.ropeRef = nil
    self.itemId  = nil
end

-- ==================== INPUTS ====================
function ActiveItem:_wireInput()
    local c = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self.active then return end
        if input.KeyCode == USE_KEY then
            self:_onUseKey()
        elseif input.KeyCode == PLACE_KEY then
            self:_onPlaceKey()
        elseif input.KeyCode == Enum.KeyCode.Space then
            if self.onRope then
                RopeClimb.Release(self)
            end
        end
    end)
    table.insert(self.connections, c)

    local cu = UserInputService.InputEnded:Connect(function(input, processed)
        if processed or not self.active then return end
        if input.KeyCode == USE_KEY then
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
        self.holdItemId = self.itemId
        Networking.FireServer(Networking.Events.UseActiveItem, "start", nil)
    elseif def.useType == "throw" then
        self:_doThrow()
    end
end

function ActiveItem:_onPlaceKey()
    if not self.itemId then return end
    local def = ItemData.Items[self.itemId]
    if not def or def.useType ~= "place" then return end

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

-- ==================== THROW PREVIEWS ====================
function ActiveItem:_doThrow()
    if not self.itemId then return end
    local def = ItemData.Items[self.itemId]
    if not def or def.useType ~= "throw" then return end

    local now = tick()
    if now - (self.throwCooldown or 0) < 0.4 then return end
    self.throwCooldown = now

    local cam    = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local dir    = cam.CFrame.LookVector.Unit

    ThrowPreview.Clear(self)

    Networking.FireServer(Networking.Events.ThrowItem, {
        itemId    = self.itemId,
        origin    = { X = origin.X, Y = origin.Y, Z = origin.Z },
        direction = { X = dir.X,    Y = dir.Y,    Z = dir.Z    },
    })
end

-- ==================== UPDATE LOOPS ====================
function ActiveItem:_wireRenderStepped()
    local c = RunService.Heartbeat:Connect(function(dt)
        if not self.active then return end
        self:_updatePhysicsEffects(dt)
        
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            RopeClimb.CheckGrab(self, hrp, self.lastVelY)
            RopeClimb.Update(self, hrp)
        end
        
        self:_checkSpring()
        self:_checkWaterSources()
    end)
    table.insert(self.connections, c)

    local cr = RunService.RenderStepped:Connect(function()
        if not self.active then return end
        ThrowPreview.Update(self)
    end)
    table.insert(self.connections, cr)
end

function ActiveItem:_updatePhysicsEffects(dt)
    local char = player.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    self.lastVelY = hrp.AssemblyLinearVelocity.Y

    PhysicsItems.UpdateParachute(self, hrp, char, dt)
    PhysicsItems.UpdateBalloon(self, hrp, dt)
    PhysicsItems.UpdateJetpack(self, hrp, dt)
    PhysicsItems.UpdateThrower(self, hrp, hum, dt)
end

function ActiveItem:_checkSpring()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local now = tick()
    if now - self.lastSpringTime < 0.4 then return end

    if hum.FloorMaterial ~= Enum.Material.Air then
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
            if impact > def.dangerSpeed then
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

-- ==================== VISUALS ====================
function ActiveItem:_openParachute()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if self.chutePart then self.chutePart:Destroy() end
    local chute = Instance.new("Part")
    chute.Name         = "Parachute"
    chute.Size         = Vector3.new(14, 0.5, 14)
    chute.CanCollide   = true
    chute.Color        = ItemData.Items.Parachute.color
    chute.Material     = Enum.Material.Fabric
    chute.Transparency = 0.3
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
    balloon.CanCollide  = false
    balloon.Color       = ItemData.Items.Balloon.color
    balloon.Material    = Enum.Material.SmoothPlastic
    balloon.Transparency = 0.2
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

function ActiveItem:_spawnImpactVFX(pos, itemId, hitPlayerId)
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
    
    local TweenService = game:GetService("TweenService")
    local tw = TweenService:Create(flash,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = flash.Size * 2.5, Transparency = 1 })
    tw:Play()
    tw.Completed:Connect(function() flash:Destroy() end)
end

-- ==================== NETWORKING ====================
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
    end)
    table.insert(self.connections, c5)
end

return ActiveItem
