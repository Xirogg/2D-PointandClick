extends Node2D
var test_dialogue = preload("res://Prototype Dialogue.dialogue")

var is_payer_in_range: bool = false
@onready var x: Button = $Claw/x
@onready var amul: Button = $BasicAmulett/Amul

func _ready() -> void:
	Global.SpawnNPCs()

func _process(delta: float) -> void:
	if is_payer_in_range: 
		get_tree().change_scene_to_file("res://Scenes/Levels/test_level_right.tscn")

func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("Player"): 
		is_payer_in_range = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		is_payer_in_range = false


func _on_amul_pressed() -> void:
	ItemLogic.add_item("Lunari")
	var test = amul.get_parent()
	test.queue_free()

func _on_x_pressed() -> void:
	
	ItemLogic.add_item("Test Item2")
	var xp = x.get_parent()
	xp.queue_free()
