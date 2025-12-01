class_name Player
extends CharacterBody2D

@export var Speed: int = 250
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var click_target :=  Vector2.ZERO

var shpapeshiftable_races: Dictionary = {
	"Lunari": false,
	"Avalen": true

}

### COMPONENTS

@onready var shape_shift_b_container: HBoxContainer = $"Player HUD/ShapeShiftBContainer"
@onready var sus_bar: ProgressBar = $"Player HUD/Sus-Bar"



func _ready() -> void:
	click_target = position
	
	#Stuff for Debug

	
func _process(delta: float) -> void:
	Handle_Sus_Bar()
	playanis()
func playanis(): 
	
	if velocity.x < 0: 
		animated_sprite_2d.flip_h = true
		
	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
		
	if velocity.x != 0:
		if Global.is_lunari:
			animated_sprite_2d.play("Lunari Walk")
		else: 
			animated_sprite_2d.play("Avalen Walk")
			
	if velocity.x == 0:
		if Global.is_lunari:
			animated_sprite_2d.play("Lunari")
		else:
			animated_sprite_2d.play("default")
		
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
#
func Show_Possible_Shapeshifts(): 
	for child in shape_shift_b_container.get_children():
		if child: 
			child.queue_free()
			
	for race in shpapeshiftable_races.keys(): 
		var race_button := Button.new()
		race_button.text = race
		race_button.disabled = not shpapeshiftable_races[race] 
		
		if shpapeshiftable_races[race]: 
			var temp = Callable(self, "_on_race_button_pressed").bind(race)
			race_button.pressed.connect(temp)
		shape_shift_b_container.add_child(race_button)
		
	
func _on_race_button_pressed(race): 
	print("Wants to Shapeshift into: " ,race)
	var temp = "res://Assets/Placeholders/Placeholder Shapes/%s.png" % race
	var test = load(temp)
	
	if test: 
		
		Global.change_current_shape_string(race)
		Global.emit_signal("changed_shape")
		if Global.is_lunari:
			animated_sprite_2d.play("Lunari")
		else:
			animated_sprite_2d.play("default")
		
		for child in shape_shift_b_container.get_children():
			child.queue_free()

func _on_shapeshift_button_pressed() -> void:
	Show_Possible_Shapeshifts()

func Handle_Sus_Bar(): 
	var sus_bar_min = 0 
	var sus_bar_max = 100 
	
	var bar_target = clamp(Global.Sussynes, sus_bar_min, sus_bar_max )
	var tween = get_tree().create_tween()
	var duration := 0.5
	tween.tween_property(sus_bar, "value", bar_target, duration).set_trans(Tween.TRANS_BOUNCE)


func _on_inventory_button_pressed() -> void:
	$InventoryLayer.show()


func _on_close_inv_pressed() -> void:
	$InventoryLayer.hide()


func _on_sus_t_imer_timeout() -> void:
	Global.Remove_Sus(5)
	print("Removed Sus ", Global.Sussynes)
	
