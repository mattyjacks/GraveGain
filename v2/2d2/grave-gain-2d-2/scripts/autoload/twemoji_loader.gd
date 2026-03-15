extends Node

# Twemoji Font Loader - Automatically detects and loads Twemoji fonts
# Supports both res://fonts/emoji/ and user://fonts/emoji/ directories

const TWEMOJI_NAMES = [
	"Twemoji.Mozilla.ttf",
	"TwemojiMozilla.ttf",
	"Twemoji Mozilla.ttf",
	"twemoji.ttf",
	"TwitterColorEmoji-SVGinOT.ttf",
]

const FONT_PATHS = [
	"res://fonts/emoji/",
	"user://fonts/emoji/",
]

var twemoji_font: Font = null
var twemoji_available: bool = false

func _ready() -> void:
	twemoji_font = _load_twemoji_font()
	if twemoji_font:
		twemoji_available = true
		print("✓ Twemoji font loaded successfully")
	else:
		print("⚠ Twemoji font not found. Download from: https://github.com/mozilla/twemoji-colr/releases")

func _load_twemoji_font() -> Font:
	for path in FONT_PATHS:
		for font_name in TWEMOJI_NAMES:
			var full_path = path + font_name
			if ResourceLoader.exists(full_path):
				print("Loading Twemoji from: " + full_path)
				return load(full_path)
	
	return null

func get_twemoji_font() -> Font:
	return twemoji_font

func is_twemoji_available() -> bool:
	return twemoji_available
