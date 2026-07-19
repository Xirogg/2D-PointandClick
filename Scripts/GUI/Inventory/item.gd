extends Node2D

## An item lying in the level, waiting to be walked over to and picked up.
##
## This node holds no item data of its own — it points at an ItemData resource,
## which is also what the inventory, the recipes and the puzzles use. Setting up
## a pickup is therefore: drop item.tscn into the level, drag an ItemData into
## "Item", done.

## What this pickup gives the player. Drag in a .tres from res://Ressources/Items/.
@export var item: ItemData:
	set(value):
		item = value
		_refresh_icon()

# Optional manual override. Leave empty to let the item derive a stable,
# unique id automatically from where it is placed (see _resolve_item_id).
# Set this by hand if you want a specific, save-game-stable key for an item.
@export var item_id: StringName = &""

# Resolved once in _ready so pickup and the respawn check always agree.
var _resolved_id: StringName

@onready var icon: Sprite2D = $"Item Icon"


func _ready() -> void:
	_resolved_id = _resolve_item_id()

	# Already collected in this session? Don't respawn it.
	if Global.is_item_picked_up(_resolved_id):
		queue_free()
		return

	_refresh_icon()


# The setter can run before _ready (when the scene is being built), at which
# point the icon node does not exist yet. _ready calls this again.
func _refresh_icon() -> void:
	if icon == null:
		return
	icon.texture = item.texture if item != null else null


# Builds the key used to remember whether this item was picked up.
# Uses the level scene file + this node's path inside it, which stays the
# same every time the level is reloaded and is unique per placed item.
func _resolve_item_id() -> StringName:
	if item_id != &"":
		return item_id
	if owner != null:
		return StringName(owner.scene_file_path + "::" + str(owner.get_path_to(self)))
	# Fallback: no owner (e.g. spawned at runtime). ItemLogic.spawn_in_world
	# sets item_id explicitly, so reaching this means someone instantiated the
	# scene by hand without giving it a key.
	push_warning("Item '%s' has no owner and no item_id; set item_id for stable pickup state." % name)
	return StringName(get_path())


# Called by the Pickup_Range Interactable once the player has walked over to
# this item, so picking up never happens from across the room.
func _on_pickup_range_interacted(_player: Node2D) -> void:
	pickupitem()


func pickupitem() -> void:
	if item == null:
		push_warning("Item '%s' has no ItemData assigned; nothing to pick up." % name)
		return
	if not Global.PlayerNode:
		return

	# Global adds it to the inventory and records the pickup flag. Only remove
	# the world item if it was actually taken (e.g. not when inventory is full).
	if Global.pickup_world_item(item, _resolved_id):
		queue_free()
