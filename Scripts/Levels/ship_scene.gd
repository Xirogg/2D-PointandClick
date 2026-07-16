extends Node2D

## Which glyph the big button puts on screen. Exported so the same button can
## front a different glyph from the inspector once there are more of them.
@export var button_glyph_id: StringName = &"Test"

@onready var _glyph_popup: GlyphPopup = $GlyphPopup


func _on_button_pressed() -> void:
	_glyph_popup.open(button_glyph_id)
