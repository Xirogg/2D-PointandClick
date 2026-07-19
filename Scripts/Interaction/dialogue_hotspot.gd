class_name DialogueHotspot
extends Interactable

## A clickable piece of scenery that talks: a tent, a crate, a notice board.
##
## Same idea as prototype_npc.gd, but for things that are not characters and so
## do not need a CharacterBody2D of their own. Put this script straight on the
## Area2D that already covers the object and it is both the hotspot and the
## thing that reacts to being clicked.
##
## There is one dialogue slot per stage of Global.StoryStage:
##   1. First Visit       - before the player has been to the ship
##   2. After Ship        - once the ship scene has been entered once
##   3. Glyphs Translated - once every glyph in the game is named correctly
##
## Fill the later slots only where this hotspot actually has something new to
## say - an empty slot falls back to the newest *earlier* filled slot (see
## StoryDialogue).
##
## How to use / reuse:
##   1. Put this script on an Area2D with a CollisionShape2D over the object.
##   2. Assign a ".dialogue" file to "Dialogue First Visit".
##   3. Connect "dialogue_finished" in the level script to hand out items or
##      move the story on. It carries the stage that just played, so one handler
##      can cover all three.

## Fired after the balloon has closed, carrying the Global.StoryStage whose
## dialogue just played. This is what levels hang their rewards off.
signal dialogue_finished(stage: int)

@export_group("Stage 1 - First Visit")
@export var dialogue_first_visit: DialogueResource
@export var title_first_visit: String = "start"

@export_group("Stage 2 - After Ship")
@export var dialogue_after_ship: DialogueResource
@export var title_after_ship: String = "start"

@export_group("Stage 3 - Glyphs Translated")
@export var dialogue_after_glyphs: DialogueResource
@export var title_after_glyphs: String = "start"


func _ready() -> void:
	# Interactable._ready() is what forces this onto the physics layer the
	# player's click query looks at, so it must not be skipped.
	super._ready()
	interacted.connect(_on_interacted)


# Called by Interactable.interact() once the player has walked up to this.
func _on_interacted(_player: Node2D) -> void:
	var slots: Array[DialogueResource] = [dialogue_first_visit, dialogue_after_ship, dialogue_after_glyphs]
	var titles: Array[String] = [title_first_visit, title_after_ship, title_after_glyphs]

	var stage := StoryDialogue.play(slots, titles, name)
	if stage < 0:
		return

	await DialogueManager.dialogue_ended
	dialogue_finished.emit(stage)
