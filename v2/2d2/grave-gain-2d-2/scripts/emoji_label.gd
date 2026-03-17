extends Control

class_name EmojiLabel

var text: String = ""
var font_size: int = 32
var horizontal_alignment: int = HORIZONTAL_ALIGNMENT_LEFT
var vertical_alignment: int = VERTICAL_ALIGNMENT_TOP
var modulate_color: Color = Color.WHITE
var label_settings: LabelSettings = null

var _container: HBoxContainer = null
var _emoji_nodes: Array = []

func _ready() -> void:
	_container = HBoxContainer.new()
	_container.add_theme_constant_override("separation", 0)
	add_child(_container)
	_update_display()

func _update_display() -> void:
	# Clear existing emoji nodes
	for node in _emoji_nodes:
		node.queue_free()
	_emoji_nodes.clear()
	_container.clear()
	
	if text.is_empty():
		return
	
	# Try to render each character as SVG emoji
	for i in range(text.length()):
		var char = text[i]
		var texture = SvgEmojiRenderer.load_emoji_texture(char, font_size)
		
		if texture:
			# Render as texture
			var emoji_rect = TextureRect.new()
			emoji_rect.texture = texture
			emoji_rect.custom_minimum_size = Vector2(font_size, font_size)
			emoji_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			emoji_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			emoji_rect.modulate = modulate_color
			_container.add_child(emoji_rect)
			_emoji_nodes.append(emoji_rect)
		else:
			# Fallback to text rendering
			var label = Label.new()
			label.text = char
			label.custom_minimum_size = Vector2(font_size, font_size)
			if label_settings:
				label.label_settings = label_settings
			else:
				var ls = LabelSettings.new()
				ls.font_size = font_size
				ls.font_color = modulate_color
				label.label_settings = ls
			_container.add_child(label)
			_emoji_nodes.append(label)
	
	# Apply alignment
	_container.alignment = horizontal_alignment

func set_text(new_text: String) -> void:
	text = new_text
	_update_display()

func set_font_size(size: int) -> void:
	font_size = size
	_update_display()

func set_modulate(color: Color) -> void:
	modulate_color = color
	for node in _emoji_nodes:
		node.modulate = color
