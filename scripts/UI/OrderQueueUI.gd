extends HBoxContainer

signal order_selected(customer: Node)
signal order_deselected()

## Maps customer Node → its Button
var _order_buttons: Dictionary = {}
## Maps customer Node → its active Tween (pulse)
var _order_tweens: Dictionary = {}
var _selected_customer: Node = null

const COLOR_WAITING     := Color(0.940, 0.940, 0.940)   # #F0F0F0 — neutral
const COLOR_SELECTED    := Color(0.910, 0.322, 0.039)   # #E8520A — orange
const COLOR_IN_PROGRESS := Color(0.910, 0.322, 0.039)   # #E8520A — same, + pulse

func _ready() -> void:
	var cm: Node = get_tree().current_scene.get_node("CustomerManager")
	cm.order_ready.connect(_on_order_ready)
	cm.customer_departed.connect(_on_customer_departed)

# ---------------------------------------------------------------------------
# Order arrival
# ---------------------------------------------------------------------------
func _on_order_ready(customer: Node) -> void:
	var btn := Button.new()
	btn.text = customer.order
	btn.custom_minimum_size = Vector2(120.0, 48.0)
	btn.set_meta("state", "waiting")
	_apply_style(btn, COLOR_WAITING, Color(0.2, 0.2, 0.2))
	btn.pressed.connect(_on_button_pressed.bind(customer))
	add_child(btn)
	_order_buttons[customer] = btn

# ---------------------------------------------------------------------------
# Button interaction — drives selection state only; serving is via Station
# ---------------------------------------------------------------------------
func _on_button_pressed(customer: Node) -> void:
	var btn: Button = _order_buttons.get(customer)
	if btn == null:
		return
	var current_state: String = btn.get_meta("state", "waiting")
	if current_state == "in_progress":
		return   # in-progress orders can't be re-selected

	if current_state == "selected":
		# Deselect
		_set_state(customer, "waiting")
		_selected_customer = null
		order_deselected.emit()
	else:
		# Select — deselect any previously selected waiting order
		if _selected_customer and _selected_customer != customer:
			_set_state(_selected_customer, "waiting")
		_selected_customer = customer
		_set_state(customer, "selected")
		order_selected.emit(customer)

# ---------------------------------------------------------------------------
# Called by StationManager when a station accepts the order and starts prep
# ---------------------------------------------------------------------------
func set_in_progress(customer: Node) -> void:
	if _selected_customer == customer:
		_selected_customer = null
	_set_state(customer, "in_progress")

# ---------------------------------------------------------------------------
# Customer departure cleanup (patience timeout or served)
# ---------------------------------------------------------------------------
func _on_customer_departed(customer: Node, _was_served: bool) -> void:
	if _selected_customer == customer:
		_selected_customer = null
		order_deselected.emit()
	_remove_button(customer)

func _remove_button(customer: Node) -> void:
	var tween: Tween = _order_tweens.get(customer)
	if tween:
		tween.kill()
	_order_tweens.erase(customer)
	var btn: Button = _order_buttons.get(customer)
	if btn and is_instance_valid(btn):
		btn.queue_free()
	_order_buttons.erase(customer)

# ---------------------------------------------------------------------------
# Visual state machine
# ---------------------------------------------------------------------------
func _set_state(customer: Node, new_state: String) -> void:
	var btn: Button = _order_buttons.get(customer)
	if btn == null or not is_instance_valid(btn):
		return

	# Kill any existing pulse tween
	var tween: Tween = _order_tweens.get(customer)
	if tween:
		tween.kill()
		_order_tweens.erase(customer)
	btn.modulate = Color.WHITE

	btn.set_meta("state", new_state)

	match new_state:
		"waiting":
			_apply_style(btn, COLOR_WAITING, Color(0.2, 0.2, 0.2))
		"selected":
			_apply_style(btn, COLOR_SELECTED, Color.WHITE)
		"in_progress":
			_apply_style(btn, COLOR_IN_PROGRESS, Color.WHITE)
			_start_pulse(customer, btn)

func _start_pulse(customer: Node, btn: Button) -> void:
	var t := create_tween()
	t.set_loops()
	t.tween_property(btn, "modulate:a", 0.45, 0.5)
	t.tween_property(btn, "modulate:a", 1.00, 0.5)
	_order_tweens[customer] = t

# ---------------------------------------------------------------------------
# Styling helpers
# ---------------------------------------------------------------------------
func _apply_style(btn: Button, bg_color: Color, font_color: Color) -> void:
	btn.add_theme_stylebox_override("normal",  _make_sb(bg_color))
	btn.add_theme_stylebox_override("hover",   _make_sb(bg_color.lightened(0.08)))
	btn.add_theme_stylebox_override("pressed", _make_sb(bg_color.darkened(0.15)))
	btn.add_theme_color_override("font_color", font_color)

func _make_sb(bg_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left   = 8.0
	sb.content_margin_right  = 8.0
	sb.content_margin_top    = 4.0
	sb.content_margin_bottom = 4.0
	return sb
