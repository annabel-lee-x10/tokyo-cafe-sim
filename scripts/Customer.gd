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
				patience_bar.size.x = PATIENCE_BAR_WIDTH * (patience_node.time_left / PATIENCE_DURATION)
		State.LEAVING:
			position = position.lerp(EXIT_POSITION, LERP_WEIGHT * delta)
			if position.distance_to(EXIT_POSITION) < 6.0:
				queue_free()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

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
	GameManager.add_revenue(revenue_value)
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
	patience_bar.size.x = PATIENCE_BAR_WIDTH
	patience_bar.visible = true
	patience_node.start()
	show_order_bubble()

func _on_patience_timeout() -> void:
	if state == State.WAITING:
		customer_left.emit(self, false)
		leave_cafe()
