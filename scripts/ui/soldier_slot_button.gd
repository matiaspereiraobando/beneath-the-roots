extends TextureButton
class_name SoldierSlotButton

const FRAME_SIZE := 32


static func frame_from_sheet(sheet: Texture2D, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2i(index * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
	return atlas


static func load_sheet(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			return imported
	var image := Image.new()
	if image.load(path) == OK:
		return ImageTexture.create_from_image(image)
	return null


func setup_from_sheet(sheet_path: String) -> void:
	var sheet := load_sheet(sheet_path)
	if sheet == null:
		push_error("Soldier button sheet failed to load: %s" % sheet_path)
		return
	custom_minimum_size = Vector2(FRAME_SIZE, FRAME_SIZE)
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP
	texture_normal = frame_from_sheet(sheet, 0)
	texture_hover = frame_from_sheet(sheet, 1)
	texture_disabled = frame_from_sheet(sheet, 2)
