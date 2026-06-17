extends PanelContainer

signal expand_requested

const AntType = preload("res://scripts/data/ant_types.gd").Type
const RAIL_SLOT_SIZE := 24
const RAIL_COUNT_ICON := 16

@onready var _expand_btn: Button = $Margin/VBox/ExpandBtn
@onready var _satiety_bar: ProgressBar = $Margin/VBox/SatietyBar
@onready var _gatherer_label: Label = $Margin/VBox/Counts/GathererCol/CountLabel
@onready var _builder_label: Label = $Margin/VBox/Counts/BuilderCol/CountLabel
@onready var _soldier_label: Label = $Margin/VBox/Counts/SoldierCol/CountLabel
@onready var _gatherer_icon: TextureRect = $Margin/VBox/Counts/GathererCol/Icon
@onready var _builder_icon: TextureRect = $Margin/VBox/Counts/BuilderCol/Icon
@onready var _soldier_icon: TextureRect = $Margin/VBox/Counts/SoldierCol/Icon
@onready var _slot_col: VBoxContainer = $Margin/VBox/SlotCol

var _icon_textures: Dictionary = {}
var _slot_buttons: Array[TextureButton] = []
var _pulse_tween: Tween


func _ready() -> void:
	theme_type_variation = &"ColonyRail"
	clip_contents = true
	_icon_textures = ColonyUiIcons.load_icon_map(RAIL_SLOT_SIZE)
	_setup_count_icons()
	_build_slot_buttons()
	_expand_btn.pressed.connect(func() -> void: expand_requested.emit())
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.nursery_changed.connect(_refresh_slots)
	GameState.colony_counts_changed.connect(_refresh_colony_counts)
	_on_satiety_changed(GameState.queen_satiety)
	call_deferred("_refresh_slots")
	call_deferred("_refresh_colony_counts")


func set_expanded_tab(expanded: bool) -> void:
	_expand_btn.text = "»" if expanded else "«"


func pulse_breach() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	modulate = Color.WHITE
	_pulse_tween = create_tween()
	_pulse_tween.set_loops(2)
	_pulse_tween.tween_property(self, "modulate", Color(1.0, 0.35, 0.35), 0.12)
	_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func _setup_count_icons() -> void:
	var brighten := GameTuning.UI_ICON_BRIGHTEN
	var icon_size := GameTuning.UI_ICON_NATIVE_SIZE
	_gatherer_icon.texture = PixelArt.load_texture(SpritePaths.ui_icon("icon_gatherer"), icon_size, brighten)
	_builder_icon.texture = PixelArt.load_texture(SpritePaths.ui_icon("icon_builder"), icon_size, brighten)
	_soldier_icon.texture = PixelArt.load_texture(SpritePaths.ui_icon("icon_soldier"), icon_size, brighten)
	for icon in [_gatherer_icon, _builder_icon, _soldier_icon]:
		icon.custom_minimum_size = Vector2(RAIL_COUNT_ICON, RAIL_COUNT_ICON)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _build_slot_buttons() -> void:
	for i in GameState.NURSERY_SLOTS:
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(RAIL_SLOT_SIZE, RAIL_SLOT_SIZE)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_slot_pressed.bind(i))
		_slot_col.add_child(btn)
		_slot_buttons.append(btn)


func _on_slot_pressed(index: int) -> void:
	GameState.cycle_nursery_slot(index)


func _refresh_slots() -> void:
	ColonyUiIcons.refresh_slot_buttons(_slot_buttons, _icon_textures)


func _refresh_colony_counts() -> void:
	_gatherer_label.text = str(GameState.gatherer_count)
	_builder_label.text = str(GameState.builder_count)
	_soldier_label.text = str(GameState.free_soldiers)


func _on_satiety_changed(value: float) -> void:
	_satiety_bar.value = value
	_satiety_bar.modulate = ColonyUiIcons.satiety_color(value)
