class_name GameEnums
extends RefCounted

enum FaceDir { RIGHT, LEFT, UP, DOWN }


static func face_dir_to_vector(dir: FaceDir) -> Vector2i:
	match dir:
		FaceDir.LEFT: return Vector2i(-1, 0)
		FaceDir.UP: return Vector2i(0, -1)
		FaceDir.DOWN: return Vector2i(0, 1)
		_: return Vector2i(1, 0)


static func vector_to_face_dir(vec: Vector2i) -> FaceDir:
	if vec.x < 0: return FaceDir.LEFT
	if vec.y < 0: return FaceDir.UP
	if vec.y > 0: return FaceDir.DOWN
	return FaceDir.RIGHT
