extends Area2D

#Needed Item for the specific Puzzle
@export var needed_item: String 

var mouse_in_range: bool = false


func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("LMB (Single)"):
		
		if mouse_in_range: 
			Handle_Activity()
			
			
			
func Handle_Activity(): 
	var parent = get_parent()
	
	if Global.LastSelectedItem != needed_item: 
		return 
	
	#Execute the Action 
	### THERE MUST BE A FUNCTION WITH THAT NAME, OTHERWISE ITS GG
	else:
		if parent.Execute_Function():
			parent.Execute_Action() 
			
		else:
			return
		


func _on_area_entered(area: Area2D) -> void:
	mouse_in_range = true


func _on_area_exited(area: Area2D) -> void:
	mouse_in_range = false
