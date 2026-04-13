extends Control
## Full-screen dialogue overlay for named regular loyalty scenes.
## Tap anywhere to advance; closes automatically after the final line.

signal dialogue_closed

# ---------------------------------------------------------------------------
# Dialogue strings — 5 regulars × 3 levels = 15 scenes
# ---------------------------------------------------------------------------
const DIALOGUES: Dictionary = {
	"keita": {
		1: [
			"Tough week. Your cortado is the only thing holding me together.",
			"Keep the receipts. My boss thinks I've been at client meetings.",
		],
		2: [
			"I've been recommending this place to colleagues. You're half the reason I haven't quit yet.",
			"Honestly? The other cafés feel empty now.",
		],
		3: [
			"Can I tell you something?",
			"My company wants to relocate me to Osaka.",
			"I've been stalling the paperwork for three weeks.",
			"Every morning I think: one more cortado, then I'll deal with it.",
			"...I'm going to need about thirty more before I sign anything.",
			"Save my table for me?",
		],
	},
	"yui": {
		1: [
			"My thesis is a disaster. This iced matcha is not.",
			"Can I sit here for four hours? Maybe five?",
		],
		2: [
			"I passed my defence. I cited 'sustained cognitive support via matcha' in the acknowledgements.",
			"That's technically you.",
		],
		3: [
			"Okay, I need to say something out loud.",
			"I want to apply to culinary school.",
			"My parents want me to finish the economics degree first.",
			"But every time I come here, I think about flavour pairings instead of GDP.",
			"What does green tea volatility mean? Not stock markets.",
			"Is it weird that this café made me figure out what I actually want?",
			"...Don't answer that. I'll have another one.",
		],
	},
	"marco": {
		1: [
			"In my country we call this 'coffee magic'. Here I just say flat white.",
			"I keep missing my tour group. Completely worth it.",
		],
		2: [
			"I was supposed to leave Tokyo last week.",
			"I told myself: one more flat white. That was eight flat whites ago.",
		],
		3: [
			"Okay. Confession time.",
			"I've been in Tokyo for two months.",
			"My return ticket is fully refundable.",
			"I told my mother I'm 'on assignment'.",
			"She thinks I'm a journalist.",
			"I am not a journalist.",
			"I just really like this flat white.",
			"...And the city. Mostly the flat white.",
		],
	},
	"setsuko": {
		1: [
			"The light here at 3pm is perfect. I've filled a whole sketchbook.",
			"You've become part of my practice somehow.",
		],
		2: [
			"A gallery in Shimokitazawa wants my café series.",
			"You're going to be hanging on walls, you know.",
		],
		3: [
			"I sold the piece.",
			"The one where the steam makes the shape of a bird.",
			"Took three months to get the hojicha angle right.",
			"I kept coming back because the light here changes. Every visit, different.",
			"Like the café breathes.",
			"The buyer wanted to know the name of the place.",
			"I said: my third home.",
		],
	},
	"rin": {
		1: [
			"I'm not going to post this place yet.",
			"I want to keep it secret. That's a first for me.",
		],
		2: [
			"I finally posted. Twelve thousand saves in an hour.",
			"I gave you a fake name in the article.",
			"You're welcome, by the way.",
		],
		3: [
			"My editor wants a full feature.",
			"'Hidden Tokyo: The café they don't want you to find.'",
			"I said no.",
			"She offered triple my usual rate.",
			"I said no again.",
			"Some places shouldn't be found.",
			"Don't tell anyone I said that. I have a reputation.",
			"...This pour over is genuinely the best thing I've ever had.",
		],
	},
}

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var portrait:      ColorRect = $Box/Content/TopRow/Portrait
@onready var name_label:    Label     = $Box/Content/TopRow/NameLabel
@onready var dialogue_text: Label     = $Box/Content/DialogueText
@onready var tap_hint:      Label     = $Box/Content/TapHint

var _lines: Array  = []
var _line_idx: int = 0

func _ready() -> void:
	visible = false
	dialogue_text.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_font_size_override("font_size", 22)

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------
func show_dialogue(regular_id: String, level: int) -> void:
	var data:  Dictionary = RegularManager.get_regular(regular_id)
	var lines: Array      = DIALOGUES.get(regular_id, {}).get(level, [])
	if lines.is_empty():
		return
	_lines    = lines
	_line_idx = 0
	portrait.color  = data.get("sprite_color", Color(0.5, 0.5, 0.5))
	name_label.text = data.get("name", regular_id.capitalize())
	_show_line()
	visible = true

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------
func _show_line() -> void:
	if _line_idx >= _lines.size():
		_close()
		return
	dialogue_text.text = _lines[_line_idx]
	tap_hint.text = "▼ Tap to close" if _line_idx == _lines.size() - 1 \
	                else "▼ Tap to continue"

func _advance() -> void:
	_line_idx += 1
	_show_line()

func _close() -> void:
	visible = false
	_lines    = []
	_line_idx = 0
	dialogue_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or \
	                   (event is InputEventMouseButton and event.pressed and \
	                    event.button_index == MOUSE_BUTTON_LEFT)
	if tapped:
		_advance()
		get_viewport().set_input_as_handled()
