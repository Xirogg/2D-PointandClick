class_name Player
extends CharacterBody2D

## Point-and-click movement plus the "walk there first" interaction rule.
##
## Every left click goes through click_at(), which decides one of two things:
##   * the click landed on an Interactable  -> use it, walking over first if it
##     is not already inside InteractionArea
##   * the click landed on empty ground     -> just walk there
##
## InteractionArea is the small area around the player that defines "close
## enough to use without walking". Resize its CollisionShape2D to make the
## player reach further, and keep Interactable.approach_distance below its
## radius so that walking up actually lands inside it.

@export var Speed: int = 250
## Keeps the player this many pixels inside the scene edges
## (0 = exactly the camera/background bounds).
@export var edge_margin: float = 0.0

## Below this the player is treated as standing on the target already, so no
## walk is started and no arrival is expected. Only has to be big enough to
## swallow float noise; overshoot is handled in _physics_process.
const ARRIVE_EPSILON: float = 1.0

## Safety cap on how many hotspots one click may return. Only matters for
## hotspots stacked on the same pixel.
const MAX_HOTSPOTS_PER_CLICK: int = 32

## The two animations in the sprite's SpriteFrames.
const IDLE_ANIMATION: StringName = &"idle"
const WALK_ANIMATION: StringName = &"walk"

@onready var escalation_bar: ProgressBar = $"Player HUD/EscalationBar"

## Maya's sprite. Holds the "idle" and "walk" animations; the art faces right, so
## walking left is a horizontal flip.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var camera: Camera2D = $Camera2D

## Anything overlapping this counts as close enough to use without walking.
@onready var interaction_area: Area2D = $InteractionArea


var click_target := Vector2.ZERO

## What to use once the current walk finishes. Null when the player is just
## moving, so a plain move order silently cancels a pending interaction.
var _pending_interactable: Interactable = null

## True while a walk is running, so arrival fires exactly once.
var _walking: bool = false


func _ready() -> void:
	click_target = position

	# item.gd and friends reach the player through here.
	Global.player_reference(self)

	# Only see Interactables, and stay invisible to everything else: this area
	# is a pure detector, so it deliberately sits on no layer of its own.
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 1 << (Interactable.PHYSICS_LAYER - 1)

	# Reflect the global escalation tracker on the HUD progress bar.
	Global.escalation_changed.connect(_on_escalation_changed)
	_on_escalation_changed(Global.escalation)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("LMB (Single)"):
		click_at(get_global_mouse_position())


## Reacts to a click at `world_position`. Split out from _unhandled_input so the
## decision can be driven without a real mouse (tests, cutscenes, a "use item on
## thing" flow later).
func click_at(world_position: Vector2) -> void:
	var target := _interactable_at(world_position)
	if target == null:
		# Plain move order — drop whatever we were on the way to.
		_pending_interactable = null
		_set_walk_target(round(world_position.x))
		return

	_use(target)


func _physics_process(delta: float) -> void:
	var distance_x := click_target.x - position.x

	# Still more than one step away: keep walking.
	if absf(distance_x) > Speed * delta:
		var direction := signf(distance_x)
		velocity = Vector2(direction * Speed, 0.0)
		move_and_slide()
		_face(direction)
		_play(WALK_ANIMATION)
		return

	# Within a single step, so land exactly on the target instead of stepping
	# over it and jittering back and forth.
	position.x = click_target.x
	velocity = Vector2.ZERO
	# Standing still keeps whichever way Maya was last facing.
	_play(IDLE_ANIMATION)

	if _walking:
		_walking = false
		_arrive()


## A click landed on `target`: use it now if it is already in reach, otherwise
## walk over and use it on arrival.
func _use(target: Interactable) -> void:
	if is_in_reach(target):
		_pending_interactable = null
		_set_walk_target(position.x)  # stop where we are
		target.interact(self)
		return

	_pending_interactable = target
	_set_walk_target(target.get_walk_target_x(position.x))

	if not _walking:
		# Standing on the interaction point yet still out of reach — e.g. a
		# hotspot mounted well above or below the player. There is nothing to
		# walk, and waiting for an arrival that never comes would make the
		# click do nothing at all.
		_arrive()


## Turns Maya to face `direction` (-1 left, 1 right). The art is drawn facing
## right, so only leftward movement is mirrored. A direction of 0 leaves her
## facing whichever way she already was.
func _face(direction: float) -> void:
	if direction != 0.0:
		sprite.flip_h = direction < 0.0


## Switches to `animation_name`, ignoring the call when it is already running so
## the loop is not restarted from frame 0 every physics tick.
func _play(animation_name: StringName) -> void:
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


## Whether `target` currently overlaps the interaction area around the player.
func is_in_reach(target: Interactable) -> bool:
	return target in interaction_area.get_overlapping_areas()


## Runs the interaction the current walk was started for, if any.
func _arrive() -> void:
	var target := _pending_interactable
	_pending_interactable = null
	# The target can die mid-walk (an item picked up by other means, an NPC
	# leaving), so re-check before touching it.
	if target != null and is_instance_valid(target):
		target.interact(self)


## Points the walk at world X `x`, clamped into the scene. Sets `_walking` so
## _physics_process knows whether an arrival is still owed.
func _set_walk_target(x: float) -> void:
	click_target = Vector2(_clamp_x_to_bounds(x), position.y)
	_walking = absf(click_target.x - position.x) > ARRIVE_EPSILON


## The Interactable under `world_position`, or null when the click landed on
## empty ground. Disabled hotspots are skipped so their clicks fall through to
## plain movement.
func _interactable_at(world_position: Vector2) -> Interactable:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1 << (Interactable.PHYSICS_LAYER - 1)

	var hits := get_world_2d().direct_space_state.intersect_point(query, MAX_HOTSPOTS_PER_CLICK)

	var best: Interactable = null
	for hit in hits:
		var candidate := hit.get("collider") as Interactable
		if candidate == null or not candidate.enabled:
			continue
		if best == null or _outranks(candidate, best):
			best = candidate
	return best


## Tie-break for overlapping hotspots: the one drawn on top wins, and at equal
## depth the one nearer to the player does.
func _outranks(candidate: Interactable, best: Interactable) -> bool:
	if candidate.z_index != best.z_index:
		return candidate.z_index > best.z_index
	var candidate_distance := absf(candidate.global_position.x - position.x)
	var best_distance := absf(best.global_position.x - position.x)
	return candidate_distance < best_distance


func _on_escalation_changed(value: int) -> void:
	escalation_bar.value = value

	# Colour the fill in discrete bands so the bar reads "good -> bad".
	# Mutates this bar's own fill stylebox.
	var fill := escalation_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = _escalation_color(value)


# Maps an escalation value (0..10) to its band colour.
#   0-3  green | 4-5  yellow | 6-7  dark orange | 8+  red
func _escalation_color(value: int) -> Color:
	if value <= 3:
		return Color(0.223529, 0.662745, 0.4)     # green
	elif value <= 5:
		return Color(0.898039, 0.831373, 0.223529) # yellow
	elif value <= 7:
		return Color(0.803922, 0.435294, 0.101961) # dark orange
	else:
		return Color(0.992157, 0.235294, 0.235294) # red


## Clamps a world X to the scene's horizontal bounds — the same limits the
## camera stops at — so a click out of bounds walks the player as far as
## possible and no further.
func _clamp_x_to_bounds(x: float) -> float:
	var min_x := camera.limit_left + edge_margin
	var max_x := camera.limit_right - edge_margin
	if min_x > max_x:
		# Scene narrower than the margins; fall back to its centre.
		return (camera.limit_left + camera.limit_right) * 0.5
	return clampf(x, min_x, max_x)



func _on_inventory_button_pressed() -> void:
	$InventoryLayer.show()


func _on_close_inv_pressed() -> void:
	$InventoryLayer.hide()
