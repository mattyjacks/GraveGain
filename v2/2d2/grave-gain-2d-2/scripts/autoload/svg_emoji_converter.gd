extends Node

# SVG Emoji Converter - Converts SVG emoji files to usable textures
# Handles the conversion and caching of emoji textures

const SVG_EMOJI_PATH = "res://fonts/emoji/svg/"
const EMOJI_CACHE_SIZE = 512

var emoji_cache: Dictionary = {}
var svg_available: bool = false

func _ready() -> void:
	_check_svg_files()

func _check_svg_files() -> void:
	var dir = DirAccess.open(SVG_EMOJI_PATH)
	if dir != null:
		svg_available = true
		print("✓ SVG emoji directory found")
	else:
		print("⚠ SVG emoji directory not found")

func get_emoji_texture(emoji: String, size: int = 32) -> Texture2D:
	if not svg_available:
		return null
	
	var cache_key = emoji + "_" + str(size)
	if cache_key in emoji_cache:
		return emoji_cache[cache_key]
	
	# Get SVG file path
	var svg_path = _get_svg_path_for_emoji(emoji)
	if svg_path.is_empty():
		return null
	
	# Try to load the SVG file as a texture
	var texture = load(svg_path) as Texture2D
	if texture:
		emoji_cache[cache_key] = texture
		if emoji_cache.size() > EMOJI_CACHE_SIZE:
			emoji_cache.clear()
		return texture
	
	return null

func _get_svg_path_for_emoji(emoji: String) -> String:
	if emoji.is_empty():
		return ""
	
	# Get codepoint(s) for the emoji
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

func is_available() -> bool:
	return svg_available

func clear_cache() -> void:
	emoji_cache.clear()
