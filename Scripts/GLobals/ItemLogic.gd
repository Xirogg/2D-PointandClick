extends Node

var Items: Dictionary = {
	
	"Test Item": {
		
		"gd_name" : "Test Item",
		"name_en" : "Test Item",
		"name_de" : "Test Item",
		"description_en" : " Bruh",
		"description_de" : " Bruh aber deutsch",
		"texture" : preload("res://Assets/Placeholders/Raccoon.png")
	},
	
	"Test Item2": {
		
		"gd_name" : "Test Item2",
		"name_en" : "Test Item2",
		"name_de" : "Test Item2",
		"description_en" : " Brwuh",
		"description_de" : " Bruh aber deutsch",
		"texture" : preload("res://Assets/Placeholders/32s32.png")
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
	
	#Empty for now
}



func get_item(gd_name: String): 
	
	return Items.get(gd_name, {})
	

func add_item(gd_name):
	
	var item_to_add = get_item(gd_name)
	print("Item to Add: ", item_to_add)
	Global.additem(item_to_add)
	
