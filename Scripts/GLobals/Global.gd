extends Node

var PlayerNode: Node = null ### Player Node

## One entry per slot: an ItemStack, or null for an empty slot. Always exactly
## inventory_size long, so a slot index is also a UI index.
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

## The item the player armed with "BENUTZEN", or null. Puzzle hotspots
## (activity_module.gd) compare against this. Holding the ItemData rather than a
## German display string means renaming or translating an item can no longer
## silently break a puzzle.
var selected_item: ItemData = null
signal selected_item_changed(item: ItemData)

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

# --- One-shot story flags -------------------------------------------
# "This already happened" markers, e.g. "the big tent handed out its gas mask".
# Levels are rebuilt from scratch every time the player walks back into them,
# so a level node cannot remember this on its own - it has to live out here in
# the autoload, next to has_visited_ship.
#   flag (StringName) -> true
var story_flags: Dictionary = {}


## Whether this one-shot has already fired.
func has_flag(flag: StringName) -> bool:
	return story_flags.get(flag, false)


## Mark a one-shot as fired. Returns false when it had already fired, so a
## reward can be written as a single guard:
##     if Global.claim_flag(&"big_tent_gasmaske"):
##         ItemLogic.give("gasmaske")
func claim_flag(flag: StringName) -> bool:
	if story_flags.get(flag, false):
		return false
	story_flags[flag] = true
	return true


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
	story_flags.clear()
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

	# Lexicon and ItemLogic autoload *after* this script, so they do not exist
	# yet inside _ready. Deferring puts the connects on the next idle frame, by
	# which point every autoload is in the tree.
	_connect_autoloads.call_deferred()


func _connect_autoloads() -> void:
	Lexicon.all_glyphs_translated.connect(_on_all_glyphs_translated)
	# A combination the player got wrong is what drives the escalation bar.
	ItemLogic.craft_failed.connect(_on_craft_failed)


func _on_craft_failed(_first: ItemData, _second: ItemData) -> void:
	increase_escalation()


# --- Inventory ------------------------------------------------------
# These are the storage mechanics, working on ItemData and ids. Gameplay code
# should go through ItemLogic (give / take / has / craft) rather than calling
# these directly.

## Put `count` of `item` into the inventory. Stacks onto an existing slot when
## the item allows it, otherwise takes one fresh slot per copy. Returns false
## when there is not enough room, and in that case nothing is added at all.
func add_item(item: ItemData, count: int = 1) -> bool:
	if item == null or count <= 0:
		return false

	if item.stackable:
		for stack in inventory:
			if stack != null and stack.id() == item.id:
				stack.quantity += count
				updateinventory.emit()
				return true

	# One slot per copy, so check that they all fit before placing any of them.
	# Adding only some and still reporting failure would make the world pickup
	# free itself while the inventory kept just part of it.
	var free_slots := 0
	for stack in inventory:
		if stack == null:
			free_slots += 1
	if free_slots < count:
		return false

	var placed := 0
	for i in range(inventory.size()):
		if placed == count:
			break
		if inventory[i] == null:
			inventory[i] = ItemStack.new(item, 1)
			placed += 1

	updateinventory.emit()
	return true


## Remove `count` of the item with this id. Returns false when the player is
## not carrying that many, in which case nothing is removed.
func remove_item(id: StringName, count: int = 1) -> bool:
	if count <= 0 or count_item(id) < count:
		return false

	var left := count
	for i in range(inventory.size()):
		if left == 0:
			break
		var stack = inventory[i]
		if stack == null or stack.id() != id:
			continue

		var taken: int = mini(stack.quantity, left)
		stack.quantity -= taken
		left -= taken
		if stack.quantity <= 0:
			inventory[i] = null

	# The armed item may have just been consumed by a craft.
	if selected_item != null and selected_item.id == id and count_item(id) == 0:
		select_item(null)

	updateinventory.emit()
	return true


## How many of this id the player is carrying, across all slots.
func count_item(id: StringName) -> int:
	var total := 0
	for stack in inventory:
		if stack != null and stack.id() == id:
			total += stack.quantity
	return total


## The slot index holding this id, or -1 when the player is not carrying it.
func find_slot(id: StringName) -> int:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i].id() == id:
			return i
	return -1


## Empty every slot. Call when starting a new game.
func clear_inventory() -> void:
	inventory.clear()
	inventory.resize(inventory_size)
	select_item(null)
	updateinventory.emit()


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
func pickup_world_item(item: ItemData, item_id: StringName) -> bool:
	if add_item(item):
		mark_item_picked_up(item_id)
		return true
	return false


# Call this when starting a new game so previously collected items reappear.
func reset_picked_up_items() -> void:
	picked_up_items.clear()


func player_reference(player):
	PlayerNode = player


func swap_inventory(index_1: int, index_2: int) -> bool:
	# The old bound check compared with ">" against size(), which let size()
	# itself through and indexed one past the end of the array.
	if index_1 < 0 or index_1 >= inventory.size():
		return false
	if index_2 < 0 or index_2 >= inventory.size():
		return false

	var temp = inventory[index_1]
	inventory[index_1] = inventory[index_2]
	inventory[index_2] = temp
	updateinventory.emit()
	return true


## Arm an item for use on a puzzle hotspot, or pass null to disarm.
func select_item(item: ItemData) -> void:
	selected_item = item
	selected_item_changed.emit(item)


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
