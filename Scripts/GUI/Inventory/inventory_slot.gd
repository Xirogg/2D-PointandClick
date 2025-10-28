extends Control



var item = null

var item_name

var item_name_de
var item_description_de

var item_name_en
var item_description_en


var ActualName

#  Node References
@onready var inner_border: ColorRect = $InnerBorder
@onready var ItemIcon: TextureRect = $InnerBorder/ItemIcon
@onready var ItemQuantity: Label = $InnerBorder/ItemQuantitiy
@onready var ItemName: Label = $InnerBorder/ItemName
@onready var activity_stuff: ColorRect = $ActivityStuff

# Signals

signal drag_start(slot)
signal drag_end()

# For Crafting


func _ready() -> void:
	print("Inv Slot instantiated")


func setempty():
	ItemIcon.texture = null 
	ItemQuantity.text = " "
	ItemName.text = " "
	
	
func set_item(new_item):
	
	item = new_item
	
	
	ItemIcon.texture = new_item["texture"] 
#	ItemQuantity.text = str(item["quantity"])
	ItemName.text = str(item["name_de"])
	
	item_name = str(item["name_de"])
	
	item_name_de = str(item["name_de"])
	item_description_de = str(item["description_de"])
	
	item_name_en = str(item["name_en"])
	item_description_en = str(item["description_en"])
	 
	#print("ITEM : ", ItemQuantity.text, "  | ITEM NAME: ", ItemName.text)
	
	
func get_item():
	
	var ChosenItemName = str(ItemName.text)
	Global.LastSelectedItem = ChosenItemName
	print(ActualName)


#func _on_item_button_pressed() -> void:
	#if item != null:
		#get_item()
	#else:
		#return


func _on_item_button_mouse_entered() -> void:
	pass # Replace with function body.


func _on_item_button_mouse_exited() -> void:
	pass # Replace with function body.


func _on_item_button_gui_input(event: InputEvent) -> void:
	var InventoryUI = get_parent().get_parent() #Node InventoryUI
	if event is InputEventMouseButton:
		print("TESTRUN LADIES")
		#LMB
		if event.button_index == MOUSE_BUTTON_MASK_LEFT and event.is_pressed():

			
			if item != null: 
				
				#Name und Beschreibung von Items anzeigen
				if Global.SelectedLanguage == "de":
					InventoryUI.setitemname(item_name_de)
					InventoryUI.setdescriptionname(item_description_de)
					activity_stuff.show()
					#
				else: 
					InventoryUI.setitemname(item_name_en)
					InventoryUI.setdescriptionname(item_description_en)
					activity_stuff.show()
				
			else: 
				#Nichts anzeigen bei leeren Slots / Text resetten
				InventoryUI.setitemname("")
				InventoryUI.setdescriptionname("")
				
				
		#RMG
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				
				inner_border.modulate = Color(2,0,2)
				drag_start.emit(self)
				
			else: 
				
				inner_border.modulate = Color(1,1,1)
				drag_end.emit()
		

func _on_use_button_pressed() -> void:
	var invui = get_parent().get_parent().get_parent().get_parent()
	#Hide the Inventory and select the Playerrs selected Item
	invui.hide()
	activity_stuff.hide()
	Global.change_selecteditem(item_name)
	print(Global.LastSelectedItem, "LAST")
#Make the Use Button Disappear when another Slot is selected
func _on_item_button_focus_exited() -> void:
	activity_stuff.hide()
