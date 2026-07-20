extends Control

## Glyph gallery.
##
## Renders every glyph that actually exists, then pads the grid out to
## `total_slot_count` with locked "???" slots, so the collection reads as bigger
## than the content shipped so far. Adding a real glyph .tres eats one padding
## slot instead of growing the grid.

const GlyphSlotScene := preload("res://Scenes/Placeholders/test_glyph_scene.tscn")

## The "Schließen" button was pressed. Whoever opened the gallery (the Player,
## through its GlyphLayer) owns the actual hiding — the same split the inventory
## uses with its own close_requested.
signal close_requested

## Slots shown in total, real plus locked. A value at or below the number of
## real glyphs simply adds no padding.
@export var total_slot_count: int = 20

@onready var grid: GridContainer = %GlyphGrid


func _ready() -> void:
	# Every glyph the Lexicon loaded from res://Ressources/Glyphs/
	build(Lexicon.glyphs.keys())


func build(ids: Array) -> void:
	for child in grid.get_children():
		child.queue_free()
	for id in ids:
		_add_slot(id)
	# Padding trails the real glyphs, so the grid reads as "discovered so far,
	# then everything still ahead".
	for _i in maxi(total_slot_count - ids.size(), 0):
		_add_slot(&"", true)


func _add_slot(id: StringName, locked: bool = false) -> void:
	var slot: PanelContainer = GlyphSlotScene.instantiate()
	var view: GlyphView = slot.get_node("%GlyphView")
	# Set before add_child so the view is configured by the time _ready runs.
	view.glyph_id = id
	view.locked = locked
	grid.add_child(slot)


func _on_close_button_pressed() -> void:
	close_requested.emit()
