extends RefCounted

const TILESET_PATH := "res://assets/tilesets/citadel_interior.png"
const SOURCE_TILE_SIZE := 16
const TILE_COUNT := 6

var tile_set: TileSet


func _init() -> void:
	_build()


func tile_to_atlas(tile: int) -> Vector2i:
	return Vector2i(int(tile), 0)


func _build() -> void:
	var image := _load_image()
	var tile_size := GameTuning.MICRO_TILE_SIZE
	if image.get_height() == SOURCE_TILE_SIZE and tile_size != SOURCE_TILE_SIZE:
		image = _upscale_tile_row(image, tile_size)
	var tex := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(tile_size, tile_size)
	for i in TILE_COUNT:
		atlas.create_tile(Vector2i(i, 0))
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_source(atlas, 0)


func _upscale_tile_row(image: Image, tile_size: int) -> Image:
	var scale := tile_size / float(SOURCE_TILE_SIZE)
	var out_w := image.get_width() * scale
	var out_h := tile_size
	var out := Image.create(out_w, out_h, false, Image.FORMAT_RGBA8)
	for ty in SOURCE_TILE_SIZE:
		for tx in image.get_width():
			var c := image.get_pixel(tx, ty)
			for sy in scale:
				for sx in scale:
					out.set_pixel(tx * scale + sx, ty * scale + sy, c)
	return out


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
	var tile_size := GameTuning.MICRO_TILE_SIZE
	var colors: Array[Color] = [
		Color(0.28, 0.22, 0.18),
		Color(0.14, 0.11, 0.09),
		Color(0.22, 0.28, 0.20),
		Color(0.30, 0.22, 0.18),
		Color(0.38, 0.16, 0.32),
		Color(0.24, 0.20, 0.16),
	]
	var image := Image.create(tile_size * TILE_COUNT, tile_size, false, Image.FORMAT_RGBA8)
	for i in TILE_COUNT:
		var c: Color = colors[i]
		for x in tile_size:
			for y in tile_size:
				image.set_pixel(i * tile_size + x, y, c)
	return image
