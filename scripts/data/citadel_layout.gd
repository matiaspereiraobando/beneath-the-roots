extends RefCounted
class_name CitadelLayout

const GRID_COLS := 4
const GRID_ROWS := 4
const CELL_SIZE := 64
const CELL_GAP := 4


static func grid_pixel_size() -> Vector2i:
	return Vector2i(
		GRID_COLS * CELL_SIZE + (GRID_COLS - 1) * CELL_GAP,
		GRID_ROWS * CELL_SIZE + (GRID_ROWS - 1) * CELL_GAP,
	)
