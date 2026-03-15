extends Node

# Central mini-game manager
# Handles triggering race-specific mini-games and reward distribution

signal minigame_started(game_type: String)
signal minigame_ended(game_type: String, won: bool, reward: Dictionary)

enum GameType { HUMAN_PHONE, ELF_MIND, DWARF_LOCK, ORC_SLICE }

var player_ref: CharacterBody2D = null
var hud_ref: CanvasLayer = null

var active_minigame: Node = null
var is_minigame_active: bool = false

const HumanPhoneScript = preload("res://scripts/minigames/human_phone.gd")
const ElfMindScript = preload("res://scripts/minigames/elf_mind.gd")
const DwarfLockScript = preload("res://scripts/minigames/dwarf_lock.gd")
const OrcSliceScript = preload("res://scripts/minigames/orc_slice.gd")

func _ready() -> void:
	add_to_group("minigame_manager")

func start_minigame(game_type: GameType) -> void:
	if is_minigame_active or not is_instance_valid(player_ref):
		return

	is_minigame_active = true
	minigame_started.emit(GameType.keys()[game_type])

	var minigame: Node = null
	match game_type:
		GameType.HUMAN_PHONE:
			minigame = Node.new()
			minigame.set_script(HumanPhoneScript)
		GameType.ELF_MIND:
			minigame = Node.new()
			minigame.set_script(ElfMindScript)
		GameType.DWARF_LOCK:
			minigame = Node.new()
			minigame.set_script(DwarfLockScript)
		GameType.ORC_SLICE:
			minigame = Node.new()
			minigame.set_script(OrcSliceScript)

	if minigame:
		minigame.player_ref = player_ref
		minigame.hud_ref = hud_ref
		minigame.minigame_finished.connect(_on_minigame_finished)
		add_child(minigame)
		active_minigame = minigame

func _on_minigame_finished(won: bool, reward: Dictionary) -> void:
	if is_instance_valid(player_ref) and won:
		if reward.get("gold", 0) > 0:
			player_ref.add_gold(reward["gold"])
		if reward.get("xp", 0) > 0:
			player_ref.add_xp(reward["xp"])
		if hud_ref and hud_ref.has_method("show_notification"):
			hud_ref.show_notification("Mini-game won! +" + str(reward.get("gold", 0)) + " gold, +" + str(reward.get("xp", 0)) + " XP", Color(0.8, 1.0, 0.6))

	var game_name: String = GameType.keys()[active_minigame.game_type] if is_instance_valid(active_minigame) else "Unknown"
	minigame_ended.emit(game_name, won, reward)

	if is_instance_valid(active_minigame):
		active_minigame.queue_free()
	active_minigame = null
	is_minigame_active = false

func get_minigame_for_race(race: int) -> GameType:
	match race:
		0:  # Human
			return GameType.HUMAN_PHONE
		1:  # Elf
			return GameType.ELF_MIND
		2:  # Dwarf
			return GameType.DWARF_LOCK
		3:  # Orc
			return GameType.ORC_SLICE
		_:
			return GameType.HUMAN_PHONE
