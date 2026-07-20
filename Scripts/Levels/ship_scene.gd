extends Node2D

const BASE_CAMP_SCENE := "res://Scenes/Levels/base_camp_scene.tscn"

## Which glyph the console opens on the very first time. After that the console
## reopens on whatever the player last cycled to, so the selection survives
## walking away and coming back.
@export var console_glyph_id: StringName = &"Zeit"

@export_group("Decoder feedback")
## What gets tinted. Exported so the feedback can move to a different node (a
## light, a full-screen ColorRect) without touching this script.
@export var background: CanvasItem
## Tinted over the background while the answer is being shown. Modulate is a
## multiply, so these read as "darken towards green/red" rather than a flat fill.
@export var correct_color: Color = Color(0.235294, 0.501961, 0.286275)
@export var wrong_color: Color = Color(0.549020, 0.180392, 0.180392)
## Seconds to ease into the colour, sit on it, and drain back out.
@export var fade_in_time: float = 0.6
@export var hold_time: float = 1.0
@export var fade_out_time: float = 0.6

@onready var _glyph_popup: GlyphPopup = $GlyphPopup

## The running feedback tween, kept so a second attempt can cut the first one
## short instead of the two fighting over modulate.
var _feedback_tween: Tween = null


func _ready() -> void:
	# Arriving here at all is a story beat: the NPCs back at the base camp
	# switch to their stage 2 dialogue from now on.
	Global.mark_ship_visited()

	# The ship's own footstep sound, plus the one-shot that greets the player on
	# arrival (only fired here in _ready, so re-opening the console doesn't).
	AudioManager.set_footsteps_stream(AudioManager.WALK_SHIP)
	AudioManager.play(AudioManager.SHIP_ENTER)


## Called by the Console Interactable once the player has walked over to it.
func _on_console_interacted(_player: Node2D) -> void:
	AudioManager.play(AudioManager.CONSOLE_POPUP)
	var id := Lexicon.active_glyph_id
	if id == &"":
		id = console_glyph_id
	_glyph_popup.open(id)


## Called by the Scene Changer Interactable — the way back to the base camp.
## Being an Interactable rather than a body_entered trigger means the player
## walks over to it on click instead of teleporting the moment he brushes past.
func _on_scene_changer_interacted(_player: Node2D) -> void:
	# Tells the camp which entrance to stand the player at.
	Global.came_from = scene_file_path
	get_tree().change_scene_to_file(BASE_CAMP_SCENE)


## Called by the Item Check Interactable when the player uses an armed item on
## it. Holding a picture against the console says "this is what that glyph
## means" — the background answers in green or red.
##
## Anything that is not one of the decoding pictures is ignored outright, as is
## an attempt made with no glyph on the console, since there would be nothing to
## be right or wrong about.
func _on_item_check_item_used(item: ItemData, _player: Node2D) -> void:
	if item == null or not Lexicon.is_decoding_item(item.id):
		return
	if Lexicon.get_active_glyph() == null:
		return
	_flash_background(Lexicon.item_matches_active_glyph(item.id))


## Eases the background to `color`, holds, and eases back to untinted.
## Always ends on Color.WHITE, so an interrupted flash cannot strand the
## background mid-tint.
func _flash_background(matched: bool) -> void:
	if background == null:
		push_warning("ship_scene: no 'background' assigned, decoder feedback is invisible.")
		return

	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	var color := correct_color if matched else wrong_color
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(background, "modulate", color, fade_in_time)
	_feedback_tween.tween_interval(hold_time)
	_feedback_tween.tween_property(background, "modulate", Color.WHITE, fade_out_time)
