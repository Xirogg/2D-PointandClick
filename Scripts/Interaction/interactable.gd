class_name Interactable
extends Area2D

## A clickable thing in the world: an NPC, an item, a console, a door, ...
##
## This node is only the *hotspot*. It knows where it is and how close the
## player has to stand, but not what clicking it does — that lives in the scene
## that owns it, which connects the "interacted" signal.
##
## The Player finds these by a physics query on click, walks over if the
## hotspot is out of reach, and only then fires "interacted". So a handler can
## always assume the player is standing next to it.
##
## How to use / reuse:
##   1. Add this script to an Area2D and give it a CollisionShape2D covering
##      the surface the player should be able to click.
##   2. Connect "interacted" to the node that reacts to it
##      (prototype_npc.tscn is the smallest example).
##   3. Optional: add a Marker2D child and assign it to "Interaction Point" to
##      pin exactly where the player stops. Without one the player stops
##      "approach_distance" pixels short, on whichever side it walks in from.

## Fired once the player is actually standing close enough to this hotspot.
signal interacted(player: Node2D)

## Fired instead of "interacted" when the player clicks this hotspot while an
## item is armed with "BENUTZEN". Only hotspots that actually connect this take
## the item route — everywhere else an armed item changes nothing and the click
## still means "interact", so arming a picture cannot silently break the console
## or an NPC.
signal item_used(item: ItemData, player: Node2D)

## The physics layer every Interactable lives on. The Player masks exactly this
## layer, both for its reach area and for the click query, so the two cannot
## drift apart.
const PHYSICS_LAYER: int = 3

## Free-text label for this hotspot. Cosmetic — handy in debug prints and for
## hover text later on.
@export var display_name: String = ""

## Where the player has to stand to use this. Leave empty to derive it from
## "approach_distance" instead.
@export var interaction_point: Marker2D

## How far short of this hotspot the player stops when no interaction_point is
## set. Keep it below the Player's reach radius, otherwise the player walks up
## but still does not count as being in range.
@export var approach_distance: float = 40.0

## Unticked = clicks fall straight through to plain "walk there" movement, as
## if this hotspot were not here at all.
@export var enabled: bool = true


func _ready() -> void:
	# Forced here instead of being left to each scene file: a hand-built
	# Interactable that silently sits on the wrong layer would be invisible to
	# the player's click query, which is a miserable thing to debug.
	collision_layer = 1 << (PHYSICS_LAYER - 1)
	collision_mask = 0
	# The player's reach area is what does the looking, so we have to be
	# monitorable — but we never need to detect anything ourselves.
	monitorable = true
	monitoring = false


## The world X the player has to reach before interact() fires.
## "from_x" is where the player is standing when the click happens, which picks
## the side it walks up to.
func get_walk_target_x(from_x: float) -> float:
	if interaction_point != null:
		return interaction_point.global_position.x
	if from_x < global_position.x:
		return global_position.x - approach_distance
	return global_position.x + approach_distance


## Called by the Player once the walk (if there was one) is done. Not meant to
## be called by hand — going through Player.click_at() is what guarantees the
## player is actually there.
func interact(player: Node2D) -> void:
	if not enabled:
		return
	var armed := Global.selected_item
	if armed != null and not item_used.get_connections().is_empty():
		item_used.emit(armed, player)
		return
	interacted.emit(player)
