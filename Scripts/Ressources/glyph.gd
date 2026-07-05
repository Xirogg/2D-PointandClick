class_name Glyph
extends Resource

@export var id: StringName
@export var texture: Texture2D
@export var acceptable_words: Array[String] = []   # ["person", "human", "man"]
@export var category: String = ""                  # noun / verb / etc.
