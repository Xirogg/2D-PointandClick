extends CharacterBody2D

## A reusable, clickable NPC that plays a Dialogue Manager dialogue.
##
## The NPC says something different depending on how far the story has come,
## so the same NPC standing in the same camp can be revisited. There is one
## slot per stage of Global.StoryStage:
##   1. First Visit       - before the player has been to the ship
##   2. After Ship        - once the ship scene has been entered once
##   3. Glyphs Translated - once every glyph in the game is named correctly
##
## How to use / reuse:
##   1. Drop this NPC scene into any level.
##   2. Assign a ".dialogue" file to "Dialogue First Visit".
##   3. Fill the later slots only where this NPC actually has something new to
##      say. An empty slot falls back to the newest *earlier* slot that is
##      filled, so an NPC with a single dialogue keeps working unchanged and a
##      quiet NPC repeats its old lines instead of going silent.
##   4. Each slot has its own title, defaulting to "start". Point all three
##      slots at the same file and give them different titles if you would
##      rather keep one dialogue file per NPC.
##   5. Connect "dialogue_finished" in the level script to hand out items or
##      move the story on.
##
## The clicking itself belongs to the child Interactable: the player walks into
## range first, and only then is _on_interactable_interacted called.
##
## Scenery that talks but is not a character uses dialogue_hotspot.gd instead;
## both share the slot-picking rule in StoryDialogue.

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


## Called by the child Interactable once the player has walked up to this NPC.
func _on_interactable_interacted(_player: Node2D) -> void:
	var slots: Array[DialogueResource] = [dialogue_first_visit, dialogue_after_ship, dialogue_after_glyphs]
	var titles: Array[String] = [title_first_visit, title_after_ship, title_after_glyphs]

	var stage := StoryDialogue.play(slots, titles, name)
	if stage < 0:
		return

	await DialogueManager.dialogue_ended
	dialogue_finished.emit(stage)
