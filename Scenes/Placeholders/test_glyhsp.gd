extends HBoxContainer

const GlyphViewScene := preload("res://Scenes/Placeholders/test_glyph_scene.tscn")


func _ready() -> void:
	# Render every glyph the Lexicon loaded from res://Ressources/Glyphs/
	build(Lexicon.glyphs.keys())


func build(ids: Array) -> void:
	for child in get_children():
		child.queue_free()
	for id in ids:
		var view: GlyphView = GlyphViewScene.instantiate()
		view.glyph_id = id
		add_child(view)
