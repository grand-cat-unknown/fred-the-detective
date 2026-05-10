# Fred the Detective Goal

## Core Fantasy

The player is a detective in a small top-down 2D space, walking between suspects, asking questions, collecting clues, and deciding who committed the murder.

The fun should come from deduction, not combat or twitch skill. The player should feel like they are slowly turning messy testimony into a confident accusation.

## North Star For V1

Build a short playable murder case with this loop:

1. Enter the scene.
2. Explore the room and inspect key evidence.
3. Talk to several suspect NPCs.
4. Notice contradictions, motives, and alibis.
5. Choose one suspect to accuse.
6. Get a success or failure ending based on the evidence.

If this loop is fun with simple art and one case, the project has a real foundation.

## Main Gameplay Loop

### 1. Explore

The player walks around a compact map.

They can inspect interactive objects such as:

- the body
- a weapon
- a note
- a broken object
- a door or window

Each inspected object gives a clue. Clues should be short and readable in a few seconds.

### 2. Interview Suspects

There should be multiple NPC suspects in the same space or nearby connected spaces.

Each suspect should provide:

- a role or relationship to the victim
- a motive or possible motive
- an alibi
- a distinct attitude
- at least one useful fact

The player should be able to revisit suspects after finding new clues. New evidence should unlock better questions or expose contradictions.

### 3. Build Understanding

The player is not just gathering items. They are comparing statements against evidence.

The game should support simple deductions such as:

- one suspect says the window was closed, but the player found signs it was opened
- two suspects give conflicting timelines
- a suspect claims innocence, but an inspected clue places them at the scene

This is the real heart of the game.

### 4. Accuse Someone

Once the player has enough information, they choose a suspect.

The accusation step should feel deliberate. Ideally the player also names one or two supporting clues, even in a simple form.

Possible v1 structure:

- choose the suspect
- choose the strongest clue
- optionally choose the contradiction that proves the case

### 5. Resolve The Case

If the accusation is correct, the player wins and gets a short wrap-up.

If it is wrong, the player gets a failure outcome. Failure should still teach something, not just say "wrong." It can briefly explain what evidence was missed.

## What Makes The Loop Fun

The loop works if:

- each suspect feels different to talk to
- clues are easy to understand but meaningful to combine
- the player can form theories before the answer is revealed
- there is some uncertainty until the accusation
- the solution feels earned instead of random

The loop fails if:

- clues are just collectibles with no reasoning attached
- suspects repeat generic dialogue with no new information
- the player can only solve the case by guessing
- the correct answer is obvious immediately

## Recommended V1 Structure

Keep the first real case small.

- 1 room or 2 connected rooms
- 3 suspects
- 4 to 6 inspectable clues
- 1 murderer
- 1 accusation screen
- 1 success ending and 1 failure ending

That is enough to prove the concept without overbuilding.

## Role Of The LLM In V1

The LLM should support suspect conversations, not define the truth of the case.

For v1:

- the murderer, motives, and clue relationships should be authored by the game
- the LLM should help each suspect speak in character
- suspects can reveal or hide information based on what the player has found
- the player should solve a designed mystery, not a randomly generated one

This keeps the case fair and debuggable while still making conversations feel alive.

## How The Current Prototype Maps To This

The current project already has the beginnings of the loop:

- top-down movement
- clue collection
- NPC conversation
- case exit / completion gate

The next step is to turn those from a generic collect-and-exit flow into a suspect-and-accuse flow.

## Suggested Implementation Order

1. Replace the single NPC with 3 suspects, each with a name, role, and short suspect profile.
2. Replace generic clue pickups with named evidence the player can inspect and review.
3. Add a simple case notebook UI that lists discovered clues and suspect statements.
4. Gate progress with information quality, not just "all clues collected."
5. Add an accusation flow.
6. Add success and failure endings.

## Boundaries For Now

Do not solve these yet:

- larger multi-room story structure
- multiple chapters or cases
- deep procedural generation
- combat or stealth
- elaborate inventory systems
- branching narrative sprawl

The immediate goal is one strong small case with a satisfying accusation loop.

## One-Sentence Product Goal

Make a small top-down detective game where the player explores a scene, interviews suspects, connects clues to contradictions, and accuses the murderer with enough evidence to feel smart when they are right.
