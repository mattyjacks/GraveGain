extends Node

# Emoji SVG Font - Creates a working font from SVG emoji files
# Uses a fallback approach: render emoji as TextureRect nodes instead of text

const SVG_EMOJI_PATH = "res://fonts/emoji/svg/"

var emoji_textures: Dictionary = {}
var svg_available: bool = false

func _ready() -> void:
	_check_availability()

func _check_availability() -> void:
	var dir = DirAccess.open(SVG_EMOJI_PATH)
	svg_available = (dir != null)
	if svg_available:
		print("✓ Emoji SVG font initialized")
	else:
		print("⚠ SVG emoji directory not found")

func is_available() -> bool:
	return svg_available

func get_emoji_as_texture(emoji: String, size: int = 32) -> Texture2D:
	if not svg_available:
		return null
	
	var cache_key = emoji + "_" + str(size)
	if cache_key in emoji_textures:
		return emoji_textures[cache_key]
	
	# Get the SVG path for this emoji
	var svg_path = _get_svg_path(emoji)
	if svg_path.is_empty():
		return null
	
	# Load the SVG file
	var texture = load(svg_path) as Texture2D
	if texture:
		emoji_textures[cache_key] = texture
		return texture
	
	return null

func _get_svg_path(emoji: String) -> String:
	if emoji.is_empty():
		return ""
	
	# Get all codepoints in the emoji
	var codepoints: Array[int] = []
	for i in range(emoji.length()):
		var cp = emoji.unicode_at(i)
		if cp > 0:
			codepoints.append(cp)
	
	if codepoints.is_empty():
		return ""
	
	# Try multi-codepoint sequence first
	if codepoints.size() > 1:
		var hex_parts: Array[String] = []
		for cp in codepoints:
			hex_parts.append("%x" % cp)
		var multi_hex = "-".join(hex_parts)
		var path = SVG_EMOJI_PATH + multi_hex + ".svg"
		if ResourceLoader.exists(path):
			return path
	
	# Try single codepoint
	var hex = "%x" % codepoints[0]
	var path = SVG_EMOJI_PATH + hex + ".svg"
	if ResourceLoader.exists(path):
		return path
	
	# Try with padding
	path = SVG_EMOJI_PATH + hex.pad_zeros(4) + ".svg"
	if ResourceLoader.exists(path):
		return path
	
	return ""

func render_emoji_text(text: String, font_size: int = 32) -> Control:
	# Create a container that renders emoji as textures
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)
	
	for i in range(text.length()):
		var char = text[i]
		var texture = get_emoji_as_texture(char, font_size)
		
		if texture:
			# Render as texture
			var rect = TextureRect.new()
			rect.texture = texture
			rect.custom_minimum_size = Vector2(font_size, font_size)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(rect)
		else:
			# Fallback to label
			var label = Label.new()
			label.text = char
			label.custom_minimum_size = Vector2(font_size, font_size)
			var ls = LabelSettings.new()
			ls.font_size = font_size
			label.label_settings = ls
			container.add_child(label)
	
	return container

func clear_cache() -> void:
	emoji_textures.clear()
	print("✓ Emoji texture cache cleared")
