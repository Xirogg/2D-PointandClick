class_name Glyph
extends Resource

@export var id: StringName
@export var texture: Texture2D
@export var acceptable_words: Array[String] = []   # ["person", "human", "man"]
@export var category: String = ""                  # noun / verb / etc.
## Position in the console's cycle order. Ties fall back to the id, so glyphs
## that share a value still cycle in a stable (if arbitrary) order.
@export var sort_order: int = 0

## The "Bild" item that decodes this glyph, matched by ItemData.id. Holding the
## pairing here rather than on the item keeps ItemData generic — most items have
## nothing to do with glyphs — and makes the whole puzzle one field per .tres.
## Leave empty for a glyph that no picture unlocks.
@export var paired_item_id: StringName = &""
