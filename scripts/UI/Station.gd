extends VBoxContainer

enum State { IDLE, PREPPING, READY }

signal station_tapped(station_id: String)
signal prep_complete(station_id: String)

@export var station_id: String = ""

var state: State = State.IDLE
var drinks: Array = []
var prep_duration: float = 8.0
var _prep_elapsed: float = 0.0
var _active_prep_duration: float = 8.0   # actual duration for current prep (with staff multiplier)
var _prepping_drink: String = ""
var _pulse_tween: Tween = null

@onready var name_label: Label         = $NameLabel
@onready var prep_button: Button       = $PrepButton
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var drink_label: Label        = $DrinkLabel

func _ready() -> void:
	add_to_group("stations")
	progress_bar.visible = false
	progress_bar.max_value = 1.0
	drink_label.visible = false
	prep_button.pressed.connect(_on_button_pressed)

func _process(delta: float) -> void:
	if state != State.PREPPING:
		return
	_prep_elapsed += delta
	progress_bar.value = minf(_prep_elapsed / _active_prep_duration, 1.0)
	if _prep_elapsed >= _active_prep_duration:
		_complete_prep()

# ---------------------------------------------------------------------------
# Called by StationManager._ready() after all nodes are in the tree
# ---------------------------------------------------------------------------
func setup(display_name: String, drink_list: Array, duration: float) -> void:
	drinks = drink_list
	prep_duration = duration
	name_label.text = display_name

# ---------------------------------------------------------------------------
# State queries
# ---------------------------------------------------------------------------
func is_idle() -> bool:
	return state == State.IDLE

func is_ready() -> bool:
	return state == State.READY

# ---------------------------------------------------------------------------
# State transitions (called by StationManager)
# ---------------------------------------------------------------------------
func start_prep(drink_name: String) -> void:
	state = State.PREPPING
	_prepping_drink = drink_name
	_prep_elapsed = 0.0
	_active_prep_duration = prep_duration \
		* StaffManager.get_prep_speed_multiplier() \
		* UpgradeManager.get_station_prep_multiplier(station_id)
	prep_button.disabled = true
	progress_bar.visible = true
	progress_bar.value = 0.0
	drink_label.text = drink_name
	drink_label.visible = true

func flash_red() -> void:
	var tween := create_tween()
	tween.tween_property(prep_button, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.05)
	tween.tween_property(prep_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func collect_drink() -> void:
	state = State.IDLE
	_prepping_drink = ""
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	prep_button.modulate = Color.WHITE
	prep_button.disabled = false
	progress_bar.visible = false
	drink_label.visible = false

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------
func _complete_prep() -> void:
	state = State.READY
	progress_bar.value = 1.0
	prep_button.disabled = false
	prep_complete.emit(station_id)
	_start_pulse()

func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(prep_button, "modulate", Color(1.0, 0.8, 0.0, 1.0), 0.35)
	_pulse_tween.tween_property(prep_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)

func _on_button_pressed() -> void:
	station_tapped.emit(station_id)
