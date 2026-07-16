extends CharacterBody2D

## A reusable, clickable NPC that plays a Dialogue Manager dialogue.
##
## How to use / reuse:
##   1. Drop this NPC scene into any level.
##   2. In the Inspector, assign a ".dialogue" file to "Dialogue Resource".
##   3. (Optional) Change "Dialogue Title" if the file starts at a node other than "start".
## Each instance can point at a different dialogue file, so the same scene is reused everywhere.
##
## The clicking itself belongs to the child Interactable: the player walks into
## range first, and only then is _on_interactable_interacted called.

## The dialogue file this NPC speaks when clicked. Assign a .dialogue resource in the Inspector.
@export var dialogue_resource: DialogueResource

## The title (starting node) inside the dialogue file. Most files begin at "start".
@export var dialogue_title: String = "start"


## Called by the child Interactable once the player has walked up to this NPC.
func _on_interactable_interacted(_player: Node2D) -> void:
	if dialogue_resource == null:
		push_warning("NPC '%s' was clicked but has no Dialogue Resource assigned." % name)
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title)
