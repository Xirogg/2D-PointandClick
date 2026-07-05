extends Node

var Items: Dictionary = {
	
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
	
