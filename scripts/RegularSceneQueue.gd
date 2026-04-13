extends Node
## Queues loyalty scenes and plays one per day-end, never during active service.

var _queue: Array = []          # Array[{regular_id, level}]
var _dialogue_panel: Control    # set in _ready()

func _ready() -> void:
	RegularManager.regular_scene_triggered.connect(_on_scene_triggered)
	GameManager.day_ended.connect(_on_day_ended)
	_dialogue_panel = get_tree().current_scene.get_node("DialoguePanel")

func _on_scene_triggered(regular_id: String, level: int) -> void:
	_queue.append({"regular_id": regular_id, "level": level})

## Plays at most one queued scene per day — fires after the day ends.
func _on_day_ended(_day: int, _revenue: float) -> void:
	if _queue.is_empty() or _dialogue_panel == null:
		return
	var entry: Dictionary = _queue.pop_front()
	_dialogue_panel.show_dialogue(entry["regular_id"], entry["level"])
