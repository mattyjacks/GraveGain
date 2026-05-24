-- DropDwarf: fps_camera.lua
-- First-person camera with mouse look

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FPSCamera = {}
FPSCamera.__index = FPSCamera

local MOUSE_SENSITIVITY = 0.003
local VERTICAL_CLAMP = 80 -- degrees

local TPS_GHOST_ALPHA = 0.7  -- transparency of occluding parts in TPS mode

function FPSCamera.new()
    local self = setmetatable({}, FPSCamera)
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    self.yaw = 0
    self.pitch = 0
    self.active = false
    self.isDead = false    -- true while death screen is showing
    self.dropType = "fps"  -- "fps" or "tps"
    self.connection = nil
    self.tpsGhosted = {}   -- { [part] = originalTransparency } for TPS occlusion restore
    
    -- Volumetric physical shakes
    self.shakeTime = 0
    self.shakeDuration = 0
    self.shakeMagnitude = 0
    self.shakeSpeed = 25
    return self
end

function FPSCamera:GetCharacter()
    return self.player.Character
end

function FPSCamera:GetHead()
    local char = self:GetCharacter()
    if not char then return nil end
    return char:FindFirstChild("Head")
end

function FPSCamera:GetHRP()
    local char = self:GetCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Hide all character BaseParts for first-person view
local function hideCharacter(char)
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
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
    local char = self:GetCharacter()
    hideCharacter(char)
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    self.camera.CameraType = Enum.CameraType.Scriptable
end

function FPSCamera:RestoreFirstPerson()
    local char = self:GetCharacter()
    showCharacter(char)
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    self.camera.CameraType = Enum.CameraType.Custom
end

function FPSCamera:Start(dropType)
    if self.active then
        self:Stop()
    end
    self.active = true
    self.dropType = dropType or "fps"

    if self.dropType == "fps" then
        self:SetupFirstPerson()
        self.connection = RunService.RenderStepped:Connect(function()
            self:UpdateFPS()
        end)
    else
        -- TPS: use Roblox default camera with occlusion ghosting
        local char = self:GetCharacter()
        showCharacter(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        self.camera.CameraType = Enum.CameraType.Custom
        if hum then self.camera.CameraSubject = hum end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        self.connection = RunService.RenderStepped:Connect(function()
            self:UpdateTPS()
        end)
    end
end

function FPSCamera:Stop()
    self.active = false
    self.isDead = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    -- Restore any ghosted TPS parts
    for part, origTrans in pairs(self.tpsGhosted) do
        if part and part.Parent then
            part.LocalTransparencyModifier = origTrans
        end
    end
    self.tpsGhosted = {}
    self:RestoreFirstPerson()
end

-- Call when the death screen appears: unlock mouse for button clicks but keep look active
function FPSCamera:EnterDeathView()
    self.isDead = true
    UserInputService.MouseBehavior  = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

-- Call when the player respawns back into the level (not hub)
function FPSCamera:LeaveDeathView()
    self.isDead = false
    if self.active and self.dropType == "fps" then
        UserInputService.MouseBehavior  = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end

-- Hook dynamic noise shake
function FPSCamera:ApplyShake(magnitude, duration, speed)
    self.shakeMagnitude = magnitude or 1.5
    self.shakeDuration  = duration or 0.4
    self.shakeSpeed     = speed or 25
    self.shakeTime      = self.shakeDuration
end

function FPSCamera:UpdateFPS()
    local head = self:GetHead()
    local hrp = self:GetHRP()
    if not head or not hrp then return end

    if self.isDead then
        -- Death view: keep mouse free every frame so nothing can re-lock it
        UserInputService.MouseBehavior  = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        -- Still render camera at current yaw/pitch so the view doesn't snap
        local camCF = CFrame.new(head.Position)
            * CFrame.Angles(0, self.yaw, 0)
            * CFrame.Angles(self.pitch, 0, 0)
        self.camera.CFrame = camCF
        return
    end

    -- Only consume mouse delta when mouse is locked (live gameplay)
    local delta = UserInputService:GetMouseDelta()
    self.yaw   = self.yaw   - delta.X * MOUSE_SENSITIVITY
    self.pitch = self.pitch - delta.Y * MOUSE_SENSITIVITY
    self.pitch = math.clamp(self.pitch, math.rad(-VERTICAL_CLAMP), math.rad(VERTICAL_CLAMP))

    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, self.yaw, 0)

    local camCF = CFrame.new(head.Position)
        * CFrame.Angles(0, self.yaw, 0)
        * CFrame.Angles(self.pitch, 0, 0)

    -- Apply physical camera shake calculations via Perlin Noise
    if self.shakeTime > 0 then
        self.shakeTime = math.max(0, self.shakeTime - 0.016)
        local ratio = self.shakeTime / self.shakeDuration
        local t = tick() * self.shakeSpeed
        local shakeX = math.noise(t, 17, 34) * self.shakeMagnitude * ratio
        local shakeY = math.noise(t, 29, 88) * self.shakeMagnitude * ratio
        local shakeZ = math.noise(t, 93, 14) * self.shakeMagnitude * ratio
        
        camCF = camCF * CFrame.new(shakeX * 0.12, shakeY * 0.12, 0)
                      * CFrame.Angles(shakeY * 0.024, shakeX * 0.024, shakeZ * 0.018)
    end

    self.camera.CFrame = camCF

    hideCharacter(self:GetCharacter())
end

function FPSCamera:Update()
    -- Legacy alias
    self:UpdateFPS()
end

function FPSCamera:UpdateTPS()
    local hrp = self:GetHRP()
    if not hrp then return end

    local camPos = self.camera.CFrame.Position
    local charPos = hrp.Position
    local dir = charPos - camPos
    local dist = dir.Magnitude
    if dist < 0.1 then return end

    -- Raycast from camera toward character to find occluding parts
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local char = self:GetCharacter()
    rp.FilterDescendantsInstances = char and { char } or {}

    -- Track which parts are currently occluding
    local nowGhosted = {}
    local origin = camPos
    local remaining = dist
    -- Step along ray checking for parts
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
            -- Continue ray past this part
            local newOrigin = result.Position + dir.Unit * 0.1
            remaining = (charPos - newOrigin).Magnitude
            origin = newOrigin
        else
            break
        end
    end

    -- Restore parts no longer occluding
    for part, origTrans in pairs(self.tpsGhosted) do
        if not nowGhosted[part] then
            if part and part.Parent then
                part.LocalTransparencyModifier = origTrans
            end
            self.tpsGhosted[part] = nil
        end
    end
end

-- Get current look direction as unit vector
function FPSCamera:GetLookVector()
    return self.camera.CFrame.LookVector
end

-- Get yaw in radians
function FPSCamera:GetYaw()
    return self.yaw
end

return FPSCamera
