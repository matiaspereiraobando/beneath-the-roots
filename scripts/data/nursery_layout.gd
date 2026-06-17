extends RefCounted
class_name NurseryLayout

## Anchor positions in native 256×256 nursery background space.

const NATIVE_SIZE := Vector2(256, 256)

const QUEEN_ANCHOR := Vector2(128, 218)

const BREACH_RECT := Rect2(88, 188, 80, 56)

const EGG_ROOM_CENTERS: Array[Vector2] = [
	Vector2(72, 78),
	Vector2(72, 138),
]

const FOOD_ROOM_CENTER := Vector2(196, 108)

const SPINE_TOP := Vector2(128, 36)
const SPINE_MID := Vector2(128, 128)


static func apply_path_curves(
	path_gatherer: Path2D,
	path_builder: Path2D,
	path_soldier: Path2D
) -> void:
	path_gatherer.curve = _gatherer_curve()
	path_builder.curve = _builder_curve()
	path_soldier.curve = _soldier_curve()


static func _gatherer_curve() -> Curve2D:
	var curve := Curve2D.new()
	curve.add_point(FOOD_ROOM_CENTER)
	curve.add_point(Vector2(128, 108))
	curve.add_point(QUEEN_ANCHOR)
	curve.add_point(Vector2(128, 108))
	curve.add_point(FOOD_ROOM_CENTER)
	return curve


static func _builder_curve() -> Curve2D:
	var curve := Curve2D.new()
	curve.add_point(SPINE_TOP)
	curve.add_point(Vector2(72, 78))
	curve.add_point(Vector2(128, 78))
	curve.add_point(Vector2(72, 138))
	curve.add_point(Vector2(128, 138))
	curve.add_point(Vector2(128, 200))
	curve.add_point(SPINE_TOP)
	return curve


static func _soldier_curve() -> Curve2D:
	var curve := Curve2D.new()
	var r := BREACH_RECT
	curve.add_point(Vector2(r.position.x + 8, r.position.y + r.size.y * 0.5))
	curve.add_point(Vector2(r.position.x + r.size.x - 8, r.position.y + r.size.y * 0.5))
	curve.add_point(Vector2(r.position.x + r.size.x - 8, r.position.y + r.size.y - 6))
	curve.add_point(Vector2(r.position.x + 8, r.position.y + r.size.y - 6))
	curve.add_point(Vector2(r.position.x + 8, r.position.y + r.size.y * 0.5))
	return curve
