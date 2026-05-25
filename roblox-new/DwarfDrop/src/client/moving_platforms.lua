-- DwarfDrop: moving_platforms.lua
-- Client-side moving platform animation using tags

local RunService = game:GetService("RunService")

local MovingPlatforms = {}
MovingPlatforms.__index = MovingPlatforms

function MovingPlatforms.new()
    local self = setmetatable({}, MovingPlatforms)
    self.platforms  = {}  -- { part, origin, axis, amplitude, speed, phase, weld }
    self.connection = nil
    return self
end

-- Register a part as moving platform
function MovingPlatforms:Register(part)
    local axisTag   = part:FindFirstChild("MoveAxis")
    local ampTag    = part:FindFirstChild("MoveAmplitude")
    local speedTag  = part:FindFirstChild("MoveSpeed")
    local phaseTag  = part:FindFirstChild("MovePhase")

    if not axisTag then return end

    local axis  = axisTag.Value or "Y"
    local amp   = (ampTag  and ampTag.Value)  or 8
    local speed = (speedTag and speedTag.Value) or 1.5
    local phase = (phaseTag and phaseTag.Value) or 0

    local origin = part.Position
    local entry = {
        part      = part,
        origin    = origin,
        axis      = axis,
        amplitude = amp,
        speed     = speed,
        phase     = phase,
    }
    table.insert(self.platforms, entry)
end

-- Scan workspace for tagged moving platforms
function MovingPlatforms:ScanAndRegister()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "MovingPlatform" then
            self:Register(obj)
        end
    end
end

function MovingPlatforms:Start()
    self:ScanAndRegister()
    local t0 = tick()
    self.connection = RunService.Heartbeat:Connect(function()
        local t = tick() - t0
        for _, entry in ipairs(self.platforms) do
            local p = entry.part
            if not p or not p.Parent then continue end
            local offset = math.sin(t * entry.speed * math.pi * 2 + entry.phase) * entry.amplitude
            local newPos = entry.origin
            if entry.axis == "X" then
                newPos = newPos + Vector3.new(offset, 0, 0)
            elseif entry.axis == "Y" then
                newPos = newPos + Vector3.new(0, offset, 0)
            elseif entry.axis == "Z" then
                newPos = newPos + Vector3.new(0, 0, offset)
            end
            p.CFrame = CFrame.new(newPos)
        end
    end)
end

function MovingPlatforms:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.platforms = {}
end

return MovingPlatforms
