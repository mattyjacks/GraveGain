-- DropDwarf: item_handler.lua
-- Server-side active item logic: validates use, manages water, ticks effects.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris     = game:GetService("Debris")

local Networking = require(game.ReplicatedStorage.Shared.networking)
local ItemData   = require(game.ReplicatedStorage.Shared.item_data)
local Session    = require(script.Parent.session)

local ItemHandler = {}

-- Per-player item state keyed by userId
-- {
--   activeItem  : string itemId or nil
--   itemCount   : number (for stackable)
--   water       : number (0..5)
--   healTick    : { remaining: number } or nil
--   parachuteOpen : bool
--   balloonOn   : bool
--   jetpackOn   : bool
--   throwerOn   : bool
--   chuteHP     : number
--   placedItems : { [partInstance] = {type, owner} }
-- }
local playerItems = {}

local BACKPACK_SIZE = 4

function ItemHandler.InitPlayer(player)
    playerItems[player.UserId] = {
        activeItem    = nil,
        activeSlot    = 1,           -- which backpack slot is equipped
        itemCount     = 0,
        backpack      = {},          -- array[1..4] of {itemId, count} or nil
        water         = 0,
        healTick      = nil,
        parachuteOpen = false,
        balloonOn     = false,
        jetpackOn     = false,
        throwerOn     = false,
        chuteHP       = 3,
        placedItems   = {},
    }
end

local function broadcastBackpack(player, state)
    -- Serialize backpack for network (array of {itemId,count} or false for empty)
    local slots = {}
    for i = 1, BACKPACK_SIZE do
        local slot = state.backpack[i]
        slots[i] = slot and { itemId = slot.itemId, count = slot.count } or false
    end
    Networking.FireClient(Networking.Events.BackpackUpdate, player, slots, state.activeSlot)
end

function ItemHandler.CleanupPlayer(player)
    local state = playerItems[player.UserId]
    if state then
        -- Remove any placed world items
        for part, _ in pairs(state.placedItems) do
            if part and part.Parent then
                part:Destroy()
            end
        end
    end
    playerItems[player.UserId] = nil
end

function ItemHandler.GiveItem(player, itemId, count)
    local state = playerItems[player.UserId]
    if not state then return end
    local def = ItemData.Items[itemId]
    if not def then return end

    count = count or 1

    -- Find existing stack of same item or first empty slot
    local targetSlot = nil
    for i = 1, BACKPACK_SIZE do
        if state.backpack[i] and state.backpack[i].itemId == itemId and def.stackable then
            targetSlot = i
            break
        end
    end
    if not targetSlot then
        for i = 1, BACKPACK_SIZE do
            if not state.backpack[i] then
                targetSlot = i
                break
            end
        end
    end
    if not targetSlot then
        -- Backpack full: replace active slot
        targetSlot = state.activeSlot
    end

    if state.backpack[targetSlot] and state.backpack[targetSlot].itemId == itemId then
        state.backpack[targetSlot].count = state.backpack[targetSlot].count + count
    else
        state.backpack[targetSlot] = { itemId = itemId, count = count }
    end

    -- Auto-equip if slot 1 was empty (first pickup)
    if not state.activeItem then
        state.activeSlot = targetSlot
        state.activeItem = itemId
        state.itemCount  = state.backpack[targetSlot].count
    end

    -- Water items start with half a tank if below starting amount
    if def.useCost == "water" and state.water < ItemData.WATER_START then
        state.water = ItemData.WATER_START
        Networking.FireClient(Networking.Events.WaterUpdate, player, state.water)
    end

    broadcastBackpack(player, state)
    ItemHandler.ApplyWeightEffects(player)
    Networking.FireClient(Networking.Events.ItemPickup, player, {
        itemId = itemId,
        count  = state.backpack[targetSlot].count,
        water  = state.water,
        slot   = targetSlot,
        activeSlot = state.activeSlot,
    })
end

function ItemHandler.GetState(player)
    return playerItems[player.UserId]
end

-- Call at start of each new run to destroy placed items and reset state
function ItemHandler.ResetRunItems(player)
    local state = playerItems[player.UserId]
    if not state then return end
    for part, _ in pairs(state.placedItems) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    state.placedItems   = {}
    state.backpack      = {}
    state.activeItem    = nil
    state.activeSlot    = 1
    state.itemCount     = 0
    state.healTick      = nil
    state.parachuteOpen = false
    state.balloonOn     = false
    state.jetpackOn     = false
    state.throwerOn     = false
    state.chuteHP       = ItemData.Items.Parachute.chuteDurability
    broadcastBackpack(player, state)
end

-- Called when client fires UseActiveItem
local function onUseActiveItem(player, action, data)
    local state = playerItems[player.UserId]
    if not state or not state.activeItem then return end
    local def   = ItemData.Items[state.activeItem]
    if not def then return end

    -- Water cost check (skip when stopping a hold item)
    if def.useCost == "water" and action ~= "stop" then
        if state.water <= 0 then
            Networking.FireClient(Networking.Events.ItemUsed, player, {
                itemId = state.activeItem, denied = true, reason = "No water"
            })
            return
        end
    end

    -- Handle by use type
    if def.useType == "instant" then
        -- Healing Potion
        if state.activeItem == "HealingPotion" then
            state.healTick = { remaining = def.healDuration }
            state.activeItem = nil
            state.itemCount  = 0
            Networking.FireClient(Networking.Events.ItemUsed, player, {
                itemId = "HealingPotion", consumed = true
            })
        end

    elseif def.useType == "toggle" then
        -- Parachute / Balloon
        if state.activeItem == "Parachute" then
            state.parachuteOpen = not state.parachuteOpen
            Networking.FireClient(Networking.Events.ItemUsed, player, {
                itemId = "Parachute", open = state.parachuteOpen, chuteHP = state.chuteHP
            })
        elseif state.activeItem == "Balloon" then
            state.balloonOn = not state.balloonOn
            Networking.FireClient(Networking.Events.ItemUsed, player, {
                itemId = "Balloon", on = state.balloonOn
            })
        end

    elseif def.useType == "hold" then
        -- Jetpack / Thrower: action = "start" or "stop"
        if state.activeItem == "SteamJetpack" then
            state.jetpackOn = (action == "start")
            Networking.FireClient(Networking.Events.ItemUsed, player, {
                itemId = "SteamJetpack", on = state.jetpackOn, water = state.water
            })
        elseif state.activeItem == "SteamThrower" then
            state.throwerOn = (action == "start")
            Networking.FireClient(Networking.Events.ItemUsed, player, {
                itemId = "SteamThrower", on = state.throwerOn, water = state.water
            })
        end

    elseif def.useType == "place" then
        -- Rope / Spring / Piton: data = {position, normal, surfacePart}
        if state.itemCount <= 0 then return end
        local pos    = data and data.position
        local normal = data and data.normal
        if not pos then return end

        -- Range-check: placement must be within 16 studs of the player
        local placeVec = Vector3.new(
            pos.x or pos.X or 0,
            pos.y or pos.Y or 0,
            pos.z or pos.Z or 0)
        local pChar = player.Character
        local pHrp  = pChar and pChar:FindFirstChild("HumanoidRootPart")
        if not pHrp or (pHrp.Position - placeVec).Magnitude > 16 then return end
        pos = placeVec  -- normalised Vector3 from here on
        -- Normalise normal to a proper Vector3 as well
        if normal and type(normal) == "table" then
            normal = Vector3.new(
                normal.x or normal.X or 0,
                normal.y or normal.Y or 1,
                normal.z or normal.Z or 0)
            if normal.Magnitude > 0.01 then normal = normal.Unit
            else normal = Vector3.new(0, 1, 0) end
        elseif not normal then
            normal = Vector3.new(0, 1, 0)
        end

        if state.activeItem == "ClimbingRope" then
            local ropeTop = Instance.new("Part")
            ropeTop.Name        = "ClimbRope"
            ropeTop.Anchored    = true
            ropeTop.CanCollide  = false
            ropeTop.Size        = Vector3.new(0.4, def.ropeLength, 0.4)
            ropeTop.CFrame      = CFrame.new(pos + Vector3.new(0, -def.ropeLength/2, 0))
            ropeTop.Color       = def.color
            ropeTop.Material    = Enum.Material.SmoothPlastic
            ropeTop.Transparency = 0.2
            ropeTop.Parent      = workspace
            local tag = Instance.new("StringValue")
            tag.Name  = "IsClimbRope"
            tag.Value = tostring(player.UserId)
            tag.Parent = ropeTop
            state.placedItems[ropeTop] = { type = "ClimbingRope", owner = player }
            state.itemCount = state.itemCount - 1
            if state.itemCount <= 0 then state.activeItem = nil end
            Networking.FireClient(Networking.Events.ItemPlaced, player, {
                itemId = "ClimbingRope", partRef = ropeTop, remaining = state.itemCount
            })

        elseif state.activeItem == "SpringThing" then
            local springBase = Instance.new("Part")
            springBase.Name     = "SpringBase"
            springBase.Anchored = true
            springBase.Size     = Vector3.new(4, 1, 4)
            springBase.CFrame   = CFrame.new(pos + Vector3.new(0, 0.5, 0))
            springBase.Color    = def.color
            springBase.Material = Enum.Material.Metal
            springBase.Parent   = workspace
            local pad = Instance.new("Part")
            pad.Name     = "SpringPad"
            pad.Anchored = true
            pad.Size     = Vector3.new(4, 0.8, 4)
            pad.CFrame   = CFrame.new(pos + Vector3.new(0, 3.5, 0))
            pad.Color    = Color3.fromRGB(255, 240, 100)
            pad.Material = Enum.Material.SmoothPlastic
            pad.Parent   = workspace
            local springTag = Instance.new("StringValue")
            springTag.Name  = "IsSpring"
            springTag.Value = "true"
            springTag.Parent = pad
            state.placedItems[springBase] = { type = "SpringThing", owner = player }
            state.placedItems[pad]        = { type = "SpringThing", owner = player }
            state.itemCount = state.itemCount - 1
            if state.itemCount <= 0 then state.activeItem = nil end
            Networking.FireClient(Networking.Events.ItemPlaced, player, {
                itemId = "SpringThing", remaining = state.itemCount
            })

        elseif state.activeItem == "PitonSpikes" then
            local piton = Instance.new("Part")
            piton.Name     = "Piton"
            piton.Anchored = true
            piton.Size     = Vector3.new(0.6, 0.4, 0.6)
            -- Offset from wall surface so piton sits flush (not half-inside)
            local safeNormal = normal or Vector3.new(0, 1, 0)
            local facingCF = CFrame.new(pos + safeNormal * 0.3, pos + safeNormal)
            piton.CFrame   = facingCF
            piton.Color    = def.color
            piton.Material = Enum.Material.Metal
            piton.Parent   = workspace
            local pitonTag = Instance.new("StringValue")
            pitonTag.Name  = "IsPiton"
            pitonTag.Value = "true"
            pitonTag.Parent = piton
            state.placedItems[piton] = { type = "PitonSpikes", owner = player }
            state.itemCount = state.itemCount - 1
            if state.itemCount <= 0 then state.activeItem = nil end
            Networking.FireClient(Networking.Events.ItemPlaced, player, {
                itemId = "PitonSpikes", remaining = state.itemCount
            })
        end
    end

    -- Send updated water only for water-cost items
    if def.useCost == "water" then
        Networking.FireClient(Networking.Events.WaterUpdate, player, state.water)
    end
end

-- Water refill from biome water sources (called via UseActiveItem waterTouch action)
local WATER_TOUCH_RADIUS = 5  -- must be within 5 studs of a tagged water source
local function handleWaterTouch(player, state)
    if not state then return end
    local def = state.activeItem and ItemData.Items[state.activeItem]
    if not def or def.useCost ~= "water" then return end
    if state.water >= ItemData.WATER_MAX then return end

    -- Server-side proximity check: player must actually be near a tagged water source
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { char }
    local nearParts = workspace:GetPartBoundsInRadius(hrp.Position, WATER_TOUCH_RADIUS, overlapParams)
    local foundWater = false
    for _, part in ipairs(nearParts) do
        if part:FindFirstChild("IsWaterSource") then
            foundWater = true
            break
        end
    end
    if not foundWater then return end

    state.water = math.min(ItemData.WATER_MAX, state.water + ItemData.WATER_FILL_RATE)
    Networking.FireClient(Networking.Events.WaterUpdate, player, state.water)
end

-- ==================== THROW HANDLER ====================
-- Spawns a projectile part on the server, applies velocity, handles impact.
local function handleThrow(player, data)
    local state = playerItems[player.UserId]
    if not state or not state.activeItem then return end
    local itemId = state.activeItem
    local def    = ItemData.Items[itemId]
    if not def or def.useType ~= "throw" then return end

    -- Validate origin (must be near player character)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local origin = data and data.origin
    if not origin then
        origin = hrp.Position + Vector3.new(0, 1.5, 0)
    else
        -- Clamp to within 8 studs of character to prevent teleport-throws
        if (Vector3.new(origin.x or origin.X, origin.y or origin.Y, origin.z or origin.Z) - hrp.Position).Magnitude > 8 then
            origin = hrp.Position + Vector3.new(0, 1.5, 0)
        else
            origin = Vector3.new(origin.x or origin.X, origin.y or origin.Y, origin.z or origin.Z)
        end
    end

    local dir = data and data.direction
    if not dir then return end
    local dirVec = Vector3.new(
        dir.x or dir.X or 0,
        dir.y or dir.Y or 0,
        dir.z or dir.Z or 0
    )
    if dirVec.Magnitude < 0.01 then return end
    dirVec = dirVec.Unit

    -- Consume one from backpack
    local slot = state.backpack[state.activeSlot]
    if not slot or slot.itemId ~= itemId then return end
    slot.count = slot.count - 1
    if slot.count <= 0 then
        state.backpack[state.activeSlot] = nil
        state.activeItem = nil
        state.itemCount  = 0
    else
        state.itemCount = slot.count
    end
    broadcastBackpack(player, state)
    ItemHandler.ApplyWeightEffects(player)

    -- Build projectile part
    local proj = Instance.new("Part")
    proj.Name         = "Projectile_" .. itemId
    proj.Anchored     = false
    proj.CanCollide   = true
    proj.CastShadow   = false
    proj.Material     = Enum.Material.SmoothPlastic

    if itemId == "Javelin" then
        proj.Size  = Vector3.new(0.35, 0.35, 5.5)
        proj.Color = def.color
        -- Orient along direction of travel
        proj.CFrame = CFrame.lookAt(origin, origin + dirVec)
    elseif itemId == "SmallRock" then
        proj.Shape = Enum.PartType.Ball
        proj.Size  = Vector3.new(1.4, 1.4, 1.4)
        proj.Color = def.color
        proj.CFrame = CFrame.new(origin)
    elseif itemId == "BigRock" then
        proj.Shape = Enum.PartType.Block
        proj.Size  = Vector3.new(2.8, 2.4, 2.8)
        proj.Color = def.color
        proj.CFrame = CFrame.new(origin)
    end

    -- Tag with owner so the thrower can't self-damage immediately
    local ownerTag = Instance.new("IntValue")
    ownerTag.Name  = "OwnerUserId"
    ownerTag.Value = player.UserId
    ownerTag.Parent = proj

    local itemTag = Instance.new("StringValue")
    itemTag.Name   = "ProjectileItemId"
    itemTag.Value  = itemId
    itemTag.Parent = proj

    proj.Parent = workspace
    proj.AssemblyLinearVelocity = dirVec * def.throwSpeed

    -- Safety: auto-destroy after 12 seconds if nothing hit
    Debris:AddItem(proj, 12)

    -- Impact detection
    local landed = false
    local function onImpact(hitPart)
        if landed then return end
        if not hitPart or not hitPart.Parent then return end
        -- Ignore the projectile hitting itself or other projectiles
        if hitPart:FindFirstChild("ProjectileItemId") then return end
        -- Ignore hitting the thrower's own character for 0.3s after throw
        if hitPart:IsDescendantOf(char) then return end

        landed = true
        local landPos = proj.Position

        -- Check for players hit in radius
        local hitUserId = nil
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = { proj }
        local nearParts = workspace:GetPartBoundsInRadius(landPos, def.hitRadius, overlapParams)
        local hitPlayers = {}
        for _, p in ipairs(nearParts) do
            local hitChar = p.Parent
            if hitChar then
                local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
                if hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer.UserId] then
                    hitPlayers[hitPlayer.UserId] = true
                    -- Apply damage
                    local hum = hitChar:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        hum.Health = math.max(0, hum.Health - def.playerDamage)
                        hitUserId = hitPlayer.UserId
                        -- Knockback: push away from impact
                        local hitHrp = hitChar:FindFirstChild("HumanoidRootPart")
                        if hitHrp then
                            local kDir = (hitHrp.Position - landPos)
                            if kDir.Magnitude < 0.1 then kDir = dirVec end
                            kDir = kDir.Unit
                            local kForce = itemId == "BigRock" and 80 or 40
                            Networking.FireClient(Networking.Events.PlayerHit, hitPlayer, {
                                damage         = def.playerDamage,
                                knockbackDir   = { kDir.X, kDir.Y + 0.3, kDir.Z },
                                knockbackForce = kForce,
                                attackerName   = player.Name,
                            })
                        end
                    end
                end
            end
        end

        -- Broadcast landing to all session members for VFX
        local team = Session.GetAllMembers(player)
        for _, p in ipairs(team) do
            Networking.FireClient(Networking.Events.ProjectileLanded, p, {
                itemId      = itemId,
                pos         = { landPos.X, landPos.Y, landPos.Z },
                hitPlayerId = hitUserId,
                throwerId   = player.UserId,
            })
        end

        if itemId == "Javelin" then
            -- Stick the javelin in place as a standable surface
            proj.Anchored   = true
            proj.CanCollide = true
            -- Orient tip toward landing normal
            local stuckCF = CFrame.lookAt(landPos, landPos + dirVec)
            proj.CFrame = stuckCF
            -- Tag as stuck so players can stand on it
            local stuckTag = Instance.new("StringValue")
            stuckTag.Name  = "IsStuckJavelin"
            stuckTag.Value = tostring(player.UserId)
            stuckTag.Parent = proj
            -- Remove auto-cleanup and let it persist (cancel Debris)
            Debris:AddItem(proj, 45)  -- clean up after 45 seconds
            -- Track in placedItems for ResetRunItems cleanup
            local pState = playerItems[player.UserId]
            if pState then
                pState.placedItems[proj] = { type = "Javelin", owner = player }
            end
        else
            -- Rocks: destroy on impact
            proj:Destroy()
        end
    end

    proj.Touched:Connect(onImpact)
end

-- Returns total backpack weight in kg (counts stacked items by count)
function ItemHandler.GetBackpackWeightKg(player)
    local state = playerItems[player.UserId]
    if not state then return 0 end
    local total = 0
    for i = 1, BACKPACK_SIZE do
        local slot = state.backpack[i]
        if slot then
            local def = ItemData.Items[slot.itemId]
            if def and def.weightKg then
                total = total + def.weightKg * slot.count
            end
        end
    end
    return total
end

-- Applies weight-based WalkSpeed penalty to humanoid and fires WeightUpdate to client.
function ItemHandler.ApplyWeightEffects(player)
    local state = playerItems[player.UserId]
    if not state then return end
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    local totalKg    = ItemHandler.GetBackpackWeightKg(player)
    local speedMult  = math.max(
        ItemData.WEIGHT_SPEED_FLOOR,
        1 - totalKg * ItemData.WEIGHT_SPEED_PER_KG
    )
    -- Fall damage multiplier is computed server-side on impact; send it to client too
    local fallMult   = 1 + totalKg * ItemData.WEIGHT_FALL_PER_KG

    -- Apply walk speed
    if hum then
        local base = state.stats and state.stats.walkSpeed or 16
        hum.WalkSpeed = base * speedMult
    end

    -- Notify client so movement.lua can mirror the speed and show weight HUD
    Networking.FireClient(Networking.Events.WeightUpdate, player, {
        totalKg   = totalKg,
        speedMult = speedMult,
        fallMult  = fallMult,
    })
end

-- Init: must be called AFTER Networking.CreateRemotes() in main.server.lua
-- Wires all Heartbeat loops and RemoteEvent handlers.
function ItemHandler.Init()
    -- Heartbeat: tick water drain for jetpack/thrower
    local lastTick = tick()
    RunService.Heartbeat:Connect(function()
        local now = tick()
        local dt  = now - lastTick
        lastTick  = now

        for _, player in ipairs(Players:GetPlayers()) do
            local state = playerItems[player.UserId]
            if not state then continue end

            -- Water drain for jetpack
            if state.jetpackOn and state.water > 0 then
                local def = ItemData.Items.SteamJetpack
                state.water = math.max(0, state.water - def.waterPerSec * dt)
                Networking.FireClient(Networking.Events.WaterUpdate, player, state.water)
                if state.water <= 0 then
                    state.jetpackOn = false
                    Networking.FireClient(Networking.Events.ItemUsed, player, {
                        itemId = "SteamJetpack", on = false, water = 0
                    })
                end
            end

            -- Water drain for thrower
            if state.throwerOn and state.water > 0 then
                local def = ItemData.Items.SteamThrower
                state.water = math.max(0, state.water - def.waterPerSec * dt)
                Networking.FireClient(Networking.Events.WaterUpdate, player, state.water)
                if state.water <= 0 then
                    state.throwerOn = false
                    Networking.FireClient(Networking.Events.ItemUsed, player, {
                        itemId = "SteamThrower", on = false, water = 0
                    })
                end
            end
        end
    end)

    -- UseActiveItem: use/toggle/hold/waterTouch
    Networking.OnServer(Networking.Events.UseActiveItem, function(player, action, data)
        if action == "waterTouch" then
            handleWaterTouch(player, playerItems[player.UserId])
        else
            onUseActiveItem(player, action, data)
        end
    end)

    -- EquipSlot: client switches which backpack slot is active
    Networking.OnServer(Networking.Events.EquipSlot, function(player, slotIndex)
        local state = playerItems[player.UserId]
        if not state then return end
        slotIndex = math.clamp(math.floor(slotIndex or 1), 1, BACKPACK_SIZE)
        local slot = state.backpack[slotIndex]
        state.activeSlot  = slotIndex
        state.activeItem  = slot and slot.itemId or nil
        state.itemCount   = slot and slot.count or 0
        broadcastBackpack(player, state)
        -- Recompute weight effects after slot change
        ItemHandler.ApplyWeightEffects(player)
        -- Also fire ItemPickup so active_item.lua updates its local state
        if state.activeItem then
            Networking.FireClient(Networking.Events.ItemPickup, player, {
                itemId = state.activeItem,
                count  = state.itemCount,
                water  = state.water,
                slot   = slotIndex,
                activeSlot = state.activeSlot,
            })
        end
    end)

    -- GrabRope: handled client-side, server acknowledges only
    Networking.OnServer(Networking.Events.GrabRope, function(player, ropeRef)
    end)

    -- PlaceItem: place a rope/spring/piton in the world
    Networking.OnServer(Networking.Events.PlaceItem, function(player, data)
        local state = playerItems[player.UserId]
        if not state or not state.activeItem then return end
        local def = ItemData.Items[state.activeItem]
        if not def or def.useType ~= "place" then return end
        onUseActiveItem(player, "place", data)
    end)

    -- ThrowItem: throw the active throw-type item
    Networking.OnServer(Networking.Events.ThrowItem, function(player, data)
        local state = playerItems[player.UserId]
        if not state or not state.activeItem then return end
        local def = ItemData.Items[state.activeItem]
        if not def or def.useType ~= "throw" then return end
        handleThrow(player, data)
    end)
end

return ItemHandler
