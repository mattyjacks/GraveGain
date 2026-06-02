local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CameraController = {}
local GameData

-- State
local state = {
    camera = nil,
    jetSky = nil,
    hull = nil,
    currentOffset = Vector3.new(0, 0, 0),
    targetOffset = Vector3.new(0, 0, 0),
    currentDistance = GameData and GameData.CAMERA_DISTANCE or 20
}

function CameraController:Init(jetSky)
    GameData = require(game:GetService("ReplicatedStorage").Shared.game_data)
    
    state.camera = Workspace.CurrentCamera
    state.jetSky = jetSky
    state.hull = jetSky:WaitForChild("Hull")
    state.currentDistance = GameData.CAMERA_DISTANCE
    
    -- Camera setup
    state.camera.CameraType = Enum.CameraType.Scriptable
    state.camera.FieldOfView = 70
    
    -- Initial position
    local hullPos = state.hull.Position
    local initialOffset = Vector3.new(0, GameData.CAMERA_HEIGHT, -GameData.CAMERA_DISTANCE)
    state.camera.CFrame = CFrame.new(hullPos + initialOffset, hullPos)
    
    print("[CameraController] Initialized")
end

function CameraController:Update(dt, velocity)
    if not state.hull or not state.camera then return end
    
    local hull = state.hull
    local hullCFrame = hull.CFrame
    local hullPos = hull.Position
    
    -- Calculate dynamic distance based on speed
    local speed = velocity and velocity.Magnitude or 0
    local speedFactor = math.clamp(speed / GameData.MAX_SPEED, 0, 1)
    local targetDistance = GameData.CAMERA_DISTANCE + (speedFactor * 10)
    
    -- Smooth distance transition
    state.currentDistance = state.currentDistance + (targetDistance - state.currentDistance) * dt * 2
    
    -- Calculate camera position (behind and above)
    local backVector = -hullCFrame.LookVector
    local upVector = Vector3.new(0, 1, 0)
    
    local cameraOffset = (backVector * state.currentDistance) + (upVector * GameData.CAMERA_HEIGHT)
    local targetPos = hullPos + cameraOffset
    
    -- Smooth camera position
    local currentPos = state.camera.CFrame.Position
    local smoothedPos = currentPos:Lerp(targetPos, math.min(dt * GameData.CAMERA_SMOOTH_SPEED, 1))
    
    -- Look at hull with slight offset for better view
    local lookTarget = hullPos + Vector3.new(0, 5, 0)
    
    -- Apply camera transform
    state.camera.CFrame = CFrame.new(smoothedPos, lookTarget)
end

function CameraController:SetDistance(distance)
    state.currentDistance = math.clamp(distance, GameData.CAMERA_MIN_DISTANCE, GameData.CAMERA_MAX_DISTANCE)
end

function CameraController:Shake(intensity, duration)
    -- Screen shake effect for boosts/collisions
    local startTime = tick()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            connection:Disconnect()
            return
        end
        
        local decay = 1 - (elapsed / duration)
        local shake = Vector3.new(
            math.random(-10, 10) / 10 * intensity * decay,
            math.random(-10, 10) / 10 * intensity * decay,
            math.random(-10, 10) / 10 * intensity * decay
        )
        
        state.camera.CFrame = state.camera.CFrame * CFrame.new(shake)
    end)
end

return CameraController
