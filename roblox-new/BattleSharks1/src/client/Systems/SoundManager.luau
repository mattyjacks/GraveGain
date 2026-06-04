-- BattleSharks Sound Manager (D2)
-- Centralized audio system for SFX and music

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("Constants"):WaitForChild("GameConstants"))
local GameUtilities = require(Shared:WaitForChild("Utilities"):WaitForChild("GameUtilities"))

local SoundManager = {}

-- PRIVATE VARIABLES
local soundsFolder = nil
local musicFolder = nil
local activeMusic = nil
local soundPool = {}
local maxPoolSize = 20

-- SOUND CONFIGURATION
local SOUND_CONFIG = {
	MasterVolume = GameConstants.MASTER_VOLUME or 0.8,
	SFXVolume = GameConstants.SFX_VOLUME or 0.7,
	MusicVolume = GameConstants.MUSIC_VOLUME or 0.5,
	MaxConcurrentSounds = 10,
	FadeTime = 1.0
}

-- SOUND ASSETS (placeholders - replace with actual asset IDs)
local SOUND_ASSETS = {
	-- Combat
	Bite = "rbxassetid://123456",
	AttackHit = "rbxassetid://123457",
	DamageTaken = "rbxassetid://123458",
	Death = "rbxassetid://123459",
	
	-- Movement
	Swim = "rbxassetid://123460",
	Boost = "rbxassetid://123461",
	WaterSplash = "rbxassetid://123462",
	Leap = "rbxassetid://123463",
	
	-- UI
	ButtonClick = "rbxassetid://123464",
	Hover = "rbxassetid://123465",
	Error = "rbxassetid://123466",
	Success = "rbxassetid://123467",
	LevelUp = "rbxassetid://123468",
	
	-- Environment
	UnderwaterAmbience = "rbxassetid://123469",
	SurfaceAmbience = "rbxassetid://123470",
	
	-- Music
	MainTheme = "rbxassetid://123471",
	BattleMusic = "rbxassetid://123472",
	AquariumMusic = "rbxassetid://123473"
}

-- INITIALIZATION
function SoundManager.Initialize()
	GameUtilities.DebugPrint("SoundManager: Initializing")
	
	-- Create folders
	soundsFolder = Instance.new("Folder")
	soundsFolder.Name = "BattleSharksSFX"
	soundsFolder.Parent = SoundService
	
	musicFolder = Instance.new("Folder")
	musicFolder.Name = "BattleSharksMusic"
	musicFolder.Parent = SoundService
	
	-- Initialize sound pool
	SoundManager.InitializeSoundPool()
	
	-- Set initial volumes
	SoundManager.SetVolumes()
	
	-- Start ambient sounds
	SoundManager.StartAmbientSounds()
	
	GameUtilities.DebugPrint("SoundManager: Initialized")
end

function SoundManager.InitializeSoundPool()
	for i = 1, maxPoolSize do
		local sound = Instance.new("Sound")
		sound.Parent = soundsFolder
		sound.PoolId = i
		sound.Playing = false
		table.insert(soundPool, sound)
	end
end

function SoundManager.GetPooledSound()
	for _, sound in pairs(soundPool) do
		if not sound.Playing then
			return sound
		end
	end
	
	-- Create new if pool exhausted
	local newSound = Instance.new("Sound")
	newSound.Parent = soundsFolder
	return newSound
end

-- VOLUME CONTROL
function SoundManager.SetVolumes()
	SoundService.MasterVolume = SOUND_CONFIG.MasterVolume
end

function SoundManager.SetMasterVolume(volume)
	SOUND_CONFIG.MasterVolume = math.clamp(volume, 0, 1)
	SoundService.MasterVolume = SOUND_CONFIG.MasterVolume
end

function SoundManager.SetSFXVolume(volume)
	SOUND_CONFIG.SFXVolume = math.clamp(volume, 0, 1)
end

function SoundManager.SetMusicVolume(volume)
	SOUND_CONFIG.MusicVolume = math.clamp(volume, 0, 1)
	if activeMusic then
		activeMusic.Volume = SOUND_CONFIG.MusicVolume
	end
end

-- SOUND PLAYING
function SoundManager.PlaySFX(soundName, position, pitch)
	local assetId = SOUND_ASSETS[soundName]
	if not assetId then
		warn("SoundManager: Unknown sound " .. soundName)
		return nil
	end
	
	local sound = SoundManager.GetPooledSound()
	sound.SoundId = assetId
	sound.Volume = SOUND_CONFIG.SFXVolume
	sound.Pitch = pitch or 1
	
	if position then
		-- 3D sound at position
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = position
		attachment.Parent = Workspace.Terrain
		sound.Parent = attachment
		
		sound.Ended:Connect(function()
			attachment:Destroy()
		end)
	else
		sound.Parent = soundsFolder
	end
	
	sound:Play()
	return sound
end

function SoundManager.PlayUISound(soundName)
	return SoundManager.PlaySFX(soundName)
end

function SoundManager.PlayMusic(musicName, fadeIn)
	local assetId = SOUND_ASSETS[musicName]
	if not assetId then return end
	
	-- Fade out current music
	if activeMusic then
		if fadeIn then
			SoundManager.FadeOutMusic(activeMusic)
		else
			activeMusic:Destroy()
		end
	end
	
	-- Create new music
	activeMusic = Instance.new("Sound")
	activeMusic.Name = musicName
	activeMusic.SoundId = assetId
	activeMusic.Volume = fadeIn and 0 or SOUND_CONFIG.MusicVolume
	activeMusic.Looped = true
	activeMusic.Parent = musicFolder
	activeMusic:Play()
	
	-- Fade in
	if fadeIn then
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < SOUND_CONFIG.FadeTime do
				local progress = (tick() - startTime) / SOUND_CONFIG.FadeTime
				activeMusic.Volume = SOUND_CONFIG.MusicVolume * progress
				task.wait(0.05)
			end
			activeMusic.Volume = SOUND_CONFIG.MusicVolume
		end)
	end
	
	return activeMusic
end

function SoundManager.FadeOutMusic(music)
	task.spawn(function()
		local startVolume = music.Volume
		local startTime = tick()
		
		while tick() - startTime < SOUND_CONFIG.FadeTime do
			local progress = (tick() - startTime) / SOUND_CONFIG.FadeTime
			music.Volume = startVolume * (1 - progress)
			task.wait(0.05)
		end
		
		music:Destroy()
	end)
end

function SoundManager.StopMusic()
	if activeMusic then
		SoundManager.FadeOutMusic(activeMusic)
		activeMusic = nil
	end
end

-- GAMEPLAY SOUNDS
function SoundManager.PlayCombatSound(soundType, position)
	local sounds = {
		Bite = "Bite",
		Hit = "AttackHit",
		Damage = "DamageTaken",
		Death = "Death"
	}
	
	local soundName = sounds[soundType]
	if soundName then
		return SoundManager.PlaySFX(soundName, position, 0.9 + math.random() * 0.2)
	end
end

function SoundManager.PlayMovementSound(soundType, position)
	local sounds = {
		Swim = "Swim",
		Boost = "Boost",
		Splash = "WaterSplash",
		Leap = "Leap"
	}
	
	local soundName = sounds[soundType]
	if soundName then
		return SoundManager.PlaySFX(soundName, position, 0.95 + math.random() * 0.1)
	end
end

function SoundManager.PlayUISoundByType(soundType)
	local sounds = {
		Click = "ButtonClick",
		Hover = "Hover",
		Error = "Error",
		Success = "Success",
		LevelUp = "LevelUp"
	}
	
	local soundName = sounds[soundType]
	if soundName then
		return SoundManager.PlayUISound(soundName)
	end
end

-- AMBIENT SOUNDS
function SoundManager.StartAmbientSounds()
	-- Underwater ambience handled by zone detection
end

function SoundManager.SetAmbience(isUnderwater)
	if isUnderwater then
		SoundManager.PlaySFX("UnderwaterAmbience", nil, 1)
	else
		SoundManager.PlaySFX("SurfaceAmbience", nil, 1)
	end
end

-- CLEANUP
function SoundManager.Cleanup()
	if soundsFolder then soundsFolder:Destroy() end
	if musicFolder then musicFolder:Destroy() end
	soundPool = {}
	activeMusic = nil
	GameUtilities.DebugPrint("SoundManager: Cleaned up")
end

return SoundManager
