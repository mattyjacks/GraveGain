-- DwarfDrop: fps_camera.lua
-- First-person / third-person camera with mouse look and shake

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FPSCamera = {}
FPSCamera.__index = FPSCamera

local MOUSE_SENSITIVITY = 0.003
local VERTICAL_CLAMP    = 80  -- degrees
local TPS_GHOST_ALPHA   = 0.7

function FPSCamera.new()
    local self = setmetatable({}, FPSCamera)
    self.player      = Players.LocalPlayer
    self.camera      = workspace.CurrentCamera
    self.yaw         = 0
    self.pitch       = 0
    self.active      = false
    self.isDead      = false
    self.dropType    = "fps"
    self.connection  = nil
    self.tpsGhosted  = {}
    self.shakeTime      = 0
    self.shakeDuration  = 0
    self.shakeMagnitude = 0
    self.shakeSpeed     = 25
    return self
end

function FPSCamera:GetCharacter()
    return self.player.Character
end

function FPSCamera:GetHRP()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function hideCharacter(char)
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj.Name == "FlashlightAnchor" or obj.Name == "FlashlightBeam" then continue end
        if obj:IsA("BasePart") then
            obj.LocalTransparencyModifier = 1
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        end
    end
end

local function showCharacter(char)
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.LocalTransparencyModifier = 0
        elseif obj:IsA("Decal") then
            obj.Transparency = 0
        end
    end
end

function FPSCamera:SetupFirstPerson()
    hideCharacter(self:GetCharacter())
    UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    self.camera.CameraType = Enum.CameraType.Scriptable
end

function FPSCamera:RestoreFirstPerson()
    showCharacter(self:GetCharacter())
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    self.camera.CameraType = Enum.CameraType.Custom
end

function FPSCamera:Start(dropType)
    if self.active then self:Stop() end
    self.active   = true
    self.dropType = dropType or "fps"

    if self.dropType == "fps" then
        self:SetupFirstPerson()
        local hrp = self:GetHRP()
        if hrp then
            local eyePos = hrp.Position + Vector3.new(0, 1.5, 0)
            self.camera.CFrame = CFrame.new(eyePos)
                * CFrame.Angles(0, self.yaw, 0)
                * CFrame.Angles(self.pitch, 0, 0)
        end
        self.connection = RunService.RenderStepped:Connect(function()
            self:UpdateFPS()
        end)
    else
        showCharacter(self:GetCharacter())
        local char = self:GetCharacter()
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        self.camera.CameraType = Enum.CameraType.Custom
        if hum then self.camera.CameraSubject = hum end
        UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        self.connection = RunService.RenderStepped:Connect(function()
            self:UpdateTPS()
        end)
    end
end

function FPSCamera:Stop()
    self.active  = false
    self.isDead  = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    for part, origTrans in pairs(self.tpsGhosted) do
        if part and part.Parent then
            part.LocalTransparencyModifier = origTrans
        end
    end
    self.tpsGhosted = {}
    self:RestoreFirstPerson()
    local char = self:GetCharacter()
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end
end

function FPSCamera:EnterDeathView()
    self.isDead = true
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

function FPSCamera:LeaveDeathView()
    self.isDead = false
    if self.active and self.dropType == "fps" then
        UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end

function FPSCamera:ApplyShake(magnitude, duration, speed)
    self.shakeMagnitude = magnitude or 1.5
    self.shakeDuration  = duration  or 0.4
    self.shakeSpeed     = speed     or 25
    self.shakeTime      = self.shakeDuration
end

function FPSCamera:UpdateFPS()
    local hrp = self:GetHRP()
    if not hrp then return end
    local eyePos = hrp.Position + Vector3.new(0, 1.5, 0)

    if self.isDead then
        UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        self.camera.CFrame = CFrame.new(eyePos)
            * CFrame.Angles(0, self.yaw, 0)
            * CFrame.Angles(self.pitch, 0, 0)
        return
    end

    local delta = UserInputService:GetMouseDelta()
    self.yaw   = self.yaw   - delta.X * MOUSE_SENSITIVITY
    self.pitch = self.pitch - delta.Y * MOUSE_SENSITIVITY
    self.pitch = math.clamp(self.pitch,
        math.rad(-VERTICAL_CLAMP), math.rad(VERTICAL_CLAMP))

    local camCF = CFrame.new(eyePos)
        * CFrame.Angles(0, self.yaw, 0)
        * CFrame.Angles(self.pitch, 0, 0)

    if self.shakeTime > 0 then
        self.shakeTime = math.max(0, self.shakeTime - 0.016)
        local ratio = self.shakeTime / math.max(0.001, self.shakeDuration)
        local t = tick() * self.shakeSpeed
        local sx = math.noise(t, 17, 34) * self.shakeMagnitude * ratio
        local sy = math.noise(t, 29, 88) * self.shakeMagnitude * ratio
        local sz = math.noise(t, 93, 14) * self.shakeMagnitude * ratio
        camCF = camCF
            * CFrame.new(sx * 0.12, sy * 0.12, 0)
            * CFrame.Angles(sy * 0.024, sx * 0.024, sz * 0.018)
    end

    self.camera.CFrame = camCF
    hideCharacter(self:GetCharacter())
end

function FPSCamera:UpdateTPS()
    local hrp = self:GetHRP()
    if not hrp then return end
    local camPos  = self.camera.CFrame.Position
    local charPos = hrp.Position
    local dir     = charPos - camPos
    local dist    = dir.Magnitude
    if dist < 0.1 then return end

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local char = self:GetCharacter()
    rp.FilterDescendantsInstances = char and { char } or {}

    local nowGhosted = {}
    local origin    = camPos
    local remaining = dist
    while remaining > 0.5 do
        local result = workspace:Raycast(origin, dir.Unit * remaining, rp)
        if not result then break end
        local part = result.Instance
        if part and part:IsA("BasePart") and part.Transparency < TPS_GHOST_ALPHA then
            if not self.tpsGhosted[part] then
                self.tpsGhosted[part] = part.LocalTransparencyModifier
            end
            part.LocalTransparencyModifier = TPS_GHOST_ALPHA
            nowGhosted[part] = true
            origin    = result.Position + dir.Unit * 0.1
            remaining = (charPos - origin).Magnitude
        else
            break
        end
    end

    for part, origTrans in pairs(self.tpsGhosted) do
        if not nowGhosted[part] then
            if part and part.Parent then
                part.LocalTransparencyModifier = origTrans
            end
            self.tpsGhosted[part] = nil
        end
    end
end

function FPSCamera:GetLookVector()
    return self.camera.CFrame.LookVector
end

function FPSCamera:GetYaw()
    return self.yaw
end

return FPSCamera
