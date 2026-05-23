--[[
    Neon Skip Simulator - Shop UI (SAFETY VERSION)
    Handles rope upgrades and pet purchases with rate limiting
    
    SAFETY FEATURES:
    - Rate limiting on purchases
    - Data validation
    - Clear purchase feedback
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Shared.game_config)
local SafetyConfig = require(ReplicatedStorage.Shared.safety_config)

-- UI Elements
local shopGui = nil
local ropeFrame = nil
local petFrame = nil
local momentumDisplay = nil
local closeButton = nil
local tabButtons = {}

-- State
local currentTab = "ropes"
local unlockedRopes = {1}
local purchasedPets = {}
local lastPurchaseTime = 0 -- Rate limiting

function initializeShop()
    local playerGui = player:WaitForChild("PlayerGui")
    shopGui = playerGui:WaitForChild("ShopUI")
    
    -- Hide initially
    shopGui.Enabled = false
    
    -- Get references
    ropeFrame = shopGui:WaitForChild("RopeFrame")
    petFrame = shopGui:WaitForChild("PetFrame")
    momentumDisplay = shopGui:WaitForChild("MomentumDisplay")
    closeButton = shopGui:WaitForChild("CloseButton")
    
    tabButtons.robes = shopGui:WaitForChild("RopesTab")
    tabButtons.pets = shopGui:WaitForChild("PetsTab")
    
    -- Connect buttons
    closeButton.MouseButton1Click:Connect(closeShop)
    tabButtons.robes.MouseButton1Click:Connect(function() switchTab("ropes") end)
    tabButtons.pets.MouseButton1Click:Connect(function() switchTab("pets") end)
    
    -- Setup content
    setupRopeButtons()
    setupPetButtons()
    
    -- Update momentum display
    local leaderstats = player:WaitForChild("leaderstats")
    local momentumStat = leaderstats:WaitForChild("Momentum")
    
    momentumStat.Changed:Connect(function(value)
        momentumDisplay.Text = "💰 " .. formatNumber(value) .. " MOMENTUM"
        updateButtonStates()
    end)
    
    momentumDisplay.Text = "💰 " .. formatNumber(momentumStat.Value) .. " MOMENTUM"
    
    -- Open shop on keypress
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.E then
            toggleShop()
        end
    end)
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

function setupRopeButtons()
    local template = ropeFrame:WaitForChild("Template")
    template.Visible = false
    
    for i, rope in ipairs(GameConfig.ROPES) do
        local button = template:Clone()
        button.Name = "Rope_" .. rope.id
        button.Visible = true
        button.Parent = ropeFrame
        
        -- Set properties
        button:WaitForChild("NameLabel").Text = rope.name
        button:WaitForChild("CostLabel").Text = rope.cost == 0 and "FREE" or formatNumber(rope.cost) .. " 💰"
        button:WaitForChild("SpeedLabel").Text = "⚡ " .. tostring(rope.speed) .. "x Speed"
        button:WaitForChild("HeightLabel").Text = "⬆️ " .. tostring(rope.jumpHeight) .. " Height"
        
        -- Set color preview
        button:WaitForChild("ColorPreview").BackgroundColor3 = rope.color
        
        -- Position
        button.Position = UDim2.new(0, 10, 0, 10 + ((i - 1) * 70))
        
        -- Click handler
        button.MouseButton1Click:Connect(function()
            purchaseRope(i)
        end)
    end
    
    -- Update canvas size
    ropeFrame.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.ROPES * 70 + 20)
end

function setupPetButtons()
    local template = petFrame:WaitForChild("Template")
    template.Visible = false
    
    for i, pet in ipairs(GameConfig.PETS) do
        local button = template:Clone()
        button.Name = "Pet_" .. pet.id
        button.Visible = true
        button.Parent = petFrame
        
        -- Set properties
        button:WaitForChild("NameLabel").Text = pet.name
        button:WaitForChild("RarityLabel").Text = pet.rarity
        button:WaitForChild("RarityLabel").TextColor3 = getRarityColor(pet.rarity)
        button:WaitForChild("CostLabel").Text = formatNumber(pet.cost) .. " 💰"
        button:WaitForChild("MultiplierLabel").Text = "✨ " .. tostring(pet.multiplier) .. "x Multiplier"
        
        -- Color preview
        button:WaitForChild("ColorPreview").BackgroundColor3 = pet.color
        
        -- Position
        button.Position = UDim2.new(0, 10, 0, 10 + ((i - 1) * 80))
        
        -- Click handler
        button.MouseButton1Click:Connect(function()
            purchasePet(pet.id)
        end)
    end
    
    petFrame.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.PETS * 80 + 20)
end

function getRarityColor(rarity)
    local colors = {
        Common = Color3.fromRGB(200, 200, 200),
        Uncommon = Color3.fromRGB(0, 255, 0),
        Rare = Color3.fromRGB(0, 100, 255),
        Epic = Color3.fromRGB(150, 0, 255),
        Legendary = Color3.fromRGB(255, 200, 0)
    }
    return colors[rarity] or Color3.fromRGB(255, 255, 255)
end

function switchTab(tab)
    currentTab = tab
    
    if tab == "ropes" then
        ropeFrame.Visible = true
        petFrame.Visible = false
        tabButtons.robes.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        tabButtons.pets.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    else
        ropeFrame.Visible = false
        petFrame.Visible = true
        tabButtons.robes.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabButtons.pets.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
    end
    
    playClickSound()
end

function updateButtonStates()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local momentum = leaderstats.Momentum.Value
    
    -- Update rope buttons
    for i, rope in ipairs(GameConfig.ROPES) do
        local button = ropeFrame:FindFirstChild("Rope_" .. rope.id)
        if button then
            local canAfford = momentum >= rope.cost
            local owned = table.find(unlockedRopes, i) ~= nil
            
            if owned then
                button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                button:WaitForChild("StatusLabel").Text = "✓ OWNED"
            elseif canAfford then
                button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                button:WaitForChild("StatusLabel").Text = "Click to Buy!"
            else
                button.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                button:WaitForChild("StatusLabel").Text = "Too Expensive"
            end
        end
    end
    
    -- Update pet buttons
    for _, pet in ipairs(GameConfig.PETS) do
        local button = petFrame:FindFirstChild("Pet_" .. pet.id)
        if button then
            local canAfford = momentum >= pet.cost
            local owned = table.find(purchasedPets, pet.id) ~= nil
            
            if owned then
                button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                button:WaitForChild("StatusLabel").Text = "✓ OWNED"
            elseif canAfford then
                button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                button:WaitForChild("StatusLabel").Text = "Click to Buy!"
            else
                button.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                button:WaitForChild("StatusLabel").Text = "Too Expensive"
            end
        end
    end
end

function purchaseRope(ropeIndex)
    -- Rate limiting check
    local currentTime = tick()
    if currentTime - lastPurchaseTime < SafetyConfig.RATE_LIMITS.SHOP_PURCHASE_COOLDOWN then
        return -- Too soon
    end
    lastPurchaseTime = currentTime
    
    local rope = GameConfig.ROPES[ropeIndex]
    if not rope then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local momentumStat = leaderstats.Momentum
    
    -- Check if already owned
    if table.find(unlockedRopes, ropeIndex) then
        -- Just equip
        if _G.SkipController then
            _G.SkipController.upgradeRope(ropeIndex)
        end
        playEquipSound()
        return
    end
    
    -- Check cost
    if momentumStat.Value < rope.cost then
        -- Not enough money
        shakeButton(ropeFrame:FindFirstChild("Rope_" .. rope.id))
        return
    end
    
    -- Deduct and unlock
    momentumStat.Value = momentumStat.Value - rope.cost
    table.insert(unlockedRopes, ropeIndex)
    
    -- Equip
    if _G.SkipController then
        _G.SkipController.upgradeRope(ropeIndex)
    end
    
    playPurchaseSound()
    updateButtonStates()
    
    -- Flash success
    showPurchaseFlash("🎉 Unlocked " .. rope.name .. "!")
end

function purchasePet(petId)
    -- Rate limiting check
    local currentTime = tick()
    if currentTime - lastPurchaseTime < SafetyConfig.RATE_LIMITS.SHOP_PURCHASE_COOLDOWN then
        return -- Too soon
    end
    lastPurchaseTime = currentTime
    
    local pet = nil
    for _, p in ipairs(GameConfig.PETS) do
        if p.id == petId then
            pet = p
            break
        end
    end
    if not pet then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local momentumStat = leaderstats.Momentum
    
    -- Check if already owned
    if table.find(purchasedPets, petId) then
        -- Just equip
        if _G.SkipController then
            _G.SkipController.equipPet(petId)
        end
        playEquipSound()
        return
    end
    
    -- Check cost
    if momentumStat.Value < pet.cost then
        shakeButton(petFrame:FindFirstChild("Pet_" .. petId))
        return
    end
    
    -- Deduct and unlock
    momentumStat.Value = momentumStat.Value - pet.cost
    table.insert(purchasedPets, petId)
    
    -- Equip
    if _G.SkipController then
        _G.SkipController.equipPet(petId)
    end
    
    playPurchaseSound()
    updateButtonStates()
    
    showPurchaseFlash("🎉 Acquired " .. pet.name .. "!")
end

function shakeButton(button)
    if not button then return end
    
    local originalPos = button.Position
    local tween = TweenService:Create(
        button,
        TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 4, true),
        {Position = originalPos + UDim2.new(0, 5, 0, 0)}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        button.Position = originalPos
    end)
end

function showPurchaseFlash(message)
    local flash = Instance.new("ScreenGui")
    flash.Name = "PurchaseFlash"
    flash.Parent = player:WaitForChild("PlayerGui")
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0.1, 0)
    label.Position = UDim2.new(0.1, 0, 0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = flash
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 3
    stroke.Parent = label
    
    local tween = TweenService:Create(
        label,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.1, 0, 0.3, 0), TextTransparency = 1}
    )
    
    task.wait(1)
    tween:Play()
    
    tween.Completed:Connect(function()
        flash:Destroy()
    end)
end

function playClickSound()
    -- TOS compliant - skip if no audio configured
    if not GameConfig.AUDIO.clickSound then
        return
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = GameConfig.AUDIO.clickSound
    sound.Volume = 0.3
    sound.Parent = SoundService
    sound:Play()
    task.delay(0.5, function() sound:Destroy() end)
end

function playPurchaseSound()
    -- TOS compliant - skip if no audio configured
    if not GameConfig.AUDIO.upgradeSound then
        return
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = GameConfig.AUDIO.upgradeSound
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    task.delay(2, function() sound:Destroy() end)
end

function playEquipSound()
    -- TOS compliant - skip if no audio configured
    -- Uses clickSound as fallback (set in game_config)
    local soundId = GameConfig.AUDIO.clickSound
    if not soundId then
        return
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.4
    sound.Parent = SoundService
    sound:Play()
    task.delay(1, function() sound:Destroy() end)
end

function toggleShop()
    shopGui.Enabled = not shopGui.Enabled
    
    if shopGui.Enabled then
        updateButtonStates()
        playOpenSound()
    end
end

function openShop()
    shopGui.Enabled = true
    updateButtonStates()
    playOpenSound()
end

function closeShop()
    shopGui.Enabled = false
    playClickSound()
end

function playOpenSound()
    -- TOS compliant - skip if no audio configured
    local soundId = GameConfig.AUDIO.upgradeSound or GameConfig.AUDIO.clickSound
    if not soundId then
        return
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.4
    sound.Parent = SoundService
    sound:Play()
    task.delay(1, function() sound:Destroy() end)
end

-- Initialize
player.CharacterAdded:Connect(function()
    task.wait(1)
    initializeShop()
end)

if player.Character then
    initializeShop()
end

-- Expose for other scripts
_G.ShopUI = {
    open = openShop,
    close = closeShop,
    toggle = toggleShop
}
