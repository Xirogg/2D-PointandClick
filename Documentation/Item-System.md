# Item & Crafting System

Items and recipes are **Resources** (`.tres` files), not code. Adding content is
an editor job — you should never have to open a script to add an item, a pickup
or a recipe.

| What | Where |
|---|---|
| Item definitions | `res://Ressources/Items/*.tres` |
| Recipes | `res://Ressources/Recipes/*.tres` |
| The API | `ItemLogic` (autoload) |
| Slot storage | `Global.inventory` |

`ItemLogic` scans both folders on startup, so a new `.tres` is picked up
automatically. No registration step.

---

## 1. Creating an item

1. Right-click `res://Ressources/Items/` → **New Resource…** → search `ItemData`.
2. Save it as e.g. `seil.tres`.
3. Fill it in:

| Field | Meaning |
|---|---|
| **id** | The key everything matches on: `seil`. lowercase, no spaces, unique. **Never translated.** |
| **name_en / name_de** | What the player reads. Rename these freely — puzzles match on `id`, not on this. |
| **description_en / description_de** | Shown in the inventory panel. |
| **texture** | Icon. Used in the inventory *and* on the world pickup. |
| **world_scene** | Leave empty. Only set it if this item needs a custom pickup scene instead of the default `item.tscn`. |
| **stackable** | Off for normal adventure items. On = several share one slot and count up. |

That's the whole item. It is now valid everywhere: pickups, recipes, puzzles,
dialogue.

---

## 2. Placing an item in a scene (player walks over and picks it up)

Yes — this still works, and it's less work than before.

1. Drag `res://Scenes/GUI/Inventory/item.tscn` into your level.
2. In the Inspector, drag your `ItemData` into the **Item** field.
3. Position it. Done.

You no longer fill in name/description/texture on the node — it reads all of
that from the `ItemData`. The icon appears from the resource.

The player has to **walk over to it first**: the pickup is driven by the child
`Pickup_Range` (an `Interactable`), so it can never be grabbed from across the
room. Resize its `CollisionShape2D` to change the clickable area.

**Picked-up items stay picked up.** `Global` remembers the item by a key derived
from the level file + the node's path, so re-entering or reloading the level does
not respawn it. If the inventory was full the pickup is *not* consumed — it stays
in the world for later.

> Set the **item_id** field by hand only if you want a specific, save-stable key
> (e.g. the same logical item placed in two levels).

---

## 3. Spawning an item at runtime

### From dialogue (after a conversation reaches a point)

Put a `do` mutation on its own line in the `.dialogue` file:

```
~ start
Nathan: Hier, nimm das Seil.
do ItemLogic.give("seil")
=> END
```

Dialogue Manager resolves autoloads directly, so no glue code is needed.

You can branch on what the player carries:

```
if ItemLogic.has("seil")
	Nathan: Du hast das Seil ja schon.
else
	Nathan: Nimm das hier.
	do ItemLogic.give("seil")
```

### From code

```gdscript
ItemLogic.give("seil")           # straight into the inventory
ItemLogic.give("muenze", 3)      # three of them
ItemLogic.take("seil")           # remove one
ItemLogic.has("seil")            # bool
ItemLogic.count("muenze")        # int
```

### As a pickup on the ground instead of in the inventory

```gdscript
ItemLogic.spawn_in_world("seil", self, Vector2(320, 180))
```

Drops a real pickup into the level at that position, which the player has to
walk over to — same as an editor-placed one.

### Return values

`give()` returns `false` when the inventory is full or the id is unknown, and in
that case **nothing** is added. `take()` returns `false` when the player doesn't
have that many, and removes nothing. Both are safe to call blindly.

---

## 4. Creating a recipe

1. Right-click `res://Ressources/Recipes/` → **New Resource…** → search `Recipe`.
2. Save it as e.g. `schutzausruestung.tres`.
3. Fill it in:

| Field | Meaning |
|---|---|
| **inputs** | Set size to 2, drag one `ItemData` into each element. |
| **result** | The `ItemData` the player gets. |
| **consume_inputs** | On = the inputs are used up. Off = the player keeps them (for a tool). |

**Order does not matter.** Rope + hook and hook + rope both find the recipe.

Working example in the repo: `Ressources/Recipes/schutzausruestung.tres`
(Gasmaske + Schutzanzug → Vollständige Schutzausrüstung).

### What happens in game

The player right-click-drags one slot onto another → a **Kombinieren** button
appears → pressing it calls `ItemLogic.craft()`, which either:

- **finds a recipe** → consumes the inputs, adds the result, fires `craft_succeeded`
- **finds nothing** → changes nothing and fires `craft_failed`, which `Global`
  turns into one tick on the **escalation bar**

A failed craft can never eat an item — the inputs are checked before anything is
removed.

---

## 5. Item-on-hotspot puzzles

"Use the crowbar on the crate":

1. Add `Scenes/Modules/activity_module.tscn` as a **child of the node that owns
   the puzzle**.
2. Drag the required `ItemData` into **Needed Item**.
3. Tick **Consume Item** if the item is used up.
4. Give the *parent* node these methods:

```gdscript
func Execute_Function() -> bool:
	return not already_open        # may the puzzle fire right now?

func Execute_Action() -> void:
	already_open = true            # what actually happens
```

The player arms an item by opening the inventory, clicking it, and pressing
**BENUTZEN** — that sets `Global.selected_item`. Clicking the hotspot then fires
if the armed item matches. Matching is on the `ItemData` resource itself, so
renaming or translating an item cannot break the puzzle.

The armed item is cleared after a successful use, so it isn't still "in hand"
for the next click.

---

## 6. Useful signals

```gdscript
ItemLogic.item_granted       # (item: ItemData) — an item entered the inventory
ItemLogic.give_failed        # (item: ItemData) — inventory was full
ItemLogic.craft_succeeded    # (recipe: Recipe)
ItemLogic.craft_failed       # (first, second: ItemData) — drives escalation
Global.updateinventory       # slots changed, redraw
Global.selected_item_changed # (item: ItemData) — armed item changed
```

---

## 7. Starting a new game

```gdscript
Global.clear_inventory()
Global.reset_picked_up_items()   # placed world items reappear
Global.reset_escalation()
Global.reset_story_state()
```

---

## Known gap

The inventory is capped at 10 slots (`Global.inventory_size`). If an NPC hands
the player an item while all slots are full, `give()` fails and the item is
simply not granted — `give_failed` fires but nothing listens to it yet. Either
listen to it and show a "no room" line, or make the grid scroll and drop the cap.
