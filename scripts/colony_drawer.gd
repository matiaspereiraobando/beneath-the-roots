extends PanelContainer

signal collapse_requested

const AntType = preload("res://scripts/data/ant_types.gd").Type
const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
const DRAWER_SLOT_SIZE := 32

@onready var _collapse_btn: Button = $Margin/Scroll/VBox/HeaderRow/CollapseBtn
@onready var _satiety_label: Label = $Margin/Scroll/VBox/SatietyLabel
@onready var _feed_btn: Button = $Margin/Scroll/VBox/FeedBtn
@onready var _colony_label: Label = $Margin/Scroll/VBox/ColonyLabel
@onready var _slot_col: VBoxContainer = $Margin/Scroll/VBox/SlotCol
@onready var _placeholder: Label = $Margin/Scroll/VBox/FutureActions/Placeholder

var _icon_textures: Dictionary = {}
var _slot_buttons: Array[TextureButton] = []


func _ready() -> void:
	theme_type_variation = &"ColonyDrawer"
	_apply_fonts()
	_icon_textures = ColonyUiIcons.load_icon_map(DRAWER_SLOT_SIZE)
	_build_slot_buttons()
	_collapse_btn.pressed.connect(func() -> void: collapse_requested.emit())
	_feed_btn.pressed.connect(_on_feed_pressed)
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.nursery_changed.connect(_refresh_slots)
	GameState.colony_counts_changed.connect(_refresh_colony_counts)
	_on_satiety_changed(GameState.queen_satiety)
	call_deferred("_refresh_slots")
	call_deferred("_refresh_colony_counts")


func _apply_fonts() -> void:
	var title: Label = $Margin/Scroll/VBox/HeaderRow/Title
	for node in [title, _satiety_label, _colony_label, _placeholder]:
		HudThemeRes.apply_pixel_font(node, HudThemeRes.FONT_STAT)
	for btn in [_collapse_btn, _feed_btn]:
		HudThemeRes.apply_pixel_font(btn, HudThemeRes.FONT_STAT)


func _build_slot_buttons() -> void:
	for i in GameState.NURSERY_SLOTS:
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(DRAWER_SLOT_SIZE, DRAWER_SLOT_SIZE)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_slot_pressed.bind(i))
		_slot_col.add_child(btn)
		_slot_buttons.append(btn)


func _on_slot_pressed(index: int) -> void:
	GameState.cycle_nursery_slot(index)


func _on_feed_pressed() -> void:
	GameState.feed_queen()


func _refresh_slots() -> void:
	ColonyUiIcons.refresh_slot_buttons(_slot_buttons, _icon_textures)
	_feed_btn.text = "Feed (%d)" % GameTuning.FEED_COST


func _refresh_colony_counts() -> void:
	_colony_label.text = "G:%d  B:%d  S:%d" % [
		GameState.gatherer_count,
		GameState.builder_count,
		GameState.free_soldiers,
	]


func _on_satiety_changed(value: float) -> void:
	_satiety_label.text = "Satiety: %d%%" % int(value)
	_satiety_label.modulate = ColonyUiIcons.satiety_color(value)
