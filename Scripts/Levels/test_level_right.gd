extends Node2D

var player_in_range: bool = false
@onready var label: Label = $"Pin Stuff/VBoxContainer/MarginContainer/Label"

const PASSWORD = "4750"
func _ready() -> void:
	Global.can_enter_next_room = false

func _process(delta: float) -> void:
	if player_in_range: 
		get_tree().change_scene_to_file("res://Scenes/Levels/test_level.tscn")






func keypress(digit): 
	if len(label.text) <4: 
		label.text += str(digit)
		






func _on_area_2d_body_entered(body: Node2D) -> void:
	player_in_range = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	player_in_range = false




func _on_b_1_pressed() -> void:
	keypress(1)


func _on_b_2_pressed() -> void:
	keypress(2)


func _on_b_3_pressed() -> void:
	keypress(3)


func _on_b_4_pressed() -> void:
	keypress(4)


func _on_b_5_pressed() -> void:
	keypress(5)


func _on_b_6_pressed() -> void:
	keypress(6)


func _on_b_7_pressed() -> void:
	keypress(7)


func _on_b_8_pressed() -> void:
	keypress(8)


func _on_b_9_pressed() -> void:
	keypress(9)


func _on_back_pressed() -> void:
	pass # Replace with function body.


func _on_b_10_pressed() -> void:
	keypress(0)


func _on_yes_pressed() -> void:
	if label.text == PASSWORD:
		ItemLogic.add_item("Test Craft Item")
		$"Pin Stuff".hide()


func _on_button_pressed() -> void:
	$"Pin Stuff".show()
