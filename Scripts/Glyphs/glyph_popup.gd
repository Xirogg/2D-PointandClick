class_name GlyphPopup
extends CanvasLayer

## Shows one glyph at a time, together with the word the player thinks it means.
##
## Instance this scene wherever a glyph needs to be opened (a level root, a HUD,
## ...), leave it hidden, and call open(id). Everything on display is pulled from
## the Lexicon autoload, so a single instance can show every glyph in the game —
## call open() again with another id to swap it, or let the player walk the whole
## set with the two arrow buttons.
##
## Whatever glyph stands on screen is the *active* glyph: the popup writes it to
## Lexicon.set_active_glyph(), so anything else in the level (the console's
## Sprite2D, later on doors/terminals/...) can follow along without knowing this
## scene exists.
##
## The guess is written back to the Lexicon on Enter, on close, and before every
## arrow press, which makes any GlyphView listening to Lexicon.guess_changed
## relabel itself.

## Emitted once the popup has hidden and the guess is saved.
signal closed

## The glyph on display. Empty until the first open()/show_glyph().
var glyph_id: StringName = &""

@onready var _title: Label = %Title
@onready var _glyph_texture: TextureRect = %GlyphTexture
@onready var _name_input: LineEdit = %NameInput
@onready var _prev_button: Button = %PrevButton
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	# A single glyph has nothing to cycle to; hiding the arrows beats leaving
	# two buttons that visibly do nothing.
	var has_cycle := Lexicon.get_ordered_ids().size() > 1
	_prev_button.visible = has_cycle
	_next_button.visible = has_cycle


## Shows `id` and pops the window open, ready for typing. An empty or unknown id
## falls back to the first glyph in the cycle, so callers that do not care which
## one comes up can just call open().
func open(id: StringName = &"") -> void:
	if not Lexicon.glyphs.has(id):
		id = Lexicon.get_glyph_id_offset_from(&"", 0)
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
	Lexicon.set_active_glyph(id)
	_refresh_title()


## Saves whatever stands in the input field, then hides the popup.
func close() -> void:
	_commit_guess()
	visible = false
	closed.emit()


## Steps `step` glyphs along the cycle (-1 back, +1 forward), keeping the guess
## the player has already typed for the glyph being left behind.
func cycle(step: int) -> void:
	_commit_guess()
	var next_id := Lexicon.get_glyph_id_offset_from(glyph_id, step)
	if next_id == &"" or next_id == glyph_id:
		return
	show_glyph(next_id)
	_name_input.grab_focus()


# Guarded against a popup that was never given a glyph, so a stray close()
# cannot write a guess under an empty id.
func _commit_guess() -> void:
	if glyph_id == &"":
		return
	Lexicon.set_guess(glyph_id, _name_input.text.strip_edges())


# "Glyphe 2 / 3" — without a counter the arrows give no sense of how much is
# left, and wrapping around is indistinguishable from being stuck.
func _refresh_title() -> void:
	var ids := Lexicon.get_ordered_ids()
	var index := ids.find(glyph_id)
	if index == -1:
		_title.text = "Glyphe"
		return
	_title.text = "Glyphe %d / %d" % [index + 1, ids.size()]


func _on_name_input_text_submitted(_new_text: String) -> void:
	close()


func _on_close_button_pressed() -> void:
	close()


func _on_prev_button_pressed() -> void:
	cycle(-1)


func _on_next_button_pressed() -> void:
	cycle(1)
