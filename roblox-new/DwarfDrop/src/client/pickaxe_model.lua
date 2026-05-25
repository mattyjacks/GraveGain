-- DwarfDrop: pickaxe_model.lua
-- Client-side pickaxe: viewmodel, swing animation, mine/pvp hit detection

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Networking = require(game.ReplicatedStorage.Shared.networking)
local GameData   = require(game.ReplicatedStorage.Shared.game_data)

local PickaxeModel = {}
PickaxeModel.__index = PickaxeModel

local SWING_COOLDOWN  = 0.38  -- seconds between swings
local SWING_DURATION  = 0.22  -- full swing arc time
local MINE_RANGE      = 14    -- studs
local PVP_RANGE       = 10    -- studs, for hit detection
local VIEWMODEL_OFFSET = CFrame.new(1.1, -1.2, -2.4)
    * CFrame.Angles(math.rad(-10), math.rad(10), 0)

-- Names of the outer shaft walls (cannot grab these)
local OUTER_WALL_NAMES = {
    WallN = true, WallS = true, WallE = true, WallW = true,
    BasketWall1 = true, BasketWall2 = true,
    BasketWall3 = true, BasketWall4 = true, BasketFloor = true,
}

function PickaxeModel.new(fpsCamera)
    local self = setmetatable({}, PickaxeModel)
    self.player       = Players.LocalPlayer
    self.fpsCamera    = fpsCamera
    self.model        = nil
    self.connection   = nil
    self.swingTimer   = 0
    self.swingActive  = false
    self.swingT       = 0
    self.active       = false
    self.movementRef  = nil  -- set via SetMovement()
    self.grabCooldown = 0    -- prevent spam grabs
    return self
end

function PickaxeModel:SetMovement(movementObj)
    self.movementRef = movementObj
end

-- Build a simple pickaxe viewmodel from parts
local function buildPickaxeModel()
    local model = Instance.new("Model")
    model.Name = "PickaxeViewModel"

    -- Handle
    local handle = Instance.new("Part")
    handle.Name     = "Handle"
    handle.Size     = Vector3.new(0.18, 1.1, 0.18)
    handle.Color    = Color3.fromRGB(100, 70, 40)
    handle.Material = Enum.Material.Wood
    handle.Anchored = false
    handle.CanCollide = false
    handle.CastShadow = false
    handle.Parent = model

    -- Head
    local head = Instance.new("Part")
    head.Name     = "Head"
    head.Size     = Vector3.new(0.14, 0.14, 0.8)
    head.Color    = Color3.fromRGB(150, 150, 160)
    head.Material = Enum.Material.Metal
    head.Anchored = false
    head.CanCollide = false
    head.CastShadow = false
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0  = handle
    weld.Part1  = head
    weld.Parent = handle

    head.CFrame = handle.CFrame
        * CFrame.new(0, 0.55, -0.28)
        * CFrame.Angles(0, 0, math.rad(45))

    model.PrimaryPart = handle
    return model
end

function PickaxeModel:Equip()
    if self.model then self:Unequip() end
    self.model = buildPickaxeModel()
    self.model.Parent = workspace
    self.active = true

    self.connection = RunService.RenderStepped:Connect(function(dt)
        self:UpdateViewmodel(dt)
    end)
end

function PickaxeModel:Unequip()
    self.active = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
end

function PickaxeModel:UpdateViewmodel(dt)
    if not self.model then return end
    local camera = workspace.CurrentCamera

    self.swingTimer = math.max(0, self.swingTimer - dt)

    if self.swingActive then
        self.swingT = math.min(1, self.swingT + dt / SWING_DURATION)
        if self.swingT >= 1 then
            self.swingActive = false
            self.swingT = 0
        end
    end

    -- Swing arc: rotate handle around Y during swing
    local swingAngle = 0
    if self.swingActive then
        local t = self.swingT
        -- Quick forward arc then back
        if t < 0.4 then
            swingAngle = math.rad(-70) * (t / 0.4)
        else
            swingAngle = math.rad(-70) * (1 - (t - 0.4) / 0.6)
        end
    end

    local swingOffset = CFrame.Angles(swingAngle, 0, 0)
    local targetCF = camera.CFrame * VIEWMODEL_OFFSET * swingOffset

    -- Smooth follow (guard against PrimaryPart being nil if model was just destroyed)
    if not self.model.PrimaryPart then return end
    self.model:SetPrimaryPartCFrame(targetCF)
end

-- Returns true if the given part is an outer shaft wall (not grab-able)
local function isOuterWall(part)
    if not part then return true end
    if OUTER_WALL_NAMES[part.Name] then return true end
    -- Slot walls are tagged WallN/WallS/WallE/WallW by name
    if part.Name == "WallN" or part.Name == "WallS"
        or part.Name == "WallE" or part.Name == "WallW" then
        return true
    end
    return false
end

function PickaxeModel:TrySwing(modeId, sessionMembersRef)
    if self.swingTimer > 0 then return end
    self.swingTimer  = SWING_COOLDOWN
    self.swingActive = true
    self.swingT      = 0

    local player = self.player
    local char   = player.Character
    local hrp    = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camera  = workspace.CurrentCamera
    local origin  = camera.CFrame.Position
    local forward = camera.CFrame.LookVector

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = { char }
    rp.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, forward * MINE_RANGE, rp)
    if not result then return end

    local hit    = result.Instance
    local hitPos = result.Position

    -- Check ore first
    if hit and hit:FindFirstChild("IsOre") then
        Networking.FireServer(Networking.Events.MineWall, hit, hitPos)
        Networking.FireServer(Networking.Events.PickaxeTerrainHit, hitPos, "ore")
        Networking.FireServer(Networking.Events.CameraShakeSignal, 1.2, 0.25)
        return
    end

    -- Pickaxe grab: if player is falling and hit a non-outer-wall surface, grab it
    if hit and not isOuterWall(hit) and self.movementRef then
        local mov = self.movementRef
        if mov:IsFalling() and self.grabCooldown <= 0 then
            self.grabCooldown = 1.2  -- 1.2s cooldown before can grab again
            mov:OnPickaxeGrab(hrp)
            Networking.FireServer(Networking.Events.PickaxeTerrainHit, hitPos, "grab")
            if self.fpsCamera then
                self.fpsCamera:ApplyShake(1.8, 0.3, 22)
            end
            return
        end
    end

    -- PvP check
    local pvpEnabled = false
    if modeId == "Competitive" then pvpEnabled = true end

    if pvpEnabled then
        for _, targetPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
            if targetPlayer == player then continue end
            local tChar = targetPlayer.Character
            local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if not tHRP then continue end
            local dist = (hrp.Position - tHRP.Position).Magnitude
            if dist <= PVP_RANGE then
                local toTarget = (tHRP.Position - hrp.Position).Unit
                local dot = forward:Dot(toTarget)
                if dot > 0.6 then
                    Networking.FireServer(Networking.Events.AttackPlayer,
                        targetPlayer.UserId, tHRP.Position)
                    break
                end
            end
        end
    end

    -- Terrain hit effect
    if hit then
        Networking.FireServer(Networking.Events.PickaxeTerrainHit, hitPos, "rock")
    end
end

function PickaxeModel:Update(dt)
    if self.grabCooldown > 0 then
        self.grabCooldown = math.max(0, self.grabCooldown - dt)
    end
end

return PickaxeModel
