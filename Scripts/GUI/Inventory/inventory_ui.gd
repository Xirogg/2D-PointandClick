extends Control


var InventorySlot = preload("res://Scenes/GUI/Inventory/inventory_slot.tscn")

#Scene Nodes
@onready var Grid_Container: GridContainer = %GridContainer
@onready var item_name: Label = %ItemName
@onready var item_description: Label = %ItemDescription


## A slot asked for the inventory to close (its "BENUTZEN" was pressed). The
## Player owns the InventoryLayer, so it does the actual hiding.
signal close_requested

var dragged_slot = null
var origin_slot_index = null
var target_slot_index = null


func _ready() -> void:

	Global.updateinventory.connect(on_updateinvenory)
	on_updateinvenory()


func cleargrid():
	
	while Grid_Container.get_child_count() > 0:
		var child = Grid_Container.get_child(0)
		Grid_Container.remove_child(child)
		child.queue_free()
		
func on_updateinvenory():
	#print("Update Inv")
	cleargrid()
	for item in Global.inventory:
		var slot = InventorySlot.instantiate()
		slot.drag_start.connect(on_drag_start)
		slot.drag_end.connect(on_drag_end)
		slot.selected.connect(on_slot_selected)
		slot.use_requested.connect(on_slot_use_requested)
		slot.craft_requested.connect(on_slot_craft_requested)
		Grid_Container.add_child(slot)

		if item != null:

			slot.set_item(item)

		else:

			slot.setempty()


## A slot was clicked: describe it, and keep it the only slot with a popup open.
func on_slot_selected(slot: Control):

	for other_slot in Grid_Container.get_children():
		if other_slot != slot:
			other_slot.hide_popups()

	setitemname(slot.display_name())
	setdescriptionname(slot.display_description())


func on_slot_use_requested(_slot: Control):

	close_requested.emit()


func on_slot_craft_requested(_slot: Control):

	craft_item()


func check_crafting():

	#Get the Dev Names for each Item
	var origin_slot = Global.inventory[origin_slot_index]
	var target_slot = Global.inventory[target_slot_index]

	#Need two actual items to attempt a combination.
	if origin_slot == null or target_slot == null:
		return ""

	var origin_name = origin_slot["gd_name"]
	var target_name = target_slot["gd_name"]


	var item_array: Array = [origin_name, target_name]
	item_array.sort()
	#print(item_array)
	
	#Check for valid Combination
	for Recepies in ItemLogic.CraftingRecepies.keys():
		
		var sorted_recepie = Recepies.duplicate()
		sorted_recepie.sort()
		#Check for all possibilities
		if item_array == sorted_recepie:
			for item in item_array:
				Global.removeitem(item)
			
			return ItemLogic.CraftingRecepies[Recepies]
			
	return ""
	
func craft_item():

	# Only escalate when the player actually tried to combine two items.
	var origin_item = Global.inventory[origin_slot_index]
	var target_item = Global.inventory[target_slot_index]
	if origin_item == null or target_item == null:
		return

	var recepie = check_crafting()

	if recepie != "":

		ItemLogic.add_item(recepie)

	else:

		# The two items can't be combined -> the player failed. Escalate.
		Global.increase_escalation()
	

func on_drag_start(slot_control: Control):

	dragged_slot = slot_control
	origin_slot_index = get_slot_index(dragged_slot)
	print("Drag start: ", origin_slot_index)
	
func on_drag_end(): 

	print("Drag end")
	var target_slot = get_slot_under_mouse()
	target_slot_index = get_slot_index(target_slot)
	print("Target Slot ",target_slot)
	if target_slot and dragged_slot != target_slot: 
		
		if target_slot.item != null:
			
			print("Cant Change That shit burv", target_slot_index )
			target_slot.show_craft_interface()
			
			
		else:
			
		
			drop_slot(dragged_slot, target_slot)
			print("GGGR",target_slot.item)
	else:
		print("GEGG", target_slot)
		
func get_slot_under_mouse() -> Control:
	
	var mouse_position = get_viewport().get_mouse_position()
	
	for slot in Grid_Container.get_children():
		if slot is Control:
			if slot.get_global_rect().has_point(mouse_position):
				
				return slot 

	return null
		
func get_slot_index(slot: Control) -> int:
	#Valid Slot
	for i in range(Grid_Container.get_child_count()):
		if Grid_Container.get_child(i) == slot:
		
			return i  
	#Invalid Slot
	return -1 
	
func drop_slot(slot_1: Control, slot_2: Control):
	
	var slot_1_index = get_slot_index(slot_1)
	var slot_2_index = get_slot_index(slot_2)
	
	if slot_1_index == -1 or slot_2_index == -1:
		print("Ching Chong")
		return
	else:
		if Global.swap_inventory(slot_1_index, slot_2_index):
			on_updateinvenory()
			print("Dropping slots: ", slot_1_index," ", slot_2_index )
	
func setitemname(item_Name):
	print("NAME ", item_Name)
	item_name.text = item_Name
	
func setdescriptionname(description_name):
	print("DES",item_description)
	item_description.text = description_name
