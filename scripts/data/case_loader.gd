class_name CaseLoader
extends RefCounted

const PLAYER_START_TILE := Vector2i(5, 13)
const SPRITE_DIR := "res://assets/sprites/characters/"


static func _sprite(index: int) -> Texture2D:
	return load(SPRITE_DIR + "char_%02d.png" % index) as Texture2D


static func load_default() -> CaseData:
	var case := CaseData.new()
	case.player_start_tile = PLAYER_START_TILE
	case.suspects = [
		SuspectData.new(&"pemberton", "Dr. Otis Pemberton", Vector2(624, 272), Color8(126, 89, 150), Color8(74, 45, 94), _sprite(0)),
		SuspectData.new(&"walter", "Walter Crane", Vector2(432, 240), Color8(157, 102, 70), Color8(101, 64, 45), _sprite(4)),
		SuspectData.new(&"mara", "Mara Bell", Vector2(80, 400), Color8(84, 128, 157), Color8(43, 75, 101), _sprite(9)),
		SuspectData.new(&"theo", "Theo Griggs", Vector2(784, 144), Color8(67, 119, 122), Color8(38, 76, 82), _sprite(6)),
		SuspectData.new(&"lena", "Lena Ortiz", Vector2(848, 464), Color8(138, 84, 148), Color8(82, 48, 96), _sprite(10)),
		SuspectData.new(&"viv", "Vivian Marsh", Vector2(112, 144), Color8(166, 133, 76), Color8(96, 75, 46), _sprite(2)),
	]
	return case
