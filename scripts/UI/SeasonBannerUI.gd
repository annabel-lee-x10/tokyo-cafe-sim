extends CanvasLayer
## Season-change full-width banner.
## Fades in 0.5 s, holds 1.0 s, fades out 0.5 s — non-blocking.

@onready var banner: ColorRect = $Banner
@onready var label:  Label     = $Banner/Label

func _ready() -> void:
	banner.modulate.a = 0.0
	banner.visible = false
	SeasonManager.season_changed.connect(_on_season_changed)

func _on_season_changed(season_id: String, season_data: Dictionary) -> void:
	label.text  = "%s has arrived" % season_data.get("name", season_id.capitalize())
	banner.color = season_data.get("bg_tint", Color(1, 1, 1, 0.88))
	banner.visible = true

	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.0)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): banner.visible = false)
