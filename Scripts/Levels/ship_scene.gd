extends Node2D

## Which glyph the console puts on screen. Exported so the same console can
## front a different glyph from the inspector once there are more of them.
@export var console_glyph_id: StringName = &"Test"

@onready var _glyph_popup: GlyphPopup = $GlyphPopup


func _ready() -> void:
	# Arriving here at all is a story beat: the NPCs back at the base camp
	# switch to their stage 2 dialogue from now on.
	Global.mark_ship_visited()


## Called by the Console Interactable once the player has walked over to it.
func _on_console_interacted(_player: Node2D) -> void:
	_glyph_popup.open(console_glyph_id)
