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

---

## Thread: The Truth Path (cell → device → log → chute → idol → palms → Pemberton)

The spine of the case. Each step opens the next. By the end, Fred has the genuine Crooked Idol in hand, knows the murder method (manual purge of a Siren Cell) and its forensic signature (sub-dermal violet staining of the palms), and can ask every Ghostbuster to show their hands. Otis Pemberton is the one whose palms are stained.

This thread has no dependencies on the Julian red herring — but Julian's post-fold confession (`julian_confessed_fraud_not_murder`) corroborates the thud direction, so a player who has run that thread first will reach the chute step faster.

### Chain

```text
Inspect gear cart inventory list ──► cell missing noticed
        │
        ▼
Talk to Theo about it ──► Theo confirms cell WAS there at watch start
        │
        ▼
Pick up Iris's abandoned listening device at her west post
        │
        ▼
Give the device to Iris ──► Iris promises a transcribed log; device leaves Fred's HUD
        │
        ▼
Return to Iris ──► she hands over the transcribed log; reads it aloud
        │                                  ↳ thud + footsteps west (chute lead)
        ▼
Ask Vivian for the ground-floor chute-room key ──► Vivian hands over the key
        │
        ▼
Open the chute-room door ──► enter, find the spent Siren Cell with the real Crooked Idol stashed inside
        │
        ▼
Show the idol to a Ghostbuster (Mara / Theo / Iris) ──► they authenticate it; one of the team did this
        │
        ▼
(Pre-req earlier: get Theo's field book) ──► read the field book ──► manual-purge method → palms stained violet
        │
        ▼
Ask each Ghostbuster to show their palms ──► Mara / Theo / Iris show clean; Otis Pemberton shows violet stain
        │
        ▼
Accuse Otis Pemberton.
```

### Fact set

| Fact id | Meaning | How it flips | What it unlocks |
| --- | --- | --- | --- |
| `theo_cart_cell_missing_noticed` | Fred has inspected the gear cart's inventory list and seen that a Siren Cell is missing. | `InteractableState.effects` (passive) on the gear-cart inventory-list interactable in the Ghostbusters' room. | Theo's "confirm it was there this morning" conversation path. |
| `theo_confirmed_cell_present_at_start` | Theo has confirmed the missing cell was definitely on the cart at the start of watch. | `ConversationEffect` on Theo, gated `all_of: [theo_cart_cell_missing_noticed]`. | Establishes the cell-disappeared-during-watch fact; Iris will treat the transcribed log as relevant once this is known. (Optional gate for Iris's log handoff if we want to force order.) |
| `has_listening_device` | Fred picked up Iris's abandoned listening device at her west post. | `InteractableState.action_effects` on the device pickup. | Inventory HUD shows the device; Iris dialogue branch "give it to her" becomes meaningful. |
| `iris_received_listening_device` | Fred has handed the device over to Iris in conversation. | `ConversationEffect` on Iris, gated `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`. | Inventory HUD hides the device (visibility uses `all_of: [has_listening_device], none_of: [iris_received_listening_device]`); Iris promises a transcribed log on the next visit; unlocks her log-handoff conversation path. |
| `iris_returned_transcribed_log` | Iris has given Fred the transcribed log AND read it aloud (thud + westbound footsteps). | `ConversationEffect` on Iris, gated `all_of: [iris_received_listening_device]`, `none_of: [iris_returned_transcribed_log]`. | Inventory HUD shows the transcribed log; the chute lead is now actionable; Vivian's chute-key handoff becomes available. |
| `vivian_gave_chute_room_key` | Vivian has agreed to give Fred the key to the ground-floor chute / laundry staff room. | `ConversationEffect` on Vivian, gated `all_of: [iris_returned_transcribed_log]`. | Inventory HUD shows the key; the chute-room door interactable accepts the "open" action. |
| `chute_room_door_open` | Fred has unlocked and opened the chute-room door on the ground floor. | `InteractableState.action_effects` on the chute-room door, gated `all_of: [vivian_gave_chute_room_key]`. | Door becomes non-blocking; chute-output interactable inside becomes inspectable. |
| `has_siren_cell` | Fred picked up the spent Siren Cell from the chute output. | `InteractableState.action_effects` on the cell-in-chute interactable, gated `all_of: [chute_room_door_open]`. | Inventory HUD shows the Siren Cell; ghostbuster-authentication conversation becomes available. |
| `has_crooked_idol` | Fred extracted the real Crooked Idol from inside the spent cell. | Same pickup action as `has_siren_cell` — Fred immediately spots the idol stashed inside. (Single interaction sets both facts.) | Inventory HUD shows the Crooked Idol; one of the load-bearing inputs to the idol-authentication beat. |
| `idol_authenticated_by_ghostbusters` | At least one Ghostbuster (Mara / Theo / Iris) has confirmed the idol is genuine. | `ConversationEffect` declared on each of Mara / Theo / Iris, gated `all_of: [has_crooked_idol]`. Any one of them can flip the fact. (Otis cannot set it — he plays dumb.) | "One of you did this" deduction; opens the field-book / manual-purge investigation track if it isn't already known. |
| `theo_granted_field_book_permission` | *(existing)* Theo has given Fred permission to take the field book. | *(existing)* `ConversationEffect` on Theo. | The field-book pickup becomes available. |
| `has_field_book` | *(existing)* Fred has the field book. | *(existing)* `InteractableState.action_effects` on the field-book pickup. | Inventory HUD shows the field book; opening the book panel reveals the manual-purge passage. |
| `field_book_revealed_manual_purge` | Fred has read the field-book passage describing manual-purge of a Siren Cell and the resulting violet sub-dermal palm stain. | Set when Fred opens the field-book panel from inventory. (Implementation: hook the book panel's open event to flip this fact, OR — simpler — set it together with `has_field_book` on pickup so reading is implicit.) | Unlocks the "show me your palms" conversation effect on every Ghostbuster. |
| `mara_palms_clean_seen` | Mara has shown her palms; they are unstained. | `ConversationEffect` on Mara, gated `all_of: [field_book_revealed_manual_purge]`, `none_of: [mara_palms_clean_seen]`. | Mechanically clears Mara on the accuse panel for the "manual-purge palms" check. |
| `theo_palms_clean_seen` | Theo has shown his palms; they are unstained. | `ConversationEffect` on Theo, same gate shape. | Clears Theo on the same check. |
| `iris_palms_clean_seen` | Iris has shown her palms; they are unstained. | `ConversationEffect` on Iris, same gate shape. | Clears Iris on the same check. |
| `pemberton_palms_purple_seen` | Otis Pemberton has shown his palms; they are stained sub-dermal violet. | `ConversationEffect` on Otis, gated `all_of: [field_book_revealed_manual_purge]`, `none_of: [pemberton_palms_purple_seen]`. | **The smoking gun.** Required for a Pemberton verdict to land cleanly on the accuse panel. |

### Interactables

**`ghostbusters_gear_cart_inventory`** — placed in the Ghostbusters' room (1201 or 1202, wherever the cart is). Inspect-only.

- State A (default): *"A clipboard hangs from the gear cart with the night's inventory. Two columns: 'Loaded' and 'Used.' One row is conspicuous — a charged Siren Cell logged as loaded, not used. There's no cell on the cart to match it."* → `effects: [theo_cart_cell_missing_noticed = true]`. Passive.
- State B (already inspected, `all_of: [theo_cart_cell_missing_noticed]`): *"The clipboard. The Siren-Cell row still doesn't add up."* → no effects.

**`iris_listening_device`** — placed at Iris's west observation post in the main hallway. Pickup.

- State A (default): *"A compact reel-to-reel listening device sits on a folding stool, slow-spinning. Iris left in a hurry."* → `action_label: "Take it"`, `action_effects: [has_listening_device = true]`, `erase_tile = true` on the props layer.
- State B (already taken): tile suppressed.

**`chute_room_door`** — on the ground floor (south wall, near the chute base — exact tile placement TBD when we lay out the ground floor). Door interactable.

- State A — locked (default, `none_of: [vivian_gave_chute_room_key]`): *"A heavy service door. Locked. No staff key on Fred's ring."* → no action, `blocks_movement = true`.
- State B — can open (`all_of: [vivian_gave_chute_room_key]`, `none_of: [chute_room_door_open]`): *"The chute-room service door. Vivian's staff key fits."* → `action_label: "Yes"`, `action_prompt: "Open the door?"`, `action_effects: [chute_room_door_open = true]`, `update_tile = true` (open-door art), `update_blocks_movement = true`, `blocks_movement = false`, `toast: "Door opened."`.
- State C — open (`all_of: [chute_room_door_open]`): open art, non-blocking, no action.

**`chute_output_cell`** — inside the chute room, at the foot of the chute. Pickup.

- State A (default, `none_of: [has_siren_cell]`): *"A spent Siren Containment Cell lies in the laundry basin under the chute mouth. The back-pressure valve has been manually popped. Something solid is wedged inside the housing — a carved figurine. Heavy. Real stone. The Crooked Idol."* → `action_label: "Take both"`, `action_effects: [has_siren_cell = true, has_crooked_idol = true]`, `erase_tile = true`.
- State B (already taken): tile suppressed.

**`theo_field_book`** — *(existing)*. One small change: when Fred picks up the book, also set `field_book_revealed_manual_purge = true` in `action_effects` (Fred reads the relevant passage as he leaves the desk). Alternatively, keep pickup as-is and hook the book-panel-open event; either works.

### Inventory

Add the following `InventoryItemDefinition`s (and register in `CaseLoader.INVENTORY_IDS`):

- **`listening_device`** — single state visible when `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`. Label: *"Iris's Listening Device"*. Tooltip: *"A slow-spinning reel-to-reel recorder Iris left at her post."*
- **`transcribed_log`** — single state visible when `all_of: [iris_returned_transcribed_log]`. Label: *"Transcribed Log"*. Tooltip: *"Iris's transcription of the device's recording. A thud at 9:11, then footsteps west — toward the chute."*
- **`chute_room_key`** — single state visible when `all_of: [vivian_gave_chute_room_key]`. Label: *"Chute-Room Key"*. Tooltip: *"Vivian's staff key to the ground-floor laundry chute room."*
- **`siren_cell`** — single state visible when `all_of: [has_siren_cell]`. Label: *"Spent Siren Cell"*. Tooltip: *"Charged Siren Containment Cell — back-pressure valve popped. The kind of damage a manual purge leaves behind."*
- **`crooked_idol`** — single state visible when `all_of: [has_crooked_idol]`. Label: *"The Crooked Idol"*. Tooltip: *"The genuine artifact. Auction-block prize. Stashed inside the spent cell."*

New entries also needed in `CaseLoader.INTERACTABLE_IDS` (gear cart, listening device, chute-room door, chute output cell) and `FACT_IDS` (all of the new facts above, plus the existing `theo_granted_field_book_permission` / `has_field_book` already listed).

### Suspect wiring

**Theo** — `assets/suspects/theo.tres` (id: `&"theo"`).

`prompt_blocks` to add:

- `PromptBlock_cell_missing_noticed` — `all_of: [theo_cart_cell_missing_noticed]`, `none_of: [theo_confirmed_cell_present_at_start]`. Text:

  > REACTION BEAT — Fred has spotted that the gear-cart inventory list shows a charged Siren Cell logged as loaded but not used, and there's no cell to match. If Fred raises this, react with genuine surprise — you didn't notice. Say something like: *"Oh — is it missing? That's weird, because I checked everything this morning and it was all full. I'm sure of it. Well, mostly sure. I'm clumsy, so I don't know."* Be willing to be pinned down: yes, the cell was on the cart at the start of watch.

`allowed_effects` to add:

- `ConversationEffect_theo_confirms_cell_present` — `all_of: [theo_cart_cell_missing_noticed]`, `none_of: [theo_confirmed_cell_present_at_start]`, `fact_id = theo_confirmed_cell_present_at_start`. Description:

  > Set this only if Theo clearly confirms a charged Siren Cell was present on the gear cart at the start of the watch (i.e. before the manifestation noises began).

- `ConversationEffect_theo_palms_clean` — `all_of: [field_book_revealed_manual_purge]`, `none_of: [theo_palms_clean_seen]`, `fact_id = theo_palms_clean_seen`. Description:

  > Set this only if Theo clearly shows his palms when Fred asks AND the conversation establishes that his palms are clean / unstained.

(Existing `ConversationEffect_field_book_permission` and existing field-book-related blocks stay as-is. The `ConversationEffect_idol_authenticated` below appears identically on Mara, Theo, and Iris — all three are valid authenticators.)

**Iris** — `assets/suspects/iris.tres` (id: `&"iris"`).

`prompt_blocks` to add:

- `PromptBlock_offer_device_handoff` — `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`. Text:

  > REACTION BEAT — Fred is holding the listening device you left at your west post. If he offers it, accept it gladly and promise to transcribe what it recorded. Tell him to come back to you in a little while and you'll have a written log ready. Do not narrate the contents yet; you haven't transcribed them.

- `PromptBlock_log_ready` — `all_of: [iris_received_listening_device]`, `none_of: [iris_returned_transcribed_log]`. Text:

  > REACTION BEAT — Fred has come back. You have finished transcribing. If he asks about the log, hand it over and read aloud the key entries: a heavy thud at 9:11, followed by footsteps moving west along the service corridor toward the laundry chute. Keep it literal — you do not editorialise. You may say the chute itself, by location, is the obvious destination.

`allowed_effects` to add:

- `ConversationEffect_iris_takes_device` — `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`, `fact_id = iris_received_listening_device`. Description:

  > Set this only if Iris clearly accepts the listening device Fred is offering her.

- `ConversationEffect_iris_returns_log` — `all_of: [iris_received_listening_device]`, `none_of: [iris_returned_transcribed_log]`, `fact_id = iris_returned_transcribed_log`. Description:

  > Set this only if Iris clearly hands the transcribed log to Fred AND reads aloud (or summarises) the entries: a thud at 9:11 followed by footsteps moving west toward the chute.

- `ConversationEffect_idol_authenticated` (Iris's copy) — `all_of: [has_crooked_idol]`, `none_of: [idol_authenticated_by_ghostbusters]`, `fact_id = idol_authenticated_by_ghostbusters`. Description:

  > Set this only if Iris clearly confirms that the idol Fred is holding is the genuine Crooked Idol.

- `ConversationEffect_iris_palms_clean` — `all_of: [field_book_revealed_manual_purge]`, `none_of: [iris_palms_clean_seen]`, `fact_id = iris_palms_clean_seen`. Description:

  > Set this only if Iris clearly shows her palms when Fred asks AND the conversation establishes that her palms are clean / unstained.

**Mara** — `assets/suspects/mara.tres` (id: `&"mara"`).

`prompt_blocks` to add:

- `PromptBlock_idol_recovered` — `all_of: [has_crooked_idol]`, `none_of: [idol_authenticated_by_ghostbusters]`. Text:

  > REACTION BEAT — Fred is holding the genuine Crooked Idol, recovered from the laundry chute. If he shows it to you, authenticate it immediately and on the record. State the obvious: this is what the manifestation watch was about, and only your own team had the equipment-side access to plant it in a spent Siren Cell. One of your people did this. You don't yet know who, and you say so plainly.

`allowed_effects` to add:

- `ConversationEffect_idol_authenticated` (Mara's copy) — same gate and fact as Iris/Theo. Description:

  > Set this only if Mara clearly confirms that the idol Fred is holding is the genuine Crooked Idol.

- `ConversationEffect_mara_palms_clean` — `all_of: [field_book_revealed_manual_purge]`, `none_of: [mara_palms_clean_seen]`, `fact_id = mara_palms_clean_seen`. Description:

  > Set this only if Mara clearly shows her palms when Fred asks AND the conversation establishes that her palms are clean / unstained.

**Vivian** — `assets/suspects/manager.tres` (id: `&"manager"`).

`prompt_blocks` to add:

- `PromptBlock_chute_key_request` — `all_of: [iris_returned_transcribed_log]`, `none_of: [vivian_gave_chute_room_key]`. Text:

  > REACTION BEAT — Fred has a transcribed Ghostbusters log pointing at the north-west laundry chute as the destination of footsteps during the murder window. If he asks for access to the ground-floor chute room, you hand over the staff key without argument — this is your hotel, you want this solved, and you trust him enough by now.

`allowed_effects` to add:

- `ConversationEffect_vivian_gives_chute_key` — `all_of: [iris_returned_transcribed_log]`, `none_of: [vivian_gave_chute_room_key]`, `fact_id = vivian_gave_chute_room_key`. Description:

  > Set this only if Vivian clearly agrees to give Fred the staff key to the ground-floor laundry-chute room.

**Otis Pemberton** — `assets/suspects/otis.tres` (id: `&"otis"`).

`prompt_blocks` to add:

- `PromptBlock_palm_request` — `all_of: [field_book_revealed_manual_purge]`, `none_of: [pemberton_palms_purple_seen]`. Text:

  > REACTION BEAT — Fred now knows about manual purge and the violet sub-dermal stain it leaves on the palms. If he asks to see your hands, you cannot refuse without lighting yourself up — but your palms are stained violet. You may stall, joke, try to redirect, claim it's wine spill or chemical splash from work — but ultimately, if Fred insists, you show your hands and the staining is visible. Do not pretend the stain isn't there. Do not invent a colour.

`allowed_effects` to add:

- `ConversationEffect_pemberton_palms_seen` — `all_of: [field_book_revealed_manual_purge]`, `none_of: [pemberton_palms_purple_seen]`, `fact_id = pemberton_palms_purple_seen`. Description:

  > Set this only if Otis Pemberton clearly shows his palms when Fred asks AND the conversation establishes that the palms are visibly stained violet / purple.

Note: Otis is **not** in `allowed_effects` for `idol_authenticated_by_ghostbusters`. If Fred shows him the idol, his system prompt should have him play dumb / non-committal — he absolutely does not authenticate it for Fred.

### Accusation implications

- An Otis Pemberton verdict on the accuse panel needs `all_of: [pemberton_palms_purple_seen]` at minimum to land cleanly. Without it, the judge should reject with a "you have suspicion but no method-evidence" message.
- A clean Pemberton verdict will additionally weigh the supporting facts: `idol_authenticated_by_ghostbusters` (motive / method-context), `iris_returned_transcribed_log` (placement at chute), `has_siren_cell` (physical evidence of manual-purge method). The judge should be able to acknowledge the whole stack when accepting the accusation.
- Mara / Theo / Iris verdicts should be cleanly rejected once each respective `*_palms_clean_seen` is true.

### Open / TBD

- The user has flagged that one piece of this thread is still missing — placeholder for the additional link to be added in a follow-up pass.
- Implementation question: does `field_book_revealed_manual_purge` fire on book pickup, or on the first time the book panel is opened from inventory? The latter is more elegant ("Fred reads the book"); the former is one less click. Defaulting to **pickup** for simplicity unless we want a separate "read" beat.
- Should there be a "manual override note" or annotated diagram interactable as an additional confirmation surface for the manual-purge mechanism (e.g. a margin scribble in the book that Fred has to inspect explicitly)? Currently folded into the field-book passage.
- Ground-floor level layout TBD — chute room door tile coordinates need a placement pass when we build the ground floor in `world.tscn`.
