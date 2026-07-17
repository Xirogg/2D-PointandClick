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

## The inventory entry shown here, or null while the slot is empty.
var item = null

@onready var item_icon: TextureRect = $ItemIcon
@onready var use_button: Button = $UseButton
@onready var craft_button: Button = $CraftButton


func set_item(new_item) -> void:
	item = new_item
	item_icon.texture = new_item["texture"]


func setempty() -> void:
	item = null
	item_icon.texture = null
	hide_popups()


## Name in the player's language, empty while the slot is empty.
func display_name() -> String:
	if item == null:
		return ""
	return item["name_de"] if Global.SelectedLanguage == "de" else item["name_en"]


## Description in the player's language, empty while the slot is empty.
func display_description() -> String:
	if item == null:
		return ""
	return item["description_de"] if Global.SelectedLanguage == "de" else item["description_en"]


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
		if item != null:
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
	if item == null:
		return

	use_requested.emit(self)

	if item["name_de"] == "Luna":
		_unlock_lunari()
		return

	# Puzzles match on the German name (see activity_module.needed_item), so
	# this key deliberately ignores the selected language.
	Global.change_selecteditem(item["name_de"])


## The Lunari token unlocks the shapeshift rather than becoming a held item.
## Player does not define `shpapeshiftable_races` yet, so this warns instead of
## crashing until that half exists.
func _unlock_lunari() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player == null or not "shpapeshiftable_races" in player:
		push_warning("Luna used, but Player has no 'shpapeshiftable_races' - shapeshift unlock skipped.")
		return
	player.shpapeshiftable_races["Lunari"] = true


func _on_craft_button_pressed() -> void:
	craft_button.hide()
	craft_requested.emit(self)
