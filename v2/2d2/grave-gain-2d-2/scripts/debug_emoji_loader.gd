extends Node

# Debug script to test SVG emoji loading

func _ready() -> void:
	print("\n=== SVG Emoji Loading Debug ===")
	_test_svg_loading()
	_test_emoji_rendering()
	print("================================\n")

func _test_svg_loading() -> void:
	print("Testing SVG file loading...")
	
	var test_paths = [
		"res://fonts/emoji/svg/1f426.svg",
		"res://fonts/emoji/svg/1f4bb.svg",
		"res://fonts/emoji/svg/1f600.svg",
	]
	
	for path in test_paths:
		print("  Checking: " + path)
		if ResourceLoader.exists(path):
			print("    ✓ ResourceLoader.exists() = true")
			var texture = load(path)
			if texture:
				print("    ✓ load() successful, type: " + texture.get_class())
			else:
				print("    ✗ load() returned null")
		else:
			print("    ✗ ResourceLoader.exists() = false")

func _test_emoji_rendering() -> void:
	print("\nTesting emoji rendering...")
	
	if not SvgEmojiRenderer.is_svg_emoji_available():
		print("  ✗ SVG emoji not available")
		return
	
	print("  ✓ SVG emoji available")
	print("  Available emoji count: " + str(SvgEmojiRenderer.get_available_emoji_count()))
	
	# Test loading specific emoji
	var test_emoji = ["🐦", "💻", "😀"]
	for emoji in test_emoji:
		var texture = SvgEmojiRenderer.load_emoji_texture(emoji, 32)
		if texture:
			print("  ✓ Loaded emoji: " + emoji + " -> " + texture.get_class())
		else:
			print("  ✗ Failed to load emoji: " + emoji)
