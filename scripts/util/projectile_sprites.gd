extends RefCounted
class_name ProjectileSprites

const FRAME_SIZE := 32
const SPITTER_FRAME_SEC := 0.08
const SPITTER_SPLAT_FRAME_SEC := 0.07

static var _spitter_frames: SpriteFrames
static var _spitter_splat_frames: SpriteFrames


static func spitter_sprite_frames() -> SpriteFrames:
	if _spitter_frames != null:
		return _spitter_frames
	var sheet_path := SpritePaths.spitter_projectile_sheet()
	if ResourceLoader.exists(sheet_path):
		_spitter_frames = _sprite_frames_from_sheet(sheet_path, &"fly", true, SPITTER_FRAME_SEC)
	else:
		_spitter_frames = _fallback_spitter_frames()
	return _spitter_frames


static func spitter_splat_sprite_frames() -> SpriteFrames:
	if _spitter_splat_frames != null:
		return _spitter_splat_frames
	var sheet_path := SpritePaths.spitter_splat_sheet()
	if ResourceLoader.exists(sheet_path):
		_spitter_splat_frames = _sprite_frames_from_sheet(
			sheet_path, &"splat", false, SPITTER_SPLAT_FRAME_SEC
		)
	else:
		_spitter_splat_frames = spitter_sprite_frames()
	return _spitter_splat_frames


static func spitter_splat_duration() -> float:
	var frames := spitter_splat_sprite_frames()
	return float(frames.get_frame_count(&"splat")) * SPITTER_SPLAT_FRAME_SEC


static func spitter_splat_frame_index(elapsed_sec: float) -> int:
	var frames := spitter_splat_sprite_frames()
	var count := frames.get_frame_count(&"splat")
	return mini(count - 1, int(elapsed_sec / SPITTER_SPLAT_FRAME_SEC))


static func _sprite_frames_from_sheet(
	sheet_path: String,
	anim_name: StringName,
	loop: bool,
	frame_sec: float,
) -> SpriteFrames:
	var sheet: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	var count := maxi(1, int(float(sheet.get_width()) / float(FRAME_SIZE)))
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, atlas, frame_sec)
	return frames


static func _fallback_spitter_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	var image := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in FRAME_SIZE:
		for x in FRAME_SIZE:
			var dx := absf(x - FRAME_SIZE * 0.5)
			var dy := absf(y - FRAME_SIZE * 0.5)
			if dx + dy < FRAME_SIZE * 0.42:
				image.set_pixel(x, y, TowerSprites.projectile_color("spitter"))
	var tex := ImageTexture.create_from_image(image)
	frames.add_frame(&"fly", tex, SPITTER_FRAME_SEC)
	return frames
