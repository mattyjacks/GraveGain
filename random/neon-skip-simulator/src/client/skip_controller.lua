--[[
    Neon Skip Simulator - Skip Controller (SAFETY VERSION)
    Handles jump rope mechanics with safety caps and rate limiting
    
    SAFETY FEATURES:
    - Rate limiting on skip actions
    - Momentum gain caps
    - Accessibility options (no screen shake)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Shared.game_config)
local SafetyConfig = require(ReplicatedStorage.Shared.safety_config)

-- Player state
local playerState = {
    currentRope = GameConfig.ROPES[1],
    pets = {},
    equippedPet = nil,
    momentumPerSkip = 1,
    isAutoSkip = false,
    lastSkipTime = 0,
    combo = 0,
    lastClickTime = 0
}

-- Visual elements
local character = nil
local humanoid = nil
local humanoidRootPart = nil
local ropeTool = nil
local trail = nil
local aura = nil

-- UI References
local screenGui = nil
local clickButton = nil
local momentumDisplay = nil

-- Initialize
local function initialize()
    -- Wait for character
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Setup UI
    setupUI()
    
    -- Setup tool
    setupRopeTool()
    
    -- Connect inputs
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.TouchTapInWorld:Connect(onTouchTap)
    
    -- Auto-skip check (with safety rate limiting)
    RunService.RenderStepped:Connect(function()
        if playerState.isAutoSkip then
            local currentTime = tick()
            -- Apply auto-skip speed penalty for balance
            local effectiveSpeed = playerState.currentRope.speed * SafetyConfig.AUTO_SKIP.SPEED_PENALTY
            local cooldown = SafetyConfig.RATE_LIMITS.SKIP_ACTION_COOLDOWN / effectiveSpeed
            
            -- Hard cap on skips per second
            local minCooldown = 1 / SafetyConfig.AUTO_SKIP.MAX_SKIPS_PER_SECOND
            if cooldown < minCooldown then
                cooldown = minCooldown
            end
            
            if currentTime - playerState.lastSkipTime >= cooldown then
                performSkip()
            end
        end
    end)
end

function setupUI()
    -- Wait for UI to load
    local playerGui = player:WaitForChild("PlayerGui")
    screenGui = playerGui:WaitForChild("SkipSimulatorUI")
    
    clickButton = screenGui:WaitForChild("ClickButton")
    momentumDisplay = screenGui:WaitForChild("MomentumDisplay")
    
    -- Connect click button
    clickButton.MouseButton1Click:Connect(function()
        performSkip()
    end)
    
    -- Update momentum display
    local leaderstats = player:WaitForChild("leaderstats")
    local momentumStat = leaderstats:WaitForChild("Momentum")
    
    momentumStat.Changed:Connect(function(value)
        momentumDisplay.Text = "🔥 " .. formatNumber(value) .. " MOMENTUM"
    end)
    
    momentumDisplay.Text = "🔥 " .. formatNumber(momentumStat.Value) .. " MOMENTUM"
end

function formatNumber(num)
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

function setupRopeTool()
    -- Create rope tool
    ropeTool = Instance.new("Tool")
    ropeTool.Name = "JumpRope"
    ropeTool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 4, 0.2)
    handle.BrickColor = BrickColor.new(playerState.currentRope.color)
    handle.Material = Enum.Material.Neon
    handle.CanCollide = false
    handle.Parent = ropeTool
    
    ropeTool.Parent = player.Backpack
    
    -- Equip immediately
    humanoid:EquipTool(ropeTool)
end

function updateRopeVisuals()
    if not ropeTool or not ropeTool:FindFirstChild("Handle") then return end
    
    local handle = ropeTool.Handle
    handle.BrickColor = BrickColor.new(playerState.currentRope.color)
    
    -- Add trail if enabled
    if playerState.currentRope.trail then
        if not trail then
            local attachment0 = Instance.new("Attachment")
            attachment0.Position = Vector3.new(0, -2, 0)
            attachment0.Parent = handle
            
            local attachment1 = Instance.new("Attachment")
            attachment1.Position = Vector3.new(0, 2, 0)
            attachment1.Parent = handle
            
            trail = Instance.new("Trail")
            trail.Attachment0 = attachment0
            trail.Attachment1 = attachment1
            trail.Color = ColorSequence.new(playerState.currentRope.color)
            trail.WidthScale = NumberSequence.new(0.5)
            trail.Lifetime = 0.3
            trail.Parent = handle
        end
        trail.Enabled = true
    elseif trail then
        trail.Enabled = false
    end
end

function performSkip()
    local currentTime = tick()
    local cooldown = SafetyConfig.RATE_LIMITS.SKIP_ACTION_COOLDOWN / playerState.currentRope.speed
    
    if currentTime - playerState.lastSkipTime < cooldown then
        return
    end
    
    -- Safety check: cap momentum gain per skip
    if playerState.momentumPerSkip > SafetyConfig.DATA.MAX_MOMENTUM_PER_SKIP then
        playerState.momentumPerSkip = SafetyConfig.DATA.MAX_MOMENTUM_PER_SKIP
    end
    
    playerState.lastSkipTime = currentTime
    
    -- Combo system
    if currentTime - playerState.lastClickTime < 1.5 then
        playerState.combo = math.min(playerState.combo + 1, 50)
    else
        playerState.combo = 0
    end
    playerState.lastClickTime = currentTime
    
    -- Jump animation
    playJumpAnimation()
    
    -- Effects
    spawnEffects()
    playSound()
    
    -- Add momentum
    addMomentum()
    
    -- Show floating text
    showFloatingText()
end

function playJumpAnimation()
    if not humanoid or not humanoidRootPart then return end
    
    -- Simple jump
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    
    -- Custom jump height
    local jumpVelocity = playerState.currentRope.jumpHeight
    humanoidRootPart.Velocity = Vector3.new(0, jumpVelocity, 0)
    
    -- Animate rope
    if ropeTool and ropeTool:FindFirstChild("Handle") then
        local tween = TweenService:Create(
            ropeTool.Handle,
            TweenInfo.new(0.2 / playerState.currentRope.speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Rotation = ropeTool.Handle.Rotation + Vector3.new(0, 360, 0)}
        )
        tween:Play()
    end
end

function spawnEffects()
    if not playerState.currentRope.particles then return end
    if not humanoidRootPart then return end
    
    -- Particle burst
    local particlePart = Instance.new("Part")
    particlePart.Anchored = true
    particlePart.CanCollide = false
    particlePart.Size = Vector3.new(1, 1, 1)
    particlePart.Transparency = 1
    particlePart.Position = humanoidRootPart.Position
    particlePart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = particlePart
    
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Color = ColorSequence.new(playerState.currentRope.particleColor)
    particleEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 0)
    })
    particleEmitter.Lifetime = NumberRange.new(0.3, 0.5)
    particleEmitter.Rate = 0
    particleEmitter.Speed = NumberRange.new(10, 20)
    particleEmitter.SpreadAngle = Vector2.new(180, 180)
    particleEmitter.Acceleration = Vector3.new(0, -50, 0)
    particleEmitter.BurstCount = 8
    particleEmitter.Parent = attachment
    
    -- Emit once
    particleEmitter:Emit(8)
    
    -- Clean up
    task.delay(1, function()
        particlePart:Destroy()
    end)
    
    -- Shockwave effect
    if playerState.currentRope.shockwave then
        spawnShockwave()
    end
    
    -- Aura effect
    if playerState.currentRope.aura then
        updateAura()
    end
end

function spawnShockwave()
    if not humanoidRootPart then return end
    
    local shockwave = Instance.new("Part")
    shockwave.Shape = Enum.PartType.Ball
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Size = Vector3.new(1, 1, 1)
    shockwave.BrickColor = BrickColor.new(playerState.currentRope.particleColor)
    shockwave.Material = Enum.Material.Neon
    shockwave.Position = humanoidRootPart.Position - Vector3.new(0, 3, 0)
    shockwave.Parent = workspace
    
    local tween = TweenService:Create(
        shockwave,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(15, 15, 15), Transparency = 1}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        shockwave:Destroy()
    end)
end

function updateAura()
    if not character then return end
    
    if not aura then
        aura = Instance.new("Part")
        aura.Name = "Aura"
        aura.Shape = Enum.PartType.Ball
        aura.Anchored = false
        aura.CanCollide = false
        aura.Size = Vector3.new(6, 6, 6)
        aura.Transparency = 0.8
        aura.BrickColor = BrickColor.new(playerState.currentRope.particleColor)
        aura.Material = Enum.Material.ForceField
        
        local weld = Instance.new("Weld")
        weld.Part0 = character:WaitForChild("HumanoidRootPart")
        weld.Part1 = aura
        weld.Parent = aura
        
        aura.Parent = character
    end
    
    aura.BrickColor = BrickColor.new(playerState.currentRope.particleColor)
end

function playSound()
    -- Skip if no audio configured (nil check for TOS compliance)
    if not GameConfig.AUDIO.jumpSound then
        return
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = GameConfig.AUDIO.jumpSound
    sound.Volume = 0.5
    sound.Parent = humanoidRootPart or workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function addMomentum()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local momentumStat = leaderstats:FindFirstChild("Momentum")
    if not momentumStat then return end
    
    -- Calculate gain with multipliers
    local gain = playerState.momentumPerSkip
    
    -- Pet multiplier
    if playerState.equippedPet then
        gain = gain * playerState.equippedPet.multiplier
    end
    
    -- Rebirth multiplier
    local rebirthStat = leaderstats:FindFirstChild("Rebirths")
    if rebirthStat then
        local rebirths = rebirthStat.Value
        if rebirths > 0 then
            -- Find rebirth tier
            for i = #GameConfig.REBIRTHS, 1, -1 do
                if rebirths >= GameConfig.REBIRTHS[i].tier then
                    gain = gain * GameConfig.REBIRTHS[i].multiplier
                    break
                end
            end
        end
    end
    
    -- Combo multiplier (max 2x at 50 combo)
    local comboMultiplier = 1 + (playerState.combo / 50)
    gain = math.floor(gain * comboMultiplier)
    
    -- x2 Gamepass check (would check actual ownership)
    -- if hasGamepass then gain = gain * 2 end
    
    momentumStat.Value = momentumStat.Value + gain
end

function showFloatingText()
    if not humanoidRootPart then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.Adornee = humanoidRootPart
    billboard.Parent = workspace
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "+" .. tostring(playerState.momentumPerSkip) .. " MOMENTUM"
    label.TextColor3 = playerState.currentRope.color
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    -- Combo indicator
    if playerState.combo > 5 then
        label.Text = label.Text .. "\n🔥 x" .. tostring(playerState.combo)
    end
    
    -- Animate up and fade
    local startPos = billboard.StudsOffset
    
    local tweenUp = TweenService:Create(
        billboard,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {StudsOffset = startPos + Vector3.new(0, 3, 0)}
    )
    
    local fadeTween = TweenService:Create(
        label,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.5),
        {TextTransparency = 1}
    )
    
    tweenUp:Play()
    fadeTween:Play()
    
    fadeTween.Completed:Connect(function()
        billboard:Destroy()
    end)
end

function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    -- Mouse button or touch
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        performSkip()
    end
end

function onTouchTap(position, gameProcessed)
    if gameProcessed then return end
    performSkip()
end

-- Upgrade rope function (called from shop)
function upgradeRope(ropeIndex)
    if ropeIndex < 1 or ropeIndex > #GameConfig.ROPES then return end
    
    playerState.currentRope = GameConfig.ROPES[ropeIndex]
    updateRopeVisuals()
    
    -- Update momentum per skip based on rope
    playerState.momentumPerSkip = ropeIndex
end

-- Equip pet function
function equipPet(petId)
    for _, pet in ipairs(GameConfig.PETS) do
        if pet.id == petId then
            playerState.equippedPet = pet
            spawnPetVisual(pet)
            break
        end
    end
end

function spawnPetVisual(pet)
    if not character then return end
    
    -- Remove old pet
    local oldPet = character:FindFirstChild("EquippedPet")
    if oldPet then
        oldPet:Destroy()
    end
    
    -- Create pet orb
    local petPart = Instance.new("Part")
    petPart.Name = "EquippedPet"
    petPart.Shape = Enum.PartType.Ball
    petPart.Size = Vector3.new(1, 1, 1)
    petPart.BrickColor = BrickColor.new(pet.color)
    petPart.Material = Enum.Material.Neon
    petPart.CanCollide = false
    petPart.Parent = character
    
    -- Orbit animation
    local attachment = Instance.new("Attachment")
    attachment.Parent = character:WaitForChild("HumanoidRootPart")
    
    local petAttachment = Instance.new("Attachment")
    petAttachment.Parent = petPart
    
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Attachment0 = petAttachment
    alignPosition.Attachment1 = attachment
    alignPosition.RigidityEnabled = false
    alignPosition.MaxVelocity = 10
    alignPosition.Parent = petPart
    
    local orbitConnection
    local angle = 0
    orbitConnection = RunService.RenderStepped:Connect(function()
        if not petPart or not petPart.Parent then
            orbitConnection:Disconnect()
            return
        end
        angle = angle + 0.05
        attachment.Position = Vector3.new(math.cos(angle) * 4, 2, math.sin(angle) * 4)
    end)
end

-- Auto-skip toggle (with safety limits)
function setAutoSkip(enabled)
    playerState.isAutoSkip = enabled
    
    if enabled then
        -- Show accessibility warning
        warn("[Safety] Auto-Skip enabled. This feature is for accessibility and has built-in rate limits.")
    end
end

-- Initialize when character spawns
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    initialize()
end)

if player.Character then
    initialize()
end

-- Expose functions for shop
_G.SkipController = {
    upgradeRope = upgradeRope,
    equipPet = equipPet,
    setAutoSkip = setAutoSkip,
    getState = function() return playerState end
}
