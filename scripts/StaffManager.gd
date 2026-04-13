extends Node
## Autoload — StaffManager
## Tracks hired staff and exposes effect multipliers consumed by other systems.

const STAFF: Dictionary = {
	"sota": {
		"name":           "Sota",
		"role":           "Barista",
		"effect_desc":    "Prep speed -20%",
		"portrait_color": Color(0.55, 0.75, 0.85),   # light blue
	},
	"chinatsu": {
		"name":           "Chinatsu",
		"role":           "Hostess",
		"effect_desc":    "Loyalty bonus +25%",
		"portrait_color": Color(0.90, 0.70, 0.75),   # pink
	},
	"kenji": {
		"name":           "Kenji",
		"role":           "Roaster",
		"effect_desc":    "Order value +15%",
		"portrait_color": Color(0.70, 0.50, 0.35),   # warm brown
	},
	"momo": {
		"name":           "Momo",
		"role":           "Influencer",
		"effect_desc":    "Follower gain x2",
		"portrait_color": Color(0.95, 0.80, 0.55),   # warm yellow
	},
	"taro": {
		"name":           "Taro",
		"role":           "Sous-Chef",
		"effect_desc":    "Combo bonus +10% all effects",
		"portrait_color": Color(0.60, 0.75, 0.60),   # sage green
	},
}

signal staff_hired(staff_id: String)

var _hired: Dictionary = {
	"sota":     false,
	"chinatsu": false,
	"kenji":    false,
	"momo":     false,
	"taro":     false,
}

# ---------------------------------------------------------------------------
# Hire
# ---------------------------------------------------------------------------
func hire(staff_id: String) -> void:
	if _hired.has(staff_id) and not _hired[staff_id]:
		_hired[staff_id] = true
		staff_hired.emit(staff_id)

func is_hired(staff_id: String) -> bool:
	return _hired.get(staff_id, false)

# ---------------------------------------------------------------------------
# Unlock checks — returns staff IDs that meet their condition but aren't hired
# ---------------------------------------------------------------------------
func get_unlockable_staff() -> Array:
	var result: Array = []
	for id in ["sota", "chinatsu", "kenji", "momo", "taro"]:
		if not _hired[id] and _check_unlock(id):
			result.append(id)
	return result

func _check_unlock(staff_id: String) -> bool:
	match staff_id:
		"sota":
			return GameManager.total_revenue >= 3000.0
		"chinatsu":
			return RegularManager.get_total_visits() >= 10
		"kenji":
			return GameManager.total_customers_served >= 50
		"momo":
			return SocialManager.get_follower_count() >= 500
		"taro":
			return _hired["sota"] and _hired["chinatsu"] \
				and _hired["kenji"] and _hired["momo"]
	return false

# ---------------------------------------------------------------------------
# Effect multipliers — called each time an effect is applied
# ---------------------------------------------------------------------------
func get_prep_speed_multiplier() -> float:
	var m := 1.0
	if _hired["sota"]:
		m *= 0.80
	if _hired["taro"]:
		m *= 0.90
	return m

func get_loyalty_multiplier() -> float:
	var m := 1.0
	if _hired["chinatsu"]:
		m *= 1.25
	if _hired["taro"]:
		m *= 1.10
	return m

func get_order_value_multiplier() -> float:
	var m := 1.0
	if _hired["kenji"]:
		m *= 1.15
	if _hired["taro"]:
		m *= 1.10
	return m

func get_follower_multiplier() -> float:
	var m := 1.0
	if _hired["momo"]:
		m *= 2.0
	if _hired["taro"]:
		m *= 1.10
	return m
