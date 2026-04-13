extends Node
## Autoload — SeasonManager
## Manages seasonal cycles, revenue modifiers, patience effects, and special events.

const SEASONS: Dictionary = {
	"spring": {
		"name":                  "Spring",
		"days":                  [1, 22],
		"bg_tint":               Color(1.00, 0.95, 0.97, 1.0),
		"revenue_modifier":      1.0,
		"seasonal_drink":        "Sakura Latte",
		"seasonal_drink_price":  7.00,
		"seasonal_drink_station":"espresso",
		"event_name":            "Cherry Blossom Festival",
		"event_desc":            "Double customers for the day!",
	},
	"summer": {
		"name":                  "Summer",
		"days":                  [23, 45],
		"bg_tint":               Color(0.97, 1.00, 0.93, 1.0),
		"revenue_modifier":      1.1,
		"seasonal_drink":        "Iced Yuzu",
		"seasonal_drink_price":  7.00,
		"seasonal_drink_station":"drip",
		"event_name":            "Heat Wave",
		"event_desc":            "Only cold drinks ordered, +20% tips",
	},
	"autumn": {
		"name":                  "Autumn",
		"days":                  [46, 67],
		"bg_tint":               Color(1.00, 0.95, 0.88, 1.0),
		"revenue_modifier":      1.0,
		"seasonal_drink":        "Pumpkin Chai",
		"seasonal_drink_price":  7.00,
		"seasonal_drink_station":"matcha",
		"event_name":            "Harvest Market",
		"event_desc":            "Nearby market sends extra foot traffic (+50% spawn rate)",
	},
	"winter": {
		"name":                  "Winter",
		"days":                  [68, 90],
		"bg_tint":               Color(0.93, 0.95, 1.00, 1.0),
		"revenue_modifier":      0.9,
		"seasonal_drink":        "Hot Chocolate Deluxe",
		"seasonal_drink_price":  7.50,
		"seasonal_drink_station":"espresso",
		"event_name":            "Holiday Rush",
		"event_desc":            "All order values +30%, but patience -20%",
	},
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal season_changed(season_id: String, season_data: Dictionary)
signal special_event_started(event_name: String, description: String)
signal seasonal_drink_unlocked(drink_name: String, station_id: String)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_season_id: String = "spring"
var _active_event: String = ""

func _ready() -> void:
	GameManager.day_ended.connect(_on_day_ended)
	current_season_id = _get_season_for_day(GameManager.current_day)

# ---------------------------------------------------------------------------
# Query API — called by other systems each frame or per-serve
# ---------------------------------------------------------------------------
func get_current_season() -> Dictionary:
	return SEASONS.get(current_season_id, SEASONS["spring"])

## Base seasonal revenue multiplier + active event + upgrade bonuses.
func get_revenue_modifier() -> float:
	var base: float = get_current_season().get("revenue_modifier", 1.0)
	if current_season_id == "summer" and UpgradeManager.is_purchased("cold_brew_tower"):
		base += 0.10
	if current_season_id == "spring" and UpgradeManager.is_purchased("garden_terrace"):
		base += 0.05
	if _active_event == "Holiday Rush":
		base += 0.30
	if _active_event == "Heat Wave":
		base += 0.20   # +20% tips during heat wave
	return base

## Patience multiplier from active special event.
func get_patience_multiplier() -> float:
	if _active_event == "Holiday Rush":
		return 0.80   # -20% patience during holiday rush
	return 1.0

## Spawn interval multiplier; <1.0 means faster spawning.
func get_spawn_interval_multiplier() -> float:
	match _active_event:
		"Cherry Blossom Festival": return 0.50   # double spawn rate
		"Harvest Market":          return 0.67   # +50% spawn rate
	return 1.0

## Extra simultaneous customers during festival events.
func get_event_max_customers_bonus() -> int:
	if _active_event == "Cherry Blossom Festival":
		return 2
	return 0

## True during Heat Wave — CustomerManager should only serve cold drinks.
func is_cold_drinks_only() -> bool:
	return _active_event == "Heat Wave"

func get_active_event() -> String:
	return _active_event

# ---------------------------------------------------------------------------
# Day-end handler
# ---------------------------------------------------------------------------
func _on_day_ended(day: int, _revenue: float) -> void:
	_active_event = ""   # clear yesterday's event

	var next_day := day + 1
	if next_day > GameManager.DAYS_TOTAL:
		return

	var new_season := _get_season_for_day(next_day)
	if new_season != current_season_id:
		current_season_id = new_season
		var sdata := SEASONS[current_season_id]
		season_changed.emit(current_season_id, sdata)
		if UpgradeManager.is_purchased("seasonal_board"):
			seasonal_drink_unlocked.emit(
				sdata.get("seasonal_drink", ""),
				sdata.get("seasonal_drink_station", "espresso")
			)

	# 10% chance of a special event active tomorrow
	if randf() < 0.10:
		var edata := SEASONS[current_season_id]
		_active_event = edata.get("event_name", "")
		special_event_started.emit(_active_event, edata.get("event_desc", ""))

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------
func _get_season_for_day(day: int) -> String:
	for id in SEASONS.keys():
		var bounds: Array = SEASONS[id]["days"]
		if day >= bounds[0] and day <= bounds[1]:
			return id
	return "spring"
