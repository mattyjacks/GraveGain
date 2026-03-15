extends Node

# Advanced Enemy AI - tactical behaviors, formations, and intelligent tactics

class_name AdvancedEnemyAI

# Tactical behaviors
var use_formations: bool = true
var use_flanking: bool = true
var use_retreat: bool = true
var use_coordination: bool = true

# Formation types
var formation_types: Dictionary = {
	"line": {"spacing": 60.0, "depth": 1},
	"wedge": {"spacing": 50.0, "depth": 3},
	"circle": {"spacing": 70.0, "depth": 2},
	"scattered": {"spacing": 40.0, "depth": 1},
}

func apply_tactical_positioning(enemies: Array[Node2D], player_pos: Vector2, formation: String = "wedge") -> void:
	if not use_formations or enemies.is_empty():
		return
	
	var formation_data = formation_types.get(formation, formation_types["wedge"])
	var spacing = formation_data["spacing"]
	var center = _calculate_formation_center(enemies)
	
	match formation:
		"line":
			_apply_line_formation(enemies, player_pos, spacing)
		"wedge":
			_apply_wedge_formation(enemies, player_pos, spacing)
		"circle":
			_apply_circle_formation(enemies, center, spacing)
		"scattered":
			_apply_scattered_formation(enemies, player_pos, spacing)

func _apply_line_formation(enemies: Array[Node2D], player_pos: Vector2, spacing: float) -> void:
	var direction = (player_pos - _calculate_formation_center(enemies)).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	for i in range(enemies.size()):
		var offset = perpendicular * (i - enemies.size() / 2.0) * spacing
		if enemies[i].has_method("set_formation_target"):
			enemies[i].set_formation_target(player_pos + offset)

func _apply_wedge_formation(enemies: Array[Node2D], player_pos: Vector2, spacing: float) -> void:
	var direction = (player_pos - _calculate_formation_center(enemies)).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	var front_enemy = enemies[0]
	if front_enemy.has_method("set_formation_target"):
		front_enemy.set_formation_target(player_pos - direction * 100.0)
	
	for i in range(1, enemies.size()):
		var row = (i / 2) + 1
		var side = 1 if i % 2 == 0 else -1
		var offset = direction * (row * spacing * 0.5) + perpendicular * (side * spacing * 0.5)
		if enemies[i].has_method("set_formation_target"):
			enemies[i].set_formation_target(player_pos + offset)

func _apply_circle_formation(enemies: Array[Node2D], center: Vector2, spacing: float) -> void:
	var radius = spacing * enemies.size() / (2.0 * PI)
	
	for i in range(enemies.size()):
		var angle = (i / float(enemies.size())) * TAU
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		if enemies[i].has_method("set_formation_target"):
			enemies[i].set_formation_target(pos)

func _apply_scattered_formation(enemies: Array[Node2D], player_pos: Vector2, spacing: float) -> void:
	for enemy in enemies:
		var random_offset = Vector2(randf_range(-spacing, spacing), randf_range(-spacing, spacing))
		if enemy.has_method("set_formation_target"):
			enemy.set_formation_target(player_pos + random_offset)

func _calculate_formation_center(enemies: Array[Node2D]) -> Vector2:
	var center = Vector2.ZERO
	for enemy in enemies:
		center += enemy.global_position
	return center / float(enemies.size()) if enemies.size() > 0 else Vector2.ZERO

func calculate_flanking_position(enemy_pos: Vector2, player_pos: Vector2, allies: Array[Node2D]) -> Vector2:
	if not use_flanking:
		return enemy_pos
	
	var direction_to_player = (player_pos - enemy_pos).normalized()
	var perpendicular = Vector2(-direction_to_player.y, direction_to_player.x)
	
	# Check if we should flank left or right
	var ally_count_left = 0
	var ally_count_right = 0
	
	for ally in allies:
		var to_ally = (ally.global_position - enemy_pos).normalized()
		if to_ally.dot(perpendicular) > 0:
			ally_count_right += 1
		else:
			ally_count_left += 1
	
	var flank_dir = perpendicular if ally_count_left > ally_count_right else -perpendicular
	return enemy_pos + flank_dir * 80.0

func should_retreat(enemy_hp: float, enemy_max_hp: float, nearby_allies: int) -> bool:
	if not use_retreat:
		return false
	
	var hp_ratio = enemy_hp / maxf(enemy_max_hp, 1.0)
	var retreat_threshold = 0.2 - (nearby_allies * 0.05)
	
	return hp_ratio < retreat_threshold

func get_tactical_target(enemies: Array[Node2D], player_pos: Vector2) -> Node2D:
	if enemies.is_empty():
		return null
	
	# Prioritize targets: low health enemies, isolated enemies, ranged enemies
	var best_target = enemies[0]
	var best_score = 0.0
	
	for enemy in enemies:
		var score = 0.0
		
		# Low health priority
		if enemy.has_method("get_hp_ratio"):
			score += (1.0 - enemy.get_hp_ratio()) * 100.0
		
		# Isolation priority (far from allies)
		var distance_to_allies = 0.0
		for other in enemies:
			if other != enemy:
				distance_to_allies += enemy.global_position.distance_to(other.global_position)
		score += distance_to_allies * 0.1
		
		if score > best_score:
			best_score = score
			best_target = enemy
	
	return best_target

func coordinate_attack(enemies: Array[Node2D], player_pos: Vector2) -> void:
	if not use_coordination or enemies.size() < 2:
		return
	
	# Synchronize attack timing
	var attack_time = Time.get_ticks_msec() / 1000.0
	var sync_interval = 2.0
	
	for enemy in enemies:
		if enemy.has_method("set_coordinated_attack"):
			var should_attack = fmod(attack_time, sync_interval) < 0.5
			enemy.set_coordinated_attack(should_attack)

func calculate_defensive_position(enemy_pos: Vector2, player_pos: Vector2, allies: Array[Node2D]) -> Vector2:
	# Position behind allies for protection
	var center = _calculate_formation_center(allies)
	var direction_away = (center - player_pos).normalized()
	
	return enemy_pos + direction_away * 50.0
