extends CharacterBody2D

@export var Speed: int = 250

var click_target :=  Vector2.ZERO

func _ready() -> void:
	click_target = position
	
	#Stuff for Debug
	ItemLogic.add_item("Test Item")
	ItemLogic.add_item("Test Item2")
	
	
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("LMB (Single)"): 
		var mouse_postition = get_global_mouse_position()
		mouse_postition = round(mouse_postition)
		click_target = Vector2(mouse_postition.x, position.y)
		print("Clicked Target ", mouse_postition)
		Global.SpawnNPCs()
func _physics_process(delta: float) -> void:
	velocity = position.direction_to(click_target) * Speed
	
	if position.distance_to(click_target) > 5.0: 
		move_and_slide()
		
	else :
		position.x = click_target.x
