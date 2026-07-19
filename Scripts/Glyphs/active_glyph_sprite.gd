class_name ActiveGlyphSprite
extends Sprite2D

## Mirrors whatever glyph is currently active in the Lexicon.
##
## Drop this on any Sprite2D and it follows the player's selection — no wiring
## to the console popup needed, the Lexicon sits between the two. Works the same
## in any scene, so a second display elsewhere is just another node with this
## script on it.

## Blanks the sprite while no glyph is selected. Turn off to keep the last glyph
## on screen after the console closes.
@export var hide_when_none: bool = true


func _ready() -> void:
	Lexicon.active_glyph_changed.connect(_on_active_glyph_changed)
	# The selection may already exist (the player has used the console before
	# this scene loaded), so read it once instead of waiting for the next change.
	_refresh(Lexicon.get_active_glyph())


func _on_active_glyph_changed(glyph: Glyph) -> void:
	_refresh(glyph)


func _refresh(glyph: Glyph) -> void:
	texture = glyph.texture if glyph != null else null
	if hide_when_none:
		visible = glyph != null
