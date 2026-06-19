extends Control

const ANIM_SEC := 0.25

@onready var _scrim: ColorRect = $Scrim
@onready var _drawer: Control = $Drawer
@onready var _rail: PanelContainer = $Rail

var _expanded := false
var _layout_tween: Tween


func _ready() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail.z_index = 2
	_drawer.z_index = 1
	_rail.expand_requested.connect(toggle)
	GameState.citadel_breached.connect(_on_breach)
	call_deferred("_apply_layout", true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout", true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_colony_menu"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if _expanded:
		collapse()
	else:
		expand()


func expand() -> void:
	if _expanded:
		return
	_expanded = true
	_apply_layout(false)


func collapse() -> void:
	if not _expanded:
		return
	_expanded = false
	_apply_layout(false)


func _panel_height() -> float:
	var parent := get_parent()
	if parent is Control and parent.size.y > 1.0:
		return parent.size.y
	if size.y > 1.0:
		return size.y
	return float(GameConfig.panel_height())


func _layout_targets() -> Dictionary:
	var rail_w := GameConfig.colony_rail_width()
	var drawer_w := GameConfig.colony_drawer_width()
	var total_w := drawer_w + rail_w
	if _expanded:
		return {
			"offset_left": -total_w,
			"rail_x": float(drawer_w),
			"drawer_x": 0.0,
			"scrim_x": 0.0,
			"scrim_a": 0.25,
		}
	return {
		"offset_left": -rail_w,
		"rail_x": 0.0,
		"drawer_x": float(rail_w),
		"scrim_x": 0.0,
		"scrim_a": 0.0,
	}


func _apply_layout(immediate: bool) -> void:
	var rail_w := GameConfig.colony_rail_width()
	var drawer_w := GameConfig.colony_drawer_width()
	var panel_h := _panel_height()
	var targets := _layout_targets()

	_rail.size = Vector2(rail_w, panel_h)
	_drawer.size = Vector2(drawer_w, panel_h)
	_scrim.size = Vector2(drawer_w, panel_h)

	_rail.set_expanded_tab(_expanded)

	if immediate:
		if _layout_tween and _layout_tween.is_valid():
			_layout_tween.kill()
		offset_left = targets.offset_left
		offset_right = 0
		offset_top = 0
		offset_bottom = 0
		_rail.position.x = targets.rail_x
		_drawer.position.x = targets.drawer_x
		_scrim.position.x = targets.scrim_x
		_drawer.visible = _expanded
		_scrim.visible = _expanded
		_scrim.modulate.a = targets.scrim_a
		return

	if _layout_tween and _layout_tween.is_valid():
		_layout_tween.kill()
	if _expanded:
		_drawer.visible = true
		_scrim.visible = true
	_layout_tween = create_tween()
	_layout_tween.set_parallel(true)
	_layout_tween.set_trans(Tween.TRANS_CUBIC)
	_layout_tween.set_ease(Tween.EASE_OUT)
	_layout_tween.tween_property(self, "offset_left", targets.offset_left, ANIM_SEC)
	_layout_tween.tween_property(_rail, "position:x", targets.rail_x, ANIM_SEC)
	_layout_tween.tween_property(_drawer, "position:x", targets.drawer_x, ANIM_SEC)
	_layout_tween.tween_property(_scrim, "modulate:a", targets.scrim_a, ANIM_SEC)
	_layout_tween.chain().tween_callback(func() -> void:
		_drawer.visible = _expanded
		_scrim.visible = _expanded
	)


func _on_breach(_damage: int) -> void:
	_rail.pulse_breach()
