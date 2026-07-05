extends Node

signal glyph_discovered(glyph: Glyph)
signal guess_changed(id: StringName, word: String)
signal glyph_confirmed(id: StringName)

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

func get_guess(id: StringName) -> String:
	return guesses.get(id, "")
	
func _load_all() -> void:
	var dir := "res://Ressources/Glyphs/"
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			var g := load(dir + file) as Glyph
			if g != null:
				register(g)
