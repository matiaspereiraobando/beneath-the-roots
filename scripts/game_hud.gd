extends PanelContainer

const AntType = preload("res://scripts/data/ant_types.gd").Type
const SpritePaths = preload("res://scripts/util/sprite_paths.gd")
const ColonyUiIcons = preload("res://scripts/util/colony_ui_icons.gd")
const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
const HudIconAnimator = preload("res://scripts/ui/hud_icon_animator.gd")

const HUD_ICON_SIZE := 32

@onready var _biomass_icon: HudIconAnimator = $Margin/Row/BiomassBlock/IconWell/BiomassIcon
@onready var _biomass_value: Label = $Margin/Row/BiomassBlock/BiomassText/Value
@onready var _biomass_rate: Label = $Margin/Row/BiomassBlock/BiomassText/Rate
@onready var _wave_label: Label = $Margin/Row/WavePill/PillRow/WaveLabel
@onready var _wave_ring: Control = $Margin/Row/WavePill/PillRow/WaveRing
@onready var _builder_icon: HudIconAnimator = $Margin/Row/AntStrip/StripRow/BuilderRow/Icon
@onready var _builder_count: Label = $Margin/Row/AntStrip/StripRow/BuilderRow/Count
@onready var _gatherer_icon: HudIconAnimator = $Margin/Row/AntStrip/StripRow/GathererRow/Icon
@onready var _gatherer_count: Label = $Margin/Row/AntStrip/StripRow/GathererRow/Count
@onready var _soldier_icon: HudIconAnimator = $Margin/Row/AntStrip/StripRow/SoldierRow/Icon
@onready var _soldier_count: Label = $Margin/Row/AntStrip/StripRow/SoldierRow/Count
@onready var _hp_bar: Control = $Margin/Row/StatusRow/HpRow/HpBar
@onready var _hp_icon: HudIconAnimator = $Margin/Row/StatusRow/HpRow/HpIcon
@onready var _satiety_bar: Control = $Margin/Row/StatusRow/SatRow/SatBar
@onready var _satiety_icon: HudIconAnimator = $Margin/Row/StatusRow/SatRow/SatIcon

var _ant_icon_by_type: Dictionary = {}


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
	HudThemeRes.apply_pixel_label(_biomass_rate, HudThemeRes.FONT_CAPTION)
	_wave_label.add_theme_color_override("font_color", HudThemeRes.PRIMARY)
	HudThemeRes.apply_pixel_label(_wave_label, HudThemeRes.FONT_STAT)
	for count_lbl in [_builder_count, _gatherer_count, _soldier_count]:
		HudThemeRes.apply_pixel_label(count_lbl, HudThemeRes.FONT_STAT)
		count_lbl.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE)
	_hp_bar.set_fill_color(ColonyUiIcons.hp_color(1.0))
	_satiety_bar.set_fill_color(ColonyUiIcons.satiety_color(100.0))
	for bar in [_hp_bar, _satiety_bar]:
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.custom_minimum_size = Vector2(bar.custom_minimum_size.x, HudThemeRes.FONT_STAT)


func _load_icons() -> void:
	_setup_looping_icon(_biomass_icon, "biomass")
	_setup_ant_icon(_builder_icon, "builders", AntType.BUILDER)
	_setup_ant_icon(_gatherer_icon, "gatherers", AntType.GATHERER)
	_setup_ant_icon(_soldier_icon, "soldiers", AntType.SOLDIER)
	_setup_status_icon(_hp_icon, "health")
	_setup_status_icon(_satiety_icon, "satiety")


func _setup_looping_icon(icon: HudIconAnimator, kind: String) -> void:
	icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	icon.setup(
		SpritePaths.hud_icon(kind),
		SpritePaths.hud_icon_anim_sheet(kind),
		SpritePaths.hud_icon_anim_meta(kind),
	)
	icon.play_loop()


func _setup_status_icon(icon: HudIconAnimator, kind: String) -> void:
	icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	icon.setup(
		SpritePaths.hud_icon(kind),
		SpritePaths.hud_icon_anim_sheet(kind),
		SpritePaths.hud_icon_anim_meta(kind),
	)


func _update_status_icon_anim(icon: HudIconAnimator, is_critical: bool) -> void:
	if is_critical:
		icon.play_loop()
	else:
		icon.stop()


func _setup_ant_icon(icon: HudIconAnimator, kind: String, ant_type: int) -> void:
	icon.custom_minimum_size = Vector2(HUD_ICON_SIZE, HUD_ICON_SIZE)
	icon.setup(
		SpritePaths.hud_icon(kind),
		SpritePaths.hud_icon_anim_sheet(kind),
		SpritePaths.hud_icon_anim_meta(kind),
	)
	_ant_icon_by_type[ant_type] = icon


func _wire_signals() -> void:
	GameState.biomass_changed.connect(_on_biomass_changed)
	GameState.next_wave_timer_changed.connect(func(_t): _refresh_wave())
	GameState.phase_changed.connect(func(_p): _refresh_wave())
	GameState.colony_counts_changed.connect(_refresh_ants)
	GameState.soldiers_changed.connect(_refresh_ants)
	GameState.tower_soldiers_changed.connect(func(_t): _refresh_ants())
	GameState.tower_soldiers_changed.connect(func(_t): _refresh_biomass_rate())
	GameState.queen_hp_changed.connect(_on_queen_hp_changed)
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.ant_spawned.connect(_on_ant_spawned)
	GameState.level_loaded.connect(func(_id): _refresh_all())


func _refresh_all() -> void:
	_on_biomass_changed(GameState.biomass)
	_refresh_wave()
	_refresh_ants(GameState.free_soldiers)
	_on_queen_hp_changed(GameState.queen_hp, GameState.queen_max_hp)
	_on_satiety_changed(GameState.queen_satiety)


func _on_biomass_changed(value: int) -> void:
	_biomass_value.text = str(value)
	_refresh_biomass_rate()


func _refresh_biomass_rate() -> void:
	var net := GameState.biomass_net_per_second()
	if absf(net) < 0.05:
		_biomass_rate.text = ""
		return
	var sign := "+" if net >= 0.0 else ""
	_biomass_rate.text = "%s%.1f/s" % [sign, net]
	_biomass_rate.add_theme_color_override(
		"font_color",
		HudThemeRes.HP_FILL_END if net >= 0.0 else HudThemeRes.ERROR,
	)


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
	_builder_count.text = "%d/%d" % [GameState.builder_count, GameState.total_builder_count()]
	_gatherer_count.text = "%d/%d" % [GameState.gatherer_count, GameState.total_gatherer_count()]
	_soldier_count.text = "%d/%d" % [GameState.free_soldiers, GameState.total_soldier_count()]
	_refresh_biomass_rate()


func _on_queen_hp_changed(current: int, maximum: int) -> void:
	var max_hp := maxf(1.0, float(maximum))
	var ratio := float(current) / max_hp
	_hp_bar.set_ratio(ratio)
	_hp_bar.set_fill_color(ColonyUiIcons.hp_color(ratio))
	_update_status_icon_anim(_hp_icon, ColonyUiIcons.hp_is_critical(ratio))


func _on_satiety_changed(value: float) -> void:
	_satiety_bar.set_ratio(value / 100.0)
	_satiety_bar.set_fill_color(ColonyUiIcons.satiety_color(value))
	_update_status_icon_anim(_satiety_icon, ColonyUiIcons.satiety_is_critical(value))


func _on_ant_spawned(ant_type: int) -> void:
	var icon: HudIconAnimator = _ant_icon_by_type.get(ant_type)
	if icon:
		icon.play(2)
