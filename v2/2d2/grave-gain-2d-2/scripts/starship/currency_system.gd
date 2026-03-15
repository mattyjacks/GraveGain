extends Node

# Currency System - manages $UUSD (Universal United States Dollars) and gold conversion

class_name CurrencySystem

signal uusd_changed(amount: float)
signal gold_changed(amount: float)
signal conversion_completed(from_currency: String, to_currency: String, amount: float)

var uusd: float = 0.0
var gold: float = 0.0

# Exchange rates
var gold_to_uusd_rate: float = 10.0
var uusd_to_gold_rate: float = 0.1

func _ready() -> void:
	_load_currency()

func _load_currency() -> void:
	var config = ConfigFile.new()
	if config.load("user://currency.save") == OK:
		uusd = config.get_value("currency", "uusd", 100.0)
		gold = config.get_value("currency", "gold", 0.0)
	else:
		uusd = 100.0
		gold = 0.0

func _save_currency() -> void:
	var config = ConfigFile.new()
	config.set_value("currency", "uusd", uusd)
	config.set_value("currency", "gold", gold)
	config.save("user://currency.save")

func add_uusd(amount: float) -> void:
	uusd += amount
	uusd_changed.emit(uusd)
	_save_currency()

func remove_uusd(amount: float) -> bool:
	if uusd >= amount:
		uusd -= amount
		uusd_changed.emit(uusd)
		_save_currency()
		return true
	return false

func add_gold(amount: float) -> void:
	gold += amount
	gold_changed.emit(gold)
	_save_currency()

func remove_gold(amount: float) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		_save_currency()
		return true
	return false

func convert_gold_to_uusd(gold_amount: float) -> bool:
	if gold >= gold_amount:
		var uusd_gained = gold_amount * gold_to_uusd_rate
		remove_gold(gold_amount)
		add_uusd(uusd_gained)
		conversion_completed.emit("gold", "uusd", uusd_gained)
		return true
	return false

func convert_uusd_to_gold(uusd_amount: float) -> bool:
	if uusd >= uusd_amount:
		var gold_gained = uusd_amount * uusd_to_gold_rate
		remove_uusd(uusd_amount)
		add_gold(gold_gained)
		conversion_completed.emit("uusd", "gold", gold_gained)
		return true
	return false

func get_uusd() -> float:
	return uusd

func get_gold() -> float:
	return gold

func set_uusd(amount: float) -> void:
	uusd = amount
	uusd_changed.emit(uusd)
	_save_currency()

func set_gold(amount: float) -> void:
	gold = amount
	gold_changed.emit(gold)
	_save_currency()
