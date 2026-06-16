extends PanelContainer

@onready var _viewport: SubViewport = $Margin/SubViewportContainer/SubViewport
@onready var _macro_world: Node2D = $Margin/SubViewportContainer/SubViewport/MacroWorld
@onready var _container: SubViewportContainer = $Margin/SubViewportContainer


func _ready() -> void:
	theme_type_variation = &"MacroPanel"
	custom_minimum_size = Vector2(GameConfig.macro_width(), GameConfig.panel_height())
	var w := GameConfig.macro_width() - 16
	var h := GameConfig.panel_height() - 16
	_viewport.size = Vector2i(w, h)
	_container.gui_input.connect(_on_container_gui_input)


func _on_container_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var pos := _container.get_local_mouse_position()
	var vp_size := Vector2(_viewport.size)
	var container_size := _container.size
	if container_size.x <= 0 or container_size.y <= 0:
		return
	var world_pos := Vector2(
		pos.x / container_size.x * vp_size.x,
		pos.y / container_size.y * vp_size.y
	)
	_macro_world.handle_world_click(world_pos)
