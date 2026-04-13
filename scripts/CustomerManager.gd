extends Node

# ---------------------------------------------------------------------------
# Drink menu — name: base price (¥)
# ---------------------------------------------------------------------------
const DRINKS: Dictionary = {
	# Espresso station
	"Cafe Latte":        5.50,
	"Cappuccino":        5.00,
	"Cortado":           5.00,
	"Flat White":        5.50,
	# Drip station
	"Drip Coffee":       4.50,
	"Americano":         4.50,
	"Cold Brew":         5.00,
	# Matcha station
	"Matcha Latte":      6.00,
	"Hojicha Latte":     6.00,
	"Iced Matcha Latte": 6.50,
}

const TABLE_POSITIONS: Array = [
	Vector2(200.0, 200.0),
	Vector2(400.0, 200.0),
	Vector2(300.0, 350.0),
]

# ---------------------------------------------------------------------------
# Signals (relayed from individual customers so the UI has one place to connect)
# ---------------------------------------------------------------------------
signal order_ready(customer: Node)
signal customer_departed(customer: Node, was_served: bool)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var max_customers: int = 3
var active_customers: Array = []
var available_tables: Array = []
var spawn_timer: float = 0.0

var _customer_scene: PackedScene
var _cafe_view: Node2D

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	available_tables = TABLE_POSITIONS.duplicate()
	_customer_scene = load("res://scenes/Customer.tscn")
	_cafe_view = get_parent().get_node("CafeView")

func _process(delta: float) -> void:
	spawn_timer += delta
	var interval: float = GameManager.get_spawn_interval()
	if spawn_timer >= interval:
		spawn_timer = 0.0
		if active_customers.size() < max_customers and not available_tables.is_empty():
			spawn_customer()

# ---------------------------------------------------------------------------
# Spawn
# ---------------------------------------------------------------------------
func spawn_customer() -> void:
	var table_pos: Vector2 = get_available_table()
	if table_pos == Vector2(-1.0, -1.0):
		return

	var customer: CharacterBody2D = _customer_scene.instantiate()
	# Enter from off the left edge at the same y as the destination table
	customer.position = Vector2(-60.0, table_pos.y)
	customer.assigned_table = table_pos

	var drink_keys: Array = DRINKS.keys()
	var drink_name: String = drink_keys[randi() % drink_keys.size()]
	customer.set_order(drink_name, DRINKS[drink_name])

	customer.order_ready.connect(_on_customer_order_ready)
	customer.customer_left.connect(_on_customer_left)

	_cafe_view.add_child(customer)
	active_customers.append(customer)

# ---------------------------------------------------------------------------
# Table management
# ---------------------------------------------------------------------------
func get_available_table() -> Vector2:
	if available_tables.is_empty():
		return Vector2(-1.0, -1.0)
	var idx: int = randi() % available_tables.size()
	var pos: Vector2 = available_tables[idx]
	available_tables.remove_at(idx)
	return pos

func release_table(pos: Vector2) -> void:
	if pos == Vector2(-1.0, -1.0):
		return
	if not available_tables.has(pos):
		available_tables.append(pos)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_customer_order_ready(customer: Node) -> void:
	order_ready.emit(customer)

func _on_customer_left(customer: Node, was_served: bool) -> void:
	var idx: int = active_customers.find(customer)
	if idx != -1:
		active_customers.remove_at(idx)
	# Return the table slot — customer.assigned_table holds the original position
	if customer is CharacterBody2D:
		release_table((customer as CharacterBody2D).assigned_table)
	customer_departed.emit(customer, was_served)
