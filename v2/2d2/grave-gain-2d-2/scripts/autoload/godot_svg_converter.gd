extends Node

# Godot SVG Converter - Uses Godot's native SVG rendering to convert to PNG
# No external dependencies required

const SVG_EMOJI_PATH = "res://fonts/emoji/svg/"
const PNG_CACHE_DIR = "user://emoji_png_cache/"

var texture_cache: Dictionary = {}

func _ready() -> void:
	_ensure_cache_directory()

func _ensure_cache_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir("emoji_png_cache")

func get_emoji_texture(emoji: String, size: int = 32) -> Texture2D:
	var cache_key = emoji + "_" + str(size)
	
	# Check memory cache first
	if cache_key in texture_cache:
		return texture_cache[cache_key]
	
	# Get SVG path
	var svg_path = _get_svg_path(emoji)
	if svg_path.is_empty():
		return null
	
	# Try to load SVG directly as texture
	var texture = load(svg_path) as Texture2D
	if texture:
		texture_cache[cache_key] = texture
		return texture
	
	# Try to render SVG to image
	texture = _render_svg_to_texture(svg_path, size)
	if texture:
		texture_cache[cache_key] = texture
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

func _render_svg_to_texture(svg_path: String, size: int) -> Texture2D:
	# Load SVG file as text
	var file = FileAccess.open(ProjectSettings.globalize_path(svg_path), FileAccess.READ)
	if file == null:
		return null
	
	var svg_content = file.get_as_text()
	
	# Create an image from the SVG
	var img = Image.new()
	
	# Try to load as SVG texture
	var svg_texture = SVGTexture.new()
	svg_texture.svg_data = svg_content
	
	# Create an image texture from the SVG
	var image_texture = ImageTexture.new()
	
	# Render SVG to image using Godot's rendering
	var viewport = SubViewport.new()
	viewport.size = Vector2i(size, size)
	viewport.transparent_bg = true
	
	var sprite = Sprite2D.new()
	sprite.texture = svg_texture
	sprite.scale = Vector2(size / 64.0, size / 64.0)  # Assume 64x64 base size
	viewport.add_child(sprite)
	
	# Wait a frame for rendering
	await get_tree().process_frame
	
	# Get rendered image
	var rendered_image = viewport.get_texture().get_image()
	viewport.queue_free()
	
	if rendered_image:
		return ImageTexture.create_from_image(rendered_image)
	
	return null

func is_available() -> bool:
	return true

func clear_cache() -> void:
	texture_cache.clear()
