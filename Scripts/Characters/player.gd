class_name Player
extends CharacterBody2D

@export var Speed: int = 250
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var click_target :=  Vector2.ZERO


func _ready() -> void:
	click_target = position
	
	#Stuff for Debug

	


		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("LMB (Single)"): 
		var mouse_postition = get_global_mouse_position()
		mouse_postition = round(mouse_postition)
		click_target = Vector2(mouse_postition.x, position.y)
		print("Clicked Target ", mouse_postition)
		
func _physics_process(delta: float) -> void:
	velocity = position.direction_to(click_target) * Speed
	
	if position.distance_to(click_target) > 5.0: 
		move_and_slide()
		
	else :
		position.x = click_target.x


func _on_inventory_button_pressed() -> void:
	$InventoryLayer.show()


func _on_close_inv_pressed() -> void:
	$InventoryLayer.hide()

	
