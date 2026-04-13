extends HBoxContainer

@onready var day_label:      Label = $DayLabel
@onready var follower_label: Label = $FollowerLabel
@onready var time_label:     Label = $TimeLabel

const COLOR_NORMAL  := Color(0.900, 0.900, 0.900)
const COLOR_WARNING := Color(0.910, 0.322, 0.039)   # #E8520A — matches order palette

func _ready() -> void:
	follower_label.text = "0 followers"
	SocialManager.followers_changed.connect(_on_followers_changed)

func _process(_delta: float) -> void:
	var remaining := maxf(GameManager.DAY_DURATION - GameManager.day_timer, 0.0)
	var mins := int(remaining) / 60
	var secs := int(remaining) % 60
	time_label.text = "%02d:%02d" % [mins, secs]
	time_label.add_theme_color_override(
		"font_color",
		COLOR_WARNING if remaining < 30.0 else COLOR_NORMAL
	)
	day_label.text = "Day %d / %d" % [GameManager.current_day, GameManager.DAYS_TOTAL]

func _on_followers_changed(new_count: int) -> void:
	follower_label.text = "%d followers" % new_count
