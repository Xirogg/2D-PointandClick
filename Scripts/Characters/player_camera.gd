class_name PlayerCamera
extends Camera2D

## Follows the player (it is a child of the Player) while never scrolling past
## the edges of the current scene's background, so the grey void outside the
## background is never revealed.
##
## Setup per level: add the level's background Sprite2D to the group named by
## `bounds_group` (default "camera_bounds"). This camera finds it automatically
## and clamps its limits to that sprite's world bounds.
##
## The background must be at least as large as the game viewport in each
## direction (which is the case since your scenes are bigger than the
## resolution). If you swap the background at runtime, call refresh_limits().

## Group the level's background Sprite2D must belong to.
@export var bounds_group: StringName = &"camera_bounds"

## How quickly the camera catches up to the player. Higher = snappier.
@export var follow_speed: float = 6.0


func _ready() -> void:
	# Smoothly glide toward the player instead of snapping every frame.
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	# Ease to a stop at the borders rather than clamping abruptly.
	limit_smoothed = true

	refresh_limits()


## Recompute the camera limits from the background in `bounds_group`.
func refresh_limits() -> void:
	var background := get_tree().get_first_node_in_group(bounds_group) as Node2D
	if background == null:
		push_warning("PlayerCamera: no node in group '%s'; camera limits not set." % bounds_group)
		return

	var rect := _get_world_rect(background)
	if rect.size == Vector2.ZERO:
		push_warning("PlayerCamera: background '%s' has no drawable size." % background.name)
		return

	limit_left = int(floor(rect.position.x))
	limit_top = int(floor(rect.position.y))
	limit_right = int(ceil(rect.position.x + rect.size.x))
	limit_bottom = int(ceil(rect.position.y + rect.size.y))


## Axis-aligned world-space bounding box of a Sprite2D, respecting
## centered/offset/scale/flip. Returns an empty Rect2 for other node types.
func _get_world_rect(node: Node2D) -> Rect2:
	if node is Sprite2D:
		var local_rect: Rect2 = (node as Sprite2D).get_rect()
		return node.get_global_transform() * local_rect
	return Rect2()
