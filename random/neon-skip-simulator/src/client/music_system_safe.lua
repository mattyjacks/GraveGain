--[[
    Neon Skip Simulator - Safe Music System
    TOS-Compliant version - no custom audio ID input
    
    COMPLIANCE NOTES:
    - Only plays pre-approved, developer-selected tracks
    - No player audio input (prevents copyright violations)
    - All audio must be uploaded by developer or from Roblox free library
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- Music state
local musicState = {
    currentTrack = nil,
    isPlaying = false,
    baseVolume = 0.3
}

--[[
    SAFE AUDIO SETUP:
    Add your own uploaded audio IDs here.
    To get audio IDs:
    1. Upload audio through Roblox Creator Dashboard
    2. Or use Roblox's free Sound Effects (search in Toolbox)
    3. Copy the asset ID and paste below
    
    DO NOT use random audio IDs from the internet.
]]
local SAFE_TRACKS = {
    -- EXAMPLE (replace with your own):
    -- 123456789, -- Your uploaded track 1
    -- 987654321, -- Your uploaded track 2
}

-- Create background music (only if tracks are configured)
local function createBGM()
    if #SAFE_TRACKS == 0 then
        warn("[Music System] No audio tracks configured. Add your own uploaded audio IDs to SAFE_TRACKS.")
        return nil
    end
    
    local sound = Instance.new("Sound")
    sound.Name = "GameBGM"
    sound.SoundId = "rbxassetid://" .. SAFE_TRACKS[1]
    sound.Volume = musicState.baseVolume
    sound.Looped = true
    sound.Parent = SoundService
    
    musicState.currentTrack = sound
    
    -- Play when ready
    sound.Loaded:Connect(function()
        if musicState.isPlaying then
            sound:Play()
        end
    end)
    
    return sound
end

-- Safe notification (no external assets)
function showNotification(message)
    local playerGui = player:WaitForChild("PlayerGui")
    
    local notif = Instance.new("ScreenGui")
    notif.Name = "Notification"
    notif.Parent = playerGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0.08, 0)
    label.Position = UDim2.new(0.3, 0, 0.2, 0)
    label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    label.BackgroundTransparency = 0.2
    label.Text = message
    label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = notif
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = label
    
    game:GetService("TweenService"):Create(
        label,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 2),
        {TextTransparency = 1, BackgroundTransparency = 1}
    ):Play()
    
    task.delay(3, function()
        notif:Destroy()
    end)
end

-- Initialize
local function initialize()
    createBGM()
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    initialize()
end)

if player.Character then
    initialize()
end

-- Expose
_G.MusicSystem = {
    showNotification = showNotification
}
