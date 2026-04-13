extends Node
## Autoload — EndingManager
## Evaluates ending conditions on game_over and surfaces results via signal.

const ENDINGS: Dictionary = {
	"true": {
		"title":   "Hanami in Full Bloom",
		"message": "Every regular found their table. Every member of staff found their place. The cherry blossoms have never bloomed so beautifully.",
	},
	"good": {
		"title":   "A Thriving Corner",
		"message": "Your cafe has become a beloved neighbourhood staple. The line out the door is proof enough.",
	},
	"bittersweet": {
		"title":   "The Quiet Close",
		"message": "The cafe survives, but the magic hasn't quite landed. Maybe next season.",
	},
	"bad": {
		"title":   "Closed for Business",
		"message": "The rent was too high, the drinks too slow. Hanami Cafe closes its doors.",
	},
}

signal ending_triggered(ending_id: String, title: String, message: String, stats: Dictionary)

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)

func _on_game_over(_won: bool) -> void:
	var ending_id := _evaluate()
	var data      := ENDINGS[ending_id]
	ending_triggered.emit(ending_id, data["title"], data["message"], _get_stats())

# ---------------------------------------------------------------------------
# Evaluation
# ---------------------------------------------------------------------------
func _evaluate() -> String:
	var rev     := GameManager.total_revenue
	var reg_max := _regulars_at_level(3)
	var reg_2p  := _regulars_at_level(2)
	var staff   := _staff_hired_count()
	var foll    := SocialManager.get_follower_count()

	if rev >= 15000.0 and reg_max >= 5 and staff >= 5 and foll >= 2000:
		return "true"
	if rev >= 15000.0 and reg_2p >= 3:
		return "good"
	if rev >= 10000.0:
		return "bittersweet"
	return "bad"

func _regulars_at_level(min_level: int) -> int:
	var count := 0
	for id in RegularManager.REGULARS.keys():
		if RegularManager.get_loyalty_level(id) >= min_level:
			count += 1
	return count

func _staff_hired_count() -> int:
	var count := 0
	for id in StaffManager._hired.keys():
		if StaffManager._hired[id]:
			count += 1
	return count

func _get_stats() -> Dictionary:
	return {
		"total_revenue":      int(GameManager.total_revenue),
		"days_played":        GameManager.current_day - 1,
		"regulars_befriended": _regulars_at_level(1),
		"staff_hired":         _staff_hired_count(),
		"followers":           SocialManager.get_follower_count(),
	}
