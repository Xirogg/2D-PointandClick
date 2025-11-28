extends Node2D

var player_in_range: bool = false 

func _ready() -> void:
	
	Global.changed_shape.connect(Handle_Sus)

func _process(delta: float) -> void:
	pass
	

func Handle_Sus(): 
	
	if player_in_range:
		Global.Add_Sus(20)
		print("Player got sussed out, current Sussyness: ", Global.Sussynes)
func _on_sus_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		player_in_range = true


func _on_sus_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		player_in_range = false
