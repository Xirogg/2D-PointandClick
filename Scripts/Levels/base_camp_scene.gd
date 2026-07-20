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

## Where the player walks in. Coming back from the ship drops him off at the far
## side of the camp, where the boat lands; every other way in (the intro, or
## running this level straight from the editor) starts him at the entrance.
const SPAWN_X_DEFAULT := 55.0
const SPAWN_X_FROM_SHIP := 900.0

## The item NPC 2 wants to see before he lets the player near the ship. Which
## item that is lives on the NPC itself ("Expected Item"); this id is only what
## gets consumed on hand-over.
const SHIP_TICKET := &"schutzausruestung"

@onready var _big_tent: DialogueHotspot = $"Big Tent"
@onready var _small_tent: DialogueHotspot = $"Small Tent"
@onready var _npc_1: Node2D = $"NPC 1"
@onready var _npc_2: Node2D = $"NPC 2"
@onready var _player: Player = $Player


func _ready() -> void:
	AudioManager.set_footsteps_stream(AudioManager.WALK_BASE_CAMP)
	_place_player()
	_big_tent.dialogue_finished.connect(_on_big_tent_dialogue_finished)
	_small_tent.dialogue_finished.connect(_on_small_tent_dialogue_finished)
	_npc_1.dialogue_finished.connect(_on_npc_1_dialogue_finished)
	_npc_2.dialogue_finished.connect(_on_npc_2_dialogue_finished)
	_npc_2.item_accepted.connect(_on_npc_2_item_accepted)


# Runs after the Player's own _ready (children go first), so click_target has
# already been set from the .tscn and place_at_x has to reset it.
func _place_player() -> void:
	var arrived_from := Global.take_came_from()
	_player.place_at_x(SPAWN_X_FROM_SHIP if arrived_from == SHIP_SCENE else SPAWN_X_DEFAULT)


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
# The ride to the ship. The first ride is paid for by handing the hazmat gear
# over in person; once the player has been there, he ferries them across free.

## Plain conversation. Before the first ride this never travels: merely owning
## the gear is not the price, using it on the guard is (see _on_npc_2_item_accepted),
## so talking at stage 1 only ever gets the player his answer.
func _on_npc_2_dialogue_finished(stage: int) -> void:
	if stage == Global.StoryStage.FIRST_VISIT:
		return
	get_tree().change_scene_to_file(SHIP_SCENE)


## The gear was actively used on the guard. Spending it is what buys the ride,
## so the scene change hangs off the take() succeeding.
func _on_npc_2_item_accepted(_item: ItemData) -> void:
	if not ItemLogic.take(SHIP_TICKET):
		return
	get_tree().change_scene_to_file(SHIP_SCENE)
