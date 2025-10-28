extends Node2D

@export var item_name_de = ""
@export var item_texture: Texture
@export var item_descrpition_de = ""

#For Englisch localisation
@export var item_name_en = ""
@export var item_description_en = ""

var scene_path: String = "res://Scenes/GUI/Inventory/item.tscn"

var MouseinRange: bool = false


func _ready() -> void:
	
	$"Item Icon".texture = item_texture

func _process(delta: float) -> void:
	
	
	if Input.is_action_just_pressed("LMB"):
		if MouseinRange:
		
		
			pickupitem()

func pickupitem(): 
	
	
	var Item = {
		"quantity": 1,
		"name_de": item_name_de,
		"description_de": item_descrpition_de,
		"texture": item_texture,
		"scene_path": scene_path,
		"name_en": item_name_en,
		"description_en": item_description_en
	}
	
	
	
	if Global.PlayerNode:
		Global.additem(Item)
		
		self.queue_free()

func _on_pickup_range_mouse_entered() -> void:
	MouseinRange = true
	print("In Range of Item: ", item_name_de )

func _on_pickup_range_mouse_exited() -> void:
	MouseinRange = false
