extends Node

# ---------------------------------------------------------------------------
# Configuration constants
# ---------------------------------------------------------------------------
const DAY_DURATION: float = 180.0
const DAYS_TOTAL: int = 90
const REVENUE_TARGET: float = 15000.0

## Spawn interval lerps from MAX down to MIN as revenue_progress goes 0 → 1
const SPAWN_INTERVAL_MAX: float = 12.0
const SPAWN_INTERVAL_MIN: float = 5.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_day: int = 1
var total_revenue: float = 0.0
var day_timer: float = 0.0
var customers_served: int = 0
var total_customers_served: int = 0   # cumulative, never resets — used by StaffManager
var purchased_upgrades: Array = []    # persisted by UpgradeManager on each purchase

var _day_active: bool = false

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal revenue_changed(new_revenue: float, target: float)
signal day_ended(day: int, revenue: float)
signal game_over(won: bool)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	start_day()

func _process(delta: float) -> void:
	if not _day_active:
		return
	day_timer += delta
	if day_timer >= DAY_DURATION:
		end_day()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func start_day() -> void:
	day_timer = 0.0
	customers_served = 0
	_day_active = true

func end_day() -> void:
	_day_active = false
	day_ended.emit(current_day, total_revenue)
	current_day += 1
	if current_day > DAYS_TOTAL:
		game_over.emit(total_revenue >= REVENUE_TARGET)

func add_revenue(amount: float) -> void:
	total_revenue += amount
	customers_served += 1
	total_customers_served += 1
	revenue_changed.emit(total_revenue, REVENUE_TARGET)

func deduct_revenue(amount: float) -> void:
	total_revenue = maxf(total_revenue - amount, 0.0)
	revenue_changed.emit(total_revenue, REVENUE_TARGET)

func get_revenue_progress() -> float:
	return clampf(total_revenue / REVENUE_TARGET, 0.0, 1.0)

func get_spawn_interval() -> float:
	return lerpf(SPAWN_INTERVAL_MAX, SPAWN_INTERVAL_MIN, get_revenue_progress())
