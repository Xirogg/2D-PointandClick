extends Control

## The inventory grid: one slot per inventory index, drag-to-swap, and the
## combine flow.
##
## The slots are built once and then reused. Rebuilding them on every change
## used to throw away and re-instantiate all ten every time a single item moved,
## which also silently closed whichever popup the player had open.

var InventorySlot = preload("res://Scenes/GUI/Inventory/inventory_slot.tscn")

#Scene Nodes
@onready var Grid_Container: GridContainer = %GridContainer
@onready var item_name: Label = %ItemName
@onready var item_description: Label = %ItemDescription


## A slot asked for the inventory to close (its "BENUTZEN" was pressed). The
## Player owns the InventoryLayer, so it does the actual hiding.
signal close_requested

var dragged_slot: Control = null
var origin_slot_index: int = -1
var target_slot_index: int = -1


func _ready() -> void:
	_build_slots()
	Global.updateinventory.connect(on_updateinvenory)
	on_updateinvenory()


# One slot node per inventory index, created once and kept for the whole run.
func _build_slots() -> void:
	for child in Grid_Container.get_children():
		child.queue_free()

	for i in range(Global.inventory_size):
		var slot = InventorySlot.instantiate()
		slot.drag_start.connect(on_drag_start)
		slot.drag_end.connect(on_drag_end)
		slot.selected.connect(on_slot_selected)
		slot.use_requested.connect(on_slot_use_requested)
		slot.craft_requested.connect(on_slot_craft_requested)
		Grid_Container.add_child(slot)


func on_updateinvenory() -> void:
	var slots := Grid_Container.get_children()
	for i in range(slots.size()):
		var stack = Global.inventory[i] if i < Global.inventory.size() else null
		if stack != null:
			slots[i].set_stack(stack)
		else:
			slots[i].setempty()


## A slot was clicked: describe it, and keep it the only slot with a popup open.
func on_slot_selected(slot: Control) -> void:
	for other_slot in Grid_Container.get_children():
		if other_slot != slot:
			other_slot.hide_popups()

	setitemname(slot.display_name())
	setdescriptionname(slot.display_description())


func on_slot_use_requested(_slot: Control) -> void:
	close_requested.emit()


func on_slot_craft_requested(_slot: Control) -> void:
	craft_item()


## Combine the two slots the player dragged together.
##
## All the rules live in ItemLogic.craft(): it finds the recipe, consumes the
## inputs and adds the result, or fires craft_failed (which Global turns into an
## escalation tick). This function only supplies the two ids.
func craft_item() -> void:
	if origin_slot_index < 0 or target_slot_index < 0:
		return

	var origin = Global.inventory[origin_slot_index]
	var target = Global.inventory[target_slot_index]
	if origin == null or target == null:
		return

	ItemLogic.craft(origin.id(), target.id())


func on_drag_start(slot_control: Control) -> void:
	dragged_slot = slot_control
	origin_slot_index = get_slot_index(dragged_slot)


func on_drag_end() -> void:
	var target_slot := get_slot_under_mouse()
	target_slot_index = get_slot_index(target_slot)

	if target_slot == null or dragged_slot == target_slot:
		return

	if target_slot.stack != null:
		# Something is already there — offer to combine instead of swapping.
		target_slot.show_craft_interface()
	else:
		drop_slot(dragged_slot, target_slot)


func get_slot_under_mouse() -> Control:
	var mouse_position := get_viewport().get_mouse_position()

	for slot in Grid_Container.get_children():
		if slot is Control and slot.get_global_rect().has_point(mouse_position):
			return slot

	return null


func get_slot_index(slot: Control) -> int:
	if slot == null:
		return -1
	#Valid Slot
	for i in range(Grid_Container.get_child_count()):
		if Grid_Container.get_child(i) == slot:
			return i
	#Invalid Slot
	return -1


func drop_slot(slot_1: Control, slot_2: Control) -> void:
	var slot_1_index := get_slot_index(slot_1)
	var slot_2_index := get_slot_index(slot_2)

	if slot_1_index == -1 or slot_2_index == -1:
		return

	# swap_inventory emits updateinventory, which redraws the slots.
	Global.swap_inventory(slot_1_index, slot_2_index)


func setitemname(item_Name: String) -> void:
	item_name.text = item_Name


func setdescriptionname(description_name: String) -> void:
	item_description.text = description_name
