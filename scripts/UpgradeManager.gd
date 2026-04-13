extends Node
## Autoload — UpgradeManager
## Tracks purchased upgrades and exposes their combined effects.

const UPGRADES: Dictionary = {
	# ── Equipment ──────────────────────────────────────────────────────────────
	"faster_espresso": {
		"name":        "Faster Espresso",
		"category":    "equipment",
		"cost":        1000,
		"effect_desc": "Espresso prep time -30%",
	},
	"premium_grinder": {
		"name":        "Premium Grinder",
		"category":    "equipment",
		"cost":        2000,
		"effect_desc": "All drink value +10%",
	},
	"auto_frother": {
		"name":        "Auto-Frother",
		"category":    "equipment",
		"cost":        3500,
		"effect_desc": "Unlock Vanilla Latte + Oat Milk Latte",
	},
	"cold_brew_tower": {
		"name":        "Cold Brew Tower",
		"category":    "equipment",
		"cost":        5000,
		"effect_desc": "Unlock Nitro Cold Brew + Float, summer revenue +10%",
	},
	# ── Decor ──────────────────────────────────────────────────────────────────
	"window_seats": {
		"name":        "Window Seats",
		"category":    "decor",
		"cost":        800,
		"effect_desc": "Max tables +1 (4 total)",
	},
	"garden_terrace": {
		"name":        "Garden Terrace",
		"category":    "decor",
		"cost":        2500,
		"effect_desc": "Max tables +1 (5 total), spring revenue +5%",
	},
	"cozy_lighting": {
		"name":        "Cozy Lighting",
		"category":    "decor",
		"cost":        1500,
		"effect_desc": "Patience timer +15%",
	},
	"art_wall": {
		"name":        "Art Wall",
		"category":    "decor",
		"cost":        3000,
		"effect_desc": "Social post chance +10%",
	},
	# ── Menu ───────────────────────────────────────────────────────────────────
	"pastry_case": {
		"name":        "Pastry Case",
		"category":    "menu",
		"cost":        600,
		"effect_desc": "Pastry upsell +20 per order (40% chance)",
	},
	"seasonal_board": {
		"name":        "Seasonal Special Board",
		"category":    "menu",
		"cost":        1200,
		"effect_desc": "Unlock seasonal drink each season",
	},
	"premium_tea_set": {
		"name":        "Premium Tea Set",
		"category":    "menu",
		"cost":        2000,
		"effect_desc": "Unlock Genmaicha, Hojicha Tea, Sencha",
	},
	"chefs_dessert": {
		"name":        "Chef's Dessert",
		"category":    "menu",
		"cost":        4000,
		"effect_desc": "Dessert upsell +50 per order (25% chance)",
	},
}

## Ordered lists per tab — controls display order in UpgradePanelUI.
const CATEGORY_ORDER: Dictionary = {
	"equipment": ["faster_espresso", "premium_grinder", "auto_frother", "cold_brew_tower"],
	"decor":     ["window_seats", "garden_terrace", "cozy_lighting", "art_wall"],
	"menu":      ["pastry_case", "seasonal_board", "premium_tea_set", "chefs_dessert"],
}

signal upgrade_purchased(upgrade_id: String)

var _purchased: Dictionary = {}

func _ready() -> void:
	# Restore purchased upgrades from GameManager persistent state
	for id in GameManager.purchased_upgrades:
		_purchased[id] = true

# ---------------------------------------------------------------------------
# Purchase
# ---------------------------------------------------------------------------
func purchase(upgrade_id: String) -> bool:
	if _purchased.get(upgrade_id, false):
		return false
	var data: Dictionary = UPGRADES.get(upgrade_id, {})
	if data.is_empty():
		return false
	var cost: int = data.get("cost", 0)
	if GameManager.total_revenue < cost:
		return false
	GameManager.deduct_revenue(cost)
	_purchased[upgrade_id] = true
	GameManager.purchased_upgrades.append(upgrade_id)
	upgrade_purchased.emit(upgrade_id)
	return true

func is_purchased(upgrade_id: String) -> bool:
	return _purchased.get(upgrade_id, false)

# ---------------------------------------------------------------------------
# Effect getters
# ---------------------------------------------------------------------------

## Prep-time multiplier for a specific station (Faster Espresso only affects espresso).
func get_station_prep_multiplier(station_id: String) -> float:
	if station_id == "espresso" and is_purchased("faster_espresso"):
		return 0.70
	return 1.0

## Order value multiplier from Premium Grinder.
func get_order_value_multiplier() -> float:
	return 1.10 if is_purchased("premium_grinder") else 1.0

## Patient timer multiplier from Cozy Lighting.
func get_patience_multiplier() -> float:
	return 1.15 if is_purchased("cozy_lighting") else 1.0

## Max-customers bonus from table upgrades.
func get_max_customers_bonus() -> int:
	var bonus := 0
	if is_purchased("window_seats"):
		bonus += 1
	if is_purchased("garden_terrace"):
		bonus += 1
	return bonus

## Additional flat post-chance bonus from Art Wall (added before multiplier).
func get_post_chance_bonus() -> float:
	return 0.10 if is_purchased("art_wall") else 0.0

## Random upsell revenue added per served drink (Pastry Case and/or Chef's Dessert).
func get_upsell_value() -> float:
	var total := 0.0
	if is_purchased("pastry_case") and randf() < 0.40:
		total += 20.0
	if is_purchased("chefs_dessert") and randf() < 0.25:
		total += 50.0
	return total
