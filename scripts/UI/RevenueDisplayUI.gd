extends VBoxContainer

@onready var revenue_label: Label = $RevenueLabel
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	GameManager.revenue_changed.connect(_on_revenue_changed)
	_update_display(GameManager.total_revenue, GameManager.REVENUE_TARGET)

	# Phase 1 test: verify display updates when add_revenue() is called
	GameManager.add_revenue(500.0)

func _on_revenue_changed(new_revenue: float, target: float) -> void:
	_update_display(new_revenue, target)

func _update_display(revenue: float, target: float) -> void:
	revenue_label.text = "\u00a5%s / \u00a5%s" % [_format_yen(revenue), _format_yen(target)]
	progress_bar.value = GameManager.get_revenue_progress() * 100.0

func _format_yen(amount: float) -> String:
	var n := int(amount)
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
