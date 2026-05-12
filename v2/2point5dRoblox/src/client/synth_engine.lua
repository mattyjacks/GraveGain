-- synth_engine.lua v2 – richer synthesis: vibrato, tremolo, chorus, flange
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")
local Players      = game:GetService("Players")

local SE = {}
local BASE = "rbxasset://sounds/electronicpingshort.wav"

local function spd(s) return math.pow(2, s / 12) end
local function r(lo, hi) return lo + math.random() * (hi - lo) end
SE.r = r

local function playerPos()
	local c = Players.LocalPlayer and Players.LocalPlayer.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	return h and h.Position or Vector3.new(0, 5, 0)
end

-- p fields: semitones, speedMult, volume, duration, looped
--           distortion(0-1), eqLow/Mid/High(dB)
--           reverb(0-1), reverbDecay
--           chorus(0-1), chorusRate, chorusDepth
--           flange(0-1), flangeRate, flangeDepth
--           attack, decay
--           vibrato(0-0.1 depth), vibratoRate(Hz)
--           tremolo(0-1 depth), tremoloRate(Hz)
local function voice(p)
	p = p or {}
	local dur = p.duration or 0.35
	local vol = p.volume or 1

	local part = Instance.new("Part")
	part.Anchored = true; part.CanCollide = false
	part.Transparency = 1; part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = playerPos(); part.Name = "_SV"; part.Parent = workspace

	local snd = Instance.new("Sound")
	snd.SoundId       = BASE
	snd.Volume        = ((p.attack or 0) > 0) and 0 or vol
	snd.PlaybackSpeed = spd(p.semitones or 0) * (p.speedMult or 1)
	snd.Looped        = p.looped or false
	snd.RollOffMaxDistance = 80
	snd.Parent        = part

	if (p.distortion or 0) > 0 then
		local fx = Instance.new("DistortionSoundEffect")
		fx.Level = math.clamp(p.distortion, 0, 1); fx.Parent = snd
	end
	if p.eqLow or p.eqMid or p.eqHigh then
		local fx = Instance.new("EqualizerSoundEffect")
		fx.LowGain = p.eqLow or 0; fx.MidGain = p.eqMid or 0
		fx.HighGain = p.eqHigh or 0; fx.Parent = snd
	end
	if (p.reverb or 0) > 0 then
		local fx = Instance.new("ReverbSoundEffect")
		fx.WetLevel = p.reverb; fx.DecayTime = p.reverbDecay or 0.6
		fx.Parent = snd
	end
	if (p.chorus or 0) > 0 then
		local fx = Instance.new("ChorusSoundEffect")
		fx.Mix = p.chorus; fx.Rate = p.chorusRate or 1.5
		fx.Depth = p.chorusDepth or 0.5; fx.Parent = snd
	end
	if (p.flange or 0) > 0 then
		local fx = Instance.new("FlangeSoundEffect")
		fx.Mix = p.flange; fx.Rate = p.flangeRate or 0.5
		fx.Depth = p.flangeDepth or 0.45; fx.Parent = snd
	end

	snd:Play()

	if (p.attack or 0) > 0 then
		TweenService:Create(snd, TweenInfo.new(p.attack, Enum.EasingStyle.Linear),
			{Volume = vol}):Play()
	end
	if (p.decay or 0) > 0 then
		task.delay(math.max(0, dur - p.decay), function()
			if snd and snd.Parent then
				TweenService:Create(snd, TweenInfo.new(p.decay, Enum.EasingStyle.Sine),
					{Volume = 0}):Play()
			end
		end)
	end

	-- Vibrato LFO (pitch oscillation)
	if (p.vibrato or 0) > 0 then
		local base = snd.PlaybackSpeed
		local vr, vd = p.vibratoRate or 5, p.vibrato
		task.spawn(function()
			local t = 0
			while snd and snd.Parent and t < dur do
				snd.PlaybackSpeed = base * (1 + math.sin(t * vr * math.pi * 2) * vd)
				t += 0.016; task.wait(0.016)
			end
		end)
	end

	-- Tremolo LFO (volume oscillation)
	if (p.tremolo or 0) > 0 then
		local tr, td = p.tremoloRate or 6, p.tremolo
		task.spawn(function()
			local t = 0
			while snd and snd.Parent and t < dur do
				snd.Volume = vol * (1 - td * 0.5 * (1 + math.sin(t * tr * math.pi * 2)))
				t += 0.016; task.wait(0.016)
			end
		end)
	end

	Debris:AddItem(part, dur + 0.8)
	return snd, part
end

-- ── Public API ────────────────────────────────────────────────────────────

function SE.note(sem, dur, p)
	local q = {}; for k,v in pairs(p or {}) do q[k]=v end
	q.semitones = sem; q.duration = dur; return voice(q)
end

function SE.chord(list, dur, p)
	for _, s in ipairs(list) do
		local q = {}; for k,v in pairs(p or {}) do q[k]=v end
		q.semitones = s + (q.semitones or 0); q.duration = dur; voice(q)
	end
end

function SE.seq(notes, nLen, p, gap)
	task.spawn(function()
		for _, n in ipairs(notes) do
			local q = {}; for k,v in pairs(p or {}) do q[k]=v end
			q.semitones = n + (q.semitones or 0)
			q.duration = nLen; q.decay = q.decay or nLen * 0.25
			voice(q); task.wait((gap or nLen) * 0.8)
		end
	end)
end

function SE.sweep(fromS, toS, dur, p)
	local q = {}; for k,v in pairs(p or {}) do q[k]=v end
	q.semitones = fromS; q.duration = dur + 0.15; q.looped = true
	local snd = voice(q)
	TweenService:Create(snd, TweenInfo.new(dur, Enum.EasingStyle.Quad),
		{PlaybackSpeed = spd(toS)}):Play()
	task.delay(dur, function() if snd and snd.Parent then snd.Looped = false end end)
end

-- Multiple slightly-detuned voices (thick/chorus pad effect)
function SE.thick(sem, dur, p, spread, count)
	count = count or 3; spread = spread or 1.0
	for i = 1, count do
		local offset = (i - 1) * (spread / math.max(count - 1, 1)) - spread / 2
		task.delay((i - 1) * 0.012, function()
			local q = {}; for k,v in pairs(p or {}) do q[k]=v end
			q.semitones = sem + offset; q.duration = dur; voice(q)
		end)
	end
end

function SE.burst(count, interval, sem, dur, p)
	task.spawn(function()
		for _ = 1, count do
			local q = {}; for k,v in pairs(p or {}) do q[k]=v end
			q.semitones = sem + r(-1.5, 1.5); q.duration = dur; voice(q)
			task.wait(interval)
		end
	end)
end

return SE
