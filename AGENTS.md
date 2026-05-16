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
