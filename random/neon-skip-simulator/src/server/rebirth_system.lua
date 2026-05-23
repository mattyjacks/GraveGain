--[[
    Neon Skip Simulator - Rebirth System (SAFETY VERSION)
    Handles prestige mechanics with rate limiting
    
    SAFETY FEATURES:
    - Rate limiting on rebirth requests
    - Data validation
    - Clear visual feedback only
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.game_config)
local SafetyConfig = require(ReplicatedStorage.Shared.safety_config)

-- Rebirth pad location
local REBIRTH_PAD_POSITION = Vector3.new(-30, 0.5, 0)

-- Rate limiting
local lastRebirthRequest = {}

-- Create rebirth pad
local function createRebirthPad()
    local pad = Instance.new("Part")
    pad.Name = "RebirthPad"
    pad.Size = Vector3.new(10, 1, 10)
    pad.Position = REBIRTH_PAD_POSITION
    pad.Anchored = true
    pad.BrickColor = BrickColor.new("Gold")
    pad.Material = Enum.Material.Neon
    pad.Parent = workspace
    
    -- Glow effect
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(255, 215, 0)
    glow.Brightness = 2
    glow.Range = 20
    glow.Parent = pad
    
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = pad
    billboard.Parent = pad
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⭐ REBIRTH ⭐\nSacrifice Momentum for Power!"
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = billboard
    
    -- Particle effect
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 5, 0)
    attachment.Parent = pad
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 5
    particles.Speed = NumberRange.new(3, 6)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Acceleration = Vector3.new(0, 2, 0)
    particles.Parent = attachment
end

-- Check if player can rebirth
local function canRebirth(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false, 0 end
    
    local momentum = leaderstats.Momentum.Value
    local rebirths = leaderstats.Rebirths.Value
    
    -- Find next rebirth requirement
    local nextTier = nil
    for _, tier in ipairs(GameConfig.REBIRTHS) do
        if rebirths < tier.tier then
            nextTier = tier
            break
        end
    end
    
    if not nextTier then
        return false, 0 -- Max rebirths reached
    end
    
    return momentum >= nextTier.requiredMomentum, nextTier.requiredMomentum
end

-- Perform rebirth
local function doRebirth(player)
    local canDo, required = canRebirth(player)
    if not canDo then
        return false
    end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end
    
    -- Reset momentum
    leaderstats.Momentum.Value = 0
    
    -- Increment rebirth
    leaderstats.Rebirths.Value = leaderstats.Rebirths.Value + 1
    
    -- Notify client
    local remoteEvent = ReplicatedStorage:FindFirstChild("RebirthComplete")
    if remoteEvent then
        remoteEvent:FireClient(player, leaderstats.Rebirths.Value)
    end
    
    -- Visual effect on player
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Explosion effect
            local explosion = Instance.new("Explosion")
            explosion.Position = hrp.Position
            explosion.BlastRadius = 20
            explosion.BlastPressure = 0
            explosion.DestroyJointRadiusPercent = 0
            explosion.Parent = workspace
            
            -- Gold particles
            local attachment = Instance.new("Attachment")
            attachment.Parent = hrp
            
            local particles = Instance.new("ParticleEmitter")
            particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
            particles.Size = NumberSequence.new(1)
            particles.Lifetime = NumberRange.new(2, 3)
            particles.Rate = 50
            particles.Speed = NumberRange.new(20, 40)
            particles.BurstCount = 100
            particles.Parent = attachment
            
            particles:Emit(100)
            
            task.delay(3, function()
                attachment:Destroy()
            end)
        end
    end
    
    return true
end

-- Check players near rebirth pad
local function checkRebirthPad()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if not character then continue end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local distance = (hrp.Position - REBIRTH_PAD_POSITION).Magnitude
        if distance <= 8 then
            -- Player is on pad
            local canDo, required = canRebirth(player)
            if canDo then
                -- Auto-rebirth after 3 seconds on pad
                if not player:GetAttribute("RebirthTimer") then
                    player:SetAttribute("RebirthTimer", tick())
                    
                    -- Notify player
                    local remoteEvent = ReplicatedStorage:FindFirstChild("ShowNotification")
                    if remoteEvent then
                        remoteEvent:FireClient(player, "⭐ Stand still for 3 seconds to REBIRTH! ⭐")
                    end
                elseif tick() - player:GetAttribute("RebirthTimer") >= 3 then
                    -- Do rebirth
                    if doRebirth(player) then
                        player:SetAttribute("RebirthTimer", nil)
                    end
                end
            else
                player:SetAttribute("RebirthTimer", nil)
            end
        else
            player:SetAttribute("RebirthTimer", nil)
        end
    end
end

-- Remote event handler for manual rebirth
local function setupRemoteEvents()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local rebirthEvent = Instance.new("RemoteEvent")
    rebirthEvent.Name = "RequestRebirth"
    rebirthEvent.Parent = ReplicatedStorage
    
    rebirthEvent.OnServerEvent:Connect(function(player)
        -- Rate limiting check
        local now = tick()
        local lastRequest = lastRebirthRequest[player.UserId] or 0
        if now - lastRequest < SafetyConfig.RATE_LIMITS.SHOP_PURCHASE_COOLDOWN then
            return -- Too soon, ignore request
        end
        lastRebirthRequest[player.UserId] = now
        
        local canDo, required = canRebirth(player)
        if canDo then
            doRebirth(player)
        end
    end)
end

-- Initialize
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        player:SetAttribute("RebirthTimer", nil)
    end)
end)

-- Setup
task.wait(2)
createRebirthPad()
setupRemoteEvents()

-- Check loop
while true do
    task.wait(0.5)
    checkRebirthPad()
end
