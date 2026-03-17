extends Node

# Emoji Extractor - Extracts all emoji from game data and lists them

func _ready() -> void:
	var emoji_set: Dictionary = {}
	
	print("\n=== Extracting All Game Emoji ===\n")
	
	# Extract from race_stats
	print("Races:")
	for race_id in GameData.race_stats:
		var emoji = GameData.race_stats[race_id].get("emoji", "")
		var name = GameData.race_stats[race_id].get("name", "Unknown")
		if emoji:
			emoji_set[emoji] = name
			print("  " + emoji + " - " + name)
	
	# Extract from class_emojis
	print("\nClasses:")
	for class_id in GameData.class_emojis:
		var emoji = GameData.class_emojis[class_id]
		var class_names_dict = GameData.class_names
		var name = "Class " + str(class_id)
		if emoji:
			emoji_set[emoji] = name
			print("  " + emoji + " - " + name)
	
	# Extract from enemy_stats
	print("\nEnemies:")
	for enemy_id in GameData.enemy_stats:
		var emoji = GameData.enemy_stats[enemy_id].get("emoji", "")
		var name = GameData.enemy_stats[enemy_id].get("name", "Unknown")
		if emoji:
			if not (emoji in emoji_set):
				emoji_set[emoji] = name
			print("  " + emoji + " - " + name)
	
	# Extract from food_defs
	print("\nFood:")
	for food_id in GameData.food_defs:
		var emoji = GameData.food_defs[food_id].get("emoji", "")
		var name = GameData.food_defs[food_id].get("name", "Unknown")
		if emoji:
			if not (emoji in emoji_set):
				emoji_set[emoji] = name
			print("  " + emoji + " - " + name)
	
	# Extract from item_defs
	print("\nItems:")
	for item_id in GameData.item_defs:
		var emoji = GameData.item_defs[item_id].get("emoji", "")
		var name = GameData.item_defs[item_id].get("name", "Unknown")
		if emoji:
			if not (emoji in emoji_set):
				emoji_set[emoji] = name
			print("  " + emoji + " - " + name)
	
	# Add common UI emoji
	print("\nUI:")
	var ui_emoji = {
		"🔥": "Torch",
		"💌": "Envelope",
		"⚡": "Speed Boost",
		"⚔️": "Damage Boost",
		"🛡️": "Shield",
		"💥": "Rage",
		"❤️": "Health",
		"💰": "Gold",
		"⭐": "XP",
	}
	for emoji in ui_emoji:
		if not (emoji in emoji_set):
			emoji_set[emoji] = ui_emoji[emoji]
		print("  " + emoji + " - " + ui_emoji[emoji])
	
	print("\n=== Total Unique Emoji: " + str(emoji_set.size()) + " ===\n")
	
	# Print as list for conversion
	print("Emoji to convert (in order):")
	var emoji_list: Array[String] = []
	for emoji in emoji_set:
		emoji_list.append(emoji)
	
	for i in range(emoji_list.size()):
		var emoji = emoji_list[i]
		var hex = _emoji_to_hex(emoji)
		print(str(i+1) + ". " + emoji + " -> " + hex + ".svg")
	
	print("\n=== End Extraction ===\n")

func _emoji_to_hex(emoji: String) -> String:
	var hex_parts: Array[String] = []
	for i in range(emoji.length()):
		var cp = emoji.unicode_at(i)
		if cp > 0:
			hex_parts.append("%x" % cp)
	return "-".join(hex_parts)
