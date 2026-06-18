extends TextureRect
class_name HudIconAnimator

const PixelArt = preload("res://scripts/util/pixel_art.gd")

var _static_texture: Texture2D
var _frames: Array[Texture2D] = []
var _frame_duration: float = 0.15
var _playing := false
var _loop_forever := false
var _loops_target := 0
var _loops_done := 0
var _frame_index := 0
var _accum := 0.0


func setup(static_path: String, sheet_path: String, meta_path: String = "") -> void:
	_static_texture = PixelArt.load_texture(static_path)
	texture = _static_texture
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_frames.clear()
	set_process(false)
	if not ResourceLoader.exists(sheet_path):
		return
	var frame_size := 32
	var frame_count := 0
	if ResourceLoader.exists(meta_path):
		var meta := _read_meta(meta_path)
		frame_size = int(meta.get("width", 32))
		frame_count = int(meta.get("frames", 0))
		_frame_duration = float(meta.get("frame_ms", 150)) / 1000.0
	var sheet: Texture2D = load(sheet_path)
	if sheet == null:
		return
	if frame_count <= 0:
		frame_count = maxi(1, int(float(sheet.get_width()) / float(frame_size)))
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(i * frame_size, 0, frame_size, frame_size)
		_frames.append(atlas)


func play(loops: int = 2) -> void:
	if _frames.is_empty():
		return
	_playing = true
	_loop_forever = false
	_loops_target = loops
	_loops_done = 0
	_frame_index = 0
	_accum = 0.0
	texture = _frames[0]
	set_process(true)


func play_loop() -> void:
	if _frames.is_empty():
		return
	if _playing and _loop_forever:
		return
	_playing = true
	_loop_forever = true
	_frame_index = 0
	_accum = 0.0
	texture = _frames[0]
	set_process(true)


func stop() -> void:
	_playing = false
	_loop_forever = false
	set_process(false)
	texture = _static_texture


func _process(delta: float) -> void:
	if not _playing:
		return
	_accum += delta
	while _accum >= _frame_duration:
		_accum -= _frame_duration
		_frame_index += 1
		if _frame_index >= _frames.size():
			_frame_index = 0
			_loops_done += 1
			if not _loop_forever and _loops_done >= _loops_target:
				stop()
				return
		texture = _frames[_frame_index]


static func _read_meta(path: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	for line in file.get_as_text().split("\n"):
		var parts := line.split("=", false, 1)
		if parts.size() == 2:
			result[parts[0].strip_edges()] = parts[1].strip_edges()
	return result
