extends Node

var PlayerNode: Node = null ### Player Node 

var inventory: Array = []
var inventory_size: int = 10

signal updateinventory 
signal clickedinteractibles

@onready var Inventory_Slot_Scene = preload("res://Scenes/GUI/Inventory/inventory_slot.tscn")

var LastSelectedItem = null 


var SelectedLanguage: String
###########################


func _ready() -> void:
	

	inventory.resize(inventory_size)
	
	

func _process(delta: float) -> void:
	checklanguage()
	

	
func checklanguage(): 
	var local = TranslationServer.get_locale()
	SelectedLanguage = local.to_lower()
	
func additem(item):
	
	for i in range(inventory.size()):
		
		if inventory[i] != null and inventory[i]["name_de"] == item["name_de"]:
			#inventory[i]["quantity"] += item["quantity"] 
			emit_signal("updateinventory")
			return true 
			
		elif inventory[i] == null: 
			inventory[i] = item
			emit_signal("updateinventory")
			return true
			
		#else: 
			#inventory[i] = item
			#print("ELSE ", inventory)
	return false
		

func removeitem(item): 
	
	
	for i in range(inventory.size()):
		
		if inventory[i] != null and inventory[i]["name_de"] == item:
			print("Remove Item ", item )
			inventory[i] = null
			updateinventory.emit()
			return true
			
	return false
		

func player_reference(player): 
	PlayerNode = player
	
	
func swap_inventory(index_1, index_2):
	
	if index_1 < 0 or index_1 > inventory.size() or index_2 < 0 or index_2 > inventory.size():
		return false
		
	var temp = inventory[index_1]
	inventory[index_1] = inventory[index_2]
	inventory[index_2] = temp
	updateinventory.emit()
	return true

#Update last Selected Item
func change_selecteditem(selected_item):
	
	LastSelectedItem = selected_item
	print("Selected Item ", LastSelectedItem)





	
