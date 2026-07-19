extends Node

signal glyph_discovered(glyph: Glyph)
signal guess_changed(id: StringName, word: String)
signal glyph_confirmed(id: StringName)
## Fired the moment the last still-untranslated glyph is named correctly.
## Global listens to this to move the story on to its final stage.
signal all_glyphs_translated()
## The glyph the player currently has "in hand" — whatever the ship console is
## showing. Carries null when nothing is selected.
signal active_glyph_changed(glyph: Glyph)

var glyphs: Dictionary = {}      # id -> Glyph
var guesses: Dictionary = {}     # id -> String (player's guess)
var discovered: Dictionary = {}  # id -> bool
var confirmed: Dictionary = {}   # id -> bool

## Cycle order for the console, sorted by Glyph.sort_order then id. Kept apart
## from `glyphs` because a Dictionary's order follows load order, which is
## whatever the filesystem hands back.
var glyph_order: Array[StringName] = []

## Which glyph is selected right now. Anything that needs to react to the
## player's current pick reads this / listens to active_glyph_changed instead of
## reaching into the console UI.
var active_glyph_id: StringName = &""

func _ready() -> void:
	_load_all()

func register(g: Glyph) -> void:
	glyphs[g.id] = g
	if not glyph_order.has(g.id):
		glyph_order.append(g.id)


# --- Active glyph ---------------------------------------------------

## Selects `id`. An unknown id is ignored rather than clearing the selection, so
## a typo in an inspector field cannot silently blank the display.
func set_active_glyph(id: StringName) -> void:
	if not glyphs.has(id) or active_glyph_id == id:
		return
	active_glyph_id = id
	active_glyph_changed.emit(glyphs[id])


func get_active_glyph() -> Glyph:
	return glyphs.get(active_glyph_id)


## Clears the selection — used when the console is closed and nothing should
## read as "in hand" any more.
func clear_active_glyph() -> void:
	if active_glyph_id == &"":
		return
	active_glyph_id = &""
	active_glyph_changed.emit(null)


## The id `step` places along the cycle from `id`, wrapping at both ends.
## An unknown `id` starts from the top of the list, so the first arrow press
## always lands somewhere valid.
func get_glyph_id_offset_from(id: StringName, step: int) -> StringName:
	if glyph_order.is_empty():
		return &""
	var index := glyph_order.find(id)
	if index == -1:
		index = 0
	return glyph_order[wrapi(index + step, 0, glyph_order.size())]


func get_ordered_ids() -> Array[StringName]:
	return glyph_order.duplicate()


# --- Decoding (glyph <-> "Bild" item) -------------------------------

## The glyph that `item_id` decodes, or null when that item is not paired with
## any glyph. Doubles as the "is this even a decoding picture?" test, so no code
## has to know that the items happen to be named bild_*.
func get_glyph_for_item(item_id: StringName) -> Glyph:
	if item_id == &"":
		return null
	for id in glyph_order:
		var glyph: Glyph = glyphs[id]
		if glyph.paired_item_id == item_id:
			return glyph
	return null


## True when `item_id` belongs to some glyph — i.e. using it on the decoder is
## meant to produce a right/wrong answer rather than being ignored.
func is_decoding_item(item_id: StringName) -> bool:
	return get_glyph_for_item(item_id) != null


## Whether `item_id` is the picture that goes with the glyph on screen right
## now. False when nothing is selected, so a decode attempt without an active
## glyph never reads as correct.
func item_matches_active_glyph(item_id: StringName) -> bool:
	var glyph := get_active_glyph()
	return glyph != null and glyph.paired_item_id != &"" \
		and glyph.paired_item_id == item_id

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
	_sort_glyph_order()


# Filenames decide load order, which makes the cycle depend on what the .tres
# files happen to be called. sort_order puts that back under the designer's
# control.
func _sort_glyph_order() -> void:
	glyph_order.sort_custom(func(a: StringName, b: StringName) -> bool:
		var ga: Glyph = glyphs[a]
		var gb: Glyph = glyphs[b]
		if ga.sort_order != gb.sort_order:
			return ga.sort_order < gb.sort_order
		return String(a) < String(b))
