extends RefCounted
class_name PlaceholderTilesets
## Runtime placeholder TileSets for micro citadel until art is integrated.

enum CitadelTile { FLOOR, WALL, NURSERY, ARMORY, QUEEN, CORRIDOR }

const CITADEL_TILE_COUNT := 6

const CITADEL_COLORS: Array[Color] = [
	Color(0.28, 0.22, 0.18),
	Color(0.14, 0.11, 0.09),
	Color(0.22, 0.28, 0.20),
	Color(0.30, 0.22, 0.18),
	Color(0.38, 0.16, 0.32),
	Color(0.24, 0.20, 0.16),
]


static func build_citadel_tileset(tile_size: int = 16) -> TileSet:
	var atlas_image := Image.create(tile_size * CITADEL_TILE_COUNT, tile_size, false, Image.FORMAT_RGBA8)
	for i in CITADEL_TILE_COUNT:
		var c: Color = CITADEL_COLORS[i]
		for x in tile_size:
			for y in tile_size:
				atlas_image.set_pixel(i * tile_size + x, y, c)
	var atlas_tex := ImageTexture.create_from_image(atlas_image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = atlas_tex
	atlas.texture_region_size = Vector2i(tile_size, tile_size)
	for i in CITADEL_TILE_COUNT:
		atlas.create_tile(Vector2i(i, 0))
	var tileset := TileSet.new()
	tileset.add_source(atlas, 0)
	return tileset


static func citadel_tile_to_atlas(tile: CitadelTile) -> Vector2i:
	return Vector2i(int(tile), 0)
