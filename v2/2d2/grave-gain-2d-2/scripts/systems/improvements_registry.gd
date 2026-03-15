# ===== IMPROVEMENTS REGISTRY =====
# Master registry that loads all 1,100 improvements from individual files

extends Node

const Improvements101_250 = preload("res://scripts/systems/improvements_101_250.gd")
const Improvements251_400 = preload("res://scripts/systems/improvements_251_400.gd")
const Improvements401_550 = preload("res://scripts/systems/improvements_401_550.gd")
const Improvements551_700 = preload("res://scripts/systems/improvements_551_700.gd")
const Improvements701_850 = preload("res://scripts/systems/improvements_701_850.gd")
const Improvements851_1000 = preload("res://scripts/systems/improvements_851_1000.gd")
const Improvements1001_1100 = preload("res://scripts/systems/improvements_1001_1100.gd")
const Improvements1101_1200 = preload("res://scripts/systems/improvements_1101_1200.gd")

var all_improvements: Dictionary = {}

func _ready() -> void:
	_load_all_improvements()

func _load_all_improvements() -> void:
	# Load improvements from all files
	all_improvements.merge(Improvements101_250.get_improvements())
	all_improvements.merge(Improvements251_400.get_improvements())
	all_improvements.merge(Improvements401_550.get_improvements())
	all_improvements.merge(Improvements551_700.get_improvements())
	all_improvements.merge(Improvements701_850.get_improvements())
	all_improvements.merge(Improvements851_1000.get_improvements())
	_load_array_improvements(Improvements1001_1100.get_improvements())
	_load_array_improvements(Improvements1101_1200.get_improvements())
	_load_array_improvements(Improvements1201_1300.get_improvements())

func _load_array_improvements(arr: Array[Dictionary]) -> void:
	for item in arr:
		var id: int = item.get("id", 0)
		if id > 0:
			all_improvements[id] = item

func get_improvement(id: int) -> Dictionary:
	return all_improvements.get(id, {})

func get_all_improvements() -> Dictionary:
	return all_improvements.duplicate()

func get_improvement_count() -> int:
	return all_improvements.size()

func get_improvements_by_range(start: int, end: int) -> Dictionary:
	var result: Dictionary = {}
	for i in range(start, end + 1):
		if i in all_improvements:
			result[i] = all_improvements[i]
	return result

func get_improvement_names() -> Array[String]:
	var names: Array[String] = []
	for i in range(1, 1201):
		if i in all_improvements:
			names.append(all_improvements[i].get("name", "Unknown"))
	return names

func get_improvement_descriptions() -> Array[String]:
	var descs: Array[String] = []
	for i in range(1, 1201):
		if i in all_improvements:
			descs.append(all_improvements[i].get("desc", ""))
	return descs

func print_improvements() -> void:
	for i in range(1, 1201):
		if i in all_improvements:
			var imp = all_improvements[i]
			print("Improvement #%d: %s - %s" % [i, imp.get("name", ""), imp.get("desc", "")])
