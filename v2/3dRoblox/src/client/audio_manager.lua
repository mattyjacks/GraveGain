-- Audio Manager - Handles sound effects and music
local AudioManager = {}
AudioManager.__index = AudioManager

function AudioManager.new()
	local self = setmetatable({}, AudioManager)
	
	self.sounds = {}
	self.music_volume = 0.5
	self.sfx_volume = 0.7
	self.master_volume = 1.0
	
	return self
end

function AudioManager:initialize()
	print("[AudioManager] Initialized")
end

function AudioManager:play_sound(sound_name, position, volume)
	volume = volume or self.sfx_volume
	
	-- Create sound effect
	local sound = Instance.new("Sound")
	sound.Name = sound_name
	sound.Volume = volume * self.master_volume
	sound.Parent = workspace
	
	-- Map sound names to IDs (placeholder - would use real Roblox audio IDs)
	local sound_ids = {
		sword_swing = "rbxassetid://12345678",
		sword_hit = "rbxassetid://12345679",
		crossbow_fire = "rbxassetid://12345680",
		enemy_death = "rbxassetid://12345681",
		heal = "rbxassetid://12345682",
		level_up = "rbxassetid://12345683",
		item_pickup = "rbxassetid://12345684",
		damage_taken = "rbxassetid://12345685",
		critical_hit = "rbxassetid://12345686",
		wave_start = "rbxassetid://12345687",
	}
	
	sound.SoundId = sound_ids[sound_name] or "rbxassetid://12345678"
	
	if position then
		sound.Parent = workspace
		sound.PlayOnRemove = false
	end
	
	sound:Play()
	
	-- Auto-cleanup
	game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.5)
	
	return sound
end

function AudioManager:play_music(music_name, loop)
	loop = loop ~= false
	
	-- Create music player
	local music = Instance.new("Sound")
	music.Name = "Music_" .. music_name
	music.Volume = self.music_volume * self.master_volume
	music.Looped = loop
	music.Parent = workspace
	
	-- Map music names to IDs
	local music_ids = {
		lobby = "rbxassetid://12345700",
		gameplay = "rbxassetid://12345701",
		boss = "rbxassetid://12345702",
		victory = "rbxassetid://12345703",
		defeat = "rbxassetid://12345704",
	}
	
	music.SoundId = music_ids[music_name] or "rbxassetid://12345700"
	music:Play()
	
	return music
end

function AudioManager:stop_all_music()
	for _, sound in ipairs(workspace:GetChildren()) do
		if sound:IsA("Sound") and sound.Name:sub(1, 6) == "Music_" then
			sound:Stop()
			sound:Destroy()
		end
	end
end

function AudioManager:set_master_volume(volume)
	self.master_volume = math.clamp(volume, 0, 1)
end

function AudioManager:set_music_volume(volume)
	self.music_volume = math.clamp(volume, 0, 1)
end

function AudioManager:set_sfx_volume(volume)
	self.sfx_volume = math.clamp(volume, 0, 1)
end

function AudioManager:play_footstep(position)
	local footstep_sounds = {
		"rbxassetid://12345750",
		"rbxassetid://12345751",
		"rbxassetid://12345752",
	}
	
	local sound = Instance.new("Sound")
	sound.Name = "Footstep"
	sound.Volume = 0.3 * self.master_volume
	sound.SoundId = footstep_sounds[math.random(1, #footstep_sounds)]
	sound.Parent = workspace
	sound:Play()
	
	game:GetService("Debris"):AddItem(sound, 0.5)
end

function AudioManager:play_weapon_sound(weapon_type)
	if weapon_type == "melee" then
		self:play_sound("sword_swing", nil, 0.6)
	elseif weapon_type == "ranged" then
		self:play_sound("crossbow_fire", nil, 0.7)
	end
end

function AudioManager:play_hit_sound(is_crit)
	if is_crit then
		self:play_sound("critical_hit", nil, 0.8)
	else
		self:play_sound("sword_hit", nil, 0.6)
	end
end

function AudioManager:play_damage_sound()
	self:play_sound("damage_taken", nil, 0.5)
end

function AudioManager:play_heal_sound()
	self:play_sound("heal", nil, 0.7)
end

function AudioManager:play_item_pickup_sound()
	self:play_sound("item_pickup", nil, 0.6)
end

function AudioManager:play_enemy_death_sound()
	self:play_sound("enemy_death", nil, 0.5)
end

function AudioManager:play_wave_start_sound()
	self:play_sound("wave_start", nil, 0.8)
end

return AudioManager
