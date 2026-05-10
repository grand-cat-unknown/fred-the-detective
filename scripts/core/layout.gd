class_name Layout
extends RefCounted

const ROOM_LABEL_FONT_SIZE := 12
const ROOM_LABEL_MIN_SIZE := Vector2(220.0, 18.0)

const WALL_TOP_HEIGHT := 8.0

const RUG_INSET := 1.0
const RUG_TRIM_OUTLINE_INSET := 5.0
const RUG_TRIM_OFFSET := Vector2(4.0, 4.0)
const RUG_TRIM_THICKNESS := 3.0
const RUG_TRIM_HORIZONTAL_PAD := 8.0

const OBJECT_INSET := 3.0
const OBJECT_HIGHLIGHT_OFFSET := Vector2(3.0, 3.0)
const OBJECT_HIGHLIGHT_HORIZONTAL_PAD := 6.0
const OBJECT_HIGHLIGHT_HEIGHT := 7.0
const OBJECT_OUTLINE_WIDTH := 1.5

const PEDESTAL_OUTER_INSET := 5.0
const PEDESTAL_INNER_INSET := 10.0

const DOOR_OFFSET := Vector2(2.0, 4.0)
const DOOR_PAD := Vector2(4.0, 8.0)
const DOOR_KNOB_OFFSET_RIGHT := 8.0
const DOOR_KNOB_RADIUS := 2.0

const ELEVATOR_FRAME_INSET := 2.0
const ELEVATOR_PANEL_INSET := 4.0
const ELEVATOR_SEAM_INSET := 4.0
const ELEVATOR_ARROW_NORMALIZED: Array[Vector2] = [
	Vector2(0.3, 0.35),
	Vector2(0.7, 0.35),
	Vector2(0.5, 0.2),
]

const CLUE_RADIUS := 10.0
const CLUE_OUTLINE_WIDTH := 2.0

const ACTOR_BODY_OFFSET := Vector2(-10.0, -6.0)
const ACTOR_BODY_SIZE := Vector2(20.0, 22.0)
const ACTOR_HEAD_OFFSET := Vector2(-8.0, -22.0)
const ACTOR_HEAD_SIZE := Vector2(16.0, 16.0)
const ACTOR_SHADOW_OFFSET := Vector2(-11.0, 7.0)
const ACTOR_SHADOW_SIZE := Vector2(22.0, 5.0)
const ACTOR_NOSE_RUNNING_OFFSET := -14.0
const ACTOR_NOSE_FACE_DISTANCE := 8.0
const ACTOR_NOSE_HALF_SIZE := Vector2(2.0, 2.0)
const ACTOR_NOSE_SIZE := Vector2(4.0, 4.0)
const ACTOR_HAT_BRIM_OFFSET := Vector2(-15.0, -22.0)
const ACTOR_HAT_BRIM_SIZE := Vector2(30.0, 4.0)
const ACTOR_HAT_POINTS: Array[Vector2] = [
	Vector2(-12.0, -21.0),
	Vector2(12.0, -21.0),
	Vector2(8.0, -30.0),
	Vector2(-8.0, -30.0),
]

const INTERACT_PROMPT_NPC_OFFSET := Vector2(-60.0, -88.0)
const INTERACT_PROMPT_CLUE_OFFSET := Vector2(-60.0, -38.0)
const INTERACT_PROMPT_TILE_OFFSET := Vector2(-80.0, -44.0)

const ROOM_BORDER_WIDTH := 2.0
const TILE_OUTLINE_WIDTH := 1.0
