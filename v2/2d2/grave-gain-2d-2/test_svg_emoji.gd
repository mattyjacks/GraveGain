extends Node

func _ready() -> void:
	print("\n=== SVG Emoji Test ===")
	
	# Test 1: Check if SvgEmojiRenderer is available
	print("\n1. Checking SvgEmojiRenderer availability...")
	if SvgEmojiRenderer:
		print("✓ SvgEmojiRenderer is available")
		print("  SVG available: " + str(SvgEmojiRenderer.is_svg_emoji_available()))
		print("  Emoji count: " + str(SvgEmojiRenderer.get_available_emoji_count()))
	else:
		print("✗ SvgEmojiRenderer not found")
	
	# Test 2: Try loading a specific emoji
	print("\n2. Testing emoji texture loading...")
	var test_emojis = ["🐦", "💻", "😀", "🔥"]
	for emoji in test_emojis:
		print("\n  Testing: " + emoji)
		var texture = SvgEmojiRenderer.load_emoji_texture(emoji, 32)
		if texture:
			print("    ✓ Loaded: " + texture.get_class())
		else:
			print("    ✗ Failed to load")
	
	# Test 3: Check file paths
	print("\n3. Checking SVG file paths...")
	var test_paths = [
		"res://fonts/emoji/svg/1f426.svg",
		"res://fonts/emoji/svg/1f4bb.svg",
		"res://fonts/emoji/svg/1f600.svg",
	]
	for path in test_paths:
		var exists = ResourceLoader.exists(path)
		print("  " + path + ": " + ("✓" if exists else "✗"))
	
	print("\n=== End Test ===\n")
