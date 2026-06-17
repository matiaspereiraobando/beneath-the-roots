extends PanelContainer

@onready var _viewport_container: SubViewportContainer = $Margin/SubViewportContainer
@onready var _viewport: SubViewport = $Margin/SubViewportContainer/SubViewport


func _ready() -> void:
	theme_type_variation = &"MacroPanel"
	custom_minimum_size = Vector2(GameConfig.macro_width(), GameConfig.panel_height())
	_resize_viewport()


func _resize_viewport() -> void:
	var w := GameConfig.macro_width() - 16
	var h := GameConfig.panel_height() - 16
	_viewport_container.stretch = false
	_viewport_container.custom_minimum_size = Vector2(w, h)
	_viewport.size = Vector2i(w, h)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_resize_viewport")
