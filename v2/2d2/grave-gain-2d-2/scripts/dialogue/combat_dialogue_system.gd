extends Node

# Combat Dialogue System - manages dialogue during combat encounters

class_name CombatDialogueSystem

signal player_spoke(text: String)
signal enemy_spoke(enemy: Node2D, text: String)

var dialogue_manager: DialogueManager = null
var game_ref: Node = null
var player_ref: Node2D = null

var combat_active: bool = false
var last_dialogue_time: Dictionary = {}
var dialogue_cooldown: float = 2.0

var player_combat_lines: Array[String] = [
	"Take this!", "Hyah!", "Got you!", "Not today!", "Come on!",
	"Feel my blade!", "Taste steel!", "You're done!", "Here I come!",
	"Gotta be faster!", "Almost!", "Missed!", "Darn!", "That hurt!",
	"I'm still standing!", "Victory!", "One down!", "Excellent!", "Too easy!"
]

func _ready() -> void:
	pass

func set_references(dm: DialogueManager, game: Node, player: Node2D) -> void:
	dialogue_manager = dm
	game_ref = game
	player_ref = player

func start_combat() -> void:
	combat_active = true
	last_dialogue_time.clear()

func end_combat() -> void:
	combat_active = false
	last_dialogue_time.clear()

func on_player_attack(position: Vector2, damage: float, is_crit: bool) -> void:
	if not combat_active or not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("player", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["player"] = current_time
	
	var situation = "combat_hit"
	if is_crit:
		situation = "combat_crit"
	
	var text = await dialogue_manager.generate_dialogue("", "player", situation)
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_player_take_damage(amount: float, from_pos: Vector2) -> void:
	if not combat_active or not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("player_damage", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["player_damage"] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", "player", "combat_take_damage")
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_player_kill(enemy: Node2D) -> void:
	if not combat_active or not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("player_kill", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["player_kill"] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", "player", "combat_kill")
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_enemy_alert(enemy: Node2D, enemy_type: String) -> void:
	if not dialogue_manager:
		return
	
	var enemy_id = enemy.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("enemy_%d" % enemy_id, 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["enemy_%d" % enemy_id] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", enemy_type, "combat_alert")
	dialogue_manager.speak(enemy_type, text, enemy_type, enemy.global_position)
	enemy_spoke.emit(enemy, text)

func on_enemy_attack(enemy: Node2D, enemy_type: String) -> void:
	if not dialogue_manager:
		return
	
	var enemy_id = enemy.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("enemy_attack_%d" % enemy_id, 0.0)
	
	if current_time - last_time < dialogue_cooldown * 1.5:
		return
	
	last_dialogue_time["enemy_attack_%d" % enemy_id] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", enemy_type, "combat_hit")
	dialogue_manager.speak(enemy_type, text, enemy_type, enemy.global_position)
	enemy_spoke.emit(enemy, text)

func on_enemy_take_damage(enemy: Node2D, enemy_type: String, damage: float) -> void:
	if not dialogue_manager:
		return
	
	var enemy_id = enemy.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("enemy_damage_%d" % enemy_id, 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["enemy_damage_%d" % enemy_id] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", enemy_type, "combat_take_damage")
	dialogue_manager.speak(enemy_type, text, enemy_type, enemy.global_position)
	enemy_spoke.emit(enemy, text)

func on_enemy_conversation(enemies: Array[Node2D], enemy_type: String) -> void:
	if not dialogue_manager or enemies.is_empty():
		return
	
	var speaker = enemies[0]
	var speaker_id = speaker.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("conv_%d" % speaker_id, 0.0)
	
	if current_time - last_time < dialogue_cooldown * 2.0:
		return
	
	last_dialogue_time["conv_%d" % speaker_id] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", enemy_type, "conversation")
	dialogue_manager.speak(enemy_type, text, enemy_type, speaker.global_position)
	enemy_spoke.emit(speaker, text)

func is_dialogue_cooldown_ready(key: String) -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get(key, 0.0)
	return current_time - last_time >= dialogue_cooldown
