extends Node2D

## Test level: walking into the Area2D on the right moves to test_level_right.

var is_player_in_range: bool = false


func _process(_delta: float) -> void:
	if is_player_in_range:
		get_tree().change_scene_to_file("res://Scenes/Levels/test_level_right.tscn")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_player_in_range = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_player_in_range = false
