extends Node
## Autoload — AudioManager
## BGM crossfade + one-shot SFX.  All audio paths are placeholders;
## missing files are skipped silently.

const CROSSFADE_TIME: float = 0.5
const DB_SILENCE: float     = -80.0

# ---------------------------------------------------------------------------
# Volume state (public — SaveManager reads/writes these directly)
# ---------------------------------------------------------------------------
var master_volume: float = 1.0
var bgm_volume:    float = 0.80
var sfx_volume:    float = 1.00

var _bgm_a:       AudioStreamPlayer = null
var _bgm_b:       AudioStreamPlayer = null
var _bgm_primary: bool = true   # true = _bgm_a is the active track
var _current_bgm: String = ""
var _day_active:  bool = false  # mirrors GameManager._day_active for BGM switching

func _ready() -> void:
	_bgm_a = AudioStreamPlayer.new()
	_bgm_b = AudioStreamPlayer.new()
	add_child(_bgm_a)
	add_child(_bgm_b)
	_set_bgm_volumes()

	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	RegularManager.loyalty_level_up.connect(func(_id, _lv, _d): play_sfx("level_up"))
	StaffManager.staff_hired.connect(func(_id): play_sfx("unlock"))
	SocialManager.viral_post.connect(func(_e): play_sfx("viral"))
	SeasonManager.season_changed.connect(func(_id, _d): play_sfx("unlock"))

func _process(_delta: float) -> void:
	if not _day_active:
		return
	var remaining := maxf(GameManager.DAY_DURATION - GameManager.day_timer, 0.0)
	var target := "rush" if (remaining < 60.0 or GameManager.get_spawn_interval() < 7.0) else "morning"
	if target != _current_bgm:
		play_bgm(target)

# ---------------------------------------------------------------------------
# BGM
# ---------------------------------------------------------------------------
func play_bgm(bgm_name: String) -> void:
	if bgm_name == _current_bgm:
		return
	_current_bgm = bgm_name
	var path := "res://audio/bgm_%s.ogg" % bgm_name

	var out_player := _bgm_a if _bgm_primary else _bgm_b
	var in_player  := _bgm_b if _bgm_primary else _bgm_a
	_bgm_primary   = not _bgm_primary

	if ResourceLoader.exists(path):
		in_player.stream = load(path)
		in_player.volume_db = DB_SILENCE
		in_player.play()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(out_player, "volume_db", DB_SILENCE, CROSSFADE_TIME)
	if ResourceLoader.exists(path):
		tw.tween_property(in_player, "volume_db", _bgm_db(), CROSSFADE_TIME)
	tw.chain().tween_callback(out_player.stop)

# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------
func play_sfx(sfx_name: String) -> void:
	var path := "res://audio/sfx_%s.ogg" % sfx_name
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = linear_to_db(master_volume * sfx_volume)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

# ---------------------------------------------------------------------------
# Volume controls
# ---------------------------------------------------------------------------
func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_set_bgm_volumes()

func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	_set_bgm_volumes()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)

func _set_bgm_volumes() -> void:
	var db := _bgm_db()
	if _bgm_a and _bgm_a.playing: _bgm_a.volume_db = db
	if _bgm_b and _bgm_b.playing: _bgm_b.volume_db = db

func _bgm_db() -> float:
	return linear_to_db(maxf(master_volume * bgm_volume, 0.0001))

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_day_started(_day: int) -> void:
	_day_active = true
	play_bgm("morning")

func _on_day_ended(_day: int, _revenue: float) -> void:
	_day_active = false
	play_bgm("evening")
