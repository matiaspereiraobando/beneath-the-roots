extends RefCounted

const BASIC_PATH := "res://assets/tilesets/macro_basic_tiles.png"
const AUTOTILE_PATH := "res://assets/tilesets/macro_terrain_atlas.png"
const BASIC_TILE_COUNT := 16
const AUTOTILE_GRID := 16
const SOURCE_BASIC := 0
const SOURCE_AUTOTILE := 1
const MAGENTA_THRESHOLD := 0.9

# Mask bits: NW=128 N=1 NE=2 E=4 SE=8 S=16 SW=32 W=64
const CARDINAL_MASK := 1 | 4 | 16 | 64

var tile_set: TileSet
var valid_masks: Dictionary = {}
var _mask_fallbacks: Dictionary = {}
var _warned_masks: Dictionary = {}


func _init() -> void:
	_build()


func basic_atlas_coords(tile: int) -> Vector2i:
	return Vector2i(int(tile), 0)


func autotile_atlas_coords(mask: int) -> Vector2i:
	return Vector2i(mask % AUTOTILE_GRID, mask >> 4)


func resolve_mask(mask: int) -> int:
	if valid_masks.get(mask, false):
		return mask
	if _mask_fallbacks.has(mask):
		return _mask_fallbacks[mask]
	var best := 0
	var best_pop := -1
	var best_card := -1
	for sub in range(mask + 1):
		if (sub & mask) != sub:
			continue
		if not valid_masks.get(sub, false):
			continue
		var pop: int = _popcount(sub)
		var card: int = _popcount(sub & CARDINAL_MASK)
		if pop > best_pop or (pop == best_pop and card > best_card):
			best = sub
			best_pop = pop
			best_card = card
	if mask != best and not _warned_masks.has(mask):
		_warned_masks[mask] = true
		push_warning("Autotile mask %d missing; using fallback mask %d" % [mask, best])
	_mask_fallbacks[mask] = best
	return best


func _build() -> void:
	var tile_size := GameTuning.TILE_SIZE
	var basic_image := _load_image(BASIC_PATH)
	_ensure_soft_earth_tile(basic_image, tile_size)
	var autotile_image := _load_image(AUTOTILE_PATH)
	_key_magenta_transparent(autotile_image)
	valid_masks = _scan_valid_masks(autotile_image, tile_size)
	if not valid_masks.get(0, false):
		push_warning("Autotile mask 0 (plain dirt) is missing from macro_terrain_atlas.png")
		valid_masks[0] = true
	var basic_tex := ImageTexture.create_from_image(basic_image)
	var autotile_tex := ImageTexture.create_from_image(autotile_image)
	var basic_atlas := TileSetAtlasSource.new()
	basic_atlas.texture = basic_tex
	basic_atlas.texture_region_size = Vector2i(tile_size, tile_size)
	for i in BASIC_TILE_COUNT:
		basic_atlas.create_tile(Vector2i(i, 0))
	var autotile_atlas := TileSetAtlasSource.new()
	autotile_atlas.texture = autotile_tex
	autotile_atlas.texture_region_size = Vector2i(tile_size, tile_size)
	for mask in range(256):
		var coords := autotile_atlas_coords(mask)
		if valid_masks.get(mask, false):
			autotile_atlas.create_tile(coords)
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "walkable")
	tile_set.set_custom_data_layer_type(0, TYPE_BOOL)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(1, "build_slot")
	tile_set.set_custom_data_layer_type(1, TYPE_BOOL)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(2, "citadel")
	tile_set.set_custom_data_layer_type(2, TYPE_BOOL)
	tile_set.add_source(basic_atlas, SOURCE_BASIC)
	tile_set.add_source(autotile_atlas, SOURCE_AUTOTILE)
	_apply_basic_custom_data(basic_atlas)


func _apply_basic_custom_data(atlas: TileSetAtlasSource) -> void:
	for i in BASIC_TILE_COUNT:
		if not atlas.has_tile(Vector2i(i, 0)):
			continue
		var tile_data := atlas.get_tile_data(Vector2i(i, 0), 0)
		var walkable := i in [1, 3, 5, 6]  # surface, tunnel, spawn, citadel
		tile_data.set_custom_data("walkable", walkable)
		tile_data.set_custom_data("build_slot", i == 4)
		tile_data.set_custom_data("citadel", i == 6)


func _ensure_soft_earth_tile(image: Image, tile_size: int) -> void:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var ox := 7 * tile_size
	for y in tile_size:
		for x in tile_size:
			var edge := x < 2 or y < 2 or x >= tile_size - 2 or y >= tile_size - 2
			var color := Color(0.52, 0.38, 0.26) if edge else Color(0.62, 0.46, 0.32)
			image.set_pixel(ox + x, y, color)


func _load_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	if texture:
		return texture.get_image()
	var image := Image.new()
	if image.load(path) != OK:
		push_error("Failed to load macro tile image: %s" % path)
		return Image.create(32, 32, false, Image.FORMAT_RGBA8)
	return image


func _key_magenta_transparent(image: Image) -> void:
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if _is_magenta(c):
				image.set_pixel(x, y, Color(0, 0, 0, 0))


func _is_magenta(c: Color) -> bool:
	return c.r > 0.98 and c.g < 0.04 and c.b > 0.98


func _scan_valid_masks(image: Image, tile_size: int) -> Dictionary:
	var valid: Dictionary = {}
	for mask in range(256):
		var col := mask % AUTOTILE_GRID
		var row := mask >> 4
		var magenta := 0
		var total := tile_size * tile_size
		for y in tile_size:
			for x in tile_size:
				var px := image.get_pixel(col * tile_size + x, row * tile_size + y)
				if _is_magenta(px) or px.a < 0.1:
					magenta += 1
		if float(magenta) / float(total) < MAGENTA_THRESHOLD:
			valid[mask] = true
	return valid


func _popcount(value: int) -> int:
	var n := 0
	while value > 0:
		n += value & 1
		value >>= 1
	return n
