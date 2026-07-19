extends Node

signal glyph_discovered(glyph: Glyph)
signal guess_changed(id: StringName, word: String)
signal glyph_confirmed(id: StringName)
## Fired the moment the last still-untranslated glyph is named correctly.
## Global listens to this to move the story on to its final stage.
signal all_glyphs_translated()

var glyphs: Dictionary = {}      # id -> Glyph
var guesses: Dictionary = {}     # id -> String (player's guess)
var discovered: Dictionary = {}  # id -> bool
var confirmed: Dictionary = {}   # id -> bool

func _ready() -> void:
	_load_all()

func register(g: Glyph) -> void:
	glyphs[g.id] = g

func discover(id: StringName) -> void:
	if not discovered.get(id, false):
		discovered[id] = true
		glyph_discovered.emit(glyphs[id])

func set_guess(id: StringName, word: String) -> void:
	guesses[id] = word
	guess_changed.emit(id, word)
	_refresh_confirmation(id)

func get_guess(id: StringName) -> String:
	return guesses.get(id, "")


# --- Correctness ----------------------------------------------------
# "Correct" means the guess matches one of the glyph's acceptable_words,
# ignoring case and surrounding whitespace. A glyph with an empty
# acceptable_words list can never be correct — fill that list in the .tres,
# otherwise the story can never reach its final stage.

func is_glyph_correct(id: StringName) -> bool:
	var glyph: Glyph = glyphs.get(id)
	if glyph == null or glyph.acceptable_words.is_empty():
		return false
	var guess := get_guess(id).strip_edges().to_lower()
	if guess.is_empty():
		return false
	for word in glyph.acceptable_words:
		if word.strip_edges().to_lower() == guess:
			return true
	return false


## True once every glyph in the game carries a correct name.
## No glyphs loaded at all counts as false, so an empty Ressources/Glyphs
## folder cannot skip the story straight to the end.
func is_everything_translated() -> bool:
	if glyphs.is_empty():
		return false
	for id in glyphs:
		if not is_glyph_correct(id):
			return false
	return true


# Keeps "confirmed" in step with the current guess. Tracks the present truth
# rather than "was right once", so overwriting a correct name with a wrong one
# takes the glyph back out of the translated set.
func _refresh_confirmation(id: StringName) -> void:
	var was_confirmed: bool = confirmed.get(id, false)
	var is_correct := is_glyph_correct(id)
	confirmed[id] = is_correct
	if is_correct and not was_confirmed:
		glyph_confirmed.emit(id)
		if is_everything_translated():
			all_glyphs_translated.emit()


func _load_all() -> void:
	var dir := "res://Ressources/Glyphs/"
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			var g := load(dir + file) as Glyph
			if g != null:
				register(g)
