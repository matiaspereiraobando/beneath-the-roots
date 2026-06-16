extends Control

@onready var _hud: Control = $Root/HUD
@onready var _macro: Control = $Root/Content/MacroPanel
@onready var _micro: Control = $Root/Content/MicroPanel

func _ready() -> void:
	_setup_layout()
	GameState.biomass_changed.connect(_refresh_hud)
	GameState.phase_changed.connect(func(_p): _refresh_hud())
	GameState.queen_hp_changed.connect(func(_c, _m): _refresh_hud())
	GameState.queen_satiety_changed.connect(func(_s): _refresh_hud())
	_refresh_hud()

func _setup_layout() -> void:
	_hud.custom_minimum_size.y = GameConfig.HUD_HEIGHT
	_macro.custom_minimum_size = Vector2(GameConfig.macro_width(), GameConfig.panel_height())
	_micro.custom_minimum_size = Vector2(GameConfig.micro_width(), GameConfig.panel_height())

func _refresh_hud() -> void:
	$Root/HUD/BiomassLabel.text = "Biomass: %d" % GameState.biomass
	$Root/HUD/WaveLabel.text = "Wave: %d" % (GameState.wave_index + 1)
	match GameState.phase:
		GameState.Phase.BUILD:
			$Root/HUD/PhaseLabel.text = "BUILD %ds" % int(ceilf(GameState.build_timer))
		GameState.Phase.WAVE:
			$Root/HUD/PhaseLabel.text = "INVASION"
		GameState.Phase.WON:
			$Root/HUD/PhaseLabel.text = "WON"
		GameState.Phase.LOST:
			$Root/HUD/PhaseLabel.text = "LOST"
	$Root/HUD/QueenHpLabel.text = "Queen HP: %d/%d" % [GameState.queen_hp, GameState.queen_max_hp]
	$Root/HUD/SatietyLabel.text = "Satiety: %d" % int(GameState.queen_satiety)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
