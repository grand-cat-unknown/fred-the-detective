class_name CaseLoader
extends RefCounted

const PLAYER_START_TILE := Vector2i(5, 13)
const SUSPECT_DIR := "res://assets/suspects"
const SUSPECT_IDS := [
	&"mara",
	&"theo",
	&"otis",
	&"iris",
	&"rival",
	&"bellhop",
	&"maid",
]


static func load_default() -> CaseData:
	var case := CaseData.new()
	case.player_start_tile = PLAYER_START_TILE
	var suspects: Array[SuspectData] = []
	for id in SUSPECT_IDS:
		var suspect := _load_suspect(id)
		if suspect != null:
			suspects.append(suspect)
	case.suspects = suspects
	return case


static func _load_suspect(id: StringName) -> SuspectData:
	var path := "%s/%s.tres" % [SUSPECT_DIR, id]
	if not ResourceLoader.exists(path):
		push_warning("Missing suspect resource: %s" % path)
		return null
	return load(path) as SuspectData
