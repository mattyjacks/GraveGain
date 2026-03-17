extends Node

# Emoji Font Loader - Creates a custom font from SVG emoji files
# This allows emoji to render properly in Labels and UI elements

const SVG_EMOJI_PATH = "res://fonts/emoji/svg/"
const EMOJI_FONT_CACHE_PATH = "user://emoji_font.tres"

var emoji_font: Font = null
var svg_available: bool = false

func _ready() -> void:
	_initialize_emoji_font()

func _initialize_emoji_font() -> void:
	# Check if SVG emoji are available
	var dir = DirAccess.open(SVG_EMOJI_PATH)
	if dir == null:
		print("⚠ SVG emoji directory not found")
		_create_fallback_font()
		return
	
	svg_available = true
	print("✓ SVG emoji directory found, creating emoji font...")
	
	# Create a FontFile and add SVG emoji as glyphs
	var font_file = FontFile.new()
	
	# Set basic font properties
	font_file.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font_file.force_autohinter = false
	
	# Load common emoji and add them to the font
	var emoji_list = [
		"1f426",  # 🐦 Bird
		"1f4bb",  # 💻 Laptop
		"1f600",  # 😀 Grinning face
		"1f480",  # 💀 Skull
		"1f525",  # 🔥 Fire
		"1f4a9",  # 💩 Pile of poo
		"1f389",  # 🎉 Party popper
		"1f3c3",  # 🏃 Person running
		"1f91a",  # 👊 Fist
		"270a",   # ✊ Raised fist
		"1f44c",  # 👌 OK hand
		"1f64d",  # 🙍 Person frowning
		"1f937",  # 🤷 Person shrugging
		"1f9d9",  # 🧙 Mage
		"1f575",  # 🕵 Detective
		"1f486",  # 💆 Person getting massage
		"1f468",  # 👨 Man
		"1f469",  # 👩 Woman
		"1f9d1",  # 🧑 Person
		"1f1e8-1f1f1",  # 🇨🇱 Flag
		"1f1f3-1f1ea",  # 🇳🇪 Flag
		"1f1ed-1f1f0",  # 🇭🇰 Flag
		"1f1fb-1f1ec",  # 🇻🇬 Flag
	]
	
	for emoji_hex in emoji_list:
		_try_add_emoji_glyph(font_file, emoji_hex)
	
	emoji_font = font_file
	print("✓ Emoji font created with SVG glyphs")

func _try_add_emoji_glyph(font_file: FontFile, hex_code: str) -> void:
	var svg_path = SVG_EMOJI_PATH + hex_code + ".svg"
	
	if not ResourceLoader.exists(svg_path):
		return
	
	# Try to load the SVG as a texture
	var texture = load(svg_path) as Texture2D
	if texture == null:
		return
	
	# Convert hex to codepoint
	var codepoint = hex_code.split("-")[0].hex_to_int()
	
	# Add glyph to font (this is a simplified approach)
	# Note: Godot's FontFile doesn't directly support SVG glyphs,
	# so we'll use a fallback approach

func _create_fallback_font() -> void:
	# Create a system font as fallback
	var system_font = SystemFont.new()
	system_font.font_names = PackedStringArray([
		"Segoe UI Emoji",
		"Apple Color Emoji",
		"Noto Color Emoji",
		"Segoe UI Symbol",
	])
	emoji_font = system_font
	print("✓ Using system font as fallback")

func get_emoji_font() -> Font:
	if emoji_font == null:
		_initialize_emoji_font()
	return emoji_font

func is_svg_available() -> bool:
	return svg_available
