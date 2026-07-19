class_name ItemStack
extends RefCounted

## What actually sits in one inventory slot: an ItemData plus how many of it.
##
## Kept separate from ItemData so the definition of an item stays immutable and
## shared, while the *held* amount is per-slot. Without this split, picking up a
## second rope would mutate the rope definition itself.

var item: ItemData
var quantity: int = 1


func _init(p_item: ItemData = null, p_quantity: int = 1) -> void:
	item = p_item
	quantity = p_quantity


## The id of the held item, or &"" for a malformed stack.
func id() -> StringName:
	return item.id if item != null else &""


func display_name() -> String:
	return item.display_name() if item != null else ""


func display_description() -> String:
	return item.display_description() if item != null else ""
