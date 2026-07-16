class_name GlyphPopup
extends CanvasLayer

## Shows one glyph at a time, together with the word the player thinks it means.
##
## Instance this scene wherever a glyph needs to be opened (a level root, a HUD,
## ...), leave it hidden, and call open(id). Everything on display is pulled from
## the Lexicon autoload, so a single instance can show every glyph in the game —
## call open() again with another id to swap it.
##
## The guess is written back to the Lexicon on Enter or on close, which makes any
## GlyphView listening to Lexicon.guess_changed relabel itself.

## Emitted once the popup has hidden and the guess is saved.
signal closed

## The glyph on display. Empty until the first open()/show_glyph().
var glyph_id: StringName = &""

@onready var _glyph_texture: TextureRect = %GlyphTexture
@onready var _name_input: LineEdit = %NameInput


## Shows `id` and pops the window open, ready for typing.
func open(id: StringName) -> void:
	show_glyph(id)
	visible = true
	_name_input.grab_focus()


## Swaps the displayed glyph without touching visibility. An unknown id leaves
## the previous glyph up rather than blanking the popup.
func show_glyph(id: StringName) -> void:
	var glyph: Glyph = Lexicon.glyphs.get(id)
	if glyph == null:
		push_warning("glyph_popup: no glyph registered for id '%s'" % [id])
		return
	glyph_id = id
	_glyph_texture.texture = glyph.texture
	_name_input.text = Lexicon.get_guess(id)


## Saves whatever stands in the input field, then hides the popup.
func close() -> void:
	_commit_guess()
	visible = false
	closed.emit()


# Guarded against a popup that was never given a glyph, so a stray close()
# cannot write a guess under an empty id.
func _commit_guess() -> void:
	if glyph_id == &"":
		return
	Lexicon.set_guess(glyph_id, _name_input.text.strip_edges())


func _on_name_input_text_submitted(_new_text: String) -> void:
	close()


func _on_close_button_pressed() -> void:
	close()
