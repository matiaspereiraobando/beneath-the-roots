extends Node2D
class_name EnemyHpBar

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")

const WIDTH := 24.0
const HEIGHT := 3.0
const OFFSET_Y := -18.0

var _ratio := 1.0


func _ready() -> void:
	position.y = OFFSET_Y
	z_index = 1


func set_ratio(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var top_left := Vector2(-WIDTH * 0.5, -HEIGHT * 0.5)
	var size := Vector2(WIDTH, HEIGHT)
	draw_rect(Rect2(top_left, size), HudThemeRes.SURFACE_CONTAINER_LOWEST.lightened(0.08))
	if _ratio > 0.001:
		var fill_color := HudThemeRes.ERROR.lerp(HudThemeRes.HP_FILL_END, _ratio)
		draw_rect(Rect2(top_left, Vector2(WIDTH * _ratio, HEIGHT)), fill_color)
	draw_rect(Rect2(top_left, size), HudThemeRes.MOSS_BORDER, false, 1.0)
