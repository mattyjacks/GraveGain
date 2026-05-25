-- DwarfDrop: movement.lua
-- WASD, sprint, coyote time, air jumps, coin magnet + combo, slime slip
-- FIX Bug#10: fires CollectCoin only (no CollectCoinCombo) - server handles combo

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TweenService = game:GetService("TweenService")

local GameData   = require(game.ReplicatedStorage.Shared.game_data)
local Networking = require(game.ReplicatedStorage.Shared.networking)

local Movement = {}
Movement.__index = Movement

local FALL_CHECK_INTERVAL = 0.05
local HAZARD_COOLDOWN     = 0.5
local COIN_CHECK_RATE     = 0.08

local SLIDE_DURATION   = 1.0
local SLIME_SPEED_MULT = 1.55
local SLIME_EXTRA_SPEED = 16

local COYOTE_TIME      = GameData.COYOTE_TIME
local AIR_JUMP_IMPULSE = 52

local COMBO_RESET_TIME  = GameData.COMBO_RESET_TIME
local COMBO_THRESHOLDS  = GameData.COMBO_THRESHOLDS
local COMBO_MULTIPLIERS = GameData.COMBO_MULTIPLIERS
local MAGNET_PULL_SPEED = GameData.MAGNET_PULL_SPEED

local function cubicEaseOut(t)
    t = math.clamp(t, 0, 1)
    local inv = 1 - t
    return inv * inv * (1 + 2 * t)
end

local function getComboMult(streak)
    local mult = 1
    for i, threshold in ipairs(COMBO_THRESHOLDS) do
        if streak >= threshold then
            mult = COMBO_MULTIPLIERS[i]
        end
    end
    return mult
end

function Movement.new(fpsCamera)
    local self = setmetatable({}, Movement)
    self.player         = Players.LocalPlayer
    self.camera         = fpsCamera
    self.walkSpeed      = GameData.DEFAULT_WALK_SPEED
    self.sprintSpeed    = GameData.DEFAULT_SPRINT_SPEED
    self.connection     = nil
    self.isFalling      = false
    self.fallStartY     = nil
    self.lastGroundY    = nil
    self.fallCheckTimer = 0
    self.coinCheckTimer = 0
    self.lastHazardTime = 0
    self.isMoving       = false
    self.slimeSystem    = nil
    self.slideVelocity  = Vector3.new(0, 0, 0)
    self.slideDecayT    = 1.0
    self.wasOnSlime     = false
    self.lastMoveDir    = Vector3.new(0, 0, 0)
    self.coyoteTimer    = 0
    self.wasGrounded    = false
    self.airJumpsMax    = 0
    self.airJumpsLeft   = 0
    self.spaceWasDown   = false
    self.comboStreak    = 0
    self.comboTimer     = 0
    self.comboMult      = 1
    self.magnetRadius   = 5
    self.modifier       = GameData.RunModifiers.Normal
    self.hudRef         = nil
    self.visualsRef     = nil
    self.weightSpeedMult = 1.0
    self.currentTerrainType = nil
    self.pickaxeRef = nil  -- set via SetPickaxe()
    return self
end

function Movement:SetPickaxe(pickaxeObj)
    self.pickaxeRef = pickaxeObj
end

function Movement:SetSlimeSystem(slimeSys)
    self.slimeSystem = slimeSys
end

function Movement:SetHUD(hud)
    self.hudRef = hud
end

function Movement:SetVisuals(vis)
    self.visualsRef = vis
end

function Movement:ApplyStats(stats)
    self.walkSpeed    = stats.walkSpeed   or GameData.DEFAULT_WALK_SPEED
    self.sprintSpeed  = stats.sprintSpeed or GameData.DEFAULT_SPRINT_SPEED
    self.airJumpsMax  = stats.airJumps    or 0
    self.airJumpsLeft = self.airJumpsMax
    self.magnetRadius = stats.coinMagnet  or 5
    if self.sprintSpeed <= self.walkSpeed then
        self.sprintSpeed = self.walkSpeed * 1.55
    end
end

function Movement:SetWeightEffects(speedMult)
    self.weightSpeedMult = math.max(0.1, speedMult or 1.0)
end

function Movement:SetModifier(mod)
    self.modifier = mod or GameData.RunModifiers.Normal
end

local function getGroundPart(hrp, char)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { char }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -4.5, 0), rp)
    return result and result.Instance or nil
end

local function isGroundSlimed(hrp, char, slimeSystem)
    if not slimeSystem then return false end
    local part = getGroundPart(hrp, char)
    if not part then return false end
    return slimeSystem.IsSlimed(part)
end

local function getGroundTerrainType(hrp, char)
    local part = getGroundPart(hrp, char)
    if not part then return nil end
    local tag = part:FindFirstChild("TerrainType")
    return tag and tag.Value or nil
end

-- Returns isGrounded (bool), groundPart (Instance|nil)
local function isGroundedRaycast(hrp, char)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { char }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -5, 0), rp)
    return result ~= nil, result and result.Instance or nil
end

function Movement:GetCharacter() return self.player.Character end
function Movement:GetHumanoid()
    local c = self:GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end
function Movement:GetHRP()
    local c = self:GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end
function Movement:IsFalling()  return self.isFalling end
function Movement:IsMoving()   return self.isMoving end
function Movement:UpdateSpeeds(walk, sprint)
    self.walkSpeed   = walk   or self.walkSpeed
    self.sprintSpeed = sprint or self.sprintSpeed
end

-- Called by pickaxe grab: halts the fall, cancels fall damage, brief hang
function Movement:OnPickaxeGrab(hrp)
    if not hrp then return end
    -- Stop vertical momentum (zero Y velocity, keep horizontal)
    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X * 0.4, 0, vel.Z * 0.4)

    -- Calculate fall distance up to this point for feedback but deal NO damage
    local fallDist = self.fallStartY and (self.fallStartY - hrp.Position.Y) or 0

    -- Cancel fall state cleanly
    self.isFalling    = false
    self.fallStartY   = nil
    self.lastGroundY  = hrp.Position.Y
    self.airJumpsLeft = self.airJumpsMax

    -- Camera shake + dust puff feedback
    if fallDist > 8 then
        self.camera:ApplyShake(math.clamp(fallDist / 14, 0.8, 3.5), 0.28, 20)
    end
    if self.visualsRef then
        self.visualsRef:SpawnDustPuff(hrp.Position)
    end
    if self.hudRef then
        self.hudRef:UpdateAirJumps(self.airJumpsLeft, self.airJumpsMax)
    end

    -- Short "hang" phase: briefly reduce gravity effect so it feels like clinging
    local bv = hrp:FindFirstChild("GrabHangBV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name     = "GrabHangBV"
        bv.MaxForce = Vector3.new(0, 4000, 0)
        bv.Parent   = hrp
    end
    bv.Velocity = Vector3.new(0, 0, 0)
    task.delay(0.45, function()
        local stillBV = hrp:FindFirstChild("GrabHangBV")
        if stillBV then stillBV:Destroy() end
    end)
end

-- Platform names that count as a soft landing (70% damage reduction)
local PLATFORM_NAMES = { Platform = true, PlatformFill = true }

function Movement:OnLand(fallDistStuds, groundPart)
    if not self.isFalling then return end
    self.isFalling    = false
    self.airJumpsLeft = self.airJumpsMax
    local fallMeters  = GameData.StudsToMeters(fallDistStuds)

    -- If landed on a generated platform, significantly reduce reported fall distance
    -- (platforms have give - they absorb impact better than hard floor)
    if groundPart and (PLATFORM_NAMES[groundPart.Name]
        or groundPart:FindFirstChild("TerrainType")) then
        fallMeters = fallMeters * 0.3
    end

    if fallMeters > GameData.FALL_DAMAGE_THRESHOLD_METERS then
        Networking.FireServer(Networking.Events.ApplyFallDamage, fallMeters)
    end
    if fallDistStuds > 8 then
        self.camera:ApplyShake(math.clamp(fallDistStuds / 8, 1.0, 5.0), 0.35, 26)
        if self.visualsRef then
            local hrp = self:GetHRP()
            if hrp then self.visualsRef:SpawnDustPuff(hrp.Position) end
        end
    end
    self.fallStartY = nil
end

function Movement:CheckHazard()
    local now = tick()
    if now - self.lastHazardTime < HAZARD_COOLDOWN then return end
    local char = self:GetCharacter()
    local hrp  = self:GetHRP()
    if not char or not hrp then return end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { char }
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), rp)
    if result and result.Instance then
        local hazardTag = result.Instance:FindFirstChild("IsHazard")
        if hazardTag then
            local dmg = tonumber(hazardTag.Value) or 10
            local hum = self:GetHumanoid()
            if hum then
                hum.Health = hum.Health - dmg
                self.lastHazardTime = now
            end
        end
    end
end

function Movement:CheckCoins()
    local hrp = self:GetHRP()
    if not hrp then return end
    local pos     = hrp.Position
    local magnetR = math.max(self.magnetRadius, 5)
    local collectR = 5

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { self.player.Character }
    local nearParts = workspace:GetPartBoundsInRadius(pos, magnetR, overlapParams)

    for _, part in ipairs(nearParts) do
        if part.Name == "GoldCoin" and part:FindFirstChild("IsCoin") then
            local diff = pos - part.Position
            local dist = diff.Magnitude

            if dist < magnetR and dist > collectR then
                local pullDir   = diff.Unit
                local pullSpeed = MAGNET_PULL_SPEED * (1 - dist / magnetR)
                part.CFrame = part.CFrame + pullDir * pullSpeed * COIN_CHECK_RATE
            end

            if dist < collectR then
                self.comboStreak = self.comboStreak + 1
                self.comboTimer  = COMBO_RESET_TIME
                self.comboMult   = getComboMult(self.comboStreak)

                -- FIX Bug#10: fire CollectCoin only (server handles combo server-side)
                local coinId = string.format("%.1f_%.1f_%.1f",
                    part.Position.X, part.Position.Y, part.Position.Z)
                Networking.FireServer(Networking.Events.CollectCoin, coinId)

                if self.hudRef then
                    self.hudRef:UpdateCombo(self.comboStreak, self.comboMult)
                end
                if self.visualsRef then
                    self.visualsRef:PulseCoinCollect()
                end
                part:Destroy()
            end
        end
    end
end

function Movement:CheckTreasureChests()
    local hrp = self:GetHRP()
    if not hrp then return end
    local pos = hrp.Position
    local collectRange = 6

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { self.player.Character }
    local nearParts = workspace:GetPartBoundsInRadius(pos, 14, overlapParams)

    for _, part in ipairs(nearParts) do
        if part.Name == "ChestBody" and part:FindFirstChild("IsTreasureChest") then
            local chestIdTag = part:FindFirstChild("ChestId")
            local dist = (pos - part.Position).Magnitude
            if dist <= collectRange and chestIdTag then
                if part:FindFirstChild("_Collecting") then continue end
                local guard = Instance.new("BoolValue")
                guard.Name   = "_Collecting"
                guard.Parent = part
                Networking.FireServer(Networking.Events.CollectTreasureChest, chestIdTag.Value)
                -- Visually hide the chest immediately (server destroys for real)
                local model = part.Parent
                if model and model:IsA("Model") then
                    for _, child in ipairs(model:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.Transparency = 1
                            child.CanCollide   = false
                        elseif child:IsA("BillboardGui") then
                            child.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

function Movement:CheckItemCrates()
    local hrp = self:GetHRP()
    if not hrp then return end
    local pos = hrp.Position
    local collectRange = 6.5

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { self.player.Character }
    local nearParts = workspace:GetPartBoundsInRadius(pos, 12, overlapParams)

    for _, part in ipairs(nearParts) do
        if part.Name == "BaseCrate" and part:FindFirstChild("IsItemCrate") then
            local crateIdTag = part:FindFirstChild("CrateId")
            local dist = (pos - part.Position).Magnitude
            if dist <= collectRange and crateIdTag then
                if part:FindFirstChild("_Collecting") then continue end
                local guard = Instance.new("BoolValue")
                guard.Name   = "_Collecting"
                guard.Parent = part
                Networking.FireServer(Networking.Events.CollectItem, crateIdTag.Value)
                local model = part.Parent
                if model and model:IsA("Model") then
                    for _, child in ipairs(model:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.Transparency = 1
                            child.CanCollide   = false
                        elseif child:IsA("BillboardGui") or child:IsA("SelectionBox") then
                            child.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

function Movement:CheckFinish()
    local hrp = self:GetHRP()
    if not hrp then return end
    local finishY = GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS)
    if hrp.Position.Y <= finishY + 6 then
        Networking.FireServer(Networking.Events.PlayerReachedBottom)
        task.defer(function() self:Stop() end)
    end
end

function Movement:Start()
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function Movement:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

function Movement:Update(dt)
    local char     = self:GetCharacter()
    local humanoid = self:GetHumanoid()
    local hrp      = self:GetHRP()
    if not humanoid or not hrp or not char then
        self.isMoving = false
        return
    end

    local mod = self.modifier or GameData.RunModifiers.Normal
    local onSlime = isGroundSlimed(hrp, char, self.slimeSystem)
    self.currentTerrainType = getGroundTerrainType(hrp, char)

    local isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local baseSpeed   = (isSprinting and self.sprintSpeed or self.walkSpeed)
        * (mod.speedMult or 1)
        * (self.weightSpeedMult or 1.0)
    humanoid.WalkSpeed = onSlime
        and (baseSpeed * SLIME_SPEED_MULT + SLIME_EXTRA_SPEED)
        or  baseSpeed

    local moveDir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0,  1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new( 1, 0, 0) end

    local hasInput = moveDir.Magnitude > 0
    local worldDir = Vector3.new(0, 0, 0)
    if hasInput then
        moveDir = moveDir.Unit
        local wd = hrp.CFrame:VectorToWorldSpace(moveDir)
        worldDir = Vector3.new(wd.X, 0, wd.Z)
        if worldDir.Magnitude > 0 then worldDir = worldDir.Unit end
        self.lastMoveDir = worldDir
        self.isMoving    = true
    else
        self.isMoving = false
    end

    -- Fall / coyote check
    self.fallCheckTimer = self.fallCheckTimer + dt
    if self.fallCheckTimer >= FALL_CHECK_INTERVAL then
        self.fallCheckTimer = 0
        local isOnGround, groundPart = isGroundedRaycast(hrp, char)
        if isOnGround then
            if self.isFalling and self.fallStartY then
                local fallDist = self.fallStartY - hrp.Position.Y
                self:OnLand(math.max(0, fallDist), groundPart)
            end
            self.lastGroundY = hrp.Position.Y
            self.isFalling   = false
            self.wasGrounded = true
            self.coyoteTimer = COYOTE_TIME
        else
            self.coyoteTimer = math.max(0, self.coyoteTimer - FALL_CHECK_INTERVAL)
            if self.wasGrounded and self.coyoteTimer <= 0 then
                self.wasGrounded = false
            end
            if not self.isFalling then
                if self.lastGroundY and hrp.Position.Y < (self.lastGroundY - 2) then
                    self.isFalling  = true
                    self.fallStartY = self.lastGroundY
                end
            end
        end
    end

    -- Air jump
    local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if spaceDown and not self.spaceWasDown then
        local isOnGround, _ = isGroundedRaycast(hrp, char)
        local canCoyote  = self.coyoteTimer > 0
        if not isOnGround and not canCoyote and self.airJumpsLeft > 0 then
            self.airJumpsLeft = self.airJumpsLeft - 1
            local vel = hrp.AssemblyLinearVelocity
            if vel.Y < AIR_JUMP_IMPULSE * 0.5 then
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, AIR_JUMP_IMPULSE, vel.Z)
            end
            Networking.FireServer(Networking.Events.AirJumpUsed)
            if self.hudRef then
                self.hudRef:UpdateAirJumps(self.airJumpsLeft, self.airJumpsMax)
            end
            if self.visualsRef then
                self.visualsRef:SpawnAirJumpPuff(hrp.Position)
            end
        end
    end
    self.spaceWasDown = spaceDown

    -- Combo decay
    if self.comboStreak > 0 then
        self.comboTimer = self.comboTimer - dt
        if self.comboTimer <= 0 then
            self.comboStreak = 0
            self.comboMult   = 1
            if self.hudRef then self.hudRef:UpdateCombo(0, 1) end
        end
    end

    -- Slime slip momentum
    if onSlime then
        if hasInput then
            self.slideVelocity = worldDir * humanoid.WalkSpeed
            self.slideDecayT   = 0
            self.wasOnSlime    = true
        end
        humanoid:Move(worldDir, false)
    else
        if self.wasOnSlime and self.slideDecayT < 1.0 then
            self.slideDecayT = math.min(1.0, self.slideDecayT + dt / SLIDE_DURATION)
            local mult = cubicEaseOut(self.slideDecayT)
            if mult > 0.01 then
                local slideDir = self.slideVelocity.Magnitude > 0 and self.slideVelocity.Unit or self.lastMoveDir
                local finalDir = slideDir * mult
                if hasInput then finalDir = (finalDir + worldDir * 0.4).Unit end
                humanoid:Move(finalDir, false)
                local existingBV = hrp:FindFirstChild("SlimeBV")
                if not existingBV then
                    existingBV         = Instance.new("BodyVelocity")
                    existingBV.Name    = "SlimeBV"
                    existingBV.MaxForce = Vector3.new(1e4, 0, 1e4)
                    existingBV.Parent  = hrp
                end
                existingBV.Velocity = Vector3.new(
                    slideDir.X * mult * self.slideVelocity.Magnitude * 0.6,
                    0,
                    slideDir.Z * mult * self.slideVelocity.Magnitude * 0.6)
            else
                self.wasOnSlime    = false
                self.slideDecayT   = 1.0
                self.slideVelocity = Vector3.new(0, 0, 0)
                local bv = hrp:FindFirstChild("SlimeBV")
                if bv then bv:Destroy() end
                humanoid:Move(worldDir, false)
            end
        else
            if self.wasOnSlime and self.slideDecayT >= 1.0 then
                self.wasOnSlime = false
                local bv = hrp:FindFirstChild("SlimeBV")
                if bv then bv:Destroy() end
            end
            humanoid:Move(worldDir, false)
        end
    end

    -- Periodic checks
    self.coinCheckTimer = self.coinCheckTimer + dt
    if self.coinCheckTimer >= COIN_CHECK_RATE then
        self.coinCheckTimer = 0
        self:CheckCoins()
        self:CheckItemCrates()
        self:CheckTreasureChests()
    end
    self:CheckHazard()
    self:CheckFinish()
end

return Movement
