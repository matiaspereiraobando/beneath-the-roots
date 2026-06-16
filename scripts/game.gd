extends Control

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
	GameState.biomass_changed.connect(_refresh_hud)
	GameState.phase_changed.connect(func(_p): _refresh_hud())
	GameState.queen_hp_changed.connect(func(_c, _m): _refresh_hud())
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	GameState.build_timer_changed.connect(func(_t): _refresh_phase_label())
	GameState.soldiers_changed.connect(_refresh_soldiers)
	_refresh_hud()
	_refresh_soldiers(GameState.free_soldiers)


func _load_hud_icons() -> void:
	_biomass_icon.texture = _load_icon("res://assets/sprites/ui/icon_biomass.png")
	_satiety_icon.texture = _load_icon("res://assets/sprites/ui/icon_satiety.png")
	_soldiers_icon.texture = _load_icon("res://assets/sprites/ui/icon_soldier.png")
	for icon in [_biomass_icon, _satiety_icon, _soldiers_icon]:
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _load_icon(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.35, 0.3))
	return ImageTexture.create_from_image(image)


func _refresh_hud() -> void:
	_biomass_label.text = "%d" % GameState.biomass
	$Root/HUD/HudMargin/HudRow/WaveLabel.text = "Wave: %d" % (GameState.wave_index + 1)
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
		GameState.Phase.BUILD:
			var slots := "rock tile" if GameState.has_open_build_slot() else "no slots"
			_phase_label.text = "BUILD %ds — click %s (%d biomass)" % [
				int(ceilf(GameState.build_timer)),
				slots,
				GameTuning.SPITTER_COST,
			]
			_phase_label.modulate = Color(0.784314, 0.721569, 0.627451, 1)
		GameState.Phase.WAVE:
			_phase_label.text = "INVASION"
			_phase_label.modulate = Color(0.415686, 1, 0.290196, 1)
		GameState.Phase.WON:
			_phase_label.text = "WON"
			_phase_label.modulate = Color(0.784314, 0.721569, 0.627451, 1)
		GameState.Phase.LOST:
			_phase_label.text = "LOST"
			_phase_label.modulate = Color(1, 0.4, 0.4, 1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
