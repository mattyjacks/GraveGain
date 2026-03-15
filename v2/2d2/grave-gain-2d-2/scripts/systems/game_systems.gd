extends Node

signal achievement_unlocked(id: String, title: String)
signal level_up(new_level: int)
signal kill_streak_updated(streak: int, multiplier: float)
signal stats_updated(stat_name: String, value: float)
signal score_changed(new_score: int)
signal combo_updated(count: int, timer: float)
signal kill_feed_entry(killer: String, victim: String, weapon: String)
signal tutorial_hint(text: String, duration: float)
signal boss_hp_updated(boss_name: String, hp_pct: float, visible: bool)

const SAVE_PATH := "user://game_systems.save"
const SETTINGS_PATH := "user://settings.cfg"

# ===== IMPROVEMENT #81: Difficulty System =====
enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }
var current_difficulty: Difficulty = Difficulty.NORMAL
var difficulty_multipliers: Dictionary = {
	Difficulty.EASY: {"enemy_hp": 0.6, "enemy_dmg": 0.5, "enemy_speed": 0.9, "loot": 1.5, "xp": 0.75, "spawn_rate": 0.7},
	Difficulty.NORMAL: {"enemy_hp": 1.0, "enemy_dmg": 1.0, "enemy_speed": 1.2, "loot": 1.0, "xp": 1.0, "spawn_rate": 1.0},
	Difficulty.HARD: {"enemy_hp": 1.5, "enemy_dmg": 1.5, "enemy_speed": 1.4, "loot": 0.8, "xp": 1.5, "spawn_rate": 1.3},
	Difficulty.NIGHTMARE: {"enemy_hp": 2.5, "enemy_dmg": 2.0, "enemy_speed": 1.6, "loot": 0.6, "xp": 2.5, "spawn_rate": 1.6},
}
var difficulty_names: Array[String] = ["Easy", "Normal", "Hard", "Nightmare"]

func get_diff_mult(key: String) -> float:
	return difficulty_multipliers[current_difficulty].get(key, 1.0)

# ===== IMPROVEMENT #85: XP / Level System =====
var player_level: int = 1
var player_xp: int = 0
var xp_to_next_level: int = 100
const MAX_LEVEL := 50
const XP_SCALE := 1.15

func xp_for_level(lvl: int) -> int:
	return int(100.0 * pow(XP_SCALE, lvl - 1))

func add_xp(amount: int) -> void:
	amount = int(amount * get_diff_mult("xp"))
	player_xp += amount
	while player_xp >= xp_to_next_level and player_level < MAX_LEVEL:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = xp_for_level(player_level)
		level_up.emit(player_level)
	stats_updated.emit("xp", player_xp)

func get_level_stat_bonus() -> float:
	return 1.0 + (player_level - 1) * 0.03

# ===== IMPROVEMENT #7: Kill Streak System =====
var kill_streak: int = 0
var kill_streak_timer: float = 0.0
var best_kill_streak: int = 0
const KILL_STREAK_TIMEOUT := 4.0

func register_kill(enemy_name: String, weapon: String) -> void:
	kill_streak += 1
	kill_streak_timer = KILL_STREAK_TIMEOUT
	if kill_streak > best_kill_streak:
		best_kill_streak = kill_streak
	kill_streak_updated.emit(kill_streak, get_streak_multiplier())
	kill_feed_entry.emit("Player", enemy_name, weapon)
	_check_kill_achievements()

func get_streak_multiplier() -> float:
	if kill_streak < 3: return 1.0
	if kill_streak < 5: return 1.25
	if kill_streak < 10: return 1.5
	if kill_streak < 20: return 2.0
	if kill_streak < 50: return 3.0
	return 5.0

# ===== IMPROVEMENT #55: Score System =====
var score: int = 0
var high_score: int = 0

func add_score(base_points: int) -> void:
	var mult := get_streak_multiplier() * get_diff_mult("xp")
	score += int(base_points * mult)
	if score > high_score:
		high_score = score
	score_changed.emit(score)

# ===== IMPROVEMENT #71: Combo System =====
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_TIMEOUT := 2.0
const COMBO_DECAY := 1.5

func register_hit() -> void:
	combo_count += 1
	combo_timer = COMBO_TIMEOUT
	combo_updated.emit(combo_count, combo_timer)

func get_combo_damage_mult() -> float:
	if combo_count < 3: return 1.0
	return 1.0 + minf(combo_count * 0.05, 0.5)

# ===== IMPROVEMENT #82: Statistics Tracking =====
var stats: Dictionary = {
	"total_kills": 0, "total_deaths": 0, "total_damage_dealt": 0.0,
	"total_damage_taken": 0.0, "total_gold_earned": 0, "total_xp_earned": 0,
	"total_missions": 0, "missions_completed": 0, "total_play_time": 0.0,
	"enemies_killed_melee": 0, "enemies_killed_ranged": 0,
	"highest_combo": 0, "highest_kill_streak": 0,
	"health_potions_used": 0, "mana_potions_used": 0,
	"gold_spent": 0, "rooms_explored": 0, "lore_collected": 0,
	"dodges_performed": 0, "perfect_blocks": 0, "critical_hits": 0,
	"bosses_killed": 0, "total_distance": 0.0, "food_eaten": 0,
}

func track(stat_name: String, amount: float = 1.0) -> void:
	if stat_name in stats:
		stats[stat_name] += amount
		stats_updated.emit(stat_name, stats[stat_name])
		_check_stat_achievements(stat_name)

# ===== IMPROVEMENT #83: Achievement System =====
var achievements: Dictionary = {}
var unlocked_achievements: Dictionary = {}

func _init_achievements() -> void:
	achievements = {
		"first_blood": {"title": "First Blood", "desc": "Kill your first enemy", "icon": "\U0001F5E1\uFE0F", "condition": "total_kills >= 1"},
		"century": {"title": "Century", "desc": "Kill 100 enemies", "icon": "\U0001F4AF", "condition": "total_kills >= 100"},
		"massacre": {"title": "Massacre", "desc": "Kill 1000 enemies", "icon": "\U0001F480", "condition": "total_kills >= 1000"},
		"streak_5": {"title": "On Fire", "desc": "5 kill streak", "icon": "\U0001F525", "condition": "highest_kill_streak >= 5"},
		"streak_10": {"title": "Unstoppable", "desc": "10 kill streak", "icon": "\u26A1", "condition": "highest_kill_streak >= 10"},
		"streak_25": {"title": "Godlike", "desc": "25 kill streak", "icon": "\U0001F31F", "condition": "highest_kill_streak >= 25"},
		"combo_10": {"title": "Combo Master", "desc": "10 hit combo", "icon": "\U0001F4A5", "condition": "highest_combo >= 10"},
		"combo_25": {"title": "Combo Legend", "desc": "25 hit combo", "icon": "\U0001F300", "condition": "highest_combo >= 25"},
		"gold_1000": {"title": "Getting Rich", "desc": "Earn 1000 gold", "icon": "\U0001FA99", "condition": "total_gold_earned >= 1000"},
		"gold_100000": {"title": "Moneybags", "desc": "Earn 100,000 gold", "icon": "\U0001F4B0", "condition": "total_gold_earned >= 100000"},
		"level_10": {"title": "Seasoned", "desc": "Reach level 10", "icon": "\u2B50", "condition": "level >= 10"},
		"level_25": {"title": "Veteran", "desc": "Reach level 25", "icon": "\U0001F31F", "condition": "level >= 25"},
		"level_50": {"title": "Legend", "desc": "Reach max level", "icon": "\U0001F451", "condition": "level >= 50"},
		"perfect_10": {"title": "Shield Wall", "desc": "10 perfect blocks", "icon": "\U0001F6E1\uFE0F", "condition": "perfect_blocks >= 10"},
		"dodge_50": {"title": "Untouchable", "desc": "Dodge 50 times", "icon": "\U0001F4A8", "condition": "dodges_performed >= 50"},
		"crit_100": {"title": "Sharpshooter", "desc": "100 critical hits", "icon": "\U0001F3AF", "condition": "critical_hits >= 100"},
		"boss_1": {"title": "Boss Slayer", "desc": "Kill a boss enemy", "icon": "\U0001F432", "condition": "bosses_killed >= 1"},
		"boss_10": {"title": "Boss Hunter", "desc": "Kill 10 bosses", "icon": "\U0001F409", "condition": "bosses_killed >= 10"},
		"explorer": {"title": "Explorer", "desc": "Explore 50 rooms", "icon": "\U0001F5FA\uFE0F", "condition": "rooms_explored >= 50"},
		"lore_10": {"title": "Lore Seeker", "desc": "Collect 10 lore entries", "icon": "\U0001F4DA", "condition": "lore_collected >= 10"},
		"lore_all": {"title": "Loremaster", "desc": "Collect all lore", "icon": "\U0001F4DC", "condition": "lore_collected >= 60"},
		"survivor": {"title": "Survivor", "desc": "Complete a mission", "icon": "\U0001F3C6", "condition": "missions_completed >= 1"},
		"foodie": {"title": "Foodie", "desc": "Eat 25 food items", "icon": "\U0001F356", "condition": "food_eaten >= 25"},
		"marathon": {"title": "Marathon", "desc": "Travel 10km total", "icon": "\U0001F3C3", "condition": "total_distance >= 10000"},
	}

func _check_kill_achievements() -> void:
	stats["highest_kill_streak"] = best_kill_streak
	_check_stat_achievements("total_kills")
	_check_stat_achievements("highest_kill_streak")

func _check_stat_achievements(_stat_name: String) -> void:
	for id in achievements:
		if id in unlocked_achievements:
			continue
		var cond: String = achievements[id]["condition"]
		if _evaluate_condition(cond):
			_unlock_achievement(id)

func _evaluate_condition(cond: String) -> bool:
	var parts := cond.split(" ")
	if parts.size() != 3:
		return false
	var key: String = parts[0]
	var op: String = parts[1]
	var val := float(parts[2])
	var current: float = 0.0
	if key == "level":
		current = player_level
	elif key in stats:
		current = stats[key]
	match op:
		">=": return current >= val
		">": return current > val
		"==": return current == val
	return false

func _unlock_achievement(id: String) -> void:
	if id in unlocked_achievements:
		return
	unlocked_achievements[id] = Time.get_unix_time_from_system()
	achievement_unlocked.emit(id, achievements[id]["title"])

# ===== IMPROVEMENT #87: Mission Rating =====
func get_mission_rating(kills: int, time_seconds: float, damage_taken: float, gold: int) -> String:
	var base := kills * 10 - int(damage_taken * 0.5) + int(float(gold) / 100.0)
	var time_bonus := maxf(0.0, 300.0 - time_seconds) * 2.0
	var total := base + int(time_bonus)
	if total >= 5000: return "S"
	if total >= 3000: return "A"
	if total >= 1500: return "B"
	if total >= 500: return "C"
	return "D"

# ===== IMPROVEMENT #91: Settings =====
var settings: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 0.7,
	"mouse_sensitivity": 1.0,
	"camera_smoothing": 12.0,
	"camera_zoom": 1.5,
	"screen_shake": true,
	"damage_numbers": true,
	"show_fps": true,
	"show_minimap": true,
	"minimap_zoom": 1.0,
	"auto_pickup_range": 40.0,
	"colorblind_mode": 0,
	"vignette_enabled": true,
	"hit_markers": true,
	"tutorial_hints": true,
	"crosshair_style": 0,
	# Graphics settings
	"graphics_quality": 2, # 0=Low, 1=Medium, 2=High, 3=Ultra
	"blood_enabled": true,
	"blood_intensity": 2, # 0=Off, 1=Mild, 2=Normal, 3=Extreme
	"particles_enabled": true,
	"particle_density": 2, # 0=Low, 1=Medium, 2=High, 3=Ultra
	"shadows_enabled": true,
	"dynamic_lighting": true,
	"hit_flash_enabled": true,
	"gore_enabled": true,
	"trail_effects": true,
	"impact_effects": true,
	"ambient_particles": true,
	"hit_pause_enabled": true,
	"camera_punch": true,
	"camera_lead": true,
	# Emoji set
	"emoji_set": "system",
}

func get_setting(key: String) -> Variant:
	return settings.get(key, null)

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_settings()

func apply_settings(new_settings: Dictionary) -> void:
	for key in new_settings:
		settings[key] = new_settings[key]
	save_settings()

# ===== IMPROVEMENT #96: Tutorial System =====
var shown_tutorials: Dictionary = {}

func show_tutorial(id: String, text: String, duration: float = 5.0) -> void:
	if not settings["tutorial_hints"]:
		return
	if id in shown_tutorials:
		return
	shown_tutorials[id] = true
	tutorial_hint.emit(text, duration)

# ===== IMPROVEMENT #97: Loading Tips =====
var loading_tips: Array[String] = [
	"Dwarves can see in the dark without lights.",
	"Elven BrightEyes attract nature spirits for stronger spells.",
	"Orc Rage builds when taking damage - use it wisely!",
	"Human shields regenerate after a short delay.",
	"Perfect blocks (block within 0.2s of hit) negate all damage.",
	"Mana potions only work on Elves. Dwarves brew them, but cannot use them.",
	"Kill streaks increase your score multiplier up to 5x!",
	"Signs and gravestones contain lore - press E to read them.",
	"Orcs eat their dead to prevent uncontrolled regeneration.",
	"The NecroGenesis activated at 3:47 AM on Day 7.",
	"SafeSpaces are ley line nodes that resist necromantic energy.",
	"Goblins throw rocks at everything. Even friends. It is reflex.",
	"Higher difficulty means more XP and tougher enemies.",
	"Combos increase your damage up to 50% at high hit counts.",
	"Dodge rolling grants brief invincibility frames.",
	"Headshots deal 2x critical damage on humanoid enemies.",
	"Food heals over time - you can eat up to 3 items at once.",
	"The Dwarf Paladin's body cannot be raised as undead.",
	"Lucifer Hades was awake for 200 years on the colony ship.",
	"KillCredits are earned from confirmed combat kills.",
	"Sprinting while attacking extends your melee range.",
	"Charge attacks deal 3x damage but leave you vulnerable.",
	"Bloodlust stacks decay after 5 seconds without a kill.",
	"Fountains in shrine rooms heal you passively.",
	"Altars grant temporary buffs: strength, speed, protection, fury, or life.",
	"Elite enemies glow with a special aura and drop better loot.",
	"Treasure rooms contain enhanced chests with rare items.",
	"Secret rooms are hidden behind breakable walls.",
	"Corridor ambushes can spawn enemies unexpectedly.",
	"Dead-end corridors often contain hidden treasure caches.",
	"Hazard zones deal damage over time - avoid them or resist the element.",
	"Environmental kills count toward your statistics.",
	"Speed running is tracked - try to beat your personal best!",
	"Prestige resets your level but grants permanent bonuses.",
	"Daily challenges refresh every 24 hours with new objectives.",
	"Weapon mastery increases damage with each weapon type.",
	"Revival tokens give you extra lives - use them wisely.",
	"Respawn invulnerability lasts 2 seconds after revival.",
	"Difficulty increases over time during long missions.",
	"Auto-save happens every 60 seconds.",
	"Death recap shows the last 10 damage sources.",
	"Mission time bonuses reward fast completion.",
	"Damage resistance scales with your level.",
	"Critical damage multiplier increases as you level up.",
	"Gold interest earns you passive income every 30 seconds.",
	"Healing efficiency improves with your level.",
	"Damage type resistance helps against elemental attacks.",
	"Lore entries are weighted - new ones spawn more frequently.",
	"Lore collection progress is saved automatically.",
	"Text-to-speech can narrate lore entries if configured.",
	"Emoji sets can be swapped instantly in settings.",
	"Different emoji sets change the entire visual style.",
	"Twemoji renders cleanly at all sizes.",
	"OpenMoji has distinctive black outlines.",
	"Noto Color Emoji is Google's professional set.",
	"Blobmoji has a nostalgic, friendly feel.",
	"Fluent Emoji features 3D-inspired designs.",
	"JoyPixels offers professional polish.",
	"Samsung Emoji has vibrant, bold colors.",
	"System emoji matches your operating system.",
	"Minimap shows room layouts and enemy positions.",
	"Vignette darkens screen edges for atmosphere.",
	"Screen shake intensity can be adjusted.",
	"Camera lead offsets the view toward movement.",
	"Hit markers flash on successful strikes.",
	"Damage numbers float above enemies.",
	"Combo counter escalates with color.",
	"Kill streak announcements celebrate your progress.",
	"Bloodlust display shows your current stacks.",
	"Charge bar indicates attack power buildup.",
	"Boss HP bar appears during major encounters.",
	"DPS meter tracks your damage output.",
	"Gold popups show pickup amounts.",
	"Death screen displays comprehensive statistics.",
	"Tutorial hints can be toggled on or off.",
	"Colorblind mode adjusts colors for accessibility.",
	"Auto-pickup range increases with player level.",
	"Magnet scaling makes items easier to collect.",
	"Item rarity glow indicates value.",
	"Spinning animations help items stand out.",
	"Bobbing animations make items feel alive.",
	"Loot explosion creates satisfying drops.",
	"Gore effects can be disabled for sensitivity.",
	"Blood intensity ranges from off to extreme.",
	"Particle density affects performance.",
	"Shadow quality impacts visual fidelity.",
	"Dynamic lighting creates atmospheric depth.",
	"Hit flash provides impact feedback.",
	"Attack trails show weapon movement.",
	"Impact rings expand on collision.",
	"Ambient particles fill rooms with atmosphere.",
	"Hit pause freezes frames on impact.",
	"Execution slash appears on instant kills.",
	"Charge glow indicates power buildup.",
	"Overkill explosion celebrates massive damage.",
	"Level up burst celebrates progression.",
	"Dodge afterimage shows your movement.",
	"Healing particles indicate recovery.",
	"Shield break shards show protection loss.",
	"Elemental hits use color-coded effects.",
	"Screen flash emphasizes critical moments.",
	"Camera punch provides directional feedback.",
	"Footstep dust shows movement trails.",
	"Ambient mist creates atmospheric rooms.",
	"Sparkles decorate special areas.",
	"Smoke rises from certain decorations.",
	"Water pools slow your movement.",
	"Spike traps deal contact damage.",
	"Poison traps inflict damage over time.",
	"Lightning traps stun on contact.",
	"Ice traps slow movement.",
	"Fire traps burn continuously.",
	"Doors can be opened by approaching.",
	"Buildings contain sidescroller sections.",
	"Platforms require jumping to traverse.",
	"Wall jumps let you reach high areas.",
	"Moving platforms transport you across gaps.",
	"Breakable walls hide secrets.",
	"Spikes in buildings deal damage.",
	"Parallax backgrounds add depth.",
	"Lore pickups bob gently.",
	"Gravestones require E to interact.",
	"Signs display lore when approached.",
	"Crystals sparkle with magical energy.",
	"Tablets contain ancient knowledge.",
	"Journals tell personal stories.",
	"Letters reveal character relationships.",
	"Scrolls hold magical secrets.",
	"Books contain comprehensive lore.",
	"Rare lore entries are harder to find.",
	"Legendary lore is extremely valuable.",
	"Collection UI shows progress per category.",
	"API keys enable text-to-speech.",
	"TTS cache stores generated audio.",
	"Settings persist between sessions.",
	"High score is tracked globally.",
	"Statistics are saved automatically.",
	"Achievements unlock with milestones.",
]

func get_random_tip() -> String:
	if loading_tips.is_empty():
		return "Good luck out there!"
	return loading_tips.pick_random()

# ===== Lifecycle =====
func _ready() -> void:
	_init_achievements()
	load_settings()
	load_stats()

func _process(delta: float) -> void:
	if kill_streak_timer > 0:
		kill_streak_timer -= delta
		if kill_streak_timer <= 0:
			kill_streak = 0
			kill_streak_updated.emit(0, 1.0)

	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			if combo_count > stats.get("highest_combo", 0):
				stats["highest_combo"] = combo_count
				_check_stat_achievements("highest_combo")
			combo_count = 0
			combo_updated.emit(0, 0.0)

	stats["total_play_time"] += delta
	_check_auto_save(delta)
	if speedrun_active:
		speedrun_time += delta

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key in settings:
		if config.has_section_key("settings", key):
			settings[key] = config.get_value("settings", key)

func save_stats() -> void:
	var data := {
		"stats": stats,
		"achievements": unlocked_achievements,
		"high_score": high_score,
		"shown_tutorials": shown_tutorials,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_stats() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	if not json.data is Dictionary:
		return
	var data: Dictionary = json.data
	if "stats" in data:
		for key in data["stats"]:
			if key in stats:
				stats[key] = data["stats"][key]
	if "achievements" in data:
		unlocked_achievements = data["achievements"]
	if "high_score" in data:
		high_score = int(data["high_score"])
	if "shown_tutorials" in data:
		shown_tutorials = data["shown_tutorials"]

# ===== Improvement #84: Auto-Save System =====
var auto_save_timer: float = 0.0
var auto_save_interval: float = 60.0

func _check_auto_save(delta: float) -> void:
	auto_save_timer += delta
	if auto_save_timer >= auto_save_interval:
		auto_save_timer = 0.0
		save_stats()

# ===== Improvement #85b: Death Recap System =====
var death_recap: Array[Dictionary] = []
const MAX_RECAP_ENTRIES := 10

func add_death_recap_entry(source: String, damage: float, damage_type: String) -> void:
	death_recap.append({
		"source": source,
		"damage": damage,
		"type": damage_type,
		"time": stats["total_play_time"],
	})
	if death_recap.size() > MAX_RECAP_ENTRIES:
		death_recap.pop_front()

func get_death_recap() -> Array[Dictionary]:
	return death_recap.duplicate()

func clear_death_recap() -> void:
	death_recap.clear()

# ===== Improvement #86: Mission Time Bonus =====
func get_time_bonus(mission_time: float) -> int:
	if mission_time < 60.0: return 500
	if mission_time < 120.0: return 300
	if mission_time < 180.0: return 150
	if mission_time < 300.0: return 50
	return 0

# ===== Improvement #87b: Damage Resistance Scaling =====
func get_damage_resistance(player_level_val: int) -> float:
	return clampf(player_level_val * 0.005, 0.0, 0.25)

# ===== Improvement #88: Critical Damage Scaling =====
func get_crit_damage_bonus(player_level_val: int) -> float:
	return 1.5 + player_level_val * 0.02

# ===== Improvement #89: Gold Interest System =====
var gold_interest_rate: float = 0.01
var gold_interest_timer: float = 0.0
var gold_interest_interval: float = 30.0

func calculate_gold_interest(current_gold: int) -> int:
	return int(current_gold * gold_interest_rate)

# ===== Improvement #90: Prestige System =====
var prestige_level: int = 0
var prestige_bonuses: Dictionary = {
	0: {"dmg_mult": 1.0, "xp_mult": 1.0, "gold_mult": 1.0},
	1: {"dmg_mult": 1.05, "xp_mult": 1.1, "gold_mult": 1.1},
	2: {"dmg_mult": 1.1, "xp_mult": 1.2, "gold_mult": 1.2},
	3: {"dmg_mult": 1.15, "xp_mult": 1.35, "gold_mult": 1.35},
	4: {"dmg_mult": 1.2, "xp_mult": 1.5, "gold_mult": 1.5},
	5: {"dmg_mult": 1.3, "xp_mult": 2.0, "gold_mult": 2.0},
}

func get_prestige_bonus(key: String) -> float:
	var p := mini(prestige_level, 5)
	return prestige_bonuses[p].get(key, 1.0)

func can_prestige() -> bool:
	return player_level >= MAX_LEVEL

func do_prestige() -> void:
	if not can_prestige():
		return
	prestige_level += 1
	player_level = 1
	player_xp = 0
	xp_to_next_level = xp_for_level(1)
	save_stats()

# ===== Improvement #91b: Daily Challenge System =====
var daily_challenges: Array[Dictionary] = []
var daily_seed: int = 0

func generate_daily_challenges() -> void:
	var today := Time.get_date_dict_from_system()
	daily_seed = today["year"] * 10000 + today["month"] * 100 + today["day"]
	var rng_daily := RandomNumberGenerator.new()
	rng_daily.seed = daily_seed
	daily_challenges.clear()
	var challenge_types := [
		{"desc": "Kill %d enemies", "target_key": "total_kills", "target_val": 0},
		{"desc": "Earn %d gold", "target_key": "total_gold_earned", "target_val": 0},
		{"desc": "Deal %d damage", "target_key": "total_damage_dealt", "target_val": 0},
		{"desc": "Achieve a %d kill streak", "target_key": "highest_kill_streak", "target_val": 0},
	]
	for i in range(3):
		var ct: Dictionary = challenge_types[rng_daily.randi_range(0, challenge_types.size() - 1)].duplicate()
		match ct["target_key"]:
			"total_kills": ct["target_val"] = rng_daily.randi_range(20, 100)
			"total_gold_earned": ct["target_val"] = rng_daily.randi_range(200, 1000)
			"total_damage_dealt": ct["target_val"] = rng_daily.randi_range(500, 5000)
			"highest_kill_streak": ct["target_val"] = rng_daily.randi_range(5, 15)
		ct["desc"] = ct["desc"] % ct["target_val"]
		ct["completed"] = false
		daily_challenges.append(ct)

# ===== Improvement #92: Weapon Mastery System =====
var weapon_mastery: Dictionary = {
	"melee": 0,
	"ranged": 0,
	"ability": 0,
}
const MASTERY_PER_KILL := 1
const MASTERY_LEVELS := [0, 50, 150, 400, 1000, 2500]

func add_weapon_mastery(weapon_type: String, amount: int = MASTERY_PER_KILL) -> void:
	if weapon_type in weapon_mastery:
		weapon_mastery[weapon_type] += amount

func get_mastery_level(weapon_type: String) -> int:
	var xp_val: int = weapon_mastery.get(weapon_type, 0)
	var lvl := 0
	for threshold in MASTERY_LEVELS:
		if xp_val >= threshold:
			lvl += 1
	return mini(lvl, MASTERY_LEVELS.size())

func get_mastery_bonus(weapon_type: String) -> float:
	return 1.0 + get_mastery_level(weapon_type) * 0.05

# ===== Improvement #93: Environmental Kill Tracking =====
var env_kills: Dictionary = {
	"trap_kills": 0,
	"fall_kills": 0,
	"hazard_kills": 0,
	"explosion_kills": 0,
}

func track_env_kill(kill_type: String) -> void:
	if kill_type in env_kills:
		env_kills[kill_type] += 1
	add_score(25)

# ===== Improvement #94: Speed Run Timer =====
var speedrun_active: bool = false
var speedrun_time: float = 0.0
var speedrun_splits: Array[Dictionary] = []
var best_speedrun: float = 999999.0

func start_speedrun() -> void:
	speedrun_active = true
	speedrun_time = 0.0
	speedrun_splits.clear()

func add_speedrun_split(label: String) -> void:
	if speedrun_active:
		speedrun_splits.append({"label": label, "time": speedrun_time})

func finish_speedrun() -> float:
	speedrun_active = false
	if speedrun_time < best_speedrun:
		best_speedrun = speedrun_time
	return speedrun_time

# ===== Improvement #95: Damage Type Resistance =====
var resistance_profile: Dictionary = {
	"physical": 0.0,
	"fire": 0.0,
	"ice": 0.0,
	"poison": 0.0,
	"lightning": 0.0,
}

func apply_resistance(damage: float, damage_type: String) -> float:
	var res: float = resistance_profile.get(damage_type, 0.0)
	return damage * (1.0 - clampf(res, 0.0, 0.75))

func add_resistance(damage_type: String, amount: float) -> void:
	if damage_type in resistance_profile:
		resistance_profile[damage_type] = clampf(resistance_profile[damage_type] + amount, 0.0, 0.75)

# ===== Improvement #96b: Healing Efficiency =====
func get_healing_efficiency(player_level_val: int) -> float:
	return 1.0 + player_level_val * 0.01

# ===== Improvement #98: Revival Token System =====
var revival_tokens: int = 0
const MAX_REVIVAL_TOKENS := 3

func add_revival_token() -> void:
	revival_tokens = mini(revival_tokens + 1, MAX_REVIVAL_TOKENS)

func use_revival_token() -> bool:
	if revival_tokens > 0:
		revival_tokens -= 1
		return true
	return false

# ===== Improvement #99: Respawn Invulnerability =====
var respawn_invuln_time: float = 2.0

func get_respawn_invuln() -> float:
	return respawn_invuln_time

# ===== Improvement #100: Difficulty Scaling Over Time =====
func get_difficulty_multiplier(mission_time: float) -> float:
	return 1.0 + (mission_time / 300.0) * 0.5

func reset_mission() -> void:
	kill_streak = 0
	kill_streak_timer = 0.0
	combo_count = 0
	combo_timer = 0.0
	score = 0
	clear_death_recap()
	stats["total_missions"] += 1
	save_stats()
