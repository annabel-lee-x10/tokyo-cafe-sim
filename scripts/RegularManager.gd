extends Node
## Autoload — RegularManager
## Tracks the five named regulars, their loyalty, and unlock events.

const REGULARS: Dictionary = {
	"keita": {
		"name":               "Keita",
		"archetype":          "Salaryman",
		"favourite":          "Cortado",
		"sprite_color":       Color(0.290, 0.435, 0.647),  # #4A6FA5
		"unlock_drink":       "Cortado",
		"unlock_drink_price": 5.00,
		"min_day":            2,
	},
	"yui": {
		"name":               "Yui",
		"archetype":          "Student",
		"favourite":          "Iced Matcha Latte",
		"sprite_color":       Color(0.647, 0.769, 0.647),  # #A5C4A5
		"unlock_drink":       "Cold Brew",
		"unlock_drink_price": 5.00,
		"min_day":            3,
	},
	"marco": {
		"name":               "Marco",
		"archetype":          "Tourist",
		"favourite":          "Flat White",
		"sprite_color":       Color(0.910, 0.627, 0.353),  # #E8A05A
		"unlock_drink":       "Flat White",
		"unlock_drink_price": 5.50,
		"min_day":            5,
	},
	"setsuko": {
		"name":               "Setsuko",
		"archetype":          "Artist",
		"favourite":          "Hojicha Latte",
		"sprite_color":       Color(0.690, 0.502, 0.502),  # #B08080
		"unlock_drink":       "Hojicha Espresso",
		"unlock_drink_price": 6.50,
		"min_day":            8,
	},
	"rin": {
		"name":               "Rin",
		"archetype":          "Blogger",
		"favourite":          "Single Origin Pour Over",
		"sprite_color":       Color(0.439, 0.439, 0.439),  # #707070
		"unlock_drink":       "Single Origin Pour Over",
		"unlock_drink_price": 7.00,
		"min_day":            14,
	},
}

const LOYALTY_THRESHOLDS: Array = [3, 8, 15]

signal loyalty_level_up(regular_id: String, level: int, regular_data: Dictionary)
signal drink_unlocked(regular_id: String, drink_name: String)
signal regular_scene_triggered(regular_id: String, level: int)

## Set externally by the future social media system; blocks Rin until >= 3.
var viral_post_count: int = 0

## Keyed by regular_id: { loyalty, visits, current_level, in_cafe }
var _state: Dictionary = {}

func _ready() -> void:
	for id in REGULARS.keys():
		_state[id] = {"loyalty": 0, "visits": 0, "current_level": 0, "in_cafe": false}

# ---------------------------------------------------------------------------
# Query API
# ---------------------------------------------------------------------------
func get_regular(id: String) -> Dictionary:
	return REGULARS.get(id, {})

func get_loyalty_level(regular_id: String) -> int:
	return _get_loyalty_level(_state.get(regular_id, {}).get("loyalty", 0))

func get_eligible_regulars() -> Array:
	var result: Array = []
	for id in REGULARS.keys():
		if _is_eligible(id):
			result.append(id)
	return result

func mark_in_cafe(regular_id: String, value: bool) -> void:
	if _state.has(regular_id):
		_state[regular_id]["in_cafe"] = value

# ---------------------------------------------------------------------------
# Serve event — called by Customer.receive_drink()
# ---------------------------------------------------------------------------
func on_regular_served(regular_id: String, drink_ordered: String) -> void:
	var st: Dictionary = _state.get(regular_id, {})
	if st.is_empty():
		return
	var data: Dictionary = REGULARS.get(regular_id, {})

	var old_loyalty: int = st["loyalty"]
	st["loyalty"] += 2 if drink_ordered == data.get("favourite", "") else 1
	st["visits"]  += 1
	st["in_cafe"]  = false

	var old_level: int = _get_loyalty_level(old_loyalty)
	var new_level: int = _get_loyalty_level(st["loyalty"])

	if new_level > old_level:
		st["current_level"] = new_level
		loyalty_level_up.emit(regular_id, new_level, data)
		regular_scene_triggered.emit(regular_id, new_level)
		if new_level == 3:
			drink_unlocked.emit(regular_id, data.get("unlock_drink", ""))

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------
func _is_eligible(id: String) -> bool:
	var data: Dictionary = REGULARS.get(id, {})
	var st:   Dictionary = _state.get(id, {})
	if data.is_empty() or st.is_empty():
		return false
	if GameManager.current_day < data["min_day"]:
		return false
	if st["in_cafe"]:
		return false
	if id == "rin" and viral_post_count < 3:
		return false
	return true

func _get_loyalty_level(loyalty: int) -> int:
	if loyalty >= LOYALTY_THRESHOLDS[2]: return 3
	if loyalty >= LOYALTY_THRESHOLDS[1]: return 2
	if loyalty >= LOYALTY_THRESHOLDS[0]: return 1
	return 0
