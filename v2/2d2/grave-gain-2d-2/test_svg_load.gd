extends Node

func _ready() -> void:
	print("\n=== SVG Loading Test ===")
	
	# Test 1: Check if SVG file exists
	var svg_path = "res://fonts/emoji/svg/1f426.svg"
	print("1. Testing path: " + svg_path)
	print("   ResourceLoader.exists(): " + str(ResourceLoader.exists(svg_path)))
	
	# Test 2: Try to load it
	var texture = load(svg_path)
	print("2. load() result: " + str(texture))
	if texture:
		print("   Type: " + texture.get_class())
	
	# Test 3: Check .ctex path
	var ctex_path = "res://.godot/imported/1f426.svg-eaa10a0514cf9fdc0bf0f2830606e4b0.ctex"
	print("3. Testing .ctex path: " + ctex_path)
	print("   ResourceLoader.exists(): " + str(ResourceLoader.exists(ctex_path)))
	var ctex_texture = load(ctex_path)
	print("   load() result: " + str(ctex_texture))
	if ctex_texture:
		print("   Type: " + ctex_texture.get_class())
	
	# Test 4: Check import file
	var import_path = svg_path + ".import"
	print("4. Testing import file: " + import_path)
	print("   FileAccess.file_exists(): " + str(FileAccess.file_exists(ProjectSettings.globalize_path(import_path))))
	
	print("\n=== End Test ===\n")
