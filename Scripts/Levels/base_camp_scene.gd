extends Node2D

## Base camp: what actually *happens* after each of the four hotspots has
## finished talking.
##
## The hotspots themselves (two tents, two NPCs) only know how to pick the right
## dialogue for the current story stage and to announce when the balloon closed.
## Everything story-specific - which item comes out of which tent, when the ship
## opens up, when the game ends - is collected here, so the reward table can be
## read top to bottom in one place instead of being spread over four scripts.
##
## Rewards are guarded by Global.claim_flag(). The player walks in and out of
## this camp repeatedly and the level is rebuilt from scratch every time, so
## without that guard the small tent would hand out a fresh Schutzanzug on every
## single visit.

const SHIP_SCENE := "res://Scenes/Levels/ship_scene.tscn"
const ENDING_SCENE := "res://Scenes/Levels/ending_scene.tscn"

## The item NPC 2 wants to see before he lets the player near the ship. Handing
## it over is what consumes it.
const SHIP_TICKET := &"schutzausruestung"

@onready var _big_tent: DialogueHotspot = $"Big Tent"
@onready var _small_tent: DialogueHotspot = $"Small Tent"
@onready var _npc_1: Node2D = $"NPC 1"
@onready var _npc_2: Node2D = $"NPC 2"


func _ready() -> void:
	_big_tent.dialogue_finished.connect(_on_big_tent_dialogue_finished)
	_small_tent.dialogue_finished.connect(_on_small_tent_dialogue_finished)
	_npc_1.dialogue_finished.connect(_on_npc_1_dialogue_finished)
	_npc_2.dialogue_finished.connect(_on_npc_2_dialogue_finished)


# --- Big tent -------------------------------------------------------
# Stage 1: the gas mask. Stage 2: the two pictures.

func _on_big_tent_dialogue_finished(stage: int) -> void:
	match stage:
		Global.StoryStage.FIRST_VISIT:
			if Global.claim_flag(&"big_tent_gasmaske"):
				ItemLogic.give("gasmaske")
		Global.StoryStage.AFTER_SHIP:
			if Global.claim_flag(&"big_tent_bilder"):
				ItemLogic.give("bild_1")
				ItemLogic.give("bild_2")


# --- Small tent -----------------------------------------------------
# Stage 1: the hazmat suit. Nothing after that.

func _on_small_tent_dialogue_finished(stage: int) -> void:
	if stage == Global.StoryStage.FIRST_VISIT:
		if Global.claim_flag(&"small_tent_schutzanzug"):
			ItemLogic.give("schutzanzug")


# --- NPC 1 ----------------------------------------------------------
# Stage 2: the third picture. Stage 3: the end of the game.

func _on_npc_1_dialogue_finished(stage: int) -> void:
	match stage:
		Global.StoryStage.AFTER_SHIP:
			if Global.claim_flag(&"npc_1_bild_3"):
				ItemLogic.give("bild_3")
		Global.StoryStage.GLYPHS_TRANSLATED:
			# Reaching stage 3 at all already means every glyph is named
			# correctly. Asking Lexicon directly anyway keeps the ending honest
			# if the stage rule is ever loosened.
			if Lexicon.is_everything_translated():
				get_tree().change_scene_to_file(ENDING_SCENE)


# --- NPC 2 ----------------------------------------------------------
# The ride to the ship. The first ride costs the hazmat gear; once the player
# has been there, he ferries them across for free.

func _on_npc_2_dialogue_finished(stage: int) -> void:
	if stage == Global.StoryStage.FIRST_VISIT:
		# No gear, no ride - the dialogue has already said so, so just stay put.
		if not ItemLogic.has(SHIP_TICKET):
			return
		ItemLogic.take(SHIP_TICKET)

	get_tree().change_scene_to_file(SHIP_SCENE)
