extends Node2D

# Optional manual override. Leave empty to let the item derive a stable,
# unique id automatically from where it is placed (see _resolve_item_id).
# Set this by hand if you want a specific, save-game-stable key for an item.
@export var item_id: StringName = &""

@export var gd_name = ""
@export var item_name_de = ""
@export var item_texture: Texture
@export var item_descrpition_de = ""

#For Englisch localisation
@export var item_name_en = ""
@export var item_description_en = ""

var scene_path: String = "res://Scenes/GUI/Inventory/item.tscn"

# Resolved once in _ready so pickup and the respawn check always agree.
var _resolved_id: StringName


func _ready() -> void:
	_resolved_id = _resolve_item_id()

	# Already collected in this session? Don't respawn it.
	if Global.is_item_picked_up(_resolved_id):
		queue_free()
		return

	$"Item Icon".texture = item_texture


# Builds the key used to remember whether this item was picked up.
# Uses the level scene file + this node's path inside it, which stays the
# same every time the level is reloaded and is unique per placed item.
func _resolve_item_id() -> StringName:
	if item_id != &"":
		return item_id
	if owner != null:
		return StringName(owner.scene_file_path + "::" + str(owner.get_path_to(self)))
	# Fallback: no owner (e.g. spawned at runtime). Absolute path is less
	# robust but still stable as long as the tree layout is unchanged.
	push_warning("Item '%s' has no owner and no item_id; set item_id for stable pickup state." % name)
	return StringName(get_path())


# Called by the Pickup_Range Interactable once the player has walked over to
# this item, so picking up never happens from across the room.
func _on_pickup_range_interacted(_player: Node2D) -> void:
	pickupitem()


func pickupitem():
	if not Global.PlayerNode:
		return

	var Item = {
		"quantity": 1,
		"gd_name": gd_name,
		"name_de": item_name_de,
		"description_de": item_descrpition_de,
		"texture": item_texture,
		"scene_path": scene_path,
		"name_en": item_name_en,
		"description_en": item_description_en
	}

	# Global adds it to the inventory and records the pickup flag. Only remove
	# the world item if it was actually taken (e.g. not when inventory is full).
	if Global.pickup_world_item(Item, _resolved_id):
		self.queue_free()
