extends Control

## One inventory cell: the pixel-art frame, the item icon drawn on top of it,
## and the two small popups that open above it (use / combine).
##
## Hover and press visuals come from ItemButton's StyleBoxTextures, so there is
## no state-juggling code here. The slot also never reaches up into the
## inventory UI by walking get_parent() chains — it reports what happened
## through signals and lets inventory_ui.gd decide, so it keeps working no
## matter how deeply the UI ends up nested in the Player scene.

## Brightening laid over the whole slot while it is dragged with RMB.
const DRAG_TINT := Color(1.5, 1.5, 1.5)

signal drag_start(slot)
signal drag_end()
## LMB on this slot. The UI fills the name/description labels from it and
## closes the popups still open on other slots.
signal selected(slot)
## "BENUTZEN" pressed. The UI closes the inventory.
signal use_requested(slot)
## "Kombinieren" pressed. The UI runs the crafting check.
signal craft_requested(slot)

## The ItemStack shown here, or null while the slot is empty.
var stack: ItemStack = null

@onready var item_icon: TextureRect = $ItemIcon
@onready var use_button: Button = $UseButton
@onready var craft_button: Button = $CraftButton


## The ItemData in this slot, or null. Recipes and puzzles work on this.
func item() -> ItemData:
	return stack.item if stack != null else null


func set_stack(new_stack: ItemStack) -> void:
	stack = new_stack
	if stack == null or stack.item == null:
		setempty()
		return
	item_icon.texture = stack.item.texture


func setempty() -> void:
	stack = null
	item_icon.texture = null
	hide_popups()


## Name in the player's language, empty while the slot is empty.
func display_name() -> String:
	return stack.display_name() if stack != null else ""


## Description in the player's language, empty while the slot is empty.
func display_description() -> String:
	return stack.display_description() if stack != null else ""


func show_craft_interface() -> void:
	use_button.hide()
	craft_button.show()


func hide_craft_interface() -> void:
	craft_button.hide()


func hide_popups() -> void:
	use_button.hide()
	craft_button.hide()


func _on_item_button_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		selected.emit(self)
		# An empty slot has nothing to use, so it only clears the labels.
		if stack != null:
			use_button.show()
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		if event.is_pressed():
			modulate = DRAG_TINT
			drag_start.emit(self)
		else:
			modulate = Color.WHITE
			drag_end.emit()


func _on_use_button_pressed() -> void:
	use_button.hide()
	var data := item()
	if data == null:
		return

	use_requested.emit(self)
	Global.select_item(data)


func _on_craft_button_pressed() -> void:
	craft_button.hide()
	craft_requested.emit(self)
