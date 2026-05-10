class_name CaseLoader
extends RefCounted

const ROOM_CONCIERGE := &"concierge"
const ROOM_1220 := &"room_1220"
const ROOM_GEAR := &"gear_cart"
const ROOM_HALL := &"twelfth_hall"
const ROOM_SUITE := &"suite_1221"
const ROOM_LOBBY := &"elevator_lobby"
const ROOM_CHUTE := &"chute_access"
const ROOM_1223 := &"room_1223"

const SUSPECT_PEMBERTON := &"pemberton"
const SUSPECT_WALTER := &"walter"
const SUSPECT_MARA := &"mara"
const SUSPECT_THEO := &"theo"
const SUSPECT_LENA := &"lena"
const SUSPECT_VIV := &"viv"

const CLUE_BODY_WALL := &"body_wall"
const CLUE_PEDESTAL := &"pedestal"
const CLUE_AUCTION_RECEIPT := &"auction_receipt"
const CLUE_FIELD_BOOK := &"field_book"
const CLUE_ROOM_1220_LOG := &"room_1220_log"
const CLUE_CHUTE_NOTICE := &"chute_notice"
const CLUE_GHOST_CELL := &"ghost_cell"
const CLUE_GLOVES := &"gloves"

const PLAYER_START_TILE := Vector2i(5, 13)

const VERIFIER_INSTRUCTIONS := """You are the final case-verdict verifier for Fred the Detective. \
You are not a suspect and you do not roleplay. The case truth is authored by the game and must be \
treated as authoritative. Return only compact JSON with this exact shape: \
{"is_correct": boolean, "headline": string, "feedback": string}. \
Mark is_correct true only when the player accuses Dr. Otis Pemberton, cites the Ghost Cell in the \
Chute as the key evidence, and gives a coherent explanation connecting the ghost cell to the murder \
method, the stolen idol, and Pemberton's motive or opportunity. Mark false if the suspect is wrong, \
the key evidence is wrong, the explanation is vague, or the explanation contradicts the authored \
truth. Keep headline under 8 words. Keep feedback under 90 words, written as Fred's case-board \
verdict."""

const TRUSTED_CASE_TRUTH := """Trusted case truth:
- Victim: Reginald Vance, collector, killed in suite 1221 during a real haunting.
- Killer: Dr. Otis Pemberton, Ghostbusters physician and occult scholar.
- Motive: Pemberton wanted Vance's black anchor idol for research before Vance locked it away.
- Required key evidence: Ghost Cell in the Chute. It contains the stolen idol, its main port residue \
matches the wall fan, and its side-vent dust matches the pedestal.
- Supporting facts: Anchor idols do not vanish after hauntings; the body wound and wall fan match an \
opened charged ghost cell; the pedestal dust proves the idol was present during the discharge and \
removed afterward; Pemberton's gloves carry purge residue; Viv's clarification proves the 9:18 room \
1220 entry happened after Vance's body was found, not during Pemberton's assigned sweep."""


static func load_default() -> CaseData:
	var case := CaseData.new()
	case.title = "Sedgewick Hotel: The Vance Case"
	case.question = "Who killed Reginald Vance?"
	case.start_room = ROOM_LOBBY
	case.player_start_tile = PLAYER_START_TILE
	case.correct_suspect_id = SUSPECT_PEMBERTON
	case.required_evidence_id = CLUE_GHOST_CELL
	case.verifier_instructions = VERIFIER_INSTRUCTIONS
	case.trusted_case_truth = TRUSTED_CASE_TRUTH
	case.rooms = _build_rooms()
	case.doors = _build_doors()
	case.elevators = _build_elevators()
	case.suspects = _build_suspects()
	case.clues = _build_clues()
	case.build_indexes()
	return case


static func _build_rooms() -> Array[RoomData]:
	return [
		RoomData.new(
			ROOM_CONCIERGE, "CONCIERGE / SECURITY",
			Rect2(30.0, 30.0, 240.0, 150.0), Vector2(45.0, 42.0),
			Color8(206, 184, 128, 44), Rect2i(0, 0, 11, 6),
		),
		RoomData.new(
			ROOM_1220, "ROOM 1220",
			Rect2(330.0, 30.0, 240.0, 150.0), Vector2(345.0, 42.0),
			Color8(150, 175, 190, 44), Rect2i(9, 0, 12, 6),
		),
		RoomData.new(
			ROOM_GEAR, "SERVICE CORRIDOR / GEAR CART",
			Rect2(630.0, 30.0, 300.0, 150.0), Vector2(645.0, 42.0),
			Color8(125, 155, 145, 44), Rect2i(19, 0, 13, 6),
		),
		RoomData.new(
			ROOM_HALL, "TWELFTH FLOOR HALL",
			Rect2(30.0, 180.0, 900.0, 120.0), Vector2(45.0, 192.0),
			Color8(105, 130, 150, 34), Rect2i(0, 5, 32, 6),
		),
		RoomData.new(
			ROOM_SUITE, "SUITE 1221 - VANCE",
			Rect2(450.0, 300.0, 300.0, 180.0), Vector2(465.0, 312.0),
			Color8(160, 95, 105, 44), Rect2i(14, 10, 11, 7),
		),
		RoomData.new(
			ROOM_LOBBY, "ELEVATOR LOBBY / STAIRWELL",
			Rect2(30.0, 300.0, 240.0, 180.0), Vector2(45.0, 312.0),
			Color8(110, 150, 180, 44), Rect2i(0, 10, 9, 7),
		),
		RoomData.new(
			ROOM_CHUTE, "11F CHUTE ACCESS",
			Rect2(270.0, 300.0, 180.0, 180.0), Vector2(285.0, 312.0),
			Color8(130, 120, 105, 48), Rect2i(8, 10, 7, 7),
		),
		RoomData.new(
			ROOM_1223, "ROOM 1223",
			Rect2(750.0, 300.0, 180.0, 180.0), Vector2(765.0, 312.0),
			Color8(150, 115, 165, 44), Rect2i(24, 10, 8, 7),
		),
	]


static func _build_doors() -> Array[DoorData]:
	return [
		DoorData.new(Vector2i(4, 5), ROOM_CONCIERGE, ROOM_HALL),
		DoorData.new(Vector2i(14, 5), ROOM_1220, ROOM_HALL),
		DoorData.new(Vector2i(25, 5), ROOM_GEAR, ROOM_HALL),
		DoorData.new(Vector2i(4, 10), ROOM_HALL, ROOM_LOBBY),
		DoorData.new(Vector2i(16, 10), ROOM_HALL, ROOM_SUITE),
		DoorData.new(Vector2i(26, 10), ROOM_HALL, ROOM_1223),
	]


static func _build_elevators() -> Array[ElevatorData]:
	return [
		ElevatorData.new(
			Vector2i(7, 12), Vector2i(6, 12), ROOM_LOBBY,
			Vector2i(9, 12), Vector2i(10, 12), ROOM_CHUTE,
		),
	]


static func _build_suspects() -> Array[SuspectData]:
	return [
		SuspectData.new(
			SUSPECT_PEMBERTON, "Dr. Otis Pemberton", "Ghostbusters physician",
			ROOM_HALL, Vector2(555.0, 255.0),
			Color8(126, 89, 150), Color8(74, 45, 94),
			"You are Dr. Otis Pemberton, a Ghostbusters physician and occult scholar. You murdered Reginald Vance in suite 1221 by opening a charged spare ghost cell at close range, stole the black anchor idol, hid it inside the cell's outer case, dropped it into the jammed laundry chute, and pretended you had checked room 1220. You wanted the idol for your research before Vance locked it away. Do not confess unless Fred has clearly named the ghost cell, the idol in the chute, your gloves, and the false 1220 sweep. Otherwise deny calmly, lean on the real haunting, and sound helpful but faintly superior. Keep replies under three sentences and do not include speaker labels.",
			true,
		),
		SuspectData.new(
			SUSPECT_WALTER, "Walter Crane", "Rival collector",
			ROOM_HALL, Vector2(345.0, 255.0),
			Color8(157, 102, 70), Color8(101, 64, 45),
			"You are Walter Crane, a theatrical rival collector staying below the Sedgewick Hotel's twelfth floor. You lost the black idol to Reginald Vance at auction and wanted it badly, which makes you look suspicious, but you are innocent. Around 9:12 PM you heard something heavy strike the laundry chute. You did not understand its importance at first and resent being treated as obvious. Keep replies under three sentences and do not include speaker labels.",
			false,
		),
		SuspectData.new(
			SUSPECT_MARA, "Mara Bell", "Ghostbusters field lead",
			ROOM_LOBBY, Vector2(165.0, 435.0),
			Color8(84, 128, 157), Color8(43, 75, 101),
			"You are Mara Bell, the Ghostbusters field lead. You are innocent. During the haunting you assigned Otis Pemberton to clear room 1220, Lena Ortiz to check room 1223, Theo Griggs to guard the gear cart, and yourself to the elevator lobby and stairwell. You did not see Pemberton come out of room 1220; you saw him return from the direction of Vance's suite. You are disciplined, protective of your team, and increasingly troubled by the timeline. Keep replies under three sentences and do not include speaker labels.",
			false,
		),
		SuspectData.new(
			SUSPECT_THEO, "Theo Griggs", "Ghostbusters technician",
			ROOM_GEAR, Vector2(765.0, 135.0),
			Color8(67, 119, 122), Color8(38, 76, 82),
			"You are Theo Griggs, the Ghostbusters technician. You are innocent. You guarded the gear cart during the sweep and later noticed a charged spare ghost cell was missing; Pemberton waved it off as a paperwork error. You can explain that a purged charged cell can leave dark violet residue on protective gloves. You are practical, defensive about the equipment, and frustrated by sloppy assumptions. Keep replies under three sentences and do not include speaker labels.",
			false,
		),
		SuspectData.new(
			SUSPECT_LENA, "Lena Ortiz", "Ghostbusters trap operator",
			ROOM_1223, Vector2(825.0, 435.0),
			Color8(138, 84, 148), Color8(82, 48, 96),
			"You are Lena Ortiz, a Ghostbusters trap operator. You are innocent. You were checking room 1223 during the sweep. You noticed Pemberton return with his gloves still on and one hand tucked against his side, as if hiding equipment or residue. You do not want to accuse a teammate without proof, but you are observant and honest when Fred asks pointed questions. Keep replies under three sentences and do not include speaker labels.",
			false,
		),
		SuspectData.new(
			SUSPECT_VIV, "Vivian Marsh", "Hotel concierge",
			ROOM_CONCIERGE, Vector2(165.0, 105.0),
			Color8(166, 133, 76), Color8(96, 75, 46),
			"You are Vivian Marsh, the Sedgewick Hotel concierge. You are innocent and trying to protect guests and the hotel's reputation. The laundry chute has been jammed between floors 12 and 11 for a week. The security dashboard lagged during the haunting, but the room lock timestamps are accurate. Once Fred has found the 1220 door record and the ghost cell in the chute, you can clarify that you opened room 1220 at 9:18 PM after Vance's body was found; it was not Pemberton's sweep. Keep replies under three sentences and do not include speaker labels.",
			false,
		),
	]


static func _build_clues() -> Array[ClueData]:
	return [
		ClueData.new(
			CLUE_BODY_WALL,
			"Vance's Body and Wall Fan",
			"Reginald Vance has a small cold-burn wound under his ribs. Violet ectoplasm smears his jacket, and a narrow fan of matching residue runs from the body toward the wall.",
			ROOM_SUITE, Vector2(525.0, 375.0),
		),
		ClueData.new(
			CLUE_PEDESTAL,
			"Empty Idol Pedestal",
			"Gray binding dust surrounds a clean idol-shaped absence on the pedestal. The idol was present when the dust fell, then removed afterward.",
			ROOM_SUITE, Vector2(585.0, 375.0),
		),
		ClueData.new(
			CLUE_AUCTION_RECEIPT,
			"Auction Receipt",
			"The receipt shows Vance beat Walter Crane for the black stone idol. A folded note from Pemberton urges Vance to surrender the idol for scholarly study.",
			ROOM_SUITE, Vector2(495.0, 435.0),
		),
		ClueData.new(
			CLUE_FIELD_BOOK,
			"Anchor Idol Field Book",
			"The field book says anchor idols attract hauntings but do not vanish when hauntings end. It also diagrams opened ghost cells: directional cones, cold-burn wounds, side-vent dust, and blocked silhouettes.",
			ROOM_SUITE, Vector2(615.0, 435.0),
		),
		ClueData.new(
			CLUE_ROOM_1220_LOG,
			"Room 1220 Door Record",
			"The lock record shows room 1220 opened at 9:18 PM. The dashboard was lagging during the haunting, so the entry feels ambiguous until someone explains who opened it.",
			ROOM_1220, Vector2(435.0, 105.0),
		),
		ClueData.new(
			CLUE_CHUTE_NOTICE,
			"Laundry Chute Notice",
			"A maintenance notice says the laundry chute is blocked between floors 12 and 11. If something heavy went down the chute tonight, it may still be wedged there.",
			ROOM_HALL, Vector2(225.0, 255.0),
		),
		ClueData.new(
			CLUE_GHOST_CELL,
			"Ghost Cell in the Chute",
			"A spent spare ghost cell is wedged above floor 11. The black idol is hidden inside its outer case. Residue on the main port matches the wall fan, and gray dust on the side vents matches the pedestal.",
			ROOM_CHUTE, Vector2(345.0, 435.0),
			[CLUE_CHUTE_NOTICE] as Array[StringName],
			[SUSPECT_WALTER] as Array[StringName],
		),
		ClueData.new(
			CLUE_GLOVES,
			"Pemberton's Gloves",
			"Pemberton's protective gloves are stained dark violet inside the fingers, the pattern Theo described for someone who opened and purged a charged ghost cell by hand.",
			ROOM_GEAR, Vector2(825.0, 105.0),
			[CLUE_GHOST_CELL, CLUE_FIELD_BOOK] as Array[StringName],
			[] as Array[StringName],
		),
	]
