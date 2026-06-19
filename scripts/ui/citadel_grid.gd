extends Control
class_name CitadelGrid

const Layout = preload("res://scripts/data/citadel_layout.gd")

signal cell_hovered(cell: Vector2i)
signal cell_unhovered

const HOVER_FILL := Color("#58111d", 0.45)

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
	return Rect2(
		Vector2(Layout.GRID_ORIGIN) + Vector2(cell.x * Layout.CELL_STRIDE.x, cell.y * Layout.CELL_STRIDE.y),
		Vector2(Layout.CELL_SIZE),
	)


func _local_to_cell(local: Vector2) -> Vector2i:
	for y in Layout.GRID_ROWS:
		for x in Layout.GRID_COLS:
			var cell := Vector2i(x, y)
			if _cell_rect(cell).has_point(local):
				return cell
	return Vector2i(-1, -1)


func _draw() -> void:
	if hovered_cell.x < 0:
		return
	var rect := _cell_rect(hovered_cell)
	draw_rect(rect, HOVER_FILL)
