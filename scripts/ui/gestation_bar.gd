extends Control
class_name GestationBar

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
const EMPTY_SLOT = preload("res://scripts/data/ant_types.gd").EMPTY_SLOT

@export var bar_thickness: int = 3


func _ready() -> void:
	custom_minimum_size = Vector2(24, bar_thickness)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var w := size.x
	draw_rect(Rect2(Vector2.ZERO, size), HudThemeRes.SURFACE_CONTAINER_LOWEST)
	if GameState.nursery_queue.is_empty() or GameState.nursery_queue[0] == EMPTY_SLOT:
		return
	var interval := GameState.queen_spawn_interval()
	if interval <= 0.0:
		return
	var remaining := clampf(GameState.queen_spawn_timer / interval, 0.0, 1.0)
	var fill_w := w * remaining
	if fill_w <= 0.0:
		return
	draw_rect(
		Rect2(0.0, 0.0, fill_w, h),
		HudThemeRes.SECONDARY,
	)
