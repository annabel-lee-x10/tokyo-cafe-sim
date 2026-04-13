extends CharacterBody2D

enum State { WALKING_IN, SEATED, WAITING, SERVED, LEAVING }

signal order_ready(customer: Node)
signal customer_left(customer: Node, was_served: bool)

## Lerp weight — higher feels snappier; 3.0 gives a smooth ease-in
const LERP_WEIGHT: float = 3.0
const EXIT_POSITION: Vector2 = Vector2(-120.0, 500.0)
const PATIENCE_DURATION: float = 30.0
const PATIENCE_BAR_WIDTH: float = 48.0

var state: State = State.WALKING_IN
var assigned_table: Vector2 = Vector2.ZERO
var order: String = ""
var patience_timer: float = PATIENCE_DURATION
var revenue_value: float = 0.0
var regular_id: String = ""   # empty = random walk-in

@onready var order_bubble: Label    = $OrderBubble
@onready var patience_node: Timer   = $Patience
@onready var patience_bar: ColorRect = $PatienceBar

func _ready() -> void:
	order_bubble.visible = false
	patience_bar.visible = false
	patience_bar.size.x = PATIENCE_BAR_WIDTH
	patience_node.wait_time = PATIENCE_DURATION
	patience_node.timeout.connect(_on_patience_timeout)

func _process(delta: float) -> void:
	match state:
		State.WALKING_IN:
			position = position.lerp(assigned_table, LERP_WEIGHT * delta)
			if position.distance_to(assigned_table) < 4.0:
				position = assigned_table
				_enter_waiting()
		State.WAITING:
			if not patience_node.is_stopped():
				patience_bar.size.x = PATIENCE_BAR_WIDTH * (patience_node.time_left / patience_node.wait_time)
		State.LEAVING:
			position = position.lerp(EXIT_POSITION, LERP_WEIGHT * delta)
			if position.distance_to(EXIT_POSITION) < 6.0:
				queue_free()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Sets the sprite to a 48×64 colored rect — used for named regulars.
func set_body_color(color: Color) -> void:
	$Body.color    = color
	$Body.position = Vector2(-24.0, -64.0)
	$Body.size     = Vector2(48.0, 64.0)

func set_order(drink_name: String, price: float) -> void:
	order = drink_name
	revenue_value = price

func show_order_bubble() -> void:
	order_bubble.text = order
	order_bubble.visible = true
	order_ready.emit(self)

func receive_drink() -> void:
	if state != State.WAITING:
		return
	state = State.SERVED
	patience_node.stop()
	order_bubble.visible = false
	patience_bar.visible = false
	if regular_id != "":
		RegularManager.on_regular_served(regular_id, order)
	var amount := revenue_value \
		* StaffManager.get_order_value_multiplier() \
		* UpgradeManager.get_order_value_multiplier() \
		* SeasonManager.get_revenue_modifier()
	amount += UpgradeManager.get_upsell_value()
	GameManager.add_revenue(amount)
	customer_left.emit(self, true)
	leave_cafe()

func leave_cafe() -> void:
	state = State.LEAVING
	order_bubble.visible = false
	patience_bar.visible = false

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _enter_waiting() -> void:
	state = State.WAITING
	var effective_patience := PATIENCE_DURATION \
		* UpgradeManager.get_patience_multiplier() \
		* SeasonManager.get_patience_multiplier()
	patience_bar.size.x = PATIENCE_BAR_WIDTH
	patience_bar.visible = true
	patience_node.wait_time = effective_patience
	patience_node.start()
	show_order_bubble()

func _on_patience_timeout() -> void:
	if state == State.WAITING:
		customer_left.emit(self, false)
		leave_cafe()
