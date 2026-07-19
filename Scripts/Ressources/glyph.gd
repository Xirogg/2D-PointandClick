class_name Glyph
extends Resource

@export var id: StringName
@export var texture: Texture2D
@export var acceptable_words: Array[String] = []   # ["person", "human", "man"]
@export var category: String = ""                  # noun / verb / etc.
## Position in the console's cycle order. Ties fall back to the id, so glyphs
## that share a value still cycle in a stable (if arbitrary) order.
@export var sort_order: int = 0
