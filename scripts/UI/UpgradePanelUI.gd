extends Control
## Upgrade shop panel — slide-up on HUD button press.
## Tabs: Equipment / Decor / Menu.  All rows built programmatically.

@onready var _revenue_label: Label         = $Sheet/VBox/Header/RevenueLabel
@onready var _tab_equipment: Button        = $Sheet/VBox/TabBar/EquipmentBtn
@onready var _tab_decor:     Button        = $Sheet/VBox/TabBar/DecorBtn
@onready var _tab_menu:      Button        = $Sheet/VBox/TabBar/MenuBtn
@onready var _item_list:     VBoxContainer = $Sheet/VBox/Scroll/ItemList
@onready var _close_btn:     Button        = $Sheet/VBox/Header/CloseBtn
@onready var _sheet:         Control       = $Sheet

const SHEET_ON_Y:  float = 900.0
const SHEET_OFF_Y: float = 1940.0

var _current_tab: String = "equipment"

func _ready() -> void:
	visible = false
	_sheet.position.y = SHEET_OFF_Y

	_close_btn.pressed.connect(close)
	_tab_equipment.pressed.connect(func(): _switch_tab("equipment"))
	_tab_decor.pressed.connect(func():     _switch_tab("decor"))
	_tab_menu.pressed.connect(func():      _switch_tab("menu"))

	GameManager.revenue_changed.connect(_on_revenue_changed)
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)

# ---------------------------------------------------------------------------
# Open / close
# ---------------------------------------------------------------------------
func open() -> void:
	_refresh_revenue_label()
	_build_items(_current_tab)
	visible = true
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_sheet, "position:y", SHEET_ON_Y, 0.25)

func close() -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_sheet, "position:y", SHEET_OFF_Y, 0.20)
	tw.tween_callback(func(): visible = false)

# ---------------------------------------------------------------------------
# Tab switching
# ---------------------------------------------------------------------------
func _switch_tab(category: String) -> void:
	_current_tab = category
	_build_items(category)
	_tab_equipment.button_pressed = (category == "equipment")
	_tab_decor.button_pressed     = (category == "decor")
	_tab_menu.button_pressed      = (category == "menu")

# ---------------------------------------------------------------------------
# Row building
# ---------------------------------------------------------------------------
func _build_items(category: String) -> void:
	for child in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()

	for id in UpgradeManager.CATEGORY_ORDER.get(category, []):
		var data: Dictionary = UpgradeManager.UPGRADES[id]
		var purchased: bool  = UpgradeManager.is_purchased(id)
		var affordable: bool = GameManager.total_revenue >= data.get("cost", 0)

		# ── Row container ──────────────────────────────────────────────────
		var row := HBoxContainer.new()
		row.set_meta("upgrade_id", id)

		# Left: name + effect
		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = data["name"]
		name_lbl.add_theme_font_size_override("font_size", 24)
		if purchased:
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))

		var fx_lbl := Label.new()
		fx_lbl.text = data["effect_desc"]
		fx_lbl.add_theme_font_size_override("font_size", 17)
		fx_lbl.add_theme_color_override("font_color",
			Color(0.55, 0.55, 0.55) if purchased else Color(0.75, 0.75, 0.75))
		fx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		left.add_child(name_lbl)
		left.add_child(fx_lbl)

		# Right: cost + buy button
		var right := VBoxContainer.new()
		right.custom_minimum_size = Vector2(140.0, 0.0)

		var cost_lbl := Label.new()
		cost_lbl.text = "¥%d" % data.get("cost", 0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 20)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130.0, 56.0)
		if purchased:
			btn.text = "Owned"
			btn.disabled = true
		else:
			btn.text = "Buy"
			btn.disabled = not affordable
			btn.pressed.connect(_on_buy_pressed.bind(id))

		right.add_child(cost_lbl)
		right.add_child(btn)

		row.add_child(left)
		row.add_child(right)

		_item_list.add_child(row)
		_item_list.add_child(HSeparator.new())

# ---------------------------------------------------------------------------
# Refresh helpers
# ---------------------------------------------------------------------------
func _refresh_revenue_label() -> void:
	_revenue_label.text = "Revenue: ¥%d  /  ¥%d" % [
		int(GameManager.total_revenue),
		int(GameManager.REVENUE_TARGET)
	]

func _refresh_buy_buttons() -> void:
	for row in _item_list.get_children():
		if not row.has_meta("upgrade_id"):
			continue
		var uid: String = row.get_meta("upgrade_id")
		if UpgradeManager.is_purchased(uid):
			continue
		var right: Node = row.get_child(1)
		if right.get_child_count() < 2:
			continue
		var btn: Button = right.get_child(1)
		if btn.disabled:
			continue
		btn.disabled = GameManager.total_revenue < UpgradeManager.UPGRADES[uid].get("cost", 0)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_revenue_changed(new_revenue: float, _target: float) -> void:
	_revenue_label.text = "Revenue: ¥%d  /  ¥%d" % [int(new_revenue), int(GameManager.REVENUE_TARGET)]
	_refresh_buy_buttons()

func _on_upgrade_purchased(_id: String) -> void:
	_build_items(_current_tab)   # full rebuild to show checkmarks

# ---------------------------------------------------------------------------
# Buy handler
# ---------------------------------------------------------------------------
func _on_buy_pressed(upgrade_id: String) -> void:
	UpgradeManager.purchase(upgrade_id)
