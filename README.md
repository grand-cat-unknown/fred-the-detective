# Fred the Detective

An occult auction. A dead collector. A castle hotel full of people who know more than they are saying.

**Fred the Detective** is a playable mystery game about walking into a suspicious old hotel and pulling one clean truth out of a room full of half-truths. You are Detective Fred, called to The Sedgewick after Felix Vance, a wealthy occult collector, is found dead in the Royal Suite during a Ghostbusters containment watch.

At first, everyone wants the answer to be supernatural. The auction was full of cursed objects. The victim had just won the night's most dangerous artifact. The hotel is old enough to have secrets in its walls.

But Fred does not solve cases by believing the loudest story in the room. He searches, questions, compares, unlocks, and accuses. Every clue changes what can be asked. Every conversation can open a new route. Every suspect has a version of the night that sounds reasonable until the evidence starts pushing back.

## The Game

- Explore The Sedgewick Hotel with WASD or arrow keys.
- Inspect rooms, props, doors, clues, and suspicious leftovers with Space.
- Question suspects in free text instead of clicking through a fixed dialogue tree.
- Follow evidence through locked rooms, staff-only routes, missing equipment, forged objects, stained hands, and unreliable alibis.
- Make a final accusation by naming the killer and explaining the method and proof in your own words.

This is a compact detective story, not a sandbox with mystery flavor. There is a real culprit, a real method, false leads, gated revelations, and a final theory the player has to earn.

## What Makes It Special

Fred is built around a simple idea: the world, the inventory, the suspects, and the ending should all react to the same investigation truth.

```text
facts -> gates -> world state, inventory, suspect behavior, accusations
```

That gives the game its little spark:

- **The mystery is authored, but the interviews breathe.** Suspects answer in free text with LLM support, while progression stays locked to hand-authored facts and effects.
- **Rooms and conversations are one puzzle.** A thing learned from Iris can change what Vivian will hand over; a key from Vivian can open a door; what is behind that door can reshape the final accusation.
- **Evidence matters mechanically.** Clues are not just lore pickups. They unlock topics, change suspect reactions, reveal inventory, alter tiles, remove blockers, and make the ending possible.
- **The game resists hallucinated progress.** The LLM can perform a character, but it cannot invent new facts. Conversation state changes pass through explicit `ConversationEffect` rules and a strict judge.
- **It is a mystery engine hiding inside a small game.** The same pattern can author doors, safes, clues, suspect secrets, inventory items, and final-case logic without scattering bespoke scripts everywhere.

## How The Case Works

The repo's central design idea is simple: every meaningful game beat is a boolean fact.

Facts are defined in:

```text
assets/facts/
```

Examples:

```text
has_field_book
iris_returned_transcribed_log
vivian_gave_chute_room_key
chute_room_door_open
pemberton_palms_shown
has_evidence
```

Those facts are checked by `GateCondition` resources. A gate can require all facts in `all_of`, at least one fact in `any_of`, and no facts in `none_of`.

That same primitive powers the whole game:

- **Interactables**: what an object says, whether it offers an action, whether it changes tile art, and whether it blocks movement.
- **Inventory**: which items appear in the HUD and what they are called.
- **Suspects**: which prompt blocks, reactions, topic responses, and conversation effects are currently available.
- **Final accusation**: whether Fred has earned enough evidence to make the correct theory count.

## Data-Driven Interactables

Unique objects live in:

```text
assets/interactables/
```

An interactable is an ordered list of `InteractableState` entries. The first state whose condition passes wins.

For example, the chute-room door has three states:

```text
open      -> open tile, does not block movement
can_open  -> Fred has Vivian's key, asks "Open the door?"
locked    -> no key, closed tile, blocks movement
```

The scene places the object once in `scenes/world/world.tscn`; the resource decides how it behaves over time.

## Living Suspects

Suspects live in:

```text
assets/suspects/
```

Each suspect has:

- a persona and public-facing role
- topic-specific response states
- prompt blocks gated by discovered facts
- reaction blocks for newly uncovered evidence
- allowed conversation effects that can flip facts

The LLM is used for texture and flexibility, but it does not get to invent progression. After an exchange, `ConversationEffectJudge` checks only the authored effects that are currently available for that suspect and topic. If the player has not earned a fact, the model is not allowed to set it.

This creates a useful middle ground: characters feel conversational, while the mystery remains designed.

## Final Accusation

The ending blends hard game rules with a structured-output LLM judge.

The game first checks that Fred picked the right suspect and has the required evidence facts. Only then does `AccusationJudge` evaluate the player's written theory for the necessary ideas. The judge can accept natural wording, but it cannot reveal the answer or bypass missing evidence.

## Project Map

```text
api/                         Vercel server routes for auth and LLM proxy
assets/facts/                Fact definitions, the source of truth
assets/interactables/         Data-authored props, clues, doors, pickups
assets/inventory/             Fact-gated HUD inventory items
assets/suspects/              NPC personas, topic gates, dialogue effects
scenes/                       Godot scenes
scripts/data/                 Case resources and shared gate/effect types
scripts/services/             LLM client, dialogue, topic classification, judges
scripts/ui/                   Dialogue, evidence, inventory, inspect, accusation UI
scripts/world/                Player, NPCs, inspectables, world map behavior
Fred the detective - Story docs/  Case notes, timeline, field manual, characters
```

## Run Locally In Godot

1. Open the repo in Godot 4.
2. Run the main scene with F5.

The game can be explored locally without the deployed web shell. For full LLM-backed conversations, configure the API environment below.

## Local Web Export And Server

The recommended local web command is:

```sh
./scripts/export-web.sh && nvm use 22 && vercel dev
```

This re-exports the Godot web build into `public/`, switches Node to 22, and starts the Vercel server layer.

If Godot is not on your `PATH`, `scripts/export-web.sh` checks common AppImage locations. You can also provide a binary explicitly:

```sh
GODOT=/path/to/godot4 ./scripts/export-web.sh
```

Useful export flags:

```sh
./scripts/export-web.sh --debug
./scripts/export-web.sh --preset Web
./scripts/export-web.sh --output public/index.html
```

## Environment

Copy `.env.example` to `.env` and set:

```text
APP_USERNAME=
APP_PASSWORD=
APP_SESSION_SECRET=
OPENAI_API_KEY=
OPENAI_MODEL=
```

`OPENAI_MODEL` is optional. The server routes read values from process env, `.env`, or `.env.local`, with real process env taking priority.

The browser never receives the OpenAI key. Godot calls `/api/llm`, and the Vercel function forwards the request server-side after the login cookie is present.

## Security Shape

The web build includes a lightweight login gate for intended players. It is useful for private playtests, but the important security decision is the server-side LLM proxy:

- secrets stay in Vercel env vars
- `/api/auth` issues the session cookie
- `/api/llm` requires that session
- prompts wrap player-authored content as untrusted input
- structured outputs are used for machine-read game-state judgments

## Authoring A New Beat

Most new investigation beats follow this pattern:

1. Add a fact in `assets/facts/<fact_id>.tres`.
2. Add a physical flip surface with an `InteractableState`, or a conversational flip surface with a `ConversationEffect`.
3. Gate downstream object states, inventory items, prompt blocks, or topic responses on that fact.

Example:

```text
Fred obtains a key
-> vivian_gave_chute_room_key = true
-> chute-room door enters "can_open" state
-> Fred opens it
-> chute_room_door_open = true
-> new evidence becomes reachable
```

This is the heart of the repo: the authored mystery is not just dialogue text. It is a connected state graph the player walks through.

## Deploy

1. Set the environment variables in Vercel.
2. Export the web build:

```sh
./scripts/export-web.sh
```

3. Deploy the repo to Vercel.

`vercel.json` includes the headers Godot web exports need, including the WebAssembly content type.

## Credits And Spirit

Fred the Detective is a love letter to compact mystery design: a suspicious hotel, too many people with partial truths, physical evidence that changes what questions matter, and conversations that can actually move the world forward.

It is small enough to understand, but rich enough to be a blueprint for something larger: an authored detective game where AI dialogue is a tool for performance, not a replacement for design.
