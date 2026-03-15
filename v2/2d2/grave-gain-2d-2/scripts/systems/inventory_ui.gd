extends CanvasLayer

# ===== INVENTORY UI =====
# Full inventory screen with equipment slots, item grid, sorting, tooltips

const InventoryManager = preload("res://scripts/systems/inventory_manager.gd")

var is_open: bool = false
var inventory_mgr: Node = null
var selected_index: int = -1

# UI nodes
var bg_panel: Panel
var title_label: Label
var close_btn: Button
var item_grid: GridContainer
var equip_panel: VBoxContainer
var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var gold_label: Label
var sort_buttons: HBoxContainer
var stats_label: RichTextLabel

# Item slot buttons
var item_slots: Array[Button] = []
var equip_slots: Dictionary = {}  # int -> Button

func _ready() -> void:
	layer = 100
	visible = false
	_build_ui()

func set_inventory(mgr: Node) -> void:
	inventory_mgr = mgr
	if inventory_mgr and inventory_mgr.has_signal("inventory_changed"):
		inventory_mgr.inventory_changed.connect(_refresh_ui)

func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	get_tree().paused = true
	_refresh_ui()

func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	selected_index = -1

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func _build_ui() -> void:
	# Background overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Main panel
	bg_panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_CENTER)
	bg_panel.size = Vector2(900, 600)
	bg_panel.position = Vector2(-450, -300)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_color = Color(0.4, 0.35, 0.25)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	bg_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(bg_panel)
	
	# Title
	title_label = Label.new()
	title_label.text = "INVENTORY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 10)
	title_label.size = Vector2(900, 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_label.add_theme_font_size_override("font_size", 22)
	bg_panel.add_child(title_label)
	
	# Close button
	close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(860, 8)
	close_btn.size = Vector2(30, 30)
	close_btn.pressed.connect(close)
	bg_panel.add_child(close_btn)
	
	# Gold display
	gold_label = Label.new()
	gold_label.text = "Gold: 0"
	gold_label.position = Vector2(20, 10)
	gold_label.size = Vector2(200, 30)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	gold_label.add_theme_font_size_override("font_size", 16)
	bg_panel.add_child(gold_label)
	
	# Equipment panel (left side)
	_build_equipment_panel()
	
	# Item grid (center)
	_build_item_grid()
	
	# Sort buttons
	_build_sort_buttons()
	
	# Tooltip panel (right side)
	_build_tooltip_panel()
	
	# Stats summary
	_build_stats_panel()

func _build_equipment_panel() -> void:
	equip_panel = VBoxContainer.new()
	equip_panel.position = Vector2(20, 50)
	equip_panel.size = Vector2(180, 500)
	bg_panel.add_child(equip_panel)
	
	var header := Label.new()
	header.text = "Equipment"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	header.add_theme_font_size_override("font_size", 14)
	equip_panel.add_child(header)
	
	var slot_order := [
		InventoryManager.EquipSlot.WEAPON,
		InventoryManager.EquipSlot.OFFHAND,
		InventoryManager.EquipSlot.HELMET,
		InventoryManager.EquipSlot.CHEST,
		InventoryManager.EquipSlot.BOOTS,
		InventoryManager.EquipSlot.RING1,
		InventoryManager.EquipSlot.RING2,
		InventoryManager.EquipSlot.AMULET,
		InventoryManager.EquipSlot.TRINKET,
	]
	
	for slot in slot_order:
		var slot_name: String = InventoryManager.EQUIP_SLOT_NAMES.get(slot, "Unknown")
		var btn := Button.new()
		btn.text = "[" + slot_name + "] Empty"
		btn.custom_minimum_size = Vector2(170, 36)
		btn.pressed.connect(_on_equip_slot_pressed.bind(slot))
		
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.15, 0.15, 0.2)
		btn_style.border_color = Color(0.3, 0.3, 0.4)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_font_size_override("font_size", 11)
		
		equip_panel.add_child(btn)
		equip_slots[slot] = btn

func _build_item_grid() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(210, 80)
	scroll.size = Vector2(420, 460)
	bg_panel.add_child(scroll)
	
	item_grid = GridContainer.new()
	item_grid.columns = 8
	item_grid.size = Vector2(420, 0)
	scroll.add_child(item_grid)
	
	# Create 40 item slot buttons
	for i in range(InventoryManager.MAX_INVENTORY_SIZE):
		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(48, 48)
		btn.pressed.connect(_on_item_slot_pressed.bind(i))
		btn.mouse_entered.connect(_on_item_hover.bind(i))
		btn.mouse_exited.connect(_on_item_hover_exit)
		
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.12, 0.12, 0.18)
		btn_style.border_color = Color(0.25, 0.25, 0.35)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_font_size_override("font_size", 18)
		
		item_grid.add_child(btn)
		item_slots.append(btn)

func _build_sort_buttons() -> void:
	sort_buttons = HBoxContainer.new()
	sort_buttons.position = Vector2(210, 50)
	sort_buttons.size = Vector2(420, 28)
	bg_panel.add_child(sort_buttons)
	
	var sort_label := Label.new()
	sort_label.text = "Sort: "
	sort_label.add_theme_font_size_override("font_size", 12)
	sort_buttons.add_child(sort_label)
	
	var btn_rarity := Button.new()
	btn_rarity.text = "Rarity"
	btn_rarity.pressed.connect(func(): if inventory_mgr: inventory_mgr.sort_by_rarity())
	btn_rarity.add_theme_font_size_override("font_size", 11)
	sort_buttons.add_child(btn_rarity)
	
	var btn_name := Button.new()
	btn_name.text = "Name"
	btn_name.pressed.connect(func(): if inventory_mgr: inventory_mgr.sort_by_name())
	btn_name.add_theme_font_size_override("font_size", 11)
	sort_buttons.add_child(btn_name)
	
	var btn_type := Button.new()
	btn_type.text = "Type"
	btn_type.pressed.connect(func(): if inventory_mgr: inventory_mgr.sort_by_category())
	btn_type.add_theme_font_size_override("font_size", 11)
	sort_buttons.add_child(btn_type)

func _build_tooltip_panel() -> void:
	tooltip_panel = Panel.new()
	tooltip_panel.position = Vector2(640, 50)
	tooltip_panel.size = Vector2(250, 300)
	tooltip_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.5, 0.4, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	tooltip_panel.add_theme_stylebox_override("panel", style)
	bg_panel.add_child(tooltip_panel)
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.position = Vector2(10, 10)
	tooltip_label.size = Vector2(230, 280)
	tooltip_label.bbcode_enabled = true
	tooltip_label.scroll_active = false
	tooltip_label.add_theme_font_size_override("normal_font_size", 12)
	tooltip_panel.add_child(tooltip_label)

func _build_stats_panel() -> void:
	stats_label = RichTextLabel.new()
	stats_label.position = Vector2(640, 360)
	stats_label.size = Vector2(250, 190)
	stats_label.bbcode_enabled = true
	stats_label.scroll_active = false
	stats_label.add_theme_font_size_override("normal_font_size", 11)
	bg_panel.add_child(stats_label)

# ===== UI REFRESH =====

func _refresh_ui() -> void:
	if not inventory_mgr:
		return
	
	# Update gold
	gold_label.text = "Gold: " + str(inventory_mgr.gold)
	
	# Update equipment slots
	for slot in equip_slots:
		var btn: Button = equip_slots[slot]
		var item: Dictionary = inventory_mgr.get_equipped(slot)
		var slot_name: String = InventoryManager.EQUIP_SLOT_NAMES.get(slot, "?")
		if item.is_empty():
			btn.text = "[" + slot_name + "] Empty"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		else:
			var rarity_color: Color = InventoryManager.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
			btn.text = item.get("emoji", "") + " " + item.get("name", "?")
			btn.add_theme_color_override("font_color", rarity_color)
	
	# Update item grid
	var inv: Array[Dictionary] = inventory_mgr.inventory
	for i in range(item_slots.size()):
		var btn: Button = item_slots[i]
		if i < inv.size():
			var item: Dictionary = inv[i]
			var emoji: String = item.get("emoji", "?")
			var count: int = item.get("count", 1)
			btn.text = emoji + ((" x" + str(count)) if count > 1 else "")
			var rarity_color: Color = InventoryManager.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
			btn.add_theme_color_override("font_color", rarity_color)
			
			# Color border by rarity
			var slot_style := StyleBoxFlat.new()
			slot_style.bg_color = Color(0.12, 0.12, 0.18)
			slot_style.border_color = rarity_color * 0.6
			slot_style.set_border_width_all(1)
			slot_style.set_corner_radius_all(3)
			btn.add_theme_stylebox_override("normal", slot_style)
		else:
			btn.text = ""
			btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
			var empty_style := StyleBoxFlat.new()
			empty_style.bg_color = Color(0.12, 0.12, 0.18)
			empty_style.border_color = Color(0.25, 0.25, 0.35)
			empty_style.set_border_width_all(1)
			empty_style.set_corner_radius_all(3)
			btn.add_theme_stylebox_override("normal", empty_style)
	
	# Update stats
	_refresh_stats()

func _refresh_stats() -> void:
	if not inventory_mgr or not stats_label:
		return
	var text := "[b][color=#AABBFF]Stat Bonuses[/color][/b]\n"
	var stat_names := ["damage", "defense", "max_hp", "crit_chance", "speed", "lifesteal", "dodge", "attack_speed"]
	for stat in stat_names:
		var val: float = inventory_mgr.get_total_stat_bonus(stat)
		if val > 0.001:
			var display: String
			if stat in ["crit_chance", "lifesteal", "dodge"]:
				display = str(snappedf(val * 100.0, 0.1)) + "%"
			else:
				display = str(snappedf(val, 0.1))
			text += stat.replace("_", " ").capitalize() + ": [color=#88FF88]+" + display + "[/color]\n"
	stats_label.text = text

# ===== INTERACTION =====

func _on_item_slot_pressed(index: int) -> void:
	if not inventory_mgr:
		return
	if index >= inventory_mgr.inventory.size():
		return
	
	var item: Dictionary = inventory_mgr.inventory[index]
	selected_index = index
	
	# If equipment, try equipping
	if item.has("equip_slot"):
		inventory_mgr.equip_item(index)
	# If consumable, use it
	elif item.get("category", -1) == InventoryManager.ItemCategory.CONSUMABLE:
		inventory_mgr.use_item(index)

func _on_equip_slot_pressed(slot: int) -> void:
	if not inventory_mgr:
		return
	inventory_mgr.unequip_item(slot)

func _on_item_hover(index: int) -> void:
	if not inventory_mgr:
		return
	if index >= inventory_mgr.inventory.size():
		tooltip_panel.visible = false
		return
	
	var item: Dictionary = inventory_mgr.inventory[index]
	_show_tooltip(item)

func _on_item_hover_exit() -> void:
	tooltip_panel.visible = false

func _show_tooltip(item: Dictionary) -> void:
	var rarity: String = item.get("rarity", "common")
	var rarity_color: Color = InventoryManager.RARITY_COLORS.get(rarity, Color.WHITE)
	var color_hex := rarity_color.to_html(false)
	
	var text := "[b][color=#" + color_hex + "]" + item.get("name", "Unknown") + "[/color][/b]\n"
	text += "[color=#888888]" + rarity.capitalize() + " - Lv." + str(item.get("level", 1)) + "[/color]\n\n"
	
	# Stats
	var stats: Dictionary = item.get("stats", {})
	for stat in stats:
		var val: float = stats[stat]
		var display: String
		if stat in ["crit_chance", "lifesteal", "dodge"]:
			display = str(snappedf(val * 100.0, 0.1)) + "%"
		else:
			display = str(snappedf(val, 0.1))
		text += stat.replace("_", " ").capitalize() + ": [color=#88FF88]+" + display + "[/color]\n"
	
	text += "\n[color=#AAAAAA]" + item.get("description", "") + "[/color]"
	
	# Usage hint
	if item.has("equip_slot"):
		text += "\n\n[color=#FFDD88]Click to equip[/color]"
	elif item.get("category", -1) == InventoryManager.ItemCategory.CONSUMABLE:
		text += "\n\n[color=#FFDD88]Click to use[/color]"
	
	tooltip_label.text = text
	tooltip_panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_I or event.keycode == KEY_TAB:
			close()
			get_viewport().set_input_as_handled()
