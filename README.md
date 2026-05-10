# Fred the Detective

Super simple Godot 4 detective game for web export.

## Play loop

- Move Fred with arrow keys or WASD.
- Press E near clues to inspect evidence.
- Press E near suspects to question them.
- Once you have inspected evidence and questioned at least one suspect, make an accusation, choose the key clue, and write the theory that ties it together.

## Run in Godot

1. Open the project in Godot 4.
2. Press F5 to run the main scene.

## Local API env

The server routes now read env vars from the repo root `.env` or `.env.local` in addition to normal process env.

1. Copy `.env.example` to `.env`.
2. Fill in `APP_USERNAME`, `APP_PASSWORD`, `APP_SESSION_SECRET`, and `OPENAI_API_KEY`.
3. Run the local server layer with a tool that serves the `api/` directory, such as `vercel dev` from the repo root.

When both are present, real process env vars still win over `.env`, which keeps production behavior unchanged.

## Export for Vercel

1. The repo already includes a `Web` export preset that targets `public/index.html`.
2. From the repo root, run `scripts/export-web.sh`.
3. If Godot is not on your `PATH`, the script also checks common AppImage names in `~/Downloads`.
4. You can still force a specific binary with `GODOT=/path/to/godot4 scripts/export-web.sh` or `--godot /path/to/godot4`.
5. The script exports the build into `public/`, updating the generated `.html`, `.js`, `.pck`, `.wasm`, and support files together.
6. Import this repo into Vercel and deploy it as a static site.

Useful flags:

- `--debug`: export a debug web build.
- `--preset NAME`: use a different export preset.
- `--output PATH`: write the HTML shell somewhere else.

## Simple access login

The web entry page now checks a small server-side login before it starts the Godot build.

Set these Vercel environment variables before deploying:

- `APP_USERNAME`: login username for intended players.
- `APP_PASSWORD`: login password for intended players.
- `APP_SESSION_SECRET`: a long random string used to sign the session cookie.

The session lasts for 12 hours and is stored in an `HttpOnly` cookie.

## OpenAI setup

Do not put the OpenAI key inside the Godot export or browser JavaScript. Set these on Vercel instead:

- `OPENAI_API_KEY`: your OpenAI server key.
- `OPENAI_MODEL`: optional default model for the proxy, for example `gpt-4.1-mini`.

The repo now includes a protected server route at `/api/llm`. It only works after the login cookie has been set by `/api/auth`.
The route also adds a server-side prompt-injection guard, scans for common injection attempts, and wraps the Godot-provided `input` as untrusted JSON data before sending it to the model. The Godot dialogue builder separately marks Fred's player-authored turns as untrusted text inside the transcript. Godot uses the same route for suspect dialogue and for the final accusation verifier.

Send a `POST` request from Godot with JSON like this:

```json
{
  "input": "Summarize the clues Fred has collected.",
  "instructions": "Keep the tone short and noir.",
  "max_output_tokens": 150
}
```

Example Godot usage:

```gdscript
var headers := ["Content-Type: application/json"]
var body := JSON.stringify({
  "input": "Summarize the clues Fred has collected.",
  "instructions": "Keep the tone short and noir.",
  "max_output_tokens": 150,
})

$HTTPRequest.request("/api/llm", headers, HTTPClient.METHOD_POST, body)
```

## Important security note

This login gate helps keep casual visitors out of the game, but it does **not** make client-side API keys safe. The safe pattern is the one above: keep the provider key in the Vercel function and have Godot call `/api/llm`.

The included `vercel.json` adds the headers commonly needed by Godot web exports, including the WebAssembly content type.
