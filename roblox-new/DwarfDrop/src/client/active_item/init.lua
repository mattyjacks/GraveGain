-- DwarfDrop: active_item/init.lua
-- Client-side active item controller: Q to use/toggle, F to place, hold Q for jetpack

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking = require(game.ReplicatedStorage.Shared.networking)
local ItemData   = require(game.ReplicatedStorage.Shared.item_data)
local GameData   = require(game.ReplicatedStorage.Shared.game_data)

local ActiveItem = {}
ActiveItem.__index = ActiveItem

function ActiveItem.new(backpackUI, hudRef)
    local self = setmetatable({}, ActiveItem)
    self.player      = Players.LocalPlayer
    self.backpackUI  = backpackUI
    self.hudRef      = hudRef
    self.toggleState = {}  -- [slotIndex] = bool (on/off for toggle items)
    self.jetpackOn   = false
    self.parachuteOn = false
    self.balloonOn   = false
    self.connection  = nil
    self.qWasDown    = false
    self.fWasDown    = false
    self.waterLevel  = 0
    self.waterMax    = 0
    return self
end

-- Build the flashlight anchor on the character (SpotLight + PointLight parented to HRP)
function ActiveItem:BuildFlashlightAnchor()
    local char = self.player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local parent = head or hrp
    if not parent then return end

    -- Remove any stale anchor first
    local old = char:FindFirstChild("FlashlightAnchor")
    if old then old:Destroy() end

    local anchor = Instance.new("Part")
    anchor.Name        = "FlashlightAnchor"
    anchor.Size        = Vector3.new(0.1, 0.1, 0.1)
    anchor.Transparency = 1
    anchor.CanCollide  = false
    anchor.CastShadow  = false
    anchor.Anchored    = false
    anchor.Parent      = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = anchor
    weld.Part1 = parent
    weld.Parent = anchor
    anchor.CFrame = parent.CFrame * CFrame.new(0, 0, -1)

    -- SpotLight beam (directional flashlight)
    local beam = Instance.new("SpotLight")
    beam.Name        = "FlashlightBeam"
    beam.Face        = Enum.NormalId.Front
    beam.Brightness  = 8
    beam.Range       = GameData.FLASHLIGHT_CONE_LEN or 38
    beam.Angle       = GameData.FLASHLIGHT_ANGLE    or 35
    beam.Color       = GameData.FLASHLIGHT_COLOR    or Color3.fromRGB(245, 240, 210)
    beam.Shadows     = true
    beam.Enabled     = false
    beam.Parent      = anchor

    -- PointLight fill (ambient glow around player)
    local light = Instance.new("PointLight")
    light.Name       = "FlashlightLight"
    light.Brightness = 3
    light.Range      = 20
    light.Color      = GameData.FLASHLIGHT_COLOR or Color3.fromRGB(245, 240, 210)
    light.Enabled    = false
    light.Parent     = anchor
end

-- Called by main.client when a level begins to auto-enable the lantern in slot 1
function ActiveItem:AutoEnableLantern()
    -- Build the anchor (may be a fresh character after level load)
    self:BuildFlashlightAnchor()
    -- Force toggle ON for slot 1
    self.toggleState[1] = true
    self:ToggleLantern(true)
    if self.hudRef and self.backpackUI then
        local slotData = self.backpackUI:GetSlotData(1)
        if slotData then
            self.hudRef:UpdateActiveItem(slotData.itemId, slotData.count, true)
        end
    end
end

function ActiveItem:Start()
    -- Build flashlight geometry on the current character
    self:BuildFlashlightAnchor()

    -- Listen for water updates
    Networking.OnClient(Networking.Events.WaterUpdate, function(current, max)
        self.waterLevel = current or 0
        self.waterMax   = max or 0
        if self.hudRef then self.hudRef:UpdateWater(self.waterLevel, self.waterMax) end
    end)

    -- Listen for item used confirms
    Networking.OnClient(Networking.Events.ItemUsed, function(slotIndex, itemId, remaining, extraData)
        -- Update HUD item display for active slot
        if self.hudRef and self.backpackUI then
            local slotData = self.backpackUI:GetActiveSlotData()
            if slotData then
                self.hudRef:UpdateActiveItem(slotData.itemId, slotData.count,
                    self.toggleState[self.backpackUI:GetActiveSlotIndex()])
            end
        end
    end)

    -- Listen for backpack updates to refresh HUD
    Networking.OnClient(Networking.Events.BackpackUpdate, function(backpack)
        self:OnBackpackUpdated(backpack)
    end)

    self.connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function ActiveItem:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self:StopJetpack()
    self:CollapseParachute()
    self:PopBalloon()
end

function ActiveItem:OnBackpackUpdated(backpack)
    if not self.hudRef or not self.backpackUI then return end
    local activeIdx  = self.backpackUI:GetActiveSlotIndex()
    local slotData   = backpack and backpack[activeIdx]
    if slotData and slotData.itemId then
        self.hudRef:UpdateActiveItem(slotData.itemId, slotData.count,
            self.toggleState[activeIdx])
        -- Check if active item needs water bar
        local def = ItemData.Items[slotData.itemId]
        if def and def.waterCostPerUse then
            self.hudRef:UpdateWater(self.waterLevel, self.waterMax)
        end
    else
        self.hudRef:UpdateActiveItem(nil, 0, false)
    end
end

function ActiveItem:Update(dt)
    local qDown = UserInputService:IsKeyDown(Enum.KeyCode.Q)
    local fDown = UserInputService:IsKeyDown(Enum.KeyCode.F)

    -- Q pressed (rising edge) or held
    if qDown and not self.qWasDown then
        self:OnQPressed()
    elseif qDown then
        self:OnQHeld(dt)
    elseif not qDown and self.qWasDown then
        self:OnQReleased()
    end
    self.qWasDown = qDown

    -- F pressed (rising edge) for placement
    if fDown and not self.fWasDown then
        self:OnFPressed()
    end
    self.fWasDown = fDown
end

function ActiveItem:GetActiveItem()
    if not self.backpackUI then return nil, nil end
    local slotIdx  = self.backpackUI:GetActiveSlotIndex()
    local slotData = self.backpackUI:GetActiveSlotData()
    return slotData, slotIdx
end

function ActiveItem:OnQPressed()
    local slotData, slotIdx = self:GetActiveItem()
    if not slotData or not slotData.itemId then return end
    local def = ItemData.Items[slotData.itemId]
    if not def then return end

    if def.useType == "toggle" then
        local currentState = self.toggleState[slotIdx] or false
        local newState = not currentState
        self.toggleState[slotIdx] = newState
        self:ApplyToggle(slotData.itemId, newState, slotIdx)
        if self.hudRef then
            self.hudRef:UpdateActiveItem(slotData.itemId, slotData.count, newState)
        end
    elseif def.useType == "use" then
        -- Single fire
        Networking.FireServer(Networking.Events.UseActiveItem, slotIdx, nil)
        if slotData.itemId == "SteamVent" then
            self:FireSteamVentBlast()
        elseif slotData.itemId == "WaterCooler" then
            -- Server handles water add; nothing client-side
        end
    elseif def.useType == "throw" then
        self:ThrowItem(slotData.itemId, slotIdx)
    elseif def.useType == "hold" then
        -- Jetpack: handled in OnQHeld
        self.jetpackOn = true
    end
end

function ActiveItem:OnQHeld(dt)
    local slotData, slotIdx = self:GetActiveItem()
    if not slotData or not slotData.itemId then return end
    local def = ItemData.Items[slotData.itemId]
    if not def then return end

    if def.useType == "hold" and slotData.itemId == "JetpackFuel" and self.jetpackOn then
        self:ApplyJetpackThrust(dt, slotIdx)
    end
end

function ActiveItem:OnQReleased()
    self.jetpackOn = false
    self:StopJetpack()
end

function ActiveItem:OnFPressed()
    local slotData, slotIdx = self:GetActiveItem()
    if not slotData or not slotData.itemId then return end
    local def = ItemData.Items[slotData.itemId]
    if not def then return end

    if def.useType == "place" then
        self:PlaceItem(slotData.itemId, slotIdx)
    end
end

-- ==================== ITEM EFFECTS ====================

function ActiveItem:ApplyToggle(itemId, state, slotIdx)
    if itemId == "Parachute" then
        if state then self:DeployParachute()
        else self:CollapseParachute() end
        Networking.FireServer(Networking.Events.UseActiveItem, slotIdx, { state = state })
    elseif itemId == "Balloon" then
        if state then self:DeployBalloon()
        else self:PopBalloon() end
        Networking.FireServer(Networking.Events.UseActiveItem, slotIdx, { state = state })
    elseif itemId == "Lantern" then
        self:ToggleLantern(state)
        Networking.FireServer(Networking.Events.UseActiveItem, slotIdx, { state = state })
    end
end

function ActiveItem:DeployParachute()
    if self.parachuteOn then return end
    self.parachuteOn = true
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- Body velocity to cap fall speed
    local bv = Instance.new("BodyVelocity")
    bv.Name     = "ParachuteBV"
    bv.MaxForce = Vector3.new(0, 1e5, 0)
    bv.Velocity = Vector3.new(0, -8, 0)  -- slow descent
    bv.Parent   = hrp
end

function ActiveItem:CollapseParachute()
    if not self.parachuteOn then return end
    self.parachuteOn = false
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = hrp:FindFirstChild("ParachuteBV")
    if bv then bv:Destroy() end
end

function ActiveItem:DeployBalloon()
    if self.balloonOn then return end
    self.balloonOn = true
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name     = "BalloonBV"
    bv.MaxForce = Vector3.new(0, 1e4, 0)
    bv.Velocity = Vector3.new(0, -12, 0)
    bv.Parent   = hrp
end

function ActiveItem:PopBalloon()
    if not self.balloonOn then return end
    self.balloonOn = false
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = hrp:FindFirstChild("BalloonBV")
    if bv then bv:Destroy() end
end

function ActiveItem:ToggleLantern(state)
    local char = self.player.Character
    if not char then return end
    local anchor = char:FindFirstChild("FlashlightAnchor")
    if not anchor then return end
    local beam = anchor:FindFirstChild("FlashlightBeam")
    if beam then beam.Enabled = state end
    local light = anchor:FindFirstChild("FlashlightLight")
    if light then light.Enabled = state end
end

function ActiveItem:ApplyJetpackThrust(dt, slotIdx)
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local THRUST = 80
    local bv = hrp:FindFirstChild("JetpackBV")
    if not bv then
        bv           = Instance.new("BodyVelocity")
        bv.Name      = "JetpackBV"
        bv.MaxForce  = Vector3.new(0, 1e5, 0)
        bv.Velocity  = Vector3.new(0, THRUST, 0)
        bv.Parent    = hrp
    end
    bv.Velocity = Vector3.new(0, THRUST, 0)
    -- Auto-remove after frame to let gravity resume
    task.delay(0.05, function()
        local bv2 = hrp:FindFirstChild("JetpackBV")
        if bv2 then bv2:Destroy() end
    end)
    -- Consume fuel on server
    Networking.FireServer(Networking.Events.UseActiveItem, slotIdx, { thrust = true })
end

function ActiveItem:StopJetpack()
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = hrp:FindFirstChild("JetpackBV")
    if bv then bv:Destroy() end
end

function ActiveItem:FireSteamVentBlast()
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local BLAST_FORCE = 110
    local bv = Instance.new("BodyVelocity")
    bv.Name      = "SteamBlastBV"
    bv.MaxForce  = Vector3.new(0, 1e5, 0)
    bv.Velocity  = Vector3.new(0, BLAST_FORCE, 0)
    bv.Parent    = hrp
    game:GetService("Debris"):AddItem(bv, 0.25)
end

function ActiveItem:PlaceItem(itemId, slotIdx)
    local char = self.player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camera   = workspace.CurrentCamera
    local origin   = camera.CFrame.Position
    local forward  = camera.CFrame.LookVector
    local PLACE_RANGE = 12

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { char }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, forward * PLACE_RANGE, rp)

    local placePos = result and result.Position
        or (hrp.Position + forward * 6)

    Networking.FireServer(Networking.Events.PlaceItem, slotIdx, placePos)

    -- Optimistic local visual (server confirms with ItemPlaced)
    if itemId == "Spring" then
        self:LocalSpawnSpring(placePos)
    elseif itemId == "Rope" then
        self:LocalSpawnRopeAnchor(placePos, result and result.Instance)
    end
end

function ActiveItem:LocalSpawnSpring(pos)
    local p = Instance.new("Part")
    p.Name     = "SpringLocal"
    p.Size     = Vector3.new(2, 1, 2)
    p.Color    = Color3.fromRGB(80, 255, 80)
    p.Material = Enum.Material.Neon
    p.Anchored = true
    p.CanCollide = true
    p.Position = pos
    p.Parent   = workspace
    game:GetService("Debris"):AddItem(p, 20)
    -- Bounce logic: touch event
    p.Touched:Connect(function(hit)
        local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if hum then
            local hrp2 = hit.Parent:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                hrp2.AssemblyLinearVelocity = Vector3.new(
                    hrp2.AssemblyLinearVelocity.X, 85,
                    hrp2.AssemblyLinearVelocity.Z)
            end
        end
    end)
end

function ActiveItem:LocalSpawnRopeAnchor(pos, anchorPart)
    local anchor = Instance.new("Part")
    anchor.Name     = "RopeAnchor"
    anchor.Size     = Vector3.new(0.6, 0.6, 0.6)
    anchor.Color    = Color3.fromRGB(180, 140, 80)
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Position = pos
    anchor.Parent   = workspace
    game:GetService("Debris"):AddItem(anchor, 30)
end

function ActiveItem:ThrowItem(itemId, slotIdx)
    local char   = self.player.Character
    local hrp    = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local camera  = workspace.CurrentCamera
    local origin  = camera.CFrame.Position + camera.CFrame.LookVector * 1.5
    local dir     = camera.CFrame.LookVector

    Networking.FireServer(Networking.Events.ThrowItem, itemId, origin, dir)

    -- Local projectile visual
    local def  = ItemData.Items[itemId]
    local proj = Instance.new("Part")
    proj.Name   = itemId .. "Proj"
    proj.Size   = itemId == "BigRock" and Vector3.new(2,2,2) or Vector3.new(1,1,1)
    proj.Color  = def and def.glowColor or Color3.fromRGB(180,160,130)
    proj.Shape  = Enum.PartType.Ball
    proj.CanCollide = true
    proj.CastShadow = false
    proj.CFrame = CFrame.new(origin)
    proj.Parent = workspace

    local speed = itemId == "BigRock" and 55 or (itemId == "Javelin" and 90 or 70)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e4,1e4,1e4)
    bv.Velocity = dir * speed + Vector3.new(0, 8, 0)
    bv.Parent   = proj
    game:GetService("Debris"):AddItem(proj, 6)
end

return ActiveItem
