extends Control

@onready var _hud: Control = $Root/HUD
@onready var _phase_label: Label = $Root/HUD/HudMargin/HudRow/PhaseLabel

func _ready() -> void:
	_hud.custom_minimum_size.y = GameConfig.HUD_HEIGHT
	GameState.biomass_changed.connect(_refresh_hud)
	GameState.phase_changed.connect(func(_p): _refresh_hud())
	GameState.queen_hp_changed.connect(func(_c, _m): _refresh_hud())
	GameState.queen_satiety_changed.connect(func(_s): _refresh_hud())
	_refresh_hud()

func _process(delta: float) -> void:
	if GameState.phase == GameState.Phase.BUILD and GameState.build_timer > 0.0:
		GameState.build_timer = maxf(0.0, GameState.build_timer - delta)
		_refresh_phase_label()

func _refresh_hud() -> void:
	$Root/HUD/HudMargin/HudRow/BiomassLabel.text = "Biomass: %d" % GameState.biomass
	$Root/HUD/HudMargin/HudRow/WaveLabel.text = "Wave: %d" % (GameState.wave_index + 1)
	_refresh_phase_label()
	$Root/HUD/HudMargin/HudRow/QueenHpLabel.text = "Queen HP: %d/%d" % [GameState.queen_hp, GameState.queen_max_hp]
	$Root/HUD/HudMargin/HudRow/SatietyLabel.text = "Satiety: %d" % int(GameState.queen_satiety)

func _refresh_phase_label() -> void:
	match GameState.phase:
		GameState.Phase.BUILD:
			_phase_label.text = "BUILD %ds" % int(ceilf(GameState.build_timer))
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
