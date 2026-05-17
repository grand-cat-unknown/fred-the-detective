# Facts Spec

Living spec for the fact-driven gating that ties story beats to game elements. See `AGENTS.md` → "Gating Model" for the underlying primitives (`GateCondition`, `InteractableState`, `ConversationEffect`, `PromptBlock`, inventory `states`).

Each thread below lists:

- **Fact set** — every fact id introduced by the thread, what it means, how it flips, what it unlocks.
- **Interactables** — the world objects that carry the flip surfaces, with state ordering.
- **Inventory** — items that appear when a fact is true.
- **Suspect wiring** — `prompt_blocks` and `allowed_effects` (`ConversationEffect`s) that depend on or set these facts.
- **Accusation implications** — how the thread affects the accuse panel.

Facts flow downhill: each thread should declare which facts it consumes from other threads up front, so dependencies stay visible.

---

## Thread: Julian Vane red herring (idol-swap fraud, not murder)

The headline red herring. Julian has the loudest "I did it" silhouette of anyone who didn't — rival collector, master-key access, fake idol in his room, lawyered-up evasion. Fred is supposed to chase him hard and bounce off. The chain forces Fred through Mags first (the bribe-and-master-key confession), which is what eventually folds Julian.

### Chain

```text
1103 lit cigarette inspected ──┐
                                ├── unlocks Mags's "you smoked in 1103" pressure
Mags cigarette pouch picked up ─┘
            │
            ▼
Mags confesses: bribed, gave Julian a master key
            │
1204 fake idol inspected ───────┐
                                ├── unlocks Julian's "fold" path
Mags confession (above) ────────┘
            │
            ▼
Julian confesses: idol-swap fraud, exonerates himself on murder
```

### Fact set

| Fact id | Meaning | How it flips | What it unlocks |
| --- | --- | --- | --- |
| `lit_cigarette_found_1103` | Fred has inspected the still-lit Lady Finger cigarette in Room 1103. | `InteractableState.effects` (passive) on the cigarette prop in 1103 — fires on first inspect, no pickup required. | One half of the Mags-pressure gate. |
| `has_mags_cigarette_pouch` | Fred picked up the monogrammed pouch with Mags's initials. | `InteractableState.action_effects` on the pouch pickup in 1103 ("Take it"). | Inventory HUD shows the pouch; other half of Mags-pressure gate. |
| `mags_confessed_bribe_master_key` | Mags has admitted she took a bribe and handed Julian a master key. | `ConversationEffect` on Mags, gated `all_of: [lit_cigarette_found_1103, has_mags_cigarette_pouch]`. | Julian-fold gate; opens the Julian fraud confession path. |
| `julian_fake_idol_seen` | Fred has inspected the wax idol in Julian's room (1204) and clocked it as a forgery. | `InteractableState.effects` (passive) on the idol prop in 1204. | Deduction note; second half of Julian-fold gate. |
| `julian_confessed_fraud_not_murder` | Julian has admitted the idol-swap scheme and placed himself near 1102 at the thud. | `ConversationEffect` on Julian, gated `all_of: [mags_confessed_bribe_master_key, julian_fake_idol_seen]`. | Clears Julian on the accuse panel; surfaces independent corroboration of the 9:11 thud (feeds into the real chute-and-Pemberton chain). |

### Interactables

**`room_1103_cigarette`** — placed inside 1103 on a side table / ashtray tile. Inspect-only (not a pickup).

- State A (default): *"A still-lit Lady Finger. Smoke curling. Someone was here moments ago."* → `effects: [lit_cigarette_found_1103 = true]`. Passive, fires on first inspect.
- State B (already inspected, `all_of: [lit_cigarette_found_1103]`): *"The cigarette has burned down. Same brand."* → no effects.

**`mags_cigarette_pouch`** — placed inside 1103 (under a chair / on the bed / near the ashtray). Pickup interactable.

- State A (default): *"A small embroidered pouch. Initials `MM` stitched in red thread. Half-full of Lady Fingers."* → `action_label: "Take it"`, `action_effects: [has_mags_cigarette_pouch = true]`, `erase_tile = true` on the props layer.
- State B (already taken, `all_of: [has_mags_cigarette_pouch]`): tile already erased — entry suppressed.

**`julian_wax_idol`** — placed in 1204 on the writing desk. Inspect-only.

- State A (default): *"A carved figurine on the writing desk. Heavier than it should be — wax beneath the paint. Not the real Crooked Idol."* → `effects: [julian_fake_idol_seen = true]`. Passive.
- State B (already inspected, `all_of: [julian_fake_idol_seen]`): same description, no effects.

### Inventory

**`mags_cigarette_pouch`** — `InventoryItemDefinition` with a single state gated `all_of: [has_mags_cigarette_pouch]`.

- Label: *"Mags's Cigarette Pouch"*.
- Description / tooltip: *"Lady Fingers. `MM` monogrammed in red thread."*

Register in `CaseLoader.INVENTORY_IDS` (and the cigarette pouch interactable in `INTERACTABLE_IDS`, plus all facts in `FACT_IDS`).

### Suspect wiring

**Mags** — `assets/suspects/maid.tres` (id: `&"maid"`).

`prompt_blocks` to add:

- `PromptBlock_smoking_evidence` — `all_of: [lit_cigarette_found_1103, has_mags_cigarette_pouch]`. Text:

  > REACTION BEAT — Fred has physical proof you smoked in Room 1103: the lit cigarette AND your monogrammed pouch. This is a fireable offense and you know it. If he raises smoking, 1103, or the pouch, panic. Beg. Do not lie about it — denying with the pouch in his hand makes it worse. If he presses you for everything you know, fold completely: you took money to slip Julian Vane a master key one night. You never asked what he wanted it for. You swear you knew nothing about any murder. Plead with him not to tell Vivian.

`allowed_effects` to add:

- `ConversationEffect_mags_confesses_bribe` — `all_of: [lit_cigarette_found_1103, has_mags_cigarette_pouch]`, `fact_id = mags_confessed_bribe_master_key`. Description:

  > Set this only if Mags clearly admits she accepted a bribe and gave a master key to Julian Vane.

**Julian** — `assets/suspects/rival.tres` (id: `&"rival"`).

`prompt_blocks` to add:

- `PromptBlock_fold` — `all_of: [mags_confessed_bribe_master_key, julian_fake_idol_seen]`. Text:

  > REACTION BEAT — Fred knows two things: Mags admitted she gave you a master key, and Fred has identified the wax idol in your room as a forgery. The lawyer act will not hold. Fold. Admit you intended to swap the fake for the real Crooked Idol that night. State plainly that you were approaching 1102 to make the swap when you heard a loud thud somewhere west and seconds later the watch team was already at the door. You never entered. You did not kill Vance. You are a thief and a fraud, not a murderer. Offer details if pressed — the timing you heard, where you were standing — because corroborating yourself is now your only protection.

`allowed_effects` to add:

- `ConversationEffect_julian_confesses_fraud` — `all_of: [mags_confessed_bribe_master_key, julian_fake_idol_seen]`, `fact_id = julian_confessed_fraud_not_murder`. Description:

  > Set this only if Julian clearly admits he intended to swap a fake idol for the real one AND places himself near 1102 hearing a thud, AND denies committing the murder.

### Accusation implications

- A Julian verdict on the accuse panel is **available** when any of `julian_fake_idol_seen`, `mags_confessed_bribe_master_key`, or his rivalry with Vance is on the board — i.e. Fred has *something* circumstantial to go on.
- Before `julian_confessed_fraud_not_murder`: judge rejects with a "no kill-window placement" message. (Trap difficulty TBD — soft / medium / hard.)
- After `julian_confessed_fraud_not_murder`: judge rejects Julian cleanly and the deduction view re-labels him as a *forgery* lead, not a *murder* lead.
- Side benefit: Julian's confession is the first independent witness corroboration of the 9:11 thud, which becomes a load-bearing brick in the *real* Pemberton chain (chute → west service hall → late arrival from the wrong direction).

### Open / TBD

- Accusation trap severity (soft warning vs. one-strike vs. case-ends-wrong).
- Whether Julian, post-confession, surrenders any *additional* directional detail about the thud (e.g. "it was coming from the north-west") that could fast-forward the chute discovery. Probably yes, but keep it phrased as Julian's *impression*, not certainty.
