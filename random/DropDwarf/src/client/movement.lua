-- DropDwarf: movement.lua
-- WASD movement, sprint, fall detection, hazard handling,
-- slimed terrain speed boost + cubic bezier slip momentum,
-- coyote time, double jump (from upgrade), coin magnet + combo streak.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local GameData   = require(game.ReplicatedStorage.Shared.game_data)
local Networking = require(game.ReplicatedStorage.Shared.networking)

local Movement = {}
Movement.__index = Movement

local FALL_CHECK_INTERVAL = 0.05
local HAZARD_COOLDOWN     = 0.5
local COIN_CHECK_RATE     = 0.08  -- how often to run magnet+collect check

-- Slime momentum
local SLIDE_DURATION   = 1.0
local SLIME_SPEED_MULT = 1.55
local SLIME_EXTRA_SPEED = 16

-- Coyote time + air jump
local COYOTE_TIME      = GameData.COYOTE_TIME  -- 0.15s
local AIR_JUMP_IMPULSE = 52  -- studs/s upward kick per air jump

-- Coin magnet / combo
local COMBO_RESET_TIME  = GameData.COMBO_RESET_TIME
local COMBO_THRESHOLDS  = GameData.COMBO_THRESHOLDS
local COMBO_MULTIPLIERS = GameData.COMBO_MULTIPLIERS
local MAGNET_PULL_SPEED = GameData.MAGNET_PULL_SPEED

-- Cubic ease-out for slime slide: (1-t)^2 * (1+2t)
local function cubicEaseOut(t)
    t = math.clamp(t, 0, 1)
    local inv = 1 - t
    return inv * inv * (1 + 2 * t)
end

-- Get current combo multiplier from streak count
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
    self.player        = Players.LocalPlayer
    self.camera        = fpsCamera
    self.walkSpeed     = GameData.DEFAULT_WALK_SPEED
    self.sprintSpeed   = GameData.DEFAULT_SPRINT_SPEED
    self.connection    = nil
    self.isFalling     = false
    self.fallStartY    = nil
    self.lastGroundY   = nil
    self.fallCheckTimer  = 0
    self.coinCheckTimer  = 0
    self.lastHazardTime  = 0
    self.isMoving        = false
    -- Slime slip
    self.slimeSystem     = nil
    self.slideVelocity   = Vector3.new(0, 0, 0)
    self.slideDecayT     = 1.0
    self.wasOnSlime      = false
    self.lastMoveDir     = Vector3.new(0, 0, 0)
    -- Coyote time
    self.coyoteTimer     = 0
    self.wasGrounded     = false
    -- Double jump / air jump
    self.airJumpsMax     = 0   -- set from StatsUpdate
    self.airJumpsLeft    = 0
    self.spaceWasDown    = false
    -- Coin combo
    self.comboStreak     = 0
    self.comboTimer      = 0
    self.comboMult       = 1
    -- Coin magnet radius (from stats)
    self.magnetRadius    = 5
    -- Modifier
    self.modifier        = GameData.RunModifiers.Normal
    -- HUD reference (set externally)
    self.hudRef          = nil
    -- Current terrain type (read by pickaxe)
    self.currentTerrainType = nil
    return self
end

-- Wire in the slime system
function Movement:SetSlimeSystem(slimeSys)
    self.slimeSystem = slimeSys
end

-- Wire in HUD for combo display
function Movement:SetHUD(hud)
    self.hudRef = hud
end

-- Apply stats from server (called after StatsUpdate event)
function Movement:ApplyStats(stats)
    self.walkSpeed    = stats.walkSpeed   or self.walkSpeed
    self.sprintSpeed  = stats.sprintSpeed or self.sprintSpeed
    self.airJumpsMax  = stats.airJumps    or 0
    self.airJumpsLeft = self.airJumpsMax
    self.magnetRadius = stats.coinMagnet  or 5
end

-- Called when server fires WeightUpdate
function Movement:SetWeightEffects(speedMult)
    self.weightSpeedMult = math.max(0.1, speedMult or 1.0)
end

-- Apply run modifier (speedMult applied to base speeds)
function Movement:SetModifier(mod)
    self.modifier = mod or GameData.RunModifiers.Normal
end

-- Raycast downward and return the ground Part (or nil)
local function getGroundPart(hrp, char)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -4.5, 0), rayParams)
    return result and result.Instance or nil
end

-- Returns true if the ground under hrp is a slimed part
local function isGroundSlimed(hrp, char, slimeSystem)
    if not slimeSystem then return false end
    local part = getGroundPart(hrp, char)
    if not part then return false end
    return slimeSystem.IsSlimed(part)
end

-- Returns terrain type string of ground under hrp ("Soft", "Firm", "Hard", or nil)
local function getGroundTerrainType(hrp, char)
    local part = getGroundPart(hrp, char)
    if not part then return nil end
    local tag = part:FindFirstChild("TerrainType")
    return tag and tag.Value or nil
end

function Movement:GetCharacter()
    return self.player.Character
end

function Movement:GetHumanoid()
    local char = self:GetCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function Movement:GetHRP()
    local char = self:GetCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function Movement:UpdateSpeeds(walkSpeed, sprintSpeed)
    self.walkSpeed   = walkSpeed   or self.walkSpeed
    self.sprintSpeed = sprintSpeed or self.sprintSpeed
end

-- Landing squash: briefly nudge HRP down to simulate a squash impact
local function doLandingSquash(hrp, intensity)
    if not hrp then return end
    intensity = math.clamp(intensity, 0, 1)
    local tInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tInfo2 = TweenInfo.new(0.18, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    local offset = Vector3.new(0, -intensity * 1.2, 0)
    local squashCF = hrp.CFrame * CFrame.new(offset)
    TweenService:Create(hrp, tInfo, { CFrame = squashCF }):Play()
    task.delay(0.07, function()
        -- Spring back to wherever the HRP currently is (not the stale pre-squash position)
        if hrp and hrp.Parent then
            local recoverCF = hrp.CFrame * CFrame.new(-offset)
            TweenService:Create(hrp, tInfo2, { CFrame = recoverCF }):Play()
        end
    end)
end

function Movement:IsFalling()
    return self.isFalling
end

function Movement:IsMoving()
    return self.isMoving
end

-- Called when player lands from a fall
function Movement:OnLand(fallDistStuds)
    if not self.isFalling then return end
    self.isFalling    = false
    self.airJumpsLeft = self.airJumpsMax  -- restore air jumps on landing
    local fallMeters  = GameData.StudsToMeters(fallDistStuds)
    if fallMeters > GameData.FALL_DAMAGE_THRESHOLD_METERS then
        Networking.FireServer(Networking.Events.ApplyFallDamage, fallMeters)
    end
    -- Landing squash proportional to fall distance
    local intensity = math.clamp((fallMeters - 2) / 20, 0, 1)
    if intensity > 0.05 then
        local hrp = self:GetHRP()
        doLandingSquash(hrp, intensity)
    end
    self.fallStartY = nil
end

-- Check if standing on hazard
function Movement:CheckHazard()
    local now = tick()
    if now - self.lastHazardTime < HAZARD_COOLDOWN then return end
    local char = self:GetCharacter()
    if not char then return end
    local hrp = self:GetHRP()
    if not hrp then return end

    -- Raycast downward to detect hazard
    local origin = hrp.Position
    local direction = Vector3.new(0, -4, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance then
        local hazardTag = result.Instance:FindFirstChild("IsHazard")
        if hazardTag then
            local dmg = tonumber(hazardTag.Value) or 10
            local humanoid = self:GetHumanoid()
            if humanoid then
                humanoid.Health = humanoid.Health - dmg
                self.lastHazardTime = now
            end
        end
    end
end

-- Check coins: magnet pull + auto-collect + combo streak
function Movement:CheckCoins()
    local hrp = self:GetHRP()
    if not hrp then return end
    local pos = hrp.Position
    local magnetR = math.max(self.magnetRadius, 5)  -- at least collectR
    local collectR = 5  -- hard collect radius

    -- Use spatial query limited to magnet radius instead of GetDescendants (O(n) on all workspace)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { self.player.Character }
    local nearParts = workspace:GetPartBoundsInRadius(pos, magnetR, overlapParams)

    for _, part in ipairs(nearParts) do
        if part.Name == "GoldCoin" and part:FindFirstChild("IsCoin") then
            local diff = pos - part.Position
            local dist = diff.Magnitude

            -- Magnet pull: lerp coin toward player
            if dist < magnetR and dist > collectR then
                local pullDir = diff.Unit
                local pullSpeed = MAGNET_PULL_SPEED * (1 - dist / magnetR)
                part.CFrame = part.CFrame + pullDir * pullSpeed * COIN_CHECK_RATE
            end

            -- Collect
            if dist < collectR then
                -- Advance combo
                self.comboStreak = self.comboStreak + 1
                self.comboTimer  = COMBO_RESET_TIME
                self.comboMult   = getComboMult(self.comboStreak)

                local coinId = string.format("%.1f_%.1f_%.1f", part.Position.X, part.Position.Y, part.Position.Z)
                Networking.FireServer(Networking.Events.CollectCoin, coinId)
                -- Tell HUD
                if self.hudRef then
                    self.hudRef:UpdateCombo(self.comboStreak, self.comboMult)
                end
                part:Destroy()
            end
        end
    end
end

-- Check for finish platform
function Movement:CheckFinish()
    local hrp = self:GetHRP()
    if not hrp then return end
    local pos = hrp.Position
    local finishY = GameData.DepthToWorldY(GameData.TOTAL_DEPTH_METERS)
    if pos.Y <= finishY + 6 then
        -- Player reached bottom
        Networking.FireServer(Networking.Events.PlayerReachedBottom)
        -- Defer Stop() so we don't disconnect the Heartbeat while Update is still on the call stack
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

    -- Detect slimed ground + terrain type
    local onSlime = isGroundSlimed(hrp, char, self.slimeSystem)
    self.currentTerrainType = getGroundTerrainType(hrp, char)

    -- Speed: base * modifier * weight penalty * slime boost
    local isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local baseSpeed   = (isSprinting and self.sprintSpeed or self.walkSpeed)
        * (mod.speedMult or 1)
        * (self.weightSpeedMult or 1.0)
    if onSlime then
        humanoid.WalkSpeed = baseSpeed * SLIME_SPEED_MULT + SLIME_EXTRA_SPEED
    else
        humanoid.WalkSpeed = baseSpeed
    end

    -- ====  WASD DIRECTION ====
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

    -- ==== FALL CHECK + COYOTE TIME ====
    self.fallCheckTimer = self.fallCheckTimer + dt
    if self.fallCheckTimer >= FALL_CHECK_INTERVAL then
        self.fallCheckTimer = 0
        local isOnGround = humanoid.FloorMaterial ~= Enum.Material.Air

        if isOnGround then
            -- Just landed
            if self.isFalling and self.fallStartY then
                local fallDist = self.fallStartY - hrp.Position.Y
                self:OnLand(math.max(0, fallDist))
            end
            self.lastGroundY  = hrp.Position.Y
            self.isFalling    = false
            self.wasGrounded  = true
            self.coyoteTimer  = COYOTE_TIME
        else
            -- In air
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

    -- ==== AIR JUMP (DOUBLE JUMP) ====
    local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if spaceDown and not self.spaceWasDown then
        -- Rising edge of Space
        local isOnGround = humanoid.FloorMaterial ~= Enum.Material.Air
        local canCoyote  = self.coyoteTimer > 0

        if not isOnGround and not canCoyote and self.airJumpsLeft > 0 then
            -- Air jump!
            self.airJumpsLeft = self.airJumpsLeft - 1
            -- Apply upward velocity
            local vel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, AIR_JUMP_IMPULSE, vel.Z)
            Networking.FireServer(Networking.Events.AirJumpUsed)
            -- Notify HUD of remaining air jumps
            if self.hudRef then
                self.hudRef:UpdateAirJumps(self.airJumpsLeft, self.airJumpsMax)
            end
        end
    end
    self.spaceWasDown = spaceDown

    -- ==== COMBO DECAY ====
    if self.comboStreak > 0 then
        self.comboTimer = self.comboTimer - dt
        if self.comboTimer <= 0 then
            self.comboStreak = 0
            self.comboMult   = 1
            if self.hudRef then
                self.hudRef:UpdateCombo(0, 1)
            end
        end
    end

    -- ==== SLIME SLIP MOMENTUM ====
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
                if hasInput then
                    finalDir = (finalDir + worldDir * 0.4).Unit
                end
                humanoid:Move(finalDir, false)
                local existingBV = hrp:FindFirstChild("SlimeBV")
                if not existingBV then
                    existingBV = Instance.new("BodyVelocity")
                    existingBV.Name     = "SlimeBV"
                    existingBV.MaxForce = Vector3.new(1e4, 0, 1e4)
                    existingBV.Parent   = hrp
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

    -- ==== PERIODIC COIN + HAZARD + FINISH ====
    self.coinCheckTimer = self.coinCheckTimer + dt
    if self.coinCheckTimer >= COIN_CHECK_RATE then
        self.coinCheckTimer = 0
        self:CheckCoins()
    end
    self:CheckHazard()
    self:CheckFinish()
end

return Movement
