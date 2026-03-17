extends Node

# Emoji Renderer Helper - Converts emoji text to SVG texture rendering
# Replaces text-based emoji rendering with texture-based rendering

static func create_emoji_display(emoji_char: String, size: int = 32, shadow: bool = false) -> Control:
	var texture = SvgEmojiRenderer.load_emoji_texture(emoji_char, size)
	
	if texture:
		var rect = TextureRect.new()
		rect.texture = texture
		rect.custom_minimum_size = Vector2(size, size)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if shadow:
			rect.modulate = Color(0, 0, 0, 0.4)
		return rect
	else:
		# Fallback to label
		var label = Label.new()
		label.text = emoji_char
		label.custom_minimum_size = Vector2(size, size)
		var ls = LabelSettings.new()
		ls.font_size = size
		if shadow:
			ls.font_color = Color(0, 0, 0, 0.4)
		label.label_settings = ls
		return label

static func create_emoji_container(text: String, size: int = 32) -> Control:
	if text.is_empty():
		return Control.new()
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)
	
	for i in range(text.length()):
		var char = text[i]
		var display = create_emoji_display(char, size)
		container.add_child(display)
	
	return container

static func replace_label_emoji(label: Label, size: int = 32) -> Control:
	var text = label.text
	if text.is_empty():
		return label
	
	# If SVG emoji not available, return original label
	if not SvgEmojiRenderer.is_svg_emoji_available():
		return label
	
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)
	
	for i in range(text.length()):
		var char = text[i]
		var texture = SvgEmojiRenderer.load_emoji_texture(char, size)
		
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
