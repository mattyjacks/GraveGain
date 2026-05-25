-- DropDwarf: moving_platforms.lua
-- Client-side animation of moving platforms.
-- Reads MovePlatform StringValue tags written by level_generator.lua.
-- Moves each platform in a ping-pong arc along its configured axis.

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local MovingPlatforms = {}
MovingPlatforms.__index = MovingPlatforms

-- Parse "axis,speed,range,startX,startY,startZ" from StringValue
local function parseCfg(val)
    local axis, speed, range, sx, sy, sz =
        val:match("(%a+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)")
    if not axis then return nil end
    return {
        axis  = axis,
        speed = tonumber(speed),
        range = tonumber(range),
        startX = tonumber(sx),
        startY = tonumber(sy),
        startZ = tonumber(sz),
    }
end

function MovingPlatforms.new()
    local self = setmetatable({}, MovingPlatforms)
    self.platforms = {} -- { part, cfg, phase }
    self.connection = nil
    return self
end

-- Scan the level folder for all MovingPlatform parts and register them
function MovingPlatforms:Load(levelFolder)
    self.platforms = {}
    if not levelFolder then return end

    for _, desc in ipairs(levelFolder:GetDescendants()) do
        if desc.Name == "MovingPlatform" and desc:IsA("BasePart") then
            local tag = desc:FindFirstChild("MovePlatform")
            if tag then
                local cfg = parseCfg(tag.Value)
                if cfg then
                    table.insert(self.platforms, {
                        part  = desc,
                        cfg   = cfg,
                        phase = math.random() * math.pi * 2, -- random start phase per platform
                    })
                end
            end
        end
    end
end

function MovingPlatforms:Start()
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function MovingPlatforms:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.platforms = {}
end

function MovingPlatforms:Update(dt)
    local now = tick()

    -- Get local player HRP once per frame
    local localPlayer = Players.LocalPlayer
    local char = localPlayer and localPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    for _, entry in ipairs(self.platforms) do
        local part = entry.part
        if not part or not part.Parent then continue end
        local cfg = entry.cfg

        -- Sinusoidal ping-pong: offset = sin(phase + t*speed) * range/2
        local t   = now
        local off = math.sin(entry.phase + t * cfg.speed * 0.5) * (cfg.range / 2)

        local nx = cfg.startX + (cfg.axis == "X" and off or 0)
        local ny = cfg.startY
        local nz = cfg.startZ + (cfg.axis == "Z" and off or 0)

        local oldPos = part.Position
        local newPos = Vector3.new(nx, ny, nz)
        local delta  = newPos - oldPos

        -- If player is standing on this platform, carry them with it
        -- instead of letting the physics solver eject them
        if hrp and hum and delta.Magnitude > 0 then
            local onGround = hum.FloorMaterial ~= Enum.Material.Air
            if onGround then
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = { char }
                local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), rp)
                if ray and ray.Instance == part then
                    -- Carry player with platform (horizontal only; vertical handled by physics)
                    hrp.CFrame = hrp.CFrame + Vector3.new(delta.X, 0, delta.Z)
                end
            end
        end

        part.CFrame = CFrame.new(nx, ny, nz)
    end
end

return MovingPlatforms
