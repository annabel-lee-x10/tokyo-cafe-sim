extends Control
## Pause menu — opened by ESC key or HUD pause button.
## Pauses the day timer; settings sub-panel handles volume controls.

@onready var resume_btn:   Button = $Overlay/Panel/VBox/ResumeBtn
@onready var save_btn:     Button = $Overlay/Panel/VBox/SaveBtn
@onready var settings_btn: Button = $Overlay/Panel/VBox/SettingsBtn
@onready var quit_btn:     Button = $Overlay/Panel/VBox/QuitBtn
@onready var settings_panel: Control = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/VBox/MasterSlider
@onready var bgm_slider:    HSlider = $SettingsPanel/VBox/BGMSlider
@onready var sfx_slider:    HSlider = $SettingsPanel/VBox/SFXSlider
@onready var settings_close: Button = $SettingsPanel/VBox/CloseBtn

func _ready() -> void:
	visible = false
	settings_panel.visible = false
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	settings_close.pressed.connect(func(): settings_panel.visible = false)

	master_slider.value = AudioManager.master_volume
	bgm_slider.value    = AudioManager.bgm_volume
	sfx_slider.value    = AudioManager.sfx_volume
	master_slider.value_changed.connect(AudioManager.set_master_volume)
	bgm_slider.value_changed.connect(AudioManager.set_bgm_volume)
	sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			settings_panel.visible = false
		elif visible:
			_on_resume()
		else:
			_open()

func open() -> void:
	GameManager._day_active = false
	visible = true

func _open() -> void:
	open()

func _on_resume() -> void:
	settings_panel.visible = false
	visible = false
	GameManager._day_active = true   # restore day timer

func _on_save() -> void:
	SaveManager.save()
	save_btn.text = "Saved!"
	get_tree().create_timer(1.5).timeout.connect(func(): save_btn.text = "Save Game")

func _on_settings() -> void:
	master_slider.value = AudioManager.master_volume
	bgm_slider.value    = AudioManager.bgm_volume
	sfx_slider.value    = AudioManager.sfx_volume
	settings_panel.visible = true

func _on_quit() -> void:
	SaveManager.save()
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
