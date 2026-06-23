extends RefCounted
class_name PlacementRules

const MacroCell = preload("res://scripts/data/macro_tiles.gd").Cell

const ORTHO: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]


static func footprint_for(type: String) -> Vector2i:
	var fp: Variant = GameTuning.STRUCTURE_FOOTPRINTS.get(type)
	if fp is Vector2i:
		return fp
	return Vector2i(2, 2)


static func footprint_cells(anchor: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in size.y:
		for dx in size.x:
			cells.append(Vector2i(anchor.x + dx, anchor.y + dy))
	return cells


static func structure_world_center(anchor: Vector2i, size: Vector2i, pathfinding: GridPathfinding) -> Vector2:
	var top_left := pathfinding.tile_center(anchor)
	if size.x <= 1 and size.y <= 1:
		return top_left
	return top_left + Vector2(
		GameTuning.TILE_SIZE * (size.x - 1) * 0.5,
		GameTuning.TILE_SIZE * (size.y - 1) * 0.5,
	)


static func tower_world_center(tower: Dictionary, pathfinding: GridPathfinding) -> Vector2:
	var size := Vector2i(int(tower.get("width", 2)), int(tower.get("height", 2)))
	return structure_world_center(Vector2i(tower.tile_x, tower.tile_y), size, pathfinding)


static func cell_in_bounds(cell: Vector2i, level_data: Dictionary) -> bool:
	var cells: Array = level_data.get("cells", [])
	if cell.y < 0 or cell.y >= cells.size():
		return false
	if cell.x < 0 or cell.x >= cells[cell.y].size():
		return false
	return true


static func get_cell(level_data: Dictionary, cell: Vector2i) -> int:
	if not cell_in_bounds(cell, level_data):
		return -1
	return level_data.cells[cell.y][cell.x]


static func is_path_cell(cell_type: int) -> bool:
	return cell_type == MacroCell.TUNNEL


static func is_blocked_terrain(cell_type: int) -> bool:
	return cell_type in [MacroCell.SKY, MacroCell.SURFACE, MacroCell.SPAWN, MacroCell.CITADEL]


static func footprint_touches_tunnel(level_data: Dictionary, anchor: Vector2i, size: Vector2i) -> bool:
	for foot_cell: Vector2i in footprint_cells(anchor, size):
		for offset: Vector2i in ORTHO:
			var neighbor: Vector2i = foot_cell + offset
			if get_cell(level_data, neighbor) == MacroCell.TUNNEL:
				return true
	return false


static func is_digging_at(cell: Vector2i) -> bool:
	for job in GameState.dig_jobs:
		if job.cell_x == cell.x and job.cell_y == cell.y:
			return true
	return false


static func is_building_at(cell: Vector2i) -> bool:
	return GameState.is_building_at(cell)


static func tower_footprint_cells(tower: Dictionary) -> Array[Vector2i]:
	var size := Vector2i(int(tower.get("width", 2)), int(tower.get("height", 2)))
	return footprint_cells(Vector2i(tower.tile_x, tower.tile_y), size)


static func cell_under_tower(cell: Vector2i) -> bool:
	for tower in GameState.towers:
		if cell in tower_footprint_cells(tower):
			return true
	for job in GameState.build_jobs:
		if str(job.get("kind", "")) != "tower":
			continue
		if cell in GameState.build_job_footprint_cells(job):
			return true
	return false


static func _action_blocked() -> String:
	match GameState.phase:
		GameState.Phase.WON:
			return "Level complete."
		GameState.Phase.LOST:
			return "Colony lost."
	return ""


static func can_dig(cell: Vector2i) -> String:
	var blocked := _action_blocked()
	if blocked != "":
		return blocked
	if not cell_in_bounds(cell, GameState.level_data):
		return "Out of bounds."
	if get_cell(GameState.level_data, cell) != MacroCell.ROCK:
		return "Dig rock tiles beside an existing tunnel."
	if is_digging_at(cell):
		return "Already digging here."
	var touches := false
	for offset: Vector2i in ORTHO:
		if get_cell(GameState.level_data, cell + offset) == MacroCell.TUNNEL:
			touches = true
			break
	if not touches:
		return "Must dig rock adjacent to a tunnel."
	return ""


static func can_place_tower(anchor: Vector2i, tower_type: String) -> String:
	var blocked := _action_blocked()
	if blocked != "":
		return blocked
	if not GameTuning.TOWER_COSTS.has(tower_type):
		return "Unknown structure type."
	var size := footprint_for(tower_type)
	for foot_cell: Vector2i in footprint_cells(anchor, size):
		if not cell_in_bounds(foot_cell, GameState.level_data):
			return "Structure does not fit here."
		var cell_type := get_cell(GameState.level_data, foot_cell)
		if cell_type != MacroCell.ROCK:
			return "Chambers must be carved in rock beside tunnels."
		if is_digging_at(foot_cell):
			return "Wait for digging to finish."
		if is_building_at(foot_cell):
			return "Wait for construction to finish."
		if cell_under_tower(foot_cell):
			return "Overlaps another structure."
		if not GameState.get_mine_at(foot_cell).is_empty():
			return "Overlaps a mine."
	if not footprint_touches_tunnel(GameState.level_data, anchor, size):
		return "Must be adjacent to a tunnel."
	return ""


static func can_place_mine(cell: Vector2i) -> String:
	var blocked := _action_blocked()
	if blocked != "":
		return blocked
	if get_cell(GameState.level_data, cell) != MacroCell.TUNNEL:
		return "Mines go on tunnel tiles."
	if not GameState.get_mine_at(cell).is_empty():
		return "A mine is already on this tile."
	if cell_under_tower(cell):
		return "Blocked by a structure."
	if is_digging_at(cell):
		return "Wait for digging to finish."
	if is_building_at(cell):
		return "Wait for construction to finish."
	return ""


static func tower_covering(cell: Vector2i) -> Dictionary:
	for tower in GameState.towers:
		if cell in tower_footprint_cells(tower):
			return tower
	return {}
