extends CanvasLayer

# Quarters UI - interface for botany, repair, and room upgrades

class_name QuartersUI

signal skill_selected(skill: String)
signal plant_selected(plant_type: String)
signal repair_started(item: Dictionary)

var botany_skill: BotanySkill = null
var repair_skill: ItemRepairSkill = null
var currency_system: CurrencySystem = null
var personal_quarters: PersonalQuarters = null

var main_panel: PanelContainer = null
var botany_panel: PanelContainer = null
var repair_panel: PanelContainer = null
var upgrade_panel: PanelContainer = null

var uusd_label: Label = null
var gold_label: Label = null

func _ready() -> void:
	layer = 50
	_create_ui()

func set_references(botany: BotanySkill, repair: ItemRepairSkill, currency: CurrencySystem, quarters: PersonalQuarters) -> void:
	botany_skill = botany
	repair_skill = repair
	currency_system = currency
	personal_quarters = quarters
	
	if currency_system:
		currency_system.uusd_changed.connect(_on_uusd_changed)
		currency_system.gold_changed.connect(_on_gold_changed)
	
	if botany_skill:
		botany_skill.space_changed.connect(_on_space_changed)

func _create_ui() -> void:
	# Main panel
	main_panel = PanelContainer.new()
	main_panel.position = Vector2(10, 10)
	main_panel.size = Vector2(300, 200)
	add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_panel.add_child(main_vbox)
	
	# Currency display
	var currency_hbox = HBoxContainer.new()
	main_vbox.add_child(currency_hbox)
	
	var uusd_icon = Label.new()
	uusd_icon.text = "$UUSD:"
	currency_hbox.add_child(uusd_icon)
	
	uusd_label = Label.new()
	uusd_label.text = "0.00"
	currency_hbox.add_child(uusd_label)
	
	var gold_icon = Label.new()
	gold_icon.text = "Gold:"
	currency_hbox.add_child(gold_icon)
	
	gold_label = Label.new()
	gold_label.text = "0"
	currency_hbox.add_child(gold_label)
	
	# Skill buttons
	var botany_btn = Button.new()
	botany_btn.text = "🌱 Botany (Lvl %d)" % (botany_skill.get_skill_level() if botany_skill else 1)
	botany_btn.pressed.connect(_on_botany_pressed)
	main_vbox.add_child(botany_btn)
	
	var repair_btn = Button.new()
	repair_btn.text = "🔧 Repair (Lvl %d)" % (repair_skill.get_skill_level() if repair_skill else 1)
	repair_btn.pressed.connect(_on_repair_pressed)
	main_vbox.add_child(repair_btn)
	
	var upgrade_btn = Button.new()
	upgrade_btn.text = "🏠 Upgrade Room"
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	main_vbox.add_child(upgrade_btn)
	
	# Botany panel
	botany_panel = PanelContainer.new()
	botany_panel.position = Vector2(320, 10)
	botany_panel.size = Vector2(400, 400)
	botany_panel.visible = false
	add_child(botany_panel)
	
	var botany_vbox = VBoxContainer.new()
	botany_panel.add_child(botany_vbox)
	
	var botany_title = Label.new()
	botany_title.text = "🌱 Botany - Plant Seeds"
	botany_vbox.add_child(botany_title)
	
	var space_label = Label.new()
	space_label.text = "Space: 0/100"
	botany_vbox.add_child(space_label)
	
	if botany_skill:
		for plant_type in botany_skill.get_plant_types().keys():
			var plant_data = botany_skill.plant_types[plant_type]
			var plant_btn = Button.new()
			plant_btn.text = "%s %s (%.0f space)" % [plant_data["emoji"], plant_data["name"], plant_data["space"]]
			plant_btn.pressed.connect(_on_plant_selected.bind(plant_type))
			botany_vbox.add_child(plant_btn)
	
	# Repair panel
	repair_panel = PanelContainer.new()
	repair_panel.position = Vector2(730, 10)
	repair_panel.size = Vector2(300, 300)
	repair_panel.visible = false
	add_child(repair_panel)
	
	var repair_vbox = VBoxContainer.new()
	repair_panel.add_child(repair_vbox)
	
	var repair_title = Label.new()
	repair_title.text = "🔧 Item Repair"
	repair_vbox.add_child(repair_title)
	
	var repair_info = Label.new()
	repair_info.text = "Select an item to repair"
	repair_vbox.add_child(repair_info)
	
	# Upgrade panel
	upgrade_panel = PanelContainer.new()
	upgrade_panel.position = Vector2(10, 220)
	upgrade_panel.size = Vector2(300, 150)
	upgrade_panel.visible = false
	add_child(upgrade_panel)
	
	var upgrade_vbox = VBoxContainer.new()
	upgrade_panel.add_child(upgrade_vbox)
	
	var upgrade_title = Label.new()
	upgrade_title.text = "🏠 Upgrade Personal Quarters"
	upgrade_vbox.add_child(upgrade_title)
	
	var upgrade_info = Label.new()
	upgrade_info.text = "Cost: $UUSD"
	upgrade_vbox.add_child(upgrade_info)
	
	var upgrade_confirm_btn = Button.new()
	upgrade_confirm_btn.text = "Upgrade"
	upgrade_confirm_btn.pressed.connect(_on_upgrade_confirm)
	upgrade_vbox.add_child(upgrade_confirm_btn)

func _on_botany_pressed() -> void:
	botany_panel.visible = not botany_panel.visible
	repair_panel.visible = false
	upgrade_panel.visible = false

func _on_repair_pressed() -> void:
	repair_panel.visible = not repair_panel.visible
	botany_panel.visible = false
	upgrade_panel.visible = false

func _on_upgrade_pressed() -> void:
	upgrade_panel.visible = not upgrade_panel.visible
	botany_panel.visible = false
	repair_panel.visible = false

func _on_plant_selected(plant_type: String) -> void:
	if botany_skill:
		if botany_skill.plant_seed(plant_type):
			skill_selected.emit("botany")
			plant_selected.emit(plant_type)

func _on_upgrade_confirm() -> void:
	if personal_quarters:
		if personal_quarters.upgrade_room():
			upgrade_panel.visible = false

func _on_uusd_changed(amount: float) -> void:
	if uusd_label:
		uusd_label.text = "%.2f" % amount

func _on_gold_changed(amount: float) -> void:
	if gold_label:
		gold_label.text = "%.0f" % amount

func _on_space_changed(used: float, total: float) -> void:
	pass

func show_quarters_ui() -> void:
	visible = true

func hide_quarters_ui() -> void:
	visible = false
