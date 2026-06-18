extends Control

const PixelArt = preload("res://scripts/util/pixel_art.gd")
const SpritePaths = preload("res://scripts/util/sprite_paths.gd")

@onready var _phase_label: Label = $Root/HUD/HudMargin/HudRow/PhaseLabel
@onready var _soldiers_label: Label = $Root/HUD/HudMargin/HudRow/SoldiersRow/SoldiersLabel
@onready var _biomass_icon: TextureRect = $Root/HUD/HudMargin/HudRow/BiomassRow/BiomassIcon
@onready var _biomass_label: Label = $Root/HUD/HudMargin/HudRow/BiomassRow/BiomassLabel
@onready var _satiety_icon: TextureRect = $Root/HUD/HudMargin/HudRow/SatietyRow/SatietyIcon
@onready var _satiety_label: Label = $Root/HUD/HudMargin/HudRow/SatietyRow/SatietyLabel
@onready var _soldiers_icon: TextureRect = $Root/HUD/HudMargin/HudRow/SoldiersRow/SoldiersIcon


func _ready() -> void:
	$Root/HUD.custom_minimum_size.y = GameConfig.HUD_HEIGHT
	_load_hud_icons()
	GameState.biomass_changed.connect(_on_biomass_changed)
	GameState.phase_changed.connect(func(_p): _refresh_hud())
	GameState.queen_hp_changed.connect(func(_c, _m): _refresh_hud())
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.next_wave_timer_changed.connect(func(_t): _refresh_phase_label())
	GameState.soldiers_changed.connect(_refresh_soldiers)
	_refresh_hud()
	_refresh_soldiers(GameState.free_soldiers)


func _load_hud_icons() -> void:
	var icon_size := GameTuning.HUD_ICON_SIZE
	var brighten := GameTuning.UI_ICON_BRIGHTEN
	_biomass_icon.texture = PixelArt.load_texture(SpritePaths.ui_icon("icon_biomass"), icon_size, brighten)
	_satiety_icon.texture = PixelArt.load_texture(SpritePaths.ui_icon("icon_satiety"), icon_size, brighten)
	_soldiers_icon.texture = PixelArt.load_texture(SpritePaths.ui_icon("icon_soldier"), icon_size, brighten)
	for icon in [_biomass_icon, _satiety_icon, _soldiers_icon]:
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _on_biomass_changed(value: int) -> void:
	_biomass_label.text = str(value)


func _refresh_hud() -> void:
	_on_biomass_changed(GameState.biomass)
	$Root/HUD/HudMargin/HudRow/WaveLabel.text = "Wave: %d/%d" % [
		GameState.get_active_wave_number(),
		maxi(1, GameState.get_wave_count()),
	]
	_refresh_phase_label()
	$Root/HUD/HudMargin/HudRow/QueenHpLabel.text = "Queen HP: %d/%d" % [GameState.queen_hp, GameState.queen_max_hp]
	_on_satiety_changed(GameState.queen_satiety)


func _on_satiety_changed(value: float) -> void:
	_satiety_label.text = "%d" % int(value)
	if value < GameTuning.STARVE_THRESHOLD:
		_satiety_label.modulate = Color(1, 0.45, 0.45)
	elif value < GameTuning.AUTO_FEED_THRESHOLD:
		_satiety_label.modulate = Color(1, 0.85, 0.5)
	else:
		_satiety_label.modulate = Color(1, 1, 1)


func _refresh_soldiers(count: int) -> void:
	_soldiers_label.text = "%d" % count


func _refresh_phase_label() -> void:
	match GameState.phase:
		GameState.Phase.PLAYING:
			var timer_text := int(ceilf(GameState.next_wave_timer))
			if GameState.next_wave_index >= GameState.get_wave_count():
				if GameState.invasion_active():
					_phase_label.text = "INVASION · clear the hive"
					_phase_label.modulate = Color(0.415686, 1, 0.290196, 1)
				else:
					_phase_label.text = "Between waves"
					_phase_label.modulate = Color(0.784314, 0.721569, 0.627451, 1)
			elif GameState.invasion_active():
				_phase_label.text = "INVASION · next wave %ds" % timer_text
				_phase_label.modulate = Color(0.415686, 1, 0.290196, 1)
			else:
				_phase_label.text = "Next wave %ds" % timer_text
				_phase_label.modulate = Color(0.784314, 0.721569, 0.627451, 1)
		GameState.Phase.WON:
			_phase_label.text = "WON"
			_phase_label.modulate = Color(0.784314, 0.721569, 0.627451, 1)
		GameState.Phase.LOST:
			_phase_label.text = "LOST"
			_phase_label.modulate = Color(1, 0.4, 0.4, 1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
