extends RefCounted

const MacroCell = preload("res://scripts/data/macro_tiles.gd").Cell
const PlacementRules = preload("res://scripts/systems/placement.gd")
const SOURCE_BASIC := 0
const SOURCE_AUTOTILE := 1
const BASIC_STRUCTURE_BASE := 4

const MASK_N := 1
const MASK_NE := 2
const MASK_E := 4
const MASK_SE := 8
const MASK_S := 16
const MASK_SW := 32
const MASK_W := 64
const MASK_NW := 128

const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const MASK_BITS: Array[int] = [
	MASK_N, MASK_NE, MASK_E, MASK_SE, MASK_S, MASK_SW, MASK_W, MASK_NW,
]

# Logic enum order differs from basic atlas column order (spawn/citadel swapped).
const BASIC_ATLAS: Dictionary = {
	MacroCell.SKY: 0,
	MacroCell.SURFACE: 1,
	MacroCell.TUNNEL: 3,
	MacroCell.SPAWN: 5,
	MacroCell.CITADEL: 6,
}


func paint_all(tile_map: TileMapLayer, cells: Array, tileset) -> void:
	tile_map.clear()
	for y in cells.size():
		for x in cells[y].size():
			_paint_cell(tile_map, cells, x, y, tileset)


func refresh_region(
	tile_map: TileMapLayer,
	cells: Array,
	center: Vector2i,
	radius: int,
	tileset,
) -> void:
	var rows: int = cells.size()
	if rows == 0:
		return
	var cols: int = cells[0].size()
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x := center.x + dx
			var y := center.y + dy
			if x < 0 or y < 0 or y >= rows or x >= cols:
				continue
			_paint_cell(tile_map, cells, x, y, tileset)


func compute_tunnel_mask(cells: Array, x: int, y: int) -> int:
	var mask := 0
	for i in OFFSETS.size():
		var n := Vector2i(x, y) + OFFSETS[i]
		if not _in_bounds(cells, n):
			continue
		if _counts_as_tunnel_neighbor(cells, n):
			mask |= MASK_BITS[i]
	return mask


func _paint_cell(tile_map: TileMapLayer, cells: Array, x: int, y: int, tileset) -> void:
	var cell_type: int = cells[y][x]
	var source_id: int
	var atlas: Vector2i
	if cell_type == MacroCell.ROCK and _cell_under_tower(x, y):
		source_id = SOURCE_BASIC
		atlas = tileset.basic_atlas_coords(BASIC_STRUCTURE_BASE)
	elif cell_type == MacroCell.ROCK:
		var mask := compute_tunnel_mask(cells, x, y)
		mask = tileset.resolve_mask(mask)
		source_id = SOURCE_AUTOTILE
		atlas = tileset.autotile_atlas_coords(mask)
	else:
		source_id = SOURCE_BASIC
		atlas = tileset.basic_atlas_coords(BASIC_ATLAS.get(cell_type, 0))
	tile_map.set_cell(Vector2i(x, y), source_id, atlas)


func _cell_under_tower(x: int, y: int) -> bool:
	return PlacementRules.cell_under_tower(Vector2i(x, y))


func _counts_as_tunnel_neighbor(cells: Array, pos: Vector2i) -> bool:
	if cells[pos.y][pos.x] == MacroCell.TUNNEL:
		return true
	return PlacementRules.cell_under_tower(pos)


func _in_bounds(cells: Array, pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= cells.size():
		return false
	if pos.x < 0 or pos.x >= cells[pos.y].size():
		return false
	return true
