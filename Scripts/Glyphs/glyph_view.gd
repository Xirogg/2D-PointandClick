class_name GlyphView
extends TextureRect

## One slot in the glyph gallery.
##
## A slot either shows a real Glyph out of the Lexicon (texture plus an editable
## guess), or it is `locked`: blacked out and labelled "???", standing in for a
## glyph the player has not reached yet.

const LOCKED_TEXT := "???"

@export var glyph_id: StringName
## Draws the slot as undiscovered. `glyph_id` is ignored while this is set.
@export var locked: bool = false

@onready var guess_label: Label = $GuessLabel   # sits under the glyph
@onready var locked_overlay: ColorRect = $LockedOverlay

func _ready() -> void:
	if locked:
		_setup_locked()
		return
	var glyph: Glyph = Lexicon.glyphs.get(glyph_id)
	if glyph == null:
		push_warning("glyph_view: no glyph registered for id '%s'" % [glyph_id])
		return
	texture = glyph.texture
	_refresh_guess()
	Lexicon.guess_changed.connect(_on_guess_changed)
	gui_input.connect(_on_input)

# Deliberately skips the Lexicon wiring above: a locked slot has no id to read a
# guess from or write one back to, and never connects gui_input, so it stays
# inert instead of opening an editor over an empty id.
func _setup_locked() -> void:
	texture = null
	locked_overlay.visible = true
	guess_label.text = LOCKED_TEXT
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_guess_changed(id: StringName, _word: String) -> void:
	if id == glyph_id:
		_refresh_guess()

# Un-named glyphs get a placeholder so no slot reads as blank/broken.
func _refresh_guess() -> void:
	var guess := Lexicon.get_guess(glyph_id)
	guess_label.text = guess if guess != "" else "?"

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_open_guess_editor()

func _open_guess_editor() -> void:
	if locked or has_node("GuessInput"):   # nothing to name / already editing
		return
	var line := LineEdit.new()
	line.name = "GuessInput"
	line.text = Lexicon.get_guess(glyph_id)
	line.placeholder_text = "Deine Vermutung…"
	line.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.select_all_on_focus = true
	line.add_theme_font_size_override("font_size", 16)
	add_child(line)
	line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	line.grab_focus()
	line.text_submitted.connect(func(t):
		Lexicon.set_guess(glyph_id, t)
		line.queue_free())
	line.focus_exited.connect(line.queue_free)
