extends AnimatedSprite2D

# Decoration for the menu backdrop: a helicopter that crosses the screen on a loop.
#
# It sits between the Parallax2D and the Menu overlay, so while the menu is up it is
# dimmed by the darkening ColorRect along with everything else behind it, and it comes
# up to full brightness with the parallax once "Spielen" fades the menu out.
#
# Movement is plain screen-space drift, not parallax: once the sprite has fully left
# one side it is put back just outside the other, so the fly-by repeats forever.

## Pixels per second. Positive flies right (the way the sprite faces), negative flies left.
@export var speed: float = 55.0

## How far the helicopter drifts up and down, in pixels. Set to 0 for a dead straight line.
@export var bob_amplitude: float = 3.0

## Full up-and-down cycles per second.
@export var bob_speed: float = 0.6

var _base_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	# The bob is an offset from wherever the node was placed in the editor.
	_base_y = position.y
	play()


func _process(delta: float) -> void:
	_time += delta
	position.x += speed * delta

	# The whole frame has to be off screen before it comes back, otherwise it pops.
	var half_width: float = _frame_width() * 0.5
	var view_width: float = get_viewport_rect().size.x
	if speed > 0.0 and position.x - half_width > view_width:
		position.x = -half_width
	elif speed < 0.0 and position.x + half_width < 0.0:
		position.x = view_width + half_width

	position.y = _base_y + sin(_time * bob_speed * TAU) * bob_amplitude


# Width of the current frame in screen pixels, scale included.
func _frame_width() -> float:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return 0.0
	var texture: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	if texture == null:
		return 0.0
	return texture.get_width() * absf(global_scale.x)
