extends Area2D

## A puzzle hotspot: "use item X on this spot to make something happen".
##
## Drop this under the node that owns the puzzle, drag the required ItemData
## into "Needed Item", and give the parent an Execute_Function() / Execute_Action()
## pair. Matching happens on the ItemData resource itself, so renaming or
## translating the item cannot break the puzzle.

## The item the player has to have armed with "BENUTZEN" for this to fire.
@export var needed_item: ItemData

## Ticked = the item is consumed when the puzzle succeeds.
@export var consume_item: bool = false

## Fired when the right item was used here, for anything that would rather
## listen than implement Execute_Action on the parent.
signal solved(item: ItemData)

var mouse_in_range: bool = false


# _unhandled_input instead of polling in _process: this used to run a
# get-input check every frame on every puzzle hotspot in the level.
func _unhandled_input(event: InputEvent) -> void:
	if not mouse_in_range:
		return
	if event.is_action_pressed("LMB (Single)"):
		Handle_Activity()


func Handle_Activity() -> void:
	if needed_item == null:
		return
	if Global.selected_item != needed_item:
		return

	var parent := get_parent()

	# The parent decides whether the puzzle may fire right now (e.g. a door
	# that is already open says no).
	if parent.has_method("Execute_Function") and not parent.Execute_Function():
		return

	if parent.has_method("Execute_Action"):
		parent.Execute_Action()
	else:
		push_warning("activity_module on '%s': parent has no Execute_Action()." % parent.name)

	if consume_item:
		ItemLogic.take(needed_item.id)

	# Using an item on the thing it belongs to spends the arming, so the next
	# click somewhere else is not still carrying it.
	Global.select_item(null)
	solved.emit(needed_item)


func _on_area_entered(_area: Area2D) -> void:
	mouse_in_range = true


func _on_area_exited(_area: Area2D) -> void:
	mouse_in_range = false
