extends Node2D

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
var _build_feedback: Label
var _feedback_timer: float = 0.0

var _pathfinding := GridPathfinding.new()
var _wave_manager := WaveManager.new()
var _combat := CombatSystem.new()
var _colony
var _enemy_sprites: Dictionary = {}
var _tower_sprites: Dictionary = {}
var _projectile_sprites: Dictionary = {}
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


func _load_tex(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _load_level() -> void:
	_enemy_sprites.clear()
	_tower_sprites.clear()
	_projectile_sprites.clear()
	_clear_children(enemies_root)
	_clear_children(towers_root)
	_clear_children(projectiles_root)
	_macro_tileset = load("res://scripts/util/macro_tileset.gd").new()
	terrain.tile_set = _macro_tileset.tile_set
	_paint_level(GameState.level_data)
	_pathfinding.setup_from_level(GameState.level_data)
	_wave_manager.setup(_pathfinding)
	_combat.setup(_pathfinding)
	for tower in GameState.towers:
		_on_tower_placed(tower)
	_refresh_build_hints()
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
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
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
	if GameState.phase == GameState.Phase.BUILD:
		var err := GameState.place_spitter(cell)
		if err != "":
			_show_build_feedback(err)
		else:
			_show_build_feedback("Spitter built! Click it to assign soldiers.")


func _show_tower_menu(tower: Dictionary, world_pos: Vector2) -> void:
	_selected_tower = tower
	tower_menu.visible = true
	tower_menu.position = world_pos + Vector2(8, -40)
	_refresh_tower_menu()


func _refresh_tower_menu() -> void:
	if _selected_tower.is_empty():
		return
	_tower_info.text = "Spitter  Soldiers: %d/%d" % [
		_selected_tower.soldiers, GameTuning.TOWER_BASE_SLOTS
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
	if GameState.phase != GameState.Phase.BUILD:
		return
	for slot in GameState.level_data.get("buildSlots", []):
		var cell := Vector2i(slot.x, slot.y)
		if not GameState.get_tower_at(cell).is_empty():
			continue
		var center := _pathfinding.tile_center(cell)
		var ring := _make_build_ring()
		ring.position = center
		_build_hints.add_child(ring)


func _make_build_ring() -> Sprite2D:
	var tex_size := GameTuning.TILE_SIZE
	var thickness := 3
	var gap := 5
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	var color := Color(0.42, 1.0, 0.29, 0.9)
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
	sprite.texture = _textures.get("spitter")
	sprite.position = _pathfinding.tile_center(Vector2i(tower.tile_x, tower.tile_y))
	towers_root.add_child(sprite)
	_tower_sprites[tower.id] = sprite


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
