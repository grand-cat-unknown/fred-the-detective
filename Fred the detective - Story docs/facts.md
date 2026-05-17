<!-- markdownlint-disable MD024 -->
# Facts Spec

Living spec for the fact-driven gating that ties story beats to game elements. See `AGENTS.md` → "Gating Model" for the underlying primitives (`GateCondition`, `InteractableState`, `ConversationEffect`, `PromptBlock`, inventory `states`).

> Note: each thread reuses the same H3 subheadings (Chain / Fact set / Interactables / Inventory / Suspect wiring / Accusation implications / Open / TBD), so `MD024/no-duplicate-heading` is disabled at the file level above.

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
| `julian_confessed_fraud_not_murder` | Julian has admitted the idol-swap scheme, abandoned it when he saw the Ghostbusters at 1102, and denies the murder. | `ConversationEffect` on Julian, gated `all_of: [mags_confessed_bribe_master_key, julian_fake_idol_seen]`. | Clears Julian on the accuse panel; confirms his scheme required Vance alive and never reached 1102. |

### Interactables

**`room_1103_cigarette`** — placed inside 1103 on a side table / ashtray tile. Inspect-only (not a pickup).

- State A (default): *"A still-lit Lady Finger. Smoke curling. Someone was here moments ago."* → `effects: [lit_cigarette_found_1103 = true]`. Passive, fires on first inspect.
- State B (already inspected, `all_of: [lit_cigarette_found_1103]`): *"The cigarette has burned down. Same brand."* → no effects.

**`mags_cigarette_pouch`** — placed inside 1103 (under a chair / on the bed / near the ashtray). Pickup interactable.

- State A (default): *"A small embroidered pouch. Initials `MM` stitched in red thread. Half-full of Lady Fingers."* → `action_label: "Take it"`, `action_effects: [has_mags_cigarette_pouch = true]`, `erase_tile = true` on the props layer.
- State B (already taken, `all_of: [has_mags_cigarette_pouch]`): tile already erased — entry suppressed.

**`julian_wax_idol`** — placed in 1204 on the writing desk. Inspect-only.

- State A (default): *"A carved figurine on the writing desk. Heavier than it should be — wax beneath the paint. Not the real Anchor Idol."* → `effects: [julian_fake_idol_seen = true]`. Passive.
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

  > REACTION BEAT — Fred knows two things: Mags admitted she gave you a master key, and Fred has identified the wax idol in your room as a forgery. The lawyer act will not hold. Fold. Admit you intended to swap the fake for the real Anchor Idol that night. State plainly that you stepped out with the master key and replica, saw the Ghostbusters setting up at 1102, abandoned the plan, retreated to Suite 1204, and locked yourself in before the watch began. You never entered 1102. You did not kill Vance. You are a thief and a fraud, not a murderer.

`allowed_effects` to add:

- `ConversationEffect_julian_confesses_fraud` — `all_of: [mags_confessed_bribe_master_key, julian_fake_idol_seen]`, `fact_id = julian_confessed_fraud_not_murder`. Description:

  > Set this only if Julian clearly admits he intended to swap a fake idol for the real one, abandoned the plan when he saw the Ghostbusters at 1102, and denies committing the murder.

### Accusation implications

- A Julian verdict on the accuse panel is **available** when any of `julian_fake_idol_seen`, `mags_confessed_bribe_master_key`, or his rivalry with Vance is on the board — i.e. Fred has *something* circumstantial to go on.
- Before `julian_confessed_fraud_not_murder`: judge rejects with a "no kill-window placement" message. (Trap difficulty TBD — soft / medium / hard.)
- After `julian_confessed_fraud_not_murder`: judge rejects Julian cleanly and the deduction view re-labels him as a *forgery* lead, not a *murder* lead.
- Side benefit: Julian's confession explains the fake idol and master key without making him a sound witness or route witness.

### Open / TBD

- Accusation trap severity (soft warning vs. one-strike vs. case-ends-wrong).
- Whether Julian, post-confession, gives any additional detail about the pre-watch hallway setup. He should not corroborate the chute thud.

---

## Thread: The Truth Path (cell → device → log → chute → idol → palms → Pemberton)

The spine of the case. Each step opens the next. By the end, Fred has the genuine Anchor Idol in hand, knows the murder method (manual purge of a Siren Cell) and its forensic signature (sub-dermal violet staining of the palms), and can ask every Ghostbuster to show their hands. Otis Pemberton is the one whose palms are stained.

This thread has no dependencies on the Julian red herring. Julian's post-fold confession clears his theft scheme, but it does not corroborate the thud direction.

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
Open the chute-room door ──► enter, find the spent Siren Cell with the real Anchor Idol stashed inside
        │   (single pickup → `has_evidence`)
        ▼
(Pre-req earlier: ask Theo, then take his field book) ──► field book in inventory contains the manual-purge / violet-palm passage
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
| `has_listening_device` | Fred picked up Iris's abandoned listening device at her west post. | `InteractableState.action_effects` on the device pickup. | Inventory HUD shows the device; Iris dialogue branch "give it to her" becomes meaningful. |
| `iris_received_listening_device` | Fred has handed the device over to Iris in conversation. | `ConversationEffect` on Iris, gated `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`. | Inventory HUD hides the device (visibility uses `all_of: [has_listening_device], none_of: [iris_received_listening_device]`); Iris promises a transcribed log on the next visit; unlocks her log-handoff conversation path. |
| `iris_returned_transcribed_log` | Iris has given Fred the transcribed log AND read it aloud (thud + westbound footsteps). | `ConversationEffect` on Iris, gated `all_of: [iris_received_listening_device]`, `none_of: [iris_returned_transcribed_log]`. | Inventory HUD shows the transcribed log; the chute lead is now actionable; Vivian's chute-key handoff becomes available. |
| `vivian_gave_chute_room_key` | Vivian has agreed to give Fred the key to the ground-floor chute / laundry staff room. | `ConversationEffect` on Vivian, gated `all_of: [iris_returned_transcribed_log]`. | Inventory HUD shows the key; the chute-room door interactable accepts the "open" action. |
| `chute_room_door_open` | Fred has unlocked and opened the chute-room door on the ground floor. | `InteractableState.action_effects` on the chute-room door, gated `all_of: [vivian_gave_chute_room_key]`. | Door becomes non-blocking; chute-output interactable inside becomes inspectable. |
| `has_evidence` *(existing)* | Fred has the spent Siren Cell with the genuine Anchor Idol stashed inside it. Treated as a single piece of physical evidence. | `InteractableState.action_effects` on the chute-output interactable, gated `all_of: [chute_room_door_open]`. | Inventory HUD shows the evidence; combined with `has_field_book` it unlocks the palm-check beat; the Ghostbusters' reaction prompt blocks fire when Fred raises it. |
| `theo_granted_field_book_permission` *(existing)* | Theo has given Fred permission to take the field book. | *(existing)* `ConversationEffect` on Theo. | The field-book pickup becomes available. |
| `has_field_book` *(existing)* | Fred has the field book, which contains the manual-purge passage and its violet-palm signature. | *(existing)* `InteractableState.action_effects` on the field-book pickup. | Inventory HUD shows the field book; combined with `has_evidence`, unlocks the "show me your palms" beat. |
| `mara_palms_shown` | Mara was asked to show her palms and complied. UI presents a photo of clean, unstained hands. | `ConversationEffect` on Mara, gated `all_of: [has_evidence, has_field_book]`, `none_of: [mara_palms_shown]`. | Supporting context: the judge can cite that Mara has been ruled out. |
| `theo_palms_shown` | Theo was asked to show his palms and complied. UI presents a photo of clean, unstained hands. | `ConversationEffect` on Theo, gated `all_of: [has_evidence, has_field_book]`, `none_of: [theo_palms_shown]`. | Supporting context: the judge can cite that Theo has been ruled out. |
| `iris_palms_shown` | Iris was asked to show her palms and complied. UI presents a photo of clean, unstained hands. | `ConversationEffect` on Iris, gated `all_of: [has_evidence, has_field_book]`, `none_of: [iris_palms_shown]`. | Supporting context: the judge can cite that Iris has been ruled out. |
| `pemberton_palms_shown` | Otis Pemberton was asked to show his palms and complied. UI presents a photo of sub-dermal violet staining in his palms and cuticles. | `ConversationEffect` on Otis, gated `all_of: [has_evidence, has_field_book]`, `none_of: [pemberton_palms_shown]`. | **The smoking gun.** One of the three minimum facts the judge requires for a correct verdict (alongside `has_evidence` and `has_field_book`). |

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

- State A (default, `none_of: [has_evidence]`): *"A spent Siren Containment Cell lies in the laundry basin under the chute mouth. The back-pressure valve has been manually popped. Something solid is wedged inside the housing — a carved figurine. Heavy. Real stone. The Anchor Idol."* → `action_label: "Take it"`, `action_effects: [has_evidence = true]`, `erase_tile = true`.
- State B (already taken): tile suppressed.

**`theo_field_book`** — *(existing, unchanged)*. Pickup sets `has_field_book` as today. The manual-purge / violet-palm passage is treated as part of the book — having the book in inventory is the gameplay representation of having read it.

### Inventory

Add the following `InventoryItemDefinition`s (and register in `CaseLoader.INVENTORY_IDS`):

- **`listening_device`** — single state visible when `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`. Label: *"Iris's Listening Device"*. Tooltip: *"A slow-spinning reel-to-reel recorder Iris left at her post."*
- **`transcribed_log`** — single state visible when `all_of: [iris_returned_transcribed_log]`. Label: *"Transcribed Log"*. Tooltip: *"Iris's transcription of the device's recording. A thud at 9:11, then footsteps west — toward the chute."*
- **`chute_room_key`** — single state visible when `all_of: [vivian_gave_chute_room_key]`. Label: *"Chute-Room Key"*. Tooltip: *"Vivian's staff key to the ground-floor laundry chute room."*
- **`evidence`** *(existing)* — repurpose the existing `evidence` inventory entry to read as the spent cell with the genuine Anchor Idol inside. Single state visible when `all_of: [has_evidence]`. Label suggestion: *"Recovered Cell & Idol"*. Tooltip: *"A spent Siren Containment Cell with the genuine Anchor Idol stashed inside. Back-pressure valve popped — manual-purge signature."*

New entries also needed in `CaseLoader.INTERACTABLE_IDS` (gear cart, listening device, chute-room door, chute output cell) and `FACT_IDS` (all of the new facts above, plus the existing `theo_granted_field_book_permission` / `has_field_book` / `has_evidence` already listed).

### Suspect wiring

**Theo** — `assets/suspects/theo.tres` (id: `&"theo"`).

`prompt_blocks` to add:

- `PromptBlock_cell_missing_noticed` — `all_of: [theo_cart_cell_missing_noticed]`. Text:

  > REACTION BEAT — Fred has spotted that the gear-cart inventory list shows a charged Siren Cell logged as loaded but not used, and there's no cell to match. If Fred raises this, react with genuine surprise — you didn't notice. Say something like: *"Oh — is it missing? That's weird, because I checked everything this morning and it was all full. I'm sure of it. Well, mostly sure. I'm clumsy, so I don't know."* Be willing to be pinned down: yes, the cell was on the cart at the start of watch.

- `PromptBlock_idol_recovered` (Theo's copy) — `all_of: [has_evidence]`. Text:

  > REACTION BEAT — Fred is holding the genuine Anchor Idol, recovered from the laundry chute, stashed inside a spent Siren Cell — and the back-pressure valve has been manually popped. If he shows it to you, react with shock and confirm on the record that only your own team had the equipment-side access to plant it in a Siren Cell and execute a manual purge. State plainly: one of your people did this. You don't yet know who, and you say so plainly. Be ready to explain the manual-purge mechanism if Fred asks.

`allowed_effects` to add:

- `ConversationEffect_theo_palms_shown` — `all_of: [has_evidence, has_field_book]`, `none_of: [theo_palms_shown]`, `fact_id = theo_palms_shown`. Description:

  > Set this only if Fred asks Theo to show his palms AND Theo agrees to show them (the UI then presents the photo of clean hands).

(Existing `ConversationEffect_field_book_permission` and existing field-book-related blocks stay as-is.)

**Iris** — `assets/suspects/iris.tres` (id: `&"iris"`).

`prompt_blocks` to add:

- `PromptBlock_offer_device_handoff` — `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`. Text:

  > REACTION BEAT — Fred is holding the listening device you left at your west post. If he offers it, accept it gladly and promise to transcribe what it recorded. Tell him to come back to you in a little while and you'll have a written log ready. Do not narrate the contents yet; you haven't transcribed them.

- `PromptBlock_log_ready` — `all_of: [iris_received_listening_device]`, `none_of: [iris_returned_transcribed_log]`. Text:

  > REACTION BEAT — Fred has come back. You have finished transcribing. If he asks about the log, hand it over and read aloud the key entries: a heavy thud at 9:11, followed by footsteps moving west along the service corridor toward the laundry chute. Keep it literal — you do not editorialise. You may say the chute itself, by location, is the obvious destination.

- `PromptBlock_idol_recovered` (Iris's copy) — `all_of: [has_evidence]`. Text:

  > REACTION BEAT — Fred is holding the genuine Anchor Idol, recovered from the laundry chute, stashed inside a spent Siren Cell with the back-pressure valve manually popped. If he shows it to you, react with shock and confirm on the record that this is what the watch was about. State plainly that only your own team had equipment-side access to plant it in a Siren Cell. One of your people did this. You don't yet know who, and you say so plainly. You may speculate quietly — but stay disciplined; you observe, you don't accuse without evidence.

`allowed_effects` to add:

- `ConversationEffect_iris_takes_device` — `all_of: [has_listening_device]`, `none_of: [iris_received_listening_device]`, `fact_id = iris_received_listening_device`. Description:

  > Set this only if Iris clearly accepts the listening device Fred is offering her.

- `ConversationEffect_iris_returns_log` — `all_of: [iris_received_listening_device]`, `none_of: [iris_returned_transcribed_log]`, `fact_id = iris_returned_transcribed_log`. Description:

  > Set this only if Iris clearly hands the transcribed log to Fred AND reads aloud (or summarises) the entries: a thud at 9:11 followed by footsteps moving west toward the chute.

- `ConversationEffect_iris_palms_shown` — `all_of: [has_evidence, has_field_book]`, `none_of: [iris_palms_shown]`, `fact_id = iris_palms_shown`. Description:

  > Set this only if Fred asks Iris to show her palms AND Iris agrees to show them (the UI then presents the photo of clean hands).

**Mara** — `assets/suspects/mara.tres` (id: `&"mara"`).

`prompt_blocks` to add:

- `PromptBlock_idol_recovered` (Mara's copy) — `all_of: [has_evidence]`. Text:

  > REACTION BEAT — Fred is holding the genuine Anchor Idol, recovered from the laundry chute, stashed inside a spent Siren Cell with the back-pressure valve manually popped. If he shows it to you, react with shock and confirm on the record that this is what the manifestation watch was about. State plainly that only your own team had equipment-side access to plant it inside a Siren Cell and pull a manual purge. One of your people did this. You don't yet know who, and you say so plainly. Take responsibility as lead — this happened on your watch.

`allowed_effects` to add:

- `ConversationEffect_mara_palms_shown` — `all_of: [has_evidence, has_field_book]`, `none_of: [mara_palms_shown]`, `fact_id = mara_palms_shown`. Description:

  > Set this only if Fred asks Mara to show her palms AND Mara agrees to show them (the UI then presents the photo of clean hands).

**Vivian** — `assets/suspects/manager.tres` (id: `&"manager"`).

`prompt_blocks` to add:

- `PromptBlock_chute_key_request` — `all_of: [iris_returned_transcribed_log]`, `none_of: [vivian_gave_chute_room_key]`. Text:

  > REACTION BEAT — Fred has a transcribed Ghostbusters log pointing at the north-west laundry chute as the destination of footsteps during the murder window. If he asks for access to the ground-floor chute room, you hand over the staff key without argument — this is your hotel, you want this solved, and you trust him enough by now.

`allowed_effects` to add:

- `ConversationEffect_vivian_gives_chute_key` — `all_of: [iris_returned_transcribed_log]`, `none_of: [vivian_gave_chute_room_key]`, `fact_id = vivian_gave_chute_room_key`. Description:

  > Set this only if Vivian clearly agrees to give Fred the staff key to the ground-floor laundry-chute room.

**Otis Pemberton** — `assets/suspects/otis.tres` (id: `&"otis"`).

`prompt_blocks` to add:

- `PromptBlock_idol_recovered_deflect` — `all_of: [has_evidence]`. Text:

  > REACTION BEAT — Fred has recovered the Anchor Idol from inside a spent Siren Cell with a manually popped valve. The other three Ghostbusters will openly admit one of your team did this — you cannot publicly disagree without lighting yourself up. Play it cool: agree externally that it must have been someone with equipment-side access, look just as shocked as Mara, throw the blame radius wide ("could have been any of us, including someone outside the team if they had help"), float Theo's clumsiness as a possible angle without committing to it. Never volunteer the manual-purge method by name. Never volunteer that you handled the cart during prep. If Fred asks to see your hands here, jump to your palm-request reaction beat.

- `PromptBlock_palm_request` — `all_of: [has_evidence, has_field_book]`, `none_of: [pemberton_palms_shown]`. Text:

  > REACTION BEAT — Fred has the recovered cell from the chute (back-pressure valve manually popped — unambiguous manual-purge signature). If he asks to see your hands, you cannot refuse without lighting yourself up — but your palms are stained violet. You may stall, joke, try to redirect, claim it's wine spill or chemical splash from work — but ultimately, if Fred insists, you show your hands and the staining is visible. Do not pretend the stain isn't there. Do not invent a colour.

`allowed_effects` to add:

- `ConversationEffect_pemberton_palms_shown` — `all_of: [has_evidence, has_field_book]`, `none_of: [pemberton_palms_shown]`, `fact_id = pemberton_palms_shown`. Description:

  > Set this only if Fred asks Otis to show his palms AND Otis agrees to show them (the UI then presents the photo of violet-stained hands).

### Accusation implications

- **The accuse panel is open to every suspect at all times**, plus a "the ghost did it" option. Fred can attempt an accusation against anyone, including the obviously innocent.
- **Minimum required facts for a *correct* verdict (Otis Pemberton):** `all_of: [has_evidence, has_field_book, pemberton_palms_shown]`. Without all three, no Pemberton verdict will be accepted — the judge rejects with a "you have suspicion but no proof of method" message. (`has_field_book` is required because that is how Fred actually knows what the violet palms *mean*; without it, the photo is just a stain.)
- **Wrong-person accusations are rejected before the LLM judge runs.** Mara, Theo, Iris, Julian, Mags, Leo, Vivian, and "the ghost" are always wrong answers.
- **The LLM only judges final-form Otis accusations.** Once the selected suspect is Otis and the required final facts are present, the judge checks whether the player's method/evidence text actually describes the Siren Cell point-blank manual purge and connects it to Otis's stained palms.
- A wrong accusation made too early is a soft failure — the judge says why and the case continues; no permanent strike unless we add that rule later.

### Open / TBD

- Ground-floor level layout TBD — chute-room door tile coordinates need a placement pass when we build the ground floor in `world.tscn`.

---

## Thread: Service corridor (the missing link)

The staff-only service corridor runs along the north side of the floor, behind the 11xx row. Its entrances are concealed behind curtains — one near the auction hall (west), one near the royal-suite end of the main hallway (east, near 1103). Inside the corridor is the concealed access door into 1102 — Pemberton's actual entry route.

**Design rules (per user):**

- The corridor tiles are **always passable**. The curtains are pure visual misdirection — they *look* impassable but never block movement. An observant / curious player who walks through them mid-investigation discovers the corridor on their own and that is fine, even encouraged.
- "Knowing about the service corridor" is **not a fact**. Vivian just says it out loud when Fred shows her the recovered evidence; it's a conversational hint, not a state flip. The corridor's existence is honest world geography — once you walk in, you've found it.
- The stained gloves *are* a fact-flipping pickup and inventory item. They are supporting evidence, not a progression gate.

### Chain

```text
(Either path takes the player to the same forensic node.)

Path A: Player walks straight through a curtain tile ──► finds the corridor on their own
Path B: Player returns to Vivian with has_evidence ──► Vivian says aloud:
        "There's an access from the Royal Suite behind the curtains —
         check the service hallway."
                     │
                     ▼
        Player explores the corridor, finds the trash bin in the west end,
        picks up the violet-stained gloves
                     │
                     ▼              ──► has_stained_gloves
                     ▼
        Pemberton's geometry alibi gains an extra piece of supporting evidence.
```

### Fact set

| Fact id | Meaning | How it flips | What it unlocks |
| --- | --- | --- | --- |
| `has_stained_gloves` | Fred has picked up the discarded pair of violet-stained work gloves from the trash bin in the west end of the service corridor. | `InteractableState.action_effects` on the trash-bin pickup. | Inventory HUD shows the gloves; gives the judge and dialogue an extra corridor-route support fact. |

### Interactables

**Curtains and the concealed 1102 access** — pure environmental tiles, **not interactables**. Placed in the TileMap as decorative geometry: the curtains look impassable but never block movement; the concealed door into 1102 from the corridor is a tile feature the player notices by walking past it (or by walking through it from the 1102 side). No inspectable, no fact, no resource.

**`stained_gloves_bin`** — placed at the west end of the corridor, near the chute access. Pickup.

- State A (default, `none_of: [has_stained_gloves]`): *"A staff trash bin. Inside: a discarded pair of work gloves, violet staining soaked through the palms and fingers — the same colour the field book describes. Tucked under fresher rubbish."* → `action_label: "Take the gloves"`, `action_effects: [has_stained_gloves = true]`, `erase_tile = true`.
- State B (`all_of: [has_stained_gloves]`): tile suppressed.

### Inventory

Add the following `InventoryItemDefinition`s (and register in `CaseLoader.INVENTORY_IDS`):

- **`stained_gloves`** — single state visible when `all_of: [has_stained_gloves]`. Label: *"Stained Work Gloves"*. Tooltip: *"A discarded pair of work gloves from the service-corridor trash bin. Violet stain soaked through the palms and fingers — consistent with a manual purge."*

New entry also needed in `CaseLoader.INTERACTABLE_IDS` (stained-gloves bin) and `FACT_IDS` (`has_stained_gloves`). Curtains and the concealed 1102 access are not interactables, so no registration needed.

### Suspect wiring

**Vivian** — `assets/suspects/manager.tres` (id: `&"manager"`).

`prompt_blocks` to add:

- `PromptBlock_corridor_hint` — `all_of: [has_evidence]`. Text:

  > REACTION BEAT — Fred is showing you the recovered cell and the Anchor Idol from the chute. React with genuine shock — you didn't realise there was *this much* foul play under your roof. Then think about the geography out loud: the only way that cell crossed the floor without anyone seeing it is the staff service corridor behind the curtains. Tell Fred plainly that there's an access from the Royal Suite behind the curtains, the service hallway runs the whole north side, and he should check it — there may be more clues there. This is a verbal hint, not a hand-off. No object changes hands. You may bring it up again on later visits if it feels natural.

No `allowed_effects` are needed for this beat — Vivian saying the line out loud is the whole point; no fact flip.

**Otis Pemberton** — `assets/suspects/otis.tres` (id: `&"otis"`).

`prompt_blocks` to add:

- `PromptBlock_geometry_pressed` — `all_of: [has_evidence]`. Text:

  > REACTION BEAT — Fred has recovered the cell from the chute, so the corridor geometry is now dangerous for you. If Fred raises the service corridor, the curtains, the chute route, the gloves, or the geometry of your sweep, you cannot keep the lawyer act and the alibi at the same time. Buckle on geometry first — try to claim you lost the reading, doubled back, or that any gloves Fred found are not yours — but do NOT pre-confess the murder. The palm-show is what breaks you, not the geometry. Stay in stage one until Fred forces stage two.

### Accusation implications

- A Pemberton verdict still requires the Truth Path's minimum (`has_evidence` + `has_field_book` + `pemberton_palms_shown`). This thread does not change that bar.
- `has_stained_gloves` is *not* required for the accusation — it makes the verdict feel more complete and lets the judge cite the corridor route, but a player who skips the corridor entirely can still close the case on palms alone.

### Open / TBD

- None on this thread. Tile placement for the curtains, concealed door, and stained-gloves trash can will get pinned when we lay out `world.tscn`.
