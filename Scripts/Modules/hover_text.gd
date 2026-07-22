extends CanvasLayer

## The level's hover-name overlay: a single small label that names whatever
## point of interest the mouse is over ("Konsole", "Finn", "Großes Zelt", ...),
## so the player can tell a clickable hotspot from plain scenery before spending
## a click on it.
##
## There is exactly one of these per level, sitting at the scene root, and it
## touches none of the hotspots. Every physics frame it asks the physics world
## what Interactable is under the cursor — the very same point query the Player
## uses to resolve a click (player.gd `_interactable_at`) — and shows that
## hotspot's `display_name`. Two things fall out of sharing that query:
##   * anything the player can click gets a label for free, using the collision
##     shape the hotspot already has; nothing new to wire up per POI, and
##   * the label always names exactly what a click would hit.
## A hotspot opts out simply by leaving its `display_name` empty.
##
## How to use / reuse:
##   1. Instance this scene once at the root of a level.
##   2. Give every Interactable that should be named a `display_name`.
## That is all — no per-hotspot wiring, no extra collision shapes.

## The one physics layer every Interactable lives on; the only thing we probe.
const HOTSPOT_MASK: int = 1 << (Interactable.PHYSICS_LAYER - 1)

## Safety cap on hits per query, matching the Player's click query. Only ever
## matters for hotspots stacked on the same pixel.
const MAX_HOTSPOTS: int = 32

## Where the label sits relative to the cursor. Down-and-right keeps it clear of
## the custom cursor, whose own hotspot is the top-left corner.
const CURSOR_OFFSET: Vector2 = Vector2(12, 10)

## Pixels kept between the label and the screen edge when it would overflow.
const EDGE_PADDING: float = 2.0

@onready var _panel: PanelContainer = $Panel
@onready var _label: Label = $Panel/Label


func _ready() -> void:
	_panel.hide()


# Polled in _physics_process rather than _process: the point query reads the
# physics world, which is only guaranteed to be settled during the physics step.
func _physics_process(_delta: float) -> void:
	var hotspot := _hotspot_under_cursor()
	if hotspot == null or hotspot.display_name.is_empty():
		_panel.hide()
		return

	_label.text = hotspot.display_name
	_panel.show()
	_follow_cursor()


## The topmost enabled Interactable under the mouse, or null over empty ground.
## Mirrors Player._interactable_at so the label names exactly what a click would
## hit; on overlap the hotspot drawn on top wins.
func _hotspot_under_cursor() -> Interactable:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _world_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = HOTSPOT_MASK

	var hits := get_viewport().get_world_2d().direct_space_state.intersect_point(query, MAX_HOTSPOTS)

	var best: Interactable = null
	for hit in hits:
		var candidate := hit.get("collider") as Interactable
		if candidate == null or not candidate.enabled:
			continue
		if best == null or candidate.z_index > best.z_index:
			best = candidate
	return best


## Screen mouse -> world, through the same canvas transform the camera drives,
## so the query lines up with what is drawn no matter where the camera has
## panned. (A CanvasLayer is not a CanvasItem, so get_global_mouse_position is
## not available here.)
func _world_mouse_position() -> Vector2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()


## Parks the label just off the cursor, snapped to a whole pixel — the game
## renders at 640x360 with integer scaling, so a fractional offset would shimmer
## — and nudged back inside the screen when it would run past an edge.
func _follow_cursor() -> void:
	var viewport := get_viewport()
	var screen := viewport.get_visible_rect().size
	var size := _panel.get_combined_minimum_size()

	var pos := viewport.get_mouse_position() + CURSOR_OFFSET
	pos.x = clampf(pos.x, EDGE_PADDING, screen.x - size.x - EDGE_PADDING)
	pos.y = clampf(pos.y, EDGE_PADDING, screen.y - size.y - EDGE_PADDING)
	_panel.position = pos.round()
