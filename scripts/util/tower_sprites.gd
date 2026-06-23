extends RefCounted
class_name TowerSprites

const SIZE := 32
const TOWER_FRAME_SIZE := 64
const MINE_FRAME_SIZE := 32
const STRUCTURES_DIR := "res://assets/sprites/structures/"


static func make_structure_sprite_frames(structure_type: String) -> SpriteFrames:
	var sheet_path := STRUCTURES_DIR + structure_type + "/idle_sheet.png"
	if ResourceLoader.exists(sheet_path):
		var frame_size := _frame_size_for(structure_type)
		return _sprite_frames_from_sheet(sheet_path, frame_size, structure_type)
	return _fallback_sprite_frames(structure_type)


static func make_tower_texture(tower_type: String) -> Texture2D:
	var static_path := STRUCTURES_DIR + tower_type + "/static.png"
	if ResourceLoader.exists(static_path):
		return load(static_path) as Texture2D
	var frames := make_structure_sprite_frames(tower_type)
	if frames.has_animation(&"idle") and frames.get_frame_count(&"idle") > 0:
		return frames.get_frame_texture(&"idle", 0)
	return _draw_procedural(_fallback_draw_fn(tower_type))


static func structure_native_size(structure_type: String) -> Vector2i:
	return Vector2i(
		_mine_frame_size() if structure_type == "mine" else TOWER_FRAME_SIZE,
		_mine_frame_size() if structure_type == "mine" else TOWER_FRAME_SIZE,
	)


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


const MINE_EXPLODE_FRAME_SEC := 0.08

static var _mine_explode_frames: SpriteFrames


static func mine_explode_sprite_frames() -> SpriteFrames:
	if _mine_explode_frames != null:
		return _mine_explode_frames
	var sheet_path := SpritePaths.mine_explode_sheet()
	if ResourceLoader.exists(sheet_path):
		var sheet: Texture2D = load(sheet_path)
		_mine_explode_frames = SpriteFrames.new()
		_mine_explode_frames.add_animation(&"explode")
		_mine_explode_frames.set_animation_loop(&"explode", false)
		var count := maxi(1, int(float(sheet.get_width()) / float(MINE_FRAME_SIZE)))
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2i(i * MINE_FRAME_SIZE, 0, MINE_FRAME_SIZE, MINE_FRAME_SIZE)
			_mine_explode_frames.add_frame(&"explode", atlas, MINE_EXPLODE_FRAME_SEC)
	else:
		_mine_explode_frames = _fallback_mine_explode_frames()
	return _mine_explode_frames


static func mine_explode_duration() -> float:
	var frames := mine_explode_sprite_frames()
	return float(frames.get_frame_count(&"explode")) * MINE_EXPLODE_FRAME_SEC


static func mine_explode_frame_index(elapsed_sec: float) -> int:
	var frames := mine_explode_sprite_frames()
	var count := frames.get_frame_count(&"explode")
	return mini(count - 1, int(elapsed_sec / MINE_EXPLODE_FRAME_SEC))


static func _fallback_mine_explode_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"explode")
	frames.set_animation_loop(&"explode", false)
	var tex := _draw_procedural(_draw_mine, MINE_FRAME_SIZE)
	frames.add_frame(&"explode", tex, MINE_EXPLODE_FRAME_SEC)
	return frames


static func _frame_size_for(structure_type: String) -> int:
	return _mine_frame_size() if structure_type == "mine" else TOWER_FRAME_SIZE


static func _mine_frame_size() -> int:
	return MINE_FRAME_SIZE


static func _sprite_frames_from_sheet(sheet_path: String, frame_size: int, structure_type: String = "") -> SpriteFrames:
	var sheet: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	var meta := _load_structure_meta(structure_type)
	var frame_sec := GameTuning.STRUCTURE_IDLE_FRAME_SEC
	var count := int(meta.get("frames", 0))
	if count <= 0:
		var sheet_w := int(sheet.get_width())
		count = maxi(1, int(float(sheet_w) / float(frame_size)))
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(i * frame_size, 0, frame_size, frame_size)
		frames.add_frame(&"idle", atlas, frame_sec)
	return frames


static func _load_structure_meta(structure_type: String) -> Dictionary:
	if structure_type.is_empty():
		return {}
	var meta_path := STRUCTURES_DIR + structure_type + "/idle.meta.txt"
	if not FileAccess.file_exists(meta_path):
		return {}
	var meta: Dictionary = {}
	for line in FileAccess.get_file_as_string(meta_path).split("\n"):
		var parts := line.split("=", true, 1)
		if parts.size() == 2:
			meta[parts[0].strip_edges()] = int(parts[1].strip_edges())
	return meta


static func _fallback_sprite_frames(structure_type: String) -> SpriteFrames:
	var frame_size := _frame_size_for(structure_type)
	var tex := _draw_procedural(_fallback_draw_fn(structure_type), frame_size)
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.add_frame(&"idle", tex, GameTuning.STRUCTURE_IDLE_FRAME_SEC)
	return frames


static func _fallback_draw_fn(structure_type: String) -> Callable:
	match structure_type:
		"crusher":
			return _draw_crusher
		"needle":
			return _draw_needle
		"gland":
			return _draw_gland
		"mine":
			return _draw_mine
		_:
			return _draw_spitter


static func _load_or_make(path: String, fallback: Callable, size: int = SIZE) -> Texture2D:
	var image := Image.new()
	if image.load(path) == OK:
		if image.get_width() != size or image.get_height() != size:
			image.resize(size, size, Image.INTERPOLATE_NEAREST)
		return ImageTexture.create_from_image(image)
	return _draw_procedural(fallback, size)


static func _draw_procedural(draw_fn: Callable, size: int = SIZE) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	draw_fn.call(image, size)
	return ImageTexture.create_from_image(image)


static func _draw_spitter(image: Image, size: int) -> void:
	var base := Color(0.28, 0.42, 0.22)
	var acid := Color(0.42, 1.0, 0.29)
	for y in size:
		for x in size:
			var dx := absf(x - size * 0.5)
			var dy := y - size * 0.55
			if dx < 10.0 - dy * 0.15 and dy < 8.0:
				image.set_pixel(x, y, base)
			if dx < 3.0 and y >= 10 and y < 18:
				image.set_pixel(x, y, acid)


static func _draw_crusher(image: Image, size: int) -> void:
	var body := Color(0.55, 0.32, 0.22)
	var rim := Color(0.38, 0.22, 0.16)
	for y in size:
		for x in size:
			var dx := (x - size * 0.5) / (size * 0.34375)
			var dy := (y - size * 0.55) / (size * 0.28125)
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, body)
			elif dx * dx + dy * dy <= 1.25:
				image.set_pixel(x, y, rim)


static func _draw_needle(image: Image, size: int) -> void:
	var shaft := Color(0.55, 0.58, 0.68)
	var tip := Color(0.78, 0.82, 0.95)
	for y in size:
		for x in size:
			if absf(x - size * 0.5) < 2.5 and y >= size * 0.25 and y < size * 0.8125:
				image.set_pixel(x, y, shaft)
			if absf(x - size * 0.5) < 1.5 and y >= size * 0.125 and y < size * 0.375:
				image.set_pixel(x, y, tip)
			if absf(x - size * 0.5) < 3.5 and y >= size * 0.6875 and y < size * 0.875:
				image.set_pixel(x, y, Color(0.35, 0.35, 0.42))


static func _draw_gland(image: Image, size: int) -> void:
	var core := Color(0.58, 0.28, 0.68)
	var glow := Color(0.78, 0.45, 0.88, 0.55)
	for y in size:
		for x in size:
			var dx := (x - size * 0.5) / (size * 0.3125)
			var dy := (y - size * 0.5) / (size * 0.3125)
			var d := dx * dx + dy * dy
			if d <= 0.55:
				image.set_pixel(x, y, core)
			elif d <= 1.0:
				image.set_pixel(x, y, glow)


static func _draw_mine(image: Image, size: int) -> void:
	var cap := Color(0.45, 0.78, 0.32)
	var stem := Color(0.32, 0.55, 0.22)
	var radius_sq := (size * 0.5625) * (size * 0.5625)
	for y in size:
		for x in size:
			var dx := x - size * 0.5
			var dy := y - size * 0.5
			if dx * dx + dy * dy <= radius_sq:
				image.set_pixel(x, y, cap)
			if absf(dx) < size * 0.125 and y >= size * 0.4375 and y < size * 0.75:
				image.set_pixel(x, y, stem)
