# Agent Notes

## Local Export And Run

Use this command to re-export the Godot web build and run it locally:

```sh
./scripts/export-web.sh && nvm use 22 && vercel dev
```


## Interactable Authoring

Use the `InteractableState` workflow for new one-off objects. The goal is:

```text
world.tscn places the object.
assets/interactables/<object_id>.tres defines what it does, says, looks like, and whether it blocks movement.
facts drive state changes.
```

### Placing An Object

For unique objects such as doors, keys, cabinets, clue props, drawers, safes, etc.:

1. Paint/place the visual tile in the TileMap as usual.
2. Add an `Inspectable` scene node at that tile in `scenes/world/world.tscn`.
3. Set `object_id` to the matching resource name, for example `example_locked_door`.
4. Usually set `draw_marker = false` if the TileMap already has the art.
5. Keep tile art/state configuration out of `world.tscn` whenever possible.

Example placed object:

```text
[node name="Inspectable_example_door" parent="." instance=ExtResource("9_insp")]
position = Vector2(164, 1233)
object_id = &"example_locked_door"
draw_marker = false
snap_to_map_grid = false
```

### Defining Behavior

Create or edit:

```text
assets/interactables/<object_id>.tres
```

Prefer the `states` array on `InteractableDefinition`. Each `InteractableState` should contain everything for that state:

- `condition`: when this state is active.
- `title` / `description`: inspection text.
- `effects`: passive facts applied when inspected.
- `action_label` / `action_prompt` / `action_effects`: optional yes/no action.
- `toast`: optional short HUD message shown when this state's effects fire (after the yes/no action confirms, or on inspect for states with passive `effects`). Example: `"Door opened!"`.
- `update_tile`, `layer_name`, `source_id`, `atlas_coords`, `alternative_tile`, `erase_tile`: optional tile swap.
- `update_blocks_movement`, `blocks_movement`: optional collision state.

Example door shape:

```text
states = [
  locked: no key, closed tile, blocks movement
  can_open: has key and not open, asks "Do you want to open the door?", closed tile, blocks movement
  open: door open, open tile, does not block movement
]
```

The first state whose condition passes is used. Keep state order specific and intentional.

### Tile Visuals

Tile visuals are linked by TileMap layer name plus Godot tile IDs:

```text
layer_name = "Doors"
source_id = 2
atlas_coords = Vector2i(22, 4)
alternative_tile = 0
```

Do not store a TileSet path in interactables. The `TileMapLayer` already owns its TileSet; the interactable only says which layer and which tile from that layer's TileSet to use.

Use `erase_tile = true` for pickups or objects that should disappear after a fact changes.

### Facts

Add any new facts in `assets/facts/<fact_id>.tres`. Facts are the source of truth:

```text
example_has_door_key = true
example_door_open = true
```

Tile visuals, blocking, inspect text, and actions should all derive from facts.

### Compatibility

Older resources may still use `variants` and `tile_visuals` separately. Do not use that pattern for new objects unless maintaining existing debug content. New content should use `states`.


## Inventory Authoring

The inventory mirrors the interactable workflow. The goal is:

```text
assets/inventory/<item_id>.tres defines what the item is called and when it shows.
facts drive whether the item is visible in the HUD.
```

Each `InventoryItemDefinition` has a `states` array of `InventoryItemState` entries. The first state whose `condition` passes is rendered in the top-right inventory HUD. If no state matches, the item is hidden.

Each `InventoryItemState` contains:

- `condition`: a `GateCondition` (all_of / any_of / none_of fact ids).
- `label`: short HUD text.
- `description`: optional tooltip text.
- `icon`: optional `Texture2D`.

Register new item ids in `CaseLoader.INVENTORY_IDS` so they load alongside the case. Files in `assets/inventory/` are also auto-discovered.

Example item shape:

```text
states = [
  has_field_book: shows "Field Book" once `has_field_book` is true
]
```

Godot executable app image -> [text](../../Apps/Godot_v4.6.2-stable_linux.x86_64)


## Gating Model (How Facts Drive The World)

Every behavior change in the game — what an object shows on inspect, whether a door blocks movement, what a suspect is willing to say, whether an inventory item is visible — bottoms out in a single primitive: **facts**.

### One global truth store: facts

`CaseState` holds a flat `StringName -> bool` dictionary. Each fact has a `FactDefinition` (`assets/facts/<id>.tres`) declaring its id, default value, label, and description. Facts start at their defaults at case load and flip via effects. Fact ids are lowercase snake_case `StringName`s, e.g. `&"fred_recovered_siren_cell"`.

### One gate primitive: GateCondition

A `GateCondition` is just three lists of fact ids:

- `all_of` — every fact in this list must be true.
- `any_of` — at least one must be true (skipped if list is empty).
- `none_of` — none may be true.

A null condition is "always met." That is the only knob anywhere in the game — conversation gating, room gating, prop visuals, inventory visibility, action availability all bottom out in this single rule.

### Two ways facts get flipped

**1. Environmental — via `InteractableState`.** Each interactable carries an ordered `states` array. The first state whose `condition.is_met(case_state)` wins, and it dictates everything about the object *right now*: title/description on inspect, optional yes/no action, tile swap, blocks-movement flag, toast. Effects fire in two flavors:

- `effects` — passive, applied the moment the player inspects the object (e.g. "looking at the chute reveals the popped valve").
- `action_effects` — applied only when the player confirms the yes/no action prompt (e.g. "Pick up the book?").

State order matters: most-specific / end-state first, fallback last.

**2. Conversational — via `ConversationEffect` on suspects.** A suspect's `allowed_effects` declare which facts an LLM-driven conversation is permitted to set, and under which gate. The judge model only considers an effect if `is_available(state)` is true (its own gate is met). The `description` is the criterion the judge applies ("Set this only if Theo clearly permits Fred to borrow the manual"). This is how dialogue progresses the world without letting the LLM hallucinate arbitrary state flips.

### How suspects change behavior based on facts: PromptBlock

A suspect has two stacks of prompt blocks — `prompt_blocks` (added to the system prompt before the LLM speaks) and `reaction_blocks` (same idea, framed as "react to this happening"). Each block has a `GateCondition`; only available ones get injected. Suspects don't have hard-coded dialogue trees — they have a base persona plus a stack of conditional instructions to the LLM.

### Inventory mirrors interactables

An `InventoryItemDefinition` has its own `states` array — first state whose condition passes is rendered in the HUD; if none match, the item is hidden. Items appear/disappear by fact rather than by explicit add() calls.

### Designing A Story Beat As Game Elements

Each clue / conversation beat decomposes into:

1. **A fact id** — the boolean that captures "this thing is now known / done." (e.g. `fred_recovered_siren_cell`, `pemberton_palm_shown`, `mags_admitted_smoke_break`).
2. **A flip surface** — either an `InteractableState.action_effects` (the player physically did the thing) or a `ConversationEffect` (the suspect admitted it, judged against a written criterion).
3. **Downstream gates** — every dialogue reaction, every room/prop state, every inventory item that depends on this beat lists this fact in its `GateCondition`.

Example: "Vivian tells Fred the service corridor exists" becomes a `ConversationEffect` on Vivian that fires when she's told about it -> sets `vivian_revealed_service_corridor` -> that fact unlocks the service-corridor interactables (trash with stained gloves, concealed passage marker) and shows up as an `all_of` requirement on Pemberton's "pressed on route" prompt block, so he only starts squirming about geometry once Fred *could* know.
