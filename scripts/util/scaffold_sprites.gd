extends RefCounted
class_name ScaffoldSprites

const FRAME_SIZE := 64
const SCAFFOLD_FRAME_SEC := 0.45

static var _frames: SpriteFrames


static func make_sprite_frames() -> SpriteFrames:
	if _frames != null:
		return _frames
	var sheet_path := SpritePaths.scaffold_sheet()
	if ResourceLoader.exists(sheet_path):
		var sheet: Texture2D = load(sheet_path)
		_frames = SpriteFrames.new()
		_frames.add_animation(&"build")
		_frames.set_animation_loop(&"build", true)
		var count := maxi(1, int(float(sheet.get_width()) / float(FRAME_SIZE)))
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			_frames.add_frame(&"build", atlas, SCAFFOLD_FRAME_SEC)
	else:
		_frames = _fallback_frames()
	return _frames


static func _fallback_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"build")
	frames.set_animation_loop(&"build", true)
	var image := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.55, 0.42, 0.28, 0.85))
	var tex := ImageTexture.create_from_image(image)
	frames.add_frame(&"build", tex, SCAFFOLD_FRAME_SEC)
	return frames
