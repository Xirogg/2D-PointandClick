extends Control

# Title screen and intro in one. Entry point of the game (see application/run/main_scene).
#
# The parallax from the old intro_scene lives here as the backdrop. While the menu
# is up it sits behind a half transparent ColorRect, so it reads as background.
# "Spielen" fades the whole menu out, and because that ColorRect fades with it the
# parallax comes up to full brightness on its own: that fade is the intro. After a
# short beat the intro dialogue plays, and when it ends we head to the base camp.

## The dialogue that plays once the menu has faded away. Assign a ".dialogue" file in the Inspector.
@export var intro_dialogue: DialogueResource

## The title (starting node) inside the dialogue file. Most files begin at "start".
@export var intro_dialogue_title: String = "start"

## Seconds the menu takes to fade out while the parallax comes up to full brightness.
@export var menu_fade_duration: float = 1.5

## Seconds between the menu being gone and the dialogue balloon opening.
@export var intro_dialogue_delay: float = 3.0

@export_file("*.tscn") var base_camp_scene: String = "res://Scenes/Levels/base_camp_scene.tscn"

#Scene Nodes
@onready var menu: Control = %Menu
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

	_play_intro()


func _on_settings_button_pressed() -> void:
	settings_menu.open(settings_button)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


# Menu out, dialogue, base camp.
func _play_intro() -> void:
	_set_buttons_disabled(true)

	# One tween on the menu as a whole: the darkening ColorRect fades along with
	# the title and the buttons, which is what uncovers the parallax.
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(menu, "modulate:a", 0.0, menu_fade_duration)
	await tween.finished

	# Nothing left to see, and hidden Controls stop swallowing mouse clicks.
	menu.hide()

	await get_tree().create_timer(intro_dialogue_delay).timeout
	await _play_intro_dialogue()

	var error := get_tree().change_scene_to_file(base_camp_scene)
	if error != OK:
		push_error("MainMenu: could not load %s (error %d)" % [base_camp_scene, error])


# Opens the balloon and returns once the dialogue has run its course.
func _play_intro_dialogue() -> void:
	if intro_dialogue == null:
		push_warning("MainMenu: no Intro Dialogue assigned, going straight to %s." % base_camp_scene)
		return

	DialogueManager.show_dialogue_balloon(intro_dialogue, intro_dialogue_title)
	await DialogueManager.dialogue_ended


func _set_buttons_disabled(disabled: bool) -> void:
	play_button.disabled = disabled
	settings_button.disabled = disabled
	quit_button.disabled = disabled
