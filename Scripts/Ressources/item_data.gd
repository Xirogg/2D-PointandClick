class_name ItemData
extends Resource

## One kind of item in the game, authored as a .tres in res://Ressources/Items/.
##
## This is the single source of truth for an item. A world pickup, an inventory
## slot, a crafting recipe and a puzzle all point at the *same* ItemData, so an
## item can never disagree with itself about its own name or icon.
##
## How to add a new item:
##   1. Right-click res://Ressources/Items/ -> New Resource -> ItemData.
##   2. Give it an "id" (lowercase, no spaces - this is what code and dialogue
##      use, and it never gets translated).
##   3. Fill in the names/descriptions and drop in a texture.
##   4. Save it in res://Ressources/Items/. ItemLogic finds it on its own.
##
## The id is deliberately separate from the display names: puzzles and recipes
## match on the id, so renaming "Seil" to "Kletterseil" cannot silently break a
## puzzle the way matching on German text did.

## Stable key used by code, dialogue and recipes. Must be unique.
@export var id: StringName = &""

@export_group("English")
@export var name_en: String = ""
@export_multiline var description_en: String = ""

@export_group("Deutsch")
@export var name_de: String = ""
@export_multiline var description_de: String = ""

@export_group("")
## Icon shown in the inventory slot and on the world pickup.
@export var texture: Texture2D

## Scene dropped into the level by ItemLogic.spawn_in_world(). Leave empty to
## use the default item.tscn, which is enough for an ordinary pickup.
@export var world_scene: PackedScene

## Ticked = several of these share one inventory slot and count up.
## Adventure items are usually unique, so this is off by default.
@export var stackable: bool = false


## Name in the player's language.
func display_name() -> String:
	return name_de if _is_german() else name_en


## Description in the player's language.
func display_description() -> String:
	return description_de if _is_german() else description_en


# Read straight from the TranslationServer at call time. Cheap, and it means
# nothing has to poll the locale every frame to stay in sync.
static func _is_german() -> bool:
	return TranslationServer.get_locale().to_lower().begins_with("de")
