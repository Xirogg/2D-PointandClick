extends TextureRect

## The armed item, drawn next to the mouse pointer.
##
## When the player presses "BENUTZEN" on an inventory slot, that item becomes
## Global.selected_item and the next click in the world is aimed at a puzzle
## hotspot. Without any feedback the armed state is invisible, so the player has
## no way to tell "click to walk" apart from "click to use the gas mask".
##
## This node just mirrors Global.selected_item: it shows that item's icon and
## follows the mouse while something is armed, and hides itself the moment the
## item is used up, cancelled, or swapped. Nothing else has to tell it to
## update, so any future way of arming an item is covered automatically.
##
## It sits in the Player HUD CanvasLayer, above the world but below nothing that
## matters, and never handles input itself - the icon must not swallow the very
## click it is advertising.

## Drawn down and to the right of the pointer, so the actual cursor tip stays
## visible for aiming.
const CURSOR_OFFSET := Vector2(10, 10)


func _ready() -> void:
	# Belt and braces: an icon that eats clicks would make the armed item
	# impossible to actually use.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	Global.selected_item_changed.connect(_on_selected_item_changed)

	# The armed item lives in an autoload and so survives a scene change, while
	# this node is rebuilt with the player. Syncing here means walking into a new
	# level with an item still armed keeps showing it.
	_on_selected_item_changed(Global.selected_item)


func _process(_delta: float) -> void:
	_follow_mouse()


func _on_selected_item_changed(item: ItemData) -> void:
	texture = item.texture if item != null else null
	visible = texture != null

	# Only chase the mouse while there is actually something to draw.
	set_process(visible)
	if visible:
		# Place it straight away rather than a frame late, otherwise the icon
		# flashes at wherever the mouse was the last time an item was armed.
		_follow_mouse()


func _follow_mouse() -> void:
	var target := get_viewport().get_mouse_position() + CURSOR_OFFSET
	# Keep the icon fully on screen when the pointer is near the right or bottom
	# edge, where the offset would otherwise push it half out of view.
	var limit := get_viewport_rect().size - size
	position = Vector2(minf(target.x, limit.x), minf(target.y, limit.y))
