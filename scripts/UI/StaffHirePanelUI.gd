extends Control
## Staff hire panel — shown once per day-end when unlockable staff are available.
## Listens for RegularSceneQueue.queue_exhausted so it never interrupts a dialogue.

@onready var portrait:         ColorRect = $Background/Card/Portrait
@onready var name_label:       Label     = $Background/Card/NameLabel
@onready var role_label:       Label     = $Background/Card/RoleLabel
@onready var effect_label:     Label     = $Background/Card/EffectLabel
@onready var hire_button:      Button    = $Background/Card/HireButton
@onready var later_button:     Button    = $Background/Card/LaterButton

var _pending_id: String = ""

func _ready() -> void:
	visible = false
	hire_button.pressed.connect(_on_hire_pressed)
	later_button.pressed.connect(_on_later_pressed)
	# RegularSceneQueue is a sibling node — connect once the scene is ready
	var rsq: Node = get_parent().get_node_or_null("RegularSceneQueue")
	if rsq != null:
		rsq.queue_exhausted.connect(_on_queue_exhausted)

# ---------------------------------------------------------------------------
# Day-end handler
# ---------------------------------------------------------------------------
func _on_queue_exhausted() -> void:
	var available: Array = StaffManager.get_unlockable_staff()
	if available.is_empty():
		return
	_show_offer(available[0])

func _show_offer(staff_id: String) -> void:
	var data: Dictionary = StaffManager.STAFF.get(staff_id, {})
	_pending_id        = staff_id
	portrait.color     = data.get("portrait_color", Color(0.5, 0.5, 0.5))
	name_label.text    = data.get("name", staff_id.capitalize())
	role_label.text    = data.get("role", "")
	effect_label.text  = data.get("effect_desc", "")
	visible            = true

# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------
func _on_hire_pressed() -> void:
	if _pending_id == "":
		return
	StaffManager.hire(_pending_id)
	_pending_id = ""
	visible = false

func _on_later_pressed() -> void:
	_pending_id = ""
	visible = false
