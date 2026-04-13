extends Node

## Maps newly-unlocked drinks to the station that handles them.
## Drinks already assigned to a station in Phase 3 don't need an entry here.
const DRINK_STATION_MAP: Dictionary = {
	"Hojicha Espresso":         "espresso",
	"Single Origin Pour Over":  "drip",
}

const STATIONS: Dictionary = {
	"espresso": {
		"name": "Espresso Machine",
		"drinks": ["Cafe Latte", "Cappuccino", "Cortado", "Flat White"],
		"prep_time": 8.0,
		"position": Vector2(100, 900),   # reserved for Phase 4 world-space markers
	},
	"drip": {
		"name": "Drip Brewer",
		"drinks": ["Drip Coffee", "Americano", "Cold Brew"],
		"prep_time": 12.0,
		"position": Vector2(300, 900),
	},
	"matcha": {
		"name": "Matcha Station",
		"drinks": ["Matcha Latte", "Hojicha Latte", "Iced Matcha Latte"],
		"prep_time": 10.0,
		"position": Vector2(500, 900),
	},
}

# station_id -> Station node
var _stations: Dictionary = {}
# station_id -> customer Node currently being prepped for
var _station_orders: Dictionary = {}

var _selected_customer: Node = null
var _order_queue_ui: Node = null

func _ready() -> void:
	# Configure every Station node that registered itself via add_to_group("stations")
	for station in get_tree().get_nodes_in_group("stations"):
		var data: Dictionary = STATIONS.get(station.station_id, {})
		if data.is_empty():
			continue
		station.setup(data["name"], data["drinks"], data["prep_time"])
		_stations[station.station_id] = station
		station.station_tapped.connect(_on_station_tapped)
		station.prep_complete.connect(_on_prep_complete)

	# Wire selection signals from the order queue
	_order_queue_ui = get_tree().current_scene.get_node("UIPanel/Layout/OrderQueue")
	_order_queue_ui.order_selected.connect(_on_order_selected)
	_order_queue_ui.order_deselected.connect(_on_order_deselected)

	# Clean up stale station bookings when a customer departs mid-prep
	var cm: Node = get_tree().current_scene.get_node("CustomerManager")
	cm.customer_departed.connect(_on_customer_departed)

	# Extend live station drink lists when a regular unlocks a new drink
	RegularManager.drink_unlocked.connect(_on_drink_unlocked)

# ---------------------------------------------------------------------------
# Order selection
# ---------------------------------------------------------------------------
func _on_order_selected(customer: Node) -> void:
	_selected_customer = customer

func _on_order_deselected() -> void:
	_selected_customer = null

# ---------------------------------------------------------------------------
# Station tap handling
# ---------------------------------------------------------------------------
func _on_station_tapped(station_id: String) -> void:
	var station = _stations.get(station_id)
	if station == null:
		return

	if station.is_idle():
		_handle_idle_tap(station_id, station)
	elif station.is_ready():
		_handle_ready_tap(station_id, station)

func _handle_idle_tap(station_id: String, station) -> void:
	if _selected_customer == null or not is_instance_valid(_selected_customer):
		return

	var drink: String = _selected_customer.order
	# Check the live drinks list on the node (updated at runtime for unlocked drinks)
	if station.drinks.has(drink):
		# Correct station — begin prep
		station.start_prep(drink)
		_station_orders[station_id] = _selected_customer
		_order_queue_ui.set_in_progress(_selected_customer)
		_selected_customer = null
	else:
		# Wrong station — brief red flash, no penalty
		station.flash_red()

func _handle_ready_tap(station_id: String, station) -> void:
	var customer: Node = _station_orders.get(station_id)
	if customer and is_instance_valid(customer):
		customer.receive_drink()   # emits customer_left → revenue update → cleanup chain
	_station_orders.erase(station_id)
	station.collect_drink()

# ---------------------------------------------------------------------------
# Cleanup orphaned station bookings when a customer departs mid-prep
# ---------------------------------------------------------------------------
func _on_customer_departed(customer: Node, _was_served: bool) -> void:
	for station_id in _station_orders.keys():
		if _station_orders[station_id] == customer:
			_station_orders[station_id] = null   # station keeps prepping; drink is wasted
	if _selected_customer == customer:
		_selected_customer = null

func _on_prep_complete(_station_id: String) -> void:
	pass  # Station handles its own pulse animation

# ---------------------------------------------------------------------------
# Drink unlock — add new drinks to the appropriate station's live list
# ---------------------------------------------------------------------------
func add_drink_to_station(drink_name: String, station_id: String) -> void:
	var station = _stations.get(station_id)
	if station == null:
		return
	if not station.drinks.has(drink_name):
		station.drinks.append(drink_name)

func _on_drink_unlocked(_regular_id: String, drink_name: String) -> void:
	var station_id: String = DRINK_STATION_MAP.get(drink_name, "")
	if station_id.is_empty():
		return   # already in an existing station list; no action needed
	add_drink_to_station(drink_name, station_id)
