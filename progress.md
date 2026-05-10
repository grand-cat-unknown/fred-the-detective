# Fred the Detective — Progress

## Current State

### Done
- Top-down movement, room bounds, player drawn as hat figure
- 3 suspects placed in the room, each with name, role, and LLM-powered conversation
  - Victoria Ashmore (victim's wife) — the murderer
  - James the Butler — innocent witness
  - Chef Renard — innocent witness
- Press E near a suspect to open a dialogue; each suspect has independent conversation memory
- LLM is given the full case truth in the system prompt and plays the character accordingly
- Clues discovered via press-E-to-inspect (not auto-collect)
  - Shattered Wine Glass (near armchair)
  - Silk Glove monogrammed V.A. (center of room)
  - Broken Window Latch (right wall)
- Clue descriptions displayed in a popup panel; clue dots turn green once inspected
- "Make Accusation" button unlocks after at least 1 clue inspected + 1 suspect questioned
- Two-step accusation: pick suspect → pick key evidence (only shows inspected clues)
- Result text is evidence-aware: naming the Silk Glove gives "perfect deduction" flavour; other correct clues still win with different text; wrong accusation names the cited clue explicitly
- LLM clue context now includes full clue descriptions (not just labels) — suspects can react specifically when Fred mentions found evidence

### Case Summary (Spoilers)
Victim: Lord Pemberton. Killed in the drawing room.
Killer: Victoria Ashmore. Motive: will change cut her out.
Key evidence chain:
1. Glove monogrammed V.A. places her at the scene.
2. James saw her leave the drawing room at ~9pm.
3. Window latch broken from inside (not an intruder).
4. Chef Renard heard a woman's voice and raised voices at 9pm.

---

## Open Questions

- [ ] **Case content** — The current case is a placeholder. Is it good enough to ship as the V1 case, or do we want to redesign suspects, setting, and clues?
- [x] **Clue-to-dialogue integration** — LLM now receives full clue descriptions; suspects can react specifically to evidence Fred has found.
- [x] **Accusation depth** — Two-step flow: suspect → key evidence. Result flavour differs based on chosen clue.
- [ ] **Visual improvements** — NPC names aren't drawn in the world (just shown in interact prompt). Should they be rendered as labels above heads?
- [ ] **Suspect gating** — Right now there's no minimum requirement to talk to anyone before accusing. Is that OK for V1?
- [ ] **Notebook / case log** — Decided against for now. Revisit after testing if players forget clues mid-game.

---

## Next Steps (Proposed Order)
1. Playtest the loop: does the accusation feel earned?
2. Polish the case or redesign it if the placeholder feels weak.
3. Decide on accusation depth (evidence selection or just suspect pick).
4. Add NPC name labels drawn above heads.
5. Export and deploy the updated web build.
