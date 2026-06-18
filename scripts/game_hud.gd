extends PanelContainer

const PixelArt = preload("res://scripts/util/pixel_art.gd")
const SpritePaths = preload("res://scripts/util/sprite_paths.gd")
const ColonyUiIcons = preload("res://scripts/util/colony_ui_icons.gd")
const HudThemeRes = preload("res://scripts/util/hud_theme.gd")

@onready var _biomass_icon: TextureRect = $Margin/Row/BiomassBlock/IconWell/BiomassIcon
@onready var _biomass_value: Label = $Margin/Row/BiomassBlock/BiomassText/Value
@onready var _wave_label: Label = $Margin/Row/WavePill/PillRow/WaveLabel
@onready var _wave_ring: Control = $Margin/Row/WavePill/PillRow/WaveRing
@onready var _builder_icon: TextureRect = $Margin/Row/AntStrip/StripRow/BuilderRow/Icon
@onready var _builder_count: Label = $Margin/Row/AntStrip/StripRow/BuilderRow/Count
@onready var _gatherer_icon: TextureRect = $Margin/Row/AntStrip/StripRow/GathererRow/Icon
@onready var _gatherer_count: Label = $Margin/Row/AntStrip/StripRow/GathererRow/Count
@onready var _soldier_icon: TextureRect = $Margin/Row/AntStrip/StripRow/SoldierRow/Icon
@onready var _soldier_count: Label = $Margin/Row/AntStrip/StripRow/SoldierRow/Count
@onready var _hp_bar: Control = $Margin/Row/StatusColumn/HpRow/HpBar
@onready var _satiety_bar: Control = $Margin/Row/StatusColumn/SatRow/SatBar


func _ready() -> void:
	theme_type_variation = &"GameHud"
	custom_minimum_size = Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.HUD_HEIGHT)
	_apply_panel_styles()
	_load_icons()
	_wire_signals()
	_refresh_all()


func _apply_panel_styles() -> void:
	$Margin/Row/BiomassBlock/IconWell.add_theme_stylebox_override("panel", HudThemeRes.icon_well())
	$Margin/Row/WavePill.add_theme_stylebox_override("panel", HudThemeRes.wave_pill())
	$Margin/Row/AntStrip.add_theme_stylebox_override("panel", HudThemeRes.ant_strip())
	_biomass_value.add_theme_color_override("font_color", HudThemeRes.SECONDARY)
	HudThemeRes.apply_pixel_label(_biomass_value, HudThemeRes.FONT_STAT)
	$Margin/Row/BiomassBlock/BiomassText/Title.add_theme_color_override(
		"font_color", HudThemeRes.ON_SURFACE_VARIANT
	)
	HudThemeRes.apply_pixel_label($Margin/Row/BiomassBlock/BiomassText/Title, HudThemeRes.FONT_STAT)
	_wave_label.add_theme_color_override("font_color", HudThemeRes.PRIMARY)
	HudThemeRes.apply_pixel_label(_wave_label, HudThemeRes.FONT_STAT)
	for count_lbl in [_builder_count, _gatherer_count, _soldier_count]:
		HudThemeRes.apply_pixel_label(count_lbl, HudThemeRes.FONT_STAT)
		count_lbl.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE)
	_hp_bar.set_fill_colors(HudThemeRes.ERROR.lerp(Color.BLACK, 0.2), HudThemeRes.HP_FILL_END)
	_satiety_bar.set_fill_colors(HudThemeRes.SATIETY_FILL_START, HudThemeRes.SATIETY_FILL_END)


func _load_icons() -> void:
	var brighten := GameTuning.UI_ICON_BRIGHTEN
	var biomass_size := 24
	var ant_size := 18
	var bar_icon_size := 16
	_biomass_icon.texture = PixelArt.load_texture(
		SpritePaths.ui_icon("icon_biomass"), biomass_size, brighten
	)
	_biomass_icon.custom_minimum_size = Vector2(biomass_size, biomass_size)
	_builder_icon.texture = PixelArt.load_texture(
		SpritePaths.ui_icon("icon_builder"), ant_size, brighten
	)
	_gatherer_icon.texture = PixelArt.load_texture(
		SpritePaths.ui_icon("icon_gatherer"), ant_size, brighten
	)
	_soldier_icon.texture = PixelArt.load_texture(
		SpritePaths.ui_icon("icon_soldier"), ant_size, brighten
	)
	for icon in [_builder_icon, _gatherer_icon, _soldier_icon]:
		icon.custom_minimum_size = Vector2(ant_size, ant_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_biomass_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_biomass_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var hp_icon: TextureRect = $Margin/Row/StatusColumn/HpRow/HpIcon
	var sat_icon: TextureRect = $Margin/Row/StatusColumn/SatRow/SatIcon
	hp_icon.texture = _make_heart_texture(bar_icon_size)
	sat_icon.texture = PixelArt.load_texture(
		SpritePaths.ui_icon("icon_satiety"), bar_icon_size, brighten
	)
	for icon in [hp_icon, sat_icon]:
		icon.custom_minimum_size = Vector2(bar_icon_size, bar_icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _make_heart_texture(tex_size: int) -> Texture2D:
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var c := HudThemeRes.ERROR
	for y in tex_size:
		for x in tex_size:
			var nx := (float(x) / float(tex_size - 1)) * 2.0 - 1.0
			var ny := (float(y) / float(tex_size - 1)) * 2.0 - 1.0
			var heart := pow(nx * nx + ny * ny - 0.3, 3.0) - nx * nx * ny * ny * ny
			if heart <= 0.0:
				image.set_pixel(x, y, c)
	return ImageTexture.create_from_image(image)


func _wire_signals() -> void:
	GameState.biomass_changed.connect(_on_biomass_changed)
	GameState.next_wave_timer_changed.connect(func(_t): _refresh_wave())
	GameState.phase_changed.connect(func(_p): _refresh_wave())
	GameState.colony_counts_changed.connect(_refresh_ants)
	GameState.soldiers_changed.connect(_refresh_ants)
	GameState.queen_hp_changed.connect(_on_queen_hp_changed)
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.level_loaded.connect(func(_id): _refresh_all())


func _refresh_all() -> void:
	_on_biomass_changed(GameState.biomass)
	_refresh_wave()
	_refresh_ants(GameState.free_soldiers)
	_on_queen_hp_changed(GameState.queen_hp, GameState.queen_max_hp)
	_on_satiety_changed(GameState.queen_satiety)


func _on_biomass_changed(value: int) -> void:
	_biomass_value.text = str(value)


func _refresh_wave() -> void:
	var total := maxi(1, GameState.get_wave_count())
	var invasion := GameState.invasion_active()
	match GameState.phase:
		GameState.Phase.WON:
			_wave_label.text = "VICTORY"
			_wave_label.modulate = HudThemeRes.SECONDARY
		GameState.Phase.LOST:
			_wave_label.text = "FALLEN"
			_wave_label.modulate = HudThemeRes.ERROR
		_:
			_wave_label.text = "WAVE %d/%d" % [GameState.get_active_wave_number(), total]
			_wave_label.modulate = HudThemeRes.PRIMARY if invasion else HudThemeRes.SECONDARY
	_wave_ring.set_invasion_active(invasion and GameState.is_playing())
	var interval := GameTuning.WAVE_INTERVAL
	if GameState.next_wave_index >= GameState.get_wave_count():
		_wave_ring.set_timer(0.0, interval)
	else:
		_wave_ring.set_timer(GameState.next_wave_timer, interval)


func _refresh_ants(_count: int = 0) -> void:
	_builder_count.text = str(GameState.builder_count)
	_gatherer_count.text = str(GameState.gatherer_count)
	_soldier_count.text = str(GameState.free_soldiers)


func _on_queen_hp_changed(current: int, maximum: int) -> void:
	var max_hp := maxf(1.0, float(maximum))
	_hp_bar.set_ratio(float(current) / max_hp)


func _on_satiety_changed(value: float) -> void:
	_satiety_bar.set_ratio(value / 100.0)
	var col := ColonyUiIcons.satiety_color(value)
	_satiety_bar.set_fill_colors(
		col.darkened(0.25),
		col,
	)
