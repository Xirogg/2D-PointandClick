extends Node

var PlayerNode: Node = null ### Player Node 

var inventory: Array = []
var inventory_size: int = 10

# --- World item pickup persistence ---------------------------------
# Remembers which editor-placed world items have already been collected,
# so they do NOT respawn when a level scene is reloaded. Because this is an
# autoload it survives scene changes for the whole game session.
#   item_id (StringName) -> true
var picked_up_items: Dictionary = {}

signal updateinventory
signal clickedinteractibles

# --- Escalation tracker --------------------------------------------
# Goes up by 1 every time the player tries to combine two items that
# cannot be combined. Kept as an int in the range 0..ESCALATION_MAX so
# the Player HUD progress bar (0 = good, 10 = bad) can bind to it directly.
const ESCALATION_MAX: int = 10
var escalation: int = 0
signal escalation_changed(new_value: int)

@onready var Inventory_Slot_Scene = preload("res://Scenes/GUI/Inventory/inventory_slot.tscn")

var LastSelectedItem = null 


var SelectedLanguage: String
###########################

# --- Story stage ----------------------------------------------------
# How far the story has come. NPCs pick which of their dialogue files to
# play from this, so the same NPC in the same scene says something new on
# a later visit. Kept deliberately small: the vertical slice only needs
# three steps.
enum StoryStage {
	FIRST_VISIT = 0,        ## Nothing happened yet.
	AFTER_SHIP = 1,         ## The player has been inside the ship at least once.
	GLYPHS_TRANSLATED = 2,  ## Every glyph in the game carries its correct name.
}

## Fired when the story moves forward, for anything that has to react on the
## spot (swapping an NPC sprite, unlocking a door). Dialogue does NOT need
## this — NPCs read get_story_stage() fresh every time they are clicked.
signal story_stage_changed(new_stage: StoryStage)

## Set once the ship scene has been entered. Ship_scene does this itself.
var has_visited_ship: bool = false

var _broadcast_stage: StoryStage = StoryStage.FIRST_VISIT


## The stage the game is in right now, highest reached condition wins.
func get_story_stage() -> StoryStage:
	if Lexicon.is_everything_translated():
		return StoryStage.GLYPHS_TRANSLATED
	if has_visited_ship:
		return StoryStage.AFTER_SHIP
	return StoryStage.FIRST_VISIT


## Called by the ship scene when the player arrives there.
func mark_ship_visited() -> void:
	if has_visited_ship:
		return
	has_visited_ship = true
	_check_story_stage()


## Call this when starting a new game, next to reset_picked_up_items().
func reset_story_state() -> void:
	has_visited_ship = false
	_broadcast_stage = StoryStage.FIRST_VISIT
	story_stage_changed.emit(_broadcast_stage)


# Only announces an actual change, so listeners cannot fire twice for the
# same stage.
func _check_story_stage() -> void:
	var stage := get_story_stage()
	if stage == _broadcast_stage:
		return
	_broadcast_stage = stage
	print("Story stage: ", StoryStage.keys()[stage])
	story_stage_changed.emit(stage)


func _on_all_glyphs_translated() -> void:
	_check_story_stage()


func _ready() -> void:


	inventory.resize(inventory_size)

	# Lexicon autoloads *after* this script, so it does not exist yet inside
	# _ready. Deferring puts the connect on the next idle frame, by which
	# point every autoload is in the tree.
	_connect_lexicon.call_deferred()


func _connect_lexicon() -> void:
	Lexicon.all_glyphs_translated.connect(_on_all_glyphs_translated)



func _process(delta: float) -> void:
	checklanguage()
	

	
func checklanguage(): 
	var local = TranslationServer.get_locale()
	SelectedLanguage = local.to_lower()
	
func additem(item):
	
	for i in range(inventory.size()):
		
		if inventory[i] != null and inventory[i]["name_de"] == item["name_de"]:
			#inventory[i]["quantity"] += item["quantity"] 
			emit_signal("updateinventory")
			return true 
			
		elif inventory[i] == null: 
			inventory[i] = item
			emit_signal("updateinventory")
			return true
			
		#else: 
			#inventory[i] = item
			#print("ELSE ", inventory)
	return false
		

# --- World item pickup persistence ---------------------------------

func is_item_picked_up(item_id: StringName) -> bool:
	return picked_up_items.get(item_id, false)


func mark_item_picked_up(item_id: StringName) -> void:
	picked_up_items[item_id] = true


# Central pickup entry point for editor-placed world items (item.gd).
# Handles the inventory logic AND remembers the item as collected.
# Returns true when the item was actually taken, so the caller can free the
# world node. Returns false (e.g. inventory full) so the item stays in the
# world and can be picked up later.
func pickup_world_item(item: Dictionary, item_id: StringName) -> bool:
	if additem(item):
		mark_item_picked_up(item_id)
		return true
	return false


# Call this when starting a new game so previously collected items reappear.
func reset_picked_up_items() -> void:
	picked_up_items.clear()


func removeitem(item):


	for i in range(inventory.size()):
		
		if inventory[i] != null and inventory[i]["name_de"] == item:
			print("Remove Item ", item )
			inventory[i] = null
			updateinventory.emit()
			return true
			
	return false
		

func player_reference(player): 
	PlayerNode = player
	
	
func swap_inventory(index_1, index_2):
	
	if index_1 < 0 or index_1 > inventory.size() or index_2 < 0 or index_2 > inventory.size():
		return false
		
	var temp = inventory[index_1]
	inventory[index_1] = inventory[index_2]
	inventory[index_2] = temp
	updateinventory.emit()
	return true

#Update last Selected Item
func change_selecteditem(selected_item):

	LastSelectedItem = selected_item
	print("Selected Item ", LastSelectedItem)


# --- Escalation tracker --------------------------------------------

# Raise escalation after a failed item combination. Clamped to
# 0..ESCALATION_MAX and broadcast so the HUD can update its progress bar.
func increase_escalation(amount: int = 1) -> void:
	escalation = clampi(escalation + amount, 0, ESCALATION_MAX)
	print("Escalation: ", escalation, "/", ESCALATION_MAX)
	escalation_changed.emit(escalation)


# Reset the tracker (e.g. when starting a new game).
func reset_escalation() -> void:
	escalation = 0
	escalation_changed.emit(escalation)





	
