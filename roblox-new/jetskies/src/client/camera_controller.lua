local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local CameraController = {}
local GameData

-- Camera state
local state = {
    camera = nil,
    hull   = nil,
    -- Current smoothed camera position
    smoothPos = Vector3.zero,
    -- Current distance (scroll to zoom)
    distance  = 28,
    -- Current FOV
    fov       = 70,
}

local MIN_DIST = 12
local MAX_DIST = 60
local BASE_HEIGHT = 6   -- studs above hull

function CameraController:Init(jetSky)
    GameData = require(game:GetService("ReplicatedStorage").Shared.game_data)
    
    state.camera = Workspace.CurrentCamera
    state.hull   = jetSky:FindFirstChild("HullLower")
               or jetSky:FindFirstChild("Hull")
               or jetSky:FindFirstChildWhichIsA("BasePart")
    state.distance = GameData.CAMERA_DISTANCE or 28
    
    -- Scriptable camera
    state.camera.CameraType = Enum.CameraType.Scriptable
    state.camera.FieldOfView = 70
    
    -- Initialise smooth position
    if state.hull then
        state.smoothPos = state.hull.Position + Vector3.new(0, BASE_HEIGHT, -state.distance)
    end
    
    -- Scroll wheel zooms camera (doesn't conflict - flight throttle uses scroll too,
    -- but we check Ctrl-scroll for camera zoom to avoid conflict)
    UserInputService.InputChanged:Connect(function(inp, processed)
        if processed then return end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            -- Only zoom camera when Ctrl held; otherwise flight controller handles throttle
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                state.distance = math.clamp(
                    state.distance - inp.Position.Z * 3,
                    MIN_DIST, MAX_DIST
                )
            end
        end
    end)
    
    print("[CameraController] Initialized")
end

function CameraController:Update(dt, velocity)
    if not state.hull or not state.camera then return end
    
    local hull    = state.hull
    local hullCF  = hull.CFrame
    local hullPos = hull.Position
    
    -- ---- Dynamic distance based on speed ----
    local speed = velocity and velocity.Magnitude or 0
    local speedFactor = math.clamp(speed / (GameData.MAX_SPEED or 150), 0, 1)
    local targetDist = state.distance + speedFactor * 8
    
    -- ---- Camera target: behind + above hull using hull's own LookVector ----
    -- -LookVector = directly behind the craft, then lift by BASE_HEIGHT in world Y
    local behind = -hullCF.LookVector
    local targetPos = hullPos
        + behind * targetDist
        + Vector3.new(0, BASE_HEIGHT + speedFactor * 3, 0)
    
    -- ---- Smooth chase ----
    local smoothSpeed = GameData.CAMERA_SMOOTH_SPEED or 6
    -- Use a stronger lerp factor so camera keeps up during fast turns
    local alpha = math.min(dt * (smoothSpeed + speedFactor * 4), 1)
    state.smoothPos = state.smoothPos:Lerp(targetPos, alpha)
    
    -- ---- Look target: slightly ahead of hull ----
    local lookTarget = hullPos + hullCF.LookVector * 10 + Vector3.new(0, 2, 0)
    
    -- ---- Dynamic FOV ----
    local targetFOV = 70 + speedFactor * 20  -- 70 at rest, 90 at max speed
    state.fov = state.fov + (targetFOV - state.fov) * dt * 3
    state.camera.FieldOfView = state.fov
    
    -- ---- Apply ----
    state.camera.CFrame = CFrame.new(state.smoothPos, lookTarget)
end

function CameraController:SetDistance(d)
    state.distance = math.clamp(d, MIN_DIST, MAX_DIST)
end

function CameraController:Shake(intensity, duration)
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            connection:Disconnect()
            return
        end
        local decay = 1 - elapsed / duration
        local shake = Vector3.new(
            (math.random() * 2 - 1) * intensity * decay,
            (math.random() * 2 - 1) * intensity * decay,
            (math.random() * 2 - 1) * intensity * decay
        )
        state.camera.CFrame = state.camera.CFrame * CFrame.new(shake)
    end)
end

return CameraController
