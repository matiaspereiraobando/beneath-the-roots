extends RefCounted
class_name LevelLoader

const LEVEL_DIR := "res://data/levels/"

static func load_level(level_id: String) -> Dictionary:
	var path := LEVEL_DIR + level_id + ".json"
	if not FileAccess.file_exists(path):
		path = LEVEL_DIR + "level0_test.json"
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
			row.append(PlaceholderTilesets.MacroTile.ROCK)
		cells.append(row)
	for x in cols:
		cells[0][x] = PlaceholderTilesets.MacroTile.SKY
		cells[1][x] = PlaceholderTilesets.MacroTile.SKY
	for x in mini(8, cols):
		cells[2][x] = PlaceholderTilesets.MacroTile.SURFACE
	for x in range(8, cols):
		cells[2][x] = PlaceholderTilesets.MacroTile.SKY
	var spawn: Vector2i = Vector2i(data.spawnTile.x, data.spawnTile.y)
	cells[spawn.y][spawn.x] = PlaceholderTilesets.MacroTile.SPAWN
	var build_set := {}
	for slot in data.get("buildSlots", []):
		build_set[Vector2i(slot.x, slot.y)] = true
	for pair in data.get("tunnelTiles", []):
		var c := Vector2i(pair[0], pair[1])
		if build_set.has(c):
			cells[c.y][c.x] = PlaceholderTilesets.MacroTile.BUILD
		else:
			cells[c.y][c.x] = PlaceholderTilesets.MacroTile.TUNNEL
	var rect: Dictionary = data.citadelRect
	for dy in rect.h:
		for dx in rect.w:
			var cx: int = rect.x + dx
			var cy: int = rect.y + dy
			if cx >= 0 and cx < cols and cy >= 0 and cy < rows:
				cells[cy][cx] = PlaceholderTilesets.MacroTile.CITADEL
	data["cells"] = cells
	return data
