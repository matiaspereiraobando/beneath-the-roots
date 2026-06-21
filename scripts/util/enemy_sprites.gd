extends RefCounted
class_name EnemySprites

const FRAME_SIZE := 32
const ENEMIES_DIR := "res://assets/sprites/enemies/"
const ENEMY_TYPES := ["skitter", "mite", "chitin", "borer", "scarab"]


static func make_walk_sprite_frames(enemy_type: String) -> SpriteFrames:
	var sheet_path := SpritePaths.enemy_walk_sheet(enemy_type)
	if ResourceLoader.exists(sheet_path):
		return _sprite_frames_from_sheet(sheet_path, enemy_type)
	return _fallback_sprite_frames(enemy_type)


static func make_static_texture(enemy_type: String) -> Texture2D:
	var static_path := SpritePaths.enemy_static(enemy_type)
	if ResourceLoader.exists(static_path):
		return load(static_path) as Texture2D
	var frames := make_walk_sprite_frames(enemy_type)
	if frames.has_animation(&"walk") and frames.get_frame_count(&"walk") > 0:
		return frames.get_frame_texture(&"walk", 0)
	return _fallback_texture(enemy_type)


static func _sprite_frames_from_sheet(sheet_path: String, enemy_type: String) -> SpriteFrames:
	var sheet: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	var meta := _load_walk_meta(enemy_type)
	var frame_sec := GameTuning.ENEMY_WALK_FRAME_SEC
	if meta.has("frame_ms"):
		frame_sec = float(meta.frame_ms) / 1000.0
	var count := int(meta.get("frames", 0))
	if count <= 0:
		count = maxi(1, int(float(sheet.get_width()) / float(FRAME_SIZE)))
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(&"walk", atlas, frame_sec)
	return frames


static func _load_walk_meta(enemy_type: String) -> Dictionary:
	var meta_path := ENEMIES_DIR + enemy_type + "/walk.meta.txt"
	if not FileAccess.file_exists(meta_path):
		return {}
	var meta: Dictionary = {}
	for line in FileAccess.get_file_as_string(meta_path).split("\n"):
		var parts := line.split("=", true, 1)
		if parts.size() == 2:
			var key := parts[0].strip_edges()
			var val := parts[1].strip_edges()
			meta[key] = int(val) if val.is_valid_int() else val
	return meta


static func _fallback_sprite_frames(enemy_type: String) -> SpriteFrames:
	var tex := _fallback_texture(enemy_type)
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.add_frame(&"walk", tex, GameTuning.ENEMY_WALK_FRAME_SEC)
	return frames


static func _fallback_texture(enemy_type: String) -> Texture2D:
	var legacy := "res://assets/sprites/skitter.png"
	if enemy_type == "skitter" and ResourceLoader.exists(legacy):
		return load(legacy) as Texture2D
	var color := _fallback_color(enemy_type)
	var image := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in FRAME_SIZE:
		for x in FRAME_SIZE:
			var dx := absf(x - FRAME_SIZE * 0.5)
			var dy := y - FRAME_SIZE * 0.55
			if dx < 10.0 - dy * 0.12 and dy < 10.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func _fallback_color(enemy_type: String) -> Color:
	match enemy_type:
		"mite":
			return Color(0.75, 0.45, 0.4)
		"chitin":
			return Color(0.55, 0.35, 0.28)
		"borer":
			return Color(0.5, 0.48, 0.42)
		"scarab":
			return Color(0.35, 0.22, 0.45)
		_:
			return Color(0.65, 0.28, 0.22)
