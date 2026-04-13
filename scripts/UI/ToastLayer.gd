extends CanvasLayer
## Toast notification overlay — layer 10, appears above all game UI.

@onready var container: VBoxContainer = $Container

const DURATION: float   = 3.0
const FADE_TIME: float  = 0.5
const FONT_SIZE: int    = 18

func _ready() -> void:
	RegularManager.loyalty_level_up.connect(_on_loyalty_level_up)
	RegularManager.drink_unlocked.connect(_on_drink_unlocked)

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------
func show_toast(message: String) -> void:
	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.08, 0.08, 0.08, 0.88)
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left   = 16.0
	sb.content_margin_right  = 16.0
	sb.content_margin_top    = 10.0
	sb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text                       = message
	lbl.horizontal_alignment       = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl)
	container.add_child(panel)

	var tween := create_tween()
	tween.tween_interval(DURATION - FADE_TIME)
	tween.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(panel.queue_free)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_loyalty_level_up(regular_id: String, level: int, regular_data: Dictionary) -> void:
	var name: String = regular_data.get("name", regular_id.capitalize())
	var msg: String  = "%s is a true regular" % name if level == 3 \
	                   else "%s feels at home here" % name
	show_toast(msg)

func _on_drink_unlocked(_regular_id: String, drink_name: String) -> void:
	show_toast("New drink unlocked: %s" % drink_name)
