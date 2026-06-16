extends RefCounted
class_name GridPathfinding

var _astar := AStarGrid2D.new()
var _cols: int = 0
var _rows: int = 0
var _citadel_cells: Array[Vector2i] = []


func setup_from_level(level: Dictionary) -> void:
	_cols = level.gridSize.cols
	_rows = level.gridSize.rows
	_citadel_cells.clear()
	var rect: Dictionary = level.citadelRect
	for dy in rect.h:
		for dx in rect.w:
			_citadel_cells.append(Vector2i(rect.x + dx, rect.y + dy))
	_astar.region = Rect2i(0, 0, _cols, _rows)
	_astar.cell_size = Vector2(GameTuning.TILE_SIZE, GameTuning.TILE_SIZE)
	_astar.offset = Vector2.ZERO
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	var cells: Array = level.cells
	for y in _rows:
		for x in _cols:
			var tile: int = cells[y][x]
			var walkable := tile in [
				PlaceholderTilesets.MacroTile.SURFACE,
				PlaceholderTilesets.MacroTile.TUNNEL,
				PlaceholderTilesets.MacroTile.BUILD,
				PlaceholderTilesets.MacroTile.CITADEL,
				PlaceholderTilesets.MacroTile.SPAWN,
			]
			_astar.set_point_solid(Vector2i(x, y), not walkable)


func rebuild(_level: Dictionary) -> void:
	# Sprint 03: refresh grid after dig
	pass


func get_path_to_citadel(from: Vector2i) -> PackedVector2Array:
	var goal := _nearest_citadel(from)
	if goal == Vector2i(-1, -1):
		return PackedVector2Array()
	var id_path := _astar.get_id_path(from, goal)
	var world_path := PackedVector2Array()
	for cell in id_path:
		world_path.append(tile_center(cell))
	return world_path


func tile_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * GameTuning.TILE_SIZE + GameTuning.TILE_SIZE * 0.5,
		cell.y * GameTuning.TILE_SIZE + GameTuning.TILE_SIZE * 0.5
	)


func world_to_tile(world: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world.x / GameTuning.TILE_SIZE)),
		int(floor(world.y / GameTuning.TILE_SIZE))
	)


func is_citadel(cell: Vector2i) -> bool:
	return cell in _citadel_cells


func _nearest_citadel(from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for c in _citadel_cells:
		if _astar.is_point_solid(c):
			continue
		var d := from.distance_squared_to(c)
		if d < best_dist:
			best_dist = d
			best = c
	return best
