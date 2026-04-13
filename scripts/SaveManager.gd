extends Node
## Autoload — SaveManager
## JSON save/load at "user://hanami_save.json".
## Auto-saves at end of each day; supports manual save + new game reset.

const SAVE_PATH := "user://hanami_save.json"

signal game_saved()
signal game_loaded()

func _ready() -> void:
	GameManager.day_ended.connect(_on_day_ended)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Save using current autoload state.  Safe to call at any time.
func save() -> void:
	var data := {
		"version": 1,
		"current_day":           GameManager.current_day,
		"total_revenue":         GameManager.total_revenue,
		"total_customers_served": GameManager.total_customers_served,
		"purchased_upgrades":    GameManager.purchased_upgrades.duplicate(),
		"regular_state":         _serialize_regular_state(),
		"staff_hired":           StaffManager._hired.duplicate(),
		"followers":             SocialManager.followers,
		"viral_post_count":      SocialManager.viral_post_count,
		"social_unlocked":       SocialManager.social_unlocked.duplicate(),
		"current_season":        SeasonManager.current_season_id,
		"settings": {
			"master_volume": AudioManager.master_volume,
			"bgm_volume":    AudioManager.bgm_volume,
			"sfx_volume":    AudioManager.sfx_volume,
		},
	}
	_write_file(data)
	game_saved.emit()

## Load save data into all autoloads.  Call BEFORE changing to Main scene.
## Returns false if no save exists.
func load_game() -> bool:
	var data := _read_file()
	if data.is_empty():
		return false

	GameManager.current_day            = data.get("current_day", 1)
	GameManager.total_revenue          = data.get("total_revenue", 0.0)
	GameManager.total_customers_served = data.get("total_customers_served", 0)
	GameManager.purchased_upgrades     = data.get("purchased_upgrades", []).duplicate()

	var reg_state: Dictionary = data.get("regular_state", {})
	for id in reg_state.keys():
		if RegularManager._state.has(id):
			RegularManager._state[id] = (reg_state[id] as Dictionary).duplicate()

	var staff: Dictionary = data.get("staff_hired", {})
	for id in staff.keys():
		if StaffManager._hired.has(id):
			StaffManager._hired[id] = staff[id]

	UpgradeManager._purchased.clear()
	for id in GameManager.purchased_upgrades:
		UpgradeManager._purchased[id] = true

	SocialManager.followers         = data.get("followers", 0)
	SocialManager.viral_post_count  = data.get("viral_post_count", 0)
	SocialManager.social_unlocked   = data.get("social_unlocked", []).duplicate()
	RegularManager.viral_post_count = SocialManager.viral_post_count

	SeasonManager.current_season_id  = data.get("current_season", "spring")

	var settings: Dictionary = data.get("settings", {})
	AudioManager.set_master_volume(settings.get("master_volume", 1.0))
	AudioManager.set_bgm_volume(settings.get("bgm_volume", 0.80))
	AudioManager.set_sfx_volume(settings.get("sfx_volume", 1.0))

	game_loaded.emit()
	return true

## Reset all autoload state and delete save file — used by New Game.
func new_game() -> void:
	_delete_file()
	GameManager.current_day            = 1
	GameManager.total_revenue          = 0.0
	GameManager.total_customers_served = 0
	GameManager.customers_served       = 0
	GameManager.purchased_upgrades     = []
	for id in RegularManager._state.keys():
		RegularManager._state[id] = {"loyalty": 0, "visits": 0, "current_level": 0, "in_cafe": false}
	RegularManager.viral_post_count = 0
	for id in StaffManager._hired.keys():
		StaffManager._hired[id] = false
	UpgradeManager._purchased.clear()
	SocialManager.followers        = 0
	SocialManager.viral_post_count = 0
	SocialManager.social_unlocked  = []
	SeasonManager.current_season_id = "spring"
	SeasonManager._active_event     = ""

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_day_ended(_day: int, _revenue: float) -> void:
	# Deferred so GameManager.current_day has already incremented
	call_deferred("save")

# ---------------------------------------------------------------------------
# File I/O
# ---------------------------------------------------------------------------
func _write_file(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _read_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var result = json.get_data()
	return result if result is Dictionary else {}

func _delete_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _serialize_regular_state() -> Dictionary:
	var result := {}
	for id in RegularManager._state.keys():
		result[id] = (RegularManager._state[id] as Dictionary).duplicate()
	return result
