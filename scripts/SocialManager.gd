extends Node
## Autoload — SocialManager
## Handles social-media posts, follower count, and viral drink unlocks.

## Drinks not in any station's base list — eligible for early viral unlock.
const SOCIAL_UNLOCKABLE: Dictionary = {
	"Hojicha Espresso":        "setsuko",
	"Single Origin Pour Over": "rin",
}

## Drinks with a higher chance of generating a post.
const SIGNATURE_DRINKS: Array = [
	"Hojicha Espresso",
	"Single Origin Pour Over",
	"Iced Matcha Latte",
	"Matcha Latte",
]

const BASE_CHANCE_SIGNATURE: float = 0.15
const BASE_CHANCE_REGULAR:   float = 0.05
const VIRAL_CHANCE:          float = 0.02

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal post_generated(post_type: String, follower_gain: int)
signal viral_post(effect_desc: String)
signal followers_changed(new_count: int)
signal social_drink_unlocked(regular_id: String, drink_name: String)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var followers: int = 0
var viral_post_count: int = 0
var social_unlocked: Array = []   # drink names already unlocked by viral

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func get_follower_count() -> int:
	return followers

## Called by CustomerManager after each successful serve.
func on_customer_served(drink_name: String) -> void:
	var base := BASE_CHANCE_SIGNATURE if SIGNATURE_DRINKS.has(drink_name) \
		else BASE_CHANCE_REGULAR
	var chance := (base + UpgradeManager.get_post_chance_bonus()) \
		* StaffManager.get_follower_multiplier()
	if randf() >= chance:
		return

	# Check for viral post first, then review vs photo
	if randf() < VIRAL_CHANCE * StaffManager.get_follower_multiplier():
		_handle_viral_post()
	elif randf() < 0.5:
		_add_followers("review", 100)
	else:
		_add_followers("photo", 50)

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------
func _add_followers(post_type: String, gain: int) -> void:
	followers += gain
	post_generated.emit(post_type, gain)
	followers_changed.emit(followers)

func _handle_viral_post() -> void:
	viral_post_count += 1
	followers += 500
	RegularManager.viral_post_count = viral_post_count
	followers_changed.emit(followers)

	var effect := _try_unlock_drink()
	viral_post.emit(effect)
	post_generated.emit("viral", 500)

func _try_unlock_drink() -> String:
	## Picks a random social-unlockable drink that the player hasn't earned via
	## loyalty yet, and early-unlocks it via social_drink_unlocked signal.
	var available: Array = []
	for drink in SOCIAL_UNLOCKABLE.keys():
		var rid: String = SOCIAL_UNLOCKABLE[drink]
		if not social_unlocked.has(drink) and RegularManager.get_loyalty_level(rid) < 3:
			available.append({"id": rid, "drink": drink})
	if available.is_empty():
		return "Viral post! +500 followers"
	var choice: Dictionary = available[randi() % available.size()]
	social_unlocked.append(choice["drink"])
	social_drink_unlocked.emit(choice["id"], choice["drink"])
	return "Viral post! %s now available!" % choice["drink"]
