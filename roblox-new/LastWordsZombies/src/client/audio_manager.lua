-- Audio system for Dead-Letter Drop
-- Manages dark synth soundtrack and sound effects

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local AudioManager = {}

-- Audio storage
AudioManager.BackgroundMusic = nil
AudioManager.SoundEffects = {}
AudioManager.IsPlaying = false

-- Sound IDs - using Roblox built-in rbxasset sounds (always available, no HTTP)
local SOUND_IDS = {
	-- Music tracks (use built-in test sounds as fallback)
	MUSIC_DARK_SYNTH = "rbxasset://sounds/electronicpingloop.wav",
	MUSIC_INDUSTRIAL = "rbxasset://sounds/electronicpingloop.wav",
	MUSIC_TECHNO = "rbxasset://sounds/electronicpingloop.wav",
	MUSIC_AMBIENT = "rbxasset://sounds/electronicpingloop.wav",

	-- Sound effects (Roblox built-in)
	TYPING = "rbxasset://sounds/uuhhh.mp3",
	EXPLOSION = "rbxasset://sounds/collide.mp3",
	ZOMBIE_GROWL = "rbxasset://sounds/uuhhh.mp3",
	WAVE_COMPLETE = "rbxasset://sounds/electronicpingloop.wav",
	GAME_OVER = "rbxasset://sounds/bass.mp3",
	MENU_CLICK = "rbxasset://sounds/electronicpingloop.wav"
}

-- Initialize audio system
function AudioManager.Initialize()
	print("Audio Manager Initialized")
	
	-- Set up sound groups
	SetupSoundGroups()
	
	-- Create background music
	CreateBackgroundMusic()
	
	-- Preload sound effects
	PreloadSoundEffects()
end

-- Set up sound groups for volume control
function SetupSoundGroups()
	-- Create sound groups if they don't exist
	if not SoundService:FindFirstChild("Music") then
		local musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "Music"
		musicGroup.Parent = SoundService
		musicGroup.Volume = GameData.AUDIO.MUSIC_VOLUME
	end
	
	if not SoundService:FindFirstChild("SFX") then
		local sfxGroup = Instance.new("SoundGroup")
		sfxGroup.Name = "SFX"
		sfxGroup.Parent = SoundService
		sfxGroup.Volume = GameData.AUDIO.SFX_VOLUME
	end
end

-- Create background music player
function CreateBackgroundMusic()
	local musicSound = Instance.new("Sound")
	musicSound.Name = "BackgroundMusic"
	musicSound.SoundId = SOUND_IDS.MUSIC_DARK_SYNTH
	musicSound.Looped = true
	musicSound.Volume = 0.7
	musicSound.SoundGroup = SoundService:FindFirstChild("Music")
	musicSound.Parent = SoundService
	
	AudioManager.BackgroundMusic = musicSound
end

-- Preload sound effects
function PreloadSoundEffects()
	local soundNames = {
		"Typing", "Explosion", "ZombieGrowl", "WaveComplete", "GameOver", "MenuClick"
	}
	
	for _, name in ipairs(soundNames) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = SOUND_IDS[name:upper():gsub("([A-Z])", "_%1"):sub(2)]
		sound.Looped = false
		sound.Volume = 0.8
		sound.SoundGroup = SoundService:FindFirstChild("SFX")
		sound.Parent = SoundService
		
		AudioManager.SoundEffects[name] = sound
		
		-- Preload the sound
		sound:Play()
		sound:Pause()
		sound.TimePosition = 0
	end
end

-- Start playing background music
function AudioManager.StartMusic()
	if AudioManager.BackgroundMusic and not AudioManager.IsPlaying then
		AudioManager.BackgroundMusic:Play()
		AudioManager.IsPlaying = true
		print("Background music started")
	end
end

-- Stop background music
function AudioManager.StopMusic()
	if AudioManager.BackgroundMusic and AudioManager.IsPlaying then
		AudioManager.BackgroundMusic:Stop()
		AudioManager.IsPlaying = false
		print("Background music stopped")
	end
end

-- Change music track
function AudioManager.ChangeMusicTrack(trackId)
	local trackInfo = GameData.GetPremiumItem("MUSIC_TRACKS", trackId)
	if not trackInfo then
		trackId = "default"
		trackInfo = GameData.GetPremiumItem("MUSIC_TRACKS", "default")
	end
	
	local soundId = SOUND_IDS["MUSIC_" .. trackId:upper()]
	if soundId then
		if AudioManager.BackgroundMusic then
			local wasPlaying = AudioManager.BackgroundMusic.IsPlaying
			AudioManager.BackgroundMusic:Stop()
			AudioManager.BackgroundMusic.SoundId = soundId
			if wasPlaying then
				AudioManager.BackgroundMusic:Play()
			end
		end
		print("Changed music track to:", trackInfo.name)
	end
end

-- Play sound effect
function AudioManager.PlaySound(soundName, customVolume)
	local sound = AudioManager.SoundEffects[soundName]
	if sound then
		-- Clone the sound to allow multiple instances
		local soundClone = sound:Clone()
		soundClone.Parent = SoundService
		
		if customVolume then
			soundClone.Volume = customVolume
		end
		
		soundClone:Play()
		
		-- Clean up when finished
		soundClone.Ended:Connect(function()
			soundClone:Destroy()
		end)
		
		return soundClone
	end
	return nil
end

-- Play typing sound with variation
function AudioManager.PlayTypingSound()
	-- Add slight pitch variation for more natural typing
	local sound = AudioManager.PlaySound("Typing", 0.3)
	if sound then
		sound.Pitch = 0.9 + math.random() * 0.2 -- 0.9 to 1.1
	end
end

-- Play explosion sound with impact
function AudioManager.PlayExplosionSound()
	local sound = AudioManager.PlaySound("Explosion", 1.0)
	if sound then
		sound.Pitch = 0.8 -- Lower pitch for more impact
	end
end

-- Play zombie growl with variation
function AudioManager.PlayZombieGrowl()
	local sound = AudioManager.PlaySound("ZombieGrowl", 0.6)
	if sound then
		sound.Pitch = 0.8 + math.random() * 0.4 -- 0.8 to 1.2
	end
end

-- Play wave complete sound
function AudioManager.PlayWaveCompleteSound()
	AudioManager.PlaySound("WaveComplete", 0.8)
end

-- Play game over sound
function AudioManager.PlayGameOverSound()
	AudioManager.PlaySound("GameOver", 1.0)
end

-- Play menu click sound
function AudioManager.PlayMenuClickSound()
	AudioManager.PlaySound("MenuClick", 0.5)
end

-- Set music volume
function AudioManager.SetMusicVolume(volume)
	volume = math.max(0, math.min(1, volume))
	
	local musicGroup = SoundService:FindFirstChild("Music")
	if musicGroup then
		musicGroup.Volume = volume
	end
	
	GameData.AUDIO.MUSIC_VOLUME = volume
end

-- Set SFX volume
function AudioManager.SetSFXVolume(volume)
	volume = math.max(0, math.min(1, volume))
	
	local sfxGroup = SoundService:FindFirstChild("SFX")
	if sfxGroup then
		sfxGroup.Volume = volume
	end
	
	GameData.AUDIO.SFX_VOLUME = volume
end

-- Create dynamic audio effects based on gameplay
function AudioManager.CreateDynamicEffects()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	
	-- Distance-based zombie growls
	game:GetService("RunService").Heartbeat:Connect(function()
		if not workspace:FindFirstChild("Zombie") then return end
		
		-- Find closest zombie
		local closestZombie = nil
		local closestDistance = math.huge
		
		for _, zombie in ipairs(workspace.Zombie:GetChildren()) do
			if zombie:IsA("Model") and zombie.PrimaryPart then
				local distance = (character.PrimaryPart.Position - zombie.PrimaryPart.Position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestZombie = zombie
				end
			end
		end
		
		-- Play growl based on distance
		if closestZombie and closestDistance < 30 then
			local volume = 1 - (closestDistance / 30)
			if math.random() < 0.02 then -- 2% chance per frame
				AudioManager.PlayZombieGrowl()
			end
		end
	end)
end

-- Add audio reverb for corridor environment
function AudioManager.SetupCorridorReverb()
	local soundService = game:GetService("SoundService")
	
	-- Create reverb effect for corridor
	soundService.AmbientReverb = Enum.ReverbType.Hall
	soundService.DistanceFactor = 10 -- Sound travels farther in corridor
end

-- Create heartbeat effect when zombies are close
function AudioManager.CreateHeartbeatEffect()
	local heartbeatSound = Instance.new("Sound")
	heartbeatSound.Name = "Heartbeat"
	heartbeatSound.SoundId = "rbxassetid://131961136" -- Use a thumping sound
	heartbeatSound.Looped = true
	heartbeatSound.Volume = 0
	heartbeatSound.SoundGroup = SoundService:FindFirstChild("SFX")
	heartbeatSound.Parent = SoundService
	
	game:GetService("RunService").Heartbeat:Connect(function()
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		
		-- Check for nearby zombies
		local nearbyZombies = 0
		for _, zombie in ipairs(workspace:GetChildren()) do
			if zombie:IsA("Model") and zombie.Name == "Zombie" and zombie.PrimaryPart then
				local distance = (character.PrimaryPart.Position - zombie.PrimaryPart.Position).Magnitude
				if distance < 20 then
					nearbyZombies = nearbyZombies + 1
				end
			end
		end
		
		-- Adjust heartbeat volume based on nearby zombies
		local targetVolume = math.min(0.5, nearbyZombies * 0.1)
		heartbeatSound.Volume = heartbeatSound.Volume + (targetVolume - heartbeatSound.Volume) * 0.1
		
		if targetVolume > 0 and not heartbeatSound.IsPlaying then
			heartbeatSound:Play()
		elseif targetVolume == 0 and heartbeatSound.IsPlaying then
			heartbeatSound:Stop()
		end
	end)
end

-- Initialize all audio systems
function AudioManager.InitializeFull()
	AudioManager.Initialize()
	AudioManager.SetupCorridorReverb()
	AudioManager.CreateDynamicEffects()
	AudioManager.CreateHeartbeatEffect()
end

return AudioManager
