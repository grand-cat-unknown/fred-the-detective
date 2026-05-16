# Clue Gating And Discovery Design

This note externalizes the discovery model for the case. The goal is to keep the mystery playable: the character sheets should suggest questions, conversations should suggest places, and places should provide proof.

## Core Principle

Every major truth should move through three layers:

1. **Visible first impression**
   What Fred can notice immediately from a person, room, or object.

2. **Conversation-gated admission**
   What a character only says after Fred asks the right question, has the right evidence, or catches a contradiction.

3. **Environmental confirmation**
   A physical clue that proves, complicates, or narrows what the conversation suggested.

The strongest deductions should require at least two inputs:

```text
Conversation clue + environmental proof = new pressure option
```

Example:

```text
Iris mentions a thud + chute notice = laundry pile becomes meaningful.
Theo admits missing cell + laundry pile search = recovered cell.
Recovered cell + manual sections = murder method.
Mags in housekeeping + Otis sweep claim = false alibi.
Vivian old passages + Mara front-door testimony = hidden route theory.
```

## Character Sheet Rule

The visible character sheet is not the author sheet. It should be a detective notepad made from things Fred can reasonably notice or has already learned.

Use character sheets for:

- First impressions.
- Safe public facts.
- Suspicious but incomplete observations.
- Questions the player might ask next.

Avoid character sheets revealing:

- Hidden routes.
- Actual timelines.
- Author-only motives.
- The solution shape.
- Facts the character is explicitly instructed not to volunteer.

Bad visible hook:

```text
How he knew about the Royal Suite's hidden emergency passage.
```

Better visible hook:

```text
His east-side sweep route and exact checkpoints.
```

The first version tells the player what to solve. The second gives them a question that can become meaningful later.

## Otis Pemberton

### Visible First Impression

- Medical and occult specialist.
- Cold, precise, impatient.
- Everyone seems to defer to his diagnosis.
- Hands show faint violet staining around the palms and cuticles.

Ask about:

- His diagnosis.
- His east-side sweep route.
- His exact checkpoints.
- The stained hands.
- What a Siren Cell does.

### Conversation Gates

**No evidence yet**

If asked about the stains, Otis gives the vague gear-prep alibi:

```text
Theo's gear has been a mess all night. I've been pitching in with prep and capture-tool maintenance.
```

He must not name a specific time, place, spill, or witness.

**Fred has Theo's manual**

Otis becomes colder and more procedural. He dismisses Fred's interpretation of Purge Pigment as amateur reading of technical material.

He can explain general device mechanics, but he should not helpfully connect the mechanics to himself.

**Fred has recovered cell**

Otis retreats to chain-of-custody objections:

- Who handled the cell after discovery?
- Was the scene secured?
- Is Fred qualified to interpret a popped valve?

**Fred has Mags contradiction**

If Fred confronts him with the Housekeeping Room checkpoint, Otis attacks Mags's reliability rather than giving a new story.

### Environmental Confirmation

- Violet-stained gloves in service trash.
- Body wound: precise circular mark.
- Directional violet spray behind the body.
- Recovered Siren Cell: popped back-pressure valve.
- Recovered Siren Cell: flipped Manual Override lever.
- Hidden passage access panel.

### Avoid Leaking

Do not put "hidden emergency passage" in Otis's visible sheet. Let the player reach that through Mara, Vivian, Leo, and the environment.

## Mara Bell

### Visible First Impression

- Team lead.
- Defensive about protocol and liability.
- Certain she held the front of Room 1221.
- Treats the locked front door as the center of the case.

Ask about:

- Front-door visibility.
- Watch assignments.
- What she heard from inside 1221.
- What happened when the noises stopped.
- When Otis arrived to help.

### Conversation Gates

**Initial interview**

Mara confirms:

- At 9:00 PM, watch assignments were set.
- Mara held the front door.
- Iris was assigned west.
- Pemberton was assigned east.
- Nobody entered from the main hallway/front door.

Important: the east/west assignment should happen at 9:00 PM, not "when readings jumped." Pemberton needs the east-side assignment before 9:06 PM.

**Fred has Iris timestamps**

Mara confirms Otis was missing when she and Iris needed help at the door, and he arrived from the west around 9:13 PM.

**Fred has hidden-route evidence**

Mara admits her testimony only rules out the visible hallway and front door. It does not rule out architecture she did not know existed.

### Environmental Confirmation

- Front door damage.
- Front door lock state.
- Hallway sightline.
- Watch-station/protocol note.
- Main hallway map.

### Avoid Leaking

Mara should not solve the hidden passage problem. Her job is to make the locked-room constraint airtight.

## Iris Thorne

### Visible First Impression

- Observation-post witness.
- Keeps exact field notes.
- Calm, literal, uninterested in theories.
- Heard activity through the west wall/service space.

Ask about:

- Exact timestamps.
- What she heard.
- Her west-side position.
- When she joined Mara.
- Which direction Otis arrived from.

### Conversation Gates

**Initial interview**

Iris gives clean observations:

- Noises started around 9:07 PM.
- Noises stopped around 9:10 PM.
- She stepped into the hallway at 9:11 PM.
- Otis was not there.
- Otis arrived from the west around 9:13 PM.

**Asked about unusual sounds**

Iris mentions a heavy metallic thud in the west-side walls after the noises stopped. She can say it could have been the chute, but should not insist.

**Fred has recovered cell**

Iris repeats the sequence more firmly:

```text
Noises stopped. Then the thud. Then Otis arrived from the west.
```

She still should not name the killer.

### Environmental Confirmation

- Iris's field-book page.
- West wall/shared-wall location.
- Chute access.
- Basement laundry bin.

### Avoid Leaking

Iris can be the fair clue source, but not the solution narrator. She reports observations, not deductions.

## Theo Griggs

### Visible First Impression

- Anxious tech.
- Keeps looking at the gear cart and manual.
- Afraid of blame.
- More confident with machinery than people.

Ask about:

- Gear cart.
- Missing equipment.
- Gear log.
- Who handled the cart.
- Borrowing the manual.

### Conversation Gates

**No trust yet**

Theo deflects:

```text
I was doing tech stuff. I mean, mostly with the cart.
```

He should not immediately admit the missing cell unless Fred is friendly, specific, or technically interested.

**Friendly approach or direct gear-log question**

Theo admits a charged Siren Cell was missing before the manifestation noises.

He frames it as his likely mistake:

```text
I thought I miscounted. Or left it in the van. I didn't report it.
```

**Permission gate**

If Fred asks to borrow, take, inspect, or use Theo's manual and gear log, Theo can grant permission and set `theo_granted_field_book_permission`.

**Fred has recovered cell**

Theo matches the cell to the gear-prep log and becomes technically precise.

Only here should he clearly mention that Pemberton was around the cart during prep.

**Fred has Otis stain alibi**

Theo can disprove the vague "gear spill" explanation:

- Gear bag is clean.
- No reported leak.
- No spill on the cart.
- A normal spill would be surface residue, not skin-deep Purge Pigment.

### Environmental Confirmation

- Gear cart with empty slot.
- Theo's field manual.
- Gear log.
- Clean gear bag.
- Recovered cell serial number.

### Avoid Leaking

Theo's manual should not immediately say "Pemberton was around the cart." That should be a later admission after the recovered cell or a direct cart-handling conversation.

## Mags Higgins

### Visible First Impression

- Tired maid.
- Claims she was in basement laundry.
- Smells faintly of smoke.
- Tries to keep her hands busy.

Ask about:

- Basement laundry.
- 12th-floor housekeeping.
- Smoke.
- Master keys.
- Whether anyone opened the Housekeeping Room door.

### Conversation Gates

**Initial interview**

Mags sticks to:

```text
Basement laundry. Linens, mostly.
```

**Fred found smoke/cigarette clue**

Mags admits she was in the 12th-floor Housekeeping Room with the door shut.

**Fred knows Otis claimed the Housekeeping Room checkpoint**

Mags gives the negative-witness statement:

```text
The door never opened. Nobody came in. If he checked that room, I'd have heard him.
```

**Fred has Vane/master-key pressure**

Mags can admit she took a bribe from Julian Vane for a master key. This should be harder than the smoke-break admission.

### Environmental Confirmation

- Smoke haze.
- Warm cigarette butt.
- Lady Finger cigarette brand.
- Housekeeping Room door.
- Ashtray.
- Master-key log gap.
- Money trail or Vane testimony.

### Avoid Leaking

The visible sheet can mention smoke, but not "Lady Finger cigarettes" or "the exact room Pemberton claimed to check" until discovered.

## Julian Vane

### Visible First Impression

- Bitter collector.
- Lost the Anchor Idol by one bid.
- Claims he was in the bar with a dry martini.
- Arrogant enough to sound guilty.

Ask about:

- Bar alibi.
- Rivalry with Vance.
- Idol replica.
- Sedative.
- Master key.
- Whether his plan required Vance alive.

### Conversation Gates

**Initial interview**

Julian stays with the bar alibi.

**Leo places Julian on the 12th floor**

Julian admits he was upstairs but not inside 1221.

**Fred finds replica or sedative**

Julian admits the theft plan:

- Chloroform Vance.
- Swap real idol for wax replica.
- Leave before Vance wakes.

**Fred has cell/body evidence**

Julian becomes relieved the murder method does not match his sedative, but terrified his theft plan still looks damning.

He should insist:

```text
My plan required Vance alive.
```

### Environmental Confirmation

- Wax idol replica.
- Chloroform vial.
- Master key.
- Leo's elevator sighting.
- Bar record that weakens or disproves his alibi.

### Avoid Leaking

Julian should look guilty early. The game should separate "planned theft" from "murder method" through evidence, not through his first visible sheet.

## Vivian Marlowe

### Visible First Impression

- Hotel manager.
- Controls records.
- Protects reputation.
- Knows the Royal Suite and hotel policies.

Ask about:

- Key logs.
- Vance's privacy request.
- Royal Suite.
- Old construction.
- Service corridors.

### Conversation Gates

**Asked about key logs**

Vivian confirms no official master-key checkout was logged for Suite 1221 during the ritual window.

**Asked about old construction**

Vivian confirms The Grandview is a converted family castle with old emergency passages, many sealed or poorly documented.

**Asked about Pemberton after old-passage clue**

Vivian admits Pemberton was a childhood friend who knew old parts of the building unusually well.

**Fred found hidden panel or passage**

Vivian can confirm the route fits old family architecture and that Pemberton had more reason than most to know it.

### Environmental Confirmation

- Key log.
- Guest privacy request.
- Hotel archive/map fragment.
- Royal Suite renovation record.
- Service corridor notice.

### Avoid Leaking

Vivian's visible sheet should not immediately reveal childhood history with Pemberton. Keep that for old-construction or Pemberton-specific questioning.

## Leo Rossi

### Visible First Impression

- Veteran bellhop.
- Delivered sparkling water at 8:50 PM.
- Knows guest routines.
- Polite and observant.

Ask about:

- Vance's mood.
- Vance's routine.
- Elevator bank.
- Who was around before 9:00 PM.
- Hotel service habits.

### Conversation Gates

**Asked about Vance**

Leo confirms Vance was agitated and planned to check out tomorrow morning with the idol.

**Asked about Vance's routine**

Leo confirms the 9:00 to 9:45 PM meditation habit was public hotel folklore.

**Asked about elevators / 9:00 PM**

Leo places Julian Vane near the elevators on the 12th floor.

**Asked about odd behavior**

Leo mentions Pemberton checking his watch repeatedly.

**Asked about old construction**

Leo mentions old panic passages and service oddities as hotel history, but does not know exact usable routes.

### Environmental Confirmation

- Delivery log.
- Elevator sightline.
- Bar/elevator timing.
- Laundry/chute policy notice.

### Avoid Leaking

Leo can open several paths, but he should not connect them. He gives routine, not theory.

## Suggested Fact Gates

These facts can support a cleaner discovery flow:

```text
iris_mentioned_thud
theo_admitted_missing_cell
theo_manual_taken
cell_recovered
cell_inspected
mags_smoke_found
mags_admitted_housekeeping
pemberton_claimed_housekeeping_checkpoint
vivian_confirmed_old_passages
leo_placed_julian
julian_admitted_swap_plan
otis_stain_alibi_given
theo_disproved_gear_spill
hidden_passage_found
```

Possible derived pressure gates:

```text
can_search_laundry = iris_mentioned_thud OR vivian_described_chute OR leo_described_chute_routine
can_press_theo_on_cell = has_field_book OR cell_recovered
can_press_mags_on_housekeeping = mags_smoke_found OR pemberton_claimed_housekeeping_checkpoint
can_press_otis_on_route = mags_admitted_housekeeping AND pemberton_claimed_housekeeping_checkpoint
can_press_otis_on_method = cell_inspected AND has_field_book
can_form_hidden_route_theory = mara_front_door_confirmed AND vivian_confirmed_old_passages
```

## Discovery Chain Draft

This is one possible order. The player should be able to approach it flexibly, but the clue economy should preserve these dependencies.

1. Mara establishes the front-door impossibility.
2. Iris establishes the timing and west-side thud.
3. Theo establishes that a Siren Cell was missing before the noises.
4. The manual explains what Siren Cells can and cannot do.
5. The thud points Fred toward the chute/laundry.
6. The recovered cell proves deliberate point-blank use.
7. The body/wall evidence rules out a normal Class-5 manifestation.
8. Vivian and Leo establish that old passages exist.
9. Mara's testimony plus old-passage evidence creates the hidden-route theory.
10. Mags proves Pemberton did not check the ordinary Housekeeping Room checkpoint.
11. Theo disproves Otis's gear-spill alibi.
12. Otis's stained hands, the manual, the recovered cell, and the false route combine into the accusation.

## Implementation Notes

- Prefer `InteractableState` resources for environmental clues and fact changes.
- New one-off objects should live in `assets/interactables/<object_id>.tres`.
- New facts should live in `assets/facts/<fact_id>.tres`.
- New inventory evidence should live in `assets/inventory/<item_id>.tres`.
- Conversation gates can be represented with `ConversationEffect` and `PromptBlock` resources.
- Avoid putting author-only truth in `sheet_summary`, `sheet_details`, or `sheet_hooks`, because those are currently shown directly in the dialogue panel.

## Current Cleanup Targets

- Mara: revise assignment timing to 9:00 PM.
- Otis sheet: remove direct hidden-passage hook from visible sheet.
- Vivian sheet: move childhood/Pemberton relationship behind a gate.
- Leo sheet: avoid listing Julian and passage knowledge as immediate visible facts.
- Mags sheet: keep smoke as a visible clue, but gate Lady Finger and exact Housekeeping Room implications.
- Theo manual: remove the immediate Pemberton cart note, or gate it behind recovered-cell conversation.
- Laundry pile: consider gating the search or stronger find behind a thud/chute clue.
