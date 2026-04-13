extends CanvasLayer
## Ending screen — shown over everything when the game_over evaluation completes.

@onready var ending_title:  Label      = $Panel/VBox/EndingTitle
@onready var illustration:  ColorRect  = $Panel/VBox/Illustration
@onready var message_label: Label      = $Panel/VBox/Message
@onready var stats_grid:    GridContainer = $Panel/VBox/StatsGrid
@onready var play_again:    Button     = $Panel/VBox/PlayAgainBtn
@onready var credits_label: Label      = $Panel/VBox/CreditsScroll/CreditsLabel

var _is_true_ending: bool = false

func _ready() -> void:
	visible = false
	play_again.pressed.connect(_on_play_again)
	EndingManager.ending_triggered.connect(_on_ending_triggered)

func _on_ending_triggered(ending_id: String, title: String, message: String, stats: Dictionary) -> void:
	AudioManager.play_bgm("menu")
	ending_title.text  = title
	message_label.text = message
	_is_true_ending    = (ending_id == "true")

	# Illustration tint by ending
	match ending_id:
		"true":       illustration.color = Color(0.98, 0.90, 0.93)
		"good":       illustration.color = Color(0.90, 0.95, 0.90)
		"bittersweet": illustration.color = Color(0.95, 0.92, 0.85)
		"bad":        illustration.color = Color(0.75, 0.75, 0.80)

	_populate_stats(stats)
	credits_label.visible = _is_true_ending
	if _is_true_ending:
		_start_credits_scroll()
	visible = true

func _populate_stats(stats: Dictionary) -> void:
	for child in stats_grid.get_children():
		stats_grid.remove_child(child)
		child.queue_free()

	var entries := [
		["Total Revenue",    "¥%d" % stats.get("total_revenue", 0)],
		["Days Played",      "%d"  % stats.get("days_played", 0)],
		["Regulars Made",    "%d / 5" % stats.get("regulars_befriended", 0)],
		["Staff Hired",      "%d / 5" % stats.get("staff_hired", 0)],
		["Followers",        "%d"  % stats.get("followers", 0)],
	]
	for entry in entries:
		var key := Label.new()
		key.text = entry[0]
		key.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		var val := Label.new()
		val.text = entry[1]
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(key)
		stats_grid.add_child(val)

func _start_credits_scroll() -> void:
	# Animate the credits label scrolling upward
	credits_label.position.y = 0
	var tw := create_tween()
	tw.tween_property(credits_label, "position:y", -600.0, 12.0).set_delay(1.5)

func _on_play_again() -> void:
	SaveManager.new_game()
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
