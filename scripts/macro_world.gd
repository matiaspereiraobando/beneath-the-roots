extends Node2D

const MacroCell = preload("res://scripts/data/macro_tiles.gd").Cell

const BUILD_TYPES := ["spitter", "crusher", "needle", "gland"]
const BUILD_LABELS := {
	"spitter": "Spitter",
	"crusher": "Crusher",
	"needle": "Needle",
	"gland": "Gland",
	"mine": "Mine",
}

@onready var camera: Camera2D = $Camera2D
@onready var terrain: TileMapLayer = $Terrain
@onready var enemies_root: Node2D = $Enemies
@onready var towers_root: Node2D = $Towers
@onready var projectiles_root: Node2D = $Projectiles
@onready var tower_menu: PanelContainer = $UILayer/TowerMenu
@onready var _tower_info: Label = $UILayer/TowerMenu/VBox/Info
@onready var _add_btn: Button = $UILayer/TowerMenu/VBox/Buttons/AddBtn
@onready var _remove_btn: Button = $UILayer/TowerMenu/VBox/Buttons/RemoveBtn
@onready var _close_btn: Button = $UILayer/TowerMenu/VBox/Buttons/CloseBtn

var _build_hints: Node2D
var _dig_hints: Node2D
var _dig_progress_root: Node2D
var _mines_root: Node2D
var _build_feedback: Label
var _feedback_timer: float = 0.0
var _selected_build_type := "spitter"
var _select_mine := false

var _pathfinding := GridPathfinding.new()
var _wave_manager := WaveManager.new()
var _combat := CombatSystem.new()
var _colony
var _enemy_sprites: Dictionary = {}
var _tower_sprites: Dictionary = {}
var _mine_sprites: Dictionary = {}
var _projectile_sprites: Dictionary = {}
var _dig_progress_labels: Dictionary = {}
var _selected_tower: Dictionary = {}
var _textures: Dictionary = {}
var _macro_tileset
var _terrain_painter


func _ready() -> void:
	_macro_tileset = load("res://scripts/util/macro_tileset.gd").new()
	_terrain_painter = load("res://scripts/systems/macro_terrain_painter.gd").new()
	_colony = load("res://scripts/systems/colony_system.gd").new()
	terrain.tile_set = _macro_tileset.tile_set
	camera.make_current()
	_load_textures()
	tower_menu.visible = false
	_setup_build_ui()
	_wire_signals()
	call_deferred("_bootstrap_level")


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
	GameState.tower_placed.connect(func(_t): _refresh_build_hints())
	GameState.mine_placed.connect(_on_mine_placed)
	GameState.mine_triggered.connect(_on_mine_triggered)
	GameState.dig_started.connect(func(_c): _refresh_dig_overlays())
	GameState.dig_completed.connect(_on_dig_completed)
	GameState.cells_changed.connect(_on_cell_changed)
	GameState.phase_changed.connect(func(_p): _refresh_build_hints())
	GameState.projectiles_changed.connect(_sync_projectiles)
	GameState.soldiers_changed.connect(_on_soldiers_changed)
	_add_btn.pressed.connect(_on_add_soldier)
	_remove_btn.pressed.connect(_on_remove_soldier)
	_close_btn.pressed.connect(_hide_tower_menu)


func _load_textures() -> void:
	_textures["spitter"] = _load_tex("res://assets/sprites/spitter.png")
	_textures["skitter"] = _load_tex("res://assets/sprites/skitter.png")
	_textures["chitin"] = _load_tex("res://assets/sprites/skitter.png")
	for tower_type in BUILD_TYPES:
		if _textures.get(tower_type) == null:
			var color: Color = GameTuning.TOWER_PLACEHOLDER_COLORS.get(tower_type, Color.WHITE)
			_textures[tower_type] = _make_color_tex(color)


func _load_tex(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _make_color_tex(color: Color) -> Texture2D:
	var size := GameTuning.TILE_SIZE
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _load_level() -> void:
	_enemy_sprites.clear()
	_tower_sprites.clear()
	_mine_sprites.clear()
	_projectile_sprites.clear()
	_dig_progress_labels.clear()
	_clear_children(enemies_root)
	_clear_children(towers_root)
	_clear_children(projectiles_root)
	if _mines_root:
		_clear_children(_mines_root)
	_macro_tileset = load("res://scripts/util/macro_tileset.gd").new()
	terrain.tile_set = _macro_tileset.tile_set
	_paint_level(GameState.level_data)
	_pathfinding.setup_from_level(GameState.level_data)
	_wave_manager.setup(_pathfinding)
	_combat.setup(_pathfinding)
	for tower in GameState.towers:
		_on_tower_placed(tower)
	for mine in GameState.mines:
		_on_mine_placed(mine)
	_refresh_build_hints()
	_refresh_dig_overlays()
	_center_camera_on_spawn()


func _paint_level(level: Dictionary) -> void:
	_terrain_painter.paint_all(terrain, level.cells, _macro_tileset)


func _process(delta: float) -> void:
	if GameState.level_data.is_empty():
		return
	_update_camera_pan(delta)
	_wave_manager.update(delta)
	_combat.update(delta)
	_colony.update(delta)
	_tick_build_feedback(delta)
	_update_dig_progress_labels()
	_sync_enemy_positions()
	_sync_projectiles()


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_select_1"):
		_set_build_selection("spitter")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("build_select_2"):
		_set_build_selection("crusher")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("build_select_3"):
		_set_build_selection("needle")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("build_select_4"):
		_set_build_selection("gland")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("build_select_5"):
		_set_build_selection("mine")
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	handle_world_click(get_global_mouse_position())


func _set_build_selection(selection: String) -> void:
	if selection == "mine":
		_select_mine = true
		_show_build_feedback("Mine selected — click a tunnel tile.")
	else:
		_select_mine = false
		_selected_build_type = selection
		_show_build_feedback("%s selected (cost %d)." % [
			BUILD_LABELS.get(selection, selection),
			GameTuning.TOWER_COSTS.get(selection, GameTuning.SPITTER_COST),
		])
	_refresh_build_hints()


func handle_world_click(world_pos: Vector2) -> void:
	if GameState.phase == GameState.Phase.WON or GameState.phase == GameState.Phase.LOST:
		return
	var cell := _pathfinding.world_to_tile(world_pos)
	var tower := GameState.get_tower_at(cell)
	if not tower.is_empty():
		_show_tower_menu(tower, world_pos)
		return
	_hide_tower_menu()
	if GameState.phase != GameState.Phase.BUILD:
		return
	if GameState.get_cell_at(cell) == MacroCell.SOFT_EARTH:
		var dig_err := GameState.start_dig(cell)
		if dig_err != "":
			_show_build_feedback(dig_err)
		else:
			_show_build_feedback("Digging… builder busy for %ds." % int(GameTuning.DIG_DURATION))
		return
	if _select_mine:
		var mine_err := GameState.place_mine(cell)
		if mine_err != "":
			_show_build_feedback(mine_err)
		else:
			_show_build_feedback("Fungal mine placed on path.")
		return
	var err := GameState.place_tower(cell, _selected_build_type)
	if err != "":
		_show_build_feedback(err)
	else:
		var label: String = BUILD_LABELS.get(_selected_build_type, _selected_build_type)
		_show_build_feedback("%s built! Click it to assign soldiers." % label)


func _show_tower_menu(tower: Dictionary, world_pos: Vector2) -> void:
	_selected_tower = tower
	tower_menu.visible = true
	tower_menu.position = world_pos + Vector2(8, -40)
	_refresh_tower_menu()


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


func _on_add_soldier() -> void:
	if _selected_tower.is_empty():
		return
	GameState.assign_soldier(_selected_tower)


func _on_remove_soldier() -> void:
	if _selected_tower.is_empty():
		return
	GameState.remove_soldier(_selected_tower)


func _on_enemy_spawned(enemy: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _textures.get(enemy.type, _textures.skitter)
	sprite.position = enemy.position
	if enemy.type == "chitin":
		sprite.modulate = Color(0.7, 0.55, 0.45)
	enemies_root.add_child(sprite)
	_enemy_sprites[enemy.id] = sprite


func _on_enemy_removed(enemy: Dictionary) -> void:
	if _enemy_sprites.has(enemy.id):
		_enemy_sprites[enemy.id].queue_free()
		_enemy_sprites.erase(enemy.id)


func _setup_build_ui() -> void:
	_build_hints = Node2D.new()
	_build_hints.name = "BuildHints"
	_build_hints.z_index = 5
	add_child(_build_hints)
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
	_build_feedback = Label.new()
	_build_feedback.name = "BuildFeedback"
	_build_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_feedback.add_theme_color_override("font_color", Color(0.78, 0.72, 0.63))
	_build_feedback.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_build_feedback.add_theme_constant_override("outline_size", 4)
	_build_feedback.visible = false
	$UILayer.add_child(_build_feedback)
	_build_feedback.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_build_feedback.offset_top = 6.0
	_build_feedback.offset_bottom = 26.0


func _refresh_build_hints() -> void:
	if _build_hints == null:
		return
	for child in _build_hints.get_children():
		child.queue_free()
	if _dig_hints:
		for child in _dig_hints.get_children():
			child.queue_free()
	if GameState.phase != GameState.Phase.BUILD:
		return
	var cells: Array = GameState.level_data.get("cells", [])
	for y in cells.size():
		for x in cells[y].size():
			var cell := Vector2i(x, y)
			var cell_type: int = cells[y][x]
			var center := _pathfinding.tile_center(cell)
			if cell_type == MacroCell.BUILD and GameState.get_tower_at(cell).is_empty():
				var ring := _make_ring(Color(0.42, 1.0, 0.29, 0.9))
				ring.position = center
				_build_hints.add_child(ring)
			elif cell_type == MacroCell.SOFT_EARTH and not GameState.is_digging_at(cell):
				var earth := _make_ring(Color(0.72, 0.52, 0.32, 0.85))
				earth.position = center
				_dig_hints.add_child(earth)


func _refresh_dig_overlays() -> void:
	_update_dig_progress_labels()


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
	_terrain_painter.refresh_region(
		terrain, GameState.level_data.cells, cell, 2, _macro_tileset
	)
	_refresh_build_hints()
	_refresh_dig_overlays()
	_show_build_feedback("Dig complete — build tile ready.")


func _on_cell_changed(cell: Vector2i) -> void:
	_terrain_painter.refresh_region(
		terrain, GameState.level_data.cells, cell, 2, _macro_tileset
	)


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
		return
	_feedback_timer -= delta
	if _feedback_timer <= 0.0 and _build_feedback:
		_build_feedback.visible = false


func _on_tower_placed(tower: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _textures.get(tower.type, _textures.spitter)
	sprite.position = _pathfinding.tile_center(Vector2i(tower.tile_x, tower.tile_y))
	towers_root.add_child(sprite)
	_tower_sprites[tower.id] = sprite


func _on_mine_placed(mine: Dictionary) -> void:
	_sync_mine_sprite(mine)


func _on_mine_triggered(mine: Dictionary) -> void:
	_sync_mine_sprite(mine)


func _sync_mine_sprite(mine: Dictionary) -> void:
	var id: int = mine.id
	var center := _pathfinding.tile_center(Vector2i(mine.tile_x, mine.tile_y))
	if not _mine_sprites.has(id):
		var dot := Sprite2D.new()
		dot.texture = _make_color_tex(Color(0.55, 0.85, 0.35))
		dot.scale = Vector2(0.5, 0.5)
		dot.position = center
		_mines_root.add_child(dot)
		_mine_sprites[id] = dot
	var sprite: Sprite2D = _mine_sprites[id]
	sprite.position = center
	sprite.modulate = Color.WHITE if mine.armed else Color(0.45, 0.45, 0.45, 0.7)


func _sync_enemy_positions() -> void:
	for enemy in GameState.enemies:
		if _enemy_sprites.has(enemy.id):
			_enemy_sprites[enemy.id].position = enemy.position


func _sync_projectiles() -> void:
	var dot_size := maxi(6, int(GameTuning.TILE_SIZE * 0.375))
	var half := dot_size * 0.5
	var live: Dictionary = {}
	for proj in GameState.projectiles:
		live[proj.id] = true
		if not _projectile_sprites.has(proj.id):
			var dot := ColorRect.new()
			dot.size = Vector2(dot_size, dot_size)
			dot.color = Color(0.42, 1, 0.29)
			dot.position = Vector2(proj.x - half, proj.y - half)
			projectiles_root.add_child(dot)
			_projectile_sprites[proj.id] = dot
		else:
			_projectile_sprites[proj.id].position = Vector2(proj.x - half, proj.y - half)
	for id in _projectile_sprites.keys():
		if not live.has(id):
			_projectile_sprites[id].queue_free()
			_projectile_sprites.erase(id)
