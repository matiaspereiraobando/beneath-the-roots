extends RefCounted
class_name LevelLoader

const LEVEL_DIR := "res://data/levels/"
const MacroCell = preload("res://scripts/data/macro_tiles.gd").Cell

static func load_level(level_id: String) -> Dictionary:
	var path := LEVEL_DIR + level_id + ".json"
	if not FileAccess.file_exists(path):
		path = LEVEL_DIR + "first_breach.json"
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid level JSON: %s" % path)
		return {}
	return _build_grid(data)


static func _build_grid(data: Dictionary) -> Dictionary:
	var cols: int = data.gridSize.cols
	var rows: int = data.gridSize.rows
	var cells: Array = []
	for y in rows:
		var row: Array = []
		for x in cols:
			row.append(MacroCell.ROCK)
		cells.append(row)
	for y in GameTuning.MACRO_SKY_ROWS:
		for x in cols:
			cells[y][x] = MacroCell.SKY
	for x in cols:
		cells[GameTuning.MACRO_SKY_ROWS][x] = MacroCell.SURFACE
	var spawn: Vector2i = Vector2i(data.spawnTile.x, data.spawnTile.y)
	cells[spawn.y][spawn.x] = MacroCell.SPAWN
	for pair in data.get("tunnelTiles", []):
		var c := Vector2i(pair[0], pair[1])
		cells[c.y][c.x] = MacroCell.TUNNEL
	var rect: Dictionary = data.citadelRect
	for dy in rect.h:
		for dx in rect.w:
			var cx: int = rect.x + dx
			var cy: int = rect.y + dy
			if cx >= 0 and cx < cols and cy >= 0 and cy < rows:
				cells[cy][cx] = MacroCell.CITADEL
	data["cells"] = cells
	return data
