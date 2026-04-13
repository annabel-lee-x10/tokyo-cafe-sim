extends Node

# ---------------------------------------------------------------------------
# Drink menu — mutable so drink_unlocked events can extend it at runtime
# ---------------------------------------------------------------------------
var DRINKS: Dictionary = {
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

## Chance (0–1) that an eligible regular spawns instead of a walk-in.
const REGULAR_SPAWN_CHANCE: float = 0.30

# ---------------------------------------------------------------------------
# Signals
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
	_customer_scene  = load("res://scenes/Customer.tscn")
	_cafe_view       = get_parent().get_node("CafeView")
	RegularManager.drink_unlocked.connect(_on_drink_unlocked)

func _process(delta: float) -> void:
	spawn_timer += delta
	var interval: float = GameManager.get_spawn_interval()
	if spawn_timer >= interval:
		spawn_timer = 0.0
		if active_customers.size() < max_customers and not available_tables.is_empty():
			_decide_and_spawn()

# ---------------------------------------------------------------------------
# Spawn decision
# ---------------------------------------------------------------------------
func _decide_and_spawn() -> void:
	var eligible: Array = RegularManager.get_eligible_regulars()
	if not eligible.is_empty() and randf() < REGULAR_SPAWN_CHANCE:
		var id: String = eligible[randi() % eligible.size()]
		_spawn_regular(id)
	else:
		spawn_customer()

func spawn_customer() -> void:
	var table_pos: Vector2 = get_available_table()
	if table_pos == Vector2(-1.0, -1.0):
		return
	var customer: CharacterBody2D = _customer_scene.instantiate()
	customer.position      = Vector2(-60.0, table_pos.y)
	customer.assigned_table = table_pos
	var drink_keys: Array = DRINKS.keys()
	var drink_name: String = drink_keys[randi() % drink_keys.size()]
	customer.set_order(drink_name, DRINKS[drink_name])
	_connect_and_track(customer)

func _spawn_regular(regular_id: String) -> void:
	var table_pos: Vector2 = get_available_table()
	if table_pos == Vector2(-1.0, -1.0):
		return
	var data: Dictionary = RegularManager.get_regular(regular_id)
	var customer: CharacterBody2D = _customer_scene.instantiate()
	customer.position       = Vector2(-60.0, table_pos.y)
	customer.assigned_table = table_pos
	customer.regular_id     = regular_id
	customer.set_body_color(data["sprite_color"])
	# Regular orders favourite if available, else a random walk-in drink
	var drink_name: String = data.get("favourite", "")
	if drink_name.is_empty() or not DRINKS.has(drink_name):
		var keys: Array = DRINKS.keys()
		drink_name = keys[randi() % keys.size()]
	customer.set_order(drink_name, DRINKS.get(drink_name, 4.50))
	RegularManager.mark_in_cafe(regular_id, true)
	_connect_and_track(customer)

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
# Drink unlock (adds new drinks to the live menu at runtime)
# ---------------------------------------------------------------------------
func add_drink(drink_name: String, price: float) -> void:
	if not DRINKS.has(drink_name):
		DRINKS[drink_name] = price

func _on_drink_unlocked(regular_id: String, drink_name: String) -> void:
	var data: Dictionary = RegularManager.get_regular(regular_id)
	add_drink(drink_name, data.get("unlock_drink_price", 5.50))

# ---------------------------------------------------------------------------
# Signal plumbing
# ---------------------------------------------------------------------------
func _connect_and_track(customer: CharacterBody2D) -> void:
	customer.order_ready.connect(_on_customer_order_ready)
	customer.customer_left.connect(_on_customer_left)
	_cafe_view.add_child(customer)
	active_customers.append(customer)

func _on_customer_order_ready(customer: Node) -> void:
	order_ready.emit(customer)

func _on_customer_left(customer: Node, was_served: bool) -> void:
	var idx: int = active_customers.find(customer)
	if idx != -1:
		active_customers.remove_at(idx)
	if customer is CharacterBody2D:
		release_table((customer as CharacterBody2D).assigned_table)
	# Un-served regulars: clear in_cafe flag (served ones are cleared in on_regular_served)
	if not was_served and "regular_id" in customer and customer.regular_id != "":
		RegularManager.mark_in_cafe(customer.regular_id, false)
	customer_departed.emit(customer, was_served)
