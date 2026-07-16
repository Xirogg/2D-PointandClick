extends Control

# Title screen. Entry point of the game (see application/run/main_scene).

@export_file("*.tscn") var base_camp_scene: String = "res://Scenes/Levels/base_camp_scene.tscn"

#Scene Nodes
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_menu: CanvasLayer = %SettingsMenu


func _ready() -> void:
	# So the menu is usable with keyboard/controller right away.
	play_button.grab_focus()


func _on_play_button_pressed() -> void:
	# Fresh run: drop the state the autoloads carry between scenes.
	Global.reset_picked_up_items()
	Global.reset_escalation()

	var error := get_tree().change_scene_to_file(base_camp_scene)
	if error != OK:
		push_error("MainMenu: could not load %s (error %d)" % [base_camp_scene, error])


func _on_settings_button_pressed() -> void:
	settings_menu.open(settings_button)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
