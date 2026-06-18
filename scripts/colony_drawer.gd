extends PanelContainer

signal collapse_requested

const AntType = preload("res://scripts/data/ant_types.gd").Type
const EMPTY_SLOT = preload("res://scripts/data/ant_types.gd").EMPTY_SLOT
const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
const GestationBarScript = preload("res://scripts/ui/gestation_bar.gd")
const DRAWER_SLOT_SIZE := 32

@onready var _collapse_btn: Button = $Margin/Scroll/VBox/HeaderRow/CollapseBtn
@onready var _slot_col: VBoxContainer = $Margin/Scroll/VBox/SlotCol
@onready var _add_btn: Button = $Margin/Scroll/VBox/AddBtn
@onready var _placeholder: Label = $Margin/Scroll/VBox/FutureActions/Placeholder

var _icon_textures: Dictionary = {}
var _slot_buttons: Array[TextureButton] = []
var _gestation_bars: Array[Control] = []
var _type_menu: PopupMenu


func _ready() -> void:
	theme_type_variation = &"GameHud"
	_apply_fonts()
	_icon_textures = ColonyUiIcons.load_icon_map(DRAWER_SLOT_SIZE)
	_build_slot_rows()
	_setup_add_menu()
	_collapse_btn.pressed.connect(func() -> void: collapse_requested.emit())
	_add_btn.pressed.connect(_on_add_pressed)
	GameState.nursery_changed.connect(_refresh_slots)
	call_deferred("_refresh_slots")


func _apply_fonts() -> void:
	var title: Label = $Margin/Scroll/VBox/HeaderRow/Title
	for node in [title, _placeholder]:
		HudThemeRes.apply_pixel_font(node, HudThemeRes.FONT_STAT)
	for btn in [_collapse_btn, _add_btn]:
		HudThemeRes.apply_pixel_font(btn, HudThemeRes.FONT_STAT)
	_add_btn.add_theme_stylebox_override("normal", HudThemeRes.ant_strip())
	_add_btn.add_theme_stylebox_override("hover", HudThemeRes.wave_pill())
	_add_btn.add_theme_stylebox_override("pressed", HudThemeRes.ant_strip())


func _build_slot_rows() -> void:
	var well_size := DRAWER_SLOT_SIZE + 6
	for i in GameState.NURSERY_SLOTS:
		var well := PanelContainer.new()
		well.add_theme_stylebox_override("panel", HudThemeRes.icon_well())
		well.custom_minimum_size = Vector2(well_size, well_size)
		var center := CenterContainer.new()
		center.custom_minimum_size = well.custom_minimum_size
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(DRAWER_SLOT_SIZE, DRAWER_SLOT_SIZE)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_on_slot_pressed.bind(i))
		center.add_child(btn)
		well.add_child(center)
		_slot_buttons.append(btn)
		if i == 0:
			var col := VBoxContainer.new()
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			col.add_theme_constant_override("separation", 3)
			var gest_bar: Control = GestationBarScript.new()
			gest_bar.bar_thickness = 4
			gest_bar.custom_minimum_size = Vector2(well_size, 4)
			col.add_child(gest_bar)
			_gestation_bars.append(gest_bar)
			col.add_child(well)
			_slot_col.add_child(col)
		else:
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(well)
			_slot_col.add_child(row)


func _setup_add_menu() -> void:
	_type_menu = PopupMenu.new()
	_type_menu.add_item("Gatherer", AntType.GATHERER)
	_type_menu.add_item("Builder", AntType.BUILDER)
	_type_menu.add_item("Soldier", AntType.SOLDIER)
	_type_menu.id_pressed.connect(_on_type_selected)
	add_child(_type_menu)


func _on_add_pressed() -> void:
	if not GameState.can_enqueue_nursery():
		return
	var pos := _add_btn.get_global_rect().position
	pos.y += _add_btn.size.y
	_type_menu.position = Vector2i(int(pos.x), int(pos.y))
	_type_menu.popup()


func _on_type_selected(id: int) -> void:
	GameState.enqueue_nursery_ant(id)


func _on_slot_pressed(index: int) -> void:
	GameState.cycle_nursery_slot(index)


func _refresh_slots() -> void:
	ColonyUiIcons.refresh_slot_buttons(_slot_buttons, _icon_textures)
	_add_btn.disabled = not GameState.can_enqueue_nursery()
	_add_btn.modulate = Color.WHITE if GameState.can_enqueue_nursery() else Color(0.5, 0.5, 0.5, 0.8)
	if _gestation_bars.size() > 0:
		_gestation_bars[0].visible = GameState.nursery_queue[0] != EMPTY_SLOT
