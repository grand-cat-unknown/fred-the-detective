# Agent Notes

## Local Export And Run

Use this command to re-export the Godot web build and run it locally:

```sh
./scripts/export-web.sh && nvm use 22 && vercel dev
```


Yes. Since your sprites are already in the TileSet/TileMap, the easiest setup is now:

Option 1: Make a TileSet tile inspectable

In Godot:
<!-- 
Open assets/tile_sets/interior_world_tiles.tres.
In the TileSet editor, add custom data layers:
inspect_title as String
inspect_description as String
optional: inspect_object_id as String
Select a tile, like a desk/cabinet/painting.
Fill in inspect_title and inspect_description.
Paint that tile into world_map.tscn.
Now when the player stands next to that tile and presses interact, it opens the inspect panel.

Option 2: Unique clue text for one placed tile

TileSet custom data applies to every copy of that tile. So if one specific desk needs special text:

Paint the desk tile normally.
Add an Inspectable node on top of that tile.
Set draw_marker = false.
Set the unique title and description.
I wired both paths in code. TileMap tiles are read from custom data, and Inspectable can now be invisible or sprite-backed. I couldn’t run Godot validation because godot/godot4 is not available on PATH here. -->

New way:

Paint/place the visual object.
Add inspect_object_id on the tile, or place an invisible Inspectable.
Create/edit the matching .tres interactable definition.
Set conditions/effects in the inspector.