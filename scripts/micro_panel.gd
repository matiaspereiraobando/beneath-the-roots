extends PanelContainer

const AntType = preload("res://scripts/data/ant_types.gd").Type
const EMPTY_SLOT = preload("res://scripts/data/ant_types.gd").EMPTY_SLOT

@onready var _satiety_label: Label = $Margin/VBox/SatietyLabel
@onready var _viewport: SubViewport = $Margin/VBox/SubViewportContainer/SubViewport
@onready var _colony_label: Label = $Margin/VBox/ColonyRow/ColonyLabel
@onready var _feed_btn: Button = $Margin/VBox/ControlRow/FeedBtn
@onready var _slot_row: HBoxContainer = $Margin/VBox/SlotRow
@onready var _slot_buttons: Array[TextureButton] = []

var _icon_textures: Dictionary = {}


func _ready() -> void:
	theme_type_variation = &"MicroPanel"
	custom_minimum_size = Vector2(GameConfig.micro_width(), GameConfig.panel_height())
	var w := GameConfig.micro_width() - 16
	var h := GameConfig.panel_height() - 120
	_viewport.size = Vector2i(w, h)
	_load_icons()
	_build_slot_buttons()
	_feed_btn.pressed.connect(_on_feed_pressed)
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.nursery_changed.connect(_refresh_slots)
	GameState.colony_counts_changed.connect(_refresh_colony_counts)
	_on_satiety_changed(GameState.queen_satiety)
	call_deferred("_refresh_slots")
	call_deferred("_refresh_colony_counts")


func _load_icons() -> void:
	_icon_textures[EMPTY_SLOT] = _load_tex("res://assets/sprites/ui/slot_empty.png")
	_icon_textures[AntType.GATHERER] = _load_tex("res://assets/sprites/ui/icon_gatherer.png")
	_icon_textures[AntType.BUILDER] = _load_tex("res://assets/sprites/ui/icon_builder.png")
	_icon_textures[AntType.SOLDIER] = _load_tex("res://assets/sprites/ui/icon_soldier.png")
	if _icon_textures[EMPTY_SLOT] == null:
		_icon_textures[EMPTY_SLOT] = _make_color_tex(Color(0.2, 0.18, 0.16))
	if _icon_textures[AntType.GATHERER] == null:
		_icon_textures[AntType.GATHERER] = _make_color_tex(Color(0.55, 0.35, 0.28))
	if _icon_textures[AntType.BUILDER] == null:
		_icon_textures[AntType.BUILDER] = _make_color_tex(Color(0.45, 0.38, 0.28))
	if _icon_textures[AntType.SOLDIER] == null:
		_icon_textures[AntType.SOLDIER] = _make_color_tex(Color(0.35, 0.28, 0.24))


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _make_color_tex(color: Color) -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _build_slot_buttons() -> void:
	for i in GameState.NURSERY_SLOTS:
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(28, 28)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_slot_pressed.bind(i))
		_slot_row.add_child(btn)
		_slot_buttons.append(btn)


func _on_slot_pressed(index: int) -> void:
	GameState.cycle_nursery_slot(index)


func _on_feed_pressed() -> void:
	GameState.feed_queen()


func _refresh_slots() -> void:
	if _slot_buttons.is_empty() or GameState.nursery_queue.size() < GameState.NURSERY_SLOTS:
		return
	for i in _slot_buttons.size():
		var slot_type: int = GameState.nursery_queue[i]
		var tex: Texture2D = _icon_textures.get(slot_type, _icon_textures[EMPTY_SLOT])
		_slot_buttons[i].texture_normal = tex
	_feed_btn.text = "Feed (%d)" % GameTuning.FEED_COST


func _refresh_colony_counts() -> void:
	_colony_label.text = "G:%d  B:%d  S:%d" % [
		GameState.gatherer_count,
		GameState.builder_count,
		GameState.free_soldiers,
	]


func _on_satiety_changed(value: float) -> void:
	_satiety_label.text = "Satiety: %d%%" % int(value)
	if value < GameTuning.STARVE_THRESHOLD:
		_satiety_label.modulate = Color(1, 0.45, 0.45)
	elif value < GameTuning.AUTO_FEED_THRESHOLD:
		_satiety_label.modulate = Color(1, 0.85, 0.5)
	else:
		_satiety_label.modulate = Color(1, 1, 1)
