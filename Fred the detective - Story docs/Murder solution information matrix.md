# Murder Solution Information Matrix

This document turns the current story plan into an implementation-facing clue matrix. The purpose is to answer:

- What information is required to solve the murder?
- What information is required to clear red herrings?
- Who or what holds that information?
- How does the player access it?
- What gate controls it?
- What fact/state should unlock next?

Use this as a planning checklist before creating game states, interactables, inventory items, and conversation gates.

## Core Solution Requirements

To solve the case fairly, the player needs to prove five big things:

1. Felix died while the front door was watched.
2. The "haunting" was staged during the noisy window.
3. A missing Siren Cell is connected to the murder and later recovered.
4. Otis's route and alibi do not hold up.
5. The red herrings explain other suspicious behavior without explaining the murder.

The accusation should not rely on a single clue. It should require a bundle:

```text
front door impossible
+ west-side thud/device
+ missing/recovered Siren Cell
+ manual/glove/stain evidence
+ Otis false route/checkpoint
+ red herrings cleared
= Otis as killer
```

## Required Proof Checklist

| Proof Needed | Why It Matters | Minimum Fair Inputs | Unlocks |
| --- | --- | --- | --- |
| Felix was alive/normal shortly before the incident | Establishes the death happened during the watch window | Leo's pre-incident service account; Vivian intro | Player understands the relevant timeframe |
| Felix's 9:00 meditation was predictable | Explains why the killer and thief could plan around the same window | Leo's routine testimony; possibly hotel routine note | Julian and Otis both had timing opportunity |
| Mara watched the front door | Creates the locked-room constraint | Mara interview; front-door/hallway environment | Player must look for another route or trick |
| Assignments were set at 9:00 PM | Gives Otis east-side cover before the murder window | Mara interview | Otis had a reason to be away from the front door |
| Iris was on the west side | Places a reliable witness near the later thud | Iris interview; west-side device location | Listening device clue becomes relevant |
| Iris dropped her scan when the noise spiked | Explains why the device was left behind | Iris interview | `iris_device_known` / find device objective |
| Listening device recorded a strong west-side thud | Points toward chute/laundry disposal | Recover device; return to Iris | Laundry/chute search becomes fair |
| A Siren Cell was missing before the noises | Connects team equipment to the murder window | Theo trust/gear-log conversation | Player can connect recovered cell to missing gear |
| The recovered cell is the missing cell | Turns disposal clue into murder-method clue | Laundry/bin search; Theo serial confirmation | Cell inspection and method pressure |
| Manual explains Manual Purge/stain rules | Makes violet hands/gloves meaningful | Theo permission; field manual inventory | Otis stain alibi can be challenged |
| Stained gloves exist | Physical proof of manual cell use by a human | Service trash/environmental clue | Strengthens accusation against Otis |
| Otis's hands are stained | Visible suspicious fact | Otis visible sheet/interview | `otis_stain_alibi_given` |
| Otis gives vague gear-prep alibi | Creates a lie to break | Ask Otis about stains | Theo can disprove gear-spill explanation |
| Theo can disprove gear-spill alibi | Removes innocent explanation for Otis's stains | Otis stain alibi + Theo gear knowledge | `theo_disproved_gear_spill` |
| Pemberton was delayed arriving at door | Shows his movement does not match the emergency | Iris/Mara timing | Pressure Otis on route |
| Otis arrived from the west despite east assignment | Creates direction contradiction | Iris and Mara | Hidden/disposal route theory |
| Mags was in the Housekeeping Room with door shut | Makes her a negative witness | Smoke clue + Mags admission | Can challenge Otis's checkpoint claim |
| Otis claimed a checkpoint Mags contradicts | Breaks his route/alibi | Otis route claim + Mags testimony | `can_press_otis_on_route` |
| Julian planned theft, not murder | Clears the major red herring | Fake idol + Mags master-key confession + Julian confession | Julian suspiciousness explained |
| Vivian does not know the method | Keeps manager from being false solution source | Vivian intro/conversation | Player looks to witnesses/evidence |
| Leo was not present for the incident | Prevents overusing Leo as event witness | Leo conversation/service route note | Limits Leo to pre-incident facts |

## Full Information Matrix

| Info ID | Information | Category | Holder / Source | How Available | Gate / Unlock Condition | Suggested Fact(s) | Enables |
| --- | --- | --- | --- | --- | --- | --- | --- |
| intro_case | Felix Vance died in the Royal Suite; Fred was called in | Setup | Vivian | Opening conversation | None / start of case | `vivian_intro_complete` | Player understands premise |
| hotel_haunted_business | The Grandview is famous for hauntings; a haunted death may attract business | Context / motive color | Vivian; brochure | Vivian publicity question; Royal Suite marketing interactable | Ask Vivian about hotel reputation or inspect brochure | `hotel_haunted_reputation_known` | Frames Vivian as uneasy but not solution-critical |
| vivian_not_method_source | Vivian knows nothing useful about method/route/killer | Boundary | Vivian | Ask about murder mechanics | None, but should redirect to evidence | `vivian_denies_method_knowledge` | Prevents manager from carrying solution |
| vance_normal_before | Felix seemed basically fine before the incident | Timeline | Leo | Conversation | Ask Leo about Vance | `leo_vance_normal_before` | Establishes death window |
| vance_meditation_public | Felix's 9:00 to 9:45 meditation was public hotel folklore | Opportunity | Leo; routine note | Conversation or environmental note | Ask Leo about routine | `vance_meditation_known` | Explains why plans target 9:00 |
| evening_mood | Julian tense, Pemberton anxious, but neither proves guilt | Red herring / color | Leo | Conversation | Ask Leo about people before 9:00 | `leo_evening_mood_known` | Adds suspicion without solving |
| leo_not_present | Leo was not present for the actual event | Boundary | Leo; service log | Conversation or service log | Ask Leo about incident | `leo_not_present_for_incident` | Prevents Leo from being core witness |
| team_presence | Ghostbusters were present for the auction/idol watch | Setup | Vivian; Mara | Opening; Mara plan conversation | None | `team_presence_known` | Explains why team and gear are onsite |
| team_roles | Mara lead, Iris readings, Theo tech, Pemberton medical/occult | Orientation | Mara | Conversation | Ask Mara about team | `team_roles_known` | Helps player know whom to ask |
| watch_assignments | At 9:00, Mara held front, Iris west, Pemberton east, Theo cart | Timeline / opportunity | Mara | Conversation | Ask Mara about plan/watch | `watch_assignments_known` | Establishes Otis east cover |
| front_door_watched | Mara watched 1221's front door; nobody entered from hallway | Locked-room proof | Mara; hallway/front door | Conversation plus environment | Initial Mara interview; inspect door/hallway | `mara_front_door_confirmed` | Forces alternate route theory |
| sudden_failure | Team expected warning readings; everything happened suddenly | Context | Mara | Conversation | Ask Mara about readings/failure | `mara_sudden_failure_known` | Explains Mara guilt and confusion |
| otis_missing_at_door | Mara/Iris needed help; Otis was not there at first | Timeline contradiction | Mara; Iris | Conversation | Ask about forcing door / Iris timestamps | `otis_absent_from_initial_door_attempt` | Pressure Otis on route |
| otis_arrived_west | Otis arrived from the west after being assigned east | Route contradiction | Iris; Mara | Conversation | Ask Iris/Mara about arrival direction | `otis_arrived_from_west` | Supports false route/disposal path |
| iris_west_watch | Iris was scanning the west side and found nothing until the spike | Timeline / position | Iris | Conversation | Initial Iris interview | `iris_west_watch_known` | Makes west-side device fair |
| iris_device_left | Iris dropped/left her listening device when the noise spiked and ran to door | Environmental lead | Iris | Conversation | Ask Iris about west-side scan/device | `iris_device_known` | Tells player to search west side |
| iris_device_found | Fred finds Iris's west-side listening/scanning device | Environmental clue | West-side route/object | Interactable pickup | `iris_device_known` or free exploration | `iris_device_found` | Can return to Iris |
| iris_device_returned | Fred gives the device back to Iris | Conversation gate | Iris | Conversation/action | `iris_device_found` | `iris_device_returned` | Iris can interpret data |
| iris_thud_confirmed | Device captured strong localized west-side thud after noise stopped | Disposal clue | Iris + device | Conversation after return | `iris_device_returned` | `iris_interpreted_device`, `iris_mentioned_thud` | Unlocks chute/laundry search |
| chute_notice | Laundry/chute route can hold dropped items until morning | Environmental clue | Chute notice/service area | Inspect notice | None or after thud clue | `chute_notice_read` | Makes laundry bin search logical |
| laundry_search | Search basement laundry/bin for object dropped from west side | Environmental action | Laundry pile/bin | Interactable state | `iris_interpreted_device` OR `chute_notice_read` | `can_search_laundry` | Leads to recovered cell |
| cell_recovered | Recovered Siren Cell from laundry/bin | Physical proof | Laundry bin | Interactable/action | `can_search_laundry` | `cell_recovered` | Inspect cell; confront Theo |
| cell_inspected | Cell has popped valve / Manual Override evidence | Method proof | Recovered cell | Inventory/interactable inspection | `cell_recovered` | `cell_inspected` | Connects to manual and Otis |
| theo_missing_cell | A charged Siren Cell was missing before the noises | Method timeline | Theo | Conversation | Friendly approach OR direct gear-log question | `theo_admitted_missing_cell` | Missing cell becomes suspicious |
| theo_manual_permission | Theo permits Fred to inspect/take field manual/log | Inventory gate | Theo | Conversation | Ask to borrow/inspect manual | `theo_granted_field_book_permission`, `theo_manual_taken` | Manual evidence unlocks method |
| manual_purge_rules | Manual Purge can stain through gloves; violet pigment lasts | Method rule | Theo field manual | Inventory inspection | `theo_manual_taken` | `manual_purge_rules_known` | Otis stain becomes incriminating |
| theo_serial_match | Recovered cell matches Theo's gear log | Chain of custody | Theo + gear log | Conversation | `cell_recovered` and `theo_admitted_missing_cell` | `theo_matched_cell_serial` | Confirms recovered cell is team cell |
| pemberg_cart_access | Pemberton was around the cart during prep | Late pressure clue | Theo | Conversation | `cell_recovered` or serial match | `pemberton_cart_access_known` | Narrows who could take cell |
| otis_stained_hands | Otis has violet-stained palms/cuticles | Suspect physical clue | Otis visible sheet/interview | Immediate observation | None | `otis_stains_observed` | Ask Otis for alibi |
| otis_stain_alibi | Otis claims vague gear-prep contamination | Lie / weak alibi | Otis | Conversation | Ask about stained hands | `otis_stain_alibi_given` | Theo can disprove it |
| clean_gear_bag | Gear bag/cart has no spill matching Otis's story | Alibi breaker | Theo; gear cart | Conversation/environment | `otis_stain_alibi_given` | `theo_disproved_gear_spill` | Removes innocent stain explanation |
| stained_gloves | Violet-stained gloves in service trash | Physical proof | Service trash object | Interactable | Manual/stain knowledge or exploration | `stained_gloves_found` | Strong method proof against Otis |
| hidden_route_found | Hidden/service route evidence exists | Route proof | Environment | Interactable/area discovery | Could require front-door contradiction or exploration | `hidden_passage_found` | Explains locked-room trick |
| otis_route_claim | Otis claims east sweep/checkpoints | Suspect alibi | Otis | Conversation | Ask about route/checkpoints | `pemberton_claimed_housekeeping_checkpoint` | Mags can contradict |
| smoke_clue_found | Fresh smoke/cigarette in clean room | Environmental clue | Housekeeping Room | Inspect room/cigarette/ashtray | None or after asking Mags | `mags_smoke_found` | Press Mags |
| specific_cigarette | Lady Finger/specific cigarette brand links to Mags | Environmental clue | Housekeeping Room; Mags | Inspect + ask | `mags_smoke_found` | `mags_cigarette_linked` | Stronger Mags pressure |
| mags_housekeeping_admit | Mags admits she was in Housekeeping Room with door shut | Route witness | Mags | Conversation | `mags_smoke_found` or `mags_cigarette_linked` | `mags_admitted_housekeeping` | Can contradict Otis checkpoint |
| mags_job_safety | Fred promises not to get Mags fired through hotel management | Conversation gate | Fred/Mags | Dialogue choice/effect | Mags pressured about smoking/job | `mags_job_safety_promised` | Unlock master-key confession |
| mags_master_key | Mags admits Julian paid/requested a master key | Red herring key | Mags | Conversation | `mags_admitted_housekeeping` AND `mags_job_safety_promised` | `mags_confessed_master_key` | Press Julian |
| mags_negative_witness | Mags says nobody opened the Housekeeping Room door | Route contradiction | Mags | Conversation | `mags_admitted_housekeeping` AND `pemberton_claimed_housekeeping_checkpoint` | `mags_denied_pemberton_checkpoint` | Breaks Otis route claim |
| julian_rivalry | Julian lost idol by one bid; rivalry was respectful, not murderous | Red herring context | Julian; Leo | Conversation | Ask Julian/Leo about rivalry | `julian_respectful_rivalry_claim` | Softens murder motive |
| julian_relief | Julian is scared and relieved because if he had won, he might be dead | Red herring context | Julian | Conversation | Ask about Felix/death/rivalry | `julian_relief_known` | Makes him human, not killer |
| fake_idol_found | Fake idol/replica found in Julian's room | Environmental red herring | Julian room | Interactable | Search room / access allowed by design | `julian_fake_idol_found` | Ask Julian about replica |
| julian_replica_excuse | Julian claims replica is just admiration/collector obsession | First lie | Julian | Conversation | `julian_fake_idol_found` without `mags_confessed_master_key` | `julian_replica_excuse_given` | Await master-key proof |
| julian_swap_confession | Julian admits he planned to swap fake idol for real idol | Red herring cleared | Julian | Conversation | `julian_fake_idol_found` AND `mags_confessed_master_key` | `julian_admitted_swap_plan` | Clears Julian from murder method |
| julian_not_murder | Julian insists he wanted idol, not Felix dead | Red herring cleared | Julian + cell evidence | Conversation | `julian_admitted_swap_plan` and `cell_inspected` | `julian_murder_motive_weakened` | Separates theft from murder |
| accusation_ready | Otis can be accused fairly | Endgame | Derived state | Case logic | Required proof bundle met | `can_accuse_otis` | Finale |

## Red Herring Clearance Matrix

| Red Herring | Why It Looks Suspicious | Required To Clear | Holder / Source | Gate | Resulting State |
| --- | --- | --- | --- | --- | --- |
| Vivian benefits from haunted publicity | Haunted death could bring business | She called Fred, knows only intro/records, cannot explain method or route | Vivian; brochure | Ask about publicity and murder mechanics | `vivian_not_solution_source` |
| Leo saw pre-incident tension | He can describe people acting nervous | He was not present for the incident and cannot place people during murder window | Leo; service log | Ask about incident itself | `leo_not_present_for_incident` |
| Mara led the failed watch | Her plan failed and she feels guilty | She reliably watched the door and gives clean assignments/team roles | Mara; door/hall | Ask about plan, team, front door | `mara_front_door_confirmed` |
| Iris heard/records the thud | She may sound like she is solving it | Her device only proves a thud; it does not identify killer or object | Iris + device | Return device to Iris | `iris_interpreted_device` |
| Theo lost dangerous equipment | Missing cell could look like negligence/murder | He feared blame; recovered cell + log show it was taken/used | Theo; gear log; recovered cell | Friendly/direct gear question; cell recovery | `theo_matched_cell_serial` |
| Mags lied about location | She was not in basement and took money | She hid smoking/job risk and master-key bribe, but her truth breaks Otis route | Mags; smoke clue | Smoke clue + job-safety promise | `mags_confessed_master_key` |
| Julian wanted the idol | He had motive and fake idol | He planned theft, not murder; cell method does not match his plan | Julian; fake idol; Mags | Fake idol + master-key confession + cell evidence | `julian_admitted_swap_plan` |

## Proposed Fact And State List

These are candidate fact IDs. They can be renamed to match project conventions, but the dependency shape should remain clear.

### Setup And Orientation

```text
vivian_intro_complete
hotel_haunted_reputation_known
vivian_denies_method_knowledge
team_presence_known
team_roles_known
vance_meditation_known
leo_vance_normal_before
leo_evening_mood_known
leo_not_present_for_incident
```

### Locked Room And Timeline

```text
watch_assignments_known
mara_front_door_confirmed
mara_sudden_failure_known
otis_absent_from_initial_door_attempt
otis_arrived_from_west
iris_west_watch_known
iris_device_known
iris_device_found
iris_device_returned
iris_interpreted_device
iris_mentioned_thud
chute_notice_read
can_search_laundry
```

### Siren Cell Method

```text
theo_admitted_missing_cell
theo_granted_field_book_permission
theo_manual_taken
cell_recovered
cell_inspected
manual_purge_rules_known
theo_matched_cell_serial
pemberton_cart_access_known
otis_stains_observed
otis_stain_alibi_given
theo_disproved_gear_spill
stained_gloves_found
```

### Route Contradiction

```text
hidden_passage_found
pemberton_claimed_housekeeping_checkpoint
mags_smoke_found
mags_cigarette_linked
mags_admitted_housekeeping
mags_denied_pemberton_checkpoint
can_press_otis_on_route
```

### Red Herrings

```text
mags_job_safety_promised
mags_confessed_master_key
julian_respectful_rivalry_claim
julian_relief_known
julian_fake_idol_found
julian_replica_excuse_given
julian_admitted_swap_plan
julian_murder_motive_weakened
```

### Endgame Derived States

```text
can_press_theo_on_cell = cell_recovered OR theo_manual_taken
can_press_mags_on_housekeeping = mags_smoke_found OR mags_cigarette_linked
can_press_mags_on_master_key = mags_admitted_housekeeping AND mags_job_safety_promised
can_press_julian_on_replica = julian_fake_idol_found
can_press_julian_on_swap_plan = julian_fake_idol_found AND mags_confessed_master_key
can_press_otis_on_method = cell_inspected AND manual_purge_rules_known
can_press_otis_on_route = mags_denied_pemberton_checkpoint AND otis_arrived_from_west
can_form_hidden_route_theory = mara_front_door_confirmed AND hidden_passage_found
can_accuse_otis = mara_front_door_confirmed AND iris_interpreted_device AND cell_inspected AND manual_purge_rules_known AND stained_gloves_found AND theo_disproved_gear_spill AND mags_denied_pemberton_checkpoint AND julian_admitted_swap_plan
```

## Suggested Interactables And Inventory

| Object / Item | Type | First State | Later State(s) | Facts Applied |
| --- | --- | --- | --- | --- |
| Royal Suite front door | Interactable | Damaged/locked, inspected normally | Stronger note after Mara confirms door watch | `front_door_inspected`, possibly `mara_front_door_confirmed` if paired with conversation |
| Hallway sightline | Interactable | Shows Mara could watch front door | None | `hallway_sightline_checked` |
| West-side listening device | Interactable / inventory | Unknown device, cannot interpret | After Iris mentions it: "Iris's scanner"; after returned: removed or marked returned | `iris_device_found`, `iris_device_returned` |
| Iris device log | Inventory/state | Hidden until Iris interprets | Shows strong thud timing | `iris_interpreted_device` |
| Chute notice | Interactable | Explains laundry chute schedule | More meaningful after thud | `chute_notice_read` |
| Basement laundry bin | Interactable | Ordinary laundry | Searchable after thud/chute clue; yields cell | `cell_recovered` |
| Recovered Siren Cell | Inventory | Recovered but not understood | Inspected: popped valve/manual override; Theo: serial match | `cell_inspected`, `theo_matched_cell_serial` |
| Theo field manual | Inventory | Hidden until permission | Shows Manual Purge and Purge Pigment rules | `theo_manual_taken`, `manual_purge_rules_known` |
| Gear cart | Interactable | Empty slot can be noticed | Stronger after Theo admits missing cell | `gear_cart_empty_slot_seen` |
| Clean gear bag | Interactable | Ordinary clean equipment | Disproves Otis's spill story after alibi | `theo_disproved_gear_spill` |
| Service trash | Interactable | Trash | After manual/stain clue, contains stained gloves | `stained_gloves_found` |
| Housekeeping Room ashtray/cigarette | Interactable | Fresh smoke in clean room | Links to Mags after conversation | `mags_smoke_found`, `mags_cigarette_linked` |
| Housekeeping Room door | Interactable | Door/room state | Supports "door stayed shut" testimony | `housekeeping_room_checked` |
| Master-key confession note | State/inventory note | Hidden | Created after Mags confession | `mags_confessed_master_key` |
| Julian's fake idol | Interactable / inventory | Replica found | Becomes swap-plan proof after master-key confession | `julian_fake_idol_found` |
| Royal Suite brochure | Interactable | Haunted-hotel marketing | Supports Vivian publicity tension | `hotel_haunted_reputation_known` |
| Service log / Leo route note | Interactable | Leo was elsewhere | Clears Leo from event witness role | `leo_not_present_for_incident` |
| Hidden route/panel | Interactable | Hidden/unclear | Found after route pressure or exploration | `hidden_passage_found` |

## Conversation Gate Checklist

| Character | Gate | Opens When | Sets Fact | New Player Action |
| --- | --- | --- | --- | --- |
| Vivian | Intro complete | Start / first talk | `vivian_intro_complete` | Talk to Mara/Leo/team |
| Vivian | Haunted publicity admission | Ask about hotel reputation | `hotel_haunted_reputation_known` | Clears Vivian as motive-color, not method |
| Leo | Meditation routine | Ask about Vance/routine | `vance_meditation_known` | Understand 9:00 opportunity |
| Leo | Not present | Ask about incident | `leo_not_present_for_incident` | Stop using Leo as event witness |
| Mara | Watch plan | Ask about assignments | `watch_assignments_known`, `mara_front_door_confirmed` | Question Iris/Otis route |
| Mara | Team roles | Ask about team | `team_roles_known` | Direct player to Theo/Iris/Pemberton |
| Iris | Device lead | Ask about west-side scan | `iris_device_known` | Search west-side area |
| Iris | Device interpretation | `iris_device_found` | `iris_interpreted_device`, `iris_mentioned_thud` | Search chute/laundry |
| Theo | Missing cell admission | Friendly/direct gear question | `theo_admitted_missing_cell` | Connect cell to team gear |
| Theo | Manual permission | Ask to inspect/take manual | `theo_manual_taken` | Inspect method rules |
| Theo | Serial match | `cell_recovered` | `theo_matched_cell_serial` | Pressure method/chain |
| Theo | Disprove spill | `otis_stain_alibi_given` | `theo_disproved_gear_spill` | Pressure Otis |
| Mags | Housekeeping admission | `mags_smoke_found` | `mags_admitted_housekeeping` | Ask about door/checkpoint |
| Mags | Job-safety promise | Dialogue choice after pressure | `mags_job_safety_promised` | Ask about master keys |
| Mags | Master-key confession | `mags_job_safety_promised` and `mags_admitted_housekeeping` | `mags_confessed_master_key` | Pressure Julian |
| Mags | Negative witness | `pemberton_claimed_housekeeping_checkpoint` and `mags_admitted_housekeeping` | `mags_denied_pemberton_checkpoint` | Break Otis route |
| Julian | Replica excuse | `julian_fake_idol_found` only | `julian_replica_excuse_given` | Need master-key proof |
| Julian | Swap confession | `julian_fake_idol_found` and `mags_confessed_master_key` | `julian_admitted_swap_plan` | Clear theft red herring |
| Otis | Stain alibi | Ask about hands | `otis_stain_alibi_given` | Ask Theo/check gear |
| Otis | Route claim | Ask about sweep/checkpoints | `pemberton_claimed_housekeeping_checkpoint` | Ask Mags about door |
| Otis | Method pressure | `cell_inspected`, `manual_purge_rules_known`, `stained_gloves_found` | Endgame pressure | Accuse when route also broken |

## Accusation Bundle

The game should only present a confident accusation when these clusters are all satisfied:

| Cluster | Required Facts | Meaning |
| --- | --- | --- |
| Locked room | `mara_front_door_confirmed` | Killer did not use visible front door |
| Timeline/direction | `otis_arrived_from_west`, `otis_absent_from_initial_door_attempt` | Otis moved wrong / arrived late |
| Disposal path | `iris_interpreted_device`, `cell_recovered` | Strong west-side thud led to recovered cell |
| Murder method | `cell_inspected`, `manual_purge_rules_known`, `stained_gloves_found` | Siren Cell was used by a human |
| Otis stain lie | `otis_stain_alibi_given`, `theo_disproved_gear_spill` | His innocent explanation fails |
| Route lie | `pemberton_claimed_housekeeping_checkpoint`, `mags_denied_pemberton_checkpoint` | His sweep story fails |
| Red herring cleared | `julian_admitted_swap_plan` | Julian's suspicious plan is theft, not murder |

Minimum endgame expression:

```text
Otis had cover to be away east, arrived late from the west, lied about his sweep, had unexplained Purge Pigment stains, and the missing Siren Cell was recovered from the west-side disposal path. The gloves/manual/cell prove human Manual Purge use; Mags and Theo break his route and stain alibis; Julian's fake-idol plot explains the theft red herring without explaining the murder.
```
