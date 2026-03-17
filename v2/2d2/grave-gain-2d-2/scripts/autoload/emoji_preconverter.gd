extends Node

# Emoji Preconverter - Pre-converts common emoji used in the game
# Extracts emoji from game data and converts them at startup

const EMOJI_SIZES = [16, 18, 20, 24, 32]

var emoji_to_convert: Array[String] = []
var conversion_in_progress: bool = false

func _ready() -> void:
	_extract_emoji_from_game_data()
	_start_preconversion()

func _extract_emoji_from_game_data() -> void:
	var emoji_set: Dictionary = {}
	
	# Extract from race_stats
	for race_id in GameData.race_stats:
		var emoji = GameData.race_stats[race_id].get("emoji", "")
		if emoji:
			emoji_set[emoji] = true
	
	# Extract from class_emojis
	for class_id in GameData.class_emojis:
		var emoji = GameData.class_emojis[class_id]
		if emoji:
			emoji_set[emoji] = true
	
	# Extract from enemy_stats
	for enemy_id in GameData.enemy_stats:
		var emoji = GameData.enemy_stats[enemy_id].get("emoji", "")
		if emoji:
			emoji_set[emoji] = true
	
	# Extract from food_defs
	for food_id in GameData.food_defs:
		var emoji = GameData.food_defs[food_id].get("emoji", "")
		if emoji:
			emoji_set[emoji] = true
	
	# Extract from item_defs
	for item_id in GameData.item_defs:
		var emoji = GameData.item_defs[item_id].get("emoji", "")
		if emoji:
			emoji_set[emoji] = true
	
	# Add common UI emoji
	emoji_set["🔥"] = true  # Torch
	emoji_set["💌"] = true  # Envelope
	emoji_set["⚡"] = true  # Speed boost
	emoji_set["⚔️"] = true  # Damage boost
	emoji_set["🛡️"] = true  # Shield
	emoji_set["💥"] = true  # Rage
	emoji_set["❤️"] = true  # Health
	emoji_set["💰"] = true  # Gold
	emoji_set["⭐"] = true  # XP
	
	# Convert to array
	for emoji in emoji_set:
		emoji_to_convert.append(emoji)
	
	print("📦 Found " + str(emoji_to_convert.size()) + " unique emoji to pre-convert")

func _start_preconversion() -> void:
	if emoji_to_convert.is_empty():
		print("✓ No emoji to pre-convert")
		return
	
	conversion_in_progress = true
	print("🔄 Starting emoji pre-conversion...")
	
	# Convert emoji in batches
	var converter = get_node_or_null("/root/SvgToPngConverter")
	if not converter or not converter.is_available():
		print("⚠ Converter not available, skipping pre-conversion")
		conversion_in_progress = false
		return
	
	var converted_count = 0
	for emoji in emoji_to_convert:
		for size in EMOJI_SIZES:
			var texture = converter.get_emoji_texture(emoji, size)
			if texture:
				converted_count += 1
	
	conversion_in_progress = false
	print("✓ Pre-converted " + str(converted_count) + " emoji textures")

func is_ready() -> bool:
	return not conversion_in_progress
