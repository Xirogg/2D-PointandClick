class_name Player
extends CharacterBody2D

@export var Speed: int = 250
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var escalation_bar: ProgressBar = $"Player HUD/EscalationBar"

var click_target :=  Vector2.ZERO


func _ready() -> void:
	click_target = position

	# Reflect the global escalation tracker on the HUD progress bar.
	Global.escalation_changed.connect(_on_escalation_changed)
	_on_escalation_changed(Global.escalation)

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


func _on_escalation_changed(value: int) -> void:
	escalation_bar.value = value

	# Colour the fill in discrete bands so the bar reads "good -> bad".
	# Mutates this bar's own fill stylebox.
	var fill := escalation_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = _escalation_color(value)


# Maps an escalation value (0..10) to its band colour.
#   0-3  green | 4-5  yellow | 6-7  dark orange | 8+  red
func _escalation_color(value: int) -> Color:
	if value <= 3:
		return Color(0.223529, 0.662745, 0.4)     # green
	elif value <= 5:
		return Color(0.898039, 0.831373, 0.223529) # yellow
	elif value <= 7:
		return Color(0.803922, 0.435294, 0.101961) # dark orange
	else:
		return Color(0.792157, 0.235294, 0.235294) # red


func _on_inventory_button_pressed() -> void:
	$InventoryLayer.show()


func _on_close_inv_pressed() -> void:
	$InventoryLayer.hide()

	
