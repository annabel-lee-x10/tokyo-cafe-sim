extends CanvasLayer
## Day-end fade-to-black transition with day number.

@onready var overlay:    ColorRect = $Overlay
@onready var day_label:  Label     = $Overlay/DayLabel

func _ready() -> void:
	overlay.modulate.a = 0.0
	overlay.visible    = false
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.day_started.connect(_on_day_started)

func _on_day_ended(day: int, _revenue: float) -> void:
	day_label.text = "Day %d" % day
	overlay.visible = true
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.30)

func _on_day_started(_day: int) -> void:
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.50)
	tw.tween_callback(func(): overlay.visible = false)
