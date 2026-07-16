extends CanvasLayer

# Settings overlay. Reads/writes GameSettings, which owns the actual values
# and persists them. Changes apply live; they are saved when the panel closes.

#Scene Nodes
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VSyncCheck
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var language_option: OptionButton = %LanguageOption
@onready var close_button: Button = %CloseButton

# Where to send focus back to once the panel closes (the button that opened it).
var _return_focus: Control = null


func _ready() -> void:
	_build_language_options()


func open(return_focus: Control = null) -> void:
	_return_focus = return_focus
	_sync_from_settings()
	visible = true
	close_button.grab_focus()


func close() -> void:
	visible = false
	GameSettings.save_settings()
	if is_instance_valid(_return_focus):
		_return_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build_language_options() -> void:
	language_option.clear()
	# Item index lines up with GameSettings.LOCALES.
	language_option.add_item("Deutsch")
	language_option.add_item("English")


# Pull the current values into the widgets. Done on every open so the panel
# can't drift out of sync with GameSettings.
func _sync_from_settings() -> void:
	fullscreen_check.set_pressed_no_signal(GameSettings.fullscreen)
	vsync_check.set_pressed_no_signal(GameSettings.vsync)
	volume_slider.set_value_no_signal(GameSettings.master_volume)
	_update_volume_label(GameSettings.master_volume)

	var index := GameSettings.LOCALES.find(GameSettings.locale)
	language_option.select(index if index != -1 else 0)


func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value * 100.0)


# --- Signals -------------------------------------------------------

func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	GameSettings.set_fullscreen(toggled_on)


func _on_v_sync_check_toggled(toggled_on: bool) -> void:
	GameSettings.set_vsync(toggled_on)


func _on_volume_slider_value_changed(value: float) -> void:
	GameSettings.set_master_volume(value)
	_update_volume_label(value)


func _on_language_option_item_selected(index: int) -> void:
	GameSettings.set_locale(GameSettings.LOCALES[index])


func _on_close_button_pressed() -> void:
	close()
