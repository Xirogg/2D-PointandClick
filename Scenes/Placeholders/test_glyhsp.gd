extends Control

const GlyphSlotScene := preload("res://Scenes/Placeholders/test_glyph_scene.tscn")

@onready var grid: GridContainer = %GlyphGrid


func _ready() -> void:
	# Render every glyph the Lexicon loaded from res://Ressources/Glyphs/
	build(Lexicon.glyphs.keys())


func build(ids: Array) -> void:
	for child in grid.get_children():
		child.queue_free()
	for id in ids:
		var slot: PanelContainer = GlyphSlotScene.instantiate()
		var view: GlyphView = slot.get_node("%GlyphView")
		# Set before add_child so the view has its id by the time _ready runs.
		view.glyph_id = id
		grid.add_child(slot)
