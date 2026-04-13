extends Control
## Title screen — main menu.  Set as project's main scene.

@onready var new_game_btn:  Button  = $Content/Buttons/NewGameBtn
@onready var continue_btn:  Button  = $Content/Buttons/ContinueBtn
@onready var settings_btn:  Button  = $Content/Buttons/SettingsBtn
@onready var credits_btn:   Button  = $Content/Buttons/CreditsBtn
@onready var settings_panel: Control = $SettingsPanel
@onready var credits_panel:  Control = $CreditsPanel
@onready var master_slider: HSlider = $SettingsPanel/VBox/MasterSlider
@onready var bgm_slider:    HSlider = $SettingsPanel/VBox/BGMSlider
@onready var sfx_slider:    HSlider = $SettingsPanel/VBox/SFXSlider

func _ready() -> void:
	settings_panel.visible = false
	credits_panel.visible  = false
	continue_btn.disabled  = not SaveManager.has_save()

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings_open)
	credits_btn.pressed.connect(func(): credits_panel.visible = true)
	$SettingsPanel/VBox/CloseBtn.pressed.connect(func(): settings_panel.visible = false)
	$CreditsPanel/VBox/CloseBtn.pressed.connect(func(): credits_panel.visible = false)

	master_slider.value = AudioManager.master_volume
	bgm_slider.value    = AudioManager.bgm_volume
	sfx_slider.value    = AudioManager.sfx_volume
	master_slider.value_changed.connect(AudioManager.set_master_volume)
	bgm_slider.value_changed.connect(AudioManager.set_bgm_volume)
	sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)

	AudioManager.play_bgm("menu")

func _on_new_game() -> void:
	SaveManager.new_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_continue() -> void:
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_open() -> void:
	master_slider.value = AudioManager.master_volume
	bgm_slider.value    = AudioManager.bgm_volume
	sfx_slider.value    = AudioManager.sfx_volume
	settings_panel.visible = true
