extends Node2D

const MacroCell = preload("res://scripts/data/macro_tiles.gd").Cell
const TowerSprites = preload("res://scripts/util/tower_sprites.gd")
const EnemySprites = preload("res://scripts/util/enemy_sprites.gd")
const PlacementRules = preload("res://scripts/systems/placement.gd")
const TowerCatalog = preload("res://scripts/data/tower_catalog.gd")
const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
const SpritePaths = preload("res://scripts/util/sprite_paths.gd")
const ActionToolButton = preload("res://scripts/ui/action_tool_button.gd")
const ThemeSetupScript = preload("res://scripts/autoload/theme_setup.gd")

const BUILD_TYPES := ["spitter", "crusher", "needle", "gland"]
const BUILD_LABELS := {
	"spitter": "Spitter",
	"crusher": "Crusher",
	"needle": "Needle",
	"gland": "Gland",
	"mine": "Fungal mine",
}
const TOOLBAR_EDGE_MARGIN := 8
const TOOLBAR_SECTION_GAP := 16
const STRUCTURE_INFO_GAP := 8
const TOWER_RANGE_COLORS := {
	"spitter": Color(0.45, 0.75, 0.35, 0.9),
	"crusher": Color(0.85, 0.55, 0.35, 0.9),
	"needle": Color(0.55, 0.65, 0.9, 0.9),
	"gland": Color(0.75, 0.45, 0.9, 0.9),
}
const RANGE_CIRCLE_SEGMENTS := 72

enum MacroTool { NONE, DIG, BUILD }

@onready var camera: Camera2D = $Camera2D
@onready var terrain: TileMapLayer = $Terrain
@onready var enemies_root: Node2D = $Enemies
@onready var towers_root: Node2D = $Towers
@onready var projectiles_root: Node2D = $Projectiles
@onready var tower_menu: PanelContainer = $HudLayer/TowerMenu
@onready var structure_info_panel: PanelContainer = $HudLayer/StructureInfoPanel
@onready var _structure_info_title: Label = $HudLayer/StructureInfoPanel/Margin/VBox/Title
@onready var _structure_info_attack: Label = $HudLayer/StructureInfoPanel/Margin/VBox/AttackType
@onready var _structure_info_desc: Label = $HudLayer/StructureInfoPanel/Margin/VBox/Description
@onready var _structure_info_stats: Label = $HudLayer/StructureInfoPanel/Margin/VBox/Stats
@onready var _tower_info: Label = $HudLayer/TowerMenu/VBox/Info
@onready var _add_btn: Button = $HudLayer/TowerMenu/VBox/Buttons/AddBtn
@onready var _remove_btn: Button = $HudLayer/TowerMenu/VBox/Buttons/RemoveBtn
@onready var _close_btn: Button = $HudLayer/TowerMenu/VBox/Buttons/CloseBtn
@onready var _dig_btn: ActionToolButton = $HudLayer/ToolBarPanel/ToolBar/ActionsBar/DigBtn
@onready var _build_btn: ActionToolButton = $HudLayer/ToolBarPanel/ToolBar/ActionsBar/BuildBtn
@onready var _structure_gap: Control = $HudLayer/ToolBarPanel/ToolBar/StructureGap
@onready var _structure_bar: HBoxContainer = $HudLayer/ToolBarPanel/ToolBar/StructureBar
@onready var _toolbar_panel: PanelContainer = $HudLayer/ToolBarPanel

var _dig_hints: Node2D
var _range_indicator_root: Node2D
var _preview_root: Node2D
var _dig_progress_root: Node2D
var _mines_root: Node2D
var _effects_root: Node2D
var _build_feedback: Label
var _feedback_timer: float = 0.0
var _active_tool: MacroTool = MacroTool.NONE
var _selected_structure: String = ""
var _structure_buttons: Dictionary = {}
var _preview_valid_tex: Texture2D
var _preview_invalid_tex: Texture2D

var _pathfinding := GridPathfinding.new()
var _wave_manager := WaveManager.new()
var _combat := CombatSystem.new()
var _colony
var _enemy_sprites: Dictionary = {}
var _tower_sprites: Dictionary = {}
var _gland_aura_sprites: Dictionary = {}
var _mine_sprites: Dictionary = {}
var _projectile_sprites: Dictionary = {}
var _dig_progress_labels: Dictionary = {}
var _selected_tower: Dictionary = {}
var _textures: Dictionary = {}
var _macro_tileset
var _terrain_painter
var _terrain_depth_shader: Shader
var _sky_bg: Sprite2D


func _ready() -> void:
	_macro_tileset = load("res://scripts/util/macro_tileset.gd").new()
	_terrain_painter = load("res://scripts/systems/macro_terrain_painter.gd").new()
	_terrain_depth_shader = load("res://shaders/macro_terrain_depth.gdshader")
	_colony = load("res://scripts/systems/colony_system.gd").new()
	terrain.tile_set = _macro_tileset.tile_set
	camera.make_current()
	_load_textures()
	_make_preview_textures()
	tower_menu.visible = false
	structure_info_panel.visible = false
	_apply_hud_theme()
	_setup_world_ui()
	_setup_toolbar()
	_wire_signals()
	get_viewport().size_changed.connect(_sync_toolbar_layout)
	call_deferred("_sync_toolbar_layout")
	call_deferred("_bootstrap_level")


func _apply_hud_theme() -> void:
	var theme := _resolve_game_theme()
	if not theme:
		return
	for node in [_toolbar_panel, tower_menu, structure_info_panel]:
		node.theme = theme


func _resolve_game_theme() -> Theme:
	var vp := get_viewport()
	if vp is SubViewport:
		var host: Node = vp.get_parent()
		if host:
			var main_theme: Theme = host.get_tree().root.theme
			if main_theme:
				return main_theme
	var local_theme: Theme = get_tree().root.theme
	if local_theme:
		return local_theme
	return ThemeSetupScript.build_runtime_theme()


func _bootstrap_level() -> void:
	if GameState.level_data.is_empty():
		return
	_load_level()


func _wire_signals() -> void:
	GameState.level_loaded.connect(func(_id): _load_level())
	GameState.enemy_spawned.connect(_on_enemy_spawned)
	GameState.enemy_killed.connect(_on_enemy_removed)
	GameState.enemy_reached_end.connect(_on_enemy_removed)
	GameState.tower_placed.connect(_on_tower_placed)
	GameState.tower_placed.connect(func(_t): _refresh_dig_hints())
	GameState.mine_placed.connect(_on_mine_placed)
	GameState.mine_triggered.connect(_on_mine_triggered)
	GameState.dig_started.connect(func(_c): _refresh_dig_overlays())
	GameState.dig_completed.connect(_on_dig_completed)
	GameState.cells_changed.connect(_on_cell_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.projectiles_changed.connect(_sync_projectiles)
	GameState.combat_effects_changed.connect(_sync_combat_effects)
	GameState.tower_fired.connect(_on_tower_fired)
	GameState.soldiers_changed.connect(_on_soldiers_changed)
	_add_btn.pressed.connect(_on_add_soldier)
	_remove_btn.pressed.connect(_on_remove_soldier)
	_close_btn.pressed.connect(_hide_tower_menu)
	_dig_btn.pressed.connect(_on_dig_pressed)
	_build_btn.pressed.connect(_on_build_pressed)


func _load_textures() -> void:
	for tower_type in BUILD_TYPES + ["mine"]:
		_textures[tower_type] = TowerSprites.make_tower_texture(tower_type)


func _make_preview_textures() -> void:
	var size := GameTuning.TILE_SIZE
	_preview_valid_tex = _make_cell_texture(size, Color(0.35, 0.95, 0.4, 0.45))
	_preview_invalid_tex = _make_cell_texture(size, Color(0.95, 0.3, 0.3, 0.45))


func _make_cell_texture(size: int, color: Color) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _load_level() -> void:
	_hide_tower_menu()
	_active_tool = MacroTool.NONE
	_selected_structure = ""
	_enemy_sprites.clear()
	_tower_sprites.clear()
	_gland_aura_sprites.clear()
	_mine_sprites.clear()
	_projectile_sprites.clear()
	_dig_progress_labels.clear()
	_clear_children(enemies_root)
	_clear_children(towers_root)
	_clear_children(projectiles_root)
	if _mines_root:
		_clear_children(_mines_root)
	if _effects_root:
		_clear_children(_effects_root)
	_macro_tileset = load("res://scripts/util/macro_tileset.gd").new()
	terrain.tile_set = _macro_tileset.tile_set
	_paint_level(GameState.level_data)
	_apply_terrain_depth_shader(GameState.level_data)
	_pathfinding.setup_from_level(GameState.level_data)
	_wave_manager.setup(_pathfinding)
	_combat.setup(_pathfinding)
	for tower in GameState.towers:
		_on_tower_placed(tower)
	for mine in GameState.mines:
		_on_mine_placed(mine)
	_refresh_dig_hints()
	_refresh_dig_overlays()
	_sync_gland_auras()
	_update_toolbar_visuals()
	_update_tool_hint()
	_center_camera_on_spawn()


func _paint_level(level: Dictionary) -> void:
	_terrain_painter.paint_all(terrain, level.cells, _macro_tileset)
	_update_sky_background(level)


func _ensure_sky_background() -> void:
	if _sky_bg != null:
		return
	_sky_bg = Sprite2D.new()
	_sky_bg.name = "SkyBackground"
	_sky_bg.z_index = -10
	_sky_bg.centered = false
	add_child(_sky_bg)
	move_child(_sky_bg, terrain.get_index())


func _update_sky_background(level: Dictionary) -> void:
	_ensure_sky_background()
	var path := SpritePaths.macro_sky_background()
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var image := Image.new()
		if image.load(path) != OK:
			_sky_bg.visible = false
			return
		tex = ImageTexture.create_from_image(image)
	_sky_bg.texture = tex
	var cells: Array = level.get("cells", [])
	if cells.is_empty():
		_sky_bg.visible = false
		return
	var surface_row := _find_surface_row(cells)
	var surface_y := float(surface_row * GameTuning.TILE_SIZE)
	_sky_bg.position = Vector2(0.0, surface_y - tex.get_height())
	_sky_bg.visible = true


func _apply_terrain_depth_shader(level: Dictionary) -> void:
	if _terrain_depth_shader == null:
		terrain.material = null
		return
	var cells: Array = level.get("cells", [])
	if cells.is_empty():
		terrain.material = null
		return
	var rows: int = level.gridSize.rows
	var tile := GameTuning.TILE_SIZE
	var surface_row := _find_surface_row(cells)
	var depth_rows := maxi(1, rows - surface_row - 1)
	var mat := ShaderMaterial.new()
	mat.shader = _terrain_depth_shader
	mat.set_shader_parameter("surface_y", float(surface_row * tile))
	mat.set_shader_parameter("depth_range", float(depth_rows * tile))
	mat.set_shader_parameter("min_brightness", GameTuning.MACRO_DEPTH_MIN_BRIGHTNESS)
	mat.set_shader_parameter("cool_tint", GameTuning.MACRO_DEPTH_COOL_TINT)
	terrain.material = mat


func _find_surface_row(cells: Array) -> int:
	for y in cells.size():
		var row: Array = cells[y]
		for x in row.size():
			if row[x] == MacroCell.SURFACE:
				return y
	return 0


func _process(delta: float) -> void:
	if GameState.level_data.is_empty():
		return
	_update_camera_pan(delta)
	_wave_manager.update(delta)
	_combat.update(delta)
	_colony.update(delta)
	GameState.tick_combat_effects(delta)
	_tick_build_feedback(delta)
	_update_dig_progress_labels()
	_sync_combat_effects()
	_update_gland_pulse(delta)
	_sync_enemy_positions()
	_sync_projectiles()
	_update_hover_preview()


func _on_phase_changed(phase: GameState.Phase) -> void:
	_refresh_dig_hints()
	_update_toolbar_visuals()
	_update_tool_hint()
	_sync_gland_auras()
	_refresh_structure_info_panel()
	for tower in GameState.towers:
		if _tower_sprites.has(tower.id):
			_tower_sprites[tower.id].modulate = Color.WHITE


func _on_dig_pressed() -> void:
	if _active_tool == MacroTool.DIG:
		_clear_tool()
	else:
		_set_tool(MacroTool.DIG)


func _on_build_pressed() -> void:
	if _active_tool == MacroTool.BUILD:
		_clear_tool()
	else:
		_set_tool(MacroTool.BUILD)


func _set_tool(tool: MacroTool) -> void:
	if tool == MacroTool.NONE:
		_clear_tool()
		return
	_active_tool = tool
	if tool == MacroTool.DIG:
		_selected_structure = ""
	_update_toolbar_visuals()
	_update_tool_hint()
	_refresh_dig_hints()


func _clear_tool() -> void:
	_active_tool = MacroTool.NONE
	_selected_structure = ""
	_update_toolbar_visuals()
	_update_tool_hint()
	_refresh_dig_hints()


func _select_structure(type: String) -> void:
	_active_tool = MacroTool.BUILD
	_selected_structure = type
	_update_toolbar_visuals()
	_update_tool_hint()


func _clear_structure_selection() -> void:
	_selected_structure = ""
	_update_toolbar_visuals()
	_update_tool_hint()


func _update_toolbar_visuals() -> void:
	_dig_btn.set_pressed_no_signal(_active_tool == MacroTool.DIG)
	_build_btn.set_pressed_no_signal(_active_tool == MacroTool.BUILD)
	var show_structures := _active_tool == MacroTool.BUILD
	_structure_gap.visible = show_structures
	_structure_bar.visible = show_structures
	for type in _structure_buttons:
		var btn: ActionToolButton = _structure_buttons[type]
		var is_selected: bool = _selected_structure == type and _active_tool == MacroTool.BUILD
		btn.set_pressed_no_signal(is_selected)
	call_deferred("_sync_toolbar_layout")
	_refresh_structure_info_panel()


func _refresh_structure_info_panel() -> void:
	if structure_info_panel == null:
		return
	var show := GameState.is_playing() and _active_tool == MacroTool.BUILD and _selected_structure != ""
	structure_info_panel.visible = show
	if not show:
		return
	var type := _selected_structure
	_structure_info_title.text = TowerCatalog.display_name(type)
	_structure_info_attack.text = TowerCatalog.attack_type(type)
	_structure_info_desc.text = TowerCatalog.description(type)
	_structure_info_stats.text = "\n".join(TowerCatalog.stat_lines(type))
	call_deferred("_sync_structure_info_layout")


func _sync_structure_info_layout() -> void:
	if structure_info_panel == null or not structure_info_panel.visible:
		return
	if not is_instance_valid(_toolbar_panel):
		return
	structure_info_panel.reset_size()
	var panel_size := structure_info_panel.get_combined_minimum_size()
	structure_info_panel.size = panel_size
	structure_info_panel.position = Vector2(
		_toolbar_panel.position.x,
		maxf(TOOLBAR_EDGE_MARGIN, _toolbar_panel.position.y - STRUCTURE_INFO_GAP - panel_size.y),
	)


func _update_tool_hint() -> void:
	if not GameState.is_playing():
		if _build_feedback and _feedback_timer <= 0.0:
			_build_feedback.visible = false
		return
	var hint := ""
	match _active_tool:
		MacroTool.NONE:
			hint = ""
		MacroTool.DIG:
			hint = "Dig tool — click rock beside a tunnel (G)"
		MacroTool.BUILD:
			if _selected_structure == "":
				hint = "Build tool — pick a structure (keys 1–5, B)"
			elif _selected_structure == "mine":
				hint = "Fungal mine — click a tunnel tile"
			else:
				var label: String = BUILD_LABELS.get(_selected_structure, _selected_structure)
				hint = "%s — click valid 2×2 chamber beside path" % label
	if hint != "" and _feedback_timer <= 0.0:
		_build_feedback.text = hint
		_build_feedback.visible = true
	elif _build_feedback and _feedback_timer <= 0.0:
		_build_feedback.visible = false


func _update_camera_pan(delta: float) -> void:
	var dir := Input.get_vector(
		&"macro_pan_left", &"macro_pan_right", &"macro_pan_up", &"macro_pan_down"
	)
	if dir == Vector2.ZERO:
		return
	camera.position += dir * GameTuning.MACRO_PAN_SPEED * delta
	_clamp_camera()


func _center_camera_on_spawn() -> void:
	var spawn: Dictionary = GameState.level_data.get("spawnTile", {})
	if spawn.is_empty():
		return
	camera.position = _pathfinding.tile_center(Vector2i(spawn.x, spawn.y))
	_clamp_camera()


func _clamp_camera() -> void:
	var level := GameState.level_data
	if level.is_empty():
		return
	var map_size := Vector2(level.gridSize.cols, level.gridSize.rows) * GameTuning.TILE_SIZE
	var view_size := Vector2(get_viewport().size)
	var half_view := view_size * 0.5
	var pos := camera.position
	pos.x = _clamp_camera_axis(pos.x, half_view.x, map_size.x)
	pos.y = _clamp_camera_axis(pos.y, half_view.y, map_size.y)
	camera.position = pos


func _clamp_camera_axis(value: float, half_view: float, map_length: float) -> float:
	var min_limit := half_view
	var max_limit := map_length - half_view
	if max_limit < min_limit:
		return map_length * 0.5
	return clampf(value, min_limit, max_limit)


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("macro_tool_dig"):
		if _active_tool == MacroTool.DIG:
			_clear_tool()
		else:
			_set_tool(MacroTool.DIG)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("macro_tool_build"):
		if _active_tool == MacroTool.BUILD:
			_clear_tool()
		else:
			_set_tool(MacroTool.BUILD)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_clear_structure_selection()
			_hide_tower_menu()
			return
		if GameState.is_playing():
			match event.keycode:
				KEY_1:
					_select_structure("spitter")
				KEY_2:
					_select_structure("crusher")
				KEY_3:
					_select_structure("needle")
				KEY_4:
					_select_structure("gland")
				KEY_5:
					_select_structure("mine")
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			handle_world_click(get_global_mouse_position())


func handle_world_click(world_pos: Vector2) -> void:
	if GameState.phase == GameState.Phase.WON or GameState.phase == GameState.Phase.LOST:
		return
	var cell := _pathfinding.world_to_tile(world_pos)
	var tower := GameState.get_tower_at(cell)
	if not tower.is_empty():
		_show_tower_menu(tower, world_pos)
		return
	_hide_tower_menu()
	if not GameState.is_playing():
		return
	if _active_tool == MacroTool.DIG:
		var dig_err := GameState.start_dig(cell)
		if dig_err != "":
			_show_build_feedback(dig_err)
		else:
			_show_build_feedback("Digging… builder busy for %ds." % int(GameTuning.DIG_DURATION))
		return
	if _active_tool != MacroTool.BUILD or _selected_structure == "":
		_show_build_feedback("Select Dig or Build tool, then a structure (1–5).")
		return
	var err := ""
	if _selected_structure == "mine":
		err = GameState.place_mine(cell)
	else:
		err = GameState.place_tower(cell, _selected_structure)
	if err != "":
		_show_build_feedback(err)
	else:
		var label: String = BUILD_LABELS.get(_selected_structure, _selected_structure)
		_show_build_feedback("%s placed!" % label)


func _setup_toolbar() -> void:
	_apply_toolbar_styles()
	_toolbar_panel.clip_contents = true
	_structure_gap.custom_minimum_size = Vector2(TOOLBAR_SECTION_GAP, 0.0)
	_dig_btn.setup_from_sheet(SpritePaths.action_tool_sheet("dig"))
	_build_btn.setup_from_sheet(SpritePaths.action_tool_sheet("build"))
	_dig_btn.tooltip_text = "Dig (G)"
	_build_btn.tooltip_text = "Build (B)"
	for type in BUILD_TYPES + ["mine"]:
		var btn := ActionToolButton.new()
		btn.setup_from_sheet(SpritePaths.structure_tool_sheet(type))
		btn.tooltip_text = "%s (key %d)" % [
			BUILD_LABELS.get(type, type),
			BUILD_TYPES.find(type) + 1 if type != "mine" else 5,
		]
		btn.pressed.connect(_on_structure_button.bind(type))
		_structure_bar.add_child(btn)
		_structure_buttons[type] = btn
	_update_toolbar_visuals()
	call_deferred("_sync_toolbar_layout")


func _sync_toolbar_layout() -> void:
	if not is_instance_valid(_toolbar_panel):
		return
	_toolbar_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var panel_size := _measure_toolbar_size()
	_toolbar_panel.size = panel_size
	var vp := get_viewport().get_visible_rect().size
	_toolbar_panel.position = Vector2(TOOLBAR_EDGE_MARGIN, vp.y - TOOLBAR_EDGE_MARGIN - panel_size.y)
	_sync_structure_info_layout()


func _measure_toolbar_size() -> Vector2:
	var actions_bar := _toolbar_panel.get_node("ToolBar/ActionsBar") as HBoxContainer
	var inner_sep := float(actions_bar.get_theme_constant("separation"))
	var height := maxf(_dig_btn.get_minimum_size().y, 56.0)
	var width := _dig_btn.get_minimum_size().x + inner_sep + _build_btn.get_minimum_size().x
	if _structure_bar.visible:
		width += _structure_gap.custom_minimum_size.x + _structure_bar.get_minimum_size().x
	return Vector2(width, height)


func _apply_toolbar_styles() -> void:
	_toolbar_panel.add_theme_stylebox_override("panel", HudThemeRes.toolbar_panel())
	_apply_tower_menu_styles()
	_apply_structure_info_styles()
	if _build_feedback:
		HudThemeRes.apply_pixel_label(_build_feedback, HudThemeRes.FONT_CAPTION)
		_build_feedback.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE_VARIANT)
		_build_feedback.add_theme_color_override("font_outline_color", Color.BLACK)


func _apply_tower_menu_styles() -> void:
	tower_menu.add_theme_stylebox_override("panel", HudThemeRes.ant_strip())
	HudThemeRes.apply_pixel_label(_tower_info, HudThemeRes.FONT_CAPTION)
	_tower_info.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE)
	for btn in [_add_btn, _remove_btn]:
		HudThemeRes.apply_toolbar_text_button(btn, HudThemeRes.SECONDARY)
	HudThemeRes.apply_toolbar_text_button(_close_btn, HudThemeRes.ON_SURFACE_VARIANT)


func _apply_structure_info_styles() -> void:
	structure_info_panel.add_theme_stylebox_override("panel", HudThemeRes.game_hud_panel())
	HudThemeRes.apply_pixel_label(_structure_info_title, HudThemeRes.FONT_STAT)
	_structure_info_title.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE)
	HudThemeRes.apply_pixel_label(_structure_info_attack, HudThemeRes.FONT_CAPTION)
	_structure_info_attack.add_theme_color_override("font_color", HudThemeRes.PRIMARY)
	HudThemeRes.apply_pixel_label(_structure_info_desc, HudThemeRes.FONT_CAPTION)
	_structure_info_desc.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE_VARIANT)
	HudThemeRes.apply_pixel_label(_structure_info_stats, HudThemeRes.FONT_CAPTION)
	_structure_info_stats.add_theme_color_override("font_color", HudThemeRes.SECONDARY)


func _on_structure_button(type: String) -> void:
	if _selected_structure == type and _active_tool == MacroTool.BUILD:
		_clear_structure_selection()
	else:
		_select_structure(type)


func _show_tower_menu(tower: Dictionary, world_pos: Vector2) -> void:
	_selected_tower = tower
	tower_menu.visible = true
	_show_range_indicator(tower)
	call_deferred("_position_tower_menu", world_pos)
	_refresh_tower_menu()


func _position_tower_menu(world_pos: Vector2) -> void:
	var screen := _world_to_screen(world_pos)
	var vp := get_viewport().get_visible_rect().size
	tower_menu.position = Vector2(
		clampf(screen.x + 8.0, 8.0, vp.x - tower_menu.size.x - 8.0),
		clampf(screen.y - 48.0, 8.0, vp.y - tower_menu.size.y - 8.0),
	)


func _refresh_tower_menu() -> void:
	if _selected_tower.is_empty():
		return
	var label: String = BUILD_LABELS.get(_selected_tower.type, _selected_tower.type)
	if _selected_tower.type == "gland":
		_tower_info.text = "%s (aura support)" % label
		_add_btn.disabled = true
		_remove_btn.disabled = true
		return
	_tower_info.text = "%s  Soldiers: %d/%d" % [
		label, _selected_tower.soldiers, GameTuning.TOWER_BASE_SLOTS
	]
	_add_btn.disabled = (
		_selected_tower.soldiers >= GameTuning.TOWER_BASE_SLOTS
		or GameState.free_soldiers <= 0
	)
	_remove_btn.disabled = _selected_tower.soldiers <= 0


func _on_soldiers_changed(_count: int) -> void:
	if tower_menu.visible:
		_refresh_tower_menu()


func _hide_tower_menu() -> void:
	tower_menu.visible = false
	_selected_tower = {}
	_hide_range_indicator()


func _on_add_soldier() -> void:
	if _selected_tower.is_empty():
		return
	GameState.assign_soldier(_selected_tower)


func _on_remove_soldier() -> void:
	if _selected_tower.is_empty():
		return
	GameState.remove_soldier(_selected_tower)


func _on_enemy_spawned(enemy: Dictionary) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = EnemySprites.make_walk_sprite_frames(str(enemy.type))
	sprite.animation = &"walk"
	sprite.play()
	sprite.position = enemy.position
	enemies_root.add_child(sprite)
	_enemy_sprites[enemy.id] = sprite


func _on_enemy_removed(enemy: Dictionary) -> void:
	if _enemy_sprites.has(enemy.id):
		_enemy_sprites[enemy.id].queue_free()
		_enemy_sprites.erase(enemy.id)


func _setup_world_ui() -> void:
	_range_indicator_root = Node2D.new()
	_range_indicator_root.name = "RangeIndicator"
	_range_indicator_root.z_index = 3
	add_child(_range_indicator_root)
	_preview_root = Node2D.new()
	_preview_root.name = "HoverPreview"
	_preview_root.z_index = 8
	add_child(_preview_root)
	_dig_hints = Node2D.new()
	_dig_hints.name = "DigHints"
	_dig_hints.z_index = 5
	add_child(_dig_hints)
	_dig_progress_root = Node2D.new()
	_dig_progress_root.name = "DigProgress"
	_dig_progress_root.z_index = 6
	add_child(_dig_progress_root)
	_mines_root = Node2D.new()
	_mines_root.name = "Mines"
	_mines_root.z_index = 4
	add_child(_mines_root)
	_effects_root = Node2D.new()
	_effects_root.name = "CombatEffects"
	_effects_root.z_index = 7
	add_child(_effects_root)
	_build_feedback = Label.new()
	_build_feedback.name = "BuildFeedback"
	_build_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_feedback.visible = false
	var hud_theme := _resolve_game_theme()
	if hud_theme:
		_build_feedback.theme = hud_theme
	$HudLayer.add_child(_build_feedback)
	_build_feedback.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_build_feedback.offset_top = 4.0
	_build_feedback.offset_bottom = 24.0


func _refresh_dig_hints() -> void:
	if _dig_hints == null:
		return
	for child in _dig_hints.get_children():
		child.queue_free()
	if not GameState.is_playing() or _active_tool != MacroTool.DIG:
		return
	var cells: Array = GameState.level_data.get("cells", [])
	for y in cells.size():
		for x in cells[y].size():
			var cell := Vector2i(x, y)
			if PlacementRules.can_dig(cell) != "":
				continue
			if GameState.is_digging_at(cell):
				continue
			var hint := _make_ring(Color(0.72, 0.52, 0.32, 0.55))
			hint.position = _pathfinding.tile_center(cell)
			_dig_hints.add_child(hint)


func _update_hover_preview() -> void:
	if _preview_root == null:
		return
	for child in _preview_root.get_children():
		child.queue_free()
	if not GameState.is_playing():
		return
	var cell := _pathfinding.world_to_tile(get_global_mouse_position())
	if _active_tool == MacroTool.DIG:
		var valid := PlacementRules.can_dig(cell) == ""
		_add_preview_cell(cell, valid)
		return
	if _active_tool != MacroTool.BUILD or _selected_structure == "":
		return
	if _selected_structure == "mine":
		var mine_valid := PlacementRules.can_place_mine(cell) == ""
		_add_preview_cell(cell, mine_valid)
		return
	var size := PlacementRules.footprint_for(_selected_structure)
	var err := PlacementRules.can_place_tower(cell, _selected_structure)
	var tower_valid := err == ""
	_add_build_range_preview(cell, _selected_structure, tower_valid)
	for foot_cell in PlacementRules.footprint_cells(cell, size):
		_add_preview_cell(foot_cell, tower_valid)


func _add_build_range_preview(anchor: Vector2i, tower_type: String, valid: bool) -> void:
	var range_px: float = GameTuning.tower_stat(tower_type, "range", 0.0)
	if range_px <= 0.0:
		return
	var color := _tower_range_color(tower_type)
	if not valid:
		color.a *= 0.35
	var indicator := _make_range_circle(range_px, color)
	indicator.z_index = -1
	var size := PlacementRules.footprint_for(tower_type)
	indicator.position = PlacementRules.structure_world_center(anchor, size, _pathfinding)
	_preview_root.add_child(indicator)


func _add_preview_cell(cell: Vector2i, valid: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _preview_valid_tex if valid else _preview_invalid_tex
	sprite.centered = true
	sprite.position = _pathfinding.tile_center(cell)
	_preview_root.add_child(sprite)


func _refresh_dig_overlays() -> void:
	_update_dig_progress_labels()
	_refresh_dig_hints()


func _update_dig_progress_labels() -> void:
	if _dig_progress_root == null:
		return
	var live: Dictionary = {}
	for job in GameState.dig_jobs:
		var key := "%d,%d" % [job.cell_x, job.cell_y]
		live[key] = true
		var label: Label
		if _dig_progress_labels.has(key):
			label = _dig_progress_labels[key]
		else:
			label = Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.55))
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
			label.add_theme_constant_override("outline_size", 3)
			_dig_progress_root.add_child(label)
			_dig_progress_labels[key] = label
		var center := _pathfinding.tile_center(Vector2i(job.cell_x, job.cell_y))
		label.position = center + Vector2(-16, -8)
		var pct := int((float(job.progress) / float(job.duration)) * 100.0)
		label.text = "Dig %d%%" % pct
	for key in _dig_progress_labels.keys():
		if not live.has(key):
			_dig_progress_labels[key].queue_free()
			_dig_progress_labels.erase(key)


func _on_dig_completed(cell: Vector2i) -> void:
	_pathfinding.rebuild(GameState.level_data)
	GameState.repath_enemies(_pathfinding)
	_terrain_painter.refresh_region(
		terrain, GameState.level_data.cells, cell, 2, _macro_tileset
	)
	_refresh_dig_hints()
	_refresh_dig_overlays()
	_show_build_feedback("Tunnel opened — enemies will reroute.")


func _on_cell_changed(cell: Vector2i) -> void:
	_terrain_painter.refresh_region(
		terrain, GameState.level_data.cells, cell, 2, _macro_tileset
	)


func _show_range_indicator(tower: Dictionary) -> void:
	if _range_indicator_root == null:
		return
	_hide_range_indicator()
	var tower_type := str(tower.type)
	var range_px: float = GameTuning.tower_stat(tower_type, "range", GameTuning.SPITTER_RANGE)
	if range_px <= 0.0:
		return
	var indicator := _make_range_circle(range_px, _tower_range_color(tower_type))
	indicator.position = _tower_sprite_position(tower)
	_range_indicator_root.add_child(indicator)


func _tower_range_color(tower_type: String) -> Color:
	return TOWER_RANGE_COLORS.get(tower_type, Color(0.9, 0.9, 0.9, 0.85))


func _hide_range_indicator() -> void:
	if _range_indicator_root == null:
		return
	_clear_children(_range_indicator_root)


func _make_range_circle(radius_px: float, color: Color) -> Node2D:
	var root := Node2D.new()
	var points := PackedVector2Array()
	for i in RANGE_CIRCLE_SEGMENTS:
		var angle := TAU * float(i) / float(RANGE_CIRCLE_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius_px)
	var fill := Polygon2D.new()
	fill.polygon = points
	fill.color = Color(color.r, color.g, color.b, 0.1)
	fill.antialiased = true
	root.add_child(fill)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 2.0
	outline.default_color = color
	outline.antialiased = true
	root.add_child(outline)
	return root


func _make_ring(color: Color) -> Sprite2D:
	var tex_size := GameTuning.TILE_SIZE
	var thickness := 3
	var gap := 5
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	for y in tex_size:
		for x in tex_size:
			var outer := x < thickness or y < thickness or x >= tex_size - thickness or y >= tex_size - thickness
			var inner_hole := x >= gap and x < tex_size - gap and y >= gap and y < tex_size - gap
			if outer and not inner_hole:
				image.set_pixel(x, y, color)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
	return sprite


func _show_build_feedback(message: String) -> void:
	if _build_feedback == null:
		return
	_build_feedback.text = message
	_build_feedback.visible = true
	_feedback_timer = 2.5


func _tick_build_feedback(delta: float) -> void:
	if _feedback_timer <= 0.0:
		if GameState.is_playing():
			_update_tool_hint()
		return
	_feedback_timer -= delta
	if _feedback_timer <= 0.0:
		_update_tool_hint()


func _tower_sprite_position(tower: Dictionary) -> Vector2:
	return PlacementRules.tower_world_center(tower, _pathfinding)


func _tower_sprite_scale(tower: Dictionary) -> Vector2:
	var native := TowerSprites.structure_native_size(str(tower.type))
	if native.x <= 0 or native.y <= 0:
		return Vector2.ONE
	var footprint := Vector2(
		float(tower.get("width", 2)) * GameTuning.TILE_SIZE,
		float(tower.get("height", 2)) * GameTuning.TILE_SIZE,
	)
	return Vector2(footprint.x / float(native.x), footprint.y / float(native.y))


func _on_tower_placed(tower: Dictionary) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = TowerSprites.make_structure_sprite_frames(tower.type)
	sprite.animation = &"idle"
	sprite.play()
	sprite.position = _tower_sprite_position(tower)
	sprite.scale = _tower_sprite_scale(tower)
	towers_root.add_child(sprite)
	_tower_sprites[tower.id] = sprite
	_sync_gland_auras()
	_refresh_tower_terrain(tower)


func _refresh_tower_terrain(tower: Dictionary) -> void:
	for foot_cell in PlacementRules.tower_footprint_cells(tower):
		_terrain_painter.refresh_region(
			terrain, GameState.level_data.cells, foot_cell, 1, _macro_tileset
		)


func _on_tower_fired(tower_id: int) -> void:
	if not _tower_sprites.has(tower_id):
		return
	var sprite: AnimatedSprite2D = _tower_sprites[tower_id]
	if sprite.has_meta("flash_tween") and sprite.get_meta("flash_tween").is_valid():
		sprite.get_meta("flash_tween").kill()
	var tween := create_tween()
	sprite.set_meta("flash_tween", tween)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _sync_gland_auras() -> void:
	for id in _gland_aura_sprites.keys():
		_gland_aura_sprites[id].queue_free()
	_gland_aura_sprites.clear()
	if not GameState.invasion_active():
		return
	for tower in GameState.towers:
		if tower.type != "gland":
			continue
		var center := _tower_sprite_position(tower)
		var aura := _make_ring(Color(0.68, 0.35, 0.82, 0.35))
		var range_px: float = GameTuning.tower_stat("gland", "range", 180.0)
		var scale := (range_px * 2.0) / float(GameTuning.TILE_SIZE)
		aura.scale = Vector2(scale, scale)
		aura.position = center
		aura.z_index = -1
		towers_root.add_child(aura)
		_gland_aura_sprites[tower.id] = aura


func _update_gland_pulse(_delta: float) -> void:
	if not GameState.invasion_active():
		return
	var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.006)
	for tower in GameState.towers:
		if tower.type != "gland":
			continue
		if _tower_sprites.has(tower.id):
			_tower_sprites[tower.id].modulate = Color(0.9 * pulse, 0.75 * pulse, 1.0)
		if _gland_aura_sprites.has(tower.id):
			_gland_aura_sprites[tower.id].modulate.a = 0.22 + 0.18 * pulse


func _sync_combat_effects() -> void:
	if _effects_root == null:
		return
	_clear_children(_effects_root)
	for effect in GameState.combat_effects:
		var max_life: float = float(effect.get("max_life", 0.3))
		var alpha := clampf(float(effect.life) / max_life, 0.0, 1.0)
		match effect.get("type", ""):
			"splash":
				var splash := _make_ring(effect.color)
				var radius: float = float(effect.radius)
				splash.scale = Vector2((radius * 2.0) / float(GameTuning.TILE_SIZE), (radius * 2.0) / float(GameTuning.TILE_SIZE))
				splash.position = Vector2(effect.x, effect.y)
				splash.modulate.a = alpha
				_effects_root.add_child(splash)
			"beam":
				var line := Line2D.new()
				line.width = 4.0
				line.default_color = effect.color
				line.modulate.a = alpha
				line.add_point(Vector2(effect.x, effect.y))
				line.add_point(Vector2(effect.tx, effect.ty))
				_effects_root.add_child(line)


func _on_mine_placed(mine: Dictionary) -> void:
	_sync_mine_sprite(mine)


func _on_mine_triggered(mine: Dictionary) -> void:
	_sync_mine_sprite(mine)


func _sync_mine_sprite(mine: Dictionary) -> void:
	var id: int = mine.id
	var center := _pathfinding.tile_center(Vector2i(mine.tile_x, mine.tile_y))
	if not _mine_sprites.has(id):
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = TowerSprites.make_structure_sprite_frames("mine")
		anim.animation = &"idle"
		anim.play()
		anim.position = center
		_mines_root.add_child(anim)
		_mine_sprites[id] = anim
	var sprite: AnimatedSprite2D = _mine_sprites[id]
	sprite.position = center
	sprite.modulate = Color.WHITE if mine.armed else Color(0.45, 0.45, 0.45, 0.7)


func _sync_enemy_positions() -> void:
	for enemy in GameState.enemies:
		if not _enemy_sprites.has(enemy.id):
			continue
		var sprite: AnimatedSprite2D = _enemy_sprites[enemy.id]
		sprite.position = enemy.position
		var path: PackedVector2Array = enemy.path
		var idx: int = int(enemy.path_index)
		if idx < path.size() - 1:
			var dx: float = path[idx + 1].x - enemy.position.x
			if absf(dx) > 0.5:
				sprite.flip_h = dx < 0.0


func _sync_projectiles() -> void:
	var dot_size := maxi(6, int(GameTuning.TILE_SIZE * 0.375))
	var half := dot_size * 0.5
	var live: Dictionary = {}
	for proj in GameState.projectiles:
		live[proj.id] = true
		var color: Color = TowerSprites.projectile_color(str(proj.get("type", "spitter")))
		if not _projectile_sprites.has(proj.id):
			var dot := ColorRect.new()
			dot.size = Vector2(dot_size, dot_size)
			dot.color = color
			dot.position = Vector2(proj.x - half, proj.y - half)
			projectiles_root.add_child(dot)
			_projectile_sprites[proj.id] = dot
		else:
			var dot: ColorRect = _projectile_sprites[proj.id]
			dot.color = color
			dot.position = Vector2(proj.x - half, proj.y - half)
	for id in _projectile_sprites.keys():
		if not live.has(id):
			_projectile_sprites[id].queue_free()
			_projectile_sprites.erase(id)
