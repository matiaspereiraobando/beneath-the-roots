extends Control
class_name CitadelGrid

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
const Layout = preload("res://scripts/data/citadel_layout.gd")

signal cell_hovered(cell: Vector2i)
signal cell_unhovered

const HOVER_FILL := Color(0.35, 0.95, 0.4, 0.45)

var hovered_cell := Vector2i(-1, -1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var px := Layout.grid_pixel_size()
	custom_minimum_size = Vector2(px.x, px.y)
	tooltip_text = "Citadel chamber grid"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered(_local_to_cell(get_local_mouse_position()))


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_hovered(Vector2i(-1, -1))


func _set_hovered(cell: Vector2i) -> void:
	if hovered_cell == cell:
		return
	hovered_cell = cell
	queue_redraw()
	if cell.x >= 0:
		cell_hovered.emit(cell)
	else:
		cell_unhovered.emit()


func _cell_rect(cell: Vector2i) -> Rect2:
	var step := Layout.CELL_SIZE + Layout.CELL_GAP
	return Rect2(
		cell.x * step,
		cell.y * step,
		Layout.CELL_SIZE,
		Layout.CELL_SIZE,
	)


func _local_to_cell(local: Vector2) -> Vector2i:
	for y in Layout.GRID_ROWS:
		for x in Layout.GRID_COLS:
			var cell := Vector2i(x, y)
			if _cell_rect(cell).has_point(local):
				return cell
	return Vector2i(-1, -1)


func _draw() -> void:
	var trough := HudThemeRes.carved_trough()
	for y in Layout.GRID_ROWS:
		for x in Layout.GRID_COLS:
			var cell := Vector2i(x, y)
			var rect := _cell_rect(cell)
			draw_style_box(trough, rect)
			if cell == hovered_cell:
				draw_rect(rect, HOVER_FILL)
				draw_rect(rect.grow(-2.0), HudThemeRes.SECONDARY, false, 2.0)
