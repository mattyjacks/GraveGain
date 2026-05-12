-- sound_manager.lua v2 – richer, more varied procedural game SFX
local SE = require(script.Parent:WaitForChild("synth_engine"))
local r  = SE.r

local SM = {}

-- ── COMBAT ────────────────────────────────────────────────────────────────

function SM.Swing()
	local base = r(-3, 2)
	SE.sweep(base - 3, base + r(7, 11), r(0.10, 0.15), {
		volume = r(0.5, 0.75), distortion = r(0.3, 0.6),
		eqHigh = r(4, 9), eqLow = -6,
		chorus = r(0.1, 0.25), chorusRate = r(1, 3),
	})
	task.delay(r(0.06, 0.10), function()
		SE.note(base + r(9, 13), r(0.05, 0.09), {
			volume = r(0.2, 0.4), distortion = 0.75, eqHigh = 8, decay = 0.04,
		})
	end)
end

function SM.Hit()
	-- low thud
	SE.note(r(-11, -6), r(0.10, 0.15), {
		volume = r(0.75, 1.0), distortion = r(0.8, 1.0),
		eqLow = 8, eqHigh = -5, decay = 0.07,
	})
	-- crack
	SE.note(r(7, 13), r(0.04, 0.08), {
		volume = r(0.4, 0.7), distortion = 0.95, eqHigh = 8, speedMult = r(0.9, 1.2),
	})
	-- metallic ring
	SE.note(r(0, 6), r(0.13, 0.22), {
		volume = r(0.1, 0.25), distortion = 0,
		reverb = 0.3, reverbDecay = 0.4, eqHigh = 5, decay = 0.12,
		vibrato = 0.01, vibratoRate = 8,
	})
end

function SM.ShieldBlock()
	SE.chord({-6, 0, 5}, r(0.09, 0.14), {
		volume = r(0.55, 0.8), distortion = r(0.65, 0.9), eqLow = 7,
	})
	SE.note(r(3, 9), r(0.14, 0.24), {
		volume = r(0.2, 0.4), flange = r(0.3, 0.6), flangeRate = 2, decay = 0.12,
	})
end

function SM.BowDraw()
	SE.sweep(-14, r(-6, -2), r(0.4, 0.7), {
		volume = r(0.2, 0.4), distortion = r(0.05, 0.2), eqMid = 3,
		vibrato = r(0.01, 0.03), vibratoRate = r(4, 7),
	})
end

function SM.BowRelease()
	local s = r(5, 9)
	SE.sweep(s, s - r(14, 20), r(0.07, 0.12), {
		volume = r(0.6, 0.9), distortion = r(0.35, 0.6), decay = 0.04,
	})
	SE.note(s + r(3, 6), r(0.06, 0.11), {
		volume = r(0.2, 0.4), distortion = 0.5, eqHigh = 6,
	})
end

function SM.ArrowFly()
	SE.sweep(r(9, 13), r(3, 7), r(0.3, 0.55), {
		volume = r(0.12, 0.28), distortion = 0.2, eqHigh = 4,
	})
end

function SM.ArrowHit()
	SE.note(r(-4, 3), r(0.06, 0.10), {
		volume = r(0.4, 0.7), distortion = r(0.45, 0.65), eqHigh = 5, decay = 0.05,
	})
end

-- ── MOVEMENT ──────────────────────────────────────────────────────────────

function SM.Footstep()
	local pitches = {-14, -12, -11, -13, -15}
	SE.note(pitches[math.random(#pitches)], r(0.06, 0.09), {
		volume = r(0.2, 0.38), distortion = r(0.75, 1.0),
		eqLow = 6, eqHigh = -8, speedMult = r(0.88, 1.18), decay = 0.04,
	})
end

function SM.Jump()
	SE.sweep(r(-5, 0), r(8, 13), r(0.07, 0.12), {
		volume = r(0.35, 0.6), distortion = r(0.25, 0.5), eqHigh = 5,
	})
	SE.note(r(4, 9), r(0.05, 0.08), {
		volume = r(0.15, 0.3), distortion = 0.3, eqHigh = 7, decay = 0.04,
	})
end

function SM.Land()
	SE.note(r(-16, -11), r(0.10, 0.17), {
		volume = r(0.6, 0.9), distortion = r(0.75, 1.0), eqLow = 8, eqHigh = -6, decay = 0.07,
	})
	SE.note(r(-4, 1), r(0.08, 0.14), {
		volume = r(0.15, 0.3), distortion = 0.4, eqLow = 3, decay = 0.07,
	})
end

function SM.DodgeRoll()
	SE.sweep(r(4, 8), r(-4, -1), r(0.13, 0.19), {
		volume = r(0.3, 0.55), distortion = r(0.2, 0.45), eqHigh = 4, eqLow = -4,
	})
end

-- ── GRENADES ──────────────────────────────────────────────────────────────

function SM.Explosion()
	for i = 1, 5 do
		task.delay((i - 1) * r(0.035, 0.07), function()
			SE.note(r(-21, -13) - i, r(0.35, 0.65), {
				volume = r(0.65, 1.0) / math.sqrt(i), distortion = r(0.9, 1.0),
				eqLow = 8, eqHigh = -8, decay = 0.22,
				reverb = r(0.35, 0.55), reverbDecay = 1.1,
			})
		end)
	end
	SE.note(r(4, 11), 0.07, {volume = r(0.5, 0.8), distortion = 1.0, eqHigh = 8})
	SE.burst(7, 0.045, r(-4, 2), 0.06, {volume = r(0.1, 0.3), distortion = 0.9, eqHigh = 6})
end

function SM.Flashbang()
	SE.thick(r(20, 25), r(1.6, 2.6), {
		volume = r(0.65, 1.0), looped = true,
		eqHigh = 9, eqLow = -12,
		reverb = r(0.3, 0.5), reverbDecay = 2.2,
		decay = r(1.2, 1.7),
		vibrato = r(0.005, 0.02), vibratoRate = r(3, 6),
	}, 1.5, 3)
end

function SM.MolotovBreak()
	for i = 1, 6 do
		task.delay(i * r(0.02, 0.05), function()
			SE.note(r(8, 20), r(0.04, 0.08), {
				volume = r(0.2, 0.55), distortion = r(0.65, 1.0),
				eqHigh = 8, speedMult = r(0.65, 1.7), decay = 0.03,
			})
		end)
	end
end

function SM.FireLoop()
	SE.burst(22, r(0.09, 0.15), r(-9, -2), r(0.09, 0.15), {
		volume = r(0.10, 0.26), distortion = r(0.55, 0.85), eqLow = 4,
	})
end

-- ── PLAYER ────────────────────────────────────────────────────────────────

function SM.PotionDrink()
	SE.seq({0, 4, 7, 11, 14}, r(0.08, 0.13), {
		volume = r(0.5, 0.75), distortion = r(0.0, 0.15),
		eqHigh = 5, reverb = 0.25, reverbDecay = 0.7,
		chorus = 0.2, chorusRate = 2,
	})
end

function SM.PlayerHurt()
	local b = r(0, 5)
	SE.sweep(b, b - r(7, 12), r(0.14, 0.25), {
		volume = r(0.65, 0.95), distortion = r(0.55, 0.85), eqMid = 4, decay = 0.09,
	})
	SE.note(b - r(3, 7), r(0.08, 0.14), {
		volume = r(0.2, 0.4), distortion = 0.7, eqLow = 4, decay = 0.07,
	})
end

function SM.PlayerDeath()
	-- Descending natural minor: 0,-2,-3,-5,-7,-8,-10,-12
	SE.seq({0, -2, -3, -5, -7, -8, -10, -12}, r(0.12, 0.17), {
		volume = r(0.55, 0.8), distortion = r(0.15, 0.35),
		reverb = 0.5, reverbDecay = 1.3,
		chorus = 0.25, chorusRate = 0.8,
	}, r(0.14, 0.20))
end

-- ── DUNGEON / WORLD ───────────────────────────────────────────────────────

function SM.LorePickup()
	-- Pentatonic shimmer: 0,3,7,10,15
	SE.seq({0, 3, 7, 10, 15}, r(0.09, 0.13), {
		volume = r(0.5, 0.72), distortion = 0,
		reverb = 0.4, reverbDecay = 1.0, eqHigh = 4,
		chorus = 0.3, chorusRate = 1.8,
		vibrato = 0.008, vibratoRate = 5,
	})
end

function SM.AmmoCrate()
	SE.seq({0, 7, 12}, r(0.07, 0.11), {
		volume = r(0.4, 0.65), distortion = r(0.1, 0.3), eqHigh = 6,
	})
end

function SM.Pickup()
	SE.note(r(5, 10), r(0.08, 0.12), {
		volume = r(0.35, 0.55), distortion = 0.1, eqHigh = 5, decay = 0.06,
	})
end

function SM.BossRoar()
	-- Minor triad cluster low + sweep + long reverb
	SE.thick(-12, r(0.8, 1.2), {
		volume = r(0.8, 1.0), distortion = r(0.7, 0.95),
		eqLow = 8, eqHigh = -8, reverb = 0.55, reverbDecay = 1.4,
		decay = 0.4, vibrato = r(0.02, 0.04), vibratoRate = r(3, 5),
	}, 7, 4)
	SE.sweep(-20, r(-8, -5), r(0.6, 1.0), {
		volume = r(0.5, 0.75), distortion = 0.85,
		eqLow = 8, reverb = 0.4, decay = 0.3,
	})
end

function SM.ElevatorBeam()
	SE.thick(r(-5, -2), r(2.2, 3.0), {
		volume = r(0.45, 0.7), looped = true,
		reverb = 0.45, reverbDecay = 1.2,
		eqHigh = 6, eqLow = -4, decay = 0.55,
		chorus = 0.35, chorusRate = 0.6,
		vibrato = r(0.01, 0.025), vibratoRate = r(2, 4),
	}, 2, 3)
end

function SM.LevelUp()
	-- Ascending major fanfare
	SE.seq({0, 4, 7, 12, 16, 19}, r(0.1, 0.14), {
		volume = r(0.6, 0.85), distortion = r(0.1, 0.25),
		reverb = 0.3, eqHigh = 4, chorus = 0.2,
	})
	task.delay(0.7, function()
		SE.chord({0, 7, 12, 19}, r(0.5, 0.8), {
			volume = r(0.5, 0.7), reverb = 0.4, reverbDecay = 1.0,
			distortion = 0.1, chorus = 0.3, decay = 0.35,
		})
	end)
end

function SM.PortalHum()
	SE.thick(r(-4, -1), r(1.2, 1.8), {
		volume = r(0.18, 0.35), looped = true,
		distortion = r(0.1, 0.25), reverb = 0.4, reverbDecay = 0.9,
		eqLow = 3, decay = 0.45, tremolo = 0.3, tremoloRate = 2,
	}, 3, 3)
end

-- ── UI ────────────────────────────────────────────────────────────────────

function SM.MenuSelect()
	SE.note(r(6, 10), r(0.06, 0.09), {
		volume = r(0.35, 0.55), distortion = r(0.1, 0.3), eqHigh = 5,
	})
end

function SM.MenuHover()
	SE.note(r(3, 6), r(0.04, 0.06), {volume = r(0.18, 0.32), distortion = 0.15})
end

function SM.InventoryOpen()
	SE.chord({0, 7}, r(0.07, 0.11), {
		volume = r(0.28, 0.48), distortion = 0.1, eqHigh = 4, reverb = 0.2,
	})
end

function SM.ItemDrop()
	local b = r(2, 7)
	SE.sweep(b, b - r(5, 8), r(0.08, 0.13), {
		volume = r(0.28, 0.48), distortion = r(0.2, 0.45),
	})
end

return SM
