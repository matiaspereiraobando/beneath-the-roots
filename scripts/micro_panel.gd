extends PanelContainer

@onready var _satiety_label: Label = $Margin/VBox/SatietyLabel
@onready var _viewport: SubViewport = $Margin/VBox/SubViewportContainer/SubViewport


func _ready() -> void:
	theme_type_variation = &"MicroPanel"
	custom_minimum_size = Vector2(GameConfig.micro_width(), GameConfig.panel_height())
	var w := GameConfig.micro_width() - 16
	var h := GameConfig.panel_height() - 56
	_viewport.size = Vector2i(w, h)
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	_on_satiety_changed(GameState.queen_satiety)


func _on_satiety_changed(value: float) -> void:
	_satiety_label.text = "Satiety: %d%%" % int(value)
