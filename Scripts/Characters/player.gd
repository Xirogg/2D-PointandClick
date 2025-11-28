extends CharacterBody2D

@export var Speed: int = 250

var click_target :=  Vector2.ZERO

var shpapeshiftable_races: Dictionary = {
	"Shape01 Holder": true,
	"Shape02 Holder": true,
	"Shape03 Holder": true
}

### COMPONENTS
@onready var player_sprite: Sprite2D = $"Player Sprite"
@onready var shape_shift_b_container: HBoxContainer = $"Player HUD/ShapeShiftBContainer"



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
#
func Show_Possible_Shapeshifts(): 
	for child in shape_shift_b_container.get_children():
		if child: 
			queue_free()
			
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
		player_sprite.texture = test
		Global.change_current_shape_string(race)

func _on_shapeshift_button_pressed() -> void:
	Show_Possible_Shapeshifts()
