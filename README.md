# Fred the Detective

Super simple Godot 4 detective game for web export.

## Play loop

- Move Fred with arrow keys or WASD.
- Collect the three clues.
- Walk into the green exit to close the case.

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

1. In Godot, add the Web export preset.
2. Export the build into the `public/` folder in this repo.
3. Keep the generated `.html`, `.js`, `.pck`, `.wasm`, and support files together.
4. Import this repo into Vercel and deploy it as a static site.

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
