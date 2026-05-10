# Fred the Detective — Progress

## Current State

### Done
- Top-down movement, room bounds, player drawn as hat figure
- 3 suspects placed in the room, each with name, role, and LLM-powered conversation
- Press E near a suspect to open a dialogue; each suspect has independent conversation memory
- LLM is given the full case truth in the system prompt and plays the character accordingly
- Clues discovered via press-E-to-inspect (not auto-collect)
- Clue descriptions displayed in a popup panel; clue dots turn green once inspected
- "Make Accusation" button unlocks after at least 1 clue inspected + 1 suspect questioned
- Three-step accusation: pick suspect → pick key evidence → write the theory connecting suspect, clue, and motive
- Final accusation calls the LLM verifier with the authored case truth and the player's written explanation, then parses a structured verdict
- Evidence must actually implicate the suspect — scene clues (wine glass, window latch) do not win on their own, and a vague explanation can still fail
- LLM clue context now includes full clue descriptions (not just labels) — suspects can react specifically when Fred mentions found evidence

### In Progress
- The playable prototype still needs to be ported fully to the Sedgewick Haunting case in `ghostbusters-case.md`.
- `ghostbusters-case.md` is the current story canon for V0.

### Case Summary (Spoilers)
Victim: Reginald Vance. Killed in suite 1221 during a real haunting.
Killer: Dr. Otis Pemberton. Motive: he wanted Vance's anchor idol for his research before Vance locked it away.
Key evidence chain:
1. The field book says anchor idols do not vanish after hauntings.
2. The body wound, wall fan, and pedestal dust match an opened charged ghost cell, not a ghost attack.
3. The idol is hidden inside the spent ghost cell in the jammed laundry chute.
4. Pemberton's stained gloves tie him to opening and purging the cell.
5. Viv's clarification of the 9:18 room 1220 entry breaks Pemberton's sweep alibi.

---

## Open Questions

- [x] **Case content** — Use the Sedgewick Haunting as the V0 case.
- [x] **Clue-to-dialogue integration** — LLM now receives full clue descriptions; suspects can react specifically to evidence Fred has found.
- [x] **Accusation depth** — Three-step flow: suspect → key evidence → written theory. Needs Sedgewick-specific verifier facts before V0 is playable end-to-end.
- [ ] **Visual improvements** — NPC names aren't drawn in the world (just shown in interact prompt). Should they be rendered as labels above heads?
- [ ] **Suspect gating** — Right now there's no minimum requirement to talk to anyone before accusing. Is that OK for V1?
- [ ] **Notebook / case log** — Decided against for now. Revisit after testing if players forget clues mid-game.

---

## Next Steps (Proposed Order)
1. Port `scripts/game.gd` to the Sedgewick Haunting suspects, clues, verifier truth, and ending feedback.
2. Playtest the loop: does the accusation feel earned now that evidence matters?
3. Add NPC name labels drawn above heads.
4. Export and deploy the updated web build.
