-- DropDwarf: active_item/throw_preview.lua
-- Simulates and renders projectile flight path previews using parabolic curves.

local ItemData = require(game.ReplicatedStorage.Shared.item_data)
local player   = game:GetService("Players").LocalPlayer

local ThrowPreview = {}

local ARC_STEPS   = 20   -- number of dots along the arc
local ARC_STEP_DT = 0.06 -- time step per dot (seconds)
local DOT_SIZE    = Vector3.new(0.22, 0.22, 0.22)

function ThrowPreview.Clear(controller)
    for _, dot in ipairs(controller.arcDots or {}) do
        if dot and dot.Parent then dot:Destroy() end
    end
    controller.arcDots = {}
end

function ThrowPreview.Update(controller)
    local def = controller.itemId and ItemData.Items[controller.itemId]
    if not def or def.useType ~= "throw" then
        ThrowPreview.Clear(controller)
        return
    end

    local cam  = workspace.CurrentCamera
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        ThrowPreview.Clear(controller)
        return 
    end

    -- Throw origin: camera look direction
    local origin = cam.CFrame.Position
    local dir    = cam.CFrame.LookVector.Unit
    local vel    = dir * def.throwSpeed
    local grav   = Vector3.new(0, -def.gravity, 0)

    -- Ensure we have exactly ARC_STEPS dots
    controller.arcDots = controller.arcDots or {}
    while #controller.arcDots < ARC_STEPS do
        local dot = Instance.new("Part")
        dot.Name         = "ArcDot"
        dot.Size         = DOT_SIZE
        dot.Shape        = Enum.PartType.Ball
        dot.Anchored     = true
        dot.CanCollide   = false
        dot.CastShadow   = false
        dot.Material     = Enum.Material.Neon
        dot.Color        = def.color
        dot.Transparency = 0.3
        dot.Parent       = workspace
        table.insert(controller.arcDots, dot)
    end
    
    while #controller.arcDots > ARC_STEPS do
        local removed = table.remove(controller.arcDots)
        if removed and removed.Parent then removed:Destroy() end
    end

    -- Recolor dots to match current item
    for _, dot in ipairs(controller.arcDots) do
        dot.Color = def.color
    end

    -- Simulate arc positions
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = { char }

    local pos = origin
    local v   = vel
    for i, dot in ipairs(controller.arcDots) do
        local nextPos = pos + v * ARC_STEP_DT + grav * (0.5 * ARC_STEP_DT * ARC_STEP_DT)
        local nextV   = v + grav * ARC_STEP_DT
        
        -- Fade opacity toward end of arc
        dot.Transparency = 0.2 + (i / ARC_STEPS) * 0.65
        dot.Position = pos
        
        -- Stop drawing if arc hits terrain
        local ray = workspace:Raycast(pos, nextPos - pos, rp)
        if ray then
            -- Snap remaining dots to impact point
            for j = i, ARC_STEPS do
                if controller.arcDots[j] then
                    controller.arcDots[j].Position = ray.Position
                    controller.arcDots[j].Transparency = 0.7
                end
            end
            break
        end
        pos = nextPos
        v   = nextV
    end
end

return ThrowPreview
