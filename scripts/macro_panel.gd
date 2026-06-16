extends PanelContainer

@onready var _viewport: SubViewport = $Margin/SubViewportContainer/SubViewport
@onready var _macro_world: Node2D = $Margin/SubViewportContainer/SubViewport/MacroWorld


func _ready() -> void:
	theme_type_variation = &"MacroPanel"
	custom_minimum_size = Vector2(GameConfig.macro_width(), GameConfig.panel_height())
	var w := GameConfig.macro_width() - 16
	var h := GameConfig.panel_height() - 16
	_viewport.size = Vector2i(w, h)
