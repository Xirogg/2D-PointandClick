extends CharacterBody2D

var test = preload("res://Prototype Dialogue.dialogue")
func _on_button_pressed() -> void:
	DialogueManager.show_dialogue_balloon(test)
