extends Node

# Enemy Conversation System - manages overhearing enemy conversations when unalerted

class_name EnemyConversationSystem

signal conversation_overheard(enemies: Array[Node2D], text: String)

var dialogue_manager: DialogueManager = null
var game_ref: Node = null

var active_conversations: Dictionary = {}
var conversation_cooldown: float = 5.0
var overhear_range: float = 300.0

func _ready() -> void:
	pass

func set_references(dm: DialogueManager, game: Node) -> void:
	dialogue_manager = dm
	game_ref = game

func update_conversations(delta: float, all_enemies: Array[Node2D], player_pos: Vector2) -> void:
	if not dialogue_manager or all_enemies.is_empty():
		return
	
	# Find groups of nearby unalerted enemies
	var enemy_groups = _find_enemy_groups(all_enemies)
	
	for group in enemy_groups:
		if group.is_empty():
			continue
		
		var group_key = _get_group_key(group)
		var current_time = Time.get_ticks_msec() / 1000.0
		var last_time = active_conversations.get(group_key, 0.0)
		
		# Check if conversation is due
		if current_time - last_time < conversation_cooldown:
			continue
		
		# Check if player is in overhear range
		var speaker = group[0]
		var dist_to_player = player_pos.distance_to(speaker.global_position)
		if dist_to_player > overhear_range:
			continue
		
		# Generate and play conversation
		var enemy_type = _get_enemy_type(speaker)
		var text = await dialogue_manager.generate_dialogue("", enemy_type, "conversation")
		
		dialogue_manager.speak(enemy_type, text, enemy_type, speaker.global_position)
		active_conversations[group_key] = current_time
		conversation_overheard.emit(group, text)

func _find_enemy_groups(all_enemies: Array[Node2D]) -> Array[Array]:
	var groups: Array[Array] = []
	var processed: Array[Node2D] = []
	
	for enemy in all_enemies:
		if not is_instance_valid(enemy) or enemy in processed:
			continue
		
		# Check if enemy is alerted
		if enemy.has_method("is_alerted") and enemy.is_alerted():
			continue
		
		var group: Array[Node2D] = [enemy]
		processed.append(enemy)
		
		# Find nearby unalerted enemies of same type
		var enemy_type = _get_enemy_type(enemy)
		for other in all_enemies:
			if not is_instance_valid(other) or other in processed:
				continue
			
			if other.has_method("is_alerted") and other.is_alerted():
				continue
			
			if _get_enemy_type(other) == enemy_type:
				var dist = enemy.global_position.distance_to(other.global_position)
				if dist < 150.0:
					group.append(other)
					processed.append(other)
		
		if group.size() >= 2:
			groups.append(group)
	
	return groups

func _get_group_key(group: Array[Node2D]) -> String:
	var ids: Array[String] = []
	for enemy in group:
		ids.append(str(enemy.get_instance_id()))
	ids.sort()
	return "_".join(ids)

func _get_enemy_type(enemy: Node2D) -> String:
	if enemy.has_meta("enemy_type"):
		return enemy.get_meta("enemy_type")
	
	if enemy.has_method("get_category"):
		return enemy.get_category()
	
	# Fallback to emoji-based detection
	if enemy.has_method("get_emoji"):
		var emoji = enemy.get_emoji()
		if emoji == "👹":
			return "orc"
		elif emoji == "💀":
			return "skeleton"
		elif emoji == "🧟":
			return "zombie"
		else:
			return "goblin"
	
	return "goblin"

func get_overhear_range() -> float:
	return overhear_range

func set_overhear_range(range_val: float) -> void:
	overhear_range = range_val

func set_conversation_cooldown(cooldown: float) -> void:
	conversation_cooldown = cooldown
