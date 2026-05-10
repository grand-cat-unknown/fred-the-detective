# Fred the Detective

Super simple Godot 4 detective game for web export.

## Play loop

- Move Fred with arrow keys or WASD.
- Collect the three clues.
- Walk into the green exit to close the case.

## Run in Godot

1. Open the project in Godot 4.
2. Press F5 to run the main scene.

## Export for Vercel

1. In Godot, add the Web export preset.
2. Export the build into the `public/` folder in this repo.
3. Keep the generated `.html`, `.js`, `.pck`, `.wasm`, and support files together.
4. Import this repo into Vercel and deploy it as a static site.

The included `vercel.json` adds the headers commonly needed by Godot web exports, including the WebAssembly content type.
