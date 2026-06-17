extends RefCounted
class_name TowerSprites

const SIZE := 32


static func make_tower_texture(tower_type: String) -> Texture2D:
	match tower_type:
		"spitter":
			return _load_or_make("res://assets/sprites/spitter.png", _draw_spitter)
		"crusher":
			return _draw_procedural(_draw_crusher)
		"needle":
			return _draw_procedural(_draw_needle)
		"gland":
			return _draw_procedural(_draw_gland)
		"mine":
			return _draw_procedural(_draw_mine)
		_:
			return _draw_procedural(_draw_spitter)


static func projectile_color(tower_type: String) -> Color:
	match tower_type:
		"spitter":
			return Color(0.42, 1.0, 0.29)
		"needle":
			return Color(0.65, 0.7, 0.95)
		"crusher":
			return Color(1.0, 0.55, 0.25)
		_:
			return Color(0.78, 0.72, 0.63)


static func effect_color(tower_type: String) -> Color:
	return projectile_color(tower_type)


static func _load_or_make(path: String, fallback: Callable) -> Texture2D:
	var image := Image.new()
	if image.load(path) == OK:
		if image.get_width() != SIZE or image.get_height() != SIZE:
			image.resize(SIZE, SIZE, Image.INTERPOLATE_NEAREST)
		return ImageTexture.create_from_image(image)
	return _draw_procedural(fallback)


static func _draw_procedural(draw_fn: Callable) -> Texture2D:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	draw_fn.call(image)
	return ImageTexture.create_from_image(image)


static func _draw_spitter(image: Image) -> void:
	var base := Color(0.28, 0.42, 0.22)
	var acid := Color(0.42, 1.0, 0.29)
	for y in SIZE:
		for x in SIZE:
			var dx := absf(x - SIZE * 0.5)
			var dy := y - SIZE * 0.55
			if dx < 10.0 - dy * 0.15 and dy < 8.0:
				image.set_pixel(x, y, base)
			if dx < 3.0 and y >= 10 and y < 18:
				image.set_pixel(x, y, acid)


static func _draw_crusher(image: Image) -> void:
	var body := Color(0.55, 0.32, 0.22)
	var rim := Color(0.38, 0.22, 0.16)
	for y in SIZE:
		for x in SIZE:
			var dx := (x - SIZE * 0.5) / 11.0
			var dy := (y - SIZE * 0.55) / 9.0
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, body)
			elif dx * dx + dy * dy <= 1.25:
				image.set_pixel(x, y, rim)


static func _draw_needle(image: Image) -> void:
	var shaft := Color(0.55, 0.58, 0.68)
	var tip := Color(0.78, 0.82, 0.95)
	for y in SIZE:
		for x in SIZE:
			if absf(x - SIZE * 0.5) < 2.5 and y >= 8 and y < 26:
				image.set_pixel(x, y, shaft)
			if absf(x - SIZE * 0.5) < 1.5 and y >= 4 and y < 12:
				image.set_pixel(x, y, tip)
			if absf(x - SIZE * 0.5) < 3.5 and y >= 22 and y < 28:
				image.set_pixel(x, y, Color(0.35, 0.35, 0.42))


static func _draw_gland(image: Image) -> void:
	var core := Color(0.58, 0.28, 0.68)
	var glow := Color(0.78, 0.45, 0.88, 0.55)
	for y in SIZE:
		for x in SIZE:
			var dx := (x - SIZE * 0.5) / 10.0
			var dy := (y - SIZE * 0.5) / 10.0
			var d := dx * dx + dy * dy
			if d <= 0.55:
				image.set_pixel(x, y, core)
			elif d <= 1.0:
				image.set_pixel(x, y, glow)


static func _draw_mine(image: Image) -> void:
	var cap := Color(0.45, 0.78, 0.32)
	var stem := Color(0.32, 0.55, 0.22)
	for y in SIZE:
		for x in SIZE:
			var dx := x - SIZE * 0.5
			var dy := y - SIZE * 0.5
			if dx * dx + dy * dy <= 36.0:
				image.set_pixel(x, y, cap)
			if absf(dx) < 4.0 and y >= 14 and y < 24:
				image.set_pixel(x, y, stem)
