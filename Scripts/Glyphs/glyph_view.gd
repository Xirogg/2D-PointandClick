class_name GlyphView
extends TextureRect

@export var glyph_id: StringName
@onready var guess_label: Label = $GuessLabel   # sits under the glyph

func _ready() -> void:
	var glyph: Glyph = Lexicon.glyphs.get(glyph_id)
	if glyph == null:
		push_warning("glyph_view: no glyph registered for id '%s'" % [glyph_id])
		return
	texture = glyph.texture
	_refresh_guess()
	Lexicon.guess_changed.connect(_on_guess_changed)
	gui_input.connect(_on_input)

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
	if has_node("GuessInput"):   # already editing
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
