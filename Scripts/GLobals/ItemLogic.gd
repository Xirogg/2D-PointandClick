extends Node

## The item and crafting database, plus the one API everything else goes
## through to hand the player something.
##
## Items and recipes are .tres Resources loaded from disk on startup - the same
## approach Lexicon uses for glyphs. Nothing about an item or a recipe lives in
## code, so adding either is an editor job, not a scripting job.
##
## Giving the player an item from anywhere:
##     ItemLogic.give("rope")
##
## From a Dialogue Manager .dialogue file, as a mutation on its own line:
##     do ItemLogic.give("rope")
## which is how an item gets spawned once a conversation reaches a given point.
## Dialogue Manager resolves autoload names directly, so no glue is needed.
##
## Dropping one into the level instead of the inventory:
##     ItemLogic.spawn_in_world("rope", self, Vector2(320, 180))

const ITEM_DIR := "res://Ressources/Items/"
const RECIPE_DIR := "res://Ressources/Recipes/"
const DEFAULT_WORLD_SCENE := "res://Scenes/GUI/Inventory/item.tscn"

## An item actually entered the inventory. Carries the item so a HUD can show
## a "picked up: rope" toast without polling.
signal item_granted(item: ItemData)
## The inventory was full, so the give() did not happen.
signal give_failed(item: ItemData)
signal craft_succeeded(recipe: Recipe)
## Two items were combined that have no recipe. Global listens to this and
## raises the escalation tracker.
signal craft_failed(first: ItemData, second: ItemData)

## id (StringName) -> ItemData
var items: Dictionary = {}
## Recipe.key() (String) -> Recipe
var recipes: Dictionary = {}


func _ready() -> void:
	_load_items()
	_load_recipes()


# --- Lookup ---------------------------------------------------------

## The ItemData for an id, or null when nothing is registered under it.
## Accepts a plain String too, so dialogue can call give("rope").
func get_item(id) -> ItemData:
	return items.get(StringName(id))


## Every registered item. Handy for debug menus.
func all_items() -> Array:
	return items.values()


# --- Giving and taking ----------------------------------------------

## Put `count` of `id` into the inventory. Returns false when the id is unknown
## or the inventory is full, in which case nothing was added at all.
func give(id, count: int = 1) -> bool:
	var item := get_item(id)
	if item == null:
		push_warning("ItemLogic.give('%s'): no such item. Check res://Ressources/Items/." % id)
		return false

	if not Global.add_item(item, count):
		give_failed.emit(item)
		return false

	item_granted.emit(item)
	return true


## Remove `count` of `id`. Returns false when the player did not have that many,
## in which case nothing is removed.
func take(id, count: int = 1) -> bool:
	return Global.remove_item(StringName(id), count)


## Whether the player is carrying at least `count` of `id`.
## Meant for dialogue conditions: `if ItemLogic.has("rope")`
func has(id, count: int = 1) -> bool:
	return Global.count_item(StringName(id)) >= count


## How many of `id` the player is carrying.
func count(id) -> int:
	return Global.count_item(StringName(id))


# --- Crafting -------------------------------------------------------

## The recipe for combining these ids, or null when there is none.
## Order-independent.
func find_recipe(first_id: StringName, second_id: StringName) -> Recipe:
	var ids: Array[String] = [String(first_id), String(second_id)]
	ids.sort()
	return recipes.get("+".join(ids))


## Try to combine two carried items.
##
## On success the inputs are consumed (unless the recipe says otherwise), the
## result is added, and craft_succeeded fires. On failure nothing changes and
## craft_failed fires, which is what drives the escalation bar.
##
## Returns the crafted ItemData, or null when the combination is not a recipe.
func craft(first_id: StringName, second_id: StringName) -> ItemData:
	var recipe := find_recipe(first_id, second_id)
	if recipe == null:
		craft_failed.emit(get_item(first_id), get_item(second_id))
		return null

	# Check before removing anything, so a failed craft can never eat an item.
	if recipe.consume_inputs:
		for input in recipe.inputs:
			if Global.count_item(input.id) < 1:
				craft_failed.emit(get_item(first_id), get_item(second_id))
				return null
		for input in recipe.inputs:
			Global.remove_item(input.id, 1)

	if recipe.result != null:
		Global.add_item(recipe.result, 1)
		item_granted.emit(recipe.result)

	craft_succeeded.emit(recipe)
	return recipe.result


# --- World spawning -------------------------------------------------

## Drop an item into the level as a pickup the player has to walk over to,
## rather than straight into the inventory. `parent` is usually the level node.
## Returns the spawned node, or null when the id is unknown.
func spawn_in_world(id, parent: Node, position: Vector2) -> Node2D:
	var item := get_item(id)
	if item == null:
		push_warning("ItemLogic.spawn_in_world('%s'): no such item." % id)
		return null

	var scene: PackedScene = item.world_scene
	if scene == null:
		scene = load(DEFAULT_WORLD_SCENE)

	var node := scene.instantiate() as Node2D
	node.item = item
	# Runtime spawns have no owner to derive a pickup key from, so give them one
	# that is stable for this spawn point (see item.gd::_resolve_item_id).
	node.item_id = StringName("spawned::%s@%d,%d" % [item.id, roundi(position.x), roundi(position.y)])
	node.position = position
	parent.add_child(node)
	return node


# --- Loading --------------------------------------------------------

func _load_items() -> void:
	for resource in _load_dir(ITEM_DIR):
		var item := resource as ItemData
		if item == null:
			continue
		if item.id == &"":
			push_warning("ItemData '%s' has an empty id and was skipped." % item.resource_path)
			continue
		if items.has(item.id):
			push_warning("Duplicate item id '%s' in %s." % [item.id, item.resource_path])
			continue
		items[item.id] = item


func _load_recipes() -> void:
	for resource in _load_dir(RECIPE_DIR):
		var recipe := resource as Recipe
		if recipe == null:
			continue
		if not recipe.is_valid():
			push_warning("Recipe '%s' needs at least two filled-in inputs; skipped." % recipe.resource_path)
			continue
		recipes[recipe.key()] = recipe


# Loads every .tres in a folder. A missing folder is fine - it just means that
# half of the game has no content authored yet.
func _load_dir(path: String) -> Array:
	var loaded: Array = []
	if not DirAccess.dir_exists_absolute(path):
		return loaded
	for file in DirAccess.get_files_at(path):
		# In an exported build the .tres may have been converted to binary and
		# is listed as "<name>.tres.remap". Loading the original path still
		# works, so just strip the suffix.
		if file.ends_with(".remap"):
			file = file.trim_suffix(".remap")
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var resource := load(path + file)
		if resource != null:
			loaded.append(resource)
	return loaded
