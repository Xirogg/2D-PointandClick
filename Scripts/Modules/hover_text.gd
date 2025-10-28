extends Node2D

@export var hover_text: String = ""
@onready var label: Label = $Label

var MouseinRange: bool = false


func _process(delta: float) -> void:
	
	
	if hover_text:
	
		if MouseinRange:
			snaptopixel()
			label.text = hover_text
			print("Text Label shows:" ,  label.text)
		else: 
			label.text = ""
			
			
func snaptopixel():
	
	var snapped = label.position.round()
	
	if label.position != snapped: 
		
		label.position = snapped



#
func _on_area_2d_mouse_entered() -> void:
	MouseinRange = true


func _on_area_2d_mouse_exited() -> void:
	MouseinRange = false
