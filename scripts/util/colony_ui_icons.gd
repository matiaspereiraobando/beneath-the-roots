extends RefCounted
class_name ColonyUiIcons

const AntType = preload("res://scripts/data/ant_types.gd").Type
const EMPTY_SLOT = preload("res://scripts/data/ant_types.gd").EMPTY_SLOT


static func load_icon_map(slot_icon_size: int = 28) -> Dictionary:
	var brighten := GameTuning.UI_ICON_BRIGHTEN
	var size := GameTuning.UI_ICON_NATIVE_SIZE
	var icons: Dictionary = {}
	icons[EMPTY_SLOT] = PixelArt.load_texture(SpritePaths.ui_icon("slot_empty"), size, brighten)
	icons[AntType.GATHERER] = PixelArt.load_texture(SpritePaths.ui_icon("icon_gatherer"), size, brighten)
	icons[AntType.BUILDER] = PixelArt.load_texture(SpritePaths.ui_icon("icon_builder"), size, brighten)
	icons[AntType.SOLDIER] = PixelArt.load_texture(SpritePaths.ui_icon("icon_soldier"), size, brighten)
	if icons[EMPTY_SLOT] == null:
		icons[EMPTY_SLOT] = _make_color_tex(Color(0.2, 0.18, 0.16), slot_icon_size)
	if icons[AntType.GATHERER] == null:
		icons[AntType.GATHERER] = _make_color_tex(Color(0.55, 0.35, 0.28), slot_icon_size)
	if icons[AntType.BUILDER] == null:
		icons[AntType.BUILDER] = _make_color_tex(Color(0.45, 0.38, 0.28), slot_icon_size)
	if icons[AntType.SOLDIER] == null:
		icons[AntType.SOLDIER] = _make_color_tex(Color(0.35, 0.28, 0.24), slot_icon_size)
	return icons


static func refresh_slot_buttons(buttons: Array, icon_map: Dictionary) -> void:
	if buttons.is_empty() or GameState.nursery_queue.size() < GameState.NURSERY_SLOTS:
		return
	for i in buttons.size():
		var slot_type: int = GameState.nursery_queue[i]
		var btn: TextureButton = buttons[i]
		var tex: Texture2D = icon_map.get(slot_type, icon_map[EMPTY_SLOT])
		btn.texture_normal = tex
		if i == 0:
			btn.disabled = true
		else:
			btn.disabled = slot_type == EMPTY_SLOT
		if slot_type == EMPTY_SLOT:
			btn.modulate = Color(0.55, 0.55, 0.58, 0.75)
			btn.tooltip_text = "Empty queue slot"
		elif i == 0:
			btn.modulate = Color(0.92, 0.92, 0.95)
			btn.tooltip_text = "Gestating — type locked"
		else:
			btn.modulate = Color.WHITE
			btn.tooltip_text = "Click to change ant type"


static func satiety_color(value: float) -> Color:
	if value < GameTuning.STARVE_THRESHOLD:
		return Color(1, 0.45, 0.45)
	if value < GameTuning.AUTO_FEED_THRESHOLD:
		return Color(1, 0.85, 0.5)
	return Color(0.55, 0.95, 0.55)


static func _make_color_tex(color: Color, icon_size: int) -> Texture2D:
	var image := Image.create(icon_size, icon_size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
