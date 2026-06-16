extends RefCounted

const TILESET_PATH := "res://assets/tilesets/citadel_interior.png"
const TILE_SIZE := 16
const TILE_COUNT := 6

var tile_set: TileSet


func _init() -> void:
	_build()


func tile_to_atlas(tile: int) -> Vector2i:
	return Vector2i(int(tile), 0)


func _build() -> void:
	var image := _load_image()
	var tex := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in TILE_COUNT:
		atlas.create_tile(Vector2i(i, 0))
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(atlas, 0)


func _load_image() -> Image:
	var image := Image.new()
	if image.load(TILESET_PATH) == OK:
		return image
	var texture := load(TILESET_PATH) as Texture2D
	if texture:
		return texture.get_image()
	push_error("Missing citadel interior tileset: %s" % TILESET_PATH)
	return _fallback_image()


func _fallback_image() -> Image:
	var colors: Array[Color] = [
		Color(0.28, 0.22, 0.18),
		Color(0.14, 0.11, 0.09),
		Color(0.22, 0.28, 0.20),
		Color(0.30, 0.22, 0.18),
		Color(0.38, 0.16, 0.32),
		Color(0.24, 0.20, 0.16),
	]
	var image := Image.create(TILE_SIZE * TILE_COUNT, TILE_SIZE, false, Image.FORMAT_RGBA8)
	for i in TILE_COUNT:
		var c: Color = colors[i]
		for x in TILE_SIZE:
			for y in TILE_SIZE:
				image.set_pixel(i * TILE_SIZE + x, y, c)
	return image
