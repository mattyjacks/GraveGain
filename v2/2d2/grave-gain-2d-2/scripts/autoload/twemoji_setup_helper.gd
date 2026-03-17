extends Node

# Twemoji Setup Helper - Manages Twemoji font installation and configuration
# This script provides utilities for setting up Twemoji in GraveGain

signal setup_complete
signal setup_failed(error: String)
signal download_progress(current: int, total: int)

const TWEMOJI_FONT_NAMES = [
	"Twemoji.Mozilla.ttf",
	"TwemojiMozilla.ttf",
	"Twemoji Mozilla.ttf",
	"twemoji.ttf",
	"TwitterColorEmoji-SVGinOT.ttf",
]

const FONT_SEARCH_PATHS = [
	"res://fonts/emoji/",
	"user://fonts/emoji/",
]

var http_request: HTTPRequest = null
var setup_in_progress: bool = false

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_download_complete)

func is_twemoji_installed() -> bool:
	for path in FONT_SEARCH_PATHS:
		for font_name in TWEMOJI_FONT_NAMES:
			var full_path = path + font_name
			if ResourceLoader.exists(full_path) or FileAccess.file_exists(full_path):
				return true
	return false

func get_twemoji_font_path() -> String:
	for path in FONT_SEARCH_PATHS:
		for font_name in TWEMOJI_FONT_NAMES:
			var full_path = path + font_name
			if ResourceLoader.exists(full_path):
				return full_path
			if FileAccess.file_exists(full_path):
				return full_path
	return ""

func download_and_install_twemoji() -> void:
	if setup_in_progress:
		print("⚠ Setup already in progress")
		return
	
	setup_in_progress = true
	
	# Create directories if they don't exist
	var user_fonts_dir = "user://fonts/emoji/"
	var dir = DirAccess.open("user://fonts/")
	if dir == null:
		dir = DirAccess.open("user://")
		if dir != null:
			dir.make_dir("fonts")
			dir.make_dir("fonts/emoji")
	else:
		dir = DirAccess.open("user://fonts/")
		if dir != null:
			dir.make_dir("emoji")
	
	print("⏳ Downloading Twemoji font...")
	var download_url = "https://github.com/mozilla/twemoji-colr/releases/download/v0.7.0/Twemoji.Mozilla.ttf"
	
	var error = http_request.request(download_url)
	if error != OK:
		setup_in_progress = false
		var err_msg = "Failed to start download: " + str(error)
		print("✗ " + err_msg)
		setup_failed.emit(err_msg)

func _on_download_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	setup_in_progress = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		var err_msg = "Download failed with result: " + str(result)
		print("✗ " + err_msg)
		setup_failed.emit(err_msg)
		return
	
	if response_code != 200:
		var err_msg = "Download failed with HTTP code: " + str(response_code)
		print("✗ " + err_msg)
		setup_failed.emit(err_msg)
		return
	
	# Save the font file
	var save_path = "user://fonts/emoji/Twemoji.Mozilla.ttf"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		var err_msg = "Failed to save font file to " + save_path
		print("✗ " + err_msg)
		setup_failed.emit(err_msg)
		return
	
	file.store_buffer(body)
	print("✓ Twemoji font downloaded successfully!")
	print("Location: " + save_path)
	print("Size: " + str(body.size()) + " bytes")
	print("Restarting EmojiManager to load the font...")
	
	# Trigger a rescan in EmojiManager
	if EmojiManager:
		EmojiManager.rescan()
		EmojiManager.apply_emoji_set("twemoji")
	
	setup_complete.emit()

func get_setup_status() -> Dictionary:
	var is_installed = is_twemoji_installed()
	var font_path = get_twemoji_font_path()
	var is_active = EmojiManager.current_set_id == "twemoji" if EmojiManager else false
	
	return {
		"installed": is_installed,
		"font_path": font_path,
		"active": is_active,
		"in_progress": setup_in_progress,
	}

func print_status() -> void:
	var status = get_setup_status()
	print("\n=== Twemoji Setup Status ===")
	print("Installed: " + ("✓ Yes" if status["installed"] else "✗ No"))
	if status["installed"]:
		print("Font Path: " + status["font_path"])
	print("Active: " + ("✓ Yes" if status["active"] else "✗ No"))
	print("Setup In Progress: " + ("Yes" if status["in_progress"] else "No"))
	print("============================\n")
