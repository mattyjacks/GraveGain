extends Node

# Emoji set definitions - each set has a name, description, expected font filename,
# download URL, and license info. Users drop .ttf/.otf files into res://fonts/emoji/
# or user://fonts/emoji/ to enable them.

signal emoji_set_changed(set_id: String)

const EMOJI_SETS: Dictionary = {
	"system": {
		"name": "System Default",
		"desc": "Uses your OS built-in emoji (Segoe UI Emoji, Apple Color Emoji, etc.)",
		"font_file": "",
		"license": "Varies by OS",
		"url": "",
		"icon": "\U0001F4BB",
		"builtin": true,
	},
	"twemoji": {
		"name": "Twemoji",
		"desc": "Twitter/X open-source emoji - flat, colorful, widely recognized",
		"font_file": "Twemoji.Mozilla.ttf",
		"alt_files": ["TwemojiMozilla.ttf", "Twemoji Mozilla.ttf", "twemoji.ttf", "TwitterColorEmoji-SVGinOT.ttf"],
		"license": "CC BY 4.0 / Apache 2.0",
		"url": "https://github.com/mozilla/twemoji-colr/releases",
		"icon": "\U0001F426",
		"builtin": false,
	},
	"noto": {
		"name": "Noto Color Emoji",
		"desc": "Google's emoji font - clean, modern, great coverage",
		"font_file": "NotoColorEmoji.ttf",
		"alt_files": ["NotoColorEmoji-Regular.ttf", "noto-color-emoji.ttf", "NotoColorEmoji_WindowsCompatible.ttf"],
		"license": "Apache 2.0",
		"url": "https://github.com/googlefonts/noto-emoji/releases",
		"icon": "\U0001F310",
		"builtin": false,
	},
	"openmoji": {
		"name": "OpenMoji",
		"desc": "Open-source hand-crafted emoji - unique outlined style",
		"font_file": "OpenMoji-Color.ttf",
		"alt_files": ["OpenMoji-color.ttf", "openmoji-color.ttf", "OpenMojiColor.ttf"],
		"license": "CC BY-SA 4.0",
		"url": "https://github.com/hfg-gmuend/openmoji/releases",
		"icon": "\U0001F603",
		"builtin": false,
	},
	"blobmoji": {
		"name": "Blobmoji",
		"desc": "Google's classic blob-style emoji - round, friendly, nostalgic",
		"font_file": "Blobmoji.ttf",
		"alt_files": ["blobmoji.ttf", "Blobmoji-Regular.ttf"],
		"license": "Apache 2.0",
		"url": "https://github.com/C1710/blobmoji/releases",
		"icon": "\U0001F49B",
		"builtin": false,
	},
	"fluent": {
		"name": "Fluent Emoji",
		"desc": "Microsoft's modern 3D-style emoji - vibrant, detailed",
		"font_file": "FluentSystemEmoji.ttf",
		"alt_files": ["Fluent-Emoji.ttf", "fluent-emoji.ttf", "FluentEmoji.ttf"],
		"license": "MIT",
		"url": "https://github.com/AcmeSoftwareLLC/fluent-emoji-font/releases",
		"icon": "\U0001FA9F",
		"builtin": false,
	},
	"joypixels": {
		"name": "JoyPixels (Free)",
		"desc": "Formerly EmojiOne - polished, professional look",
		"font_file": "joypixels-android.ttf",
		"alt_files": ["JoyPixels.ttf", "joypixels.ttf", "emojione-android.ttf"],
		"license": "Free License (limited)",
		"url": "https://www.joypixels.com/download",
		"icon": "\U0001F389",
		"builtin": false,
	},
	"samsung": {
		"name": "Samsung Emoji",
		"desc": "Samsung's distinctive emoji style",
		"font_file": "SamsungColorEmoji.ttf",
		"alt_files": ["samsung-emoji.ttf", "SamsungEmoji.ttf"],
		"license": "Proprietary (extract from device)",
		"url": "",
		"icon": "\U0001F4F1",
		"builtin": false,
	},
}

var current_set_id: String = "system"
var available_sets: Dictionary = {}
var loaded_fonts: Dictionary = {}
var fallback_fonts: Array[Font] = []

const FONT_SEARCH_PATHS: Array[String] = [
	"res://fonts/emoji/",
	"res://fonts/",
	"user://fonts/emoji/",
	"user://fonts/",
]

const FALLBACK_SET_ORDER: Array[String] = [
	"system", "noto", "twemoji", "openmoji", "fluent", "blobmoji", "joypixels", "samsung"
]

func _ready() -> void:
	_scan_available_sets()
	var saved_val = GameSystems.get_setting("emoji_set")
	var saved_set: String = saved_val if saved_val != null and saved_val is String else "system"
	if saved_set in available_sets or saved_set == "system":
		apply_emoji_set(saved_set)
	else:
		apply_emoji_set("system")

func _scan_available_sets() -> void:
	available_sets.clear()
	available_sets["system"] = true

	for set_id in EMOJI_SETS:
		if set_id == "system":
			continue
		var set_info: Dictionary = EMOJI_SETS[set_id]
		var font_path := _find_font_file(set_info)
		if font_path != "":
			available_sets[set_id] = true
			loaded_fonts[set_id] = font_path

func _find_font_file(set_info: Dictionary) -> String:
	var filenames: Array = [set_info["font_file"]]
	if set_info.has("alt_files"):
		for alt in set_info["alt_files"]:
			filenames.append(alt)

	for search_path in FONT_SEARCH_PATHS:
		for filename in filenames:
			if filename == "":
				continue
			var full_path: String = search_path + filename
			if ResourceLoader.exists(full_path):
				return full_path
			if FileAccess.file_exists(full_path):
				return full_path

	# Also check user:// paths with DirAccess
	for search_path in FONT_SEARCH_PATHS:
		if not search_path.begins_with("user://"):
			continue
		var dir := DirAccess.open(search_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var lower := file_name.to_lower()
				for check_name in filenames:
					if check_name != "" and lower == check_name.to_lower():
						return search_path + file_name
			file_name = dir.get_next()
		dir.list_dir_end()

	return ""

func apply_emoji_set(set_id: String) -> void:
	if set_id == "" or set_id not in EMOJI_SETS:
		set_id = "system"

	current_set_id = set_id
	GameSystems.set_setting("emoji_set", set_id)

	var font: Font
	if set_id == "system":
		font = _create_system_font()
	elif set_id in loaded_fonts:
		var loaded := _load_font_from_path(loaded_fonts[set_id])
		if loaded:
			font = loaded
		else:
			font = _create_system_font()
			current_set_id = "system"
	else:
		font = _create_system_font()
		current_set_id = "system"

	_build_fallback_chain(set_id)
	GameData.emoji_font = font
	
	# Create large variant
	var font_large: Font
	if font is SystemFont:
		var sf_large := SystemFont.new()
		sf_large.font_names = (font as SystemFont).font_names
		sf_large.antialiasing = (font as SystemFont).antialiasing
		sf_large.size = 48
		font_large = sf_large
	else:
		font_large = font
	
	GameData.emoji_font_large = font_large
	emoji_set_changed.emit(current_set_id)

func _build_fallback_chain(primary_set: String) -> void:
	fallback_fonts.clear()
	
	# Add primary set first
	if primary_set == "system":
		fallback_fonts.append(_create_system_font())
	elif primary_set in loaded_fonts:
		var font := _load_font_from_path(loaded_fonts[primary_set])
		if font:
			fallback_fonts.append(font)
	
	# Add fallback sets in order
	for set_id: String in FALLBACK_SET_ORDER:
		if set_id == primary_set or set_id == "system":
			continue
		if set_id in available_sets:
			if set_id in loaded_fonts:
				var font := _load_font_from_path(loaded_fonts[set_id])
				if font:
					fallback_fonts.append(font)
	
	# Always add system font as final fallback
	fallback_fonts.append(_create_system_font())

func get_emoji_with_fallback(emoji: String) -> String:
	# For now, just return the emoji as-is
	# In a real implementation, you would check if the emoji renders
	# and try alternative fonts if it doesn't
	return emoji

func _create_system_font() -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray([
		"Segoe UI Emoji",
		"Apple Color Emoji",
		"Noto Color Emoji",
		"Segoe UI Symbol",
		"DejaVu Sans",
		"Liberation Sans",
		"Ubuntu",
		"Droid Sans",
		"Android Emoji",
		"EmojiOne Color",
		"Emoji",
	])
	sf.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	sf.size = 32
	sf.outline_size = 0
	return sf

func _load_font_from_path(path: String) -> Font:
	if path.begins_with("res://"):
		var res = load(path)
		if res is Font:
			return res
		# Try reading raw bytes for res:// font files
		if FileAccess.file_exists(path):
			var ff := FontFile.new()
			var data := FileAccess.get_file_as_bytes(path)
			if data.size() > 0:
				ff.data = data
				ff.antialiasing = TextServer.FONT_ANTIALIASING_LCD
				return ff

	# user:// or absolute path
	if FileAccess.file_exists(path):
		var ff := FontFile.new()
		var data := FileAccess.get_file_as_bytes(path)
		if data.size() > 0:
			ff.data = data
			ff.antialiasing = TextServer.FONT_ANTIALIASING_LCD
			return ff
	return null

func get_set_info(set_id: String) -> Dictionary:
	return EMOJI_SETS.get(set_id, {})

func get_set_name(set_id: String) -> String:
	var info := get_set_info(set_id)
	return info.get("name", set_id)

func is_set_available(set_id: String) -> bool:
	return set_id in available_sets

func get_all_set_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in EMOJI_SETS:
		ids.append(key)
	return ids

func get_available_set_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in EMOJI_SETS:
		if key in available_sets:
			ids.append(key)
	return ids

func rescan() -> void:
	_scan_available_sets()

func get_install_instructions() -> String:
	var text := "To install emoji fonts, download the .ttf file and place it in:\n"
	text += "  - [project]/fonts/emoji/\n"
	text += "  - or user://fonts/emoji/\n\n"
	text += "Supported emoji font sets:\n"
	for set_id in EMOJI_SETS:
		if set_id == "system":
			continue
		var info: Dictionary = EMOJI_SETS[set_id]
		text += "\n" + info["name"] + " (" + info["license"] + ")\n"
		text += "  File: " + info["font_file"] + "\n"
		if info["url"] != "":
			text += "  URL: " + info["url"] + "\n"
	return text
