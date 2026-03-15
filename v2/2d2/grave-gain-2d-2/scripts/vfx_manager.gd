extends Node2D

# Blood colors for variety
const BLOOD_COLORS: Array[Color] = [
	Color(0.6, 0.0, 0.0), Color(0.5, 0.02, 0.02), Color(0.7, 0.05, 0.0),
	Color(0.45, 0.0, 0.05), Color(0.55, 0.0, 0.0), Color(0.65, 0.02, 0.02),
]
const BLOOD_DARK: Array[Color] = [
	Color(0.3, 0.0, 0.0), Color(0.25, 0.01, 0.01), Color(0.35, 0.02, 0.0),
]

var game_ref: Node = null

var blood_splats: Array[Dictionary] = []
var blood_particles: Array[Dictionary] = []
var hit_flashes: Array[Dictionary] = []
var attack_trails: Array[Dictionary] = []
var impact_rings: Array[Dictionary] = []
var gore_chunks: Array[Dictionary] = []
var footstep_dust: Array[Dictionary] = []
var muzzle_flashes: Array[Dictionary] = []

# Improvement #46: Level up burst particles
var level_up_particles: Array[Dictionary] = []
# Improvement #47: Dodge afterimage
var afterimages: Array[Dictionary] = []
# Improvement #48: Healing particles
var heal_particles: Array[Dictionary] = []
# Improvement #49: Elemental hit effects
var elemental_particles: Array[Dictionary] = []
# Improvement #50: Shield break shards
var shield_shards: Array[Dictionary] = []
# Improvement #51: Execution slash
var execution_slashes: Array[Dictionary] = []
# Improvement #52: Charge glow aura
var charge_glows: Array[Dictionary] = []
# Improvement #53: Ambient environment particles
var ambient_particles: Array[Dictionary] = []
# Improvement #54: Screen flash overlay
var screen_flash_timer: float = 0.0
var screen_flash_color: Color = Color.WHITE
# Improvement #55: Overkill explosion
var overkill_rings: Array[Dictionary] = []

const MAX_BLOOD_SPLATS := 200
const MAX_PARTICLES := 300
const MAX_GORE := 50
const MAX_AMBIENT := 100

func _ready() -> void:
	z_index = 15
	name = "VFXManager"

func _process(delta: float) -> void:
	_update_blood_particles(delta)
	_update_hit_flashes(delta)
	_update_attack_trails(delta)
	_update_impact_rings(delta)
	_update_gore_chunks(delta)
	_update_footstep_dust(delta)
	_update_muzzle_flashes(delta)
	_update_level_up_particles(delta)
	_update_afterimages(delta)
	_update_heal_particles(delta)
	_update_elemental_particles(delta)
	_update_shield_shards(delta)
	_update_execution_slashes(delta)
	_update_charge_glows(delta)
	_update_ambient_particles(delta)
	_update_overkill_rings(delta)
	_decay_blood_splats(delta)
	screen_flash_timer = maxf(screen_flash_timer - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	_draw_blood_splats()
	_draw_blood_particles()
	_draw_gore_chunks()
	_draw_hit_flashes()
	_draw_attack_trails()
	_draw_impact_rings()
	_draw_footstep_dust()
	_draw_muzzle_flashes()
	_draw_level_up_particles()
	_draw_afterimages()
	_draw_heal_particles()
	_draw_elemental_particles()
	_draw_shield_shards()
	_draw_execution_slashes()
	_draw_charge_glows()
	_draw_ambient_particles()
	_draw_overkill_rings()

# ===== BLOOD SPLATS (persistent ground stains) =====

func spawn_blood_splat(pos: Vector2, size: float = 1.0, color_override: Color = Color(-1, 0, 0)) -> void:
	if not GameSystems.get_setting("blood_enabled"):
		return
	var intensity: int = GameSystems.get_setting("blood_intensity")
	if intensity == 0:
		return

	var count := 1 + intensity
	for i in range(count):
		var offset := Vector2(randf_range(-8, 8), randf_range(-8, 8)) * size
		var col: Color
		if color_override.r >= 0:
			col = color_override
		else:
			col = BLOOD_COLORS.pick_random()
		col.a = randf_range(0.5, 0.85)

		var splat_size := randf_range(3.0, 8.0) * size * (0.5 + intensity * 0.25)
		blood_splats.append({
			"pos": pos + offset,
			"size": splat_size,
			"color": col,
			"lifetime": 60.0,
			"rotation": randf() * TAU,
			"elongation": randf_range(0.6, 1.4),
			"drip_offset": Vector2(randf_range(-2, 2), randf_range(-2, 2)),
		})

		# Add to persistent gore system if available
		if game_ref and game_ref.has_method("_add_gore_decal"):
			game_ref._add_gore_decal(pos + offset, splat_size * 0.5, col)

	# Cap splats
	while blood_splats.size() > MAX_BLOOD_SPLATS:
		blood_splats.pop_front()

func _decay_blood_splats(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(blood_splats.size()):
		blood_splats[i]["lifetime"] -= delta
		# Fade out in last 10 seconds
		if blood_splats[i]["lifetime"] < 10.0:
			blood_splats[i]["color"].a *= 0.98
		if blood_splats[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		blood_splats.remove_at(idx)

func _draw_blood_splats() -> void:
	for splat in blood_splats:
		var p: Vector2 = splat["pos"]
		var s: float = splat["size"]
		var c: Color = splat["color"]
		var e: float = splat["elongation"]
		# Main splat (ellipse approximated with rect)
		draw_rect(Rect2(p.x - s * e * 0.5, p.y - s * 0.5, s * e, s), c)
		# Smaller secondary drip
		if s > 4.0:
			var drip_off: Vector2 = splat.get("drip_offset", Vector2.ZERO)
			draw_rect(Rect2(p.x + drip_off.x - s * 0.15, p.y + drip_off.y - s * 0.15, s * 0.3, s * 0.3), c * 0.8)

# ===== BLOOD PARTICLES (flying droplets) =====

func spawn_blood_burst(pos: Vector2, direction: Vector2, count: int = 8, force: float = 150.0) -> void:
	if not GameSystems.get_setting("blood_enabled"):
		return
	var intensity: int = GameSystems.get_setting("blood_intensity")
	if intensity == 0:
		return

	var density: int = GameSystems.get_setting("particle_density")
	var actual_count := int(count * (0.5 + density * 0.25) * (0.5 + intensity * 0.25))

	for i in range(actual_count):
		var spread := randf_range(-0.8, 0.8)
		var dir := direction.rotated(spread).normalized()
		var speed := force * randf_range(0.3, 1.2)
		var col: Color = BLOOD_COLORS.pick_random()
		col.a = randf_range(0.7, 1.0)

		blood_particles.append({
			"pos": pos + dir * randf_range(0, 5),
			"vel": dir * speed + Vector2(0, randf_range(-30, -80)),
			"size": randf_range(1.5, 4.0),
			"color": col,
			"lifetime": randf_range(0.3, 0.8),
			"gravity": randf_range(200, 400),
			"leaves_splat": randf() < 0.6,
		})

	while blood_particles.size() > MAX_PARTICLES:
		blood_particles.pop_front()

func _update_blood_particles(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(blood_particles.size()):
		var p := blood_particles[i]
		p["vel"] = Vector2(p["vel"].x * 0.98, p["vel"].y + p["gravity"] * delta)
		p["pos"] += p["vel"] * delta
		p["lifetime"] -= delta
		p["size"] *= 0.97

		if p["lifetime"] <= 0 or p["size"] < 0.3:
			if p["leaves_splat"]:
				spawn_blood_splat(p["pos"], p["size"] * 0.5)
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		blood_particles.remove_at(idx)

func _draw_blood_particles() -> void:
	for p in blood_particles:
		var c: Color = p["color"]
		c.a *= clampf(p["lifetime"] * 3.0, 0, 1)
		draw_rect(Rect2(p["pos"] - Vector2(p["size"] * 0.5, p["size"] * 0.5), Vector2(p["size"], p["size"])), c)

# ===== GORE CHUNKS (big pieces on death) =====

func spawn_gore_explosion(pos: Vector2, enemy_color: Color = Color(0.5, 0.0, 0.0)) -> void:
	if not GameSystems.get_setting("gore_enabled"):
		return
	var intensity: int = GameSystems.get_setting("blood_intensity")
	if intensity < 2:
		return

	var chunk_count := 3 + intensity * 2
	for i in range(chunk_count):
		var dir := Vector2.from_angle(randf() * TAU)
		var speed := randf_range(80, 250)
		gore_chunks.append({
			"pos": pos,
			"vel": dir * speed + Vector2(0, randf_range(-100, -200)),
			"size": randf_range(3.0, 7.0),
			"color": enemy_color.lerp(BLOOD_DARK.pick_random(), randf_range(0.2, 0.6)),
			"lifetime": randf_range(0.5, 1.2),
			"gravity": randf_range(300, 500),
			"rotation": randf() * TAU,
			"rot_speed": randf_range(-8, 8),
		})

	# Big blood burst
	spawn_blood_burst(pos, Vector2.UP, 15 + intensity * 5, 200.0)
	# Ground splat
	spawn_blood_splat(pos, 2.5 + intensity * 0.5)

	while gore_chunks.size() > MAX_GORE:
		gore_chunks.pop_front()

func _update_gore_chunks(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(gore_chunks.size()):
		var g := gore_chunks[i]
		g["vel"].y += g["gravity"] * delta
		g["pos"] += g["vel"] * delta
		g["vel"].x *= 0.95
		g["rotation"] += g["rot_speed"] * delta
		g["lifetime"] -= delta
		if g["lifetime"] <= 0:
			spawn_blood_splat(g["pos"], g["size"] * 0.3)
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		gore_chunks.remove_at(idx)

func _draw_gore_chunks() -> void:
	for g in gore_chunks:
		var c: Color = g["color"]
		c.a = clampf(g["lifetime"] * 2.0, 0, 1)
		var s: float = g["size"]
		draw_rect(Rect2(g["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s * 0.7)), c)
		# Blood trail behind chunks
		var trail_pos: Vector2 = g["pos"] - g["vel"].normalized() * s
		var trail_c := c * 0.6
		trail_c.a = c.a * 0.5
		draw_rect(Rect2(trail_pos - Vector2(1, 1), Vector2(2, 2)), trail_c)

# ===== HIT FLASH (white flash on impact) =====

func spawn_hit_flash(pos: Vector2, size: float = 20.0, color: Color = Color(1, 1, 1, 0.9)) -> void:
	if not GameSystems.get_setting("hit_flash_enabled"):
		return
	hit_flashes.append({
		"pos": pos,
		"size": size,
		"max_size": size * 1.5,
		"color": color,
		"lifetime": 0.12,
		"max_life": 0.12,
	})

func _update_hit_flashes(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(hit_flashes.size()):
		hit_flashes[i]["lifetime"] -= delta
		if hit_flashes[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		hit_flashes.remove_at(idx)

func _draw_hit_flashes() -> void:
	for f in hit_flashes:
		var t: float = 1.0 - (f["lifetime"] / maxf(f["max_life"], 0.001))
		var s: float = lerpf(f["size"], f["max_size"], t)
		var c: Color = f["color"]
		c.a *= (1.0 - t)
		draw_rect(Rect2(f["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)
		# Inner bright core
		var inner_s := s * 0.4
		var inner_c := Color(1, 1, 0.8, c.a * 1.5)
		draw_rect(Rect2(f["pos"] - Vector2(inner_s * 0.5, inner_s * 0.5), Vector2(inner_s, inner_s)), inner_c)

# ===== ATTACK TRAILS (melee swing arcs) =====

func spawn_attack_trail(origin: Vector2, angle: float, arc: float, reach: float, color: Color = Color(1, 1, 1, 0.6)) -> void:
	if not GameSystems.get_setting("trail_effects"):
		return
	attack_trails.append({
		"origin": origin,
		"angle": angle,
		"arc": arc,
		"reach": reach,
		"color": color,
		"lifetime": 0.2,
		"max_life": 0.2,
	})

func _update_attack_trails(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(attack_trails.size()):
		attack_trails[i]["lifetime"] -= delta
		if attack_trails[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		attack_trails.remove_at(idx)

func _draw_attack_trails() -> void:
	for trail in attack_trails:
		var t: float = 1.0 - (trail["lifetime"] / maxf(trail["max_life"], 0.001))
		var c: Color = trail["color"]
		c.a *= (1.0 - t * t)
		var origin: Vector2 = trail["origin"]
		var angle: float = trail["angle"]
		var arc: float = trail["arc"]
		var reach: float = trail["reach"] * (0.8 + t * 0.3)

		# Draw arc segments
		var segments := 8
		var start_angle := angle - arc * 0.5
		for i in range(segments):
			var a1 := start_angle + arc * (float(i) / segments)
			var a2 := start_angle + arc * (float(i + 1) / segments)
			var p1 := origin + Vector2.from_angle(a1) * reach
			var p2 := origin + Vector2.from_angle(a2) * reach
			var inner1 := origin + Vector2.from_angle(a1) * (reach * 0.6)
			var inner2 := origin + Vector2.from_angle(a2) * (reach * 0.6)
			# Outer edge (bright)
			var edge_c := c
			edge_c.a *= 0.8
			draw_line(p1, p2, edge_c, 2.0 * (1.0 - t))
			# Inner fill
			var fill_c := c * 0.5
			fill_c.a = c.a * 0.3
			draw_line(inner1, inner2, fill_c, 1.0)

# ===== IMPACT RINGS (expanding circles on hit) =====

func spawn_impact_ring(pos: Vector2, size: float = 15.0, color: Color = Color(1, 0.8, 0.3, 0.8)) -> void:
	if not GameSystems.get_setting("impact_effects"):
		return
	impact_rings.append({
		"pos": pos,
		"size": size * 0.3,
		"max_size": size,
		"color": color,
		"lifetime": 0.25,
		"max_life": 0.25,
	})

func _update_impact_rings(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(impact_rings.size()):
		impact_rings[i]["lifetime"] -= delta
		if impact_rings[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		impact_rings.remove_at(idx)

func _draw_impact_rings() -> void:
	for ring in impact_rings:
		var t: float = 1.0 - (ring["lifetime"] / maxf(ring["max_life"], 0.001))
		var s: float = lerpf(ring["size"], ring["max_size"], sqrt(t))
		var c: Color = ring["color"]
		c.a *= (1.0 - t * t)
		# Draw square ring approximation
		var half := s * 0.5
		var thickness := maxf(2.0 * (1.0 - t), 0.5)
		draw_rect(Rect2(ring["pos"].x - half, ring["pos"].y - half, s, thickness), c)
		draw_rect(Rect2(ring["pos"].x - half, ring["pos"].y + half - thickness, s, thickness), c)
		draw_rect(Rect2(ring["pos"].x - half, ring["pos"].y - half, thickness, s), c)
		draw_rect(Rect2(ring["pos"].x + half - thickness, ring["pos"].y - half, thickness, s), c)

# ===== FOOTSTEP DUST =====

func spawn_footstep_dust(pos: Vector2) -> void:
	if not GameSystems.get_setting("particles_enabled"):
		return
	for i in range(2):
		footstep_dust.append({
			"pos": pos + Vector2(randf_range(-4, 4), randf_range(-2, 2)),
			"vel": Vector2(randf_range(-15, 15), randf_range(-20, -40)),
			"size": randf_range(1.5, 3.0),
			"color": Color(0.4, 0.35, 0.3, 0.4),
			"lifetime": randf_range(0.2, 0.4),
		})

func _update_footstep_dust(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(footstep_dust.size()):
		footstep_dust[i]["pos"] += footstep_dust[i]["vel"] * delta
		footstep_dust[i]["vel"] *= 0.92
		footstep_dust[i]["lifetime"] -= delta
		footstep_dust[i]["size"] *= 0.97
		if footstep_dust[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		footstep_dust.remove_at(idx)

func _draw_footstep_dust() -> void:
	for d in footstep_dust:
		var c: Color = d["color"]
		c.a *= clampf(d["lifetime"] * 5.0, 0, 1)
		var s: float = d["size"]
		draw_rect(Rect2(d["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

# ===== MUZZLE FLASH =====

func spawn_muzzle_flash(pos: Vector2, direction: Vector2) -> void:
	if not GameSystems.get_setting("hit_flash_enabled"):
		return
	muzzle_flashes.append({
		"pos": pos + direction * 15.0,
		"dir": direction,
		"size": randf_range(10, 18),
		"color": Color(1.0, 0.9, 0.4, 0.9),
		"lifetime": 0.08,
		"max_life": 0.08,
	})

func _update_muzzle_flashes(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(muzzle_flashes.size()):
		muzzle_flashes[i]["lifetime"] -= delta
		if muzzle_flashes[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		muzzle_flashes.remove_at(idx)

func _draw_muzzle_flashes() -> void:
	for m in muzzle_flashes:
		var t: float = 1.0 - (m["lifetime"] / maxf(m["max_life"], 0.001))
		var s: float = m["size"] * (1.0 + t * 0.5)
		var c: Color = m["color"]
		c.a *= (1.0 - t)
		# Core flash
		draw_rect(Rect2(m["pos"] - Vector2(s * 0.3, s * 0.3), Vector2(s * 0.6, s * 0.6)), c)
		# Directional elongation
		var ext: Vector2 = m["dir"] * s * 0.5
		draw_rect(Rect2(m["pos"] + ext - Vector2(s * 0.15, s * 0.15), Vector2(s * 0.3, s * 0.3)), c * 0.7)

# ===== COMBO EFFECTS =====

func spawn_hit_effect(pos: Vector2, damage: float, is_crit: bool, direction: Vector2) -> void:
	# Blood burst in hit direction
	var blood_count := 5 + int(damage * 0.3)
	if is_crit:
		blood_count *= 2
	spawn_blood_burst(pos, direction, blood_count, 100.0 + damage * 2.0)

	# Impact flash
	var flash_size := 15.0 + damage * 0.3
	if is_crit:
		flash_size *= 1.5
		spawn_hit_flash(pos, flash_size, Color(1, 0.9, 0.2, 1.0))
		spawn_impact_ring(pos, flash_size * 1.5, Color(1.0, 0.6, 0.1, 0.8))
	else:
		spawn_hit_flash(pos, flash_size, Color(1, 1, 1, 0.8))
		spawn_impact_ring(pos, flash_size, Color(1.0, 0.8, 0.3, 0.6))

	# Blood splat on ground
	spawn_blood_splat(pos, 0.8 + damage * 0.02)

func spawn_death_effect(pos: Vector2, enemy_color: Color, is_boss: bool = false) -> void:
	if is_boss:
		spawn_gore_explosion(pos, enemy_color)
		spawn_gore_explosion(pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), enemy_color)
		spawn_impact_ring(pos, 60.0, Color(1.0, 0.2, 0.1, 0.9))
		spawn_impact_ring(pos, 40.0, Color(1.0, 0.5, 0.0, 0.7))
	else:
		spawn_gore_explosion(pos, enemy_color)
		spawn_impact_ring(pos, 25.0, Color(0.8, 0.2, 0.1, 0.7))

	# Large blood pool
	spawn_blood_splat(pos, 2.0 if not is_boss else 4.0)

func spawn_player_hit_effect(pos: Vector2, direction: float) -> void:
	var dir := Vector2.from_angle(direction)
	spawn_blood_burst(pos, dir, 4, 80.0)
	spawn_blood_splat(pos, 0.6)

# ===== Improvement #46: LEVEL UP BURST =====

func spawn_level_up_burst(pos: Vector2) -> void:
	for i in range(24):
		var angle := randf() * TAU
		var speed := randf_range(80, 200)
		var col: Color = [Color(0.3, 0.7, 1.0), Color(1.0, 0.9, 0.3), Color(0.4, 1.0, 0.5), Color(1.0, 0.5, 0.8)].pick_random()
		level_up_particles.append({
			"pos": pos,
			"vel": Vector2.from_angle(angle) * speed,
			"size": randf_range(2.0, 5.0),
			"color": col,
			"lifetime": randf_range(0.5, 1.2),
			"gravity": randf_range(-50, 50),
		})
	spawn_impact_ring(pos, 50.0, Color(0.3, 0.7, 1.0, 0.8))
	spawn_impact_ring(pos, 35.0, Color(1.0, 0.9, 0.3, 0.6))

func _update_level_up_particles(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(level_up_particles.size()):
		var p := level_up_particles[i]
		p["vel"] *= 0.96
		p["vel"].y += p["gravity"] * delta
		p["pos"] += p["vel"] * delta
		p["lifetime"] -= delta
		if p["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		level_up_particles.remove_at(idx)

func _draw_level_up_particles() -> void:
	for p in level_up_particles:
		var c: Color = p["color"]
		c.a = clampf(p["lifetime"] * 2.0, 0, 1)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

# ===== Improvement #47: DODGE AFTERIMAGE =====

func spawn_afterimage(pos: Vector2, emoji_text: String, facing_right: bool = true) -> void:
	afterimages.append({
		"pos": pos,
		"text": emoji_text,
		"lifetime": 0.3,
		"max_life": 0.3,
		"flip": not facing_right,
	})

func _update_afterimages(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(afterimages.size()):
		afterimages[i]["lifetime"] -= delta
		if afterimages[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		afterimages.remove_at(idx)

func _draw_afterimages() -> void:
	for img in afterimages:
		var alpha := clampf(img["lifetime"] / img["max_life"], 0, 1) * 0.4
		var c := Color(0.5, 0.8, 1.0, alpha)
		var s := 8.0
		draw_rect(Rect2(img["pos"] - Vector2(s, s), Vector2(s * 2, s * 2)), c)

# ===== Improvement #48: HEALING PARTICLES =====

func spawn_heal_particles(pos: Vector2, amount: float) -> void:
	var count := clampi(int(amount * 0.3), 3, 12)
	for i in range(count):
		heal_particles.append({
			"pos": pos + Vector2(randf_range(-15, 15), randf_range(-5, 5)),
			"vel": Vector2(randf_range(-20, 20), randf_range(-60, -30)),
			"size": randf_range(1.5, 3.5),
			"color": Color(0.2, 1.0, 0.4, 0.8),
			"lifetime": randf_range(0.4, 0.8),
		})

func _update_heal_particles(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(heal_particles.size()):
		heal_particles[i]["pos"] += heal_particles[i]["vel"] * delta
		heal_particles[i]["vel"] *= 0.95
		heal_particles[i]["lifetime"] -= delta
		if heal_particles[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		heal_particles.remove_at(idx)

func _draw_heal_particles() -> void:
	for p in heal_particles:
		var c: Color = p["color"]
		c.a *= clampf(p["lifetime"] * 3.0, 0, 1)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

# ===== Improvement #49: ELEMENTAL HIT EFFECTS =====

func spawn_elemental_hit(pos: Vector2, element: String, direction: Vector2) -> void:
	var col: Color
	var count := 6
	match element:
		"fire":
			col = Color(1.0, 0.5, 0.1, 0.9)
		"ice":
			col = Color(0.4, 0.8, 1.0, 0.9)
		"poison":
			col = Color(0.3, 0.9, 0.2, 0.9)
		"lightning":
			col = Color(1.0, 1.0, 0.3, 0.9)
		_:
			col = Color(0.8, 0.8, 0.8, 0.9)
	for i in range(count):
		var spread := randf_range(-0.5, 0.5)
		var dir := direction.rotated(spread).normalized()
		elemental_particles.append({
			"pos": pos,
			"vel": dir * randf_range(60, 140),
			"size": randf_range(2.0, 4.0),
			"color": col,
			"lifetime": randf_range(0.2, 0.5),
		})
	spawn_impact_ring(pos, 20.0, col)

func _update_elemental_particles(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(elemental_particles.size()):
		elemental_particles[i]["pos"] += elemental_particles[i]["vel"] * delta
		elemental_particles[i]["vel"] *= 0.92
		elemental_particles[i]["lifetime"] -= delta
		if elemental_particles[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		elemental_particles.remove_at(idx)

func _draw_elemental_particles() -> void:
	for p in elemental_particles:
		var c: Color = p["color"]
		c.a *= clampf(p["lifetime"] * 4.0, 0, 1)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

# ===== Improvement #50: SHIELD BREAK SHARDS =====

func spawn_shield_break(pos: Vector2) -> void:
	for i in range(8):
		var angle := randf() * TAU
		shield_shards.append({
			"pos": pos,
			"vel": Vector2.from_angle(angle) * randf_range(60, 150),
			"size": randf_range(2.0, 5.0),
			"color": Color(0.3, 0.5, 1.0, 0.9),
			"lifetime": randf_range(0.3, 0.6),
			"rotation": randf() * TAU,
		})
	spawn_impact_ring(pos, 30.0, Color(0.3, 0.5, 1.0, 0.7))

func _update_shield_shards(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(shield_shards.size()):
		shield_shards[i]["pos"] += shield_shards[i]["vel"] * delta
		shield_shards[i]["vel"] *= 0.9
		shield_shards[i]["lifetime"] -= delta
		if shield_shards[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		shield_shards.remove_at(idx)

func _draw_shield_shards() -> void:
	for s in shield_shards:
		var c: Color = s["color"]
		c.a *= clampf(s["lifetime"] * 3.0, 0, 1)
		var sz: float = s["size"]
		draw_rect(Rect2(s["pos"] - Vector2(sz * 0.5, sz * 0.3), Vector2(sz, sz * 0.6)), c)

# ===== Improvement #51: EXECUTION SLASH =====

func spawn_execution_slash(pos: Vector2, direction: Vector2) -> void:
	execution_slashes.append({
		"pos": pos,
		"dir": direction,
		"length": 60.0,
		"lifetime": 0.3,
		"max_life": 0.3,
		"color": Color(1.0, 0.2, 0.2, 1.0),
	})
	spawn_hit_flash(pos, 30.0, Color(1.0, 0.3, 0.1, 1.0))
	spawn_impact_ring(pos, 40.0, Color(1.0, 0.2, 0.1, 0.9))

func _update_execution_slashes(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(execution_slashes.size()):
		execution_slashes[i]["lifetime"] -= delta
		if execution_slashes[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		execution_slashes.remove_at(idx)

func _draw_execution_slashes() -> void:
	for s in execution_slashes:
		var t: float = 1.0 - (float(s["lifetime"]) / float(s["max_life"]))
		var c: Color = s["color"]
		c.a *= (1.0 - t)
		var half_len: float = float(s["length"]) * (0.5 + t * 0.5)
		var s_pos: Vector2 = s["pos"]
		var s_dir: Vector2 = s["dir"]
		var p1: Vector2 = s_pos - s_dir * half_len
		var p2: Vector2 = s_pos + s_dir * half_len
		draw_line(p1, p2, c, 3.0 * (1.0 - t))
		# Inner bright line
		draw_line(p1, p2, Color(1.0, 1.0, 0.8, c.a * 0.8), 1.5 * (1.0 - t))

# ===== Improvement #52: CHARGE GLOW AURA =====

func spawn_charge_glow(pos: Vector2, intensity: float) -> void:
	charge_glows.append({
		"pos": pos,
		"size": 15.0 + intensity * 20.0,
		"color": Color(1.0, 0.7, 0.2, 0.3 + intensity * 0.4),
		"lifetime": 0.1,
	})

func _update_charge_glows(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(charge_glows.size()):
		charge_glows[i]["lifetime"] -= delta
		if charge_glows[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		charge_glows.remove_at(idx)

func _draw_charge_glows() -> void:
	for g in charge_glows:
		var c: Color = g["color"]
		var s: float = g["size"]
		draw_rect(Rect2(g["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

# ===== Improvement #53: AMBIENT ENVIRONMENT PARTICLES =====

func spawn_ambient_dust(area_center: Vector2, area_size: Vector2) -> void:
	if ambient_particles.size() > MAX_AMBIENT:
		return
	for i in range(3):
		ambient_particles.append({
			"pos": area_center + Vector2(randf_range(-area_size.x * 0.5, area_size.x * 0.5), randf_range(-area_size.y * 0.5, area_size.y * 0.5)),
			"vel": Vector2(randf_range(-5, 5), randf_range(-8, -2)),
			"size": randf_range(0.8, 2.0),
			"color": Color(0.6, 0.5, 0.4, 0.15),
			"lifetime": randf_range(3.0, 8.0),
		})

func _update_ambient_particles(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(ambient_particles.size()):
		ambient_particles[i]["pos"] += ambient_particles[i]["vel"] * delta
		ambient_particles[i]["lifetime"] -= delta
		if ambient_particles[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		ambient_particles.remove_at(idx)

func _draw_ambient_particles() -> void:
	for p in ambient_particles:
		var c: Color = p["color"]
		c.a *= clampf(p["lifetime"] * 0.5, 0, 1)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

# ===== Improvement #54: SCREEN FLASH =====

func trigger_screen_flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	screen_flash_color = color
	screen_flash_timer = duration

# ===== Improvement #55: OVERKILL EXPLOSION =====

func spawn_overkill_explosion(pos: Vector2, overkill_amount: float) -> void:
	var ring_size := 30.0 + overkill_amount * 0.5
	overkill_rings.append({
		"pos": pos,
		"size": ring_size * 0.2,
		"max_size": ring_size,
		"color": Color(1.0, 0.5, 0.1, 0.9),
		"lifetime": 0.4,
		"max_life": 0.4,
	})
	spawn_gore_explosion(pos, Color(0.5, 0.0, 0.0))
	spawn_blood_burst(pos, Vector2.UP, int(overkill_amount * 0.5) + 10, 200.0)

func _update_overkill_rings(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(overkill_rings.size()):
		overkill_rings[i]["lifetime"] -= delta
		if overkill_rings[i]["lifetime"] <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		overkill_rings.remove_at(idx)

func _draw_overkill_rings() -> void:
	for ring in overkill_rings:
		var t: float = 1.0 - (float(ring["lifetime"]) / maxf(float(ring["max_life"]), 0.001))
		var s: float = lerpf(float(ring["size"]), float(ring["max_size"]), sqrt(t))
		var c: Color = ring["color"]
		c.a *= (1.0 - t * t)
		var half: float = s * 0.5
		var thickness: float = maxf(3.0 * (1.0 - t), 1.0)
		var r_pos: Vector2 = ring["pos"]
		draw_rect(Rect2(r_pos.x - half, r_pos.y - half, s, thickness), c)
		draw_rect(Rect2(r_pos.x - half, r_pos.y + half - thickness, s, thickness), c)
		draw_rect(Rect2(r_pos.x - half, r_pos.y - half, thickness, s), c)
		draw_rect(Rect2(r_pos.x + half - thickness, r_pos.y - half, thickness, s), c)
