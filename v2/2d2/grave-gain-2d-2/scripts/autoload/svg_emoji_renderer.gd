extends Node

# Emoji Renderer - Renders emoji from PNG files
# Maps Unicode codepoints to PNG files and loads them as Texture2D

const PNG_EMOJI_PATH = "res://fonts/emoji/png/"
const SVG_EMOJI_PATH = "res://fonts/emoji/svg/"
const EMOJI_CACHE_SIZE = 256

var emoji_cache: Dictionary = {}
var png_files_available: bool = false

func _ready() -> void:
	_check_png_availability()

func _check_png_availability() -> void:
	var dir = DirAccess.open(PNG_EMOJI_PATH)
	if dir != null:
		png_files_available = true
		var count = get_available_emoji_count()
		print("✓ PNG emoji directory found at " + PNG_EMOJI_PATH)
		print("  Available emoji: " + str(count))
	else:
		print("⚠ PNG emoji directory not found at " + PNG_EMOJI_PATH)
		print("  Checked path: " + SVG_EMOJI_PATH)

func unicode_to_hex(codepoint: int) -> String:
	return "%x" % codepoint

func emoji_char_to_codepoint(emoji_char: String) -> int:
	if emoji_char.is_empty():
		return 0
	return emoji_char.unicode_at(0)

func get_emoji_path(emoji: String) -> String:
	if emoji.is_empty() or not png_files_available:
		return ""
	
	# Build list of significant codepoints (strip FE0F, 200D, etc.)
	var codepoints: Array[int] = []
	for i in range(emoji.length()):
		var cp = emoji.unicode_at(i)
		if cp == 0xFE0F or cp == 0xFE0E or cp == 0x200D or cp == 0x200C or cp <= 0:
			continue
		codepoints.append(cp)
	
	if codepoints.is_empty():
		return ""
	
	# Try full multi-codepoint path first (e.g. 1f469-1f680.png)
	if codepoints.size() > 1:
		var hex_parts: Array[String] = []
		for cp in codepoints:
			hex_parts.append(unicode_to_hex(cp))
		var multi_path = PNG_EMOJI_PATH + "-".join(hex_parts) + ".png"
		if ResourceLoader.exists(multi_path):
			return multi_path
	
	# Try first codepoint only (base emoji)
	var hex_code = unicode_to_hex(codepoints[0])
	var png_path = PNG_EMOJI_PATH + hex_code + ".png"
	if ResourceLoader.exists(png_path):
		return png_path
	
	# Try with zero-padded hex
	png_path = PNG_EMOJI_PATH + hex_code.pad_zeros(4) + ".png"
	if ResourceLoader.exists(png_path):
		return png_path
	
	return ""

func _get_multi_codepoint_hex(emoji: String) -> String:
	# Build hex string from all codepoints, stripping variation selectors and ZWJ
	var hex_parts: Array[String] = []
	for i in range(emoji.length()):
		var cp = emoji.unicode_at(i)
		# Skip variation selectors (FE0F, FE0E) and ZWJ (200D)
		if cp == 0xFE0F or cp == 0xFE0E or cp == 0x200D or cp == 0x200C or cp <= 0:
			continue
		hex_parts.append(unicode_to_hex(cp))
	
	if hex_parts.size() <= 1:
		return ""
	
	return "-".join(hex_parts)

func load_emoji_texture(emoji: String, size: int = 32) -> Texture2D:
	if not png_files_available:
		return null
	
	var cache_key = emoji + "_" + str(size)
	if cache_key in emoji_cache:
		return emoji_cache[cache_key]
	
	var png_path = get_emoji_path(emoji)
	if png_path.is_empty():
		return null
	
	# Load PNG file as texture
	var texture = load(png_path) as Texture2D
	if texture:
		emoji_cache[cache_key] = texture
		if emoji_cache.size() > EMOJI_CACHE_SIZE:
			emoji_cache.clear()
		return texture
	
	return null


func is_svg_emoji_available() -> bool:
	return png_files_available

func get_available_emoji_count() -> int:
	if not png_files_available:
		return 0
	
	var dir = DirAccess.open(PNG_EMOJI_PATH)
	if dir == null:
		return 0
	
	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png"):
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return count

func clear_cache() -> void:
	emoji_cache.clear()
	print("✓ SVG emoji cache cleared")

func create_emoji_texture_rect(emoji: String, size: int = 32) -> TextureRect:
	var rect = TextureRect.new()
	var texture = load_emoji_texture(emoji, size)
	
	if texture:
		rect.texture = texture
		rect.custom_minimum_size = Vector2(size, size)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		# Fallback: create a label with the emoji character
		var label = Label.new()
		label.text = emoji
		label.custom_minimum_size = Vector2(size, size)
		var ls = LabelSettings.new()
		ls.font_size = size
		label.label_settings = ls
		return label
	
	return rect

func replace_emoji_in_label(label: Label, size: int = 32) -> Control:
	var text = label.text
	if text.is_empty():
		return label
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)
	
	for i in range(text.length()):
		var char = text[i]
		var texture = load_emoji_texture(char, size)
		
		if texture:
			var rect = TextureRect.new()
			rect.texture = texture
			rect.custom_minimum_size = Vector2(size, size)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(rect)
		else:
			var lbl = Label.new()
			lbl.text = char
			lbl.custom_minimum_size = Vector2(size, size)
			if label.label_settings:
				lbl.label_settings = label.label_settings
			else:
				var ls = LabelSettings.new()
				ls.font_size = size
				lbl.label_settings = ls
			container.add_child(lbl)
	
	return container

func print_status() -> void:
	print("\n=== PNG Emoji Renderer Status ===")
	print("Available: " + ("✓ Yes" if png_files_available else "✗ No"))
	if png_files_available:
		print("Emoji Count: " + str(get_available_emoji_count()))
		print("Cache Size: " + str(emoji_cache.size()))
	print("==================================\n")
