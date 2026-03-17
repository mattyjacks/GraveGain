extends Node

# SVG Font Builder - Creates a Godot Font that renders emoji from SVG files
# This allows emoji to be rendered in regular Labels using the font system

var svg_font: Font = null
var emoji_textures: Dictionary = {}

func _ready() -> void:
	_build_svg_font()

func _build_svg_font() -> void:
	if not SvgEmojiRenderer.is_svg_emoji_available():
		print("⚠ SVG emoji not available, skipping font build")
		return
	
	# Create a FontVariation that we'll use as fallback
	var font_var = FontVariation.new()
	var system_font = SystemFont.new()
	system_font.font_names = PackedStringArray([
		"Segoe UI Emoji",
		"Apple Color Emoji",
		"Noto Color Emoji",
		"Segoe UI Symbol",
	])
	font_var.base_font = system_font
	svg_font = font_var
	
	print("✓ SVG font builder initialized")

func get_svg_font() -> Font:
	if svg_font == null:
		_build_svg_font()
	return svg_font

func preload_emoji(emoji_list: Array[String]) -> void:
	for emoji in emoji_list:
		var texture = SvgEmojiRenderer.load_emoji_texture(emoji, 64)
		if texture:
			emoji_textures[emoji] = texture

func get_emoji_texture(emoji: String, size: int = 32) -> Texture2D:
	var cache_key = emoji + "_" + str(size)
	if cache_key in emoji_textures:
		return emoji_textures[cache_key]
	
	var texture = SvgEmojiRenderer.load_emoji_texture(emoji, size)
	if texture:
		emoji_textures[cache_key] = texture
	return texture

func clear_emoji_cache() -> void:
	emoji_textures.clear()
	SvgEmojiRenderer.clear_cache()
	print("✓ SVG font cache cleared")
