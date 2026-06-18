extends Control
class_name SegmentedBar

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")

@export var fill_start: Color = HudThemeRes.ERROR
@export var fill_end: Color = HudThemeRes.HP_FILL_END
@export var segment_width: float = 10.0

var ratio: float = 1.0


func _ready() -> void:
	custom_minimum_size = Vector2(80, 12)


func set_ratio(value: float) -> void:
	ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_fill_colors(start: Color, end: Color) -> void:
	fill_start = start
	fill_end = end
	queue_redraw()


func _draw() -> void:
	var trough := HudThemeRes.carved_trough()
	draw_style_box(trough, Rect2(Vector2.ZERO, size))
	var fill_w := (size.x - 2.0) * ratio
	if fill_w <= 0.0:
		return
	var inner := Rect2(Vector2(1, 1), Vector2(fill_w, size.y - 2.0))
	var steps := maxi(1, int(ceilf(inner.size.x / segment_width)))
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var x0 := inner.position.x + inner.size.x * t0
		var x1 := inner.position.x + inner.size.x * t1 - 1.0
		if x1 <= x0:
			continue
		var seg := Rect2(x0, inner.position.y, x1 - x0, inner.size.y)
		var col := fill_start.lerp(fill_end, (t0 + t1) * 0.5)
		draw_rect(seg, col)
