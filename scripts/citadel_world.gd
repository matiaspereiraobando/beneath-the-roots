extends Node2D

@onready var floor_map: TileMapLayer = $FloorMap
@onready var queen_overlay: ColorRect = $QueenOverlay

const GRID_W := 19
const GRID_H := 29

var _flash_time := 0.0


func _ready() -> void:
	floor_map.tile_set = PlaceholderTilesets.build_citadel_tileset()
	_paint_citadel()
	GameState.citadel_breached.connect(_on_breach)
	queen_overlay.visible = false


func _paint_citadel() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var tile := PlaceholderTilesets.CitadelTile.FLOOR
			if x == 0 or x == GRID_W - 1 or y == 0 or y == GRID_H - 1:
				tile = PlaceholderTilesets.CitadelTile.WALL
			elif y >= 20 and x >= 6 and x <= 12:
				tile = PlaceholderTilesets.CitadelTile.QUEEN
			elif y >= 8 and y <= 14 and x >= 2 and x <= 7:
				tile = PlaceholderTilesets.CitadelTile.NURSERY
			elif y >= 8 and y <= 14 and x >= 11 and x <= 16:
				tile = PlaceholderTilesets.CitadelTile.ARMORY
			elif y == 15 and x >= 4 and x <= 14:
				tile = PlaceholderTilesets.CitadelTile.CORRIDOR
			floor_map.set_cell(
				Vector2i(x, y),
				0,
				PlaceholderTilesets.citadel_tile_to_atlas(tile)
			)


func _process(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		var t := _flash_time / 0.5
		queen_overlay.modulate = Color(1, 0.3, 0.3, t * 0.6)
		if _flash_time <= 0.0:
			queen_overlay.visible = false


func _on_breach(_damage: int) -> void:
	_flash_time = 0.5
	queen_overlay.visible = true
	queen_overlay.position = Vector2(6 * 16, 20 * 16)
	queen_overlay.size = Vector2(7 * 16, 9 * 16)
