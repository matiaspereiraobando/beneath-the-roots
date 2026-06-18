extends Control
class_name SegmentedBar

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")

@export var fill_start: Color = HudThemeRes.ERROR
@export var fill_end: Color = HudThemeRes.HP_FILL_END
@export var segment_width: float = 10.0

var ratio: float = 1.0
var _fill_color: Color = HudThemeRes.ERROR


func _ready() -> void:
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_minimum_size.y = HudThemeRes.FONT_STAT
	if custom_minimum_size.x < 1.0:
		custom_minimum_size.x = 80.0
	_fill_color = fill_start


func set_ratio(value: float) -> void:
	ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_fill_color(color: Color) -> void:
	_fill_color = color
	fill_start = color
	fill_end = color
	queue_redraw()


func set_fill_colors(start: Color, end: Color) -> void:
	set_fill_color(start.lerp(end, 0.5))


func _bar_rect() -> Rect2:
	var h := float(HudThemeRes.FONT_STAT)
	var y := (size.y - h) * 0.5
	return Rect2(Vector2(0.0, y), Vector2(size.x, h))


func _draw() -> void:
	var bar := _bar_rect()
	var trough := HudThemeRes.carved_trough()
	draw_style_box(trough, bar)
	var inner := Rect2(bar.position + Vector2(1.0, 1.0), Vector2(bar.size.x - 2.0, bar.size.y - 2.0))
	var full_w := inner.size.x
	var fill_w := full_w * ratio
	if fill_w <= 0.0:
		return
	var x := 0.0
	while x < full_w:
		var seg_w := minf(segment_width - 1.0, full_w - x)
		if seg_w <= 0.0:
			break
		if x < fill_w:
			var draw_w := minf(seg_w, fill_w - x)
			draw_rect(
				Rect2(inner.position.x + x, inner.position.y, draw_w, inner.size.y),
				_fill_color,
			)
		x += segment_width
