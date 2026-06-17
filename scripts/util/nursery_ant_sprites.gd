extends RefCounted
class_name NurseryAntSprites

const AntType = preload("res://scripts/data/ant_types.gd").Type

static var _cache: Dictionary = {}


static func texture_for_type(ant_type: int) -> Texture2D:
	if _cache.has(ant_type):
		return _cache[ant_type]
	var tex: Texture2D
	match ant_type:
		AntType.GATHERER:
			tex = _make_ant_tex(Color(0.22, 0.16, 0.12), 8, 11)
		AntType.BUILDER:
			tex = _make_ant_tex(Color(0.28, 0.2, 0.14), 9, 12)
		AntType.SOLDIER:
			tex = _make_soldier_tex()
		_:
			tex = _make_ant_tex(Color(0.2, 0.15, 0.11), 8, 11)
	_cache[ant_type] = tex
	return tex


static func queen_texture() -> Texture2D:
	if _cache.has("queen"):
		return _cache["queen"]
	var tex := _make_queen_tex()
	_cache["queen"] = tex
	return tex


static func _make_ant_tex(body: Color, w: int, h: int) -> Texture2D:
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var outline := Color(0.05, 0.04, 0.03)
	_fill_oval(image, Vector2(w * 0.35, h * 0.72), Vector2(w * 0.32, h * 0.22), body, outline)
	_fill_oval(image, Vector2(w * 0.5, h * 0.42), Vector2(w * 0.22, h * 0.18), body.lightened(0.08), outline)
	_fill_oval(image, Vector2(w * 0.62, h * 0.22), Vector2(w * 0.2, h * 0.16), body.lightened(0.12), outline)
	for i in 3:
		var ly := int(h * (0.35 + i * 0.12))
		image.set_pixel(1, ly, outline)
		image.set_pixel(w - 2, ly, outline)
	return ImageTexture.create_from_image(image)


static func _make_soldier_tex() -> Texture2D:
	var w := 10
	var h := 12
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var body := Color(0.24, 0.17, 0.12)
	var outline := Color(0.05, 0.04, 0.03)
	_fill_oval(image, Vector2(w * 0.38, h * 0.72), Vector2(w * 0.34, h * 0.24), body, outline)
	_fill_oval(image, Vector2(w * 0.52, h * 0.42), Vector2(w * 0.24, h * 0.18), body.lightened(0.06), outline)
	_fill_oval(image, Vector2(w * 0.68, h * 0.24), Vector2(w * 0.22, h * 0.17), body.lightened(0.1), outline)
	image.set_pixel(w - 1, int(h * 0.18), outline)
	image.set_pixel(w - 1, int(h * 0.28), outline)
	image.set_pixel(w - 2, int(h * 0.22), Color(0.45, 0.32, 0.22))
	return ImageTexture.create_from_image(image)


static func _make_queen_tex() -> Texture2D:
	var w := 28
	var h := 22
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var body := Color(0.42, 0.22, 0.38)
	var highlight := Color(0.72, 0.55, 0.48)
	var outline := Color(0.12, 0.06, 0.1)
	_fill_oval(image, Vector2(w * 0.42, h * 0.58), Vector2(w * 0.38, h * 0.34), body, outline)
	_fill_oval(image, Vector2(w * 0.55, h * 0.35), Vector2(w * 0.2, h * 0.16), body.lightened(0.1), outline)
	_fill_oval(image, Vector2(w * 0.68, h * 0.22), Vector2(w * 0.14, h * 0.12), highlight, outline)
	for x in range(int(w * 0.2), int(w * 0.65)):
		if image.get_pixel(x, int(h * 0.52)).a > 0.5:
			image.set_pixel(x, int(h * 0.52), outline.darkened(0.2))
	return ImageTexture.create_from_image(image)


static func _fill_oval(
	image: Image,
	center: Vector2,
	radius: Vector2,
	fill: Color,
	outline: Color
) -> void:
	var x0 := int(center.x - radius.x)
	var x1 := int(center.x + radius.x)
	var y0 := int(center.y - radius.y)
	var y1 := int(center.y + radius.y)
	for y in range(maxi(0, y0), mini(image.get_height(), y1 + 1)):
		for x in range(maxi(0, x0), mini(image.get_width(), x1 + 1)):
			var dx := (x - center.x) / maxf(radius.x, 0.001)
			var dy := (y - center.y) / maxf(radius.y, 0.001)
			var d := dx * dx + dy * dy
			if d <= 1.0:
				image.set_pixel(x, y, fill)
			elif d <= 1.25:
				image.set_pixel(x, y, outline)
