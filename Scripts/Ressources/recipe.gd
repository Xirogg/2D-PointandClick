class_name Recipe
extends Resource

## One craftable combination, authored as a .tres in res://Ressources/Recipes/.
##
## How to add a new recipe:
##   1. Right-click res://Ressources/Recipes/ -> New Resource -> Recipe.
##   2. Drag the ItemData resources the player has to combine into "inputs".
##   3. Drag the ItemData that comes out into "result".
##   4. Save it in res://Ressources/Recipes/. ItemLogic indexes it on its own.
##
## Order does not matter: rope + hook and hook + rope both find this recipe.
## ItemLogic builds a lookup key from the sorted input ids, so finding a recipe
## is a single dictionary hit no matter how many recipes exist.

## The items that have to be combined. Two is the normal case; more works, but
## the inventory UI can currently only ever offer two at a time.
@export var inputs: Array[ItemData] = []

## What the player gets. Leave empty for a combination that is "valid" but
## produces nothing (rare - usually you want an item here).
@export var result: ItemData

## Unticked = the inputs survive the craft. Handy for a tool that is used on
## something rather than consumed by it.
@export var consume_inputs: bool = true


## The order-independent key ItemLogic files this recipe under.
func key() -> String:
	var ids: Array[String] = []
	for item in inputs:
		if item != null:
			ids.append(String(item.id))
	ids.sort()
	return "+".join(ids)


## False for a half-filled resource, so a typo in the editor is reported at
## load time instead of failing silently the first time a player tries it.
func is_valid() -> bool:
	if inputs.size() < 2:
		return false
	for item in inputs:
		if item == null or item.id == &"":
			return false
	return true
