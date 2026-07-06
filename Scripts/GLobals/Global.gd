extends Node

var PlayerNode: Node = null ### Player Node 

var inventory: Array = []
var inventory_size: int = 10

# --- World item pickup persistence ---------------------------------
# Remembers which editor-placed world items have already been collected,
# so they do NOT respawn when a level scene is reloaded. Because this is an
# autoload it survives scene changes for the whole game session.
#   item_id (StringName) -> true
var picked_up_items: Dictionary = {}

signal updateinventory
signal clickedinteractibles

# --- Escalation tracker --------------------------------------------
# Goes up by 1 every time the player tries to combine two items that
# cannot be combined. Kept as an int in the range 0..ESCALATION_MAX so
# the Player HUD progress bar (0 = good, 10 = bad) can bind to it directly.
const ESCALATION_MAX: int = 10
var escalation: int = 0
signal escalation_changed(new_value: int)

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
		

# --- World item pickup persistence ---------------------------------

func is_item_picked_up(item_id: StringName) -> bool:
	return picked_up_items.get(item_id, false)


func mark_item_picked_up(item_id: StringName) -> void:
	picked_up_items[item_id] = true


# Central pickup entry point for editor-placed world items (item.gd).
# Handles the inventory logic AND remembers the item as collected.
# Returns true when the item was actually taken, so the caller can free the
# world node. Returns false (e.g. inventory full) so the item stays in the
# world and can be picked up later.
func pickup_world_item(item: Dictionary, item_id: StringName) -> bool:
	if additem(item):
		mark_item_picked_up(item_id)
		return true
	return false


# Call this when starting a new game so previously collected items reappear.
func reset_picked_up_items() -> void:
	picked_up_items.clear()


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


# --- Escalation tracker --------------------------------------------

# Raise escalation after a failed item combination. Clamped to
# 0..ESCALATION_MAX and broadcast so the HUD can update its progress bar.
func increase_escalation(amount: int = 1) -> void:
	escalation = clampi(escalation + amount, 0, ESCALATION_MAX)
	print("Escalation: ", escalation, "/", ESCALATION_MAX)
	escalation_changed.emit(escalation)


# Reset the tracker (e.g. when starting a new game).
func reset_escalation() -> void:
	escalation = 0
	escalation_changed.emit(escalation)





	
