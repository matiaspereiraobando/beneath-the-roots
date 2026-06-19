extends RefCounted
class_name CitadelLayout

const GRID_COLS := 3
const GRID_ROWS := 4
const GRID_ORIGIN := Vector2i(54, 54)
const CELL_STRIDE := Vector2i(98, 105)
const CELL_SIZE := Vector2i(64, 64)


static func grid_pixel_size() -> Vector2i:
	return Vector2i(
		GRID_ORIGIN.x + (GRID_COLS - 1) * CELL_STRIDE.x + CELL_SIZE.x,
		GRID_ORIGIN.y + (GRID_ROWS - 1) * CELL_STRIDE.y + CELL_SIZE.y,
	)
