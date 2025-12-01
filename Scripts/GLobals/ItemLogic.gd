extends Node

var Items: Dictionary = {
	
	"Lunari": {
		
		"gd_name" : "Lunari Shapeshift Item",
		"name_en" : "Lunari",
		"name_de" : "Luna",
		"description_en" : " Nutze es, um dich in einen Lunari zu verwandeln",
		"description_de" : " Nutze es, um dich in einen Lunari zu verwandeln",
		"texture" : preload("res://Assets/Items/Claw.png")
	},
	
	"Test Item2": {
		
		"gd_name" : "Test Item2",
		"name_en" : "Test Item2",
		"name_de" : "Test Item2",
		"description_en" : " Dies hat einen unbekannten Wert",
		"description_de" : " Dies hat einen unbekannten Wert",
		"texture" : preload("res://Assets/Items/Basic Amulett.png")
		},
	"Test Craft Item": {
		"gd_name" : "Test Craft Item ",
		"name_en" : " Craft  ",
		"name_de" : " Craft ",
		"description_en" : " Kraft...  ",
		"description_de" : " Kraft.. ",
		"texture" : preload("res://Assets/Items/Present.png"),
		},
	
	"Placeholder": {
		"gd_name" : " ",
		"name_en" : "  ",
		"name_de" : " ",
		"description_en" : "  ",
		"description_de" : " ",
		"texture" : " "
	}
}


var CraftingRecepies: Dictionary = {
	
	["Test Item", "Test Item2"]: "Test Craft Item",
}



func get_item(gd_name: String): 
	
	return Items.get(gd_name, {})
	

func add_item(gd_name):
	
	var item_to_add = get_item(gd_name)
	print("Item to Add: ", item_to_add)
	Global.additem(item_to_add)
	
