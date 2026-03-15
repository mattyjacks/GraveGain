extends Node

# Exploration Dialogue System - manages dialogue during exploration and hub areas

class_name ExplorationDialogueSystem

signal player_spoke(text: String)
signal npc_spoke(npc: Node2D, text: String)

var dialogue_manager: DialogueManager = null
var game_ref: Node = null
var player_ref: Node2D = null

var exploration_active: bool = false
var last_dialogue_time: Dictionary = {}
var dialogue_cooldown: float = 3.0

var player_exploration_lines: Array[String] = [
	"What's this?", "Interesting...", "Let's keep moving.", "Stay alert.", "I sense danger.",
	"Hmm, something's off.", "Better be careful.", "This place is eerie.", "I don't like this.",
	"What was that sound?", "Did you hear that?", "Something's watching me.", "I need to move on.",
	"This is getting dangerous.", "I should keep my wits about me.", "Time to move forward.",
	"What lies ahead?", "Let's see what's next.", "I'm ready for anything."
]

var player_hub_lines: Array[String] = [
	"Good to be back.", "Time to resupply.", "Let me check my gear.", "I need to prepare.",
	"What's new?", "Anything interesting?", "Let's see what we have.", "I should rest.",
	"Time to plan my next move.", "I wonder what's out there.", "Let me catch my breath.",
	"This place is safe at least.", "Good to have a moment of peace.", "I need to think."
]

func _ready() -> void:
	pass

func set_references(dm: DialogueManager, game: Node, player: Node2D) -> void:
	dialogue_manager = dm
	game_ref = game
	player_ref = player

func start_exploration() -> void:
	exploration_active = true
	last_dialogue_time.clear()

func end_exploration() -> void:
	exploration_active = false
	last_dialogue_time.clear()

func on_player_explore(location_type: String = "dungeon") -> void:
	if not exploration_active or not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("exploration", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["exploration"] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", "player", "exploration")
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_player_enter_hub() -> void:
	if not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("hub_enter", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["hub_enter"] = current_time
	
	var text = player_hub_lines[randi() % player_hub_lines.size()]
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_player_find_item(item_name: String) -> void:
	if not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("find_item", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["find_item"] = current_time
	
	var lines = [
		"Found %s!" % item_name,
		"What's this? A %s!" % item_name,
		"Interesting, a %s." % item_name,
		"This %s might be useful." % item_name,
		"A %s! I'll take it." % item_name,
	]
	
	var text = lines[randi() % lines.size()]
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_player_discover_secret() -> void:
	if not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("secret", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["secret"] = current_time
	
	var lines = [
		"A secret passage!",
		"What's hidden here?",
		"Interesting discovery!",
		"I found something!",
		"This might be important.",
	]
	
	var text = lines[randi() % lines.size()]
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_npc_greet(npc: Node2D, npc_name: String) -> void:
	if not dialogue_manager:
		return
	
	var npc_id = npc.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("npc_greet_%d" % npc_id, 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["npc_greet_%d" % npc_id] = current_time
	
	var lines = [
		"Welcome back!",
		"Good to see you!",
		"How goes the mission?",
		"Stay safe out there.",
		"Be careful in the depths.",
	]
	
	var text = lines[randi() % lines.size()]
	dialogue_manager.speak(npc_name, text, "npc", npc.global_position)
	npc_spoke.emit(npc, text)

func on_enemy_idle_conversation(enemies: Array[Node2D], enemy_type: String) -> void:
	if not dialogue_manager or enemies.is_empty():
		return
	
	var speaker = enemies[0]
	var speaker_id = speaker.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("idle_conv_%d" % speaker_id, 0.0)
	
	if current_time - last_time < dialogue_cooldown * 3.0:
		return
	
	last_dialogue_time["idle_conv_%d" % speaker_id] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", enemy_type, "conversation")
	dialogue_manager.speak(enemy_type, text, enemy_type, speaker.global_position)
	npc_spoke.emit(speaker, text)

func on_player_low_health() -> void:
	if not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("low_health", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["low_health"] = current_time
	
	var text = await dialogue_manager.generate_dialogue("", "player", "low_health")
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)

func on_player_level_up() -> void:
	if not dialogue_manager or not player_ref:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var last_time = last_dialogue_time.get("level_up", 0.0)
	
	if current_time - last_time < dialogue_cooldown:
		return
	
	last_dialogue_time["level_up"] = current_time
	
	var lines = [
		"I'm getting stronger!",
		"I feel more powerful!",
		"My skills improve!",
		"I'm leveling up!",
		"Power surges through me!",
	]
	
	var text = lines[randi() % lines.size()]
	dialogue_manager.speak("Player", text, "player", player_ref.global_position)
	player_spoke.emit(text)
