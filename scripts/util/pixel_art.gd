extends RefCounted
class_name PixelArt

## Load pixel art with optional nearest upscale and shadow lift for dark sprites.

static func load_texture(
	path: String,
	display_size: int = 0,
	brighten: float = 1.0
) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		var tex := load(path) as Texture2D
		if tex == null:
			return null
		image = tex.get_image()
	if brighten > 1.0:
		_lift_image(image, brighten)
	if display_size > 0:
		var src_size := maxi(image.get_width(), image.get_height())
		if src_size > 0 and src_size != display_size:
			var scale := display_size / float(src_size)
			image.resize(
				maxi(1, int(image.get_width() * scale)),
				maxi(1, int(image.get_height() * scale)),
				Image.INTERPOLATE_NEAREST
			)
	return ImageTexture.create_from_image(image)


static func upscale_sheet_nearest(texture: Texture2D, frame_w: int, scale: int) -> Dictionary:
	if texture == null or scale <= 1:
		return {"texture": texture, "frame_w": frame_w}
	var image := texture.get_image()
	var new_w := image.get_width() * scale
	var new_h := image.get_height() * scale
	image.resize(new_w, new_h, Image.INTERPOLATE_NEAREST)
	return {
		"texture": ImageTexture.create_from_image(image),
		"frame_w": frame_w * scale,
	}


static func _lift_image(image: Image, brighten: float) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var lift := (brighten - 1.0) * 0.12
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.05:
				continue
			c.r = clampf(c.r * brighten + lift, 0.0, 1.0)
			c.g = clampf(c.g * brighten + lift, 0.0, 1.0)
			c.b = clampf(c.b * brighten + lift, 0.0, 1.0)
			image.set_pixel(x, y, c)
