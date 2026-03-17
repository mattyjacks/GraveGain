extends Node

# SVG to PNG Converter - Converts SVG emoji to PNG textures at runtime
# Uses system tools (convert/inkscape) to render SVG files as PNG
# Only converts emoji that are actually requested (lazy loading)

const SVG_EMOJI_PATH = "res://fonts/emoji/svg/"
const PNG_CACHE_DIR = "user://emoji_png_cache/"
const EMOJI_CACHE_SIZE = 512

var texture_cache: Dictionary = {}
var converter_available: bool = false
var converter_tool: String = ""
var converted_emojis: Dictionary = {}  # Track which emoji have been converted

func _ready() -> void:
	_check_converter_availability()
	_ensure_cache_directory()

func _check_converter_availability() -> void:
	# Check for ImageMagick convert
	var result = OS.execute("which", ["convert"], [], true)
	if result == 0:
		converter_tool = "convert"
		converter_available = true
		print("✓ ImageMagick convert found")
		return
	
	# Check for Inkscape
	result = OS.execute("which", ["inkscape"], [], true)
	if result == 0:
		converter_tool = "inkscape"
		converter_available = true
		print("✓ Inkscape found")
		return
	
	print("⚠ No SVG converter found (convert or inkscape required)")

func _ensure_cache_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir("emoji_png_cache")

func get_emoji_texture(emoji: String, size: int = 32) -> Texture2D:
	if not converter_available:
		return null
	
	var cache_key = emoji + "_" + str(size)
	
	# Check memory cache first
	if cache_key in texture_cache:
		return texture_cache[cache_key]
	
	# Get SVG path
	var svg_path = _get_svg_path(emoji)
	if svg_path.is_empty():
		return null
	
	# Check if PNG already exists in disk cache
	var png_filename = svg_path.get_file().trim_suffix(".svg") + "_" + str(size) + ".png"
	var png_cache_path = PNG_CACHE_DIR + png_filename
	
	# If PNG exists in cache, load it directly
	if ResourceLoader.exists(png_cache_path):
		var texture = load(png_cache_path) as Texture2D
		if texture:
			texture_cache[cache_key] = texture
			return texture
	
	# Only convert if not already converted (lazy loading)
	if not (emoji in converted_emojis and size in converted_emojis[emoji]):
		var png_path = _convert_svg_to_png(svg_path, size)
		if png_path.is_empty():
			return null
		
		# Track that we've converted this emoji
		if not (emoji in converted_emojis):
			converted_emojis[emoji] = {}
		converted_emojis[emoji][size] = true
	else:
		# Already converted, just load it
		var png_abs = ProjectSettings.globalize_path(png_cache_path)
		if not FileAccess.file_exists(png_abs):
			return null
	
	# Load PNG as texture
	var texture = load(png_cache_path) as Texture2D
	if texture:
		texture_cache[cache_key] = texture
		if texture_cache.size() > EMOJI_CACHE_SIZE:
			texture_cache.clear()
		return texture
	
	return null

func _get_svg_path(emoji: String) -> String:
	if emoji.is_empty():
		return ""
	
	# Get codepoint(s)
	var codepoints: Array[int] = []
	for i in range(emoji.length()):
		var cp = emoji.unicode_at(i)
		if cp > 0:
			codepoints.append(cp)
	
	if codepoints.is_empty():
		return ""
	
	# Try multi-codepoint first
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

func _convert_svg_to_png(svg_path: String, size: int) -> String:
	# Get absolute paths
	var svg_abs = ProjectSettings.globalize_path(svg_path)
	var png_filename = svg_path.get_file().trim_suffix(".svg") + "_" + str(size) + ".png"
	var png_cache_path = PNG_CACHE_DIR + png_filename
	var png_abs = ProjectSettings.globalize_path(png_cache_path)
	
	# Check if already converted
	if ResourceLoader.exists(png_cache_path):
		return png_cache_path
	
	# Convert using available tool
	if converter_tool == "convert":
		_convert_with_imagemagick(svg_abs, png_abs, size)
	elif converter_tool == "inkscape":
		_convert_with_inkscape(svg_abs, png_abs, size)
	
	# Verify conversion succeeded
	if FileAccess.file_exists(png_abs):
		return png_cache_path
	
	return ""

func _convert_with_imagemagick(svg_abs: String, png_abs: String, size: int) -> void:
	var args = [
		"-density", "96",
		"-resize", str(size) + "x" + str(size),
		"-background", "none",
		svg_abs,
		png_abs
	]
	var result = OS.execute("convert", args)
	if result != 0:
		print("⚠ ImageMagick conversion failed for " + svg_abs)

func _convert_with_inkscape(svg_abs: String, png_abs: String, size: int) -> void:
	var args = [
		"-w", str(size),
		"-h", str(size),
		svg_abs,
		"-o", png_abs
	]
	var result = OS.execute("inkscape", args)
	if result != 0:
		print("⚠ Inkscape conversion failed for " + svg_abs)

func is_available() -> bool:
	return converter_available

func clear_cache() -> void:
	texture_cache.clear()
	print("✓ Emoji texture cache cleared")
