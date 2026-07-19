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
##
## The clicking itself belongs to the child Interactable: the player walks into
## range first, and only then is _on_interactable_interacted called.

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
	var stage := _stage_to_play()
	if stage < 0:
		push_warning("NPC '%s' was clicked but has no Dialogue Resource assigned." % name)
		return
	DialogueManager.show_dialogue_balloon(_resource_for_stage(stage), _title_for_stage(stage))


# Walks back from the current story stage until it finds a slot that actually
# has a file in it. Returns -1 when every slot is empty.
func _stage_to_play() -> int:
	var stage := int(Global.get_story_stage())
	while stage >= 0:
		if _resource_for_stage(stage) != null:
			return stage
		stage -= 1
	return -1


func _resource_for_stage(stage: int) -> DialogueResource:
	if stage == Global.StoryStage.GLYPHS_TRANSLATED:
		return dialogue_after_glyphs
	if stage == Global.StoryStage.AFTER_SHIP:
		return dialogue_after_ship
	return dialogue_first_visit


# An empty title field means "start" rather than a broken jump into the file.
func _title_for_stage(stage: int) -> String:
	var title := title_first_visit
	if stage == Global.StoryStage.GLYPHS_TRANSLATED:
		title = title_after_glyphs
	elif stage == Global.StoryStage.AFTER_SHIP:
		title = title_after_ship
	return title if not title.strip_edges().is_empty() else "start"
