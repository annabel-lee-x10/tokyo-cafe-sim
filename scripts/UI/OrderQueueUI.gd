extends HBoxContainer

## Maps customer Node → its Button in the queue
var _order_buttons: Dictionary = {}

const COLOR_PENDING     := Color(0.392, 0.259, 0.173)   # dark café brown
const COLOR_IN_PROGRESS := Color(0.910, 0.322, 0.039)   # #E8520A

func _ready() -> void:
	# CustomerManager is a direct child of the root scene (Main)
	var cm: Node = get_tree().current_scene.get_node("CustomerManager")
	cm.order_ready.connect(_on_order_ready)
	cm.customer_departed.connect(_on_customer_departed)

# ---------------------------------------------------------------------------
# Order lifecycle
# ---------------------------------------------------------------------------
func _on_order_ready(customer: Node) -> void:
	var btn := Button.new()
	btn.text = customer.order
	btn.custom_minimum_size = Vector2(120.0, 48.0)
	_apply_style(btn, COLOR_PENDING)
	btn.pressed.connect(_on_button_pressed.bind(customer))
	add_child(btn)
	_order_buttons[customer] = btn

func _on_button_pressed(customer: Node) -> void:
	var btn: Button = _order_buttons.get(customer)
	if btn == null or not is_instance_valid(btn):
		return

	if not btn.has_meta("in_progress"):
		# First tap: mark as in-progress
		btn.set_meta("in_progress", true)
		_apply_style(btn, COLOR_IN_PROGRESS)
	else:
		# Second tap: serve — cleanup flows through customer_departed signal
		customer.receive_drink()

func _on_customer_departed(customer: Node, _was_served: bool) -> void:
	_remove_button(customer)

func _remove_button(customer: Node) -> void:
	var btn: Button = _order_buttons.get(customer)
	if btn and is_instance_valid(btn):
		btn.queue_free()
	_order_buttons.erase(customer)

# ---------------------------------------------------------------------------
# Styling helpers
# ---------------------------------------------------------------------------
func _apply_style(btn: Button, bg_color: Color) -> void:
	btn.add_theme_stylebox_override("normal",  _make_sb(bg_color))
	btn.add_theme_stylebox_override("hover",   _make_sb(bg_color.lightened(0.08)))
	btn.add_theme_stylebox_override("pressed", _make_sb(bg_color.darkened(0.15)))
	btn.add_theme_color_override("font_color", Color.WHITE)

func _make_sb(bg_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left    = 6
	sb.corner_radius_top_right   = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left   = 8.0
	sb.content_margin_right  = 8.0
	sb.content_margin_top    = 4.0
	sb.content_margin_bottom = 4.0
	return sb
