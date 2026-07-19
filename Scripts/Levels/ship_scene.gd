extends Node2D

## Which glyph the console opens on the very first time. After that the console
## reopens on whatever the player last cycled to, so the selection survives
## walking away and coming back.
@export var console_glyph_id: StringName = &"Zeit"

@onready var _glyph_popup: GlyphPopup = $GlyphPopup


func _ready() -> void:
	# Arriving here at all is a story beat: the NPCs back at the base camp
	# switch to their stage 2 dialogue from now on.
	Global.mark_ship_visited()


## Called by the Console Interactable once the player has walked over to it.
func _on_console_interacted(_player: Node2D) -> void:
	var id := Lexicon.active_glyph_id
	if id == &"":
		id = console_glyph_id
	_glyph_popup.open(id)
