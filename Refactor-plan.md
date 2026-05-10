Phased execution plan

 Each phase ends with a manual smoke test using
 ./scripts/export-web.sh && nvm use 22 && vercel dev (per AGENTS.md)
 plus opening the project in the Godot editor to confirm no parser
 errors. Don't start phase N+1 until phase N runs clean.

 Phase 1 — Foundation (low risk, no behavior change)

 1. Create scripts/core/enums.gd with GamePhase (move existing
 Phase), RequestKind { DIALOGUE, ACCUSATION },
 AccusationStep { PICK_SUSPECT, PICK_EVIDENCE, EXPLAIN, RESOLVING, DONE },
 InteractKind { NONE, NPC, CLUE, DOOR, ELEVATOR },
 FaceDir { RIGHT, LEFT, UP, DOWN } with helpers.
 2. Create scripts/core/theme_constants.gd — every color and pixel
 offset currently inlined in _draw_* (e.g., Vector2(rect.size.x, 8.0)
 wall-top height, Vector2(face_dir.x * 8.0, -14.0 + face_dir.y * 8.0)
 nose offset, the 14 @export color defaults).
 3. Create scripts/core/tile_map_constants.gd with MAP_ROWS,
 BLOCKING_TILES, TILE_SIZE, MAP_WIDTH, MAP_HEIGHT, VIEW_SIZE.
 4. Create scripts/core/event_bus.gd (autoload) with the signals listed
 above. Empty bodies; no listeners yet.
 5. Create scripts/core/game_state.gd (autoload). Holds
 current_room: String, phase: GamePhase,
 clue_inspected: Dictionary[String, bool] (keyed by clue ID, not
 index — fixes the index-vs-array fragility),
 suspect_talked: Dictionary[String, bool], with mutator methods that
 emit EventBus signals.
 6. Register both autoloads in project.godot.
 7. Refactor game.gd to import from these new files (just the
 constants — keep all behavior). Verify game still runs identically.

 Phase 2 — Typed data Resources

 1. scripts/data/suspect_data.gd (class_name SuspectData):
 id: StringName, display_name, subtitle, room: StringName,
 position: Vector2, color: Color, instructions: String,
 accent_color: Color.
 2. Same for clue_data.gd (unlock_requirements: Array[StringName]
 replaces the "chute" / "gloves" magic strings — each entry is a
 prerequisite clue ID or suspect ID), room_data.gd, door_data.gd,
 elevator_data.gd.
 3. case_data.gd: suspects: Array[SuspectData],
 clues: Array[ClueData], rooms: Array[RoomData],
 doors: Array[DoorData], elevators: Array[ElevatorData],
 verifier_instructions: String,
 required_evidence_id: StringName, correct_suspect_id: StringName.
 4. case_loader.gd: a single function that builds the in-memory
 CaseData from the existing const SUSPECTS/CLUES/... dicts. Do
 not create .tres files yet — keep the current dicts as the source
 of truth. The loader is the bridge that lets every consumer work with
 typed Resources without us hand-converting 30 dicts to YAML.
 (Optional follow-up: actually serialize to .tres. Out of scope
 unless the user wants it later.)
 5. Replace every SUSPECTS[i]["foo"] lookup in game.gd with
 case.suspects[i].foo. Replace integer index constants
 (SUSPECT_PEMBERTON := 0) with ID lookup helpers
 (case.suspect_by_id(&"pemberton")). Verify game still runs.

 Phase 3 — Services (the big extraction)

 Order matters: services are extracted bottom-up so the next one can
 depend on the previous.

 1. UnlockResolver first — pure function, no state:
 is_clue_available(clue: ClueData, state: GameState) -> bool reads
 clue.unlock_requirements. unlocked_context_for_suspect(id, state) -> Array[String]. Replace the two duplicated blocks in game.gd
 (_is_clue_available and _build_unlocked_case_context) with calls
 into the resolver.
 2. LLMClient:
   - Owns the HTTPRequest node.
   - Public API: request_dialogue(payload) -> int (a request id),
 request_accusation(payload) -> int. Returns -1 on
 local-error / queueing; queue subsequent requests if one is in
 flight rather than dropping them.
   - Emits dialogue_completed(reply: String),
 dialogue_failed(reason: String), accusation_completed(verdict: AccusationVerdict),
 accusation_failed(reason: String).
   - JSON parsing happens here; consumers never see Variant.
   - Fixes the early-return bug: any non-success path emits failure
 and returns immediately; never falls through to parsing.
 3. DialogueService:
   - Owns conversations: Dictionary[StringName, Array[Line]].
   - start_conversation(suspect_id), submit(suspect_id, message),
 close().
   - Validates non-empty before mutating history (fixes the bug at
 game.gd:1265-1275).
   - Builds the prompt, including the UnlockResolver context.
   - Trims history at one place (eliminates the duplicated trim).
   - Listens to LLMClient.dialogue_completed/failed for the active
 conversation; emits EventBus.dialogue_* for the panel.
 4. AccusationService:
   - Owns step: AccusationStep, picked_suspect_id,
 picked_evidence_id, explanation.
   - Methods drive transitions; emits
 EventBus.accusation_step_changed and accusation_resolved.
   - Holds the local verdict fallback. The keyword matcher
 (_explanation_mentions_core_solution) lives here as one private
 helper with named keyword sets per concept.
 5. InteractionDetector — given player position and current_room,
 returns a single typed InteractTarget { kind, index, label }. One
 sweep per frame, replacing the current 4-loop pass.

 After each service is extracted, delete the corresponding code from
 game.gd and verify behavior.

 Phase 4 — World nodes

 1. Player (Node2D + script): owns position, target, stepping,
 face direction; step(direction) method; draws itself. Reads
 walkability from WorldMap. Emits moved(tile) so
 InteractionDetector can react.
 2. NPC: takes a SuspectData resource; draws itself; interact()
 emits a signal.
 3. ClueMarker: takes a ClueData; draws itself; visibility tracks
 UnlockResolver and editor_show_locked_clues.
 4. RoomZone: takes a RoomData; draws bounds + label.
 5. Door, Elevator: take their respective *Data; emit
 interact_target events.
 6. WorldMap: draws the tile map; exposes
 is_walkable(tile: Vector2i) -> bool, world_to_tile,
 tile_to_world.
 7. Update main.tscn to instance these (one of each per content row, or
 spawned at runtime by game.gd from CaseData).

 Phase 5 — UI scenes

 Each panel becomes its own scene + script. The script:

 - Caches its own %-named children in _ready().
 - Connects its own buttons.
 - Exposes a small typed surface to the controller
 (open(), close(), set_busy(bool, msg), append_line(speaker, text)).
 - Emits semantic signals (submitted(text), closed,
 restart_pressed, etc.) — never reaches into another scene.

 Move the panel definitions out of main.tscn into individual scenes;
 main.tscn instances them. The unique_name_in_owner flags keep
 existing %Name access working in the new scenes' own _ready().

 Phase 6 — game.gd thin controller

 Final shape (~150 lines):

 extends Node2D
 class_name DetectiveGame

 @onready var _world_map: WorldMap = %WorldMap
 @onready var _player: Player = %Player
 @onready var _hud: Hud = %Hud
 @onready var _dialogue_panel: DialoguePanel = %DialoguePanel
 # ...one @onready per scene-instanced child

 var _case: CaseData
 var _llm: LLMClient
 var _dialogue: DialogueService
 var _accusation: AccusationService
 var _interaction: InteractionDetector
 var _unlocks: UnlockResolver

 func _ready() -> void:
     _case = CaseLoader.load_default()
     _build_services()
     _spawn_world_from_case()
     _wire_event_bus()
     GameState.reset(_case)

 func _wire_event_bus() -> void:
     EventBus.clue_inspected.connect(_on_clue_inspected)
     EventBus.suspect_talked.connect(_on_suspect_talked)
     EventBus.dialogue_completed.connect(_dialogue_panel.append_reply)
     # ...etc.

 No rendering here. No HTTP. No conversation arrays. No accusation
 state. No more than a handful of one-line callbacks.

 Phase 7 — Polish pass

 - gdformat / consistent style (still no comments unless explaining
 WHY).
 - Verify every func has typed args + return type.
 - Verify no Variant in any public API.
 - Walk every _draw call site to ensure colors/sizes pull from
 theme_constants.gd.
 - Remove the now-unused integer index constants
 (SUSPECT_PEMBERTON := 0 etc.).

 ---
 Bug fixes piggy-backed on the refactor

 1. Empty-message dialogue submit (game.gd:1265-1275): currently
 appends to history before validating non-empty. Fixed naturally in
 DialogueService.submit() by validating first.
 2. LLM error-path fall-through (game.gd:1362-1379): on
 result != RESULT_SUCCESS or response_code != 200, current code
 continues into JSON parsing and may double-handle the error. Fixed
 in LLMClient with a strict early-return ladder.
 3. Pending-request state leak: three different sites
 (game.gd:1160-1163, 1352-1353, 1391-1393) reset overlapping subsets
 of pending fields. Centralized in LLMClient.clear_pending() and
 service-level _finish_request() helpers.

 ---
 Verification

 Run after each phase, not just the end:

 1. ./scripts/export-web.sh && nvm use 22 && vercel dev — confirms the
 web export still builds and serves.
 2. Open project.godot in the Godot editor and verify the parser is
 green (no class_name clashes, no missing autoloads).
 3. Manual smoke test with browser at localhost:3000:
   - Walk between all rooms; no walls passable, no rooms unreachable.
   - Inspect every clue; verify the locked clues stay locked and the
 unlock chain still works (Chute Notice + Walter unlocks chute,
 Ghost Cell + Field Book unlocks gloves).
   - Talk to every suspect; confirm LLM replies stream in and
 conversation persists across re-opens.
   - Trigger an empty-message submit on the dialogue input — must NOT
 mutate the conversation (regression check on bug #1).
   - Disconnect network mid-dialogue (DevTools → Offline) and confirm
 a single failure message, no double-append (regression check on
 bug #2).
       - Disconnect network mid-dialogue (DevTools → Offline) and confirm
     a single failure message, no double-append (regression check on
     bug #2).
       - Run a wrong accusation and a right accusation; verify both verdicts
     and the local fallback (with OPENAI_API_KEY removed) still work.
     4. Run an editor preview: toggle editor_preview_room_index and
     editor_show_locked_clues and confirm the per-room preview still
     renders correctly post-extraction.

     End-to-end, the user-visible behavior should be identical except for
     the three bug fixes called out.

     ---
     What this plan deliberately does NOT do

     - Does not move case truth out of the client. Per user choice;
     ACCUSATION_VERIFIER_INSTRUCTIONS, the killer name, and the local
     fallback keyword matcher all stay in AccusationService.
     - Does not switch to Godot's TileMap node. The hand-drawn
     MAP_ROWS string array works and converting it has no behavioral
     upside.
     - Does not introduce a unit test framework. The architecture makes
     testing possible (services have no Node dependencies, the LLM is
     injectable), but adding GUT/GdUnit is a separate decision.
     - Does not generate .tres files for case content. The
     CaseLoader produces typed Resources from the existing in-script
     dicts; serializing to .tres is an optional follow-up.
     - Does not touch the backend (api/llm.js, lib/auth.js).
