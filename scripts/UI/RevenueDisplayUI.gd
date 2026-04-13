extends VBoxContainer

@onready var revenue_label: Label = $RevenueLabel
@onready var progress_bar: ProgressBar = $ProgressBar

var _display_revenue: float = 0.0
var _target_revenue: float = 0.0

func _ready() -> void:
	GameManager.revenue_changed.connect(_on_revenue_changed)
	_display_revenue = GameManager.total_revenue
	_target_revenue  = GameManager.total_revenue
	_update_display(_display_revenue)

func _process(delta: float) -> void:
	if abs(_display_revenue - _target_revenue) > 0.5:
		_display_revenue = lerpf(_display_revenue, _target_revenue, 15.0 * delta)
		_update_display(_display_revenue)

func _on_revenue_changed(new_revenue: float, _target: float) -> void:
	_target_revenue = new_revenue

func _update_display(revenue: float) -> void:
	revenue_label.text = "\u00a5%s / \u00a5%s" % [_format_yen(revenue), _format_yen(GameManager.REVENUE_TARGET)]
	progress_bar.value = clampf(revenue / GameManager.REVENUE_TARGET, 0.0, 1.0) * 100.0

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
